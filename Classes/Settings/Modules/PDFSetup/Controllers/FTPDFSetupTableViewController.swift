//
//  FTPDFSetupTableViewController.swift
//  Noteshelf
//
//  Created by Paramasivan on 2/11/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import Flurry_iOS_SDK
import IntentsUI

class FTPDFSetupTableViewController: FTSettingsBaseTableViewController, FTInputCustomFontColorPickerDelegate {
    var voiceShortcut : AnyObject?
    
    @IBOutlet weak var headerTitleButton: FTStyledButton!
    @IBOutlet weak var headerTitleLabel: FTStyledLabel!
    
    @IBOutlet weak var shortcutPhrase: UILabel!
    @IBOutlet weak var addToSiriLabel: UILabel!
    
    @IBOutlet weak var setDefaultFontTableViewCell: FTSettingsTableViewCellWithSeparator!
    @IBOutlet weak var changePageTemplateTableViewCell: FTSettingsTableViewCellWithSeparator!
    @IBOutlet weak var advancedSettingsTableViewCell: FTSettingsTableViewCellWithSeparator!
    @IBOutlet weak var changePageTemplateLabel: FTStyledLabel!
    @IBOutlet weak var addToSiriShortcutCell: FTSettingsTableViewCellWithSeparator!
    
    @IBOutlet weak var switchAutoBackup: UISwitch!

    @IBOutlet weak var switchEvernote: UISwitch!
    @IBOutlet weak var passwordCellLabel:FTStyledLabel!
    @IBOutlet weak var labelHelpMessage: FTStyledLabel!
    
    @IBOutlet weak var defaultFontLabel: UILabel!
    @IBOutlet weak var passwordTableViewCell: FTSettingsTableViewCellWithSeparator!
    
    @IBOutlet weak var helpMessageSeparatorViewBottomConstraint: NSLayoutConstraint?
    @IBOutlet weak var headerTitleButtonLeadingConstraint: NSLayoutConstraint?
    @IBOutlet weak var helpMessageLabelLeadingConstraint: NSLayoutConstraint?
    
    var passwordSettingPopoverController : UIPopoverPresentationController?
    var hasBandChanged = false;
    var autoBackupEnabled = false;
    var enSyncEnabled = false;
    private var isReadOnlyPage = false;
    private var canChangePageTemplate = false;

    var changePasswordController:FTChangePasswordController?
    @IBOutlet weak var helpMessageSeparatorView: NSLayoutConstraint?
    var pinController:FTSetPasswordViewController?
    
    var shelfItem: FTShelfItemProtocol? {
        guard let splitViewController = AppDelegate.rootViewController.presentedViewController as? FTUniversalSettingsSplitViewController else {return nil}
        
        return splitViewController.notebookShelfItem;
    }
    
    //MARK:- UIViewController
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection);
        
        self.updateHeaderLayout();
    }
    func shouldAddDummyStatusBar() -> Bool{
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.rowHeight = UITableViewAutomaticDimension;
        self.tableView.estimatedRowHeight = 240;
        self.headerView?.backgroundColor = UIColor.clear
        
        self.defaultFontLabel.numberOfLines = 0
        self.defaultFontLabel.adjustsFontSizeToFitWidth = true
        self.defaultFontLabel.baselineAdjustment = .alignBaselines
        self.defaultFontLabel.layer.cornerRadius = 3.0
        self.defaultFontLabel.layer.masksToBounds = true
//        self.defaultFontLabel.layer.backgroundColor = UIColor(hexString: "fcfcfa").cgColor
        self.defaultFontLabel.layer.backgroundColor = UIColor.white.cgColor
        
        self.changePageTemplateLabel.styleText = NSLocalizedString("ChangePageTemplate", comment: "Change Page Template");
        
        if let settingsSplitController = AppDelegate.rootViewController.presentedViewController as? FTUniversalSettingsSplitViewController, let notebookDocument = settingsSplitController.notebookDocument {
            self.canChangePageTemplate = settingsSplitController.settingsDelegate?.canChangePageTemplate() ?? false;
            
            let backupItem = FTAutoBackupItem.init(URL: notebookDocument.URL, documentUUID: notebookDocument.documentUUID);
            self.autoBackupEnabled = FTCloudBackUpManager.shared().isBackupEnabled(backupItem);
            if(FTCloudBackUpManager.shared().currentBackUpCloudType() == FTCloudBackUpType.none) {
                self.autoBackupEnabled = false;
            }
            
            self.enSyncEnabled = FTENPublishManager.shared().isSyncEnabled(forDocumentUUID: notebookDocument.documentUUID);
            if nil != (notebookDocument as? FTDocument)?.pin {
                self.passwordCellLabel.styleText = NSLocalizedString("SetPassword", comment: "SetPassword")
            }
            else {
                self.passwordCellLabel.styleText = NSLocalizedString("ChangePassword", comment: "Change Password")
            }
            
            if #available(iOS 12.0, *){
                FTSiriShortcutManager.shared.getShortcutForUUID(notebookDocument.documentUUID) { (error, voiceShortcut) in
                    DispatchQueue.main.async {
                        if voiceShortcut != nil {
                            self.voiceShortcut = voiceShortcut
                            self.addToSiriLabel.text = NSLocalizedString("AddedToSiri", comment: "Added to Siri")
                            guard let invocationPhrase = voiceShortcut?.invocationPhrase else { return }
                            self.shortcutPhrase.text = "\"\(invocationPhrase)\""
                        } else {
                            self.addToSiriLabel.text = NSLocalizedString("AddToSiri", comment: "Add To Siri")
                            self.shortcutPhrase.text = ""
                        }
                    }
                }
            }
        }
        else {
            if #available(iOS 12.0, *){
                self.addToSiriLabel.text = NSLocalizedString("AddToSiri", comment: "Add To Siri")
            }
            self.isReadOnlyPage = true;
        }
        self.updateHeaderLayout();
        self.updateDisplay();
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let coverPickerContainerViewController = segue.destination as? FTThemePickerSplitViewController, let settingsSplitController = AppDelegate.rootViewController.presentedViewController as? FTUniversalSettingsSplitViewController, let settingsDelegate = settingsSplitController.settingsDelegate {
            coverPickerContainerViewController.type = .paper;
            coverPickerContainerViewController.selectedTheme = FTNThemesLibrary(libraryType: FTNThemeLibraryType.papers).getDefaultTheme(defaultMode: .QuickCreate);
            coverPickerContainerViewController.pickerDelegate = settingsDelegate;
        }
    }
    
    //MARK:- Actions
    
    @available(iOS 12.0, *)
    func addToSiri() {
        if let settingsSplitController = AppDelegate.rootViewController.presentedViewController as? FTUniversalSettingsSplitViewController,
            let notebookDocument = settingsSplitController.notebookDocument {
            if (shortcutPhrase.text?.count)! > 1 {
                let viewController = INUIEditVoiceShortcutViewController(voiceShortcut: self.voiceShortcut! as! INVoiceShortcut)
                viewController.modalPresentationStyle = .fullScreen
                viewController.delegate = self
                present(viewController, animated: true, completion: nil)
            } else {
                if let image = notebookDocument.shelfImage, let data = UIImagePNGRepresentation(image) {
                    let activity = NSUserActivity(siriShortcutActivity: .openNotebook(["coverImage" : data as AnyObject , "notebookURL" : notebookDocument.URL as AnyObject , "title" : shelfItem?.displayTitle as AnyObject , "uuid" : notebookDocument.documentUUID as AnyObject]))
                    self.userActivity = activity
                    self.userActivity!.becomeCurrent()
                    let shortcut = INShortcut(userActivity: activity)
                    let viewController = INUIAddVoiceShortcutViewController(shortcut: shortcut)
                    viewController.modalPresentationStyle = .fullScreen
                    viewController.delegate = self
                    present(viewController, animated: true, completion: nil)
                }
            }
        }
    }
    
    @IBAction override func backClicked(_ sender: AnyObject) {
        _ = self.parent?.navigationController?.popViewController(animated: true)
    }

    //AutoBackup
    @IBAction func toggleAutoBackup(_ sender: AnyObject) {
        if (!FTCloudBackUpManager.shared().activeCloudBackUpManager.isLoggedIn())
        {
            if(FTCloudBackUpManager.shared().currentBackUpCloudType() == FTCloudBackUpType.none){
                self.updateDisplay()

                UIAlertController.showSetupBackupDialog(with: NSLocalizedString("SelectBackupAccount", comment: ""), message: "", from: self, completionHandler: {
                    if let splitController:FTUniversalSettingsSplitViewController = AppDelegate.window.visibleViewController() as? FTUniversalSettingsSplitViewController{
                        splitController.mode = FTSettingsMode(rawValue: FTSettingsMode.RawValue(UInt8(FTSettingsModeDesk.rawValue) | UInt8(FTSettingsModeAutoBackupSetup.rawValue)))
                        
                        if(splitController.viewControllers.count > 0){
                            let navigationController:UINavigationController = splitController.viewControllers.first as! UINavigationController
                            if(navigationController.viewControllers.first is FTUniversalSettingsViewController){
                                (navigationController.viewControllers.first as!
                                    FTUniversalSettingsViewController).forceToOpenCloudAndBackupSettings()
                            }
                        }
                    }
                })
                return
            }

            FTCloudBackUpManager.shared().activeCloudBackUpManager.login(with: self, completionHandler: { (success : Bool) in
                if(success)
                {
                    self.toggleAutoBackup(sender);
                }else {
                    DispatchQueue.main.async(execute: {
                        self.updateDisplay()
                    })
                }
            });
            return;
        }
        self.autoBackupEnabled = !self.autoBackupEnabled;
        self.updateAutoBackUpSyncOnShelfItem();
        self.updateDisplay();
    }
    
    
    //MARK:- Custom
    private func updateHeaderLayout() {
        if self.isReadOnlyPage {
            self.labelHelpMessage.isAccessibilityElement = true;
            self.helpMessageSeparatorViewBottomConstraint?.constant = 0;
            self.labelHelpMessage.styleText = NSLocalizedString("NotebookOptionsHelp", comment: "NotebookOptionsHelp");
            var frame = self.tableView.tableHeaderView!.frame;
            frame.size.height = 190;
            if !self.view.isRegularClass() {
                frame.size.height = 130;
            }
            self.tableView.tableHeaderView!.frame = frame;

            //self.tableView.makeHeaderHeightDynamic();
        }
        else {
            self.labelHelpMessage.isAccessibilityElement = false;
            var frame = self.tableView.tableHeaderView!.frame;
            self.labelHelpMessage.styleText = "a\nb";
            self.helpMessageSeparatorViewBottomConstraint?.constant = -60;
            
            frame.size.height = 128;
            if !self.view.isRegularClass() {
                frame.size.height = 80;
            }
            self.tableView.tableHeaderView!.frame = frame;
        }
        if self.view.isRegularClass() {
            self.headerTitleLabel?.textAlignment = NSTextAlignment.left
            self.headerTitleButton?.setImage(UIImage.init(named: "popiconbackwhite"), for: UIControlState.normal)
        }
        else
        {
            self.headerTitleButton?.setImage(UIImage.init(named: "naviconBack"), for: UIControlState.normal)
            self.headerTitleLabel?.textAlignment = NSTextAlignment.center
        }
        
        self.updateDefaultFontLabel()
        
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.headerTitleButtonLeadingConstraint?.constant = 10 + self.originalSafeAreaInsets().left;
        self.helpMessageLabelLeadingConstraint?.constant = 16 + self.originalSafeAreaInsets().left
        self.updateViewConstraints()
    }
    func updateDefaultFontLabel() {
        if let settingsSplitController = AppDelegate.rootViewController.presentedViewController as? FTUniversalSettingsSplitViewController, let notebookDocument = settingsSplitController.notebookDocument {
                let font = notebookDocument.localMetadataCache?.defaultBodyFont
                if (notebookDocument.localMetadataCache?.byDefaultIsUnderline)! {
                    self.defaultFontLabel.attributedText = NSAttributedString(string: "Aa", attributes:[NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue])
                }else{
                    self.defaultFontLabel.attributedText = NSAttributedString(string: "Aa", attributes:[NSUnderlineStyleAttributeName: NSUnderlineStyle.styleNone.rawValue])
                }
                self.defaultFontLabel.font = font
                self.defaultFontLabel.textColor = notebookDocument.localMetadataCache?.defaultTextColor
        }
    }
    
    func updateDisplay() {
        //AutoBackup
        self.switchAutoBackup.isOn = self.autoBackupEnabled;

        //ENSync
        self.switchEvernote.isOn = self.enSyncEnabled;
        
        //Passcode
        if self.isPasswordEnabled() == true {
            self.passwordCellLabel.styleText = NSLocalizedString("ChangePassword", comment: "Change Password")
        }
        else {
            self.passwordCellLabel.styleText = NSLocalizedString("SetPassword", comment: "SetPassword")
        }
        
        if self.isReadOnlyPage {
            self.switchAutoBackup.isOn = false;
            self.passwordCellLabel.styleText = NSLocalizedString("SetPassword", comment: "SetPassword")
            self.switchEvernote.isOn = false;
        }
    }

    //MARK:- UITableViewDelegate
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? FTSettingsTableViewCellWithSeparator {
            if(self.isReadOnlyPage) {
                if cell == advancedSettingsTableViewCell {
                    cell.setEnable(true)
                }else{
                    cell.setEnable(false);
                }
            }
            else {
                if(cell == changePageTemplateTableViewCell) {
                    cell.setEnable(self.canChangePageTemplate);
                }
                else if cell == advancedSettingsTableViewCell {
                    cell.setEnable(true)
                }
                else if let shelfCollection = self.shelfItem?.shelfCollection, shelfCollection.collectionType != .migrated || cell == passwordTableViewCell {
                    cell.setEnable(true);
                }
                else {
                    cell.setEnable(false);
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension;
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        var numberOfSections = 3;
        if #available(iOS 12.0, *) {
            numberOfSections = 4
        }
        return numberOfSections;
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(section == 3) {
            if #available(iOS 12.0, *) {
                return 1;
            }
            return 0;
        }
        if(section == 2) {
            return 3;
        }
        return 1;
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            showFontStyleView()
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
        if indexPath.row == 2 {
            FTNotebookUtils.checkIfAudioIsPlayingShowMessage(NSLocalizedString("AudioRecoring_Progress_Message", comment: ""), onCompletion: { (success) in
                if success {
                    self.handlePasswordModifyRequest()
                }
            });
        }
        if(indexPath.section == 3) {
            let siriStatus = INPreferences.siriAuthorizationStatus()
            if siriStatus == .authorized {
                if #available(iOS 12.0, *) {
                    addToSiri()
                } else {
                    // Fallback on earlier versions
                }
            }
            else if siriStatus == .notDetermined {
                INPreferences.requestSiriAuthorization { (status) in
                    if status == .authorized{
                        if #available(iOS 12.0, *) {
                            self.addToSiri()
                        } else {
                            // Fallback on earlier versions
                        }
                    }
                }
            }else {
                let message = String.init(format: NSLocalizedString("SiriPermissionPopupMsg", comment: "Please allow to access..."), applicationName()!, applicationName()!);
                UIAlertController.showAlert(withTitle: "", message: message, from: self, withCompletionHandler: nil)
            }
            
        }
    }

    //MARK:- show font style controller
    func showFontStyleView() {
        if let settingsSplitController = AppDelegate.rootViewController.presentedViewController as? FTUniversalSettingsSplitViewController, let notebookDocument = settingsSplitController.notebookDocument {
            let font = notebookDocument.localMetadataCache?.defaultBodyFont
            let customFontManager = FTCustomFontManager.init()
            customFontManager.customFontInfo.displayName = (font?.familyName)!
            customFontManager.customFontInfo.fontName = (font?.familyName)!
            customFontManager.customFontInfo.fontStyle = (font?.fontName)!
            customFontManager.customFontInfo.fontSize = (font?.pointSize)!
            customFontManager.customFontInfo.isBold = (font?.isBoldTrait())!
            customFontManager.customFontInfo.isItalic = (font?.isItalicTrait())!
            customFontManager.customFontInfo.textColor = (notebookDocument.localMetadataCache?.defaultTextColor)!
            customFontManager.customFontInfo.isUnderlined = (notebookDocument.localMetadataCache?.byDefaultIsUnderline)!
            let controller = FTInputCustomFontViewController.showAsPopover(fromViewController: self, withSourceView: setDefaultFontTableViewCell, withFontManager: customFontManager, withDelegate: self, arrowDirection: .up) as? FTInputCustomFontViewController
            controller?.isSettingDefaultFont = true
        }
    }
    
    func didClosePopOver(_ picker : FTInputCustomFontViewController) {
        let defaultFont : UIFont = UIFont.init(name: picker.customFontManager.customFontInfo.fontStyle, size: picker.customFontManager.customFontInfo.fontSize)!
        if let settingsSplitController = AppDelegate.rootViewController.presentedViewController as? FTUniversalSettingsSplitViewController, let notebookDocument = settingsSplitController.notebookDocument {
            notebookDocument.localMetadataCache?.defaultBodyFont = defaultFont
            notebookDocument.localMetadataCache?.defaultTextColor = picker.customFontManager.customFontInfo.textColor
            notebookDocument.localMetadataCache?.byDefaultIsUnderline = picker.customFontManager.customFontInfo.isUnderlined
            notebookDocument.save { (result) in
                self.updateDefaultFontLabel()
            }
        }
    }
    
    fileprivate func updateAutoBackUpSyncOnShelfItem()
    {
        if(nil == self.shelfItem) {
            FTUtils.cls_Log_Swift("shelf item not found");
            return;
        }
        let documentItem = self.shelfItem as! FTDocumentItemProtocol;
        
        let autoBackupItem = FTAutoBackupItem.init(URL: documentItem.URL, documentUUID: documentItem.documentUUID!);
        let autoBackupEnabled = FTCloudBackUpManager.shared().isBackupEnabled(autoBackupItem);
        if (!autoBackupEnabled && self.autoBackupEnabled)
        {
            FTCloudBackUpManager.shared().shelfItemDidGetAdded(autoBackupItem);
        }
        else if(autoBackupEnabled && !self.autoBackupEnabled)
        {
            FTCloudBackUpManager.shared().shelfItemDidGetDeleted(autoBackupItem);
        }
    }
    
    //MARK:- ENSync
    @IBAction func toggleEvernoteSync() {
        guard let localShelfItem = self.shelfItem as? FTDocumentItemProtocol else {
            FTUtils.cls_Log_Swift("shelf item not found");
            return;
        }
        let evernotePublishManager = FTENPublishManager.shared()!;
        evernotePublishManager.checkENSyncPrerequisite(from: self) { (success) in
            if success {
                let documentItemProtocol = localShelfItem ;
                let documentUUID = documentItemProtocol.documentUUID!;
                if evernotePublishManager.isSyncEnabled(forDocumentUUID: documentItemProtocol.documentUUID!) {
                    FTENPublishManager.recordSyncLog("User disabled Sync for notebook \(documentUUID)");
                    self.enSyncEnabled = false;
                    self.updateDisplay();
                    evernotePublishManager.disableSync(for: documentItemProtocol);
                    evernotePublishManager.disableBackupForShelfItem(withUUID: documentUUID);
                }
                else {
                    FTENPublishManager.recordSyncLog("User enabled Sync for notebook: \(documentUUID)");
                    evernotePublishManager.showAccountChooser(self, withCompletionHandler: { (accountType) in
                        if accountType != EvernoteAccountUnknown {
                            self.enSyncEnabled = true;
                            self.updateDisplay();
                            
                            if let settingsSplitController = AppDelegate.rootViewController.presentedViewController as? FTUniversalSettingsSplitViewController, let notebookDoc:FTDocument = settingsSplitController.notebookDocument as? FTDocument {
                                if nil != notebookDoc.pin {
                                    let uuid = settingsSplitController.notebookDocument!.documentUUID
                                    FTDocument.keychainSet(notebookDoc.pin!, forKey: uuid)
                                }
                            }
                            
                            evernotePublishManager.enableSync(for: documentItemProtocol);
                            evernotePublishManager.updateSyncRecord(forShelfItem: localShelfItem, withDocumentUUID: documentUUID);
                            evernotePublishManager.updateSyncRecord(forShelfItemAtURL: localShelfItem.URL, withDeleteOption: true, andAccountType: accountType);
                        }
                    });
                }
            }
        }
    }
    
    //MARK:- Password protection
     fileprivate func isPasswordEnabled() -> Bool {
        if let settingsSplitController = AppDelegate.rootViewController.presentedViewController as? FTUniversalSettingsSplitViewController, let notebookDocument = settingsSplitController.notebookDocument as? FTDocument {
            if (notebookDocument.pin != nil) {
                return true
            }
        }
        return false
    }
}


@available(iOS 12.0, *)
extension FTPDFSetupTableViewController: INUIAddVoiceShortcutViewControllerDelegate {
    
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController,
                                        didFinishWith voiceShortcut: INVoiceShortcut?,
                                        error: Error?) {
        if let error = error as NSError? {
            print("error : addVoiceShortcutViewController : \(error.debugDescription)")
        }else{
            Flurry.logEvent("Siri Shortcut", withParameters: ["type" : "Shortcut To Open Notbook"])
            self.voiceShortcut = voiceShortcut
            guard let invocationPhrase = voiceShortcut?.invocationPhrase else { return }
            self.shortcutPhrase.text = "\"\(invocationPhrase)\""
            addToSiriLabel.text = NSLocalizedString("AddedToSiri", comment: "Added to Siri")
        }
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

@available(iOS 12.0, *)
extension FTPDFSetupTableViewController: INUIEditVoiceShortcutViewControllerDelegate {
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController,
                                         didUpdate voiceShortcut: INVoiceShortcut?,
                                         error: Error?) {
        if let error = error as NSError? {
            print("error : addVoiceShortcutViewController : \(error.debugDescription)")
        }else{
            self.voiceShortcut = voiceShortcut
            guard let invocationPhrase = voiceShortcut?.invocationPhrase else { return }
            self.shortcutPhrase.text = "\"\(invocationPhrase)\""
            addToSiriLabel.text = NSLocalizedString("AddedToSiri", comment: "Added to Siri")
        }
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController,
                                         didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        self.voiceShortcut = nil
        addToSiriLabel.text = NSLocalizedString("AddToSiri", comment: "Add To Siri");
        shortcutPhrase.text = ""
        controller.dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}
