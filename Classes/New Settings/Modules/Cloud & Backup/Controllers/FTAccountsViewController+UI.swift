//
//  FTAccountsTableViewController+UI.swift
//  Noteshelf
//
//  Created by Paramasivan on 4/11/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

enum CellIdentifiers: String {
    // Section - 0
    case iCloud = "CellUseiCloud"
    case evernotePublish = "tableViewCellEvernotePublish"
    case exportData = "tableViewCellExportData"
    
    // Section - 1
    case backUp = "tableViewCellBackupTo"
    case backUpOptions = "CellBackUpOptions"
    case notebooks = "CellBackupNotebooks"
    case backUpOnWifi = "CellBackupOnWiFiOnly"
}

extension FTAccountsViewController: FTAccountActivityDelegate {
    func setDetailsTextLabel(_ detailsText: String?, forCell cell: FTSettingsBaseTableViewCell) {
        runInMainThread {
            cell.labelSubTitle?.text = detailsText;
        }
    }
    
    // MARK: - FTAccountActivityDelegate
    func accountDidLogout(_ account: FTAccount, fromViewController viewController: UIViewController) {
        self.logout(account: account) { success in
            if success {
                self.tableView?.reloadData()
            }
        }
    }
}
