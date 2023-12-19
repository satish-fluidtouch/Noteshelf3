//
//  ExtensionDelegate.swift
//  Noteshelf3 WatchApp Extension
//
//  Created by Rajitha on 25/09/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import WatchKit
var audioServiceCurrentState : FTAudioServiceStatus! = FTAudioServiceStatus.none
var recentPlayedAudio: Dictionary<String, Any>! = ["currentTime" : 0.0, "GUID": ""]
var isInForeground = true

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    let recordingStore = FTWatchCommunicationManager.shared
    func handleUserActivity(_ userInfo: [AnyHashable : Any]?) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: DID_WATCH_COMPLICATION_RECEIVED), object: nil, userInfo: ["activeState": true])
    }
    func applicationDidFinishLaunching() {
    }

    func applicationDidBecomeActive() {
        isInForeground = true
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: DID_CHANGE_WATCH_STATE), object: nil, userInfo: ["activeState": true])

        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    func applicationDidEnterBackground() {
        isInForeground = false
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: DID_CHANGE_WATCH_STATE), object: nil, userInfo: ["activeState": false])
    }
    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.

        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                if #available(watchOSApplicationExtension 4.0, *) {
                    backgroundTask.setTaskCompletedWithSnapshot(false)

                } else {
                    // Fallback on earlier versions
                }
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                if #available(watchOSApplicationExtension 4.0, *) {
                    connectivityTask.setTaskCompletedWithSnapshot(false)
                } else {
                    // Fallback on earlier versions
                }
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                if #available(watchOSApplicationExtension 4.0, *) {
                    urlSessionTask.setTaskCompletedWithSnapshot(false)
                } else {
                    // Fallback on earlier versions
                }
            default:
                // make sure to complete unhandled task types
                if #available(watchOSApplicationExtension 4.0, *) {
                    task.setTaskCompletedWithSnapshot(false)
                } else {
                    // Fallback on earlier versions
                }
            }
        }
    }

}
