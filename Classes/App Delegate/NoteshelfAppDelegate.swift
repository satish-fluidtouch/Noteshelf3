//
//  NoteshelfAppDelegate.swift
//  Gallery
//
//  Created by Amar on 01/07/19.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FirebaseAnalytics
import FirebaseCrashlytics
import FTStyles
import FTTemplatesStore

let AppDelegate = UIApplication.shared.delegate as! NoteshelfAppDelegate

@objcMembers class NoteshelfAppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    // The font style check states used in the Style menu.
    var fontMenuStyleStates = Set<String>()

    //This works only for iOS 12
    private var rootViewController : UIViewController? {
        return self.window?.rootViewController
    }

    private var shortcutItemToProcess: UIApplicationShortcutItem?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        self.clearTempCache();
        FTStyles.registerFonts()
        FTImportStorageManager.resetCorruptedStatusWhenTerminated()
        FTCLSLog("--- didFinishLaunchingWithOptions ---")
        FTUserDefaults.configure()
        FTAnalytics.start(application: application, with: launchOptions)
        
        self.didCrashDuringPreviousExecution();
        
        FTIAPManager.shared.config();
        FTNoteshelfAIConfigHelper.configureAI();
        FTLanguageResourceManager.shared.activateOnDemandResourcesIfNeeded()
        if FTWhatsNewManger.shouldShowWhatsNew() {
            FTWhatsNewManger.start()
        }

        FTiRateManager.configureiRate(delegate: self);
        FTCloudSetupManager.configure()
        DataServices.shared().initializeDatabase()
        FabricHelper.configure()
        FTStyles.registerFonts()
        FTTextStyleManager.shared.copyStylesFromResourceIfRequired()
        if let shortcutItem = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            shortcutItemToProcess = shortcutItem
        }
        FTWhiteboardDisplayManager.shared.configure();
        FTDocumentCache.shared.start()
        FTStoreLibraryHandler.shared.start()
        FTStoreCustomTemplatesHandler.shared.start()
        FTSavedClipsProvider.shared.start()
        return true
    }


    func applicationWillResignActive(_ application: UIApplication) {
        FTCLSLog("--- resign active ---")

        FTCloudBackUpManager.shared.handleAppWillResignActive()

        UserDefaults.standard.synchronize()

        (rootViewController as? FTRootViewController)?.saveApplicationStateByClosingDocument(false, keepEditingOn: true, onCompletion: nil)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        FTCLSLog("--- became active ---")
        if let shortcutItem = shortcutItemToProcess, let handlingController = window?.rootViewController as? FTIntentHandlingProtocol {
            let handler = FTAppIntentHandler(with: handlingController)
            handler.handleShortcutItem(item: shortcutItem)
            shortcutItemToProcess = nil
        }

        FTCloudBackUpManager.shared.handleAppDidBecomeActive()

        ServerURLManager.sharedInstance().updateServerUrlDictIfNeeded()
        FTAppConfigHelper.sharedAppConfig().updateAppConfig()

        //Evernote related
        #if !targetEnvironment(macCatalyst)
        if let session = EvernoteSession.shared(), session.isAuthenticated {
            Analytics.setUserProperty((session.businessUser.active ? "business" : "personal"), forName: "ns_evernote_user")
        } else {
            Analytics.setUserProperty("none", forName: "ns_evernote_user")
        }

        if let countryCode = Locale.current.language.region?.identifier {
            Analytics.setUserProperty(countryCode, forName: "ns_user_country")
        }

        //Last Active date
        let outputFormatter = DateFormatter()
        outputFormatter.locale = NSLocale(localeIdentifier: "en_US") as Locale
        outputFormatter.dateFormat = "YYYYMMdd"
        let dateString = outputFormatter.string(from: Date())
        Analytics.setUserProperty(dateString, forName: "ns_last_active")

        //Active since
        var activeSinceDateString = UserDefaults.standard.object(forKey: "ACTIVE_SINCE_DATE") as? String
        if activeSinceDateString == nil {
            activeSinceDateString = dateString
            UserDefaults.standard.set(activeSinceDateString, forKey: "ACTIVE_SINCE_DATE")
            Analytics.setUserProperty(dateString, forName: "ns_active_since")
        }
        PressurePenEngine.shared().start()
        #endif
        FabricHelper.configure()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        FTCLSLog("--- foreground ---")
        FTiRateManager.checkForApplicationForegroundActions()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        FTCLSLog("--- background ---")
        #if !targetEnvironment(macCatalyst)
        PressurePenEngine.shared().stop()
        #endif
    }

    func applicationWillTerminate(_ application: UIApplication) {
        FTCLSLog("--- terminate ---")
        (rootViewController as? FTRootViewController)?.saveApplicationStateByClosingDocument(false, keepEditingOn: true, onCompletion: nil)
    }
}

//MARK:- State restoration
extension NoteshelfAppDelegate {
    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        application.ignoreSnapshotOnNextApplicationLaunch()
        return true
    }

    func application(_ application: UIApplication, shouldRestoreSecureApplicationState coder: NSCoder) -> Bool {
        return true
    }
}

//MARK:- Open URL
extension NoteshelfAppDelegate {
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let sourceApp = options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String
        let annotation = options[UIApplication.OpenURLOptionsKey.annotation] as? String
        var urlOptions = FTURLOptions(sourceApplication: sourceApp, annotation: annotation)
        if let handlingController = rootViewController as? FTIntentHandlingProtocol {
            let handler = FTAppIntentHandler(with: handlingController)
            urlOptions.openInPlace = (options[.openInPlace] as? NSNumber)?.boolValue ?? false;
            return handler.open(url, options: urlOptions)
        }
        return false
    }
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if let handlingController = rootViewController as? FTIntentHandlingProtocol {
            let handler = FTAppIntentHandler(with: handlingController)
            return handler.continueUserActivity(userActivity, restorationHandler: restorationHandler)
        }
        return false
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        if let handlingController = window?.rootViewController as? FTIntentHandlingProtocol {
            let handler = FTAppIntentHandler(with: handlingController)
            handler.handleShortcutItem(item: shortcutItem)
        }
    }
}
extension NoteshelfAppDelegate  {
    func didCrashDuringPreviousExecution() {
        if(Crashlytics.crashlytics().didCrashDuringPreviousExecution()) {
            if let attemptsInfo = UserDefaults.standard.object(forKey: "attempts") as? [AnyHashable : Any] {
                var attempt = (attemptsInfo["noOfAttempts"] as? NSNumber)?.intValue ?? 0
                attempt += 1
                let attemptsInfo = [
                    "noOfAttempts": NSNumber(value: attempt),
                    "lastAttempt": NSNumber(value: Date.timeIntervalSinceReferenceDate)
                ]
                UserDefaults.standard.set(attemptsInfo, forKey: "attempts")
            } else {
                let attemptsInfo = [
                    "noOfAttempts": NSNumber(value: 1),
                    "lastAttempt": NSNumber(value: Date.timeIntervalSinceReferenceDate)
                ]
                UserDefaults.standard.set(attemptsInfo, forKey: "attempts")
            }
            FTiRateManager.reset()
            UserDefaults.standard.synchronize()
        }
    }
}

extension NoteshelfAppDelegate {

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        #if targetEnvironment(macCatalyst)
        if let userActivity = options.userActivities.first
            , userActivity.activityType == FTNoteshelfSessionID.openNotebook.activityIdentifier {
            FTCLSLog("#### - Book Session Added");
            return UISceneConfiguration(name: "Book Configuration", sessionRole: connectingSceneSession.role);
        }
        else if let userActivity = options.userActivities.first
            , userActivity.activityType == FTPreferenceSceneDelegate.activityIdentifier {
            FTCLSLog("#### - Preference Session Added");
            return UISceneConfiguration(name: "Preference Configuration", sessionRole: connectingSceneSession.role);
        }
        #endif
        FTCLSLog("#### - Shelf Session Added");
        return  UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        updateSessionCountInFabric()
        FTCLSLog("#### - Session Discarded");
    }
}

private extension NoteshelfAppDelegate {
    func clearTempCache() {
        if !UserDefaults.standard.bool(forKey: "Template_Cache_Cleared") {
            DispatchQueue.global().async {
                if let contents = try? FileManager().contentsOfDirectory(atPath: NSTemporaryDirectory()) {
                    contents.forEach { eacItem in
                        let path = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(eacItem);
                        if path.isFileURL, path.pathExtension.isEmpty {
                            try? FileManager().removeItem(at: path)
                        }
                    }
                }
                UserDefaults.standard.set(true, forKey: "Template_Cache_Cleared");
            }
        }

        DispatchQueue.global().async {
            let tempLocation = URL(fileURLWithPath: (FTUtils.applicationCacheDirectory() as NSString).appendingPathComponent("TempZip"))
            try? FileManager().removeItem(at: tempLocation)
        }
    }
}
