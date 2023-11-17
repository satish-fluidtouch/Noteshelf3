//
//  FTEvernoteFooterView.swift
//  Noteshelf
//
//  Created by Narayana on 15/12/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles
import FTCommon

class FTEvernoteFooterView: UITableViewHeaderFooterView {
    @IBOutlet weak var signOutBtn: UIButton!
    weak var evernoteVc: FTEvernoteSettingsViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.signOutBtn.layer.cornerRadius = 8.0
        self.signOutBtn.setTitleColor(UIColor.appColor(.signoutBtnColor), for: .normal)
        self.signOutBtn.titleLabel?.font = UIFont.appFont(for: .regular, with: 15)
        self.signOutBtn.setTitle(NSLocalizedString("shelf.evernote.signout", comment: "Sign Out from Evernote"), for: .normal)
    }
    
    @IBAction func signOutTapped(_ sender: Any) {
        let account = FTAccount.evernote
        let accountInfoRequest = FTAccountInfoRequest.accountInfoRequestForType(account)
        accountInfoRequest.logOut({ success in
            if success {
                runInMainThread({
                    if let navVc = self.evernoteVc?.navigationController {
                        if nil == navVc.popViewController(animated: true) {
                            navVc.dismiss(animated: true, completion: nil) // From shelf tool bar error scenario
                        }
                    }
                    track("settings_account", params: ["action" : "loggedOut", "accountType": account.rawValue])
                })
            } else {
                let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: "Error"), message: "Error in logging out. Please try after sometime", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alertVc.addAction(okAction)
                self.evernoteVc?.present(alertVc, animated: true, completion: nil)
            }
        })
    }
}
