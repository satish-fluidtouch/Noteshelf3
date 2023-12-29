//
//  FTDiaryPageInfo.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 28/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

enum DiaryPageType: Codable {
    case calendar
    case year
    case month
    case week
    case day
    case tracker
    case notes
}
@objcMembers class FTDiaryPageInfo: NSObject,Codable {
    var type: DiaryPageType
    var date: TimeInterval?
    var shouldShowThisPageOnDiaryLaunch : Bool {
        var status: Bool = false
        if let currentDate = Date().utcDate() , let date {
            let pageDate = Date(timeIntervalSinceReferenceDate: date).utcDate() ?? Date(timeIntervalSinceReferenceDate: date);
            if pageDate.compareDate(currentDate) == ComparisonResult.orderedSame {
                status = true;
            }
        }
        return status
    }

    init(type: DiaryPageType,date:TimeInterval? = nil){
        self.type = type
        self.date = date
    }
}
