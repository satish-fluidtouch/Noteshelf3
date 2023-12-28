//
//  FabricHelper.swift
//  Noteshelf
//
//  Created by Akshay on 28/03/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import FirebaseCrashlytics
import Foundation
import FTDocumentFramework
import FTCommon

struct FabircKeys {
    //Boolean Values
    static let iCloud = "iCloud"
    static let Pencil = "ApplePencil"
    static let Watch = "AppleWatch"
    static let Club = "Club"
    static let ENPublish = "ENPublish"

    //String values
    static let Language = "Lang"
    static let Theme = "Theme"
    static let Locale = "Locale"
    static let Recognition = "Recognition"
    static let RecognitionActivated = "Recog_Act"
    static let FavoriteBarStatus = "FavoriteBarStatus"

    static let Clouds = "Clouds"
    static let Layout = "Layout"
    static let Premium = "Premium"
    static let Noteshelf2 = "NS2"
    static let SafeMode = "SafeMode"
    static let DeviceIDs = "DeviceIDs"
}

class FabricHelper: NSObject {

    class func configure() {
        if let userId = UserDefaults.standard.object(forKey: "USER_ID_FOR_CRASH") as? String {
            Crashlytics.crashlytics().setUserID(userId)
            FTUbiquitousKeyValueStoreListner.shared().addUserID(userId);
        }
        let isPaired = NSUbiquitousKeyValueStore.default.isWatchPaired()
        let isWatchAppInstalled = NSUbiquitousKeyValueStore.default.isWatchAppInstalled()
        var watchStatus = isPaired ? "N/I" : "N/A";
        if(isWatchAppInstalled) {
            watchStatus = "Installed";
        }

        var keys = [String: String]()
        keys[FabircKeys.iCloud] = FTNSiCloudManager.shared().iCloudOn().asString
        keys[FabircKeys.Pencil] = UserDefaults.standard.bool(forKey: "isUsingApplePencil").asString
        keys[FabircKeys.Watch] = watchStatus
        keys[FabircKeys.ENPublish] = UserDefaults.standard.bool(forKey: "EvernotePubUsed").asString

        keys[FabircKeys.Language] = FTUtils.currentLanguage()
        keys[FabircKeys.Theme] = FTShelfThemeStyle.defaultTheme().title
        keys[FabircKeys.Locale] = Locale.current.identifier

        keys[FabircKeys.Clouds] = FTZenDeskManager.cloudUsed()
        keys[FabircKeys.Recognition] = FTNotebookRecognitionHelper.shouldProceedRecognition ? "YES" : "NO";
        keys[FabircKeys.RecognitionActivated] = FTNotebookRecognitionHelper.myScriptActivated ? "YES" : "NO";
        keys[FabircKeys.Layout] = (UserDefaults.standard.pageLayoutType == .vertical) ? "Vertical" : "Horizontal";
        keys[FabircKeys.Premium] = FTIAPManager.shared.premiumUser.isPremiumUser ? "YES" : "NO"
        keys[FabircKeys.Noteshelf2] = FTDocumentMigration.isNS2AppInstalled() ? "YES" : "NO"
        keys[FabircKeys.SafeMode] = FTUserDefaults.isInSafeMode() ? "YES" : "NO"
        
        let deviceInfo = FTUbiquitousKeyValueStoreListner.shared().deviceIdsForFabric();
        if !deviceInfo.isEmpty {
            keys[FabircKeys.DeviceIDs] = deviceInfo;
        }
        Crashlytics.crashlytics().setCustomValue(keys, forKey: "Startup Keys")
    }

    class func updateFabric(key: String, value: Any) {
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }
    
    class func updatePageLayout(_ layout: FTPageLayout) {
        FabricHelper.updateFabric(key: FabircKeys.Layout, value: (layout == .vertical) ? "Vertical" : "Horizontal");
    }
}

extension Bool {
    var asString: String {
        return self ? "true" : "false"
    }
}
