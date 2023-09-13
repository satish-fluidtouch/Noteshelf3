//
//  FTWebdavBackupPublisher.swift
//  Noteshelf
//
//  Created by Ramakrishna on 05/02/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTWebdavBackupPublisher : FTCloudBackupPublisher {
    
    override func cloudBackUpType() -> FTCloudBackUpType {
        return FTCloudBackUpType.webdav
    }
    
    @objc override func cloudBackUpName() -> String {
        return "Webdav"
    }
    override func login(with viewController: UIViewController, completionHandler block: @escaping FTGenericCompletionBlockWithStatus) {
        if !self.isLoggedIn() {
            FTWebdavManager.shared.authenticateToWebdav(from: viewController) { (success, cancelled, error) in
                if !success {
                    if !cancelled {
                        let alertController = UIAlertController(title: "", message: "Unable to access webdav.", preferredStyle: .alert)

                        let action = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .cancel, handler: nil)
                        alertController.addAction(action)
                        viewController.present(alertController, animated: true)
                    }
                }
                block(success)
            }
        }
    }
   
    override func isLoggedIn() -> Bool {
        return FTWebdavManager.shared.isLoggedIn()
    }
    override func backUpItem(forInfo inDict: [String : Any]) -> FTCloudBackup? {
        let entry = FTWebdavBackupEntry(withDict: inDict)
        return entry
    }
    
    override func publishRequest(forItem inItem: FTCloudBackup, itemURL: URL) -> FTCloudPublishRequest? {
        let request = FTWebdavPublishRequest(backupEntry: inItem, delegate: self,sourceFile:itemURL);
        return request;
    }
}
