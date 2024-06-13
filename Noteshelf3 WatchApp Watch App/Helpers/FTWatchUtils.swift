//
//  FTWatchUtils.swift
//  Noteshelf3 WatchApp
//
//  Created by Narayana on 07/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

 let widgetKind: String = "FT-Complication"

class FTWatchUtils {
    static func timeFormatted(totalSeconds: UInt) -> String {
        var seconds = 0, minutes = 0, hours = 0
        var formatString = ""

        hours = Int(totalSeconds) / 3600
        if hours > 0 {
            seconds = Int(totalSeconds) % 60
            minutes = (Int(totalSeconds) / 60) % 60
            hours = Int(totalSeconds) / 3600

            formatString = String(format: "%02ld:%02ld:%02ld", hours, minutes, seconds)
        } else {
            seconds = Int(totalSeconds) % 60
            minutes = Int(totalSeconds) / 60
            formatString = String(format: "%02ld:%02ld", minutes, seconds)
        }

        return formatString
    }
}

class FTWidgetDefaults: NSObject {
    fileprivate static var sharedDefaults: UserDefaults? = nil
    @objc class func shared() -> UserDefaults {
        if(nil == sharedDefaults) {
            sharedDefaults = UserDefaults(suiteName: FTSharedGroupID.getAppGroupID())
        }
        return sharedDefaults!
    }

    class func resetRecording() {
        FTWidgetDefaults.shared().isRecording = false
    }
}

extension UserDefaults {
    @objc dynamic var isRecording: Bool {
        get {
            return FTWidgetDefaults.sharedDefaults?.bool(forKey: "isRecording") ?? false
        }
        set {
            FTWidgetDefaults.sharedDefaults?.set(newValue, forKey: "isRecording")
            FTWidgetDefaults.sharedDefaults?.synchronize()
        }
    }
}
