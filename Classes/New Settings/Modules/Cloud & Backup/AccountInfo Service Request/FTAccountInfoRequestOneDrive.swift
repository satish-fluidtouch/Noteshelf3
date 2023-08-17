//
//  FTAccountInfoRequestOneDrive.swift
//  Noteshelf
//
//  Created by Siva on 24/11/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTAccountInfoRequestOneDrive: FTAccountInfoRequest {
    override func accountInfo(onUpdate updateBlock: ((FTCloudAccountInfo) -> Void), onCompletion completionBlock : @escaping ((FTCloudAccountInfo, NSError?) -> Void)) {
        let account = FTCloudAccountInfo();

        if(self.isLoggedIn()) {

            account.statusText = account.loadingText;
            updateBlock(account);
            let infoTask = FTOneDriveClient.shared.getDriveInfoTask()
            infoTask.getDriveInfo({ (drive, error) in
                if drive != nil && error == nil {
                    let username: String;
                    if let displayname = drive?.owner?.user?.displayName, displayname != "" {
                        username = displayname;
                    } else if let email = drive?.owner?.user?.email {
                        username = email;
                    } else {
                        username = FTEmptyDisplayName;
                    }
                    account.userName = username;
                    account.totalBytes = drive?.quota?.total;
                    account.consumedBytes = drive?.quota?.used;

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
            account.statusText = NSLocalizedString("OneDriveHelpMessage", comment: "Import and Export to your OneDrive account");
            completionBlock(account, NSError(domain: "NSUSERNOTLOGGEDIN", code: 103, userInfo: nil));
        }
    }
    override func isLoggedIn() -> Bool {
        return FTOneDriveClient.shared.isLoggeedIn();
    }

    override func showLoginView(withViewController viewController: UIViewController, completion: @escaping ((Bool) -> Void)) {
        FTOneDriveClient.shared.login(onController: viewController, onCompletion: { (account, nserror) in
            if account != nil && nserror == nil {
                completion(true)
            } else {
                completion(false)
            }
        }) 
    }

    override func logOut(_ onCompletion : @escaping ((Bool) -> Void)) {
        FTOneDriveClient.shared.signOut { (success) in
            if success {
                let userdefaults = UserDefaults.standard;
                userdefaults.removeObject(forKey: "ONEDRIVE_IMPORT_FOLDER_ID");
                userdefaults.removeObject(forKey: PersistenceKey_ExportTarget_FolderID_OneDrive);
                userdefaults .synchronize();
            }
            onCompletion(success)
        }
    }
}
