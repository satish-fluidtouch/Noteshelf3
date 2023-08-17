//
//  FTNoteshelfAIViewController.swift
//  Sample AI
//
//  Created by Amar Udupa on 31/07/23.
//

import UIKit

class FTNoteshelfAI {
    static var supportsNoteshelfAI: Bool {
#if targetEnvironment(macCatalyst)
        return !UIDevice.isChinaRegion
#else
        return !UIDevice.isChinaRegion
#endif
    }
}
extension UIStoryboard {
    static func instantiateAIViewController(withIdentifier: String) -> UIViewController {
        let storyboard = UIStoryboard(name: "NoteshelfAI", bundle: Bundle(for: FTNoteshelfAIViewController.self))
        return storyboard.instantiateViewController(withIdentifier: withIdentifier)
    }
}

protocol FTNoteshelfAIDelegate: NSObjectProtocol {
    func noteshelfAIController(_ ccntroller: FTNoteshelfAIViewController,didTapOnAction: FTNotesehlfAIAction,content: String);
}

class FTNoteshelfAIInputField: UITextField {
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        commonInit();
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder);
        commonInit();
    }
    
    func commonInit() {
        if let image = UIImage(named: "navicon") {
            let imageView = UIImageView(image: image);
            self.leftView = imageView;
            self.leftViewMode = .always;
        }
    }
    
    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.leftViewRect(forBounds: bounds);
        rect.origin.x = 16;
        return rect;
    }
}

class FTSafeAreazView: UIView {
    override var safeAreaInsets: UIEdgeInsets {
        var safeInsets = super.safeAreaInsets
        if let windwow = self.window, !windwow.traitCollection.isRegular {
            if safeInsets.bottom != windwow.safeAreaInsets.bottom {
                safeInsets.bottom = windwow.safeAreaInsets.bottom;
            }
        }
        return safeInsets
    }
}

class FTNoteshelfAIViewController: UIViewController {
    private var currentToken : String = UUID().uuidString

    public static var maxAllowedTokenCounter = 30;
    
    @IBOutlet private weak var textField: UITextField?;
    @IBOutlet private weak var textView: UITextView?;
    @IBOutlet private weak var contentView: UIView?;
    @IBOutlet private weak var footerView: UIView?;
    
    private weak var delegate: FTNoteshelfAIDelegate?;
    
    private weak var footerVC: FTNoteshelfAIFooterViewController?;
    private weak var betaAlertVC: FTNoteshelfAITokensConsumedAlertViewController?;

    private var contentString: String?;
    private var enteredContent: String = "";
    
    private var languageCode: String = "" {
        didSet {
            if languageCode != oldValue,aiCommand == .langTranslate {
                updateContentView();
            }
        }
    }

    private let formSheetTransitionDelegate = FTFormSheetTransitionDelegate();
    private weak var optionsController: UIViewController?;
    private var aiCommand: FTOpenAICommandType = .none {
        didSet {
            if aiCommand != oldValue {
                updateContentView();
                currentToken = UUID().uuidString;
            }
        }
    };
        
    private func reset() {
        self.textField?.text = "";
        languageCode = "";
        self.enteredContent = "";
    }
        
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange();
    }
    static func showNoteshelfAI(from presentingController:UIViewController, content:String?,delegate: FTNoteshelfAIDelegate?) {
        guard let controller = UIStoryboard.instantiateAIViewController(withIdentifier: "FTNoteshelfAIViewController") as? FTNoteshelfAIViewController else {
            fatalError("ERROR!!!!");
        }
        controller.contentString = content;
        controller.delegate = delegate;
        controller.preferredContentSize = CGSize(width: 500, height: 508);
        let navController = UINavigationController(rootViewController: controller);
        navController.modalPresentationStyle = .formSheet;
        navController.transitioningDelegate = controller.formSheetTransitionDelegate;
        navController.isModalInPresentation = true;
        presentingController.present(navController, animated: true);
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "noteshelf.ai.noteshelfAI".aiLocalizedString;
        let doneButton = FTNavBarButtonItem(type: .right, title: "Done".localized, delegate: self);
        self.navigationItem.rightBarButtonItem = doneButton;
        updateContentView();
        for eachController in children {
            if let controller = eachController as? FTNoteshelfAIFooterViewController {
                footerVC = controller;
                break;
            }
        }
    }
    
    private func updateContentView() {
        guard let contentView = self.contentView else {
            return;
        }
        
        var controller: UIViewController?;
        
        self.textField?.placeholder = self.aiCommand.placeholderMessage;
        self.footerVC?.footermode = .noteshelfAiBeta;
                
        if aiCommand == .none {
            self.reset();
            controller = UIStoryboard.instantiateAIViewController(withIdentifier: FTNoteshelfAIOptionsViewController.className);
            (controller as? FTNoteshelfAIOptionsViewController)?.delegate = self;
            (controller as? FTNoteshelfAIOptionsViewController)?.contentString = self.contentString;
        }
        else if aiCommand == .langTranslate && languageCode.isEmpty {
            self.reset();
            controller = UIStoryboard.instantiateAIViewController(withIdentifier: FTNoteshelfAITranslateViewController.className);
            (controller as? FTNoteshelfAITranslateViewController)?.delegate = self;
        }
        else {
            controller = UIStoryboard.instantiateAIViewController(withIdentifier: FTNoteshelfAITextViewViewController.className);
            (controller as? FTNoteshelfAITextViewViewController)?.delegate = self;
        }
        
        if let optCOntorller = controller {
            self.optionsController?.view.removeFromSuperview();
            self.optionsController?.removeFromParent();

            optCOntorller.view.frame = contentView.bounds;
            contentView.addSubview(optCOntorller.view);
            optCOntorller.view.addEqualConstraintsToView(toView: contentView);
            self.addChild(optCOntorller);
            
            self.setOverrideTraitCollection(self.traitCollection, forChild: optCOntorller);
            self.optionsController = optCOntorller;
        }
        
        if allTokensConsumed {
            self.showTokensConsumedAlert();
        }
    }
}

extension FTNoteshelfAIViewController: FTNoteshelfAIOptionsViewControllerDelegate {
    func aiOptionsController(_ controller: FTNoteshelfAIOptionsViewController, didTapOnOption option: FTOpenAICommandType) {
        self.aiCommand = option;
        if self.textField?.isFirstResponder ?? false {
            self.textField?.delegate = nil;
            self.textField?.resignFirstResponder();
            self.textField?.delegate = self;
        }
        
        if option != .langTranslate {
            self.executeAIAction();
        }
    }
}

extension FTNoteshelfAIViewController: FTNoteshelfAITranslateViewControllerDelegate {
    func translateController(_ controller: FTNoteshelfAITranslateViewController, didSelectLanguage language: FTTranslateOption) {
        languageCode = language.title.openAITrim();
        if self.textField?.isFirstResponder ?? false {
            self.textField?.delegate = nil;
            self.textField?.resignFirstResponder();
            self.textField?.delegate = self;
        }
        self.executeAIAction();
    }
}

extension FTNoteshelfAIViewController: FTNoteshelfAITextViewViewControllerDelegate {
    func textViewController(_ controller: FTNoteshelfAITextViewViewController, didSelectOption action: FTNotesehlfAIAction,content: String) {
        if action == .regenerateResponse {
            self.executeAIAction();
        }
        else {
            self.delegate?.noteshelfAIController(self, didTapOnAction: action, content: content)
        }
    }
}


extension FTNoteshelfAIViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if self.aiCommand == .langTranslate, (self.contentToExecute?.isEmpty ?? true) {
            self.aiCommand = .generalQuestion;
        }
    }
    
    @objc func textFieldDidChange(_ name: Notification) {
        if self.aiCommand != .langTranslate, self.textField?.text?.isEmpty ?? false {
            self.aiCommand = .none;
        }
        else if self.aiCommand == .langTranslate, !self.languageCode.isEmpty {
            self.aiCommand = .none;
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        return true;
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if self.aiCommand != .langTranslate {
            self.aiCommand = .none;
        }
        else if self.aiCommand == .langTranslate, !self.languageCode.isEmpty {
            self.aiCommand = .none;
        }
        return true;
    }
        
    func textFieldDidEndEditing(_ textField: UITextField) {
        if self.aiCommand == .langTranslate {
            if let trimmedText = textField.text?.openAITrim(), !trimmedText.isEmpty {
                languageCode = trimmedText;
                self.executeAIAction();
            }
            else {
                updateContentView();
            }
        }
        else if let trimmedText = textField.text?.openAITrim()
            ,trimmedText.isEmpty {
            self.aiCommand = .none;
        }
        else {
            self.enteredContent = textField.text?.openAITrim() ?? "";
            self.aiCommand = (self.aiCommand == .none) ? .generalQuestion : aiCommand;
            self.executeAIAction();
        }
    }
}

private extension FTNoteshelfAIViewController {
    var allTokensConsumed: Bool {
        if FTNoteshelfAIViewController.maxAllowedTokenCounter <= UserDefaults.aiTokensConsumed {
            return true;
        }
        return false;
    }
    
    func canExecuteAIAction() -> Bool {
        guard aiCommand != .none else {
            return false;
        }
        
        guard let stringToExecute = self.contentToExecute,!stringToExecute.isEmpty else {
            return false;
        }
        
        if aiCommand == .langTranslate, languageCode.isEmpty {
            return false;
        }
        return true;
    }
        
    func executeAIAction() {
        if(allTokensConsumed) {
            self.showTokensConsumedAlert();
            return;
        }
        
        guard canExecuteAIAction() else {
            self.textViewController?.showPlaceHolder(self.aiCommand.placeHolderContent);
            return;
        }
        
        if self.aiCommand == .none {
            fatalError("Command is none and is not expected");
        }
        
        self.textViewController?.showPlaceHolder("");
        self.textViewController?.showActionOptions(false);
        
        let command = FTAICommand.command(for: self.aiCommand,content: self.contentToExecute ?? "");
        (command as? FTAITranslateCommand)?.languageCode = languageCode;
        
        self.textField?.text = command.executionMessage;
        
        UserDefaults.incrementAiTokenConsumed()
        currentToken = command.commandToken;
        FTOpenAI.shared.execute(command: command) {[weak self] (string, error,token) in
            guard let curToken = self?.currentToken, curToken == token else {
                return;
            }
            self?.textViewController?.insertText(string);
        } onCompletion: { [weak self] (error,token) in
            guard let curToken = self?.currentToken, curToken == token else {
                return;
            }
            var supportHandwrite = false;
            if self?.aiCommand == .langTranslate {
                if let langCode = self?.languageCode, let option = FTTranslateOption.languageOption(title: langCode) {
                    supportHandwrite = option.supportsHandWritingRecognition;
                }
            }
            else if UIDevice.isChinaRegion {
                supportHandwrite = false;
            }
            else if UIDevice.supportedLanguages {
                supportHandwrite = true;
            }
            self?.textViewController?.supportsHandwriting = supportHandwrite;
            self?.textViewController?.showActionOptions(error == nil);
            self?.footerVC?.footermode = .sendFeedback;
        }
    }
    
    var textViewController: FTNoteshelfAITextViewViewController? {
        return self.optionsController as? FTNoteshelfAITextViewViewController
    }
    
    var contentToExecute: String? {
        if aiCommand == .generalQuestion {
            return self.enteredContent;
        }
        if aiCommand != .langTranslate {
            if !self.enteredContent.isEmpty {
                return self.enteredContent;
            }
        }
        return self.contentString;
    }
}

//MARK:- Tokens View -
private extension FTNoteshelfAIViewController {
    func showTokensConsumedAlert() {
        guard nil == self.betaAlertVC
                , let contentView = self.contentView
                , let vc = UIStoryboard.instantiateAIViewController(withIdentifier: FTNoteshelfAITokensConsumedAlertViewController.className) as? FTNoteshelfAITokensConsumedAlertViewController else {
            return;
        }
        self.textField?.isUserInteractionEnabled = false;

        vc.view.frame = contentView.bounds;
        self.addChild(vc);
        self.betaAlertVC = vc;
        contentView.addSubview(vc.view);
        vc.view.addEqualConstraintsToView(toView: contentView);
    }
    
    func removeTokensConsumedAlert() {
        guard let vc = self.betaAlertVC else {
            return;
        }
        self.textField?.isUserInteractionEnabled = true;
        vc.view.removeFromSuperview();
        vc.removeFromParent();
        self.aiCommand = .none;
    }
}

extension UserDefaults {
    static var aiTokensConsumed: Int {
        return UserDefaults.standard.integer(forKey: "aiTokensConsumed");
    }
    
    static func incrementAiTokenConsumed() {
        let counter = self.aiTokensConsumed + 1;
        UserDefaults.standard.set(counter, forKey: "aiTokensConsumed");
        UserDefaults.standard.synchronize();
    }
    
#if !RELEASE
    static func resetAITokens() {
        UserDefaults.standard.removeObject(forKey: "aiTokensConsumed");
    }
#endif
}

extension FTNoteshelfAIViewController: FTBarButtonItemDelegate {
    func didTapBarButtonItem(_ type: FTBarButtonItemType) {
        self.dismiss(animated: true);
    }
}
