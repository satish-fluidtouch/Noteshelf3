//
//  FTAccountInfoRequestGoogleDrive.swift
//  Noteshelf
//
//  Created by Sreenu Cheedella on 21/04/20.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import GoogleAPIClientForREST_Drive

class FTAccountInfoRequestGoogleDrive: FTAccountInfoRequest {
    override func accountInfo(onUpdate updateBlock: ((FTCloudAccountInfo) -> Void), onCompletion completionBlock : @escaping ((FTCloudAccountInfo, NSError?) -> Void)) {
        let account = FTCloudAccountInfo();
        
        if(self.isLoggedIn()) {
            
            account.statusText = account.loadingText;
            updateBlock(account);
            let googleDriveAPIHelper: GoogleDriveAPI = GoogleDriveAPI(service: FTGoogleDriveClient.shared.authenticationService(), callbackQueue: nil)
            googleDriveAPIHelper.about() { (aboutDetails, error) in
                if let driveDetails = aboutDetails {
                    if let user = driveDetails.user {
                        account.userName = user.emailAddress;
                        if(account.userName == "") {
                            account.userName = user.displayName;
                        }
                    }
                    
                    if(account.userName == "") {
                        account.userName = FTEmptyDisplayName;
                    }
                    let storageQuota = (driveDetails as AnyObject).storageQuota!;
                    account.totalBytes = (storageQuota!.limit != nil) ? storageQuota!.limit!.int64Value : Int64(0);
                    account.consumedBytes = (storageQuota!.usage != nil) ? storageQuota!.usage!.int64Value : Int64(0);
                } else {
                    account.userName = FTEmptyDisplayName;
                    account.totalBytes = Int64(0);
                    account.consumedBytes = Int64(0);
                }
                
                let usedSize = account.spaceUsedFormatString();
                if(account.userName == FTEmptyDisplayName) {
                    account.statusText = usedSize;
                } else {
                    let userName = account.usernameFormatString();
                    account.statusText = "\(userName)\n\(usedSize)"
                }
                completionBlock(account, nil);
            }
        } else {
            account.statusText = NSLocalizedString("GoogleDriveHelpMessage", comment: "Import and Export to your Google Drive account");
            completionBlock(account, NSError(domain: "NSUSERNOTLOGGEDIN", code: 103, userInfo: nil));
        }
    }
    
    override func isLoggedIn() -> Bool {
            return FTGoogleDriveClient.shared.isLoggedIn();
    }
    
    override func showLoginView(withViewController viewController: UIViewController, completion: @escaping ((Bool) -> Void)) {
        FTGoogleDriveClient.shared.login(onController: viewController, onCompletion: { (account, nsError) in
            if account != nil && nsError == nil {
                completion(true)
            } else {
                completion(false)
            }
        })
    }
    
    override func logOut(_ onCompletion : @escaping ((Bool) -> Void)) {
        FTGoogleDriveClient.shared.signOut { (success) in
            onCompletion(success)
        }
    }
}
