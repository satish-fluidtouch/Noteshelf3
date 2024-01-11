//
//  FTClassicDiaryFormat.swift
//  Noteshelf
//
//  Created by Ramakrishna on 03/08/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTClassicDiaryFormat : FTDairyFormat {
    var customVariants : FTPaperVariants
    var currentDayRectsInfo: FTDiaryDayRectsInfo = FTDiaryDayRectsInfo()
    var currentWeekRectInfo: FTDiaryWeekRectsInfo = FTDiaryWeekRectsInfo()
    
    var isiPad : Bool {
        return true
    }
    required init(customVariants : FTPaperVariants){
        self.customVariants = customVariants
        super.init()
    }
    class func getFormatBasedOn(variants: FTPaperVariants) -> FTClassicDiaryFormat{
        if !variants.selectedDevice.isiPad  {
            return FTClassicDiaryiPhoneFormat(customVariants: variants)
        }
        return  FTClassicDiaryiPadFormat(customVariants: variants)
    }
    override var yearTemplate: String {
        return getClassicDiaryAssetPDFPath(ofType: FTClassicDiaryTemplateType.year, customVariants: formatInfo.customVariants)
    }
    override var monthTemplate: String {
        return getClassicDiaryAssetPDFPath(ofType: FTClassicDiaryTemplateType.month, customVariants: formatInfo.customVariants)
    }
    override var weekTemplate: String {
        return getClassicDiaryAssetPDFPath(ofType: FTClassicDiaryTemplateType.week, customVariants: formatInfo.customVariants)
    }
    override var dayTemplate: String {
        return getClassicDiaryAssetPDFPath(ofType: FTClassicDiaryTemplateType.day, customVariants: formatInfo.customVariants)
    }
    var calendarTemplate: String {
        return getClassicDiaryAssetPDFPath(ofType: FTClassicDiaryTemplateType.calendar, customVariants:formatInfo.customVariants)
    }
    func renderCalendarPage(context : CGContext,months : [FTMonthlyCalendarInfo],calendarYear : FTYearFormatInfo){
        
    }
    override func getTemplateBackgroundColor() -> UIColor {
        return UIColor(hexString: "#FAFAEF")
    }
    override func getYearCellHeight(rowCount: CGFloat) -> CGFloat {
        let templateInfo = screenInfo.spacesInfo.yearPageSpacesInfo
        return (currentPageRect.size.height - (currentPageRect.size.height*templateInfo.baseBoxY/100) - (currentPageRect.size.height*templateInfo.boxBottomOffset/100) - ((rowCount - 1) * (currentPageRect.size.height*templateInfo.cellOffsetY/100)))/rowCount
    }
    override func getYearCellWidth(columnCount: CGFloat) -> CGFloat {
        let templateInfo = screenInfo.spacesInfo.yearPageSpacesInfo
        return (currentPageRect.size.width - (2 * (currentPageRect.size.width*templateInfo.baseBoxX/100)) - ((columnCount - 1) * (currentPageRect.size.width*templateInfo.cellOffsetX/100)))/columnCount
    }
    
    func getClassicDiaryAssetPDFPath(ofType type : FTClassicDiaryTemplateType, customVariants variants: FTPaperVariants) -> String {
        var customVariants = variants
        let journalScreenType : String =  self.isiPad ? "ipad" :"iphone"
        let isiPad = (journalScreenType == "ipad") ? "1" : "0"
        customVariants.selectedDevice = FTDeviceModel(dictionary: ["displayName" : variants.selectedDevice.displayName.displayTitle,
                                                                   "dimension" : variants.selectedDevice.dimension,
                                                                   "identifier" : variants.selectedDevice.identifier,
                                                                   "dimension_land": variants.selectedDevice.dimension_land,
                                                                   "dimension_port":variants.selectedDevice.dimension_port,
                                                                   "isiPad" : isiPad])
        let orientation = customVariants.isLandscape ? "Land" : "Port"
        let screenType = customVariants.selectedDevice.isiPad ? "iPad" : "iPhone"
        let screenSize = FTFiveMinJournalFormat.getScreenSize(fromVariants: customVariants)
        let key = type.displayName + "_" + screenType + "_" + orientation +  "_" + "\(screenSize.width)" + "_"
            + "\(screenSize.height)"
//        let pdfURL = self.rootPath.appendingPathComponent(key).appendingPathExtension("pdf")
//        if FileManager.default.fileExists(atPath: pdfURL.path){
//            return pdfURL.path
//        }else{
            let templateDiaryInfo = FTClassicDiaryTemplateInfo(templateType: type,customVariants: customVariants)
            let generator = FTClassicDiaryTemplateAssetGenerator(templateInfo: templateDiaryInfo)
            let generatedPDFURL = generator.generate()
            return generatedPDFURL.path
        //}
    }
    class func getScreenSize(fromVariants variants: FTPaperVariants) -> CGSize {
        let dimension = variants.isLandscape ? variants.selectedDevice.dimension_land : variants.selectedDevice.dimension_port
        let measurements = dimension.split(separator: "_")
        return CGSize(width: Int(measurements[0])!, height: Int(Double(measurements[1])!))
    }
    func renderFiveMinJournalPDF(context: CGContext, pdfTemplatePath path:String){
        UIGraphicsBeginPDFPage();
        let pageRect = UIGraphicsGetPDFContextBounds();
        
        let templatePath = path;
        let pdfDocument = PDFDocument.init(url: URL(fileURLWithPath: templatePath));
        let pdfPage = pdfDocument!.page(at: 0);
        
        context.saveGState();
        context.translateBy(x: 0, y: pageRect.size.height);
        context.scaleBy(x: 1, y: -1);
        pdfPage?.transform(context, for: .cropBox);
        pdfPage?.draw(with: .cropBox, to: context);
        context.restoreGState();
    }
    //MARK:- PDF Generation and linking between pages
    override func generateCalendar(context : CGContext, monthlyFormatter : FTYearInfoMonthly, weeklyFormatter : FTYearInfoWeekly){
        
        self.renderYearPage(context: context, months: monthlyFormatter.monthInfo, calendarYear: formatInfo);

        self.renderCalendarPage(context: context, months: monthlyFormatter.monthCalendarInfo, calendarYear: self.formatInfo)
    
        let calendarMonths = monthlyFormatter.monthCalendarInfo;
        calendarMonths.forEach { (calendarMonth) in
            self.renderMonthPage(context: context, monthInfo: calendarMonth, calendarYear: formatInfo)
            self.diaryPagesInfo.append(FTDiaryPageInfo(type: .month))
        }
        let weeklyInfo = weeklyFormatter.weeklyInfo;
        weeklyInfo.forEach { (weekInfo) in
            self.renderWeekPage(context: context, weeklyInfo: weekInfo)
            self.diaryPagesInfo.append(FTDiaryPageInfo(type: .week))
        }

        let monthInfo = monthlyFormatter.monthCalendarInfo;
        monthInfo.forEach { (eachMonth) in
            let dayInfo = eachMonth.dayInfo;
            dayInfo.forEach { (eachDayInfo) in
                if eachDayInfo.belongsToSameMonth {
                    self.renderDayPage(context: context, dayInfo: eachDayInfo);
                    if let utcDate = eachDayInfo.date.utcDate() {
                        diaryPagesInfo.append(FTDiaryPageInfo(type: .day,date: utcDate.timeIntervalSinceReferenceDate))
                    }
                }
            }
        }
    }
    override func calendarOffsetCount() -> Int {
        return self.offsetCount
    }
    
    //:- linking pages
        
        func linkCalendarPages(doc: PDFDocument, index: Int, format: FTDairyFormat,
                               startDate: Date, endDate: Date, atPoint: CGPoint, monthlyFormatter : FTYearInfoMonthly, weeklyFormatter : FTYearInfoWeekly) -> Int{
            let pageIndex = index
            let calendarMonths = monthlyFormatter.monthCalendarInfo;
            let calendarWeeks = weeklyFormatter.weeklyInfo
            let daysBeforeCount = 1 + startDate.numberOfMonths(endDate) + calendarWeeks.count
            
            let calendarPage = doc.page(at: pageIndex);
            
            var calenderMonthsCount = 1
            for monthRect in format.calendarRectsInfo.monthRects {
                if let page = (doc.page(at: calenderMonthsCount )){
                    calendarPage?.addLinkAnnotation(bounds: monthRect, goToPage: page, at: atPoint)
                }
                calenderMonthsCount += 1
            }
            var monthRectsCount = 0
            calendarMonths.forEach { (eachMonth) in
                let dayRects = format.calendarRectsInfo.dayRects[monthRectsCount]
                var dayRectsCount = 0
                eachMonth.dayInfo.forEach({(eachDay) in
                    let calendarPage = doc.page(at: index)
                    if isBelongToCalendar(currentDate: eachDay.date, startDate: startDate, endDate: endDate) {
                        if eachDay.belongsToSameMonth {
                            if dayRects.count > dayRectsCount {
                                if let page = doc.page(at: eachDay.date.daysBetween(date: startDate) + daysBeforeCount) {
                                    calendarPage?.addLinkAnnotation(bounds: dayRects[dayRectsCount], goToPage: page, at: atPoint)
                                }
                                dayRectsCount += 1
                            }
                            
                        }
                    }
                })
                monthRectsCount += 1
            }
            return pageIndex + 1
        }
        func linkMonthPages(doc: PDFDocument, index: Int, format: FTDairyFormat, isToDisplayOutOfMonthDate: Bool,
                            startDate: Date, endDate: Date, atPoint: CGPoint, monthlyFormatter : FTYearInfoMonthly) -> Int {
            var pageIndex = index
            let calendarMonths = monthlyFormatter.monthCalendarInfo;
            var monthRectsCount = 0
            
            let lastDate = calendarMonths[calendarMonths.count - 1].dayInfo[calendarMonths[calendarMonths.count - 1].dayInfo.count - 1].date
            
            var daysBeforeCount = 1 + startDate.numberOfMonths(endDate) + calendarMonths[0].dayInfo[0].date.numberOfWeeks(lastDate)
            if endDate.daysBetween(date: lastDate) + 1 > 7 {
                daysBeforeCount -= 1
            }
            self.offsetCount = daysBeforeCount
            
            let startweekDay = startDate.weekDay();
            let weekStartOff = Int(formatInfo.weekFormat);
            var startOffset = 1 - startweekDay
            if(weekStartOff == 2) {
                if startweekDay == 1 {
                    startOffset = -6
                }else {
                    startOffset = 2 - startweekDay
                }
            }
            
            let weekcalStartDate = startDate.offsetDate(startOffset);
            let weekBeforeDaysCount : Int = 1 + calendarMonths.count
            calendarMonths.forEach { (eachMonth) in
                let monthPage = doc.page(at: pageIndex);
                let monthRectsInfo = format.monthRectsInfo[monthRectsCount]
                monthPage?.addLinkAnnotation(bounds: monthRectsInfo.yearRect, goToPage: (doc.page(at: 0))!, at : atPoint)
                let weekRectsInfo = monthRectsInfo.weekRects
                if !weekRectsInfo.isEmpty {
                    for (weekIndex, weekRect) in weekRectsInfo.enumerated() {
                        let numberofWeeks = eachMonth.dayInfo[weekIndex*7].date.numberOfWeeks(weekcalStartDate) - 1
                        let weekPageIndex = weekBeforeDaysCount + numberofWeeks
                        if let page = doc.page(at: weekPageIndex), eachMonth.dayInfo[weekIndex*7].date < endDate {
                            monthPage?.addLinkAnnotation(bounds: weekRect, goToPage: page, at: atPoint)
                        }
                    }
                }
                var dayRectsCount = 0
                eachMonth.dayInfo.forEach({(eachDay) in
                    if isBelongToCalendar(currentDate: eachDay.date, startDate: startDate, endDate: endDate) {
                        if isToDisplayOutOfMonthDate {
                            if monthRectsInfo.dayRects.count > dayRectsCount {
                                if let page = doc.page(at: eachDay.date.daysBetween(date: startDate) + daysBeforeCount) {
                                    monthPage?.addLinkAnnotation(bounds: monthRectsInfo.dayRects[dayRectsCount], goToPage: page, at: atPoint)
                                }
                            }
                            dayRectsCount += 1
                        } else {
                            if eachDay.belongsToSameMonth {
                                if monthRectsInfo.dayRects.count > dayRectsCount {
                                    if let page = doc.page(at: eachDay.date.daysBetween(date: startDate) + daysBeforeCount) {
                                        monthPage?.addLinkAnnotation(bounds: monthRectsInfo.dayRects[dayRectsCount], goToPage: page, at: atPoint)
                                    }
                                }
                                dayRectsCount += 1
                            }
                        }
                    }
                })
                pageIndex += 1
                monthRectsCount += 1
            }
            return pageIndex
        }
        
        func linkWeekPages(_nextIndex: Int, yearMonthsCount: Int, index: Int, doc: PDFDocument, format:FTDairyFormat,
                           startDate: Date, endDate: Date, atPoint: CGPoint, weeklyFormatter : FTYearInfoWeekly) -> Int {
            var pageIndex = index
            var nextIndex = _nextIndex
            nextIndex = 1 + yearMonthsCount + weeklyFormatter.weeklyInfo.count
            let weeklyInfo = weeklyFormatter.weeklyInfo;
            var weekRectsCount = 0
            weeklyInfo.forEach { (weekInfo) in
                let weekPage = doc.page(at: pageIndex);
                let weekRectsInfo:FTDiaryWeekRectsInfo = format.weekRectsInfo[weekRectsCount]
                
                let monthTo:Int = startDate.numberOfMonths(weekInfo.dayInfo[0].date) - 1
                
                if isBelongToCalendar(currentDate: weekInfo.dayInfo[0].date, startDate: startDate, endDate: endDate){
                    weekPage?.addLinkAnnotation(bounds: weekRectsInfo.monthRect, goToPage: (doc.page(at: 1 + monthTo))!, at : atPoint)
                }
                weekPage?.addLinkAnnotation(bounds: weekRectsInfo.yearRect, goToPage: (doc.page(at: 0))!, at : atPoint)
                var currentWeekDaysCount=0
                for weekDayRect in weekRectsInfo.weekDayRects{
                    if let page = (doc.page(at: currentWeekDaysCount + nextIndex)) {
                        weekPage?.addLinkAnnotation(bounds: weekDayRect, goToPage: page, at : atPoint)
                    }
                    currentWeekDaysCount+=1
                }
                nextIndex += currentWeekDaysCount
                
                pageIndex += 1
                weekRectsCount += 1
            }
            return pageIndex
        }
        
        func linkDayPages(doc: PDFDocument, startDate: Date, index: Int, format: FTDairyFormat, atPoint: CGPoint, yearMonthsCount: Int,monthlyFormatter : FTYearInfoMonthly) {
            var pageIndex = index
            let monthInfo = monthlyFormatter.monthCalendarInfo;
            var dayRectsCount = 0
            
            let startweekDay = startDate.weekDay();
            let weekStartOff = Int(formatInfo.weekFormat);
            var startOffset = 1 - startweekDay
            if(weekStartOff == 2) {
                if startweekDay == 1 {
                    startOffset = -6
                }else {
                    startOffset = 2 - startweekDay
                }
            }
            
            let weekcalStartDate = startDate.offsetDate(startOffset);
            
            var helperOffset = startDate.weekDay() - 1
            monthInfo.forEach { (eachMonth) in
                let dayInfo = eachMonth.dayInfo;
                dayInfo.forEach { (eachDayInfo) in
                    if eachDayInfo.belongsToSameMonth{
                        let dayPage = doc.page(at: pageIndex);
                        let dayRectsInfo:FTDiaryDayRectsInfo=format.dayRectsInfo[dayRectsCount]
                        
                        var monthTo:Int=eachDayInfo.month
                        let year:Int=eachDayInfo.year
                        
                        if monthTo == formatInfo.startMonth.month && year == formatInfo.startMonth.year {
                            monthTo = 0
                        } else if monthTo == formatInfo.endMonth.month && year == formatInfo.endMonth.year {
                            monthTo = 13
                        }
                        
                        let monthPage = eachDayInfo.date.numberOfMonths(startDate);
                        if let page = doc.page(at: monthPage) {
                            dayPage?.addLinkAnnotation(bounds: dayRectsInfo.monthRect, goToPage:  page, at : atPoint)
                        }
                        
                        let weekPage = eachDayInfo.date.numberOfWeeks(weekcalStartDate) - 1;
                        if let page = doc.page(at: 1 + yearMonthsCount + weekPage) {
                            dayPage?.addLinkAnnotation(bounds: dayRectsInfo.weekRect, goToPage:  page, at : atPoint)
                        }
                        
                        dayPage?.addLinkAnnotation(bounds: dayRectsInfo.yearRect, goToPage: (doc.page(at: 0))!, at : atPoint)
                        
                        pageIndex += 1
                        dayRectsCount += 1
                    }
                }
            }
        }
}
