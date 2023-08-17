//
//  FTAccountInfoRequestWebdav.swift
//  Noteshelf
//
//  Created by Ramakrishna on 08/01/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTAccountInfoRequestWebdav : FTAccountInfoRequest {
    
    override func accountInfo(onUpdate updateBlock: ((FTCloudAccountInfo) -> Void), onCompletion completionBlock: @escaping ((FTCloudAccountInfo, NSError?) -> Void)) {
        let account = FTCloudAccountInfo();
        if self.isLoggedIn(){
            if let serverAuthProperties = FTWebdavManager.shared.fetchSavedWebdavAuthenticationProperties() {
                if !(serverAuthProperties.serverCredentials?.user ?? "").isEmpty{
                    account.userName =  serverAuthProperties.serverCredentials?.user
                }
                account.serverAddress = serverAuthProperties.serverAddress.absoluteString 
                if(account.userName == "") {
                    account.userName = FTEmptyDisplayName;
                }
                completionBlock(account, nil);
            }else{
                account.statusText = "Publish notebooks to your Webdav Server";
                completionBlock(account, NSError(domain: "NSUSERNOTLOGGEDIN", code: 103, userInfo: nil));
            }
        }else{
            account.statusText = "Publish notebooks to your Webdav Server";
            completionBlock(account, NSError(domain: "NSUSERNOTLOGGEDIN", code: 103, userInfo: nil));
        }
    }
    override func isLoggedIn() -> Bool {
        if FTWebdavManager.shared.fetchSavedWebdavAuthenticationProperties()?.serverAddress != nil{
            return true
        }
        return false
    }
    override func showLoginView(withViewController viewController: UIViewController, completion: @escaping ((Bool) -> Void)) {
        FTWebdavManager.shared.authenticateToWebdav(from: viewController) { (success, cancelled,error)  in
            if(error != nil) {
                if let errorText = error?.localizedDescription{
                    UIAlertController.showAlert(withTitle: "",
                                                message: errorText,
                                                from: viewController,
                                                withCompletionHandler: nil);
                }
            }
            completion(success)
        }
    }

    override func logOut(_ onCompletion : @escaping ((Bool) -> Void)) {
        if FTWebdavManager.shared.removeWebdavAuthProperties(){
            FTWebdavManager.removeWebdavBackupLocation()
            onCompletion(true)
        }
        onCompletion(false);
    }
}
