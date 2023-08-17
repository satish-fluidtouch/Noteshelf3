//
//  FTDateInfo.swift
//  Template Generator
//
//  Created by Amar on 13/11/19.
//  Copyright © 2019 Amar. All rights reserved.
//

import UIKit

class FTDayFormatInfo {
    var dayFormat : String = "EEEE";
    var dayShortFormat : String = "E"
    var yearFormat : String = "yyyy";
    var dateFormat : String = "d";
    var monthFormat : String = "MMM";
    var fulldayFormat : String = "dd";
}

class FTDayInfo: NSObject {

    private(set) var dayString : String = "1"
    private(set) var fullDayString : String = "01"
    private(set) var weekString : String = "Sunday";
    private(set) var monthString :  String = "Jan";
    private(set) var fullMonthString :  String = "January";
    private(set) var yearString : String = "2019";
    private(set) var weekDay : String = "S";
    private(set) var month : Int = 1;
    private(set) var year : Int = 1;
    private(set) var date : Date = Date();
    private(set) var weekShortString : String = "Sun";
    private(set) var shortWeekRange: String = "03 Oct - 09 Oct"
    private(set) var fullWeekRange: String = "03 October - 09 October"

    private(set) var weekNumber : Int = 1;

    var belongsToSameMonth : Bool = true;

    private var localeID : String = "en";
    private var format : FTDayFormatInfo;
    
    required init(localeIdentifier : String,formatInfo : FTDayFormatInfo)
    {
        localeID = localeIdentifier;
        format = formatInfo;
        super.init();
    }
    
    func populateDateInfo(date : Date)
    {
        self.date = date;
        
        monthString = date.monthTitle(localeID: localeID, monthFormat: format.monthFormat);
        fullMonthString = date.monthTitle(localeID: localeID, monthFormat: "MMMM");
        
        let dateformatter = DateFormatter.init();
        dateformatter.dateStyle = DateFormatter.Style.full;
        dateformatter.timeStyle = DateFormatter.Style.none;
        let locale = Locale.init(identifier: NSCalendar.calLocale(localeID));
        dateformatter.locale = locale;

        dateformatter.dateFormat = format.dateFormat
        dayString = dateformatter.string(from: date);
        
        dateformatter.dateFormat = format.fulldayFormat
        fullDayString = dateformatter.string(from: date);

        dateformatter.dateFormat = format.yearFormat
        yearString = dateformatter.string(from: date);
        
        let day = date.weekDay();
        
        dateformatter.locale = Locale.init(identifier: localeID)
        weekDay = dateformatter.veryShortWeekdaySymbols[day-1];
        
        weekNumber = date.weekNumber()
        
        dateformatter.dateFormat = format.dayFormat
        weekString = dateformatter.string(from: date);
        
        dateformatter.dateFormat = format.dayShortFormat
        weekShortString = dateformatter.string(from: date);
        
        month = date.month()
        year = date.year()
        
        if let startDateOfWeek = date.startOfWeek, let endDateOfWeek = date.endOfWeek {
            dateformatter.dateFormat = format.fulldayFormat
            let startDay = dateformatter.string(from: startDateOfWeek)
            let endDay = dateformatter.string(from: endDateOfWeek)
            var startMonth = startDateOfWeek.monthTitle(localeID: localeID, monthFormat: "MMM")
            var endMonth = endDateOfWeek.monthTitle(localeID: localeID, monthFormat: "MMM")
            shortWeekRange = "\(startDay) \(startMonth) - \(endDay) \(endMonth)"
            startMonth = startDateOfWeek.monthTitle(localeID: localeID, monthFormat: "MMMM")
            endMonth = endDateOfWeek.monthTitle(localeID: localeID, monthFormat: "MMMM")
            fullWeekRange = "\(startDay) \(startMonth) - \(endDay) \(endMonth)"
        }

    }
    
    override var description: String {
        let description = """
        Desc:
        day: \(self.dayString)
        week: \(self.weekString)
        month: \(self.monthString)
        year: \(self.yearString)
        weekDay: \(self.weekDay)
        """
        return description;
    }
}

extension Date {
    var startOfWeek: Date? {
        let gregorian = Calendar(identifier: .gregorian)
        guard let startDay = gregorian.date(from: gregorian.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else { return nil }
        return startDay
    }

    var endOfWeek: Date? {
        let gregorian = Calendar(identifier: .gregorian)
        guard let startDay = gregorian.date(from: gregorian.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else { return nil }
        return gregorian.date(byAdding: .day, value: 6, to: startDay)
    }
}
