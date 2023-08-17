//
//  FTOneDriveAlertHandler.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 25/10/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

weak var oneDriveAlertController: UIAlertController?

class FTOneDriveAlertHandler: NSObject {
    static func showOneDriveAuthenticationAlertIfNeeded(_ onController: UIViewController){

        if UserDefaults.oneDriveAuthAlertShown == false && oneDriveAlertController == nil {
            let autoBackupType = FTCloudBackUpManager.shared.currentBackUpCloudType()
            guard let isLoggedIn = FTCloudBackUpManager.shared.activeCloudBackUpManager?.isLoggedIn() else {
                return
            }
            if autoBackupType == .oneDrive && isLoggedIn == false {
                let controller = UIAlertController(title: "", message: NSLocalizedString("OneDriveAuthAlertMessage", comment: "Re-authenticate One Drive to auto-backup notes."), preferredStyle: UIAlertController.Style.alert);
                let loginAction = UIAlertAction(title: NSLocalizedString("Login", comment: "Login"), style: .default, handler: { _ in
                    UserDefaults.oneDriveAuthAlertShown = true
                    oneDriveAlertController = nil
                    FTCloudBackUpManager.shared.activeCloudBackUpManager?.login(with: onController, completionHandler: { (_) in
                        
                    })
                });
                controller.addAction(loginAction);
                
                let laterAction = UIAlertAction(title: NSLocalizedString("Later", comment: "Later"), style: .cancel, handler: { _ in
                    UserDefaults.oneDriveAuthAlertShown = true
                    oneDriveAlertController = nil
                });
                controller.addAction(laterAction);
                
                onController.present(controller, animated: true, completion: nil);
                oneDriveAlertController = controller
            }
        }
    }
}

extension UserDefaults {
    static var oneDriveAuthAlertShown: Bool {
        get{
            return UserDefaults.standard.bool(forKey: "oneDriveAuthAlertShown")
        }
        set{
            UserDefaults.standard.set(newValue, forKey: "oneDriveAuthAlertShown");
            UserDefaults.standard.synchronize();
        }
    }
}
