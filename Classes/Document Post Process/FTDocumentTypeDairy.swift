//
//  FTDocumentTypeDairy.swift
//  Noteshelf
//
//  Created by Matra on 19/11/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import Foundation


class FTDocumentTypeDairy: NSObject,FTPostProcess {

    fileprivate var fileURL : URL!
    fileprivate var documentInfo : FTDocumentInputInfo!
    
    override init() {
        super.init();
    }
    
    required convenience init(url: URL, info : FTDocumentInputInfo) {
        self.init();
        self.fileURL = url
        self.documentInfo = info
    }
    
    func perform(completion : @escaping () -> Void) {
        let pageNumber = self.pageNumberForCurrentDate()
        let request = FTDocumentOpenRequest(url: self.fileURL, purpose: .write);
        FTNoteshelfDocumentManager.shared.openDocument(request: request) { (token, document, _) in
            if let doc = document {
                doc.localMetadataCache?.lastViewedPageIndex = pageNumber;
                FTNoteshelfDocumentManager.shared.saveAndClose(document: doc, token: token) { (_) in
                    completion()
                }
            }
            else {
                completion()
            }
        }
    }
    
    func pageNumberForCurrentDate() -> Int {
//        var date = startDateForCalendar()
        var date = startDateForCalendar()
        let endDate = endDateForCalendar()
        
        let calendar = Calendar.current
        var component = calendar.dateComponents([.day , .month, .year, .hour, .minute, .second], from: Date())
        component.hour = 1
        component.minute = 0
        component.second = 0
        let currentDate = calendar.date(from: component)
        if date > currentDate! || currentDate! > endDate {
            return 0
        }
        
        if self.documentInfo.postProcessInfo.documentType == FTDocumentType.diary {
            let daysComponent = calendar.dateComponents([.day], from: date, to: currentDate!)
            let monthsComponent = calendar.dateComponents([.month], from: date, to: currentDate!)
            if let totalDays = daysComponent.day, let typeMonths = monthsComponent.month {
                let pageNumber = totalDays + typeMonths + 1 + 1 // +1 for year page : +1 for current day
                return pageNumber
            }
        }
        else if self.documentInfo.postProcessInfo.documentType == .dailyAndWeeklyPlanner {
            return (NSCalendar.current as NSCalendar).dayIndex(date: Date())
        }
        else {
            let currentWeekDay = (calendar.dateComponents([.weekday], from: date)).weekday
            if currentWeekDay != 2 { // checking starting of week for 2 becuase we are staring week from
                                    //Monday(weekday = 2)
                var additionaldays = 2 - currentWeekDay!
                if currentWeekDay! < 2 {
                    additionaldays = -6
                }
                date = calendar.date(byAdding: .day, value: additionaldays, to: date)!
            }
            let daysComponent = calendar.dateComponents([.weekOfYear], from: date, to: currentDate!)
            let numberOfWeeks = daysComponent.weekOfYear! + 1  // +1 for year page
            return numberOfWeeks
        }
        
        return 0
    }
    
    
    func startDateForCalendar() -> Date {
        let calendar = Calendar.init(identifier: Calendar.Identifier.gregorian)
        let lastComponents = NSDateComponents()
        if let startYear = self.documentInfo.postProcessInfo.diaryStartYear {
            lastComponents.year = startYear
        }
        else {
            let currentYearInt = (calendar.component(.year, from: Date()))
            lastComponents.year = currentYearInt
        }
        lastComponents.day = 1
        lastComponents.month = 12
        lastComponents.hour = 1
        lastComponents.minute = 0
        lastComponents.second = 0
        
        let date = calendar.date(from: lastComponents as DateComponents);
        return date!
    }
    
    func endDateForCalendar() -> Date {
        let calendar = Calendar.init(identifier: Calendar.Identifier.gregorian)
        let lastComponents = NSDateComponents()
        if let startYear = self.documentInfo.postProcessInfo.diaryStartYear {
            lastComponents.year = startYear + 2
        }
        else {
            let currentYearInt = (calendar.component(.year, from: Date()))
            lastComponents.year = currentYearInt + 2
        }
        lastComponents.day = 31
        lastComponents.month = 1
        lastComponents.hour = 1
        lastComponents.minute = 0
        lastComponents.second = 0
        
        let date = calendar.date(from: lastComponents as DateComponents);
        return date!
    }
}
