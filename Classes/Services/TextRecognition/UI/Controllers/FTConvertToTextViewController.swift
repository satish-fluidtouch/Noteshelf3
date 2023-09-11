//
//  FTConvertToTextViewController.swift
//  Noteshelf
//
//  Created by Naidu on 15/06/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

@objc protocol FTConvertToTextViewControllerDelegate: NSObjectProtocol {
    func didFinishConversion(withText recognisedString:String, controller: FTConvertToTextViewController)
    func didChooseReplace(withInfo recognitionInfo:FTRecognitionResult?, useDefaultFont: Bool, controller: FTConvertToTextViewController)
}
protocol FTNS1SearchWarningProtocol: NSObjectProtocol{
    func handleNS1ContentWarning()
    func dontShowNS1ContentWarning(for notebookUUID: String?)
    func canShowWarning(for notebookUUID: String) -> Bool
}

private let USE_DEFAULT_COLOR = true;

@objcMembers class FTConvertToTextViewController: UIViewController {
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var convertToTextButton: UIButton?
    @IBOutlet private weak var copyButton: UIButton?
    @IBOutlet private weak var textView: UITextView?
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView?
    @IBOutlet private weak var tableView: UITableView!
    
    weak var delegate: FTConvertToTextViewControllerDelegate?
    weak var currentPage: FTPageProtocol?
    weak var searchOptions: FTFinderSearchOptions?

    private var keyboardOffset: CGFloat = 0.0
    internal let textChecker = UITextChecker()

    var defaultTextColor = UIColor.label
    var defaultTextFont  = UIFont.systemFont(ofSize: 10)
    var annotations: [FTAnnotation]?
    var canvasSize: CGSize = CGSize.zero
    var recognitionProcessor: FTRecognitionTaskProcessor?
    var recognitionInfo: FTRecognitionResult?
    var currentEngineLanguage: String!
    
    var neverShowNS1ContentWarning: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "neverShowNS1ContentWarning")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "neverShowNS1ContentWarning")
            UserDefaults.standard.synchronize()
        }
    }

    var convertPreferredLanguage: String {
        FTConvertToTextViewModel.convertPreferredLanguage
    }

    var convertPreferredFont: String {
        FTConvertToTextViewModel.convertPreferredFont
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        #if DEBUG
        debugPrint("\(type(of: self)) is deallocated");
        #endif
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureNavigationItems()
        self.tableView?.register(UINib.init(nibName: "FTConvertToTextCell", bundle: nil), forCellReuseIdentifier: "ConvertToTextSettings")
        self.registerForKeyboardDidShowNotification()
        self.registerForKeyboardWillHideNotification()
        self.currentEngineLanguage = self.convertPreferredLanguage
        self.startRecognitionProcess()
        self.configureTextView()
        self.configureCopyBtn()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if (self.convertPreferredFont == FTConvertFontSize.default.displayTitle) {
            if(!USE_DEFAULT_COLOR) {
                self.textView?.textColor = defaultTextColor
            }
            self.textView?.font = defaultTextFont
        }
        else{
            if(!USE_DEFAULT_COLOR) {
                if let annotationsList = self.annotations, !annotationsList.isEmpty {
                    if let firstStroke = annotationsList.first as? FTStroke {
                        self.textView?.textColor = firstStroke.strokeColor;
                    }
                }
            }
            self.textView?.font = defaultTextFont.withSize(17.0)
        }

        if(self.currentEngineLanguage != self.convertPreferredLanguage){
            self.currentEngineLanguage = self.convertPreferredLanguage
            self.startRecognitionProcess()
        }
        self.tableView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if(FTLanguageResourceManager.shared.currentLanguageCode == nil){
            UIAlertController.showAlert(withTitle: "Please select your language preference for recognition.", message: "" , from: self, withCompletionHandler: nil)
        }
    }

    private func configureTextView() {
        self.textView?.layer.borderWidth = 1.0
        self.textView?.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor
        self.textView?.layer.cornerRadius = 10.0
        self.textView?.layer.masksToBounds = true
        self.textView?.addDoneButton(title: "Done".localized, target: self, selector: #selector(tapDone(sender:)))
    }

    private func configureCopyBtn() {
        self.copyButton?.layer.borderColor = UIColor.appColor(.accent).cgColor
        self.copyButton?.layer.borderWidth = 1.0
        self.copyButton?.layer.cornerRadius = 10.0
        self.copyButton?.layer.masksToBounds = true
    }

    private func configureNavigationItems() {
        // Cancel Button
        let customFont = UIFont.appFont(for: .regular, with: 17.0)
        let customButton = UIButton(type: .custom)
        customButton.titleLabel?.font = customFont
        customButton.setTitle("Cancel", for: .normal)
        customButton.setTitleColor(.appColor(.accent), for: .normal)
        let customBarButtonItem = UIBarButtonItem(customView: customButton)
        customButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = customBarButtonItem

        // Title
        self.navigationItem.title = "ConvertToText".localized
        let font = UIFont.clearFaceFont(for: .medium, with: 20)
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: font]

        // Back Button
        let backButton = UIBarButtonItem(title: "Back".localized, style: .plain, target: nil, action: nil)
        backButton.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.appFont(for: .medium, with: 17.0)], for: .normal)
        self.navigationController?.navigationBar.tintColor = UIColor.appColor(.accent)
        self.navigationItem.backBarButtonItem = backButton
    }

    @objc func cancelButtonTapped() {
        self.dismiss(animated: true)
    }

    @objc func tapDone(sender: Any) {
        self.view.endEditing(true)
    }

    func startRecognitionProcess(){
        self.textView?.text = ""
        self.convertToTextButton?.isEnabled = false
        self.copyButton?.isEnabled = false
        self.convertToTextButton?.alpha = 0.5
        self.copyButton?.alpha = 0.5
        
        self.textView?.contentInset = UIEdgeInsets.init(top: 10, left: 10, bottom: 10, right:10)
//        self.preferredContentSize = CGSize.init(width: 580, height: 495)
        
        self.activityIndicator?.startAnimating()
        
        // Configure the iink runtime environment
        if (Bundle.languageConfigurationPath(forLanguage: self.convertPreferredLanguage) != nil) {
            track("convert_to_text", params: ["action" : "Processed"], shouldLog: true);
            FTNotebookRecognitionHelper.activateMyScript("Convert_Text");
            self.recognitionProcessor = FTRecognitionTaskProcessor.init(with: self.convertPreferredLanguage)
            DispatchQueue.global().async { [weak self] in
                if let weakSelf  = self {
                    let task: FTRecognitionTask = FTRecognitionTask(language: weakSelf.convertPreferredLanguage
                                                                    , annotations: weakSelf.annotations ?? [FTAnnotation]()
                                                                    , canvasSize: weakSelf.canvasSize)
                    task.onCompletion = { (info, error) in
                        runInMainThread {
                            weakSelf.recognitionInfo = info
                            guard let recogInfo = weakSelf.recognitionInfo, weakSelf.currentEngineLanguage == recogInfo.languageCode else {
                                weakSelf.activityIndicator?.stopAnimating()
                                return
                            }
                            weakSelf.textView?.text = weakSelf.getFormattedRecognizedString(recogInfo.recognisedString)
                            weakSelf.convertToTextButton?.isEnabled = true
                            weakSelf.copyButton?.isEnabled = true
                            weakSelf.convertToTextButton?.alpha = 1.0
                            weakSelf.copyButton?.alpha = 1.0
                            
                            weakSelf.delegate?.didFinishConversion(withText: recogInfo.recognisedString, controller: weakSelf)
                            weakSelf.handleNS1ContentWarning()
                            weakSelf.activityIndicator?.stopAnimating()
                        }
                    }
                    weakSelf.recognitionProcessor?.startTask(task, onCompletion: nil)
                }
            }
        } else {
            self.activityIndicator?.stopAnimating()
        }
    }
    
    @IBAction func replaceWithTextBoxClicked(_ sender: Any) {
        self.delegate?.didChooseReplace(withInfo: self.recognitionInfo, useDefaultFont: (self.convertPreferredFont == FTConvertFontSize.default.displayTitle), controller: self)
    }
    
    @IBAction func copyToClipBoardClicked(_ sender: Any) {
        if let convertedString = self.recognitionInfo?.recognisedString, !convertedString.isEmpty {
            UIPasteboard.general.string = convertedString
            let config = FTToastConfiguration(title: "convertToText.copiedToClipBoard".localized)
            FTToastHostController.showToast(from: self, toastConfig: config)
        }
    }
}

extension FTConvertToTextViewController: FTNS1SearchWarningProtocol{
    internal func handleNS1ContentWarning(){
        if let documentID = self.currentPage?.parentDocument?.documentUUID {
            if self.canShowWarning(for: documentID) {
                let alertController = UIAlertController.init(title: "NS1ContentWarningInfo".localized, message: nil, preferredStyle: .alert);
                let dismissAction = UIAlertAction.init(title: "Dismiss".localized, style: .default) { (_) in
                    
                };
                alertController.addAction(dismissAction);
                
                let dontShowAction = UIAlertAction.init(title: "DontShowForThisBook".localized, style: .default) {[weak self] (_) in
                    self?.dontShowNS1ContentWarning(for: self?.currentPage?.parentDocument?.documentUUID)
                };
                alertController.addAction(dontShowAction);
                
                let neverShowAction = UIAlertAction.init(title: "NeverShowAgain".localized, style: .destructive) {[weak self] (_) in
                    self?.neverShowNS1ContentWarning = true
                };
                
                alertController.addAction(neverShowAction);
                self.present(alertController, animated: true, completion: { [weak self] in
                    self?.searchOptions?.hasAlreadyShownNS1ContentWarning = true
                });
            }
        }
    }
    internal func dontShowNS1ContentWarning(for notebookUUID: String?){
        if let UUID = notebookUUID {
            var notebookUUIDs:[String] = []
            if let existingIds = UserDefaults.standard.array(forKey: "DontShowUUIDs") as? [String]{
                notebookUUIDs.append(contentsOf: existingIds)
            }
            notebookUUIDs.append(UUID)
            UserDefaults.standard.set(notebookUUIDs, forKey: "DontShowUUIDs")
            UserDefaults.standard.synchronize()
        }
    }
    internal func canShowWarning(for notebookUUID: String) -> Bool{
        var canShow:Bool = (self.neverShowNS1ContentWarning == false && self.currentPage?.parentDocument?.hasNS1Content == true && self.searchOptions?.hasAlreadyShownNS1ContentWarning == false)
        if let existingIds = UserDefaults.standard.array(forKey: "DontShowUUIDs") as? [String]{
            if canShow == true{
                canShow = (existingIds.contains(notebookUUID) == false)
            }
        }
        return canShow
    }
    
}
extension FTConvertToTextViewController {
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)

        var contentInsets = self.textView?.contentInset ?? UIEdgeInsets.zero;
        contentInsets.bottom = self.keyboardOffset;

        if newCollection.horizontalSizeClass == UIUserInterfaceSizeClass.regular && newCollection.horizontalSizeClass == UIUserInterfaceSizeClass.regular {
            contentInsets.bottom = 0
        }
        self.textView?.contentInset = contentInsets
        self.textView?.scrollIndicatorInsets = contentInsets
    }
    //MARK:- KeyboardRelated
    func registerForKeyboardDidShowNotification() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidShowNotification, object: nil, queue: nil, using: { [weak self] (notification) -> Void in
            guard let strongSelf = self,let _textView = self?.textView, let userInfo = notification.userInfo else {
                return;
            }
            
            let keyboardSize = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue.size
            strongSelf.keyboardOffset = keyboardSize.height-150
            
            var contentInsets = _textView.contentInset;
            contentInsets.bottom = strongSelf.keyboardOffset;
            
            _textView.contentInset = contentInsets
            _textView.scrollIndicatorInsets = contentInsets
        });
    }
    
    func registerForKeyboardWillHideNotification() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil, using: { [weak self] (_) -> Void in
            guard let _textView = self?.textView else {
                return;
            }
            var contentInsets = _textView.contentInset;
            contentInsets.bottom = 0;

            _textView.contentInset = contentInsets
            _textView.scrollIndicatorInsets = contentInsets
        })
    }
}

extension FTConvertToTextViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return FTConvertToTextViewModel.allCases.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNonzeroMagnitude
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ConvertToTextSettings", for: indexPath) as? FTConvertToTextCell else {
            fatalError("Programmer error - Couldnot find cell with id ConvertToTextSettings")
        }
        let viewModel = FTConvertToTextViewModel(rawValue: indexPath.row)
        cell.settingLabel?.text = viewModel?.displayName
        cell.valueLabel?.text = viewModel?.displayInfo
        cell.extraConfigureCell()
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            let convertOptionsVc = FTConvertToTextViewModel.fontSize.detailViewController
            (convertOptionsVc as? FTConvertPreferencesViewController)?.isLanguageSettings = false
            convertOptionsVc.view.addVisualEffectBlur(style: .regular, cornerRadius: 0.0)
            convertOptionsVc.view.alpha = 0.0
            convertOptionsVc.view.isOpaque = true
            self.navigationController?.pushViewController(convertOptionsVc, animated: true) {
                convertOptionsVc.view.alpha = 1.0
            }
        } else if indexPath.row == 1 {
            let convertOptionsVc = FTConvertToTextViewModel.language.detailViewController
            convertOptionsVc.view.addVisualEffectBlur(style: .regular, cornerRadius: 0.0)
            convertOptionsVc.view.alpha = 0.0
            convertOptionsVc.view.isOpaque = true
            self.navigationController?.pushViewController(convertOptionsVc, animated: true) {
                convertOptionsVc.view.alpha = 1.0
            }
        } else if indexPath.row == 2 {
            let customDictVc = FTConvertToTextViewModel.customDictionary.detailViewController
            customDictVc.view.addVisualEffectBlur(style: .regular, cornerRadius: 0.0)
            customDictVc.view.alpha = 0.0
            customDictVc.view.isOpaque = true
            self.navigationController?.pushViewController(customDictVc, animated: true) {
                customDictVc.view.alpha = 1.0
            }
        }
    }
}

#if targetEnvironment(macCatalyst)
extension FTConvertToTextViewController: FTKeyCommandAction {
    override var keyCommands: [UIKeyCommand]? {
        return [
            FTKeyCommand.closeModalWindow
        ]
    }
    
    func didTapOnClose(_ sender: UIKeyCommand) {
        self.cancelButtonTapped();
    }
}
#endif
