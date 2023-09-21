//
//  FTBackUpOptionsFooterView.swift
//  Noteshelf
//
//  Created by Narayana on 01/12/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles
import FTCommon

class FTBackUpOptionsFooterView: UITableViewHeaderFooterView {
    @IBOutlet weak var signoutBtn: UIButton!
    weak var backUpOptionsVc: FTBackupOptionsViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.signoutBtn.layer.cornerRadius = 10.0
        self.signoutBtn.setTitleColor(UIColor.appColor(.darkRed), for: .normal)
        self.signoutBtn.titleLabel?.font = UIFont.appFont(for: .regular, with: 17)
    }

    @IBAction func signOutClicked(_ sender: UIButton) {
        if let account = self.backUpOptionsVc?.fetchLoggedInAccount() {
            let type = FTCloudBackUpManager.shared.currentBackUpCloudType()
            if type != .none, type == account.cloudType {
                self.showBackupTurnOffWarning(account: account)
                return;
            }
            self.backUpOptionsVc?.logout(account: account) { _ in
                FTCloudBackUpManager.shared.setEnableCloudBackUp(false)
                self.backUpOptionsVc?.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    private func showBackupTurnOffWarning(account: FTAccount) {
        let messageString = String(format: NSLocalizedString("LogoutAutoBackupAlert", comment: "This action will turn off... %@"), account.rawValue)
        let alertController = UIAlertController(title: messageString, message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("TurnOffAutoBackup", comment: "Turn off Auto-backup"), style: .destructive, handler: { action in
            self.backUpOptionsVc?.logout(account: account) { success in
                FTCloudBackUpManager.shared.setEnableCloudBackUp(false)
                if success {
                    self.backUpOptionsVc?.navigationController?.popViewController(animated: true)
                }
            }
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .default, handler: nil))
        self.backUpOptionsVc?.present(alertController, animated: true, completion: nil)
    }
}
