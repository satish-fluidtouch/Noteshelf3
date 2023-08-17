//
//  FTDropboxManager.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 02/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import SwiftyDropbox

typealias FTDropboxAuthenticateCallback = (Bool, Bool) -> Void
typealias FTDropboxAccountInfoCallback = (FTBackUpAccountInfo?, Error?) -> Void

@objc class FTDropboxManager: NSObject {
    private var authCallBack: FTDropboxAuthenticateCallback?
    private var accountInfo: FTBackUpAccountInfo?
    private var accInfoCallBackArray: [FTDropboxAccountInfoCallback]?
    
    @objc static let sharedDropboxManager = FTDropboxManager()
   
    override init() {
        super.init()
        self.accInfoCallBackArray = [FTDropboxAccountInfoCallback]()
        NotificationCenter.default.addObserver(self, selector: #selector(dropboxClientUnlinked(_:)), name: NSNotification.Name(rawValue: FTDidUnlinkAllDropboxClient), object: nil)
    }
    
    @objc func isLoggedIn() -> Bool {
        return DropboxClientsManager.authorizedClient != nil
    }
    
    func authenticateToDropBox(from controller: UIViewController?,
                               onCompletion completionHandler: @escaping FTDropboxAuthenticateCallback) {
        authCallBack = completionHandler
        //
        DropboxClientsManager.authorizeFromControllerV2(UIApplication.shared,
                                                        controller: controller,
                                                        loadingStatusDelegate: nil,
                                                        openURL: { url in
                                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }, scopeRequest: nil) //TODO: (AK) update to V2 Swift API
        NotificationCenter.default.addObserver(self, selector: #selector(didCompleteDropBoxAuthetication(_:)), name: NSNotification.Name(rawValue: FTDidCompleteDropBoxAuthetication), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didCancelDropBoxAuthetication(_:)), name: NSNotification.Name(rawValue: FTDidCancelDropBoxAuthetication), object: nil)
    }

    @objc func didCancelDropBoxAuthetication(_ notification: Notification?) {
        NotificationCenter.default.removeObserver(self)
        if (authCallBack != nil) {
            authCallBack?(false, true)
            authCallBack = nil
        }
    }

    @objc func didCompleteDropBoxAuthetication(_ notification: Notification?) {
        NotificationCenter.default.removeObserver(self)
        if (authCallBack != nil) {
            authCallBack?(true, false)
            authCallBack = nil
        }
    }
    
    func signOut(onCompletionHandler block: GenericSuccessBlock) {
        DropboxClientsManager.unlinkClients()
        NotificationCenter.default.post(name: Notification.Name(FTDidUnlinkAllDropboxClient), object: nil)
        block(true)
    }
    
    func accountInfo(onCompletion completionHandler: @escaping FTDropboxAccountInfoCallback) {
        if (accountInfo != nil){
            completionHandler(accountInfo, nil)
        }
        accInfoCallBackArray?.append(completionHandler)
        loadAccountInfo()
    }
    
    @objc func dropboxClientUnlinked(_ notification: Notification?) {
        NotificationCenter.default.removeObserver(self)
        accountInfo = nil
    }
    
    func loadAccountInfo() {
        let client = DropboxClientsManager.authorizedClient
        client?.users.getCurrentAccount().response(completionHandler: { (account, error) in
            if let result = account {
                let accountInfo = FTBackUpAccountInfo()
                accountInfo.name = result.name.displayName
                client?.users.getSpaceUsage().response(completionHandler: { (resultValue, routeError) in
                    if let result = resultValue {
                        switch result.allocation {
                        case .individual(let space):
                            accountInfo.consumedBytes = result.used
                            accountInfo.totalBytes = space.allocated
                        case .team(let space):
                            accountInfo.consumedBytes = space.used
                            accountInfo.totalBytes = space.allocated
                        default:
                            break
                        }
                    }
                    self.accInfoCallBackArray?.forEach({ (eachInfo) in
                        eachInfo(accountInfo, nil)
                    })
                    self.accInfoCallBackArray?.removeAll()
                })
                self.accountInfo = accountInfo
            }
            self.accInfoCallBackArray?.forEach({ (eachInfo) in
                switch error {
                case .authError:
                    NotificationCenter.default.post(name: NSNotification.Name("DBLoggedOut"), object: nil)
                case .clientError(let err):
                    eachInfo(nil, err)
                default:
                    eachInfo(nil, nil)
                }
            })
        })
    }
}
