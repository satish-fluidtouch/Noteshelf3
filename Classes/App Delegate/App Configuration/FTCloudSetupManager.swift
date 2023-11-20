//
//  FTCloudSetupManager.swift
//  Noteshelf
//
//  Created by Akshay on 28/06/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import SwiftyDropbox
import FTDocumentFramework
import FirebaseCore

import GoogleSignIn

//MARK: - Cloud Drive Setup
final class FTCloudSetupManager {

    static func configure() {
        configureCloudDrives()
    }

    private static func configureCloudDrives() {
        FTNSiCloudManager.shared().defaultUserDefaults = FTUserDefaults.defaults()
        
        //Dropbox setup
        DropboxClientsManager.setupWithAppKey(dropboxAppKey)
        
        //Google Drive setup
        FTGoogleDriveClient.shared.signInSilently();
        //Evernote session setup
        #if !targetEnvironment(macCatalyst)
        EvernoteSession.setSharedSessionHost("www.evernote.com", consumerKey: EVERNOTE_CONSUMER_KEY, consumerSecret: evernoteConsumerSecret)
        #endif
    }
}

private extension FTCloudSetupManager {
    
    static var dropboxAppKey: String {
        return "25u7ct2k9iro3ka";
    }

    static var evernoteConsumerSecret: String {
        return "d6cf9eb19478fc157ef4425036d0c13f06256fba1ee87d54aa816885";
    }
    
    static var oneDriveClientID : String {
        #if DEBUG
        return "00000000401E4308"
        #elseif RELEASE
        return "000000004C1EAB29"
        #else
        return "00000000401EDA38"
        #endif
    }
    
    static var oneDriveBusinessAppID : String {
        return "c0447e05-bcac-429e-a47c-45370474da2f";
    }
}
