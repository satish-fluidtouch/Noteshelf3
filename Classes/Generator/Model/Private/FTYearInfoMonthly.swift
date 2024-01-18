//
//  FTYearInfoMonthly.swift
//  Template Generator
//
//  Created by Amar on 13/11/19.
//  Copyright © 2019 Amar. All rights reserved.
//

import UIKit

class FTDate
{
    var month : Int = 1;
    var year : Int = 2019;
}
enum FTWeekFormat : String {
    case Sunday = "1"
    case Monday = "2"
}

class FTYearFormatInfo : NSObject
{
    var dayFormat = FTDayFormatInfo();
    
    private(set) var startMonth = FTDate();
    private(set) var endMonth = FTDate();
    
    var supportsForAllLocales : Bool = true
    let locale = Locale.current.language.languageCode?.identifier.lowercased() ?? "en"
    var screenSize = UIDevice.deviceSpecificKey()
    var screenType: FTScreenType = UIDevice.deviceScreenType()
    private(set) var templateId : FTTemplateID = .digitalDiariesClassic
    private(set) var orientation = FTScreenOrientation.Port.rawValue
    private(set) var weekFormat = "1"
    var customVariants : FTPaperVariants = FTBasicTemplatesDataSource.shared.getDefaultVariants()

    init(year : Int) {
        self.startMonth.month = 12;
        self.startMonth.year = year - 1;

        self.endMonth.month = 1;
        self.endMonth.year = year + 1;
    }
    
    init(startDate: Date, endDate: Date) {
        self.startMonth.month = startDate.month();
        self.startMonth.year = startDate.year();
        
        self.endMonth.month = endDate.month();
        self.endMonth.year = endDate.year();
    }
    
    init(startDate: Date, endDate: Date, theme:FTAutoTemlpateDiaryTheme, weekFormat : FTWeekFormat = .Sunday)
    {
        self.startMonth.month = startDate.month();
        self.startMonth.year = startDate.year();

        self.endMonth.month = endDate.month();
        self.endMonth.year = endDate.year();

        self.templateId = theme.templateId;
        self.orientation = theme.customvariants.isLandscape ? FTScreenOrientation.Land.rawValue : FTScreenOrientation.Port.rawValue;
        
        self.screenSize = theme.customvariants.selectedDevice.dimension;
        self.screenType = theme.customvariants.selectedDevice.isiPad ? FTScreenType.Ipad : FTScreenType.Iphone;
        self.customVariants = theme.customvariants
        if (templateId == .digitalDiariesColorfulPlanner || templateId == .digitalDiariesColorfulPlannerDark), self.screenType == .Iphone { // As mobile version is not developed, pointing to default iPad 10.5 size
            self.screenType = .Ipad
            self.screenSize = FTDeviceDataManager().standardiPadDevice.dimension
            self.customVariants.selectedDevice = FTDeviceDataManager().standardiPadDevice
        }
        if templateId == .landscapeDiariesColorfulPlanner , self.screenType == .Iphone {
            self.screenType = .Ipad
            self.orientation = FTScreenOrientation.Land.rawValue;
            self.screenSize = FTDeviceDataManager().standardiPadDevice.dimension
            self.customVariants.selectedDevice = FTDeviceDataManager().standardiPadDevice
        }
        if templateId != .digitalDiariesMidnight , templateId != .digitalDiariesDayandNightJournal, self.screenType == .Iphone{
            self.orientation = FTScreenOrientation.Port.rawValue;
        }
        self.weekFormat = weekFormat.rawValue
    }
}

class FTYearInfoMonthly: NSObject {
    
    private(set) var monthInfo = [FTMonthInfo]();
    private(set) var monthCalendarInfo = [FTMonthlyCalendarInfo]();

    private var localeID : String = "en";
    private var format : FTYearFormatInfo;
    private var _weekFormat : String;
    
    required init(formatInfo : FTYearFormatInfo)
    {
        if formatInfo.supportsForAllLocales {
            localeID = formatInfo.locale;
        }
        format = formatInfo;
        self._weekFormat = formatInfo.weekFormat
        super.init();
    }

    func generate() {
        let calendar = NSCalendar.gregorian();

        let startDate = calendar.date(month: format.startMonth.month, year: format.startMonth.year);
        let endDateFirst = calendar.date(month: format.endMonth.month, year: format.endMonth.year);

        let daysInMonth = endDateFirst?.numberOfDaysInMonth() ?? 1;
        let endDate = calendar.date(month: format.endMonth.month,
                                          year: format.endMonth.year,
                                          day: daysInMonth);

        let totalMonths = (endDate?.numberOfMonths(startDate!) ?? 0);
        
        var curMonth = format.startMonth.month;
        var curYear = format.startMonth.year;
        let formatter = self.dateformatter
        for _ in 0..<totalMonths {
            let month = FTMonthInfo.init(localeIdentifier: localeID, formatInfo: format,weekFormat: self._weekFormat,dateformatter: formatter);
            if(curMonth > 12) {
                curMonth = 1;
                curYear += 1;
            }
            month.generate(month: curMonth, year: curYear);
            monthInfo.append(month);
            
            let monthCalendar = FTMonthlyCalendarInfo.init(localeIdentifier: localeID, formatInfo: format.dayFormat,weekFormat:self._weekFormat);
            monthCalendar.generate(month: curMonth, year: curYear,dateFormatter: formatter);
            monthCalendarInfo.append(monthCalendar);
            
            curMonth += 1;
        }
        #if DEBUG
        debugPrint("monthInfo: \(monthInfo) monthCalendarInfo:\(monthCalendarInfo)");
        #endif
    }
    private var dateformatter : DateFormatter {
        let dateformatter = DateFormatter()
        dateformatter.dateStyle = DateFormatter.Style.full;
        dateformatter.timeStyle = DateFormatter.Style.none;
        let locale = Locale.init(identifier: NSCalendar.calLocale(localeID));
        dateformatter.locale = locale;
        return dateformatter
    }
}
