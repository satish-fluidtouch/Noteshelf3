//
//  FTGoogleDriveBackupPublisher.swift
//  Noteshelf
//
//  Created by sreenu cheedella on 16/04/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import MSAL

class FTGoogleDriveBackupPublisher: FTCloudBackupPublisher {
    override func cloudBackUpType() -> FTCloudBackUpType {
        return FTCloudBackUpType.googleDrive
    }
    
    @objc override func cloudBackUpName() -> String {
        return "GoogleDrive"
    }
    
    override func isLoggedIn() -> Bool {
            return FTGoogleDriveClient.shared.isLoggedIn()
    }
    
    override func login(with viewController: UIViewController!, completionHandler block: FTGenericCompletionBlockWithStatus!) {
        FTGoogleDriveClient.shared.login(onController: viewController){ (user, error) in
            if error != nil {
                var errorMessage = NSLocalizedString("AuthenticationFailed", comment: "Unable to authenticate")
                if let nserror = error as NSError?, let msalErrorMessage = nserror.userInfo[MSALErrorDescriptionKey] as? String {
                    errorMessage = msalErrorMessage
                }
                UIAlertController.showAlert(withTitle: "", message: errorMessage, from: viewController,withCompletionHandler: nil);
                block(false)
            } else {
                block(true)
            }
        }
    }
    
    override func backUpItem(forInfo inDict: [String : Any]) -> FTCloudBackup? {
        let entry = FTGoogleDriveBackupEntry.init(withDict: inDict)
        return entry
    }
    
    override func publishRequest(forItem inItem: FTCloudBackup, itemURL: URL) -> FTCloudPublishRequest? {
        let request = FTGoogleDrivePublishRequest(backupEntry: inItem, delegate: self,sourceFile:itemURL);
        return request;
    }
}
