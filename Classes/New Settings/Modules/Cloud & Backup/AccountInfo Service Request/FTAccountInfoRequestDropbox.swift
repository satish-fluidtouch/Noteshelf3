//
//  FTAccountInfoRequestDropbox.swift
//  Noteshelf
//
//  Created by Siva on 24/11/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTAccountInfoRequestDropbox: FTAccountInfoRequest {
    override func accountInfo(onUpdate updateBlock: ((FTCloudAccountInfo) -> Void), onCompletion completionBlock : @escaping ((FTCloudAccountInfo, NSError?) -> Void)) {
        let account = FTCloudAccountInfo();

        if(self.isLoggedIn()) {

            account.statusText = account.loadingText;
            updateBlock(account);

            FTDropboxManager.sharedDropboxManager.accountInfo(onCompletion: { accountInfo, error in
                account.userName = FTEmptyDisplayName;
                if(nil == error) {
                    let username: String;
                    if let email = accountInfo?.email, email != "" {
                        username = email;
                    } else if let displayname = accountInfo?.name, displayname != "" {
                        username = displayname;
                    } else {
                        username = FTEmptyDisplayName;
                    }
                    account.userName = username
                    if var totalBytes = accountInfo?.totalBytes, var consumedBytes = accountInfo?.consumedBytes {
                        let tempTotalBytes = totalBytes
                        totalBytes = consumedBytes
                        consumedBytes = tempTotalBytes
                        account.totalBytes = Int64(totalBytes)
                        account.consumedBytes = Int64(consumedBytes)
                    }

                    let usedSize = account.spaceUsedFormatString();
                    if(account.userName == FTEmptyDisplayName) {
                        account.statusText = usedSize;
                    } else {
                        let userName = account.usernameFormatString();
                        account.statusText = "\(userName)\n\(usedSize)"
                    }
                } else {
                    account.statusText = NSLocalizedString("ErrorConnecting", comment: "Error Connecting");
                }
                completionBlock(account, error as NSError?);
            });
        } else {
            account.statusText = NSLocalizedString("DropboxHelpMessage", comment: "Backup, Import and Export to your Dropbox account");
            completionBlock(account, NSError(domain: "NSUSERNOTLOGGEDIN", code: 103, userInfo: nil));
        }
    }
    override func isLoggedIn() -> Bool {
        return FTDropboxManager.sharedDropboxManager.isLoggedIn();
    }

    override func showLoginView(withViewController viewController: UIViewController, completion: @escaping ((Bool) -> Void)) {

        let dropboxManager = FTDropboxManager.sharedDropboxManager
        if(dropboxManager.isLoggedIn()) {
            completion(true);
        } else {
            dropboxManager.authenticateToDropBox(from: viewController, onCompletion: { success, cancelled in
                if(!success) {
                    if(!cancelled) {
                        UIAlertController.showAlert(withTitle: "",
                                                    message: NSLocalizedString("UnableToAccessDropbox", comment: "Unable to access Dropbox"),
                                                    from: viewController,
                                                    withCompletionHandler: nil);
                    }
                }
                completion(success);
            });
        }
    }

    override func logOut(_ onCompletion : @escaping ((Bool) -> Void)) {
        FTDropboxManager.sharedDropboxManager.signOut(onCompletionHandler: onCompletion);
    }
}
