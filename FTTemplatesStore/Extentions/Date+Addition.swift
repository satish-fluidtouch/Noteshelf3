//
//  UIView+Addition.swift
//  TempletesStore
//
//  Created by Siva on 01/06/23.
//

import UIKit

extension Date {
    func numberOfDaysInMonth() -> Int
    {
        let calendar = NSCalendar.gregorian();
        let days = calendar.range(of: .day, in: .month, for: self);
//        let totalDays = days.length + days.location;
        let totalDays = days.length;
        return totalDays;
    }

    func lastDateOfMonth() -> Date?
    {
        let calendar = NSCalendar.gregorian()
        let dayCount = self.numberOfDaysInMonth()

        var comp = calendar.components([.year, .month, .day], from: self)
        comp.day = dayCount
        return calendar.date(from: comp)!
    }

    func numberOfMonths(_ date : Date) -> Int
    {
        let calendar = NSCalendar.gregorian();
        let comp = calendar.components(.month, from: self, to: date, options: [])
        let totalMonths = abs(comp.month ?? 0);
        return totalMonths + 1;
    }
}

extension NSCalendar
{
    static func calLocale(_ locale : String) -> String
    {
        if(["ja","zh_hans","zh_hant","ko","zh"].contains(locale.lowercased())) {
            return "en";
        }
        return locale;
    }

    static func gregorian() -> NSCalendar
    {
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian);
        return calendar!;
    }

    func date(month : Int, year : Int,day : Int = 1) -> Date?
    {
        let calendar = NSCalendar.gregorian();
        var currentComponents = DateComponents()
        currentComponents.year = year
        currentComponents.day = day
        currentComponents.month = month
//        currentComponents.weekday = 1
        currentComponents.hour = 0
        currentComponents.minute = 0
        currentComponents.second = 0
        return calendar.date(from: currentComponents);
    }
}
