//
//  FTScreenFontsInfo.swift
//  Template Generator
//
//  Created by sreenu cheedella on 30/12/19.
//  Copyright © 2019 Amar. All rights reserved.
//

import UIKit

protocol FTScreenDetailsProtocol{
    var yearDetails: FTScreenYearFontsInfo {get}
    var monthDetails: FTScreenMonthFontsInfo {get}
    var weekDetails: FTScreenWeekFontsInfo {get}
    var dayDetails: FTScreenDayFontsInfo {get}
}

struct FTScreenYearFontsInfo: Codable {
    let yearFontSize: CGFloat
    let titleMonthFontSize: CGFloat
    let outMonthFontSize: CGFloat
    
    enum CodingKeys: CodingKey {
        case yearFontSize
        case titleMonthFontSize
        case outMonthFontSize
    }

    init(decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.yearFontSize = try values.decodeIfPresent(CGFloat.self, forKey: .yearFontSize) ?? 20
        self.titleMonthFontSize = try values.decodeIfPresent(CGFloat.self, forKey: .titleMonthFontSize) ?? 24
        self.outMonthFontSize = try values.decodeIfPresent(CGFloat.self, forKey: .outMonthFontSize) ?? 16
    }
}

struct FTScreenMonthFontsInfo: Codable {
    let monthFontSize: CGFloat
    let yearFontSize: CGFloat
    let weekFontSize: CGFloat
    let dayFontSize: CGFloat
    
    enum CodingKeys: CodingKey {
        case monthFontSize
        case yearFontSize
        case weekFontSize
        case dayFontSize
    }
    
    init(decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.monthFontSize = try values.decodeIfPresent(CGFloat.self, forKey: .monthFontSize) ?? 24
        self.yearFontSize = try values.decodeIfPresent(CGFloat.self, forKey: .yearFontSize) ?? 24
        self.weekFontSize = try values.decodeIfPresent(CGFloat.self, forKey: .weekFontSize) ?? 15
        self.dayFontSize = try values.decodeIfPresent(CGFloat.self, forKey: .dayFontSize) ?? 21
    }
}

struct FTScreenWeekFontsInfo: Codable {
    let monthFontSize: CGFloat
    let yearFontSize: CGFloat
    let weekFontSize: CGFloat
    let dayFontSize: CGFloat
    
    enum CodingKeys: CodingKey {
        case monthFontSize
        case yearFontSize
        case weekFontSize
        case dayFontSize
    }
    
    init(decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.monthFontSize = try values.decodeIfPresent(CGFloat.self, forKey: .monthFontSize) ?? 20
        self.yearFontSize = try values.decodeIfPresent(CGFloat.self, forKey: .yearFontSize) ?? 10
        self.weekFontSize = try values.decodeIfPresent(CGFloat.self, forKey: .weekFontSize) ?? 14
        self.dayFontSize = try values.decodeIfPresent(CGFloat.self, forKey: .dayFontSize) ?? 18
    }
}

struct FTScreenDayFontsInfo: Codable {
    let dayFontSize: CGFloat
    let monthFontSize: CGFloat
    let weekFontSize: CGFloat
    let yearFontSize: CGFloat
    
    enum CodingKeys: CodingKey {
        case dayFontSize
        case monthFontSize
        case weekFontSize
        case yearFontSize
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.dayFontSize = try values.decodeIfPresent(CGFloat.self, forKey: .dayFontSize) ?? 54
        self.monthFontSize = try values.decodeIfPresent(CGFloat.self, forKey: .monthFontSize) ?? 18
        self.weekFontSize = try values.decodeIfPresent(CGFloat.self, forKey: .weekFontSize) ?? 10
        self.yearFontSize = try values.decodeIfPresent(CGFloat.self, forKey: .yearFontSize) ?? 10
    }
}
struct FTScreenPrioritiesFontsInfo: Codable {
    let dayFontSize: CGFloat
    let yearFontSize: CGFloat
    
    enum CodingKeys: CodingKey {
        case dayFontSize
        case yearFontSize
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.dayFontSize = try values.decodeIfPresent(CGFloat.self, forKey: .dayFontSize) ?? 30
        self.yearFontSize = try values.decodeIfPresent(CGFloat.self, forKey: .yearFontSize) ?? 40
    }
}
struct FTScreenFontsInfo: Codable {
    let yearPageDetails: FTScreenYearFontsInfo
    let monthPageDetails: FTScreenMonthFontsInfo
    let weekPageDetails: FTScreenWeekFontsInfo
    let dayPageDetails: FTScreenDayFontsInfo
    let prioritiesPageDetails : FTScreenPrioritiesFontsInfo
    
    enum CodingKeys: String, CodingKey {
        case yearPageDetails = "year"
        case monthPageDetails = "month"
        case weekPageDetails = "week"
        case dayPageDetails = "day"
        case prioritiesPageDetails = "priorities"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
       // self.calendarPageDetails = try values.decodeIfPresent(FTScreenCalendarFontsInfo.self, forKey: .calendarPageDetails) ?? FTScreenCalendarFontsInfo.init(from: decoder)
        self.yearPageDetails = try values.decodeIfPresent(FTScreenYearFontsInfo.self, forKey: .yearPageDetails) ?? FTScreenYearFontsInfo.init(from: decoder)
        self.monthPageDetails = try values.decodeIfPresent(FTScreenMonthFontsInfo.self, forKey: .monthPageDetails) ?? FTScreenMonthFontsInfo.init(from: decoder)
        self.weekPageDetails = try values.decodeIfPresent(FTScreenWeekFontsInfo.self, forKey: .weekPageDetails) ?? FTScreenWeekFontsInfo.init(from: decoder)
        self.dayPageDetails = try values.decodeIfPresent(FTScreenDayFontsInfo.self, forKey: .dayPageDetails) ?? FTScreenDayFontsInfo.init(from: decoder)
        self.prioritiesPageDetails = try values.decodeIfPresent(FTScreenPrioritiesFontsInfo.self, forKey: .prioritiesPageDetails) ?? FTScreenPrioritiesFontsInfo.init(from: decoder)
    }
}
