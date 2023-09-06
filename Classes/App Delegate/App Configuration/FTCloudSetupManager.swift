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
        ENSession.setSharedSessionConsumerKey(EVERNOTE_CONSUMER_KEY,
                                              consumerSecret: evernoteConsumerSecret,
                                              optionalHost: nil)
        
        //Evernote Sandbox Session setup
        //Enable below line for sandbox
//        ENSession.setSharedSessionConsumerKey(EVERNOTE_CONSUMER_KEY,
//                                              consumerSecret: evernoteConsumerSecret,
//                                              optionalHost: ENSessionHostSandbox)
        
        ENSession.shared.logger = nil
        #endif
    }
}

private extension FTCloudSetupManager {
    
    static var dropboxAppKey: String {
        return "25u7ct2k9iro3ka";
    }

    static var evernoteConsumerSecret: String {
        return "7c45c3fb78eb6dba";
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
