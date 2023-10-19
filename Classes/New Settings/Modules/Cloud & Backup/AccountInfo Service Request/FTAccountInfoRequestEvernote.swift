//
//  FTAccountInfoRequestEvernote.swift
//  Noteshelf
//
//  Created by Siva on 24/11/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

#if !targetEnvironment(macCatalyst)
import Evernote_SDK_iOS
#endif
import Foundation

class FTAccountInfoRequestEvernote: FTAccountInfoRequest {
    override func accountInfo(onUpdate updateBlock: ((FTCloudAccountInfo) -> Void), onCompletion completionBlock : @escaping ((FTCloudAccountInfo, NSError?) -> Void)) {
        let account = FTCloudAccountInfo();

        if(self.isLoggedIn()) {
            account.statusText = account.loadingText;
            updateBlock(account);
    #if !targetEnvironment(macCatalyst)
            let evernoteSession = EvernoteSession.shared();
            let userStore = evernoteSession?.userStore();
            if let authToken = evernoteSession?.authenticationToken as? String {
                let user = userStore?.getUser(authToken)
                let username: String;

                if let email = user?.email, email != "" {
                    username = email;
                } else if let user_name = user?.username, user_name != "" {
                    username = user_name;
                } else if let name = user?.name, name != "" {
                    username = name;
                } else {
                    username = FTEmptyDisplayName;
                }
                account.userName = username;
                self.fetchUsageDetails(account, onCompelltion: completionBlock);
            } else {
                account.statusText = NSLocalizedString("ErrorConnecting", comment: "Error Connecting");
                completionBlock(account, nil);
            }
        #endif
        } else {
            account.statusText = NSLocalizedString("EvernoteHelpMessage", comment: "Publish notebooks to your Evernote account");
            completionBlock(account, NSError(domain: "NSUSERNOTLOGGEDIN", code: 103, userInfo: nil));
        }
    }

    private func fetchUsageDetails(_ account: FTCloudAccountInfo,
                                   onCompelltion completionBlock : @escaping ((FTCloudAccountInfo, NSError?) -> Void) ) {
#if !targetEnvironment(macCatalyst)
        guard let evernoteSession = EvernoteSession.shared() else {
            account.statusText = NSLocalizedString("ErrorConnecting", comment: "Error Connecting");
            completionBlock(account, nil)
            return
        }
        guard isLoggedIn(),let authToken = evernoteSession.authenticationToken as? String  else {
            account.statusText = NSLocalizedString("ErrorConnecting", comment: "Error Connecting");
            completionBlock(account, nil);
            return;
        }

        EvernoteNoteStore(session: evernoteSession).getSyncState { edamSyncState in
            let user = evernoteSession.userStore()?.getUser(authToken)
            //account.consumedBytes = user?.accounting.;
            var accountingInfo = user?.accounting;

            if let businessUser = evernoteSession.businessUser, businessUser.active {
                accountingInfo = evernoteSession.businessUser?.accounting;
                //account.consumedBytes = accountingInfo;
            }

            account.totalBytes = accountingInfo?.uploadLimit ?? 0;
            account.consumedBytes = edamSyncState?.uploaded;

            let usedSize = account.spaceUsedFormatString();
            if(account.userName == FTEmptyDisplayName) {
                account.statusText = usedSize;
            } else {
                let userName = account.usernameFormatString();
                //Added condition to check for totalbytes which will return as 0 when there is no internet connection while quering.
                //Instead of showing empty used ,here we will be just shwoing the logged user name/id
                if(account.totalBytes! > 0) {
                    account.statusText = "\(userName)\n\(usedSize)"
                } else {
                    account.statusText = "\(userName)\n";
                }
            }
            completionBlock(account, nil);
        } failure: { error in
            account.statusText = NSLocalizedString("ErrorConnecting", comment: "Error Connecting");
            completionBlock(account, error as NSError?);
        }
#endif
    }

    override func isLoggedIn() -> Bool {
        #if !targetEnvironment(macCatalyst)
        return EvernoteSession.shared().isAuthenticated;
        #else
        return false
        #endif
    }

    override func showLoginView(withViewController viewController: UIViewController, completion: @escaping ((Bool) -> Void)) {
        #if !targetEnvironment(macCatalyst)
        EvernoteSession.shared().authenticate(with: viewController) { error in
            self.clearEvernotePersistentData();
            completion(EvernoteSession.shared().isAuthenticated)
        }
        #endif
    }

    override func logOut(_ onCompletion : @escaping ((Bool) -> Void)) {
        #if !targetEnvironment(macCatalyst)

        if let evernoteSession = EvernoteSession.shared(),(evernoteSession.isAuthenticated) {
            evernoteSession.logout();
        }
        #endif
        self.clearEvernotePersistentData();
        FTENIgnoreListManager.shared.clearIgnoreList();
        onCompletion(true);
    }

    func clearEvernotePersistentData() {
        let standardUserDefaults = UserDefaults.standard
        standardUserDefaults.removeObject(forKey: EVERNOTE_PUBLISH_ERROR)
        standardUserDefaults.removeObject(forKey: EN_PUBLISH_ERR_SHOW_SUPPORT)
        standardUserDefaults.removeObject(forKey: "EVERNOTE_LAST_LOGIN_ALERT_TIME")
        standardUserDefaults.synchronize()
    }

}
