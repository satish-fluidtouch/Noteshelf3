//
//  FTMonthInfo.swift
//  Template Generator
//
//  Created by Amar on 13/11/19.
//  Copyright © 2019 Amar. All rights reserved.
//

import UIKit

class FTMonthInfo: NSObject {
    private(set) var dayInfo = [FTDayInfo]();
    private(set) var monthTitle : String = "";
    private(set) var monthShortTitle : String = "";
    private(set) var year : Int = 2020;
    private(set) var month : Int = 0;

    private var localeID : String = "en";
    private var format : FTYearFormatInfo;
    private var _weekFormat : String;
    
    required init(localeIdentifier : String,formatInfo : FTYearFormatInfo,weekFormat:String)
    {
        localeID = localeIdentifier;
        format = formatInfo;
        self._weekFormat=weekFormat;
        super.init();
    }

    func generate(month : Int, year : Int)
    {
        self.generateDaysInfo(month: month, year: year);
        self.year = year;
        self.month = month
        
        let calendar = NSCalendar.gregorian();
        if let startDate = calendar.date(month: month, year: year) {
//            var yearFormat = "MMMM";
//            if((month == format.startMonth.month && year == format.startMonth.year)
//                || (month == format.endMonth.month && year == format.endMonth.year)) {
//                yearFormat = "MMM";
//            }
            self.monthTitle = startDate.monthTitle(localeID: localeID, monthFormat: "MMMM");
            self.monthShortTitle = startDate.monthTitle(localeID: localeID, monthFormat: "MMM");
            let numberOfdaysInMonth = startDate.numberOfDaysInMonth();
            
            let weekday = startDate.weekDay();
            
            var startOffset = 1 - weekday
            
            if _weekFormat.elementsEqual("2"){
                if weekday == 1 {
                    startOffset = -6
                }else {
                    startOffset = 2 - weekday
                }
            }
            let startDayOfMonthCal = startDate.offsetDate(startOffset);
            let lastDayOfMonth = startDate.lastDateOfMonth();
            
            var endOffset = 7 - lastDayOfMonth!.weekDay();
            if _weekFormat.elementsEqual("2"){
                if lastDayOfMonth!.weekDay() == 1 {
                    endOffset = 0
                }else {
                    endOffset = 8 - lastDayOfMonth!.weekDay()
                }
            }
            
            var numberOfdays = numberOfdaysInMonth + endOffset+abs(startOffset);
            
            var nextDate = startDayOfMonthCal
            if numberOfdays < 42{
                numberOfdays = 42
            }
            for _ in 0..<numberOfdays {
                let dateInfo = FTDayInfo.init(localeIdentifier: localeID, formatInfo: format.dayFormat);
                dateInfo.populateDateInfo(date: nextDate);
                self.dayInfo.append(dateInfo);
                nextDate = nextDate.nextDay();
            }
        }
    }
    
    func generateDaysInfo(month : Int, year : Int)
    {
        let calendar = NSCalendar.gregorian();
        
        if let startDate = calendar.date(month: month, year: year) {
            let numberOfdays = startDate.numberOfDaysInMonth();
            var nextDate = startDate
            for _ in 0..<numberOfdays {
                let dateInfo = FTDayInfo.init(localeIdentifier: localeID, formatInfo: format.dayFormat);
                dateInfo.populateDateInfo(date: nextDate);
                self.dayInfo.append(dateInfo);
                nextDate = nextDate.nextDay();
            }
        }
    }
    
    override var description: String {
        return self.dayInfo.description;
    }
}
