//
//  FTDropboxBackupPublisher.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 31/08/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

let FTDidCompleteDropBoxAuthetication = "FTDidCompleteDropBoxAuthetication"
let FTDidCancelDropBoxAuthetication = "FTDidCancelDropBoxAuthetication"

class FTDropboxBackupPublisher: FTCloudBackupPublisher {
    
    override func login(with viewController: UIViewController, completionHandler block: @escaping FTGenericCompletionBlockWithStatus) {
        if !self.isLoggedIn() {
            FTDropboxManager.sharedDropboxManager.authenticateToDropBox(from: viewController, onCompletion: { success, cancelled in
                if !success {
                    if !cancelled {
                        let alertController = UIAlertController(title: "", message: NSLocalizedString("UnableToAccessDropbox", comment: "Unable to access Dropbox"), preferredStyle: .alert)

                        let action = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .cancel, handler: nil)
                        alertController.addAction(action)
                        viewController.present(alertController, animated: true)
                    }
                }
                block(success)
            })
        }
    }
    
    override func isLoggedIn() -> Bool {
        return FTDropboxManager.sharedDropboxManager.isLoggedIn()
    }
    
    // MARK: Publish Private
    override func backUpItem(forInfo inDict: [String : Any]) -> FTCloudBackup? {
        let entry = FTDropboxBackupEntry(withDict: inDict)
        return entry
    }
    
    override func publishRequest(forItem inItem: FTCloudBackup, itemURL: URL) -> FTCloudPublishRequest? {
        let request = FTDropboxPublishRequest(backupEntry: inItem, delegate: self,sourceFile:itemURL);
        return request;
    }

    // MARK: Sync Log
    override func cloudBackUpType() -> FTCloudBackUpType {
        return .dropBox
    }

    override func cloudBackUpName() -> String {
        return "Dropbox"
    }
}
