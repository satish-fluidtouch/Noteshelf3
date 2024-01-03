//
//  FTDairyRenderFormat.swift
//  Template Generator
//
//  Created by Amar on 13/11/19.
//  Copyright © 2019 Amar. All rights reserved.
//

import UIKit
import PDFKit

protocol FTDairyRenderTemplate : NSObjectProtocol {
    var dayTemplate: String {get}
    var weekTemplate: String {get}
    var monthTemplate: String {get}
    var yearTemplate: String {get}
}

@objc protocol FTDairyRenderFormat : NSObjectProtocol {
    var diaryPagesInfo : [FTDiaryPageInfo] {get set}
    func isToDisplayOutOfMonthDate() -> Bool
    func pageRect() -> CGRect;
    func generateCalendar(context : CGContext, monthlyFormatter : FTYearInfoMonthly, weeklyFormatter : FTYearInfoWeekly)
    func addCalendarLinks(url : URL,format : FTDairyFormat,pageRect: CGRect, calenderYear: FTYearFormatInfo, isToDisplayOutOfMonthDate: Bool,monthlyFormatter : FTYearInfoMonthly, weeklyFormatter : FTYearInfoWeekly)
    func calendarOffsetCount() -> Int;
}
@objc protocol FTDiaryPageRenderer : NSObjectProtocol {
    func renderYearPage(context : CGContext,months : [FTMonthInfo],calendarYear : FTYearFormatInfo);
    func renderMonthPage(context : CGContext,monthInfo : FTMonthlyCalendarInfo, calendarYear: FTYearFormatInfo);
    func renderWeekPage(context : CGContext,weeklyInfo : FTWeekInfo);
    func renderDayPage(context : CGContext,dayInfo : FTDayInfo);
}
