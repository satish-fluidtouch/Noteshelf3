//
//  FTSlideShowTimeTracker.swift
//  Noteshelf
//
//  Created by Narayana on 24/06/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTSlideShowTimeTracker: NSObject {
    static let shared = FTSlideShowTimeTracker()
    
    private func getSlideShowTime(startTime: Date?, endTime: Date?) -> Int {
        if let tempStartTime = startTime, let tempEndTime = endTime {
            let timeDiff = tempEndTime.timeIntervalSince(tempStartTime)
            return Int(timeDiff)
        }
        return 0
    }
    
    func trackSlideShowTime(startTime: Date?, endTime: Date?, pageTitle: String, source: FTSourceScreen) {
        let time = self.getSlideShowTime(startTime: startTime, endTime: endTime)
        let indexTitle = getSlideTimeIndexName(pageTitle: pageTitle)
        if source == .settings {
            track("Settings_WhatsNew_Slide\(indexTitle)_Time", params: ["time" : time], screenName: FTScreenNames.whatsNew)
        } else {
            track("WhatsNew_Slide\(indexTitle)_Time", params: ["time" : time], screenName: FTScreenNames.whatsNew)
        }
    }
    
    func getSlideTimeIndexName(pageTitle: String) -> String {
        var timeIndexName: String = ""
        switch pageTitle {
        case FTWhatsNewLocalizedString("WhatsNewStartTitle", comment: "WHAT’S NEW"):
            timeIndexName = "First"
        case FTWhatsNewLocalizedString("WhatsNewStudentPackTitle", comment: "New Student Templates"):
            timeIndexName = "Second"
        case FTWhatsNewLocalizedString("WhatsNewQuickCreateTitle", comment: "WhatsNewQuickCreateTitle"):
            timeIndexName = "Third"
        case FTWhatsNewLocalizedString("WhatsNewReadModeTitle", comment: "Distraction free Read-Only Mode!"):
            timeIndexName = "Fourth"
        case FTWhatsNewLocalizedString("WhatsNewConvertToShapeTitle", comment: "Hold to covert to Shape"):
            timeIndexName = "Fifth"
        case FTWhatsNewLocalizedString("JoinUsTitle", comment: "Follow Us"):
            timeIndexName = "Sixth"
        default:
            timeIndexName = ""
        }
        return timeIndexName
    }
    
}
