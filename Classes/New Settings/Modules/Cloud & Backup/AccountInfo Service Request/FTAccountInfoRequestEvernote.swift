//
//  FTAccountInfoRequestEvernote.swift
//  Noteshelf
//
//  Created by Siva on 24/11/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

#if !targetEnvironment(macCatalyst)
// import EvernoteSDK
#endif
import Foundation

class FTAccountInfoRequestEvernote: FTAccountInfoRequest {
    override func accountInfo(onUpdate updateBlock: ((FTCloudAccountInfo) -> Void), onCompletion completionBlock : @escaping ((FTCloudAccountInfo, NSError?) -> Void)) {
        let account = FTCloudAccountInfo();

        if(self.isLoggedIn()) {
            account.statusText = account.loadingText;
            updateBlock(account);
    #if !targetEnvironment(macCatalyst)
            guard let evernoteSession = EvernoteSession.shared() else {
                account.statusText = NSLocalizedString("ErrorConnecting", comment: "Error Connecting");
                completionBlock(account, nil);
                return
            }
            EvernoteUserStore(session: evernoteSession).getUserWithSuccess { user in
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
                UserDefaults.standard.set(username,forKey:EN_LOGGED_USERNAME)

                self.fetchUsageDetails(account, user: user, onCompelltion: completionBlock);
            } failure: { error in
                account.statusText = NSLocalizedString("ErrorConnecting", comment: "Error Connecting");
                completionBlock(account, nil);
            }
        #endif
        } else {
            account.statusText = NSLocalizedString("EvernoteHelpMessage", comment: "Publish notebooks to your Evernote account");
            completionBlock(account, NSError(domain: "NSUSERNOTLOGGEDIN", code: 103, userInfo: nil));
        }
    }

    private func fetchUsageDetails(_ account: FTCloudAccountInfo,user: EDAMUser?,
                                   onCompelltion completionBlock : @escaping ((FTCloudAccountInfo, NSError?) -> Void) ) {
#if !targetEnvironment(macCatalyst)
        guard let evernoteSession = EvernoteSession.shared(), evernoteSession.isAuthenticated else {
            account.statusText = NSLocalizedString("ErrorConnecting", comment: "Error Connecting");
            completionBlock(account, nil)
            return
        }

        EvernoteNoteStore(session: evernoteSession).getSyncState { edamSyncState in
            var accountingInfo = user?.accounting;
            if let businessUser = evernoteSession.businessUser, businessUser.active {
                accountingInfo = evernoteSession.businessUser?.accounting;
            }

            account.totalBytes = accountingInfo?.uploadLimit ?? 0;
            account.consumedBytes = edamSyncState?.uploaded;

            let usedSize = account.spaceUsedFormatString() + " Evernote";
            UserDefaults.standard.set(usedSize,forKey: EN_USEDSPACE)
            UserDefaults.standard.set(account.percentage, forKey: EN_USEDSPACEPERCENT)
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
