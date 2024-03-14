//
//  FTWatchUtils.swift
//  Noteshelf3 WatchApp
//
//  Created by Narayana on 07/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

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
