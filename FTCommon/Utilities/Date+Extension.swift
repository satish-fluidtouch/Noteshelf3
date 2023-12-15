//
//  File.swift
//  
//
//  Created by Narayana on 16/05/22.
//

import Foundation

public extension Date {
    func month() -> Int {
        let calendar = NSCalendar.gregorian()
        let components = calendar.components(.month, from: self)
        return components.month ?? 1
    }

    func year() -> Int {
        let calendar = NSCalendar.gregorian()
        let components = calendar.components(.year, from: self)
        return components.year ?? 2019
    }
}

public class FTShortStyleDateFormatter {
    public static let shared = FTShortStyleDateFormatter()
    private let formatter: DateFormatter
    
    private init() {
        formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = .current
    }
    
   public func shortStyleFormat(for date: Date) -> String {
        return formatter.string(from: date)
    }
}
