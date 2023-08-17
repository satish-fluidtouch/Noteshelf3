//
//  FTYearInfoWeekly.swift
//  Template Generator
//
//  Created by Amar on 13/11/19.
//  Copyright © 2019 Amar. All rights reserved.
//

import UIKit

class FTYearInfoWeekly: NSObject {
    private(set) var weeklyInfo = [FTWeekInfo]();
    private var localeID : String = "en";
    private var format : FTYearFormatInfo;
    private var _weekFormat: String = "1";
    
    required init(formatInfo : FTYearFormatInfo)
    {
        localeID = formatInfo.locale
        format = formatInfo;
        _weekFormat = format.weekFormat;
        super.init();
    }

    func generate()
    {
        let calendar = NSCalendar.gregorian();

        var startDate = calendar.date(month: format.startMonth.month, year: format.startMonth.year);
        let startweekDay = startDate!.weekDay();
        let weekStartOff = Int(_weekFormat);
        var startOffset = 1 - startweekDay
        if(weekStartOff == 2) {
            if startweekDay == 1 {
                startOffset = -6
            }else {
                startOffset = 2 - startweekDay
            }
        }
        
        startDate = startDate?.offsetDate(startOffset);
        
        let endDateFirst = calendar.date(month: format.endMonth.month, year: format.endMonth.year);

        let daysInMonth = endDateFirst?.numberOfDaysInMonth() ?? 1;
        var endDate = calendar.date(month: format.endMonth.month,
                                    year: format.endMonth.year,
                                    day: daysInMonth);
        let endweekDay = endDate!.weekDay();
        if(weekStartOff == 1) {
            endDate = endDate?.offsetDate(7 - endweekDay);
        }
        else {
            var startOffset = 6 - endweekDay
            if endweekDay == 1 {
                startOffset = 0
            }
            endDate = endDate?.offsetDate(startOffset);
        }
        let numberOFWeeks = (startDate?.numberOfWeeks(endDate!) ?? 0);
        var weekDay = startDate!;
        for _ in 0..<numberOFWeeks {
            let weekInfo = FTWeekInfo.init(localeIdentifier: localeID, formatInfo: format.dayFormat);
            weekInfo.generate(forWeekDate: weekDay);
            weekDay = weekDay.nextWeek();
            self.weeklyInfo.append(weekInfo);
        }
        #if DEBUG
        debugPrint("info: \(self.weeklyInfo)");
        #endif
    }
    
    override var description: String {
        return weeklyInfo.description;
    }
}
