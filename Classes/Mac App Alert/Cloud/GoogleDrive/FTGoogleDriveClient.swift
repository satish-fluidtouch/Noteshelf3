//
//  FTGoogleDriveClient.swift
//  Noteshelf
//
//  Created by sreenu cheedella on 16/04/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST_Drive
import Firebase

protocol FTBackUpClient {
    func isLoggedIn() -> Bool
    func login(onController: UIViewController, onCompletion: ((GIDGoogleUser?, Error?) -> Void)?)
    func signOut(onCompletion: (Bool)->(Void))
}

class FTGoogleDriveClient: NSObject, FTBackUpClient {
    static let shared: FTGoogleDriveClient = FTGoogleDriveClient()
    private var currentOnCompletion: ((GIDGoogleUser?, Error?) -> Void)?
    
    override init() {
        super.init();
    }
    
    func signInSilently() {
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            GIDSignIn.sharedInstance.restorePreviousSignIn { _, _ in
                
            };
        }
    }
    
    func isLoggedIn() -> Bool {
        return GIDSignIn.sharedInstance.currentUser != nil
    }
    
    func login(onController: UIViewController, onCompletion: ((GIDGoogleUser?, Error?) -> Void)?){
        if (GIDSignIn.sharedInstance.currentUser) != nil {
            GIDSignIn.sharedInstance.restorePreviousSignIn{ _, _ in
                
            }
        } else {
            if let clientUD = FirebaseApp.app()?.options.clientID {
                let cong = GIDConfiguration(clientID: clientUD);
                GIDSignIn.sharedInstance.configuration = cong;
                GIDSignIn.sharedInstance.signIn(withPresenting: onController) { result, error in
                    if let inerror = error {
                        onCompletion?(result?.user,inerror)
                    }
                    else if let scopes =  result?.user.grantedScopes, scopes.contains(kGTLRAuthScopeDriveFile) {
                        onCompletion?(result?.user,error)
                    }
                    else {
                        GIDSignIn.sharedInstance.currentUser?.addScopes([kGTLRAuthScopeDriveFile], presenting: onController)
                    }
               }
            }
        }
    }
    
    func signOut(onCompletion: (Bool)->(Void)) {
        GIDSignIn.sharedInstance.signOut()
        onCompletion(true)
    }
    
    func authenticationService() -> GTLRDriveService {
        let service = GTLRDriveService()
        let sharedInstance = GIDSignIn.sharedInstance
        service.authorizer = sharedInstance.currentUser?.fetcherAuthorizer
        return service
    }
}

struct FTGoogleDriveError {
    private static let errorDomain = "com.fluidtouch.googleDrive"
    
    private static var badRequestError: NSError {
        return NSError.init(domain: self.errorDomain, code: 400, userInfo: [NSLocalizedDescriptionKey : "Trouble uploading the document, please try again"])
    }
    
    private static var authenticationError: NSError {
        return NSError.init(domain: self.errorDomain, code: 401, userInfo: [NSLocalizedDescriptionKey : "Your session expired, please login again."])
    }
    
    private static func forbiddenError(_ withError: NSError) -> NSError {
        var errorDescription = withError.errorDescription()
        if withError.errorDescription().contains("Properties and app properties are limited to 124 bytes") {
            errorDescription = "Character Limit Exceeded. Please choose a smaller notebook name."
        }
        
        return NSError.init(domain: self.errorDomain, code: 403, userInfo: [NSLocalizedDescriptionKey:errorDescription])
    }
    
    private static var fileNotFoundError: NSError {
        return NSError.init(domain: self.errorDomain, code: 404, userInfo: [NSLocalizedDescriptionKey : "File not found"])
    }
    
    private static var tooManyReuestsError: NSError {
        return NSError.init(domain: self.errorDomain, code: 429, userInfo: [NSLocalizedDescriptionKey : "Too many requests"])
    }
    
    private static var serverSideError: NSError {
        return NSError.init(domain: self.errorDomain, code: 500, userInfo: [NSLocalizedDescriptionKey : "Server is facing some trouble"])
    }
    
    private static func defaultError(_ withError: NSError)-> NSError {
        return NSError.init(domain: self.errorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : withError.errorDescription()])
    }
    
    static var cloudBackupError: Error {
        return NSError.init(domain: FTGoogleDriveError.errorDomain, code: 102, userInfo: [NSLocalizedDescriptionKey: "Cloud backup error"])
    }
    
    static func error(withError: NSError) -> NSError {
        switch withError.code {
        case 400:
            return badRequestError
        case 401:
            return authenticationError
        case 403:
            return forbiddenError(withError)
        case 404:
            return fileNotFoundError
        case 429:
            return tooManyReuestsError
        case 500:
            return serverSideError
        default:
            return defaultError(withError)
        }
    }
}
