//
//  FTAccountsTableViewController+Segue.swift
//  Noteshelf
//
//  Created by Paramasivan on 4/11/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//


import Foundation
import FTCommon

extension FTAccountsViewController {
    func performEvernoteSegue(withIdentifier identifier: String, sender: Any?) {
        if let cell = sender as? UITableViewCell, let indexpath = self.tableView?.indexPath(for: cell) {
            let account = FTAccount.evernote
            let accountInfoRequest = FTAccountInfoRequest.accountInfoRequestForType(account)
            let isLoggedIn = accountInfoRequest.isLoggedIn()

            if !isLoggedIn {
                accountInfoRequest.showLoginView(withViewController: self, completion: { success in
                    runInMainThread {
                        if success {
                            self.performSegue(withIdentifier: "Accounts_to_EvernoteSettingsPublish", sender: self.tableView?.cellForRow(at: indexpath))
                            track("Shelf_Settings_Cloud_Backup_EvernotePub", params: [:], screenName: FTScreenNames.shelfSettings)
                        } else {
                            UIAlertController.showAlert(withTitle: "", message: NSLocalizedString("UnableToauthenticate", comment: "Unable to authenticate"), from: self, withCompletionHandler: nil);
                        }
                    }
                })
            } else {
                self.performSegue(withIdentifier: "Accounts_to_EvernoteSettingsPublish", sender: self.tableView?.cellForRow(at: indexpath))
                track("Shelf_Settings_Cloud_Backup_EvernotePub", params: [:], screenName: FTScreenNames.shelfSettings)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if let cell = sender as? UITableViewCell {
//            if let evernoteSettingsTableViewController = segue.destination as? FTEvernoteSettingsViewController {
//                evernoteSettingsTableViewController.delegate = self
//                evernoteSettingsTableViewController.account = .evernote
//            } 
//            track("settings_account", params: ["identifier": "\(cell.reuseIdentifier!)"])
//        }
    }
}
