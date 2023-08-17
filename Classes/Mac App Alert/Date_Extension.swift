//
//  Date_Extension.swift
//  FTMacAppAlert
//
//  Created by Amar on 27/12/19.
//  Copyright © 2019 Amar. All rights reserved.
//

import UIKit

extension TimeZone
{
    static var utcTimeZone : TimeZone {
        return TimeZone(identifier: "UTC") ?? TimeZone.current;
    }
}

extension DateFormatter
{
    private static var utcZoneDateFormatter : DateFormatter {
        let formatter = DateFormatter();
        formatter.timeZone = TimeZone.utcTimeZone;
        return formatter;
    }

    static func utcDateString(format : String, date : Date) -> String
    {
        let dateFormatter = DateFormatter.utcZoneDateFormatter;
        dateFormatter.dateFormat = format;
        return dateFormatter.string(from: date);
    }
    
    static func utcDate(format : String, dateString : String) -> Date?
    {
        let dateFormatter = DateFormatter.utcZoneDateFormatter;
        dateFormatter.dateFormat = format;
        let date = dateFormatter.date(from: dateString);
        return date
    }
}

extension Calendar
{
    static func compareDate(date : Date, other : Date) -> ComparisonResult
    {
        let gregorian = Calendar.gregorianCalendar;

        let components : [Calendar.Component] = [.month,.day,.year];
        let set = Set.init(components);
        let date1Components = gregorian.dateComponents(set, from: date);
        let date2Components = gregorian.dateComponents(set, from: other);
        
        if let date1 = gregorian.date(from: date1Components),
            let date2 = gregorian.date(from: date2Components) {
            return date1.compare(date2);
        }
        return .orderedAscending;
    }

    private static var gregorianCalendar : Calendar {
        var gregorian = Calendar.current
        gregorian.timeZone = TimeZone.utcTimeZone
        return gregorian;
    }
    
    private func date(dateComponents : DateComponents) -> Date?
    {
        var currentComponents = DateComponents()
        currentComponents.timeZone = TimeZone.utcTimeZone;
        currentComponents.timeZone = TimeZone.current
        currentComponents.year = dateComponents.year
        currentComponents.day = dateComponents.day
        currentComponents.month = dateComponents.month
        currentComponents.hour = 12
        currentComponents.minute = 0
        currentComponents.second = 0
        return self.date(from: currentComponents);
    }
}
