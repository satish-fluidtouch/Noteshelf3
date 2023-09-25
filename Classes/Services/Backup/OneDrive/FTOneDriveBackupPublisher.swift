//
//  FTOneDriveBackupPublisher.swift
//  Noteshelf
//
//  Created by Amar on 20/12/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import MSAL

class FTOneDriveBackupPublisher: FTCloudBackupPublisher {

    override func cloudBackUpType() -> FTCloudBackUpType {
        return FTCloudBackUpType.oneDrive
    }
    
    @objc override func cloudBackUpName() -> String {
        return "OneDrive"
    }
    
    override func isLoggedIn() -> Bool {
        return FTOneDriveClient.shared.isLoggeedIn();
    }
    
    override func login(with viewController: UIViewController, completionHandler block: @escaping  FTGenericCompletionBlockWithStatus) {
        FTOneDriveClient.shared.login(onController: viewController) { (_, error) in
            if error != nil {
                var errorMessage = NSLocalizedString("AuthenticationFailed", comment: "Unable to authenticate")
                if let nserror = error as NSError?, let msalErrorMessage = nserror.userInfo[MSALErrorDescriptionKey] as? String {
                    errorMessage = msalErrorMessage
                }
                UIAlertController.showAlert(withTitle: "", message: errorMessage, from: viewController,withCompletionHandler: nil);
                block(false)
            }
            else {
                block(true)
            }
        }
    }
    
    override func backUpItem(forInfo inDict: [String : Any]) -> FTCloudBackup? {
        let entry = FTOneDriveBackupEntry.init(withDict: inDict)
        return entry
    }
    
    override func publishRequest(forItem inItem: FTCloudBackup, itemURL: URL) -> FTCloudPublishRequest? {
        let request = FTOneDrivePublishRequest(backupEntry: inItem, delegate: self,sourceFile:itemURL);
        return request;
    }
}
