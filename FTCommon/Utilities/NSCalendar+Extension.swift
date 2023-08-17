//
//  File.swift
//  
//
//  Created by Narayana on 16/05/22.
//

import Foundation

public extension NSCalendar {
    static func gregorian() -> NSCalendar {
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)
        return calendar!
    }

    func date(month: Int, year: Int, day: Int = 1) -> Date? {
        let calendar = NSCalendar.gregorian()
        var currentComponents = DateComponents()
        currentComponents.year = year
        currentComponents.day = day
        currentComponents.month = month
        currentComponents.hour = 0
        currentComponents.minute = 0
        currentComponents.second = 0
        return calendar.date(from: currentComponents)
    }
}
