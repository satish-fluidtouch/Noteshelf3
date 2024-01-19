//
//  FTDairyFormat1Port.swift
//  Template Generator
//
//  Created by Amar on 18/11/19.
//  Copyright © 2019 Amar. All rights reserved.
//

import UIKit
import PDFKit

class FTDairyFormat : NSObject, FTDairyRenderTemplate, FTDairyRenderFormat , FTDiaryPageRenderer
{
    var calendarRectsInfo : FTDiaryCalendarRectInfo = FTDiaryCalendarRectInfo();
    var yearRectsInfo: FTDiaryYearRectsInfo = FTDiaryYearRectsInfo();
    var monthRectsInfo: [FTDiaryMonthRectsInfo] = [];
    var weekRectsInfo: [FTDiaryWeekRectsInfo] = [];
    var dayRectsInfo: [FTDiaryDayRectsInfo] = [];
    var weekPrioritiesInfo : FTDiaryWeeklyPrioritiesRectInfo =  FTDiaryWeeklyPrioritiesRectInfo()
    var weekNotesInfo : FTDiaryWeeklyNotesRectInfo = FTDiaryWeeklyNotesRectInfo()
    var dailyPrioritiesInfo : FTDiaryDailyPrioritiesRectInfo =  FTDiaryDailyPrioritiesRectInfo()
    var dailyNotesInfo : FTDiaryDailyNotesRectInfo = FTDiaryDailyNotesRectInfo()
    var screenInfo: FTScreenInfo!
    var formatInfo:FTYearFormatInfo = FTYearFormatInfo.init(year: 2020)
    var currentPageRect: CGRect = CGRect.init(x: 0, y: 0, width: 768, height: 960);
    var quoteProvider: FTQuotesProvider = FTQuotesProvider()
    var offsetCount: Int = 76
    var diaryPagesInfo: [FTDiaryPageInfo] = []
    
    private var orientationTail : String {
        return formatInfo.orientation == FTScreenOrientation.Port.rawValue ? "" : "-land"
    }
    
    private var assetsFolder : String {
        if(useTestTemplates) {
            return "assets/" + formatInfo.templateId.rawValue + "/" + formatInfo.screenSize + "/" + formatInfo.orientation + "/test"
        }
        return "assets/" + formatInfo.templateId.rawValue + "/" + formatInfo.screenSize + "/" + formatInfo.orientation;
    }
    
    var dayTemplate: String {
        if let path = Bundle.main.path(forResource: "day" + orientationTail, ofType: "pdf", inDirectory: self.assetsFolder) {
                return path;
        }
        fatalError("file missing"+self.assetsFolder);
    }
    
    var weekTemplate: String {
        if let path = Bundle.main.path(forResource: "weekly2" + orientationTail, ofType: "pdf", inDirectory: self.assetsFolder) {
                return path;
            }
        fatalError("file missing");
    }
    
    var monthTemplate: String {
        if let path = Bundle.main.path(forResource: "month" + orientationTail, ofType: "pdf", inDirectory: self.assetsFolder) {
            return path;
        }
        fatalError("file missing");
    }
    
    var yearTemplate: String {
        if let path = Bundle.main.path(forResource: "year" + orientationTail, ofType: "pdf", inDirectory: self.assetsFolder) {
            return path;
        }
        fatalError("file missing");
    }
    
    var metaDataPath: URL {
        if let fileURL = Bundle.main.url(forResource: formatInfo.templateId.rawValue, withExtension: "plist", subdirectory: "assets/" + formatInfo.templateId.rawValue) {
            return fileURL
        }
        fatalError("file missing");
    }
    var calendarPageYear : String {
        var curYear = String(formatInfo.startMonth.year);
        if formatInfo.startMonth.year == formatInfo.endMonth.year - 1 {
            let endYear:NSString = NSString.init(string: String(formatInfo.endMonth.year))
            curYear = String(formatInfo.startMonth.year)  + "-" + endYear.substring(from: 2)
        }
        return curYear
    }
    
    func isToDisplayOutOfMonthDate() -> Bool {
        let metaData = NSDictionary.init(contentsOf: self.metaDataPath) as! [String: Any]
        return metaData["isToDisplayOutOfMonthDate"] as! Bool
    }
    
    func pageRect() -> CGRect {
        let templatePath = self.yearTemplate;
        let pdfDocument = PDFDocument.init(url: URL(fileURLWithPath: templatePath));
        
        let pdfPage = pdfDocument!.page(at: 0);
        let cgPDFPage = pdfPage?.pageRef
        currentPageRect = cgPDFPage!.getBoxRect(CGPDFBox.cropBox);
        return currentPageRect
    }
    func getTemplateBackgroundColor() -> UIColor{
        return UIColor(hexString: "#FFFFFF")
    }
    func generateCalendar(context : CGContext, monthlyFormatter : FTYearInfoMonthly, weeklyFormatter : FTYearInfoWeekly){

        self.renderYearPage(context: context, months: monthlyFormatter.monthInfo, calendarYear: formatInfo);

        let calendarMonths = monthlyFormatter.monthCalendarInfo;
        calendarMonths.forEach { (calendarMonth) in
            self.renderMonthPage(context: context, monthInfo: calendarMonth, calendarYear: formatInfo)
        }
        
        let weeklyInfo = weeklyFormatter.weeklyInfo;
        weeklyInfo.forEach { (weekInfo) in
            self.renderWeekPage(context: context, weeklyInfo: weekInfo)
        }
        
        let monthInfo = monthlyFormatter.monthCalendarInfo;
        monthInfo.forEach { (eachMonth) in
            let dayInfo = eachMonth.dayInfo;
            dayInfo.forEach { (eachDayInfo) in
                self.renderDayPage(context: context, dayInfo: eachDayInfo);
            }
        }
    }
    func addCalendarLinks(url : URL,format : FTDairyFormat,pageRect: CGRect, calenderYear: FTYearFormatInfo, isToDisplayOutOfMonthDate: Bool, monthlyFormatter : FTYearInfoMonthly, weeklyFormatter : FTYearInfoWeekly) {
        let doc = PDFDocument.init(url: url);
        var pageIndex: Int = 0;
        var nextIndex:Int = 0;
        let offset = 0;
        let atPoint:CGPoint = CGPoint(x: 0, y: pageRect.height)
        let calendar = NSCalendar.gregorian()
        let startDate = calendar.date(month: calenderYear.startMonth.month, year: calenderYear.startMonth.year)!
        let endFirstDate = calendar.date(month: calenderYear.endMonth.month, year: calenderYear.endMonth.year)!
        let endDate = endFirstDate.offsetDate(endFirstDate.numberOfDaysInMonth() - 1)
        
        //Linking the year page
        nextIndex = 1
        let yearPage = doc?.page(at: pageIndex);
        var yearMonthsCount = 0
        for monthRect in format.yearRectsInfo.monthRects{
            if let page = (doc?.page(at: yearMonthsCount + nextIndex + offset)) {
                //yearPage?.addLinkAnnotation(bounds: monthRect, goToPage: page, at: atPoint)
            }
            yearMonthsCount += 1
        }
        pageIndex += 1
        
        //Linking the month pages
        //pageIndex = linkMonthPages(doc: doc!, index: pageIndex, format: format, isToDisplayOutOfMonthDate: isToDisplayOutOfMonthDate,
                                   //startDate: startDate, endDate: endDate, atPoint: atPoint,monthlyFormatter : monthlyFormatter)
        
        //Linking the week pages
        //pageIndex = linkWeekPages(_nextIndex: nextIndex, yearMonthsCount: yearMonthsCount, index: pageIndex, doc: doc!, format: format,
                                  //startDate: startDate, endDate: endDate, atPoint: atPoint, weeklyFormatter: weeklyFormatter)
        
        //Linking the day pages
        //linkDayPages(doc: doc!, startDate: startDate, index: pageIndex, format: format, atPoint: atPoint, yearMonthsCount: yearMonthsCount,monthlyFormatter: monthlyFormatter)
        
        doc?.write(to: url);
    }
    func calendarOffsetCount() -> Int {
        return self.offsetCount
    }
    func renderYearPage(context: CGContext,months : [FTMonthInfo],calendarYear : FTYearFormatInfo) {
        UIGraphicsBeginPDFPage();
        let pageRect = UIGraphicsGetPDFContextBounds();
        let templatePath = self.yearTemplate;
        let pdfDocument = PDFDocument.init(url: URL(fileURLWithPath: templatePath));
        let pdfPage = pdfDocument!.page(at: 0);
        context.saveGState();
        context.translateBy(x: 0, y: pageRect.size.height);
        context.scaleBy(x: 1, y: -1);
        pdfPage?.transform(context, for: .cropBox);
        pdfPage?.draw(with: .cropBox, to: context);
        context.restoreGState();
    }
    
    func renderMonthPage(context : CGContext,monthInfo : FTMonthlyCalendarInfo, calendarYear: FTYearFormatInfo) {
        UIGraphicsBeginPDFPage();
        let pageRect = UIGraphicsGetPDFContextBounds();
        let templatePath = self.monthTemplate;
        let pdfDocument = PDFDocument.init(url: URL(fileURLWithPath: templatePath));
        let pdfPage = pdfDocument!.page(at: 0);
        
        context.saveGState();
        context.translateBy(x: 0, y: pageRect.size.height);
        context.scaleBy(x: 1, y: -1);
        pdfPage?.transform(context, for: .cropBox);
        pdfPage?.draw(with: .cropBox, to: context);
        context.restoreGState();
    }
    
    func renderWeekPage(context : CGContext,weeklyInfo : FTWeekInfo) {
        UIGraphicsBeginPDFPage();
        let pageRect = UIGraphicsGetPDFContextBounds();
        let templatePath = self.weekTemplate;
        let pdfDocument = PDFDocument.init(url: URL(fileURLWithPath: templatePath));
        let pdfPage = pdfDocument!.page(at: 0);
        
        context.saveGState();
        context.translateBy(x: 0, y: pageRect.size.height);
        context.scaleBy(x: 1, y: -1);
        pdfPage?.transform(context, for: .cropBox);
        pdfPage?.draw(with: .cropBox, to: context);
        context.restoreGState();
    }
    
    func renderDayPage(context : CGContext,dayInfo : FTDayInfo) {
        UIGraphicsBeginPDFPage();
        let pageRect = UIGraphicsGetPDFContextBounds();
        
        let templatePath = self.dayTemplate;
        let pdfDocument = PDFDocument.init(url: URL(fileURLWithPath: templatePath));
        let pdfPage = pdfDocument!.page(at: 0);
        
        context.saveGState();
        context.translateBy(x: 0, y: pageRect.size.height);
        context.scaleBy(x: 1, y: -1);
        pdfPage?.transform(context, for: .cropBox);
        pdfPage?.draw(with: .cropBox, to: context);
        context.restoreGState();
    }
    
    func isBelongToCalendarYear(month: FTMonthInfo) -> Bool{
        return !((formatInfo.startMonth.month == month.month && formatInfo.startMonth.year == month.year)
            || (formatInfo.endMonth.month == month.month && formatInfo.endMonth.year == month.year))
    }
    
    func isBelongToCalendarYear(day: FTDayInfo) -> Bool{
        return !((formatInfo.startMonth.month == day.month && formatInfo.startMonth.year == day.year)
            || (formatInfo.endMonth.month == day.month && formatInfo.endMonth.year == day.year))
    }
    
    func isBelongToCalendarYear(currentDate: Date) -> Bool{
        let calendar = NSCalendar.gregorian()
        let startDate = calendar.date(month: formatInfo.startMonth.month, year: formatInfo.startMonth.year)!
        let endFirstDate = calendar.date(month: formatInfo.endMonth.month, year: formatInfo.endMonth.year)!
        let endDate = endFirstDate.offsetDate(endFirstDate.numberOfDaysInMonth() - 1)
        return (currentDate.compare(startDate) == ComparisonResult.orderedSame ||
            currentDate.compare(startDate) == ComparisonResult.orderedDescending)
            && (currentDate.compare(endDate) == ComparisonResult.orderedSame ||
                currentDate.compare(endDate) == ComparisonResult.orderedAscending)
    }
    
    func getLinkRect(location at: CGPoint, frameSize: CGSize) -> CGRect {
        return CGRect(x: at.x, y:currentPageRect.height - at.y - frameSize.height, width: frameSize.width, height: frameSize.height)
    }
    
    func getYearCellWidth(columnCount: CGFloat) -> CGFloat {
        let templateInfo = screenInfo.spacesInfo.yearPageSpacesInfo
        return (currentPageRect.size.width - (2 * templateInfo.baseBoxX) - ((columnCount - 1) * templateInfo.cellOffsetX))/columnCount
    }
    
    func getYearCellHeight(rowCount: CGFloat) -> CGFloat {
        let templateInfo = screenInfo.spacesInfo.yearPageSpacesInfo
        return (currentPageRect.size.height - templateInfo.baseBoxY - templateInfo.boxBottomOffset - ((rowCount - 1) * templateInfo.cellOffsetY))/rowCount
    }
    
    func getWeekSymbols(monthInfo: FTMonthlyCalendarInfo) -> [String]{
        let dateFormatter = DateFormatter.init();
        dateFormatter.locale = Locale.init(identifier: monthInfo.localeID);
        var symbols = dateFormatter.veryShortWeekdaySymbols;
        
        if formatInfo.weekFormat.elementsEqual("2"){
            let first = symbols?[0]
            symbols?.remove(at: 0)
            symbols?.append((first)!)
        }
        return symbols!
    }
    func getWeekDayNames(monthInfo: FTMonthlyCalendarInfo) -> [String]{
        let dateFormatter = DateFormatter.init();
        dateFormatter.locale = Locale.init(identifier: monthInfo.localeID);
        var symbols = dateFormatter.shortStandaloneWeekdaySymbols;
        
        if formatInfo.weekFormat.elementsEqual("2"){
            let first = symbols?[0]
            symbols?.remove(at: 0)
            symbols?.append((first)!)
        }
        return symbols!
    }
    
    func getColumnCount() -> CGFloat {
        if formatInfo.screenType == FTScreenType.Ipad {
            return formatInfo.orientation == FTScreenOrientation.Port.rawValue ? 3 : 4
        } else {
            return formatInfo.orientation == FTScreenOrientation.Port.rawValue ? 3 : 4
        }
    }
    
    func getRowCount() -> CGFloat {
        if formatInfo.screenType == FTScreenType.Ipad {
            return formatInfo.orientation == FTScreenOrientation.Port.rawValue ? 4 : 3
        } else {
            return formatInfo.orientation == FTScreenOrientation.Port.rawValue ? 4 : 3
        }
    }
    
    var rootPath: URL {
        return NSURL.fileURL(withPath: NSTemporaryDirectory())
    }
    
    private func linkMonthPages(doc: PDFDocument, index: Int, format: FTDairyFormat, isToDisplayOutOfMonthDate: Bool,
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
        
        calendarMonths.forEach { (eachMonth) in
            let monthPage = doc.page(at: pageIndex);
            let monthRectsInfo = format.monthRectsInfo[monthRectsCount]
            monthPage?.addLinkAnnotation(bounds: monthRectsInfo.yearRect, goToPage: (doc.page(at: 0))!, at : atPoint)
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
    
    private func linkWeekPages(_nextIndex: Int, yearMonthsCount: Int, index: Int, doc: PDFDocument, format:FTDairyFormat,
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
    
    private func linkDayPages(doc: PDFDocument, startDate: Date, index: Int, format: FTDairyFormat, atPoint: CGPoint, yearMonthsCount: Int,monthlyFormatter : FTYearInfoMonthly) {
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
    func isBelongToCalendar(currentDate: Date, startDate: Date, endDate: Date) -> Bool{
        return (currentDate.compare(startDate) == ComparisonResult.orderedSame ||
            currentDate.compare(startDate) == ComparisonResult.orderedDescending)
            && (currentDate.compare(endDate) == ComparisonResult.orderedSame ||
                currentDate.compare(endDate) == ComparisonResult.orderedAscending)
    }
    func drawColorBandsWith(xAxis : CGFloat, yAxis : CGFloat, context : CGContext, width : CGFloat,height: CGFloat, bandColor : UIColor, cornerRadius: CGFloat){
        let monthBandRect = CGRect(x: xAxis , y: yAxis , width: width , height: height)
        let bezierRect = UIBezierPath(roundedRect: monthBandRect, cornerRadius: cornerRadius)
        context.addPath(bezierRect.cgPath)
        context.setFillColor(bandColor.cgColor)
        context.fillPath()
    }
    func layoutRequiresExplicitFont() -> Bool {
        if self.formatInfo.customVariants.selectedDevice.identifier == "standard4" ||
            self.formatInfo.customVariants.selectedDevice.identifier == "standard2" ||
            self.formatInfo.customVariants.selectedDevice.identifier == "standard1"{
           return true
        }
        return false
    }
    func setDiaryPageAsCurrentPage(pageDate date: Date) -> Bool {
        if let currentDate = Date().utcDate() {
            if date.compareDate(currentDate) == ComparisonResult.orderedSame {
                return true
            }
        }
        return false
    }
}

@objc extension FTDairyFormat
{
    func renderYearPageTitle(monthInfo: FTMonthlyCalendarInfo) {
    }
    
    func renderMonthTitle(monthInfo: FTMonthlyCalendarInfo) {
    }
    
    func render(dayInfo : [FTDayInfo],calendarYear: FTYearFormatInfo){
    }
}

extension FTDairyFormat {
    static func getFormat(formatInfo: FTYearFormatInfo) -> FTDairyFormat{
        var format: FTDairyFormat = FTDairyFormat()
        switch formatInfo.templateId {
        case .digitalDiariesClassic :
            format = FTClassicDiaryFormat.getFormatBasedOn(variants: formatInfo.customVariants)
            if let classicDiaryFormat = format as? FTClassicDiaryFormat {
                formatInfo.screenType = classicDiaryFormat.isiPad ? FTScreenType.Ipad : FTScreenType.Iphone
                formatInfo.screenSize = formatInfo.screenType.rawValue
            }
        case .digitalDiariesModern :
            format = FTModernDiaryFormat.getFormatBasedOn(variants: formatInfo.customVariants)
            if let modernDiaryFormat = format as? FTModernDiaryFormat {
                formatInfo.screenType = modernDiaryFormat.isiPad ? FTScreenType.Ipad : FTScreenType.Iphone
                formatInfo.screenSize = formatInfo.screenType.rawValue
            }
        case .digitalDiariesMidnight :
            format = FTMidnightDairyFormat.getFormatBasedOn(variants: formatInfo.customVariants)
            if let MidnightFormat = format as? FTMidnightDairyFormat {
                formatInfo.screenType = MidnightFormat.isiPad ? FTScreenType.Ipad : FTScreenType.Iphone
                formatInfo.screenSize = formatInfo.screenType.rawValue
            }
        case .digitalDiariesDayandNightJournal :
            format = FTFiveMinJournalFormat.getFormatBasedOn(variants: formatInfo.customVariants)
            if let fiveMinJournalFormat = format as? FTFiveMinJournalFormat {
                formatInfo.screenType = fiveMinJournalFormat.isiPad ? FTScreenType.Ipad : FTScreenType.Iphone
                formatInfo.screenSize = formatInfo.screenType.rawValue
                formatInfo.supportsForAllLocales = false
            }
        case .digitalDiariesColorfulPlanner :
            format = FTPlannerDiaryFormat.getFormatBasedOn(variants: formatInfo.customVariants)
            if let plannerDiayFormat = format as? FTPlannerDiaryFormat {
                formatInfo.screenType = plannerDiayFormat.isiPad ? FTScreenType.Ipad : FTScreenType.Iphone
                formatInfo.screenSize = formatInfo.screenType.rawValue
                formatInfo.supportsForAllLocales = false
            }
        case .landscapeDiariesColorfulPlanner :
            format = FTPlanner2024DiaryFormat.getFormatBasedOn(variants: formatInfo.customVariants)
            if let plannerDiayFormat = format as? FTPlanner2024DiaryFormat {
                formatInfo.screenType = plannerDiayFormat.isiPad ? FTScreenType.Ipad : FTScreenType.Iphone
                formatInfo.screenSize = formatInfo.screenType.rawValue
                formatInfo.supportsForAllLocales = false
            }
        case .digitalDiariesColorfulPlannerDark :
            format = FTPlannerDiaryFormat.getFormatBasedOn(variants: formatInfo.customVariants,isDarkTemplate: true)
            if let plannerDiayFormat = format as? FTPlannerDiaryFormat {
                formatInfo.screenType = plannerDiayFormat.isiPad ? FTScreenType.Ipad : FTScreenType.Iphone
                formatInfo.screenSize = formatInfo.screenType.rawValue
                formatInfo.supportsForAllLocales = false
            }
        default:
            format = FTDiaryFormat2019()
        }
        
        format.formatInfo = formatInfo
        format.screenInfo = FTScreenInfo.init(formatInfo: formatInfo)
        return format
    }
}

extension NSAttributedString {
    func requiredSizeForAttributedStringConStraint(to size: CGSize) -> CGSize {
        let textContainer = NSTextContainer(size: size)
        textContainer.lineFragmentPadding = 0
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        let textStorage = NSTextStorage(attributedString: self)
        textStorage.addLayoutManager(layoutManager)
        let bounds = layoutManager.usedRect(for: textContainer)
        return bounds.size
    }
}
// MARK: Today Pill
extension FTDairyFormat {
    func addTodayLink(toContext context : CGContext,
                              withRect rect : CGRect,
                              withFont font : UIFont,
                              withTextColor textColor: UIColor,
                              WithBackgroundColor backgroundColor: UIColor){

        let todayPillHorizontalPaddingPercnt: CGFloat = 0.35
        let todayLinkRectX = rect.origin.x
        let todayLinkRectY = rect.origin.y
        let todayLinkRectHeight = rect.height


        let todayPillHorizontalPadding = self.currentPageRect.width*todayPillHorizontalPaddingPercnt/100

        var todayFont = font
        var todayRectCornerRadius : CGFloat = 3
        if self.layoutRequiresExplicitFont(){
            todayFont = font.withSize(7)
            todayRectCornerRadius = 2
        }

        let todayAttrs: [NSAttributedString.Key: Any] = [.font: todayFont,
                                                        .kern: 1.6,
                                                        .foregroundColor: textColor]
        let todayString = NSAttributedString.init(string: "TODAY",attributes: todayAttrs)

        let todayPillRect = CGRect(x: todayLinkRectX, y: todayLinkRectY, width: todayString.size().width + todayPillHorizontalPadding*2, height: todayLinkRectHeight)

        self.drawColorBandsWith(xAxis: todayPillRect.origin.x, yAxis: todayPillRect.origin.y, context: context, width: todayPillRect.width, height: todayPillRect.height, bandColor: backgroundColor, cornerRadius: todayRectCornerRadius)

        let todayRect = CGRect(x: todayPillRect.origin.x + (todayPillRect.width - todayString.size().width)/2 , y: todayLinkRectY + (todayPillRect.height - todayString.size().height)/2, width: todayString.size().width, height: todayString.size().height)
        todayString.draw(at:CGPoint(x: todayRect.origin.x + 1, y: todayRect.origin.y + 0.5))


        let todayLinkRect = getLinkRect(location: CGPoint(x:todayPillRect.origin.x - 3, y: todayPillRect.origin.y - 3), frameSize:CGSize(width: todayPillRect.width + 6 , height: todayPillRect.height + 6))
        let urlString = FTSharedGroupID.getAppGroupID() + "://todayLink"
        if let todayURL = URL(string: urlString){
            UIGraphicsSetPDFContextURLForRect(todayURL, todayLinkRect)
        }
    }
}
