//
//  FTOneDriveClient.swift
//  OneDriveDemo
//
//  Created by Simhachalam Naidu on 13/09/19.
//  Copyright © 2019 Simhachalam Naidu. All rights reserved.
//

import UIKit
import MSGraphMSALAuthProvider

public let kGraphURI = "https://graph.microsoft.com/v1.0"
class FTOneDriveClient: NSObject {
    
    @objc static let shared: FTOneDriveClient = FTOneDriveClient()
    
    private static var oneDriveRedirectUri : String = "www.noteshelf.net://auth"
    
    private let kClientID : String = "c0447e05-bcac-429e-a47c-45370474da2f"
    let kAuthority = "https://login.microsoftonline.com/common"
    
    private let kScopes: [String] = ["https://graph.microsoft.com/user.read", "https://graph.microsoft.com/files.readwrite"]

    private var authorityURL: URL {
        return URL(string: self.kAuthority)!
    }
    private var applicationContext : MSALPublicClientApplication?

    private lazy var authProvider: MSAuthenticationProvider = {
        let authProviderOptions: MSALAuthenticationProviderOptions = MSALAuthenticationProviderOptions.init(scopes: kScopes)
        let authenticationProvider = MSALAuthenticationProvider(publicClientApplication: self.applicationContext, andOptions: authProviderOptions)
       return authenticationProvider!
    }()
    private lazy var httpClient: MSHTTPClient = {
        return MSClientFactory.createHTTPClient(with: self.authProvider)
    }()

    override init() {
        super.init()
        do {
            let authority = try MSALAADAuthority(url: authorityURL)
            let msalConfiguration = MSALPublicClientApplicationConfig(clientId: kClientID, redirectUri: FTOneDriveClient.oneDriveRedirectUri, authority: authority)
            self.applicationContext = try MSALPublicClientApplication(configuration: msalConfiguration)
        }
        catch {
            //Handle error
        }
    }
    private func currentAccount() -> MSALAccount? {
        guard let applicationContext = self.applicationContext else { return nil }
        // We retrieve our current account by getting the first account from cache
        // In multi-account applications, account should be retrieved by home account identifier or username instead
        do {
            let cachedAccounts = try applicationContext.allAccounts()
            if !cachedAccounts.isEmpty {
                return cachedAccounts.first
            }
        } catch {
            return nil
        }
        return nil
    }

    func login(onController: UIViewController,
               onCompletion: ((MSALAccount?, Error?) -> Void)?) {
        guard let applicationContext = self.applicationContext else {
            onCompletion?(nil, FTOneDriveError.authenticationError)
            return
        }
        // We retrieve our current account by getting the first account from cache
        // In multi-account applications, account should be retrieved by home account identifier or username instead
        if let account = self.currentAccount() {
            let parameters = MSALSilentTokenParameters(scopes: self.kScopes, account: account)
            applicationContext.acquireTokenSilent(with: parameters) { (result, error) in
                if let error = error {
                    let nsError = error as NSError
                    if (nsError.domain == MSALErrorDomain) {
                        if (nsError.code == MSALError.interactionRequired.rawValue) {
                            DispatchQueue.main.async {
                                let params = MSALInteractiveTokenParameters.init(scopes: self.kScopes, webviewParameters: MSALWebviewParameters.init(parentViewController: onController))
                                params.promptType = MSALPromptType.login
                                applicationContext.acquireToken(with: params) { (result, error) in
                                  onCompletion?(result?.account, error)
                                }
                            }
                            return
                        }
                    }
                    return
                }
                guard let result = result else {
                    onCompletion?(nil, FTOneDriveError.authenticationError)
                    return
                }
                onCompletion?(result.account, nil)
            }
        }
        else {
            DispatchQueue.main.async {
                let params = MSALInteractiveTokenParameters.init(scopes: self.kScopes, webviewParameters: MSALWebviewParameters.init(parentViewController: onController))
                params.promptType = MSALPromptType.login
                applicationContext.acquireToken(with: params) { (result, error) in
                  onCompletion?(result?.account, error)
                }
            }
        }
    }
    @objc func isLoggeedIn() -> Bool{
        return self.currentAccount() != nil
    }
    func signOut(withCompletion onCompletion: ((Bool) -> Void)?){
        guard let applicationContext = self.applicationContext, let account = self.currentAccount() else
        {
            onCompletion?(false)
            return
        }
        do {
            try applicationContext.remove(account)
            onCompletion?(true)
        } catch {
            onCompletion?(false)
        }
    }
}

extension FTOneDriveClient {
    func getDriveInfoTask() -> FTOneDriveInfoTask {
        let task = FTOneDriveInfoTask.init(withHttpClient: self.httpClient)
        return task
    }
    func getFileListTask() -> FTOneDriveFileListTask {
        let task = FTOneDriveFileListTask.init(withHttpClient: self.httpClient)
        return task
    }
    func getUploadTask() -> FTOneDriveUploadTask {
        let task = FTOneDriveUploadTask.init(withHttpClient: self.httpClient)
        return task
    }
    func getFileInfoTask() -> FTOneDriveFileInfoTask {
        let task = FTOneDriveFileInfoTask.init(withHttpClient: self.httpClient)
        return task
    }
    func getDownloadTask() -> FTOneDriveDownloadTask {
        let task = FTOneDriveDownloadTask.init(withHttpClient: self.httpClient)
        return task
    }
    func getMoveTask() -> FTOneDriveMoveTask {
        let task = FTOneDriveMoveTask.init(withHttpClient: self.httpClient)
        return task
    }
}

struct FTOneDriveError {
    private static let errorDomain = "com.fluidtouch.onedrive"
    //==================
    static var authenticationError: Error {
        return NSError.init(domain: FTOneDriveError.errorDomain, code: 100, userInfo: [NSLocalizedDescriptionKey : "Authentication Error"])
    }
    //==================
    static var defaultError: Error {
        return NSError.init(domain: FTOneDriveError.errorDomain, code: 101, userInfo: [NSLocalizedDescriptionKey: "Unknown Error"])
    }
    static var cloudBackupError: Error {
        return NSError.init(domain: FTOneDriveError.errorDomain, code: 102, userInfo: [NSLocalizedDescriptionKey: "Cloud backup error"])
    }
    static var urlRequestError: Error {
        return NSError.init(domain: FTOneDriveError.errorDomain, code: 103, userInfo: [NSLocalizedDescriptionKey: "Invalid URL Request"])
    }

    static func uploadError(with code: Int) -> Error {
        if code == 413 {
            return NSError.init(domain: FTOneDriveError.errorDomain, code: code, userInfo: [NSLocalizedDescriptionKey: "Notebook too large to backup"])
        }
        else if code == 400 {
            return NSError.init(domain: FTOneDriveError.errorDomain, code: code, userInfo: [NSLocalizedDescriptionKey: "Invalid input error"])
        }
        return FTOneDriveError.defaultError
    }
    
    static func ftDomainError(_ error : Error?) -> Error {
        if let fterror = error as NSError? {
            let code = fterror.code;
            let defaultNSError = FTOneDriveError.defaultError as NSError;
            var error = FTOneDriveError.uploadError(with: code) as NSError
            if(error.code == defaultNSError.code) {
                error = NSError.init(domain: FTOneDriveError.errorDomain,
                                     code: code,
                                     userInfo: fterror.userInfo)
            }
            return error;
        }
        return FTOneDriveError.defaultError
    }
    //==================
}
