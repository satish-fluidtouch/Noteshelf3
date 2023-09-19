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

struct FTEvernoteError {
    var description: String?
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
    var arrayDynamicSections = [[FTEvernoteError]]();
    var hideBackButton: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        account = .evernote
        let accountInfoRequest = FTAccountInfoRequest.accountInfoRequestForType(account);
        accountInfoRequest.accountInfo(onUpdate: { accountInfo in
            self.updateInfo(withAccounfInfo: accountInfo);
            }, onCompletion: { accountInfo, error in
                self.updateInfo(withAccounfInfo: accountInfo);
        });

        self.view.backgroundColor = UIColor.appColor(.formSheetBgColor)
        var arrayErrorAndSync = [FTEvernoteError]()
        let standardUserDefaults = UserDefaults.standard

        if let evernoteError = standardUserDefaults.object(forKey: EVERNOTE_PUBLISH_ERROR) {
            arrayErrorAndSync.append(FTEvernoteError(description: "Sync failed with reason: \(evernoteError)", image: "en-error-red"));
        }

        if let lastPublishTime = standardUserDefaults.object(forKey: EVERNOTE_LAST_PUBLISH_TIME) as? TimeInterval {

            let dateString = DateFormatter.localizedString(from: Date(timeIntervalSinceReferenceDate: lastPublishTime), dateStyle: .short, timeStyle: .short);
            let loc = "LastsuccessfulsyncAtFormat".localized
            let description = String(format: loc, dateString);
            arrayErrorAndSync.append(FTEvernoteError(description: description, image: "iconCheckBadge"))
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

                arrayIgnoredNotebooks.append(FTEvernoteError(description: message, image: "en-error-orange"));
            }
            self.arrayDynamicSections.append(arrayIgnoredNotebooks);
        }

        self.tableView?.delegate = self
        self.tableView?.dataSource = self
        self.updateUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureNewNavigationBar(hideDoneButton: false,title: "Evernote".localized)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let selectNotebookController = segue.destination as? FTSelectNotebookForBackupViewController {
            selectNotebookController.mode = .evernoteSync;
        }
    }

    // MARK: - UI
    func updateInfo(withAccounfInfo accountInfo: FTCloudAccountInfo) {
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
            let error = self.arrayDynamicSections[indexPath.section - FixedSectionsCount][indexPath.row];

            let cell = tableView.dequeueReusableCell(withIdentifier: "CellErrorOrSuccess", for: indexPath) as? FTSettingsBaseTableViewCell;

            cell?.imageViewIcon?.image = UIImage(named: error.image ?? "");
            cell?.labelTitle?.text = error.description ?? "";

            return cell!
        }
        return UITableViewCell();
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return (section == tableView.numberOfSections - 1) ? 76.0 : .leastNonzeroMagnitude
   }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == tableView.numberOfSections - 1 {
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
        let predicate = NSPredicate.init(format: "parentRecord.nsGUID != nil");
        let evernotenoteBooksBackedUp = FTENSyncUtilities.fetchCount(withEntity: "ENSyncRecord", predicate: predicate)
        let options = FTFetchShelfItemOptions()
        cell.notebooksCountLabel?.text = ""
        FTNoteshelfDocumentProvider.shared.fetchAllShelfItems(option: options) { shelfItems in
            cell.notebooksCountLabel?.text = String(format: "%d/%d %@", evernotenoteBooksBackedUp, shelfItems.count, "Notebooks".localized)
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
