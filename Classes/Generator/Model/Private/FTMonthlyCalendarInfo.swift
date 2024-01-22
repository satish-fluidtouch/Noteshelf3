//
//  FTMonthlyCalendarInfo.swift
//  Template Generator
//
//  Created by Amar on 19/11/19.
//  Copyright © 2019 Amar. All rights reserved.
//

import UIKit

class FTMonthlyCalendarInfo: NSObject {
    private(set) var dayInfo = [FTDayInfo]();
    private(set) var year : String = "2020";
    private(set) var shortMonth : String = "Jan";
    private(set) var fullMonth : String = "Jan";
    
    private(set) var localeID : String = "en";
    private var format : FTDayFormatInfo;
    private var _weekFormat : String;
    private(set) var numberOfdaysInMonth : Int = 1
    private(set) var weeklyInfo = [FTWeekInfo]();
    
    required init(localeIdentifier : String,formatInfo : FTDayFormatInfo,weekFormat: String)
    {
        localeID = localeIdentifier;
        format = formatInfo;
        self._weekFormat=weekFormat
        super.init();
    }

    func generate(month : Int, year : Int, dateFormatter : DateFormatter)
    {
        let calendar = NSCalendar.gregorian();
        if var startDate = calendar.date(month: month, year: year) {
             numberOfdaysInMonth = startDate.numberOfDaysInMonth() - 1;

            let dateInfo = FTDayInfo.init(localeIdentifier: localeID, formatInfo: format);
            dateInfo.populateDateInfo(date: startDate, dateFormatter: dateFormatter);
            self.shortMonth = dateInfo.monthString;
            self.fullMonth = dateInfo.fullMonthString;
            self.year = dateInfo.yearString;
            
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
            var endDate = startDate.lastDateOfMonth();
            startDate = startDate.offsetDate(startOffset);
            var endOffset = 7 - lastDayOfMonth!.weekDay();
            endDate = endDate?.offsetDate(7 - lastDayOfMonth!.weekDay())
            if _weekFormat.elementsEqual("2"){
                if lastDayOfMonth!.weekDay() == 1 {
                    endOffset = 0
                }else {
                    endOffset = 8 - lastDayOfMonth!.weekDay()
                }
            }
            
            var numberOfdays = numberOfdaysInMonth + endOffset+abs(startOffset);
            
            var nextDate = startDayOfMonthCal
            endDate = nextDate;
            if numberOfdays < 42{
                numberOfdays = 42
            }
            
            for _ in 0..<numberOfdays {
                let dateInfo = FTDayInfo.init(localeIdentifier: localeID, formatInfo: format);
                dateInfo.populateDateInfo(date: nextDate, dateFormatter: dateFormatter);
                endDate = nextDate;

                if(nextDate.month() != month) {
                    dateInfo.belongsToSameMonth = false;
                }
                self.dayInfo.append(dateInfo);
                nextDate = nextDate.nextDay();
            }
            let numberOFWeeks = (startDate.numberOfWeeks(endDate!) );
            var weekDay = startDate;
            for _ in 0..<numberOFWeeks {
                let weekInfo = FTWeekInfo.init(localeIdentifier: localeID, formatInfo: format, dateFormatter: dateFormatter);
                weekInfo.generate(forWeekDate: weekDay);
                weekDay = weekDay.nextWeek();
                self.weeklyInfo.append(weekInfo);
            }
        }
    }
    // weeks count whose first day belong to itself
    func getWeeksCount() -> Int {
        return weeklyInfo.filter({$0.dayInfo.first?.fullMonthString.uppercased()  == self.fullMonth.uppercased()}).count
    }
    override var description: String {
        return self.dayInfo.description;
    }
    var weeksCount : Int {
        return  weeklyInfo.reduce(0) { partialResult, weekInfo in
            return partialResult + (weekInfo.dayInfo.first?.fullMonthString.uppercased() == fullMonth.uppercased() ? 1 : 0)
        }
    }
}
