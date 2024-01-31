//
//  FTDiaryYearRectsInfo.swift
//  Template Generator
//
//  Created by sreenu cheedella on 29/11/19.
//  Copyright © 2019 Amar. All rights reserved.
//

import UIKit

class FTDiaryCalendarRectInfo : NSObject {
    var yearRect: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
    var monthRects : [CGRect] = []
    var dayRects : [[CGRect]] = []
}
class FTDiaryYearRectsInfo: NSObject {
    var yearRect: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0);
    var monthRects: [CGRect] = [];
    var yearPageNumRects : [CGRect] = [];
}

class FTDiaryMonthRectsInfo: NSObject {
    var monthRect: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0);
    var yearRect: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0);
    var weekRects: [CGRect] = [];
    var dayRects: [CGRect] = [];
}

class FTDiaryWeekRectsInfo: NSObject {
    var monthRect: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0);
    var yearRect: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0);
    var weekDayRects: [CGRect] = [];
    var weekStartDaysMonthRect = CGRect(x: 0, y: 0, width: 0, height: 0)
    var weekEndDaysMonthRect = CGRect(x: 0, y: 0, width: 0, height: 0)
    var prioritiesRect: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0);
    var notesRect: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0);
}

class FTDiaryDayRectsInfo: NSObject {
    var monthRect: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0);
    var weekRect: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0);
    var yearRect: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0);
    var prioritiesRect: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0);
    var dailyPlanRect : CGRect = CGRect(x: 0, y: 0, width: 0, height: 0);
    var notesRect: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0);
}
struct FTDiaryWeeklyPrioritiesRectInfo {
    var weekRect : CGRect = CGRect(x: 0, y: 0, width: 0, height: 0);
}
struct FTDiaryWeeklyNotesRectInfo {
    var weekRect : CGRect = CGRect(x: 0, y: 0, width: 0, height: 0);
}
struct FTDiaryDailyNotesRectInfo {
    var dayRect : CGRect = CGRect(x: 0, y: 0, width: 0, height: 0);
}
struct FTDiaryDailyPrioritiesRectInfo {
    var dayRect : CGRect = CGRect(x: 0, y: 0, width: 0, height: 0);
}
struct FTDiaryDailyPlansRectInfo {
    var dayRect : CGRect = CGRect(x: 0, y: 0, width: 0, height: 0);
}
class FTPlannerDiarySideNavigationRectInfo : NSObject {
    var calendarRect : CGRect = CGRect(x: 0, y: 0, width: 0, height: 0);
    var yearRect : CGRect = CGRect(x: 0, y: 0, width: 0, height: 0);
    var monthRects : [String : CGRect] = [:];
    var extrasRect : CGRect = CGRect(x: 0, y: 0, width: 0, height: 0);
}
class FTPlannerDiaryTopNavigationRectInfo : NSObject {
    var plannerTopNavigationRects : [FTPlannerDiaryTemplateType : CGRect] = [:]
}
class FTPlannerDiaryExtrasTabRectInfo : NSObject {
    var plannerExtrasRects : [CGRect] = []
}
