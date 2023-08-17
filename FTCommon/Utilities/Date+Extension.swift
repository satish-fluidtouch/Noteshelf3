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
