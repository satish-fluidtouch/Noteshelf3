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
    case monthlyNotes
    case extras
    case weeklyPriorities
    case dailyPriorities
    case weeklyNotes
    case dailyNotes
    case help
    case sample
}
@objcMembers class FTDiaryPageInfo: NSObject,Codable {
    let type: DiaryPageType
    let date: TimeInterval?
    let isCurrentPage : Bool

    init(type: DiaryPageType,date:TimeInterval? = nil, isCurrentPage : Bool  = false){
        self.type = type
        self.date = date
        self.isCurrentPage = isCurrentPage
    }
}
