//
//  FTRemoteMessagePopupController.swift
//  Noteshelf
//
//  Created by Amar on 9/2/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//
#if !targetEnvironment(macCatalyst)
import Foundation
import FirebaseRemoteConfig
import FTCommon

@objc enum FTRemoteConfigMessageType : Int{
    case none = 0
    case criticalUpdateComingSoon
    case criticalUpdateAvailable
    case newUpdateAvailable
    case info
}

struct FTRemoteAlertOptions : OptionSet {
    let rawValue: Int
    static let Default         = FTRemoteAlertOptions(rawValue: 1 << 0)
    static let DontShow  = FTRemoteAlertOptions(rawValue: 1 << 1)
    static let LearnMore = FTRemoteAlertOptions(rawValue: 1 << 2)
    static let UpgradeNow  = FTRemoteAlertOptions(rawValue: 1 << 3)
    static let Later  = FTRemoteAlertOptions(rawValue: 1 << 4)
}

@objcMembers class FTRemoteMessagePopupController : NSObject
{
    fileprivate var remoteConfig : RemoteConfig?;
    
    convenience init(remoteConfig : RemoteConfig?) {
        self.init();
        self.remoteConfig = remoteConfig;
    }
    
    func popUpAppropriateMessage() {
        let messageType = self.messageType();
        if(messageType == FTRemoteConfigMessageType.none) {
            return;
        }
        else {
            if(self.shouldShowMessage()) {
                switch messageType {
                case .criticalUpdateComingSoon:
                    self.showCriticalUpdateAvailableSoonDialog();
                case .criticalUpdateAvailable:
                    self.showCriticalUpdateAvailableDialog();
                case .newUpdateAvailable:
                    self.showNewUpdateAvailableDialog();
                case .info:
                    self.showInfoDialog();
                default:
                    break;
                }
            }
        }
    }

    //MARK-  message
    fileprivate func showCriticalUpdateAvailableSoonDialog()
    {
        let title = NSLocalizedString("CriticalUpdateComingSoon", comment: "Critical Update available Soon");
        var options : FTRemoteAlertOptions = FTRemoteAlertOptions.Default;
        if(nil != self.messageUUID()) {
            options.insert(FTRemoteAlertOptions.DontShow);
        }
        if(nil != self.learnMoreID()) {
            options.insert(FTRemoteAlertOptions.LearnMore);
        }
        self.showAlert(title, actions: options);
    }

    fileprivate func showCriticalUpdateAvailableDialog()
    {
        let title = NSLocalizedString("CriticalUpdateAvailable", comment: "Critical Update available Soon");
        var options : FTRemoteAlertOptions = [FTRemoteAlertOptions.UpgradeNow,FTRemoteAlertOptions.Later];
        if(nil != self.messageUUID()) {
            options.insert(FTRemoteAlertOptions.DontShow);
        }
        if(nil != self.learnMoreID()) {
            options.insert(FTRemoteAlertOptions.LearnMore);
        }
        self.showAlert(title, actions: options);
    }

    fileprivate func showNewUpdateAvailableDialog()
    {
        let key = self.lastShownUpdateAvailableTimeKey();
        
        let lastUpdatedTime = UserDefaults.standard.double(forKey: key);
        let currenttime = Date.timeIntervalSinceReferenceDate;
        if((currenttime - lastUpdatedTime) > 24*60*60)
        {
            let title = NSLocalizedString("UpdateAvailable", comment: "Critical Update available Soon");
            var options : FTRemoteAlertOptions = [FTRemoteAlertOptions.UpgradeNow,FTRemoteAlertOptions.Later];
            if(nil != self.messageUUID()) {
                options.insert(FTRemoteAlertOptions.DontShow);
            }
            if(nil != self.learnMoreID()) {
                options.insert(FTRemoteAlertOptions.LearnMore);
            }
            
            self.showAlert(title, actions: options);
            UserDefaults.standard.set(currenttime, forKey: key);
            UserDefaults.standard.synchronize();
        }
    }

    fileprivate func showInfoDialog()
    {
        let messageID = self.messageUUID();
        if(messageID == nil) {
            return;
        }
        
        let messageKey = self.remoteConfigMessageTextKey();
        let message = self.remoteConfig?.configValue(forKey: messageKey).stringValue;
        if(message != nil) {
            var options : FTRemoteAlertOptions = [FTRemoteAlertOptions.Default];
            if(nil != self.learnMoreID()) {
                options.insert(FTRemoteAlertOptions.LearnMore);
            }
            let dontShowMessageID = "Do_not_show_\(messageID!)";
            UserDefaults.standard.set(true, forKey: dontShowMessageID);
            UserDefaults.standard.synchronize();

            self.showAlert(message!, actions: options);
        }
    }
    
    func showAlert(_ title : String,actions : FTRemoteAlertOptions) {
        let messageID = self.messageUUID();
        
        let alertController = UIAlertController.init(title: title, message: nil, preferredStyle: UIAlertController.Style.alert);
        
        if(actions.contains(.UpgradeNow)) {
            let action = FTRemoteUpgradeNowAlertAction.init(messageUUID: messageID);
            alertController.addAction(action);
        }

        if(actions.contains(.Later)) {
            let action = FTRemoteRemindLaterAlertAction.init(messageUUID: messageID);
            alertController.addAction(action);
        }

        if(actions.contains(.DontShow)) {
            let action = FTRemoteDontShowAlertAction.init(messageUUID: messageID);
            alertController.addAction(action);
        }

        if(actions.contains(.LearnMore)) {
            let action = FTRemoteLearnMoreAlertAction.init(messageUUID: messageID);
            action.articleId = self.learnMoreID()!;
            alertController.addAction(action);
        }

        if(actions.contains(.Default)) {
            let action = FTRemoteAlertAction.init(messageUUID: messageID);
            alertController.addAction(action);
        }

        Application.keyWindow?.visibleViewController?.present(alertController, animated: true, completion: nil);
    }
    
    //MARK- other helpers
    fileprivate func messageUUID() -> String?
    {
        let configKey = self.remoteConfigMessageUUIDKey();
        let messageUUID = self.remoteConfig?.configValue(forKey: configKey).stringValue;
        if(messageUUID?.count == 0){
            return nil;
        }
        return messageUUID;
    }
    
    fileprivate func learnMoreID() -> String?
    {
        let configKey = self.remoteConfigLearnMoreKey();
        let learnMoreID = self.remoteConfig?.configValue(forKey: configKey).stringValue;

        if(learnMoreID?.count == 0){
            return nil;
        }
        return learnMoreID;
    }

    fileprivate func shouldShowMessage() -> Bool
    {
        var shouldShowMessage = true;

        let messageUUID = self.messageUUID();
        if(messageUUID != nil) {
            let messageID = messageUUID!;
            let dontShowMessageID = "Do_not_show_\(messageID)";
            shouldShowMessage = !UserDefaults.standard.bool(forKey: dontShowMessageID);
        }
        return shouldShowMessage;
    }
    
    fileprivate func messageType() -> FTRemoteConfigMessageType
    {
        var messageType = FTRemoteConfigMessageType.none;
        if(self.remoteConfig != nil) {
            let messageKey = self.remoteConfigMessageShowKey();
            let valueNumber = self.remoteConfig?.configValue(forKey: messageKey).numberValue;
            if(valueNumber != nil) {
                let newMessageType = FTRemoteConfigMessageType.init(rawValue: valueNumber!.intValue);
                if(newMessageType != nil) {
                    messageType = newMessageType!;
                }
            }
        }
        return messageType;
    }
    
    //MARK- Remote Config Keys
    fileprivate func remoteConfigMessageUUIDKey() -> String
    {
        let appVersion1 = self.formattedAppVersion();
        let envPrefix = appEnviromentPrefix();
        let configKey = "\(envPrefix)_message_uuid_\(appVersion1)";
        return configKey;
    }

    fileprivate func remoteConfigMessageShowKey() -> String
    {
        let appVersion1 = self.formattedAppVersion();
        let envPrefix = appEnviromentPrefix();
        let messageKey = "\(envPrefix)_message_show_\(appVersion1)";
        return messageKey;
    }

    fileprivate func remoteConfigLearnMoreKey() -> String
    {
        let appVersion1 = self.formattedAppVersion();
        let envPrefix = appEnviromentPrefix();
        let configKey = "\(envPrefix)_message_learn_more_\(appVersion1)";
        return configKey;
    }

    fileprivate func remoteConfigMessageTextKey() -> String
    {
        let appVersion1 = self.formattedAppVersion();
        let envPrefix = appEnviromentPrefix();
        let configKey = "\(envPrefix)_message_text_\(appVersion1)";
        return configKey;
    }
    
    //MARK- appVersion
    fileprivate func formattedAppVersion() -> String
    {
        return (appVersion() as NSString).replacingOccurrences(of: ".", with: "_");
    }
    
    //MARK- User Default Keys
    fileprivate func lastShownUpdateAvailableTimeKey() -> String
    {
        let envPrefix = appEnviromentPrefix();
        let userDefaultKey = "Update_available_\(self.formattedAppVersion())";
        let key = "\(envPrefix)_last_shown_\(userDefaultKey)";
        return key;
    }
}
#endif
