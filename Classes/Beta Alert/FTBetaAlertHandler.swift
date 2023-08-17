//
//  FTBetaAlertHandler.swift
//  Noteshelf
//
//  Created by Amar on 23/08/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
#if !targetEnvironment(macCatalyst)
private var shouldMaskBeta = false;
#else
private var shouldMaskBeta = true;
#endif

extension UIApplication
{
    func firstForegroundScene() -> UIWindowScene?
    {
        var windowScene : UIScene?;
        let connectedScenes = self.connectedScenes;
        windowScene = connectedScenes.first { (scene) -> Bool in
            if(scene.activationState == .foregroundActive) {
                return true;
            }
            return false;
        }
        return windowScene as? UIWindowScene;
    }
}

class FTBetaAlertHandler: NSObject {

    @objc class func initializeForFreshInstall()
    {
        if #available(iOS 13.0, *) {
            UserDefaults.standard.markAsRemindMeLaterForBetaAlert();
        }
    }
    
    static func showiOS13BetaAlertIfNeeded(onViewController : UIViewController) {
        if(canShowBetaAlert()) {
            if #available(iOS 13.0, *) {
                guard let curWindow = onViewController.view.window?.windowScene,
                let firstScene = UIApplication.shared.firstForegroundScene() else {
                    return;
                }
            }
        }
    }
    
    static func hasBetaURL() -> Bool {
        if #available(iOS 13.0, *),!shouldMaskBeta {
            if nil != FTAppConfigHelper.sharedAppConfig().betaTestingAppURL() {
                return true;
            }
        }
        return false;
    }
    
    private static func canShowBetaAlert() -> Bool
    {
        if(self.hasBetaURL()) {
            return UserDefaults.standard.canShowBetaAlert();
        }
        return false;
    }
}

private enum FTBetaAlertState : String {
    case dontShow = "dontshow"
    case remindLater = "remind_later"
    
    func stateKey() -> String
    {
        let key = FTAppConfigHelper.sharedAppConfig().betaTestingAppVersionKey();
        return key.appending("_\(self.rawValue)");
    }
}

@objc extension UserDefaults
{
    func canShowBetaAlert() -> Bool {
        let dontShowAgain = self.bool(forKey: FTBetaAlertState.dontShow.stateKey());
        if(!dontShowAgain) {
            let nowInSeconds = Date().timeIntervalSinceReferenceDate;
            let reminderTimeInSeconds = self.double(forKey: FTBetaAlertState.remindLater.stateKey());
            if nowInSeconds > reminderTimeInSeconds {
                return true;
            }
        }
        return false;
    }
    
    func markAsRemindMeLaterForBetaAlert()
    {
        #if DEBUG
        let tomorrowInSeconds = Date().addingTimeInterval(20).timeIntervalSinceReferenceDate;
        #elseif BETA
        let tomorrowInSeconds = Date().addingTimeInterval(1*60).timeIntervalSinceReferenceDate;
        #else
        let tomorrowInSeconds = Date().addingTimeInterval(24*60*60).timeIntervalSinceReferenceDate;
        #endif
        self.set(tomorrowInSeconds, forKey: FTBetaAlertState.remindLater.stateKey());
        self.synchronize();
    }
    
    func markAsDontShowAgainForBetaAlert()
    {
        self.set(true, forKey: FTBetaAlertState.dontShow.stateKey());
        self.synchronize();
    }
}
