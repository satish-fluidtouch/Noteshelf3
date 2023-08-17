//
//  FTScreenSpacesInfo.swift
//  Template Generator
//
//  Created by sreenu cheedella on 30/12/19.
//  Copyright © 2019 Amar. All rights reserved.
//

import UIKit

struct FTScreenCalendarSpacesInfo: Codable {
    let baseBoxX: CGFloat
    let baseBoxY: CGFloat
    let cellOffsetX: CGFloat
    let cellOffsetY: CGFloat
    let boxBottomOffset: CGFloat
    let boxRightOffset: CGFloat
    let yearY: CGFloat
    let yearX : CGFloat
    
    enum CodingKeys: CodingKey {
        case baseBoxX
        case baseBoxY
        case cellOffsetX
        case cellOffsetY
        case boxBottomOffset
        case boxRightOffset
        case yearY
        case yearX
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.baseBoxX = try values.decodeIfPresent(CGFloat.self, forKey: .baseBoxX) ?? 5.15
        self.baseBoxY = try values.decodeIfPresent(CGFloat.self, forKey: .baseBoxY) ?? 14.41
        self.cellOffsetX = try values.decodeIfPresent(CGFloat.self, forKey: .cellOffsetX) ?? 2.39
        self.cellOffsetY = try values.decodeIfPresent(CGFloat.self, forKey: .cellOffsetY) ?? 6.39
        self.boxBottomOffset = try values.decodeIfPresent(CGFloat.self, forKey: .boxBottomOffset) ?? 4.79
        self.boxRightOffset = try values.decodeIfPresent(CGFloat.self, forKey: .boxRightOffset) ?? 6.48
        self.yearY = try values.decodeIfPresent(CGFloat.self, forKey: .yearY) ?? 4.77
        self.yearX = try values.decodeIfPresent(CGFloat.self, forKey: .yearX) ?? 5.39
    }
}

struct FTScreenYearSpacesInfo: Codable {
    let baseBoxX: CGFloat
    let baseBoxY: CGFloat
    let cellOffsetX: CGFloat
    let cellOffsetY: CGFloat
    let boxBottomOffset: CGFloat
    let boxRightOffset: CGFloat
    let yearY: CGFloat
    let yearX: CGFloat
    
    enum CodingKeys: CodingKey {
        case baseBoxX
        case baseBoxY
        case cellOffsetX
        case cellOffsetY
        case boxBottomOffset
        case boxRightOffset
        case yearY
        case yearX
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.baseBoxX = try values.decodeIfPresent(CGFloat.self, forKey: .baseBoxX) ?? 44
        self.baseBoxY = try values.decodeIfPresent(CGFloat.self, forKey: .baseBoxY) ?? 268
        self.cellOffsetX = try values.decodeIfPresent(CGFloat.self, forKey: .cellOffsetX) ?? 24
        self.cellOffsetY = try values.decodeIfPresent(CGFloat.self, forKey: .cellOffsetY) ?? 24
        self.boxBottomOffset = try values.decodeIfPresent(CGFloat.self, forKey: .boxBottomOffset) ?? 108
        self.boxRightOffset = try values.decodeIfPresent(CGFloat.self, forKey: .boxRightOffset) ?? 64
        self.yearY = try values.decodeIfPresent(CGFloat.self, forKey: .yearY) ?? 54
        self.yearX = try values.decodeIfPresent(CGFloat.self, forKey: .yearX) ?? 45
    }
}

struct FTScreenMonthSpacesInfo: Codable {
    let baseBoxX: CGFloat
    let baseBoxY: CGFloat
    let boxRightOffset: CGFloat
    let boxBottomOffset: CGFloat
    let cellOffsetY: CGFloat
    let cellOffsetX: CGFloat
    let monthY: CGFloat
    
    enum CodingKeys: CodingKey {
        case baseBoxX
        case baseBoxY
        case boxRightOffset
        case boxBottomOffset
        case cellOffsetX
        case cellOffsetY
        case monthY
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.baseBoxX = try values.decodeIfPresent(CGFloat.self, forKey: .baseBoxX) ?? 44
        self.baseBoxY = try values.decodeIfPresent(CGFloat.self, forKey: .baseBoxY) ?? 320
        self.boxRightOffset = try values.decodeIfPresent(CGFloat.self, forKey: .boxRightOffset) ?? 48
        self.boxBottomOffset = try values.decodeIfPresent(CGFloat.self, forKey: .boxBottomOffset) ?? 45
        self.cellOffsetX = try values.decodeIfPresent(CGFloat.self, forKey: .cellOffsetX) ?? 24
        self.cellOffsetY = try values.decodeIfPresent(CGFloat.self, forKey: .cellOffsetY) ?? 24
        self.monthY = try values.decodeIfPresent(CGFloat.self, forKey: .monthY) ?? 54
    }
}

struct FTScreenWeekSpacesInfo: Codable {
    let baseBoxX: CGFloat
    let baseBoxY: CGFloat
    let titleLineY: CGFloat
    let cellOffsetX: CGFloat
    let cellOffsetY: CGFloat
    let cellWidth: CGFloat
    let cellHeight: CGFloat
    let lastCellHeight: CGFloat
    let priorityBoxWidth: CGFloat
    let priorityBoxHeight: CGFloat
    let prioritiesBoxX: CGFloat
    let prioritiesBoxY: CGFloat
    let notesBoxWidth: CGFloat
    let notesBoxHeight: CGFloat
    
    enum CodingKeys: CodingKey {
        case baseBoxX
        case baseBoxY
        case titleLineY
        case cellOffsetX
        case cellOffsetY
        case cellWidth
        case cellHeight
        case lastCellHeight
        case priorityBoxWidth
        case priorityBoxHeight
        case prioritiesBoxX
        case prioritiesBoxY
        case notesBoxWidth
        case notesBoxHeight
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.baseBoxX = try values.decodeIfPresent(CGFloat.self, forKey: .baseBoxX) ?? 34
        self.baseBoxY = try values.decodeIfPresent(CGFloat.self, forKey: .baseBoxY) ?? 133
        self.titleLineY = try values.decodeIfPresent(CGFloat.self, forKey: .titleLineY) ?? 64
        self.cellOffsetX = try values.decodeIfPresent(CGFloat.self, forKey: .cellOffsetX) ?? 24
        self.cellOffsetY = try values.decodeIfPresent(CGFloat.self, forKey: .cellOffsetY) ?? 24
        self.cellWidth = try values.decodeIfPresent(CGFloat.self, forKey: .cellWidth) ?? 512
        self.cellHeight = try values.decodeIfPresent(CGFloat.self, forKey: .cellHeight) ?? 294
        self.lastCellHeight = try values.decodeIfPresent(CGFloat.self, forKey: .lastCellHeight) ?? 141
        self.priorityBoxWidth = try values.decodeIfPresent(CGFloat.self, forKey: .priorityBoxWidth) ?? 35.74
        self.priorityBoxHeight = try values.decodeIfPresent(CGFloat.self, forKey: .priorityBoxHeight) ?? 22.8
        self.prioritiesBoxX = try values.decodeIfPresent(CGFloat.self, forKey: .prioritiesBoxX) ?? 59.23
        self.prioritiesBoxY = try values.decodeIfPresent(CGFloat.self, forKey: .prioritiesBoxY) ?? 24.04
        self.notesBoxWidth = try values.decodeIfPresent(CGFloat.self, forKey: .notesBoxWidth) ?? 35.74
        self.notesBoxHeight = try values.decodeIfPresent(CGFloat.self, forKey: .notesBoxHeight) ?? 47.43
    }
}

struct FTScreenDaySpacesInfo: Codable {
    let baseX: CGFloat
    let baseY: CGFloat
    let notesBoxX: CGFloat
    let notesBoxY: CGFloat
    let prioritiesBoxX: CGFloat
    let prioritiesBoxY: CGFloat
    let priorityBoxWidth: CGFloat
    let priorityBoxHeight: CGFloat
    let notesBoxWidth: CGFloat
    let notesBoxHeight: CGFloat
    let dailyPlanBoxX: CGFloat
    let dailyPlanBoxY: CGFloat
    let dailyPlanBoxWidth: CGFloat
    let dailyPlanBoxHeight: CGFloat
    
    enum CodingKeys: CodingKey {
        case baseX
        case baseY
        case notesBoxX
        case notesBoxY
        case prioritiesBoxX
        case prioritiesBoxY
        case priorityBoxHeight
        case priorityBoxWidth
        case notesBoxWidth
        case notesBoxHeight
        case dailyPlanBoxX
        case dailyPlanBoxY
        case dailyPlanBoxWidth
        case dailyPlanBoxHeight
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.baseX = try values.decodeIfPresent(CGFloat.self, forKey: .baseX) ?? 27
        self.baseY = try values.decodeIfPresent(CGFloat.self, forKey: .baseY) ?? 27
        self.notesBoxX = try values.decodeIfPresent(CGFloat.self, forKey: .notesBoxX) ?? 59.53
        self.notesBoxY = try values.decodeIfPresent(CGFloat.self, forKey: .notesBoxY) ?? 56.29
        self.prioritiesBoxX = try values.decodeIfPresent(CGFloat.self, forKey: .prioritiesBoxX) ?? 59.53
        self.prioritiesBoxY = try values.decodeIfPresent(CGFloat.self, forKey: .prioritiesBoxY) ?? 27.36
        self.priorityBoxHeight = try values.decodeIfPresent(CGFloat.self, forKey: .priorityBoxHeight) ?? 21.29
        self.priorityBoxWidth = try values.decodeIfPresent(CGFloat.self, forKey: .priorityBoxWidth) ?? 36.78
        self.notesBoxWidth = try values.decodeIfPresent(CGFloat.self, forKey: .notesBoxWidth) ?? 36.78
        self.notesBoxHeight = try values.decodeIfPresent(CGFloat.self, forKey: .notesBoxHeight) ?? 44.41
        self.dailyPlanBoxX = try values.decodeIfPresent(CGFloat.self, forKey: .dailyPlanBoxX) ?? 5.33
        self.dailyPlanBoxY = try values.decodeIfPresent(CGFloat.self, forKey: .dailyPlanBoxY) ?? 26.79
        self.dailyPlanBoxWidth = try values.decodeIfPresent(CGFloat.self, forKey: .dailyPlanBoxWidth) ?? 89.33
        self.dailyPlanBoxHeight = try values.decodeIfPresent(CGFloat.self, forKey: .dailyPlanBoxHeight) ?? 46.08
    }
}
struct FTScreenNotesSpacesInfo: Codable {
    let boxX: CGFloat
    let boxY: CGFloat
    let titleX: CGFloat
    let titleY: CGFloat
    let dayInfoY: CGFloat
    let boxWidth: CGFloat
    
    enum CodingKeys: CodingKey {
        case boxX
        case boxY
        case titleX
        case titleY
        case dayInfoY
        case boxWidth
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.boxX = try values.decodeIfPresent(CGFloat.self, forKey: .boxX) ?? 4.79
        self.boxY = try values.decodeIfPresent(CGFloat.self, forKey: .boxY) ?? 11.83
        self.titleX = try values.decodeIfPresent(CGFloat.self, forKey: .titleX) ?? 59.53
        self.titleY = try values.decodeIfPresent(CGFloat.self, forKey: .titleY) ?? 4.00
        self.dayInfoY = try values.decodeIfPresent(CGFloat.self, forKey: .dayInfoY) ?? 4.96
        self.boxWidth = try values.decodeIfPresent(CGFloat.self, forKey: .boxWidth) ?? 90.28
    }
}
struct FTScreenPrioritiesSpacesInfo: Codable {
    let boxX: CGFloat
    let boxY: CGFloat
    let titleX: CGFloat
    let titleY: CGFloat
    let dayInfoY: CGFloat
    let boxWidth: CGFloat
    
    enum CodingKeys: CodingKey {
        case boxX
        case boxY
        case titleX
        case titleY
        case dayInfoY
        case boxWidth
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.boxX = try values.decodeIfPresent(CGFloat.self, forKey: .boxX) ?? 4.79
        self.boxY = try values.decodeIfPresent(CGFloat.self, forKey: .boxY) ?? 11.83
        self.titleX = try values.decodeIfPresent(CGFloat.self, forKey: .titleX) ?? 59.53
        self.titleY = try values.decodeIfPresent(CGFloat.self, forKey: .titleY) ?? 4.00
        self.dayInfoY = try values.decodeIfPresent(CGFloat.self, forKey: .dayInfoY) ?? 4.96
        self.boxWidth = try values.decodeIfPresent(CGFloat.self, forKey: .boxWidth) ?? 90.28
    }
}
struct FTScreenJournalDaySpacesInfo : Codable {
    let baseX: CGFloat
    let baseY: CGFloat
    let quoteX : CGFloat
    let quoteY : CGFloat
    let heading1Y : CGFloat
    let headingX : CGFloat
    let heading2Y : CGFloat
    let heading3Y : CGFloat
    let heading4Y : CGFloat
    let heading5Y : CGFloat
    let quoteWidth : CGFloat
    let headingWidth : CGFloat
    
    enum CodingKeys: CodingKey {
        case baseX
        case baseY
        case quoteX
        case quoteY
        case heading1Y
        case headingX
        case heading2Y
        case heading3Y
        case heading4Y
        case heading5Y
        case quoteWidth
        case headingWidth
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.baseX = try values.decodeIfPresent(CGFloat.self, forKey: .baseX) ?? 5.39
        self.baseY = try values.decodeIfPresent(CGFloat.self, forKey: .baseY) ?? 4.48
        self.quoteX = try values.decodeIfPresent(CGFloat.self, forKey: .quoteX) ?? 4.79
        self.quoteY = try values.decodeIfPresent(CGFloat.self, forKey: .quoteY) ?? 13.45
        self.heading1Y = try values.decodeIfPresent(CGFloat.self, forKey: .heading1Y) ?? 23.75
        self.headingX = try values.decodeIfPresent(CGFloat.self, forKey: .headingX) ?? 4.79
        self.heading2Y = try values.decodeIfPresent(CGFloat.self, forKey: .heading2Y) ?? 37.38
        self.heading3Y = try values.decodeIfPresent(CGFloat.self, forKey: .heading3Y) ?? 51.81
        self.heading4Y = try values.decodeIfPresent(CGFloat.self, forKey: .heading4Y) ?? 68.70
        self.heading5Y = try values.decodeIfPresent(CGFloat.self, forKey: .heading5Y) ?? 82.72
        self.quoteWidth = try values.decodeIfPresent(CGFloat.self, forKey: .quoteWidth) ?? 88.00
        self.headingWidth = try values.decodeIfPresent(CGFloat.self, forKey: .headingWidth) ?? 90.04
    }
}
struct FTScreenSpacesInfo: Codable {
    let calendarSpacesInfo: FTScreenCalendarSpacesInfo
    let yearPageSpacesInfo: FTScreenYearSpacesInfo
    let monthPageSpacesInfo: FTScreenMonthSpacesInfo
    let weekPageSpacesInfo: FTScreenWeekSpacesInfo
    let dayPageSpacesInfo: FTScreenDaySpacesInfo
    let notesPageSpacesInfo : FTScreenNotesSpacesInfo
    let prioritiesPageSpacesInfo : FTScreenPrioritiesSpacesInfo
    let journalDayPageSpacesInfo : FTScreenJournalDaySpacesInfo
    
    enum CodingKeys: String, CodingKey {
        case calendarSpacesInfo = "calendar"
        case yearPageSpacesInfo = "year"
        case monthPageSpacesInfo = "month"
        case weekPageSpacesInfo = "week"
        case dayPageSpacesInfo = "day"
        case notesPageSpacesInfo = "notes"
        case prioritiesPageSpacesInfo = "priorities"
        case journalDayPageSpacesInfo = "journalDay"
    }
    
    init(from decoder:Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.calendarSpacesInfo = try values.decodeIfPresent(FTScreenCalendarSpacesInfo.self, forKey: .calendarSpacesInfo) ?? FTScreenCalendarSpacesInfo.init(from: decoder)
        self.yearPageSpacesInfo = try values.decodeIfPresent(FTScreenYearSpacesInfo.self, forKey: .yearPageSpacesInfo) ?? FTScreenYearSpacesInfo.init(from: decoder)
        self.monthPageSpacesInfo = try values.decodeIfPresent(FTScreenMonthSpacesInfo.self, forKey: .monthPageSpacesInfo) ?? FTScreenMonthSpacesInfo.init(from: decoder)
        self.weekPageSpacesInfo = try values.decodeIfPresent(FTScreenWeekSpacesInfo.self, forKey: .weekPageSpacesInfo) ?? FTScreenWeekSpacesInfo.init(from: decoder)
        self.dayPageSpacesInfo = try values.decodeIfPresent(FTScreenDaySpacesInfo.self, forKey: .dayPageSpacesInfo) ?? FTScreenDaySpacesInfo.init(from: decoder)
        self.notesPageSpacesInfo = try values.decodeIfPresent(FTScreenNotesSpacesInfo.self, forKey: .notesPageSpacesInfo) ?? FTScreenNotesSpacesInfo.init(from: decoder)
        self.prioritiesPageSpacesInfo = try values.decodeIfPresent(FTScreenPrioritiesSpacesInfo.self, forKey: .prioritiesPageSpacesInfo) ?? FTScreenPrioritiesSpacesInfo.init(from: decoder)
        self.journalDayPageSpacesInfo = try values.decodeIfPresent(FTScreenJournalDaySpacesInfo.self, forKey: .journalDayPageSpacesInfo) ?? FTScreenJournalDaySpacesInfo.init(from: decoder)
    }
}
