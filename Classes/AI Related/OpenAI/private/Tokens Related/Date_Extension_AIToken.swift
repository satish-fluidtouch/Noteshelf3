//
//  Date_Extension_AIToken.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 09/10/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension Date {
    static var utcDate: Date {
        let format = DateFormatter.utcDateString(format: "yyyy-MM-dd", date: Date());
        return Date.dateFromUTC(format)
    }
    
    var utcDateString: String {
        let format = DateFormatter.utcDateString(format: "yyyy-MM-dd", date: self);
        return format;
    }
    
    static func dateFromUTC(_ dateString: String) -> Date {
        let date = DateFormatter.utcDate(format: "yyyy-MM-dd", dateString: dateString);
        return date ?? Date();
    }
    
    func startDayOfMonth() -> Date {
        let gregorian = Calendar.gregorian;
        let dateComponents = gregorian.dateComponents([.year, .month], from: self);
        
        var currentComponents = DateComponents()
        currentComponents.timeZone = TimeZone.utcTimeZone;
        currentComponents.year = dateComponents.year
        currentComponents.day = dateComponents.day
        currentComponents.month = dateComponents.month
        currentComponents.hour = 0
        currentComponents.minute = 0
        currentComponents.second = 0
        return gregorian.date(from: currentComponents) ?? self;
    }
    
    var nextMonth: Date {
        let gregorian = Calendar.gregorian;
        let nextMonth = gregorian.date(byAdding: .month, value: 1, to: self) ?? Date();
        return nextMonth;
    }
}

private extension Calendar {
    static var gregorian: Calendar {
        return Calendar(identifier: Calendar.Identifier.gregorian);
    }
}
