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
            let evernoteSession = EvernoteSession.shared;
            let userStore = evernoteSession.userStore;

            userStore?.fetchUser(completion: { user, error in
                if (nil != error) {
                    account.statusText = NSLocalizedString("ErrorConnecting", comment: "Error Connecting");
                    completionBlock(account, nil);
                } else {
                    let username: String;

                    if let email = user?.email, email != "" {
                        username = email;
                    } else if let user_name = user?.username, user_name != "" {
                        username = user_name;
                    } else if let name = user?.name, name != "" {
                        username = name;
                    } else if evernoteSession.userDisplayName != "" {
                        username = evernoteSession.userDisplayName;
                    } else {
                        username = FTEmptyDisplayName;
                    }
                    account.userName = username;
                    self.fetchUsageDetails(account, onCompelltion: completionBlock);
                }
            })
            #endif
        } else {
            account.statusText = NSLocalizedString("EvernoteHelpMessage", comment: "Publish notebooks to your Evernote account");
            completionBlock(account, NSError(domain: "NSUSERNOTLOGGEDIN", code: 103, userInfo: nil));
        }
    }

    private func fetchUsageDetails(_ account: FTCloudAccountInfo,
                                   onCompelltion completionBlock : @escaping ((FTCloudAccountInfo, NSError?) -> Void) ) {
        #if !targetEnvironment(macCatalyst)
        let evernoteSession = EvernoteSession.shared;
        
        var currentStore: EDAMNoteStoreClient? = evernoteSession.primaryNoteStore();
        if(evernoteSession.isBusinessUser) {
            currentStore = evernoteSession.businessNoteStore();
        }
        guard isLoggedIn(),let store = currentStore  else {
            account.statusText = NSLocalizedString("ErrorConnecting", comment: "Error Connecting");
            completionBlock(account, nil);
            return;
        }

        store.fetchSyncState(completion: { syncState, error in
            if(nil != error) {
                account.statusText = NSLocalizedString("ErrorConnecting", comment: "Error Connecting");
                completionBlock(account, nil);
            } else {
                account.consumedBytes = evernoteSession.personalUploadUsage;
                var accountingInfo = evernoteSession.user?.accounting;

                if(evernoteSession.isBusinessUser) {
                    accountingInfo = evernoteSession.businessUser?.accounting;
                    account.consumedBytes = evernoteSession.businessUploadUsage;
                }

                account.totalBytes = accountingInfo?.uploadLimit.int64Value ?? 0;

                if(nil != syncState) {
                    account.consumedBytes = syncState!.uploaded.int64Value;
                }

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
            }
        })
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
        EvernoteSession.shared().authenticate(with: viewController, preferRegistration: false, completion: { error in
            self.clearEvernotePersistentData();
            completion(EvernoteSession.shared().isAuthenticated)
        })
        #endif
    }

    override func logOut(_ onCompletion : @escaping ((Bool) -> Void)) {
        #if !targetEnvironment(macCatalyst)
        let evernoteSession = EvernoteSession.shared;
        if (evernoteSession.isAuthenticated) {
            evernoteSession.unauthenticate();
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
