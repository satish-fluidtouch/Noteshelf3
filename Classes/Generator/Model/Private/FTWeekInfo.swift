//
//  FTWeekInfo.swift
//  Template Generator
//
//  Created by Amar on 13/11/19.
//  Copyright © 2019 Amar. All rights reserved.
//

import UIKit

class FTWeekInfo: NSObject {
    private(set) var dayInfo = [FTDayInfo]();
    
    private var localeID : String = "en";
    private var format : FTDayFormatInfo;

    required init(localeIdentifier : String,formatInfo : FTDayFormatInfo)
    {
        localeID = localeIdentifier;
        format = formatInfo;
        super.init();
    }
    
    func generate(forWeekDate date: Date)
    {
        let weekStartDate = date //date.offsetDate(1-dayOfWeek);
        
        let nextWeekStartDate = weekStartDate.nextWeek();

        var curDate = weekStartDate;
        while curDate.compareDate(nextWeekStartDate) != .orderedSame {
            let _dayInfo = FTDayInfo.init(localeIdentifier: localeID, formatInfo: format);
            _dayInfo.populateDateInfo(date: curDate);
            self.dayInfo.append(_dayInfo)
            curDate = curDate.nextDay();
        }
    }
    
    override var description: String {
        return "Week:\(dayInfo.description)";
    }
}
