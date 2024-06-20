//
//  FTNoteshelfAIViewController.swift
//  Sample AI
//
//  Created by Amar Udupa on 31/07/23.
//

import UIKit
import Combine
import FTCommon

class FTNoteshelfAI {
    static var supportsNoteshelfAI: Bool {
        if !FTFeatureConfigHelper.shared.isFeatureEnabled(.Noteshelf_AI) {
            return false
        }
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
    func noteshelfAIController(_ ccntroller: FTNoteshelfAIViewController
                               ,didTapOnAction: FTNotesehlfAIAction
                               ,content: FTAIContent);
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

class FTPageContent: NSObject {
    var writtenContent: String = "" {
        didSet {
            let trimmedText = writtenContent.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
            if writtenContent != trimmedText {
                writtenContent = trimmedText;
            }
        }
    }
    var pdfContent: String = "" {
        didSet {
            let trimmedText = pdfContent.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
            if pdfContent != trimmedText {
                pdfContent = trimmedText;
            }
        }
    }
    var textContent: String = "" {
        didSet {
            let trimmedText = textContent.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
            if textContent != trimmedText {
                textContent = trimmedText;
            }
        }
    }
    
    var content: String {
        var contents = [String]();
        if !pdfContent.isEmpty {
            contents.append(pdfContent)
        }
        
        if !textContent.isEmpty {
            contents.append(textContent)
        }
        
        if !writtenContent.isEmpty {
            contents.append(writtenContent)
        }
        return contents.joined(separator: " ");
    }
    
    var nonPDFContent: String {
        var contents = [String]();
        if !textContent.isEmpty {
            contents.append(textContent)
        }

        if !writtenContent.isEmpty {
            contents.append(writtenContent)
        }
        return contents.joined(separator: " ");
    }
}

class FTNoteshelfAIViewController: UIViewController {
    private var currentToken : String = UUID().uuidString

    public static var maxAllowedTokenCounter = 100;
    
    @IBOutlet private weak var footerHeightConstraint: NSLayoutConstraint?;

    @IBOutlet private weak var textField: UITextField?;
    @IBOutlet private weak var textView: UITextView?;
    @IBOutlet private weak var contentView: UIView?;
    @IBOutlet private weak var footerView: UIView?;
    var premiumCancellableEvent: AnyCancellable?;

    private weak var delegate: FTNoteshelfAIDelegate?;
    
    private weak var footerVC: FTNoteshelfAIFooterViewController?;
    private weak var betaAlertVC: FTNoteshelfAITokensConsumedAlertViewController?;

    private var userInputInProgess = false;
    private var content = FTPageContent();
    private var enteredContent: String = "";
    
    @IBOutlet private weak var creditsContainerView: UIView?;
    @IBOutlet private weak var creditsContainerViewHeightConstraint: NSLayoutConstraint?;
    @IBOutlet private weak var creditsContainerViewBottomConstraint: NSLayoutConstraint?;

    private weak var creditsController: UIViewController?;

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
        FTOpenAI.shared.cancelCurrentExecution();
        self.textField?.text = "";
        languageCode = "";
        self.enteredContent = "";
    }
        
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange();
    }
    static func showNoteshelfAI(from presentingController:UIViewController
                                , content:FTPageContent
                                ,delegate: FTNoteshelfAIDelegate?, animated: Bool = true) {
        guard let controller = UIStoryboard.instantiateAIViewController(withIdentifier: "FTNoteshelfAIViewController") as? FTNoteshelfAIViewController else {
            fatalError("ERROR!!!!");
        }
        controller.content = content;
        controller.delegate = delegate;
        let navController = UINavigationController(rootViewController: controller);
        presentingController.ftPresentFormsheet(vcToPresent: navController, contentSize: CGSize(width: 500, height: 508),animated: animated, hideNavBar: false)
        
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        FTNoteshelfAITokenManager.shared.refreshTokenInfo();
        self.title = "noteshelf.ai.noteshelfAI".aiLocalizedString;
        let doneButton = FTNavBarButtonItem(type: .right, title: "Done".localized, delegate: self);
        self.navigationItem.rightBarButtonItem = doneButton;
#if DEBUG ||  BETA
        self.addDebugCommandButton();
#endif
        updateContentView();
        for eachController in children {
            if let controller = eachController as? FTNoteshelfAIFooterViewController {
                footerVC = controller;
                break;
            }
        }
        self.creditsContainerView?.layer.cornerRadius = 12;
        self.updateFooterHeight();
        if !FTIAPManager.shared.premiumUser.isPremiumUser {
            premiumCancellableEvent = FTIAPManager.shared.premiumUser.$isPremiumUser.sink { [weak self] isPremium in
                self?.updateFooterHeight();
                self?.addCredtisFooter();
            }
        }
        else {
            self.addCredtisFooter();
        }
    }

    deinit{
        FTOpenAI.shared.cancelCurrentExecution();
        self.premiumCancellableEvent?.cancel();
        self.premiumCancellableEvent = nil;
    }

    private func updateFooterHeight() {
        var footerHeight: CGFloat = 16;
        if let mode = self.footerVC?.footermode,mode != .noFooter {
            footerHeight =  48;
        }
        self.footerHeightConstraint?.constant = footerHeight;
        self.view.layoutIfNeeded()
    }
    
    private func setFooterMode(_ mode: FTAIFooterMode) {
        self.footerVC?.footermode = mode;
        self.updateFooterHeight();
    }
    
    private func updateContentView() {
        guard let contentView = self.contentView else {
            return;
        }
        
        var controller: UIViewController?;
        
        self.textField?.placeholder = self.aiCommand.placeholderMessage;
        let allTokensConsumed = allTokensConsumed;
        self.setFooterMode(allTokensConsumed ? .sendFeedback : .noteshelfAiBeta);

        let enteredText = self.textField?.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) ?? "";
        
        self.creditsContainerViewHeightConstraint?.constant = FTIAPManager.shared.premiumUser.isPremiumUser ? 74 : 142;
        var bottomConstraint: CGFloat = (self.creditsContainerViewHeightConstraint?.constant ?? 0) * -1;
        if aiCommand == .none {
            self.reset();
            bottomConstraint = 0;
            controller = UIStoryboard.instantiateAIViewController(withIdentifier: FTNoteshelfAIOptionsViewController.className);
            (controller as? FTNoteshelfAIOptionsViewController)?.delegate = self;
            (controller as? FTNoteshelfAIOptionsViewController)?.content = self.content;
            (controller as? FTNoteshelfAIOptionsViewController)?.isAllTokensConsumend = allTokensConsumed;
        }
        else if aiCommand == .langTranslate
                    , let txtField = self.textField
                    , languageCode.isEmpty
                    , !(txtField.isFirstResponder && !enteredText.isEmpty) {
            self.reset();
            controller = UIStoryboard.instantiateAIViewController(withIdentifier: FTNoteshelfAITranslateViewController.className);
            (controller as? FTNoteshelfAITranslateViewController)?.delegate = self;
        }
        else {
            controller = UIStoryboard.instantiateAIViewController(withIdentifier: FTNoteshelfAITextViewViewController.className);
            (controller as? FTNoteshelfAITextViewViewController)?.delegate = self;
        }
        
        self.creditsContainerViewBottomConstraint?.constant = bottomConstraint
        self.creditsContainerView?.isHidden = aiCommand != .none;
        
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
        if aiCommand == .generalQuestion || (aiCommand == .langTranslate
                                             && ((self.textField?.isFirstResponder ?? false) && !enteredText.isEmpty)) {
            self.textViewController?.showPlaceHolder("noteshelf.ai.pressEnterToSend".aiLocalizedString);
        }
        self.textField?.isUserInteractionEnabled = !allTokensConsumed;
        self.textField?.alpha = allTokensConsumed ? 0.6: 1;
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
    func textViewController(_ controller: FTNoteshelfAITextViewViewController, didSelectOption action: FTNotesehlfAIAction,content: FTAIContent) {
        if action == .regenerateResponse {
            self.executeAIAction();
        }
        else if action == .semdFeedback {
            FTZenDeskManager.shared.showSupportContactUsScreen(controller: self
                                                               , defaultSubject: "Noteshelf-AI Feedback"
                                                               , extraTags: ["Noteshelf-AI"]);
        }
        else {
            FTNoteshelfAITokenManager.shared.markAsConsumed();
            self.delegate?.noteshelfAIController(self, didTapOnAction: action, content: content)
        }
    }
}


extension FTNoteshelfAIViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if self.aiCommand == .langTranslate, self.contentToExecute.isEmpty {
            self.aiCommand = .generalQuestion;
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.textFieldDidChange(_:)), name: UITextField.textDidChangeNotification, object: textField);
    }
    
    @objc func textFieldDidChange(_ name: Notification) {
        if self.textField?.text?.isEmpty ?? false {
            self.aiCommand = .none;
        }
        else if self.aiCommand != .langTranslate {
            self.aiCommand = .generalQuestion;
        }
        else {
            self.updateContentView();
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        return true;
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.aiCommand = .none;
        return true;
    }
        
    func textFieldDidEndEditing(_ textField: UITextField) {
        NotificationCenter.default.removeObserver(self, name: UITextField.textDidChangeNotification, object: textField);
        
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
#if DEBUG
        return false;
#else
        return FTNoteshelfAITokenManager.shared.tokensLeft == 0;
#endif
    }
    
    func canExecuteAIAction() -> Bool {
        guard aiCommand != .none else {
            return false;
        }
        
        guard !self.contentToExecute.isEmpty else {
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
        
        let command = FTAICommand.command(for: self.aiCommand, content: content, enteredContent: self.enteredContent)
        (command as? FTAITranslateCommand)?.languageCode = languageCode;
        
        self.textField?.text = command.executionMessage;
        
        currentToken = command.commandToken;
        FTOpenAI.shared.execute(command: command) {[weak self] (response, error,token) in
            guard nil != self, let curToken = self?.currentToken, curToken == token else {
                return;
            }
            if let inerror = error {
                track("AI Error", params: ["detail":inerror.localizedDescription], screenName: nil)
                self?.textViewController?.showPlaceHolder("noteshelf.ai.noteshelfAIError".aiLocalizedString);
            }
            else {
                self?.textViewController?.showResponse(response);
            }
        } onCompletion: { [weak self] (error,token) in
            guard nil != self, let curToken = self?.currentToken, curToken == token else {
                return;
            }
            if let inerror = error as? NSError {
                track("AI Error", params: ["detail":inerror.localizedDescription], screenName: nil)
                if FTOPenAIError.isNoInternetConnectionError(inerror) {
                    self?.textViewController?.showPlaceHolder(inerror.localizedDescription);
                }
                else {
                    self?.textViewController?.showPlaceHolder("noteshelf.ai.noteshelfAIError".aiLocalizedString);
                }
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
            self?.setFooterMode(.noFooter);
        }
    }
    
    var textViewController: FTNoteshelfAITextViewViewController? {
        return self.optionsController as? FTNoteshelfAITextViewViewController
    }
    
    var contentToExecute: String {
        if aiCommand == .generalQuestion {
            return self.content.content.appending(" \(self.enteredContent)");
        }
        if aiCommand != .langTranslate {
            if !self.enteredContent.isEmpty {
                return self.enteredContent;
            }
        }
        return self.content.content;
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

extension FTNoteshelfAIViewController: FTBarButtonItemDelegate {
    func didTapBarButtonItem(_ type: FTBarButtonItemType) {
        self.dismiss(animated: true);
    }
}

private extension FTNoteshelfAIViewController {
    func addCredtisFooter() {
        self.removeCreditsFooter();
        
        guard let creditsView = self.creditsContainerView else {
            return;
        }
        var controller: UIViewController;
        if FTIAPManager.shared.premiumUser.isPremiumUser {
            controller = UIStoryboard.instantiateAIViewController(withIdentifier: "FTNoteshelfAIPremiumUserCreditsViewController");
        }
        else {
            controller = UIStoryboard.instantiateAIViewController(withIdentifier: "FTNoteshelfAIFreeUserCreditsViewController");
        }
        self.addChild(controller);
        self.creditsController = controller;
        controller.view.frame = creditsView.bounds;
        controller.view.addFullConstraints(creditsView);
    }
    
    func removeCreditsFooter() {
        self.creditsController?.view.removeFromSuperview();
        self.creditsController?.removeFromParent();
    }
}
