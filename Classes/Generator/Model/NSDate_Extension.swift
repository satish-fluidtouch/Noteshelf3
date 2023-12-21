//
//  NSDate_Extension.swift
//  Template Generator
//
//  Created by Amar on 13/11/19.
//  Copyright © 2019 Amar. All rights reserved.
//

import UIKit

private let dateformatter : DateFormatter = DateFormatter();

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

extension Date
{
//    func numberOfDays(date:Date) -> Int {
//        let calendar = NSCalendar.gregorian();
//        let comp = calendar.components(.day, from: self, to: date, options: [])
//        let totalDays = abs(comp.day ?? 1);
//        return totalDays;
//    }
    
    func numberOfDays(calendarYear:FTYearFormatInfo) -> Int {
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!;
        let startDate: Date = calendar.date(month: calendarYear.startMonth.month, year: calendarYear.startMonth.year)!
//        let endDate: Date = calendar.date(month: 12, year: 2019, day: 6)!
        let endDateFirst = calendar.date(month: calendarYear.endMonth.month, year: calendarYear.endMonth.year)!
        let daysInMonth = endDateFirst.numberOfDaysInMonth();
        let endDate = calendar.date(month: endDateFirst.month(), year: endDateFirst.year(), day: daysInMonth)!;
        
        let dayComp = calendar.components(.day, from: startDate, to: self, options: [])
        let totalDays = abs(dayComp.day ?? 1);
        return 1 + 14 + startDate.numberOfWeeks(endDate) + totalDays;
    }
    
    func daysBetween(date:Date) -> Int {
        let calendar = NSCalendar.gregorian();
        let comp = calendar.components(.day, from: self, to: date, options: [])
        let totalDays = abs(comp.day ?? 1);
        return totalDays;
    }
    
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
    func endOfMonth() -> Date {
        return Calendar.current.dateInterval(of: .month, for: Date())!.end
    }
    func compareDate(_ date: Date) -> ComparisonResult {
        let calendar = NSCalendar.gregorian();

        let selfdateComponents = calendar.components([.day,.month,.year], from: self);
        let selfDate = calendar.date(from: selfdateComponents);

        let toDateComponenets = calendar.components([.day,.month,.year], from: date);
        let toDate = calendar.date(from: toDateComponenets);

        if let _selfDate = selfDate, let _toDate = toDate {
            return _selfDate.compare(_toDate);
        }
        return .orderedAscending;
    }

    func nextDay() -> Date
    {
        let calendar = NSCalendar.gregorian();
        var onedayComp = DateComponents();
        onedayComp.day = 1;
        return calendar.date(byAdding: onedayComp, to: self, options: []) ?? self
    }
    
    func numberOfWeeks(_ date : Date) -> Int
    {
        let calendar = NSCalendar.gregorian();
        let comp = calendar.components(.weekOfMonth, from: self, to: date, options: [])
        let totalWeeks = abs(comp.weekOfMonth ?? 0);
        return totalWeeks + 1;
    }

    func nextWeek() -> Date
    {
        let calendar = NSCalendar.gregorian();
        var onedayComp = DateComponents();
        onedayComp.weekOfMonth = 1;
        return calendar.date(byAdding: onedayComp, to: self, options: []) ?? self
    }

    func weekDay() -> Int
    {
        let calendar = NSCalendar.gregorian()
        let components = calendar.components(.weekday, from: self)
        return components.weekday ?? 1;
    }
    func weekNumber() -> Int {
        let calendar = NSCalendar.gregorian()
        let components = calendar.components(.weekOfYear, from: self)
        return components.weekOfYear ?? 1;
    }
    func month() -> Int
    {
        let calendar = NSCalendar.gregorian()
        let components = calendar.components(.month, from: self)
        return components.month ?? 1;
    }

    func year() -> Int
    {
        let calendar = NSCalendar.gregorian()
        let components = calendar.components(.year, from: self)
        return components.year ?? 2019;
    }

    func offsetDate(_ offset : Int) -> Date
    {
        let calendar = NSCalendar.gregorian()
        var components = DateComponents();
        components.day = offset
        return calendar.date(byAdding: components, to: self, options: []) ?? Date();
    }
    
    func monthTitle(localeID : String,monthFormat : String) -> String {
        dateformatter.dateStyle = DateFormatter.Style.full;
        dateformatter.timeStyle = DateFormatter.Style.none;
        let locale = Locale.init(identifier: NSCalendar.calLocale(localeID));
        dateformatter.locale = locale;

        dateformatter.dateFormat = monthFormat
        if(["ja","zh_hans","zh_hant"].contains(localeID.lowercased())) {
            let currentLocale = dateformatter.locale;
            let usLocale = Locale.init(identifier: "en")
            dateformatter.locale = usLocale;
            dateformatter.locale = currentLocale;
        }
        return dateformatter.string(from: self);
    }
}
#if  !NS2_SIRI_APP && !NOTESHELF_ACTION
extension UIFont {
    static func baskervilleMedium(_ fontSize: CGFloat) -> UIFont{
        guard let font = UIFont(name: "BaskervilleT-Medi", size: fontSize) else {
            return UIFont.systemFont(ofSize: fontSize);
        }
        return font
    }
    
    static func baskervilleRegular(_ fontSize: CGFloat) -> UIFont{
        guard let font = UIFont(name: "Baskerville", size: fontSize) else {
            return UIFont.systemFont(ofSize: fontSize);
        }
        return font
    }
    
    static func baskervilleSemiBold(_ fontSize: CGFloat) -> UIFont{
        guard let font = UIFont(name: "Baskerville-SemiBold", size: fontSize) else {
            return UIFont.systemFont(ofSize: fontSize);
        }
        return font
    }
    
    static func robotoMedium(_ fontSize : CGFloat) -> UIFont {
        guard let font = UIFont(name: "Roboto-Medium", size: fontSize) else {
            return UIFont.systemFont(ofSize: fontSize);
        }
        return font
    }
    static func robotoMediumItalic(_ fontSize : CGFloat) -> UIFont {
        guard let font = UIFont(name: "Roboto-MediumItalic", size: fontSize) else {
            return UIFont.systemFont(ofSize: fontSize);
        }
        return font
    }
    static func robotoRegular(_ fontSize: CGFloat) -> UIFont {
        guard let font = UIFont(name: "Roboto-Regular", size: fontSize) else {
            return UIFont.systemFont(ofSize: fontSize);
        }
        return font
    }
    static func robotoLight(_ fontSize: CGFloat) -> UIFont {
        guard let font = UIFont(name: "Roboto-Light", size: fontSize) else {
            return UIFont.systemFont(ofSize: fontSize);
        }
        return font
    }
    static func dancingScriptRegular(_ fontSize : CGFloat) -> UIFont {
        guard let font = UIFont(name: "DancingScript-Regular", size: fontSize) else {
            return UIFont.systemFont(ofSize: fontSize);
        }
        return font
    }
    static func LoraRegular(_ fontSize : CGFloat) -> UIFont {
        guard let font = UIFont(name: "Lora-Regular", size: fontSize) else {
            return UIFont.systemFont(ofSize: fontSize);
        }
        return font
    }
    static func AbelRegular(_ fontSize : CGFloat) -> UIFont {
        guard let font = UIFont(name: "Abel-Regular", size: fontSize) else {
            return UIFont.systemFont(ofSize: fontSize);
        }
        return font
    }
    static func SpectralRegular(withFontSize fontSize : CGFloat) -> UIFont {
        guard let font = UIFont(name: "Spectral-Regular", size: fontSize) else {
            return UIFont.systemFont(ofSize: fontSize);
        }
        return font
    }
    static func LoraItalic(_ fontSize : CGFloat) -> UIFont {
        guard let font = UIFont(name: "Lora-Italic", size: fontSize) else {
            return UIFont.systemFont(ofSize: fontSize);
        }
        return font
    }
    static func SpectralMedium(withFontSize fontSize : CGFloat) -> UIFont {
        guard let font = UIFont(name: "Spectral-Medium", size: fontSize) else {
            return UIFont.systemFont(ofSize: fontSize);
        }
        return font
    }
    static func SpectralSemiBold(withFontSize fontSize : CGFloat) -> UIFont {
        guard let font = UIFont(name: "Spectral-SemiBold", size: fontSize) else {
            return UIFont.systemFont(ofSize: fontSize);
        }
        return font
    }
    static func LoraMedium(_ fontSize : CGFloat) -> UIFont {
        guard let font = UIFont(name: "Lora-Medium", size: fontSize) else {
            return UIFont.systemFont(ofSize: fontSize);
        }
        return font
    }
    static func InterMedium(_ fontSize : CGFloat) -> UIFont {
        guard let font = UIFont(name: "Lora-Inter-Medium", size: fontSize) else {
            return UIFont.systemFont(ofSize: fontSize);
        }
        return font
    }
    static func InterLight(_ fontSize : CGFloat) -> UIFont {
        guard let font = UIFont(name: "Inter-Light", size: fontSize) else {
            return UIFont.systemFont(ofSize: fontSize);
        }
        return font
    }
    static func InterSemiBold(_ fontSize : CGFloat) -> UIFont {
        guard let font = UIFont(name: "Inter-SemiBold", size: fontSize) else {
            return UIFont.systemFont(ofSize: fontSize);
        }
        return font
    }
    static func InterRegular(_ fontSize : CGFloat) -> UIFont {
        guard let font = UIFont(name: "Inter-Regular", size: fontSize) else {
            return UIFont.systemFont(ofSize: fontSize);
        }
        return font
    }
}
extension Date {
    func utcDate() -> Date?
    {
        let gmtDf = DateFormatter()
        gmtDf.dateFormat = "yyyy-MM-dd"
        let gmtDate = gmtDf.string(from: self);

        let estDate = DateFormatter.utcDate(format: "yyyy-MM-dd", dateString: gmtDate);
        return estDate;
    }
}
#endif
