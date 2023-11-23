//
//  FTEvernoteSettingsTableViewController.swift
//  Noteshelf
//
//  Created by Paramasivan on 4/11/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//


import MessageUI
import UIKit
import FTCommon

protocol FTEvernoteSettingsTableViewControllerDelegate {
    func loggedOut(_ evernoteSettingsTableViewController: FTEvernoteSettingsViewController)
}
enum FTEvernoteInfoType {
    case user
    case error
}
protocol FTEvernoteInfo {
    var description: NSAttributedString { get set }
    var infoType: FTEvernoteInfoType { get set}
}
struct FTEvernoteUserInfo: FTEvernoteInfo {
    var description: NSAttributedString
    var infoType: FTEvernoteInfoType = .user
}
struct FTEvernoteError: FTEvernoteInfo {
    var description: NSAttributedString
    var infoType: FTEvernoteInfoType = .error
    var image: String?
}

class FTEvernoteSettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate {
    @IBOutlet weak var tableView: UITableView?

    weak var delegate: FTAccountActivityDelegate?
    var account: FTAccount!

    let FixedSectionsCount = 1;

    let Section_Actions = 0;
    let Row_PublishNotebooks = 0;
    let Row_SyncOnWifiOnly = 1;

    var errorSectionsCount = 0;
    var arrayDynamicSections = [[FTEvernoteInfo]]();
    var hideBackButton: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        account = .evernote
        let accountInfoRequest = FTAccountInfoRequest.accountInfoRequestForType(account);
        accountInfoRequest.accountInfo(onUpdate: {[weak self] _ in
            self?.relayoutIfNeeded();
        }, onCompletion: { [weak self] _,_  in
            self?.setAccountInfo()
            runInMainThread {
                self?.updateUI()
                self?.relayoutIfNeeded();
            }
        });

        self.view.backgroundColor = UIColor.appColor(.formSheetBgColor)
        self.setAccountInfo()
        self.tableView?.delegate = self
        self.tableView?.dataSource = self
        self.updateUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureNewNavigationBar(hideDoneButton: false,title: "Evernote".localized)
        let indexPathToReload = IndexPath(row: Row_PublishNotebooks, section: Section_Actions)
        self.tableView?.reloadRows(at: [indexPathToReload], with: .automatic)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    private func setAccountInfo() {
        self.arrayDynamicSections.removeAll()
        var arrayErrorAndSync = [FTEvernoteInfo]()
        let standardUserDefaults = UserDefaults.standard

        let accountInfoAttributedString = NSMutableAttributedString()
        if let usedSpace = standardUserDefaults.string(forKey: EN_USEDSPACE),!usedSpace.isEmpty {
            let spaceUsedInfo = NSAttributedString(string: usedSpace,attributes: [.font: UIFont.appFont(for: .medium, with: 15), .foregroundColor : UIColor.appColor(.black1)])
            accountInfoAttributedString.append(spaceUsedInfo)
        }
        if let username = standardUserDefaults.string(forKey: EN_LOGGED_USERNAME),!username.isEmpty {
            let usernameAttrString = NSAttributedString(string: "\n" + username,attributes: [.font: UIFont.appFont(for: .regular, with: 15), .foregroundColor : UIColor.appColor(.black70)])
            accountInfoAttributedString.append(usernameAttrString)
        }
        if let lastPublishTime = standardUserDefaults.object(forKey: EVERNOTE_LAST_PUBLISH_TIME) as? TimeInterval {
            let dateString = DateFormatter.localizedString(from: Date(timeIntervalSinceReferenceDate: lastPublishTime), dateStyle: .short, timeStyle: .short);
            let loc = "\n" + "LastsuccessfulsyncAtFormat".localized
            let description = String(format: loc, dateString);
            let syncInfo = NSAttributedString(string: description,attributes: [.font: UIFont.appFont(for: .regular, with: 13), .foregroundColor : UIColor.appColor(.accent)])
            accountInfoAttributedString.append(syncInfo)
        }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2.0
        paragraphStyle.alignment = .center
        accountInfoAttributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: accountInfoAttributedString.length))
        if !accountInfoAttributedString.string.isEmpty {
            arrayErrorAndSync.append(FTEvernoteUserInfo(description: accountInfoAttributedString))
        } else {
            let fetchErrorInfo = NSAttributedString(string:"evernote.userInfo.fetchFailureMessage".localized,attributes: [.font: UIFont.appFont(for: .regular, with: 15), .foregroundColor : UIColor.appColor(.black70)])
            arrayErrorAndSync.append(FTEvernoteUserInfo(description:fetchErrorInfo))
        }

        if let evernoteError = standardUserDefaults.object(forKey: EVERNOTE_PUBLISH_ERROR) {
            let errorInfo = NSAttributedString(string: "Sync failed with reason: \(evernoteError)",attributes: [.font: UIFont.appFont(for: .regular, with: 15), .foregroundColor : UIColor.appColor(.black1)])
            arrayErrorAndSync.append(FTEvernoteError(description: errorInfo, image: "en-error-red"));
        }
        if !arrayErrorAndSync.isEmpty {
            self.arrayDynamicSections.append(arrayErrorAndSync);
        }

        if !FTENIgnoreListManager.shared.ignoredNotebooks().isEmpty {
            var arrayIgnoredNotebooks = [FTEvernoteError]();
            let ignoredNotebooks = FTENIgnoreListManager.shared.ignoredNotebooks()
            for ignoreEntry in ignoredNotebooks.filter({ $0.shouldDisplay }) {
                let message: String!
                let title: String = ignoreEntry.title ?? ""
                if ignoreEntry.ignoreType == .dataLimitReached {
                    message = "\(title)\nSize exceeded Evernote limits";
                } else if ignoreEntry.ignoreType == .fileNotFound {
                    message = "\(title)\nFile not found";
                } else {
                    message = "\(title)\nUnknown Reason";
                }
                let ignoredNotebooksInfo = NSAttributedString(string: message,attributes: [.font: UIFont.appFont(for: .regular, with: 15), .foregroundColor : UIColor.appColor(.accent)])
                arrayIgnoredNotebooks.append(FTEvernoteError(description: ignoredNotebooksInfo, image: "en-error-orange"));
            }
            self.arrayDynamicSections.append(arrayIgnoredNotebooks);
        }
    }
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let selectNotebookController = segue.destination as? FTSelectNotebookForBackupViewController {
            selectNotebookController.mode = .evernoteSync;
        }
    }

    // MARK: - UI
    func relayoutIfNeeded() {
        runInMainThread(0.001) {
            self.tableView?.setNeedsLayout();
            self.tableView?.layoutIfNeeded();
        }
    }

    func updateUI() {
        self.tableView?.reloadData();
    }

    // MARK: - SyncOnWiFiOnly
    @IBAction func toggleSyncOnWiFiOnly(_ sender: UISwitch) {
        let standardUserDefaults = UserDefaults.standard
        standardUserDefaults.set(sender.isOn, forKey: EVERNOTE_PUBLISH_ON_WIFI_ONLY)
        standardUserDefaults.synchronize()
        track("settings_account", params: ["action" : "evernoteWifiPublish", "Enabled": sender.isOn ? "YES" : "NO"])
    }

    // MARK: - UITableViewDataSource
     func numberOfSections(in tableView: UITableView) -> Int {
        return (FixedSectionsCount + self.arrayDynamicSections.count);
    }

     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == Section_Actions {
            return 2;
        } else if section < tableView.numberOfSections {
            return self.arrayDynamicSections[section - FixedSectionsCount].count;
        }
        return 0;
    }

     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == Section_Actions {
            if indexPath.row == Row_PublishNotebooks {
                if let cell = tableView.dequeueReusableCell(withIdentifier: "CellPublishNotebooks", for: indexPath) as? FTSettingsBaseTableViewCell {
                    self.updateEvernoteBackupCount(cell: cell)
                    return cell
                }
            } else if indexPath.row == Row_SyncOnWifiOnly {
                let cell = tableView.dequeueReusableCell(withIdentifier: "CellSyncOnWiFiOnly", for: indexPath) as? FTSettingsBaseTableViewCell;

                cell?.switch?.isOn = FTENPublishManager.shared.publishOnlyOnWifi();
                cell?.switch?.addTarget(self, action: #selector(self.toggleSyncOnWiFiOnly), for: .valueChanged)

                return cell!
            }
        } else if indexPath.section < tableView.numberOfSections {
            let enInfo = self.arrayDynamicSections[indexPath.section - FixedSectionsCount][indexPath.row];
            if enInfo.infoType == .user {
                guard let userInfoView = Bundle.main.loadNibNamed("FTENUserInfoTableViewCell", owner: nil, options: nil)?.first as? FTENUserInfoTableViewCell else {
                    return UITableViewCell()
                }
                userInfoView.updateInfoLabel(attrText: enInfo.description)
                userInfoView.updateSubviewsVisibility()
                if let usedSpace = UserDefaults.standard.string(forKey: EN_USEDSPACE),!usedSpace.isEmpty {
                    let spaceUsedPercent = UserDefaults.standard.float(forKey: EN_USEDSPACEPERCENT)
                    userInfoView.progressView?.isHidden = false
                    userInfoView.userInfoLabelTopConstraint?.constant = 44.0
                    userInfoView.progressView?.progress =  spaceUsedPercent / 100.0
                } else {
                    userInfoView.userInfoLabelTopConstraint?.constant = 16.0
                    userInfoView.progressView?.isHidden = true
                }
                return userInfoView
            } else {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "CellErrorOrSuccess", for: indexPath) as? FTSettingsBaseTableViewCell,let erroInfo = enInfo as? FTEvernoteError else {
                    return UITableViewCell()
                }
                cell.imageViewIcon?.image = UIImage(named: erroInfo.image ?? "");
                cell.labelTitle?.attributedText = erroInfo.description;
                return cell
            }
        }
        return UITableViewCell();
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return (section == tableView.numberOfSections - 1) ? 76.0 : .leastNonzeroMagnitude
   }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == tableView.numberOfSections - 1 && EvernoteSession.shared().isAuthenticated {
            guard let footerView = Bundle.main.loadNibNamed("FTEvernoteFooterView", owner: nil, options: nil)?.first as? FTEvernoteFooterView else {
                return nil
            }
            footerView.evernoteVc = self
            return footerView
        }
        return nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    private func updateEvernoteBackupCount(cell: FTSettingsBaseTableViewCell) {
        let options = FTFetchShelfItemOptions()
        cell.notebooksCountLabel?.text = ""
        FTNoteshelfDocumentProvider.shared.fetchAllShelfItems(option: options) { shelfItems in
            cell.notebooksCountLabel?.text = String(format: "%d/%d %@", FTENPublishManager.shared.syncEnabledBooks?.count ?? 0, shelfItems.count, "Notebooks".localized)
        }
    }

    // MARK: - SendLog
    func composeEvernoteLog() {
        if MFMailComposeViewController.canSendMail() {
            let publishManager = FTENPublishManager.shared;
            publishManager.generateSyncLog();

            let mailComposeViewController = MFMailComposeViewController();
            mailComposeViewController.modalPresentationStyle = .overFullScreen;
            mailComposeViewController.mailComposeDelegate = self;
            mailComposeViewController.setSubject("Sync Log");
            mailComposeViewController.addSupportMailID();
            if let syncLogData = try? Data(contentsOf: URL(fileURLWithPath: (publishManager.nsENLogPath())!)) {
                mailComposeViewController.addAttachmentData(syncLogData, mimeType: "text/plain", fileName: "Sync.log");
            }
            self.present(mailComposeViewController, animated: true, completion: nil);
        } else {
            UIAlertController.showAlert(withTitle: "", message: "EmailNotSetup".localized, from: self, withCompletionHandler: nil);
        }
    }

    // MARK: - MFMailComposeViewControllerDelegate
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }

}
