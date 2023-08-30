//
//  FTAccountsTableViewController.swift
//  Noteshelf
//
//  Created by Paramasivan on 4/11/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles
import FTDocumentFramework
import GoogleAPIClientForREST_Drive
import GoogleSignIn
import FTCommon

protocol FTAccountActivityDelegate : AnyObject {
    func accountDidLogout(_ account: FTAccount, fromViewController viewController: UIViewController)
}

enum FTAutoBackUpSection: String {
    case autoBackUpNotebooks
    case backUpTo
    case notebooks
    
    func localized() -> String {
        let title: String
        switch self {
        case .autoBackUpNotebooks:
            title =  "AutoBackupNotebooks"
        case .backUpTo:
            title = "BackUpTo"
        case .notebooks:
            title = "Notebooks"
        }
        return title.localized
    }
}

class FTAccountsViewController: FTCloudBackUpViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView?

    let autoBackUpNotes: String = FTAutoBackUpSection.autoBackUpNotebooks.localized()

    private var isAutoBackUpOn: Bool = false {
        didSet {
            if let footer = self.tableView?.footerView(forSection: 1) as? FTBackupFooterView {
                if isAutoBackUpOn {
                    footer.isHidden = false
                    footer.infoView.isHidden = true
                    footer.errorInfoBtn.isHidden = true
                    footer.activityIndicator.isHidden = false
                    if self.checkIfIgnoredItemsExists() {
                        footer.errorInfoBtn.isHidden = false
                    }
                    self.updateBackUpInfoIfLoggedIn()
                } else {
                    footer.isHidden = true
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.isAutoBackUpOn = false
        self.tableView?.register(UINib(nibName: FTSettingsCommonTableViewCell.className, bundle: nil), forCellReuseIdentifier: FTSettingsCommonTableViewCell.className)
        self.tableView?.delegate = self
        self.tableView?.dataSource = self
        self.tableView?.rowHeight = UITableView.automaticDimension
        self.view.backgroundColor = UIColor.appColor(.formSheetBgColor)
        self.tableView?.separatorColor = UIColor.appColor(.black10)
    }
    
    func shouldAddDummyStatusBar() -> Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureNewNavigationBar(hideDoneButton: false, title: NSLocalizedString(FTSettingsOptions.cloudAndBackup.rawValue, comment: ""))
        runInMainThread(0.1) {
            if self.getCloudBackupIfAny() != "" {
                self.isAutoBackUpOn = true
            } else {
                self.isAutoBackUpOn = false
            }
            self.tableView?.reloadData()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let footerView = self.tableView?.tableFooterView else {
            return
        }
        if let width = self.tableView?.bounds.size.width {
            let size = footerView.systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height))
            if footerView.frame.size.height != size.height {
                footerView.frame.size.height = size.height
                tableView?.tableFooterView = footerView
            }
        }
    }
    
    private func isAutoBackUpEnabled() -> Bool {
        if FTCloudBackUpManager.shared.isCloudBackupEnabled() {
            return true
        }
        return false
    }
    
    // MARK: - Manage iCloud
    @objc
    func toggleiCloudSwitch(_ icloudSwitch: UISwitch) {
        let wasiCloudOn = FTUserDefaults.defaults().bool(forKey: "iCloudOn");
        if !wasiCloudOn && (nil == FileManager().ubiquityIdentityToken) {
            icloudSwitch.setOn(!wasiCloudOn, animated: true);
            
            let title = NSLocalizedString("iCloudNotAvailable", comment: "iCloud is not Available");
            #if !targetEnvironment(macCatalyst)
            let message = String(format: NSLocalizedString("iCloudNotAvailableInfo", comment: "Please allow to access..."), applicationName()!);
            #else
            let message = String(format: NSLocalizedString("iCloudNotAvailableInfo-Mac", comment: "Please allow to access..."), applicationName()!);
            #endif
            
            UIAlertController.showAlert(withTitle: title ,
                                        message: message,
                                        from: self,
                                        withCompletionHandler: { [weak self] in
                                            self?.tableView?.reloadData()
            });
        } else {
            self.navigationController?.dismiss(animated: true, completion: {
                FTiCloudManager.shared().setiCloud(on: !wasiCloudOn);
            });
        }
    }
    
    @objc func toggleBackupSwitch(_ backupSwitch: UISwitch) {
        if backupSwitch.isOn {
            self.performSegue(withIdentifier: "showBackupOptionsSegue", sender: nil)
        } else {
            if let account = self.fetchLoggedInAccount() {
                self.logout(account: account) { _ in
                    FTCloudBackUpManager.shared.setEnableCloudBackUp(false)
                    self.isAutoBackUpOn = false
                    self.tableView?.reloadData()
                }
            }
        }
    }
    
    // MARK: - UITableViewDelegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numRows = 0
        if section == 0 {
            numRows = 1
        } else if section == 1 {
            numRows = self.isAutoBackUpEnabled() ? 3 : 1
        } else if section == 2 {
#if targetEnvironment(macCatalyst)
            numRows = 1;
#else
            numRows = 2
#endif
        } else if section == 3{
            numRows = 1
        }
        return numRows
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cellIdentifier = cellIdentifierForIndexpath(indexPath)
        if cellIdentifier == CellIdentifiers.evernotePublish.rawValue {
            performEvernoteSegue(withIdentifier: "Accounts_to_EvernoteSettingsPublish", sender: tableView.cellForRow(at: IndexPath(item: 0, section: 2)))
        } else if cellIdentifier == CellIdentifiers.exportData.rawValue {//Local back up export data
            track("Shelf_Settings_Cloud_Backup_ExportData", params: [:], screenName: FTScreenNames.shelfSettings)
        } else if cellIdentifier == CellIdentifiers.backUpOptions.rawValue {
            track("Shelf_Settings_Cloud_Backup_DriveOption", params: [:], screenName: FTScreenNames.shelfSettings)
            self.performSegue(withIdentifier: "showBackupOptionsSegue", sender: nil)
        }else if cellIdentifier == CellIdentifiers.backUpFormatOptions.rawValue {
            track("Shelf_Settings_Cloud_Backup_Drive_Format_Option", params: [:], screenName: FTScreenNames.shelfSettings)
        } else if cellIdentifier == CellIdentifiers.notebooks.rawValue {
            track("Shelf_Settings_Cloud_Backup_NotebooksOption", params: [:], screenName: FTScreenNames.shelfSettings)
            self.performSegue(withIdentifier: "NotebooksToBackUpSegue", sender: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1{
            return backUpCellForIndexPath(indexPath)
        }else{
            let cellIdentifier = cellIdentifierForIndexpath(indexPath)
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? FTSettingsBaseTableViewCell else {
                fatalError("Programmer error - couldnot find FTSettingsBaseTableViewCell")
            }
            cell.labelTitle?.fontStyle = FTSettingFontStyle.leftOption.rawValue
            if indexPath.section == 0{
                cell.switch?.isOn = FTUserDefaults.defaults().bool(forKey: "iCloudOn")
                cell.switch?.addTarget(self, action: #selector(FTAccountsViewController.toggleiCloudSwitch(_:)), for: .valueChanged)
            }else if indexPath.section == 2 {
                if cellIdentifier == CellIdentifiers.evernotePublish.rawValue {
                    let accountInfoRequest = FTAccountInfoRequest.accountInfoRequestForType(.evernote);
                    let isLoggedIn = accountInfoRequest.isLoggedIn()
                    if !isLoggedIn {
                        cell.accessoryImageView.isHidden = true
                    } else {
                        cell.accessoryImageView.isHidden = false
                    }
                }else{
                    //Nothing to do for the local backup cell
                }
            }else if indexPath.section == 3{
                if cellIdentifier == CellIdentifiers.backUpOnWifi.rawValue{
                    cell.switch?.isOn = true
                    cell.switch?.addTarget(self, action: #selector(FTAccountsViewController.toggleBackupOnWiFiOnly(_:)), for: .valueChanged)
                }
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionHeaderView = FTTableHeaderView(frame: CGRect.zero);
        if section == 0 {
            sectionHeaderView.headerLabel?.text = "shelf.settings.SYNC".localized
        } else if section == 1 {
            sectionHeaderView.headerLabel?.text = "shelf.settings.BACKUP".localized
        }else if section == 2{
            sectionHeaderView.headerLabel?.text = "shelf.settings.EXPORT & PUBLISH".localized
        }
        return sectionHeaderView
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if isAutoBackUpEnabled() && section == 1 {
            guard let footerView = Bundle.main.loadNibNamed("FTBackupFooterView", owner: nil, options: nil)?.first as? FTBackupFooterView else {
                return nil
            }
            footerView.setBackupFormat(FTUserDefaults.backupFormat)
            footerView.isHidden = !self.isAutoBackUpOn
            footerView.infoView.backgroundColor = UIColor.appColor(.cellBackgroundColor)
            return footerView
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 3 {
            return 11.0
        } else {
#if targetEnvironment(macCatalyst)
            if section == 0 {
                return  FTGlobalSettingsController.macCatalystTopInset + 20;
            }
#endif             
            return 20.0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        var heightRequired: CGFloat = 16
        if section == 1 {
            let verticalSpace: CGFloat = 16.0
            if isAutoBackUpEnabled() {
                heightRequired = 50.0 // default height
                if let _ = self.fetchLoggedInAccount() {
                    heightRequired += 70.0 + verticalSpace // to show login info
                }
                let errorMsg = self.getBackuperrorMessage()
                if !errorMsg.isEmpty {
                    heightRequired += errorMsg.sizeWithFont(UIFont.appFont(for: .regular, with: 15)).height + verticalSpace
                } else {
                    heightRequired += verticalSpace
                }
                if FTUserDefaults.backupFormat != .noteshelf {
                    heightRequired += FTBackupFooterView.warning_View_Height;
                }
            }
            if self.checkIfIgnoredItemsExists() { // to show more info button
                heightRequired += 44.0 + verticalSpace // height of more info button 44
            }
        }
        return heightRequired
   }
    private func backUpCellForIndexPath(_ indexPath: IndexPath) -> FTSettingsBaseTableViewCell {
        let cellid = self.cellIdentifierForIndexpath(indexPath)
        guard let cell = self.tableView?.dequeueReusableCell(withIdentifier: cellid, for: indexPath) as? FTSettingsBaseTableViewCell else {
            fatalError("Programmer error - Couldnot find FTSettingsBaseTableViewCell")
        }
        var text = autoBackUpNotes
        if isAutoBackUpEnabled() {
            switch cellid {
            case CellIdentifiers.backUp.rawValue:
                text = autoBackUpNotes
                cell.switch?.isOn = true
                self.isAutoBackUpOn = true
            case CellIdentifiers.backUpOptions.rawValue:
                text = FTAutoBackUpSection.backUpTo.localized()
                cell.rightSideDetailLabel?.text = self.getBackUpLocation()
                cell.backUpOptionImageview.image = self.getCloudBackupIcon()
                cell.rightSideDetailLabel?.addCharacterSpacing(kernValue: -0.41)
            case CellIdentifiers.backUpFormatOptions.rawValue:
                if let formatCell = cell as? FTSettingsBackupFormatTableViewCell {
                    formatCell.delegate = self;
                }
            case CellIdentifiers.notebooks.rawValue:
                text = FTAutoBackUpSection.notebooks.localized()
                self.updateBackUpFraction(cell: cell)
            case CellIdentifiers.backUpOnWifi.rawValue:
                cell.switch?.isOn = FTCloudBackUpManager.shared.isCloudBackupOverWifiOnly()
                cell.switch?.addTarget(self, action: #selector(toggleBackupOnWiFiOnly(_:)), for: .valueChanged)
            default:
                break
            }
        } else {
            cell.switch?.isOn = false
        }
        if indexPath.row == 0 {
            cell.switch?.addTarget(self, action: #selector(FTAccountsViewController.toggleBackupSwitch(_:)), for: .valueChanged)
        }
        (cell as? FTSettingsCommonTableViewCell)?.populateCell(image: nil, name: text, showLinkView: false)
        return cell
    }
    
    private func updateBackUpFraction(cell: FTSettingsBaseTableViewCell) {
        let noteBooksBackedUp = FTCloudBackUpManager.shared.fetchCloudBackUpItemsCount()
        let options = FTFetchShelfItemOptions()
        cell.labelSubTitle?.text = ""
        FTNoteshelfDocumentProvider.shared.fetchAllShelfItems(option: options) { shelfItems in
            cell.labelSubTitle?.text = String(format: "%d/%d %@", noteBooksBackedUp, shelfItems.count, NSLocalizedString("Notebooks", comment: "Notebooks"))
            cell.labelSubTitle?.addCharacterSpacing(kernValue: -0.41)
            cell.labelSubTitle?.textColor = noteBooksBackedUp == 0 ? UIColor(hexString: "CC4235") : UIColor.appColor(.black50)
            cell.labelSubTitle?.font = UIFont.appFont(for: .regular, with: 17)
        }
    }
    
    private func updateBackUpInfoIfLoggedIn()  {
        if let account = self.fetchLoggedInAccount() {
                let accountInfoRequest = FTAccountInfoRequest.accountInfoRequestForType(account)
                accountInfoRequest.accountInfo(onUpdate: { _ in
                }, onCompletion: { accountInfo, error in
                    runInMainThread {
                        let paragraphStyle = NSMutableParagraphStyle.init()
                        paragraphStyle.lineSpacing = 4
                        paragraphStyle.alignment = .center
                        let regularAttributes = [NSAttributedString.Key.font: UIFont.appFont(for: .medium, with: 15), NSAttributedString.Key.foregroundColor: UIColor.appColor(.black1),.paragraphStyle:paragraphStyle]
                        let userNameAttributes = [NSAttributedString.Key.font: UIFont.appFont(for: .regular, with: 15), NSAttributedString.Key.foregroundColor: UIColor.appColor(.black50),.paragraphStyle:paragraphStyle]
                        if(error == nil) {
                            let semiBoldAttributes = [NSAttributedString.Key.font: UIFont.appFont(for: .medium, with: 15), NSAttributedString.Key.foregroundColor: UIColor.appColor(.black1)]
                            let newLineString = NSAttributedString(string: "\n")
                            let spaceString = NSAttributedString(string: " ")

                            if account == FTAccount.webdav {
                                let mutableAttributedString = NSMutableAttributedString(string: String(format:NSLocalizedString("LoggedInAs", comment: "Logged in as"), accountInfo.usernameFormatString()) , attributes:regularAttributes)
                                let range = (String(format:NSLocalizedString("LoggedInAs", comment: "Logged in as"), accountInfo.usernameFormatString()) as NSString).range(of: accountInfo.usernameFormatString(), options: .caseInsensitive)
                                mutableAttributedString.addAttributes(semiBoldAttributes, range: range)
                                let learnmoreAttributedText = NSAttributedString(string: String(format: NSLocalizedString("ConnectedThrough", comment: "Connected through.."), (accountInfo.serverAddress ?? "")), attributes: regularAttributes)
                                mutableAttributedString.append(newLineString)
                                mutableAttributedString.append(learnmoreAttributedText)
                                self.updateFooterViewIfNeeded(attributedText: mutableAttributedString, progressPercent: accountInfo.percentage)
                            } else {
                                let mutableAttributedtext = NSMutableAttributedString(string: accountInfo.spaceUsedFormatString(), attributes: regularAttributes)
                                let cloudBackupAttributesText = NSMutableAttributedString(string: self.getCloudBackupIfAny(), attributes: semiBoldAttributes)
                                let usernameAttributesText = NSMutableAttributedString(string: accountInfo.usernameFormatString(), attributes: userNameAttributes)
                                let lastBackUpAttributedText = self.getLastBackUpMessage()
                                mutableAttributedtext.append(spaceString)
                                mutableAttributedtext.append(cloudBackupAttributesText)
                                mutableAttributedtext.append(newLineString)
                                mutableAttributedtext.append(usernameAttributesText)
                                mutableAttributedtext.append(newLineString)
                                mutableAttributedtext.append(lastBackUpAttributedText)
                                self.updateFooterViewIfNeeded(attributedText: mutableAttributedtext, progressPercent: accountInfo.percentage)
                            }
                        } else {
                            self.updateFooterViewIfNeeded(attributedText: NSMutableAttributedString(string: error?.localizedDescription ?? "Error", attributes: regularAttributes), progressPercent: 0)
                        }
                    }
                })
        }
    }

    private func checkIfIgnoredItemsExists() -> Bool {
        var status = false
        if let ignoredNotebooks = FTCloudBackUpManager.shared.activeCloudBackUpManager?.ignoreList.ignoredItemsForUIDisplay(), !ignoredNotebooks.isEmpty {
            status = true
        }
        return status
    }

    private func getBackuperrorMessage() -> String {
        guard let lastBackupError = UserDefaults.standard.object(forKey: BACKUP_ERROR) as? String else {
            return ""
        }
        return lastBackupError
    }
    
    private func getLastBackUpMessage() -> NSMutableAttributedString {
        let standardUserDefaults = UserDefaults.standard
        var lastBackUpMessage: String = ""
        if let lastPublishTime = standardUserDefaults.object(forKey: "LAST_SUCCESS_BACK_UP_TIME") as? TimeInterval {
            let dateString = DateFormatter.localizedString(from: Date(timeIntervalSinceReferenceDate: lastPublishTime), dateStyle: .short, timeStyle: .short);
            let loc = NSLocalizedString("LastBackupDateTime", comment: "Last Backup At Format")
            lastBackUpMessage = String(format: loc, dateString)
        }
        let lastBackUpAttributedText = NSMutableAttributedString(string: lastBackUpMessage, attributes: [NSAttributedString.Key.font: UIFont.appFont(for: .regular, with: 13), NSAttributedString.Key.foregroundColor: UIColor.appColor(.accent)])
        return lastBackUpAttributedText
    }
    
    private func updateFooterViewIfNeeded(attributedText: NSMutableAttributedString, progressPercent: Float) {
        if let footer = self.tableView?.footerView(forSection: 1) as? FTBackupFooterView {
            footer.infoView.isHidden = false
            footer.errorInfoBtn.isHidden = true
            footer.activityIndicator.isHidden = true
            footer.updateInfoLabel(attrText: attributedText)
            if self.getCloudBackupIfAny() != FTAccount.webdav.rawValue {
                footer.progressView.isHidden = false
                footer.progressView.progress =  progressPercent / 100.0
            } else {
                footer.progressView.isHidden = true
            }
            let errorMsg = self.getBackuperrorMessage()
            footer.updateErrorMessage(errorMsg)
            if self.checkIfIgnoredItemsExists() {
                footer.errorInfoBtn.isHidden = false
                footer.errorInfoTapHandler = { [weak self] in
                    if let errorInfoVc = UIStoryboard(name: "FTSettings_Accounts", bundle: nil).instantiateViewController(withIdentifier: FTErrorInfoViewController.className) as? FTErrorInfoViewController {
                        self?.navigationController?.pushViewController(errorInfoVc, animated: true)
                    }
                }
            }
        }
    }
    
    @IBAction func toggleBackupOnWiFiOnly(_ sender: UISwitch) {
        let cloudBackUpManager = FTCloudBackUpManager.shared
        cloudBackUpManager.setCloudBackUpOverWifiOnly(sender.isOn)
        let value = (cloudBackUpManager.isCloudBackupOverWifiOnly()) ? "Yes" : "No";
        FTCLSLog("Backup - Wifi only - Enabled : \(value)");
        track("Shelf_Settings_Cloud_Backup_WifiOnly", params: ["toogle":value], screenName: FTScreenNames.shelfSettings)
    }

    private func cellIdentifierForIndexpath(_ indexPath: IndexPath) -> String {
        var cellIdentifier = FTSettingsCommonTableViewCell.className
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            cellIdentifier = CellIdentifiers.iCloud.rawValue
        case (1,0):
            cellIdentifier = CellIdentifiers.backUp.rawValue
        case (1,1):
            cellIdentifier = CellIdentifiers.backUpOptions.rawValue
        case (1,2):
            cellIdentifier = CellIdentifiers.backUpFormatOptions.rawValue
#if targetEnvironment(macCatalyst)
        case (2, 0):
            cellIdentifier = CellIdentifiers.exportData.rawValue
#else
        case (2,0):
            cellIdentifier = CellIdentifiers.evernotePublish.rawValue
        case (2, 1):
            cellIdentifier = CellIdentifiers.exportData.rawValue
#endif
        case (3,0):
            cellIdentifier = CellIdentifiers.backUpOnWifi.rawValue
        default:
            break
        }
        return cellIdentifier
    }
    
    private func trackSelectediCloudLogin(_ account: FTAccount) {
        var eventName: String = ""
        switch account {
        case .dropBox:
            eventName = "Settings_CloudBackup_Cloud_Dropbox"
        case .evernote:
            eventName = "Settings_CloudBackup_Cloud_Evernote"
        case .oneDrive:
            eventName = "Settings_CloudBackup_Cloud_OneDrive"
        case .googleDrive:
            eventName = "Settings_CloudBackup_Cloud_GoogleDrive"
        case .webdav:
            eventName = "Settings_CloudBackup_Cloud_WebDAV"
        }
        
        if eventName != "" {
            track(eventName, params: [:], screenName: FTScreenNames.shelfSettings)
        }
    }
}

class FTCloudBackUpViewController: UIViewController {
    func getCloudBackupIfAny() -> String {
        let backUpType = FTCloudBackUpManager.shared.activeCloudBackUpManager?.cloudBackUpType()
        var backupTypeStr = ""
        switch backUpType {
        case .dropBox:
            backupTypeStr = FTAccount.dropBox.rawValue
        case .oneDrive:
            backupTypeStr = FTAccount.oneDrive.rawValue
        case .googleDrive:
            backupTypeStr = FTAccount.googleDrive.rawValue
        case .webdav:
            backupTypeStr = FTAccount.webdav.rawValue
        default:
            break
        }
        return backupTypeStr
    }
    func getCloudBackupIcon() -> UIImage {
        let backUpType = FTCloudBackUpManager.shared.activeCloudBackUpManager?.cloudBackUpType()
        var backupTypeImg = UIImage()
        switch backUpType {
        case .dropBox:
            backupTypeImg = FTAccount.dropBox.image
        case .oneDrive:
            backupTypeImg = FTAccount.oneDrive.image
        case .googleDrive:
            backupTypeImg = FTAccount.googleDrive.image
        case .webdav:
            backupTypeImg = FTAccount.webdav.image
        default:
            break
        }
        return backupTypeImg
    }
    
    func getBackUpLocation() -> String {
        let backUpType = FTCloudBackUpManager.shared.activeCloudBackUpManager?.cloudBackUpType()
        var backUpLocation: String = ""
        if backUpType == .webdav, var location = FTWebdavManager.getWebdavBackupLocation() {
            if location == "" {
                location = "WebDAV: Root"
            }
            backUpLocation = location
        } else {
            backUpLocation = self.getCloudBackupIfAny()
        }
        return backUpLocation
    }
    
    func fetchLoggedInAccount() -> FTAccount? {
        if let account = FTCloudBackUpManager.shared.activeCloudBackUpManager?.cloudBackUpType() {
           return account.cloudBackUpAccount()
        }
        return nil
    }
    
    func logout(account: FTAccount, onCompletion: @escaping (Bool)->()) {
       let accountInfoRequest = FTAccountInfoRequest.accountInfoRequestForType(account)
       accountInfoRequest.logOut({ success in
           if success {
               runInMainThread({
                   let type = FTCloudBackUpManager.shared.currentBackUpCloudType()
                   if type != .none, type == account.cloudType {
                       FTCloudBackUpManager.shared.setCurrentBackUpCloud(FTCloudBackUpType.none)
                   }
                   track("settings_account", params: ["action" : "loggedOut", "accountType": account.rawValue])
               })
           }
           onCompletion(success)
       })
   }
}

private class FTTableHeaderView: UIView {
    weak var headerLabel: FTSettingsLabel?
    private var previousSize: CGSize = .zero;
    let xoffset: CGFloat = 0;
    let bottomOffset: CGFloat = 4;

    override init(frame: CGRect) {
        super.init(frame: frame);
        let uilable = FTSettingsLabel(frame: CGRect.zero);
        uilable.font = .appFont(for: .medium, with: 13)
        uilable.textColor = UIColor.appColor(.black50)
        
        self.addSubview(uilable);
        self.headerLabel = uilable;
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews();
        if previousSize != self.bounds.size {
            previousSize = self.bounds.size;
            var frame = CGRect(x: xoffset
                               , y: 0
                               ,width: previousSize.width - (2 * xoffset)
                               , height: 16.0);
            frame.origin.y = previousSize.height - frame.height - bottomOffset;
            self.headerLabel?.frame = frame;
        }
    }
}

extension FTAccountsViewController: FTSettingsBackupFormatTableViewCellDelegate {
    func tableViewCell(_ cell: FTSettingsBackupFormatTableViewCell,didChangeFormat format: FTCloudBackupFormat) {
        if let footer = self.tableView?.footerView(forSection: 1) as? FTBackupFooterView {
            UIView.setAnimationsEnabled(false)
            self.tableView?.beginUpdates()
            footer.setBackupFormat(format);
            self.tableView?.endUpdates()
            UIView.setAnimationsEnabled(true)
        }
    }
}
