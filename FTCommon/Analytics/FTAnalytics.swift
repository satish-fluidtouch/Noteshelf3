//
//  FTAnalytics.swift
//  MetricsDemo
//
//  Created by Akshay on 03/04/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon
import GoogleSignIn
import FirebaseAnalytics
import Firebase
import FirebaseCore
import FirebaseCrashlytics


 func track(_ event: String, params: [String: Any]? = nil, screenName: String? = nil,shouldLog: Bool = true) {
    FTMetrics.shared.track(event: event, params: params,screeName: screenName)
    if shouldLog {
        FTCLSLog(event + (params?.description ?? ""))
    }
}

 func setScreenName(_ screenName: String, screenClass: String?) {
    FTMetrics.shared.trackScreen(with: screenName, screenClass: screenClass)
}

@objc extension Crashlytics {
    func crash() {
        fatalError("Force Crash");
    }
}

@objc
class FTAnalytics: NSObject {

    @objc
    class func start(application: UIApplication,
                     with launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {

        configureFirebase(with:launchOptions)
//        AppDelegate.application(application, didFinishLaunchingWithOptions: launchOptions)
        #if DEBUG
            FTMetrics.start(with: [.firebase], loglevel: FTMetricsLogLevel.debug)
        #else
            FTMetrics.start(with: [.firebase])
        #endif
        if let userid = UserDefaults.standard.object(forKey: "USER_ID_FOR_CRASH") as? String {
            FTMetrics.shared.setUserId(userId: userid)
        }
        clearEventsIfNeeded()
    }
}

//MARK: - Private
private extension FTAnalytics {
    
    private class func clearEventsIfNeeded() {
        if let _ = UserDefaults.standard.object(forKey: "PenSetSessionEvents") as? NSDictionary {
            UserDefaults.standard.removeObject(forKey: "PenSetSessionEvents")
        }
        if let _ = UserDefaults.standard.object(forKey: "PenSetUniqueColorEvents") as? NSDictionary {
            UserDefaults.standard.removeObject(forKey: "PenSetUniqueColorEvents")
        }
    }

    private class func configureFirebase(with launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        let firebaseConfig = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist")

        if UserDefaults.standard.string(forKey: "USER_ID_FOR_CRASH") == nil {
            UserDefaults.standard.set((FTUtils.getUUID() as NSString).substring(to: 8), forKey: "USER_ID_FOR_CRASH")
            UserDefaults.standard.synchronize()
        }

        guard let options = FirebaseOptions(contentsOfFile: firebaseConfig ?? "") else {
            fatalError("Invalid Firebase configuration file.")
        }
        FirebaseApp.configure(options: options)
        Analytics.setUserID(UserDefaults.standard.string(forKey: "USER_ID_FOR_CRASH"))
    }

}

func startPerfTracking(event: String, params: [String: Any]? = nil, shouldLog: Bool = true) {
    FTMetrics.shared.startTrackingPerformance(for: event, params: params)
    if shouldLog {
        FTCLSLog("PERF: Start" + event + (params?.description ?? ""))
    }
}

func stopPerfTracking(event: String, params: [String: Any]? = nil, shouldLog: Bool = true) {
    FTMetrics.shared.stopTrackingPerformance(for: event, params: params)
    if shouldLog {
        FTCLSLog("PERF: Stop" + event + (params?.description ?? ""))
    }
}
