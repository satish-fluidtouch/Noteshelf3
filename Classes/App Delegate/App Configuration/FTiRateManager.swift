//
//  FTiRateManager.swift
//  Noteshelf
//
//  Created by Akshay on 11/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon
final class FTiRateManager: NSObject {
    static func configureiRate(delegate : iRateDelegate?) {
        iRate.sharedInstance()?.delegate = delegate
        if FTIAPManager.shared.premiumUser.isPremiumUser
            , !(iRate.sharedInstance().declinedAnyVersion || iRate.sharedInstance().ratedAnyVersion) {
            iRate.sharedInstance()?.promptForNewVersionIfUserRated = false;
            iRate.sharedInstance()?.promptAtLaunch = true;
            iRate.sharedInstance()?.eventsUntilPrompt = 5
            iRate.sharedInstance()?.daysUntilPrompt = 0
            iRate.sharedInstance()?.usesUntilPrompt = 30
            iRate.sharedInstance()?.updateLastVersionReviewedDate()
        }
        else {
            iRate.sharedInstance()?.promptAtLaunch = false;
            reset();
        }
    }

    static func reset() {
        iRate.sharedInstance()?.usesCount = 0;
        iRate.sharedInstance()?.eventCount = 0;
    }

    static func writeReviewOnAppstore() {
        iRate.sharedInstance()?.openRatingsPageInAppStore()
    }

    @objc class func logEvent() {
        if FTIAPManager.shared.premiumUser.isPremiumUser {
            iRate.sharedInstance()?.logEvent(true)
        }
    }

    static func checkForApplicationForegroundActions() {
#if !targetEnvironment(macCatalyst)
        runInMainThread {
            if !FTIAPManager.shared.premiumUser.isPremiumUser {
                iRate.sharedInstance()?.promptAtLaunch = false;
                reset();
            }
            else {
                iRate.sharedInstance()?.promptAtLaunch = FTAppConfigHelper.sharedAppConfig().shouldShowiRate();
            }
        }
//        if iRate.sharedInstance().usesCount >= 1 {
//            //Assuming it is not using in our app, so just avoiding error here
//            if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
//                FTPermissionManager.askForSiriPermission(onController: rootViewController, shouldForce:false, completion:nil)
//            }
//        }
#endif
    }
}

extension NoteshelfAppDelegate : iRateDelegate
{
    //MARK:- iRateDelegate
    func iRateUserDidAttemptToRateApp() {
        track("iRate", params: ["action":"Attempted"], screenName: "iRate Screen")
    }
    
    func iRateUserDidDeclineToRateApp() {
        track("iRate", params: ["action":"Declined"], screenName: "iRate Screen")
    }
    
    func iRateUserDidRequestReminderToRateApp() {
        track("iRate", params: ["action":"Reminder later"], screenName: "iRate Screen")
    }
}
