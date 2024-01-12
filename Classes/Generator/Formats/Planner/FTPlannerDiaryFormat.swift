//
//  FTPlannerDiaryFormat.swift
//  Noteshelf
//
//  Created by Ramakrishna on 09/11/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import PDFKit

class FTPlannerDiaryFormat : FTDairyFormat {
    //*********** Normal Planner colors ***********//
    let textTintColor: UIColor = UIColor(hexString: "#363636")
    let monthStripColors : [String: String] = ["JANUARY" :"#AAEBF1","FEBRUARY":"#C4F2E7","MARCH":"#F3E3B5","APRIL":"#F0CBC2","MAY":"#F1C7EA","JUNE":"#DDC3F2","JULY":"#AAEBF1","AUGUST":"#C4F2E7","SEPTEMBER":"#F3E3B5","OCTOBER":"#F0CBC2","NOVEMBER":"#F1C7EA","DECEMBER":"#DDC3F2"]
    let sideStripMonthColorsDict : [String: String] = ["jan" :"#AAEBF1","feb":"#C4F2E7","mar":"#F3E3B5","apr":"#F0CBC2","may":"#F1C7EA","jun":"#DDC3F2","jul":"#AAEBF1","aug":"#C4F2E7","sep":"#F3E3B5","oct":"#F0CBC2","nov":"#F1C7EA","dec":"#DDC3F2"]
    let calendarStripColor = UIColor(hexString: "#E7E7E7")
    let stripHighlightColor = UIColor(hexString: "#FFFFFF")
    let pageNumberHighlightBGColor = UIColor(hexString: "#AAEBF1")
    let weekNumberStripColors : [Int: String] = [1 :"#AAEBF1",2:"#C4F2E7",3:"#F3E3B5",4:"#F0CBC2",5:"#F1C7EA",6:"#DDC3F2"]
    let weekDaysPastalColors = ["#AAEBF1","#C4F2E7","#F3E3B5","#F0CBC2","#F1C7EA","#DDC3F2","#AAEBF1","#C4F2E7"]
    let notesBandBGColor = UIColor(hexString: "#E7E7E7")
    //**************************************************//


    //*********** Dark Planner colors ***********//
    let darkPlannerTextTintColor: UIColor = UIColor(hexString: "#FEFEF5")
    let darkPlannerMonthStripColors : [String: String] = ["JANUARY" :"#6EB8BF","FEBRUARY":"#45B298","MARCH":"#BAA15C","APRIL":"#B27D6F","MAY":"#BD7AB2","JUNE":"#A889C2","JULY":"#6EB8BF","AUGUST":"#45B298","SEPTEMBER":"#BAA15C","OCTOBER":"#B27D6F","NOVEMBER":"#BD7AB2","DECEMBER":"#A889C2"]
    let darkPlannerSideStripMonthColorsDict : [String: String] = ["jan" :"#6EB8BF","feb":"#45B298","mar":"#BAA15C","apr":"#B27D6F","may":"#BD7AB2","jun":"#A889C2","jul":"#6EB8BF","aug":"#45B298","sep":"#BAA15C","oct":"#B27D6F","nov":"#BD7AB2","dec":"#A889C2"]
    let darkPlannerCalendarStripColor = UIColor(hexString: "#504F4F")
    let darkplannerStripHighlightColor = UIColor(hexString: "#131313")
    let darkPlannerPageNumberHighlightBGColor = UIColor(hexString: "#6EB8BF")
    let darkPlannerWeekNumberStripColors : [Int: String] = [1 :"#6EB8BF",2:"#45B298",3:"#BAA15C",4:"#B27D6F",5:"#BD7AB2",6:"#A889C2"]
    let darkPlannerWeekDaysPastalColors = ["#6EB8BF","#45B298","#BAA15C","#B27D6F","#BD7AB2","#A889C2","#6EB8BF","#45B298"]
    let darkPlannerNotesBandBGColor = UIColor(hexString: "#504F4F")
    //**************************************************//


    var customVariants : FTPaperVariants
    var weekNumbers : [FTPlannerWeekNumber] = []
    var currentYearRectInfo : FTDiaryYearRectsInfo = FTDiaryYearRectsInfo()
    var currentWeekRectInfo: FTDiaryWeekRectsInfo = FTDiaryWeekRectsInfo()
    var currentDayRectsInfo: FTDiaryDayRectsInfo = FTDiaryDayRectsInfo()
    var currentMonthRectsInfo: FTDiaryMonthRectsInfo = FTDiaryMonthRectsInfo()
    var plannerDiarySideNavigationRectsInfo : FTPlannerDiarySideNavigationRectInfo = FTPlannerDiarySideNavigationRectInfo();
    var plannerDiaryTopNavigationRectsInfo : FTPlannerDiaryTopNavigationRectInfo = FTPlannerDiaryTopNavigationRectInfo();
    var plannerDiaryExtrasTabRectsInfo : FTPlannerDiaryExtrasTabRectInfo =  FTPlannerDiaryExtrasTabRectInfo();
    var renderFirstWeek : Bool = true
    var monthCalendarInfo = [FTMonthlyCalendarInfo]()
    var isDarkTemplate: Bool = false
    required init(customVariants : FTPaperVariants, isDarkTemplate:Bool = false){
        self.customVariants = customVariants
        self.isDarkTemplate = isDarkTemplate
        super.init()
    }

    var isiPad : Bool {
        return true
    }
    override var yearTemplate: String {
        return getPlannerAssetPDFPath(ofType: FTPlannerDiaryTemplateType.year, customVariants: formatInfo.customVariants)
    }

    var _monthPagePDFDocument: PDFDocument?;
    var monthPagePDFDocument: PDFDocument? {
        get {
            if(nil == _monthPagePDFDocument) {
                let path = self.monthTemplate;
                _monthPagePDFDocument = PDFDocument(url: URL(fileURLWithPath: path));
            }
            return _monthPagePDFDocument
        }
    }
    
    override var monthTemplate: String {
        return getPlannerAssetPDFPath(ofType: FTPlannerDiaryTemplateType.month, customVariants: formatInfo.customVariants)
    }

    var _weekPagePDFDocument: PDFDocument?;
    var weekPagePDFDocument: PDFDocument? {
        get {
            if(nil == _weekPagePDFDocument) {
                let path = self.weekTemplate;
                _weekPagePDFDocument = PDFDocument.init(url: URL(fileURLWithPath: path));
            }
            return _weekPagePDFDocument
        }
    }

    override var weekTemplate: String {
        return getPlannerAssetPDFPath(ofType: FTPlannerDiaryTemplateType.week, customVariants: formatInfo.customVariants)
    }
    
    var _dayPagePDFDocument: PDFDocument?;
    var dayPagePDFDocument: PDFDocument? {
        get {
            if(nil == _dayPagePDFDocument) {
                let path = self.dayTemplate;
                _dayPagePDFDocument = PDFDocument.init(url: URL(fileURLWithPath: path));
            }
            return _dayPagePDFDocument
        }
    }
    
    override var dayTemplate: String {
        let templateType : FTPlannerDiaryTemplateType = .day
        let path = getPlannerAssetPDFPath(ofType: templateType, customVariants: formatInfo.customVariants);
        return path;
    }
    
    var calendarTemplate : String {
        return getPlannerAssetPDFPath(ofType: FTPlannerDiaryTemplateType.calendar,customVariants: formatInfo.customVariants)
    }
    var _notesPagePDFDocument: PDFDocument?;
    var notesPagePDFDocument: PDFDocument? {
        get {
            if(nil == _notesPagePDFDocument) {
                let path = self.notesTemplate;
                _notesPagePDFDocument = PDFDocument.init(url: URL(fileURLWithPath: path));
            }
            return _notesPagePDFDocument
        }
    }
    var notesTemplate : String {
        return getPlannerAssetPDFPath(ofType: FTPlannerDiaryTemplateType.notes,customVariants: formatInfo.customVariants)
    }
    var _trackerPagePDFDocument: PDFDocument?;
    var trackerPagePDFDocument: PDFDocument? {
        get {
            if(nil == _trackerPagePDFDocument) {
                let path = self.trackerTemplate;
                _trackerPagePDFDocument = PDFDocument.init(url: URL(fileURLWithPath: path));
            }
            return _trackerPagePDFDocument
        }
    }
    var trackerTemplate : String {
        return getPlannerAssetPDFPath(ofType: FTPlannerDiaryTemplateType.tracker,customVariants: formatInfo.customVariants)
    }
    var extrasTemplate : String {
        return getPlannerAssetPDFPath(ofType: FTPlannerDiaryTemplateType.extras,customVariants: formatInfo.customVariants)
    }
    
    override func getTemplateBackgroundColor() -> UIColor {
        if isDarkTemplate {
            return UIColor(hexString: "#131313")
        }else {
            return UIColor(red: 254/255, green: 254/255, blue: 254/255, alpha: 1.0)
        }
    }

    func getPlannerAssetPDFPath(ofType type : FTPlannerDiaryTemplateType, customVariants variants: FTPaperVariants) -> String {
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
        let screenSize = FTModernDiaryFormat.getScreenSize(fromVariants: customVariants)
        let displayName = isDarkTemplate ? type.displayName + "(Dark)" : type.displayName
        let key = displayName + "_" + screenType + "_" + orientation +  "_" + "\(screenSize.width)" + "_"
            + "\(screenSize.height)"
        let pdfURL = self.rootPath.appendingPathComponent(key).appendingPathExtension("pdf")
        if FileManager().fileExists(atPath: pdfURL.path) , let data = try? Data(contentsOf: pdfURL), !data.isEmpty {
            return pdfURL.path
        } else {
            let templateDiaryInfo = FTPlannerDiaryTemplateInfo(templateType: type,customVariants: customVariants,isDarkTemplate: isDarkTemplate)
            let generator = FTPlannerDiaryTemplateAssetGenerator(templateInfo: templateDiaryInfo)
            let generatedPDFURL = generator.generate()
            return generatedPDFURL.path
        }
    }

    class func getFormatBasedOn(variants: FTPaperVariants, isDarkTemplate: Bool = false) -> FTPlannerDiaryFormat {
        if !variants.selectedDevice.isiPad {
            return FTPlannerDiaryiPhoneFormat(customVariants: variants,isDarkTemplate: isDarkTemplate)
        }
        return  FTPlannerDiaryiPadFormat(customVariants: variants,isDarkTemplate: isDarkTemplate)
    }

    class func getScreenSize(fromVariants variants: FTPaperVariants) -> CGSize {
        let dimension = variants.isLandscape ? variants.selectedDevice.dimension_land : variants.selectedDevice.dimension_port
        let measurements = dimension.split(separator: "_")
        return CGSize(width: Int(measurements[0])!, height: Int(Double(measurements[1])!))
    }
    override func getYearCellHeight(rowCount: CGFloat) -> CGFloat {
        let templateInfo = screenInfo.spacesInfo.calendarSpacesInfo
        return (currentPageRect.size.height - (currentPageRect.size.height*templateInfo.baseBoxY/100) - (currentPageRect.size.height*templateInfo.boxBottomOffset/100) - ((rowCount - 1) * (currentPageRect.size.height*templateInfo.cellOffsetY/100)))/rowCount
    }
    override func getYearCellWidth(columnCount: CGFloat) -> CGFloat {
        let templateInfo = screenInfo.spacesInfo.calendarSpacesInfo
        let stripWidthPercnt = formatInfo.customVariants.isLandscape ? 3.59 : 4.67
        let stripWidth = currentPageRect.size.width*stripWidthPercnt/100
        let currentpageWidth = currentPageRect.width - stripWidth - (7*0.5)
        return ((currentpageWidth - (2 * (currentpageWidth*templateInfo.baseBoxX/100)) - ((columnCount - 1) * (currentpageWidth*templateInfo.cellOffsetX/100)))/columnCount)
    }
    override func calendarOffsetCount() -> Int {
        return self.offsetCount
    }
    func renderCalendarPage(context : CGContext,months : [FTMonthlyCalendarInfo],calendarYear : FTYearFormatInfo){
        
    }
    func renderNotesPage(context : CGContext,monthInfo: FTMonthlyCalendarInfo){
        
    }
    func renderTrackerPage(context: CGContext, monthInfo: FTMonthlyCalendarInfo, calendarYear: FTYearFormatInfo){
        
    }
    func renderExtrasPage(atIndex index : Int,context: CGContext){
        
    }
    func renderYearPage(atIndex index : Int,context: CGContext, months: [FTMonthInfo], calendarYear: FTYearFormatInfo){
        
    }
    func renderWeekPage(context: CGContext, weeklyInfo: FTWeekInfo,monthInfo: FTMonthlyCalendarInfo) {
        
    }
    func renderDayPage(context: CGContext, dayInfo: FTDayInfo,monthInfo: FTMonthlyCalendarInfo){
        
    }
    
    func renderPlannerDiaryPDF(context: CGContext, pdfTemplatePath path:String,pdfTemplate: PDFDocument?){
        UIGraphicsBeginPDFPage();
        let pageRect = UIGraphicsGetPDFContextBounds();
        
        let templatePath = path;
        var pdfDocument = pdfTemplate;
        if(nil == pdfDocument) {
            pdfDocument = PDFDocument.init(url: URL(fileURLWithPath: templatePath));
        }
        let pdfPage = pdfDocument!.page(at: 0);
        
        context.saveGState();
        context.translateBy(x: 0, y: pageRect.size.height);
        context.scaleBy(x: 1, y: -1);
        pdfPage?.transform(context, for: .cropBox);
        pdfPage?.draw(with: .cropBox, to: context);
        context.restoreGState();
    }

    //MARK:- PDF Generation and linking between pages
    override func generateCalendar(context : CGContext, monthlyFormatter : FTYearInfoMonthly, weeklyFormatter : FTYearInfoWeekly) {
    
        self.monthCalendarInfo = monthlyFormatter.monthCalendarInfo
        // Render Calendar page
        
        self.renderCalendarPage(context: context, months: monthlyFormatter.monthCalendarInfo, calendarYear: self.formatInfo)
        self.diaryPagesInfo.append(FTDiaryPageInfo(type: .calendar))
        
        // Render year page
        let numberOfYearPages : Int = self.formatInfo.customVariants.isLandscape ? 3 : 2
        for index in 1...numberOfYearPages {
            self.renderYearPage(atIndex: index, context: context, months: monthlyFormatter.monthInfo, calendarYear: self.formatInfo)
            self.diaryPagesInfo.append(FTDiaryPageInfo(type: .year))
        }
        
        // Render Month Pages
        let calendarMonths = monthlyFormatter.monthCalendarInfo;
        calendarMonths.forEach { (calendarMonth) in
            self.renderMonthPage(context: context, monthInfo: calendarMonth, calendarYear: formatInfo)
            let utcDate = calendarMonth.dayInfo.first?.date.utcDate()
            if let utcDate {
                diaryPagesInfo.append(FTDiaryPageInfo(type : .month, date : utcDate.timeIntervalSinceReferenceDate))
            }
            let weeklyInfo = calendarMonth.weeklyInfo
            // for every calendar duration add extra week if required
            if renderFirstWeek {
                renderFirstWeek = false
                if shouldAddWeekOffsetToCalendarWith(firstDay: weeklyInfo.first?.dayInfo.first), let firstWeek = weeklyInfo.first{
                    self.renderWeekPage(context: context, weeklyInfo: firstWeek,monthInfo: calendarMonth)
                    if let utcDate = firstWeek.dayInfo.first?.date.utcDate() {
                        diaryPagesInfo.append(FTDiaryPageInfo(type : .week, date : utcDate.timeIntervalSinceReferenceDate))
                    }
                }
            }
            weeklyInfo.forEach { (weekInfo) in
                let firstDayOfMonth = weekInfo.dayInfo.first
                if firstDayOfMonth?.fullMonthString.uppercased() == calendarMonth.fullMonth.uppercased(){
                //if self.shouldAddWeekToMonth(firstDay: firstDayOfMonth, currentMonth: calendarMonth) {
                    self.renderWeekPage(context: context, weeklyInfo: weekInfo,monthInfo: calendarMonth)
                    if let utcDate = weekInfo.dayInfo.first?.date.utcDate() {
                        diaryPagesInfo.append(FTDiaryPageInfo(type : .week, date : utcDate.timeIntervalSinceReferenceDate))
                    }
                }
            }
            let dayInfo = calendarMonth.dayInfo;
            dayInfo.forEach { (eachDayInfo) in
                if eachDayInfo.belongsToSameMonth {
                    self.renderDayPage(context: context, dayInfo: eachDayInfo,monthInfo: calendarMonth);
                    //For Today link
                    if let utcDate = eachDayInfo.date.utcDate() {
                        diaryPagesInfo.append(FTDiaryPageInfo(type: .day,date: utcDate.timeIntervalSinceReferenceDate , isCurrentPage: self.setDiaryPageAsCurrentPage(pageDate: utcDate)))
                    }
                }
            }
            self.renderNotesPage(context: context,monthInfo: calendarMonth)
            self.renderTrackerPage(context: context, monthInfo: calendarMonth, calendarYear: formatInfo)
            if let utcDate {
                let timeInterval = utcDate.timeIntervalSinceReferenceDate
                diaryPagesInfo.append(FTDiaryPageInfo(type : .monthlyNotes, date : timeInterval))
                diaryPagesInfo.append(FTDiaryPageInfo(type : .tracker, date : timeInterval))
            }

        }
        
        // Render extras page
        for index in 1...3 {
            self.renderExtrasPage(atIndex : index,context: context)
            self.diaryPagesInfo.append(FTDiaryPageInfo(type: .extras))
        }
    }
    func shouldAddWeekOffsetToCalendarWith(firstDay : FTDayInfo?) -> Bool {
        return firstDay?.month != formatInfo.startMonth.month
    }
    func shouldAddWeekToMonth(firstDay : FTDayInfo?,currentMonth:FTMonthlyCalendarInfo) -> Bool{
        return firstDay?.fullMonthString.uppercased() == currentMonth.fullMonth.uppercased()
    }
    override func addCalendarLinks(url : URL,format : FTDairyFormat,pageRect: CGRect, calenderYear: FTYearFormatInfo, isToDisplayOutOfMonthDate: Bool,monthlyFormatter : FTYearInfoMonthly, weeklyFormatter : FTYearInfoWeekly) {
        let doc = PDFDocument.init(url: url);
        var pageIndex: Int = 0;
        var nextIndex:Int = 0;
        let offset = 0;
        let atPoint:CGPoint = CGPoint(x: 0, y: pageRect.height)
        let calendar = NSCalendar.gregorian()
        let startDate = calendar.date(month: calenderYear.startMonth.month, year: calenderYear.startMonth.year)!
        let endFirstDate = calendar.date(month: calenderYear.endMonth.month, year: calenderYear.endMonth.year)!
        let endDate = endFirstDate.offsetDate(endFirstDate.numberOfDaysInMonth() - 1)
        nextIndex = 1
        
        //Linking the calendar page
        
        pageIndex = self.linkCalendarPages(doc: doc!, index: pageIndex, format: format, startDate: startDate, endDate: endDate, atPoint: atPoint,monthlyFormatter: monthlyFormatter, weeklyFormatter: weeklyFormatter)
        
        //Linking the year page
        
        pageIndex = self.linkYearPages(doc: doc!, index: pageIndex, format: format,atPoint: atPoint, monthlyFormatter : monthlyFormatter)
        
        
//        Linking the month pages
        self.linkMonthPages(doc: doc!, index: pageIndex, format: format,
                                             startDate: startDate, endDate: endDate, atPoint: atPoint,monthlyFormatter: monthlyFormatter, weeklyFormatter: weeklyFormatter)
        
//        //Linking the week pages
        self.linkWeekPages(doc: doc!, format: format,startDate: startDate, endDate: endDate, atPoint: atPoint,weeklyFormatter: weeklyFormatter, monthlyFormatter: monthlyFormatter)

//        //Linking the day pages
        self.linkDayPages(doc: doc!, startDate: startDate, format: format, atPoint: atPoint,monthlyFormatter: monthlyFormatter)
        
        doc?.write(to: url);
    }
    private func linkSideNavigationStrips(doc: PDFDocument, atPoint: CGPoint, monthlyFormatter : FTYearInfoMonthly, forPageAtIndex pageIndex: Int){
        let calendarMonths = monthlyFormatter.monthCalendarInfo;
        let numberYearPages = self.formatInfo.customVariants.isLandscape ? 3 : 2
        let daysBeforeCount = 1 + numberYearPages
        var dayAndWeekPagesCount = 0
        let sideNavigationStripRects = self.plannerDiarySideNavigationRectsInfo
        let indexedPage = doc.page(at: pageIndex)
        
        //calendar Page linking
        if let page = doc.page(at: 0) {
            indexedPage?.addLinkAnnotation(bounds: sideNavigationStripRects.calendarRect, goToPage: page, at: atPoint)
        }
        
        // year Page linking
        
        if let page = doc.page(at: 1) {
            indexedPage?.addLinkAnnotation(bounds: sideNavigationStripRects.yearRect, goToPage: page, at: atPoint)
        }
        
        // month pages linking
        var addWeekOffset : Bool = true
        calendarMonths.forEach { (eachMonth) in
            let numberOfWeeksOfMonth = eachMonth.getWeeksCount()
            let numberOfDaysInMonth = eachMonth.dayInfo.filter({$0.belongsToSameMonth}).count
            if let page = doc.page(at: dayAndWeekPagesCount + daysBeforeCount) , let monthRect = sideNavigationStripRects.monthRects[eachMonth.shortMonth.uppercased()]{
                indexedPage?.addLinkAnnotation(bounds:monthRect, goToPage: page, at: atPoint)
            }
            if addWeekOffset {
                addWeekOffset = false
                if self.shouldAddWeekOffsetToCalendarWith(firstDay: eachMonth.dayInfo.first){
                    dayAndWeekPagesCount += 1
                }
            }
            dayAndWeekPagesCount += numberOfWeeksOfMonth + numberOfDaysInMonth + 2  + 1 // every month, notes and tracker pages are added
        }
        
        //extras page linking
        
        if let page = doc.page(at: dayAndWeekPagesCount + daysBeforeCount) {
            indexedPage?.addLinkAnnotation(bounds: sideNavigationStripRects.extrasRect, goToPage: page, at: atPoint)
        }
    }
    private func linkCalendarPages(doc: PDFDocument, index: Int, format: FTDairyFormat,
                           startDate: Date, endDate: Date, atPoint: CGPoint, monthlyFormatter : FTYearInfoMonthly, weeklyFormatter : FTYearInfoWeekly) -> Int{
        let pageIndex = index
        let calendarMonths = monthlyFormatter.monthCalendarInfo;
        let numberYearPages = self.formatInfo.customVariants.isLandscape ? 3 : 2
        let daysBeforeCount = 1 + numberYearPages
        var dayAndWeekPagesCount = 0
        var monthRectsCount = 0
        self.linkSideNavigationStrips(doc: doc,atPoint: atPoint, monthlyFormatter: monthlyFormatter, forPageAtIndex: 0)
        var addWeekOffset : Bool = true
        calendarMonths.forEach { (eachMonth) in
            let monthRects = format.calendarRectsInfo.monthRects
            let numberOfWeeksOfMonth = eachMonth.getWeeksCount()
            let numberOfDaysInMonth = eachMonth.dayInfo.filter({$0.belongsToSameMonth}).count
            let calendarPage = doc.page(at: index)
            if let page = doc.page(at: dayAndWeekPagesCount + daysBeforeCount) {
                calendarPage?.addLinkAnnotation(bounds: monthRects[monthRectsCount], goToPage: page, at: atPoint)
            }
            if addWeekOffset {
                addWeekOffset = false
                if self.shouldAddWeekOffsetToCalendarWith(firstDay: eachMonth.dayInfo.first) {
                    dayAndWeekPagesCount += 1
                }
            }
            dayAndWeekPagesCount += numberOfWeeksOfMonth + numberOfDaysInMonth + 2  + 1 // every month, notes and tracker pages are added
            monthRectsCount += 1
        }
        return pageIndex + 1
    }
    private func linkYearPages(doc: PDFDocument, index: Int, format: FTDairyFormat,atPoint: CGPoint, monthlyFormatter : FTYearInfoMonthly) -> Int{
        let pageIndex = index
        let calendarMonths = monthlyFormatter.monthCalendarInfo;
        let numberYearPages : Int = self.formatInfo.customVariants.isLandscape ? 3 : 2
        
        let beforeDaysCount : Int =  1  + numberYearPages// calendar page
        let monthRects = format.yearRectsInfo.monthRects
        let numberOfMonthInAPage : Int = self.formatInfo.customVariants.isLandscape ? 4 : 6
        var addWeekOffset : Bool = true
        var dayAndWeekPagesCount = 0
        let pageNumRects = format.yearRectsInfo.yearPageNumRects
        for i in 1...numberYearPages {
            let yearPageIndex = i // year page
            let yearPage = doc.page(at: yearPageIndex)
            for (index,rect) in pageNumRects.enumerated() {
                let navigatingPageIndex = 1 + index
                if let navigatingPage = doc.page(at: navigatingPageIndex){
                    yearPage?.addLinkAnnotation(bounds: rect, goToPage: navigatingPage, at: atPoint)
                }
            }
        }
        
        for i in 1...numberYearPages {
            let yearPage = doc.page(at: i)
            
            for j in 1...numberOfMonthInAPage {
                let monthRect = monthRects[numberOfMonthInAPage*(i - 1) + (j - 1)]
                let numberOfWeeksOfMonth = calendarMonths[numberOfMonthInAPage*(i - 1) + (j - 1)].getWeeksCount()
                let numberOfDaysInMonth = calendarMonths[numberOfMonthInAPage*(i - 1) + (j - 1)].dayInfo.filter({$0.belongsToSameMonth}).count
                if let page = doc.page(at: dayAndWeekPagesCount + beforeDaysCount) {
                    yearPage?.addLinkAnnotation(bounds: monthRect, goToPage: page, at: atPoint)
                }
                if addWeekOffset {
                    addWeekOffset = false
                    if self.shouldAddWeekOffsetToCalendarWith(firstDay: calendarMonths.first?.dayInfo.first) {
                        dayAndWeekPagesCount += 1
                    }
                }
                dayAndWeekPagesCount += numberOfWeeksOfMonth + numberOfDaysInMonth + 2  + 1 // every month, notes and tracker pages are added
            }
            self.linkSideNavigationStrips(doc: doc,atPoint: atPoint, monthlyFormatter: monthlyFormatter, forPageAtIndex: i)
        }
        return pageIndex + numberYearPages
    }
    private func linkMonthPages(doc: PDFDocument, index: Int, format: FTDairyFormat,
                                  startDate: Date, endDate: Date, atPoint: CGPoint,monthlyFormatter : FTYearInfoMonthly, weeklyFormatter : FTYearInfoWeekly) -> Int {
        var pageIndex = index
        let calendarMonths = monthlyFormatter.monthCalendarInfo;
        let weeklyFormatter = weeklyFormatter
        var monthRectsCount = 0
        let numberYearPages = self.formatInfo.customVariants.isLandscape ? 3 : 2
        let lastDate = calendarMonths[calendarMonths.count - 1].dayInfo[calendarMonths[calendarMonths.count - 1].dayInfo.count - 1].date
        
        var daysBeforeCount = 1 + numberYearPages + startDate.numberOfMonths(endDate) + calendarMonths[0].dayInfo[0].date.numberOfWeeks(lastDate)
        if endDate.daysBetween(date: lastDate) + 1 > 7 {
            daysBeforeCount -= 1
        }
        let numberOfMonthsBeforeCurrentDate = startDate.numberOfMonths(Date())
        let numberOfWeeks = calendarMonths.prefix(numberOfMonthsBeforeCurrentDate).reduce(0) { partialResult, monthInfo in
            let weeksCount = monthInfo.weeklyInfo.reduce(0) { partialResult, weekInfo in
                return partialResult + (weekInfo.dayInfo.first(where: {$0.fullMonthString.uppercased() == monthInfo.fullMonth.uppercased()}) != nil ? 1 : 0)
            }
            return partialResult  + weeksCount
        }
        self.offsetCount = 1 + numberYearPages + numberOfMonthsBeforeCurrentDate + (numberOfMonthsBeforeCurrentDate - 1)*2 + numberOfWeeks // calender + years + months + notes + trackers + weeks count before current day.

        var weekBeforeDaysCount : Int = 0
        var monthBeforeDays : Int = 1 + numberYearPages
        var previousMonthDays : Int = 0
        var validateMonthForFirstDay : Bool = false
        var addWeekOffset : Bool = true
        var addWeekOffsetForTopNavigationLinks : Bool = true
        var eachDayBeforeDays = 1 + numberYearPages
        calendarMonths.forEach { (eachMonth) in
            let monthRectsInfo = format.monthRectsInfo[monthRectsCount]
            let weekRectsInfo = monthRectsInfo.weekRects
            let monthIndex = monthBeforeDays
            let monthPage = doc.page(at: monthIndex);
            var topNavigationIndex = monthIndex
            let topNavigationRects = self.plannerDiaryTopNavigationRectsInfo.plannerTopNavigationRects
            
            let weekIndex = topNavigationIndex + 1
            if let weekPage = doc.page(at: weekIndex), let weekRect = topNavigationRects[.week]  {
                monthPage?.addLinkAnnotation(bounds: weekRect, goToPage: weekPage, at: atPoint)
            }
            if addWeekOffsetForTopNavigationLinks {
                addWeekOffsetForTopNavigationLinks = false
                if self.shouldAddWeekOffsetToCalendarWith(firstDay: eachMonth.dayInfo.first){
                    topNavigationIndex += 1
                }
            }
            let dayIndex = topNavigationIndex + eachMonth.getWeeksCount() + 1
            if let dayPage = doc.page(at: dayIndex), let dayRect = topNavigationRects[.day]  {
                monthPage?.addLinkAnnotation(bounds: dayRect, goToPage: dayPage, at: atPoint)
            }
            let notesIndex = topNavigationIndex + eachMonth.getWeeksCount() + eachMonth.dayInfo.filter({$0.belongsToSameMonth}).count + 1
            if let notesPage = doc.page(at: notesIndex), let notesRect = topNavigationRects[.notes]  {
                monthPage?.addLinkAnnotation(bounds: notesRect, goToPage: notesPage, at: atPoint)
            }
            let trackerIndex = topNavigationIndex + eachMonth.getWeeksCount() + eachMonth.dayInfo.filter({$0.belongsToSameMonth}).count + 2
            if let trackerPage = doc.page(at: trackerIndex), let trackerRect = topNavigationRects[.tracker]  {
                monthPage?.addLinkAnnotation(bounds: trackerRect, goToPage: trackerPage, at: atPoint)
            }
            if !weekRectsInfo.isEmpty {
                weekBeforeDaysCount = monthBeforeDays + 1 // adding first week
                for  (weekIndex,weekRect) in weekRectsInfo.enumerated() {
                    let weekFirstDay = eachMonth.weeklyInfo[weekIndex].dayInfo.first
                    
                    if !validateMonthForFirstDay { // ignoring as we need to process the week even its first day doesnt belong to calendar
                        validateMonthForFirstDay = true
                        if self.shouldAddWeekOffsetToCalendarWith(firstDay: eachMonth.dayInfo.first)  {
                        
                        let weekPageIndex = weekBeforeDaysCount
                        if let page = doc.page(at: weekPageIndex){
                            monthPage?.addLinkAnnotation(bounds: weekRect, goToPage: page, at: atPoint)
                        }
                        weekBeforeDaysCount += 1
                        continue
                        }
                    }
                    
                    if weekFirstDay?.fullMonthString.uppercased() == eachMonth.fullMonth.uppercased(){
                            let weekPageIndex = weekBeforeDaysCount
                            if let page = doc.page(at: weekPageIndex){
                                monthPage?.addLinkAnnotation(bounds: weekRect, goToPage: page, at: atPoint)
                            }
                    }else{// week pages under previous month
                            weekBeforeDaysCount -= 1 // as week page falls under previous month
                            let weekPageIndex = weekBeforeDaysCount - previousMonthDays
                            if let page = doc.page(at: weekPageIndex){
                                monthPage?.addLinkAnnotation(bounds: weekRect, goToPage: page, at: atPoint)
                            }
                    }
                    weekBeforeDaysCount += 1
                }
            }
            previousMonthDays = eachMonth.dayInfo.filter({$0.belongsToSameMonth}).count + 2 + 1 // adding weeks,days, notes, tracker and month pages of one month
            monthBeforeDays += eachMonth.getWeeksCount() + eachMonth.dayInfo.filter({$0.belongsToSameMonth}).count + 2  + 1 // adding weeks,days, notes, tracker and month pages of one month
            if addWeekOffset {
                addWeekOffset = false
                if self.shouldAddWeekOffsetToCalendarWith(firstDay: eachMonth.dayInfo.first){
                    monthBeforeDays += 1
                }
            }

            //Linking days of each month

            var dayRectsCount = 0
            eachDayBeforeDays += 1 + eachMonth.getWeeksCount() // adding month and weeks belonging to a month.
            eachMonth.dayInfo.forEach({(eachDay) in
                if isBelongToCalendar(currentDate: eachDay.date, startDate: startDate, endDate: endDate) {
                    if eachDay.belongsToSameMonth {
                        if monthRectsInfo.dayRects.count > dayRectsCount {
                            eachDayBeforeDays += 1 // adding one day
                            let dayIndex = eachDayBeforeDays
                            if let page = doc.page(at: dayIndex) {
                                monthPage?.addLinkAnnotation(bounds: monthRectsInfo.dayRects[dayRectsCount], goToPage: page, at: atPoint)
                            }
                        }
                        dayRectsCount += 1
                    }
                }
            })
            eachDayBeforeDays += 2 // adding notes and tracker pages

            self.linkSideNavigationStrips(doc: doc,atPoint: atPoint, monthlyFormatter: monthlyFormatter, forPageAtIndex: monthIndex)
            pageIndex += 1
            monthRectsCount += 1
        }
        return pageIndex
    }
    private func linkWeekPages(doc: PDFDocument, format:FTDairyFormat,
                                 startDate: Date, endDate: Date, atPoint: CGPoint, weeklyFormatter : FTYearInfoWeekly, monthlyFormatter : FTYearInfoMonthly) {
        let monthlyCalendar = monthlyFormatter.monthCalendarInfo
        let numberYearPages = self.formatInfo.customVariants.isLandscape ? 3 : 2
        var monthBeforeDays : Int = 1 + numberYearPages
        var weekBeforeDaysCount : Int = 0
        var addWeekOffset : Bool = true
        var weekRectsCount : Int = 0
        var processedMonthDaysCount : Int = 0
        let topNavigationRects = self.plannerDiaryTopNavigationRectsInfo.plannerTopNavigationRects
        for (monthIndex,eachMonth) in monthlyCalendar.enumerated() {
            var weeksInMonth : Int = eachMonth.getWeeksCount()
            weekBeforeDaysCount = monthBeforeDays + 1 // adding month
            if addWeekOffset {
                addWeekOffset = false
                if shouldAddWeekOffsetToCalendarWith(firstDay: eachMonth.weeklyInfo.first?.dayInfo.first){
                    weeksInMonth += 1
                }
            }
            var currentWeekDaysCount = 1
            var deleteProcessedDaysCount : Bool = true
            for (weekIndex, eachWeek) in eachMonth.weeklyInfo.enumerated(){
                
                let weekPageIndex = weekBeforeDaysCount + weekIndex
                let weekPage = doc.page(at: weekPageIndex)
                self.linkSideNavigationStrips(doc: doc,atPoint: atPoint, monthlyFormatter: monthlyFormatter, forPageAtIndex: weekPageIndex)
                
                // Top navigatino bars month and week options navigations
                if let weekPage = weekPage, let monthPage = doc.page(at: monthBeforeDays), let monthRect = topNavigationRects[.month]{
                    weekPage.addLinkAnnotation(bounds: monthRect, goToPage: monthPage, at: atPoint)
                }
                var weekDayRectsCount : Int = 0
                var firstWeekDayIndex : Int = 0
                for (dayIndex,eachDay) in eachWeek.dayInfo.enumerated(){
                    
                    if isBelongToCalendarYear(currentDate: eachDay.date) {
                        
                        if monthIndex == 0, weekIndex != 0, dayIndex == 0,self.shouldAvoidProcessingWeekFor(dayInfo: eachDay, monthInfo: eachMonth){
                            weekBeforeDaysCount -= 1
                            weekRectsCount -= 1
                            break
                        }
                        else if monthIndex > 0, dayIndex == 0, self.shouldAvoidProcessingWeekFor(dayInfo: eachDay, monthInfo: eachMonth){
                            weekBeforeDaysCount -= 1
                            weekRectsCount -= 1
                            break
                        }
                        let weekDayRects = format.weekRectsInfo[weekRectsCount].weekDayRects
                        if eachDay.fullMonthString.uppercased() == eachMonth.fullMonth.uppercased(){
                            let weekDayRect = weekDayRects[weekDayRectsCount]
                            let dayPageIndex = monthBeforeDays + weeksInMonth  + currentWeekDaysCount + processedMonthDaysCount
                            if let page = (doc.page(at: dayPageIndex)) {
                                weekPage?.addLinkAnnotation(bounds: weekDayRect, goToPage: page, at : atPoint)
                            }
                            if let weekPage = weekPage, let dayPage = doc.page(at: dayPageIndex), let weekRect = topNavigationRects[.week]{
                                dayPage.addLinkAnnotation(bounds: weekRect, goToPage: weekPage, at: atPoint)
                            }
                            if (monthIndex == 0 && weekIndex == 0 && weekDayRectsCount == 0) || dayIndex == 0 { // for first month, first week capturing day whichever comes first
                                firstWeekDayIndex = dayPageIndex
                            }
                            weekDayRectsCount += 1
                            currentWeekDaysCount += 1
                        }
                        else {
                            // next month days
                            if deleteProcessedDaysCount {
                                deleteProcessedDaysCount = false
                                processedMonthDaysCount = 0
                            }
                            let weekDayRect = weekDayRects[weekDayRectsCount]
                            let dayPageIndex = (monthBeforeDays + weeksInMonth + eachMonth.dayInfo.filter({$0.belongsToSameMonth}).count + 2 + 1) + 1 + monthlyCalendar[monthIndex + 1 ].getWeeksCount() + processedMonthDaysCount // in the last added next month and its weeks and already processesed month days
                            if let page = (doc.page(at: dayPageIndex)) {
                                weekPage?.addLinkAnnotation(bounds: weekDayRect, goToPage: page, at : atPoint)
                            }
                            if let weekPage = weekPage, let dayPage = doc.page(at: dayPageIndex), let weekRect = topNavigationRects[.week]{
                                dayPage.addLinkAnnotation(bounds: weekRect, goToPage: weekPage, at: atPoint)
                            }
                            weekDayRectsCount += 1
                            processedMonthDaysCount += 1
                        }
                    }
                    // Top Navigation bar's day navigation
                    if firstWeekDayIndex > 0 {
                        if let weekPage = weekPage, let dayPage = doc.page(at: firstWeekDayIndex), let dayRect = topNavigationRects[.day]{
                            weekPage.addLinkAnnotation(bounds: dayRect, goToPage: dayPage, at: atPoint)
                        }
                    }
                    
                }
                weekRectsCount += 1
                // Top navigation bar's notes and tracker pages
                if let weekPage = weekPage,let notesRect = topNavigationRects[.notes], let notesPage = doc.page(at:monthBeforeDays + weeksInMonth + eachMonth.dayInfo.filter({$0.belongsToSameMonth}).count + 1) { // at the end notes index
                    weekPage.addLinkAnnotation(bounds: notesRect, goToPage: notesPage, at: atPoint)
                }
                if let weekPage = weekPage,let trackerRect = topNavigationRects[.tracker], let trackerPage = doc.page(at:monthBeforeDays + weeksInMonth + eachMonth.dayInfo.filter({$0.belongsToSameMonth}).count + 2) { // at the end notes and tracker indexes
                    weekPage.addLinkAnnotation(bounds: trackerRect, goToPage: trackerPage, at: atPoint)
                }
            }
            if deleteProcessedDaysCount { // Deleting as they may be added to subsequent months
                deleteProcessedDaysCount = false
                processedMonthDaysCount = 0
            }
            monthBeforeDays += weeksInMonth + eachMonth.dayInfo.filter({$0.belongsToSameMonth}).count + 2  + 1 // adding weeks,days, notes, tracker and month pages of one month
            
            
        }
    }
    private func linkDayPages(doc: PDFDocument, startDate: Date, format: FTDairyFormat, atPoint: CGPoint, monthlyFormatter : FTYearInfoMonthly) {
        let monthInfo = monthlyFormatter.monthCalendarInfo;
        var dayRectsCount = 0
        var addWeekOffset : Bool = true
        let numberYearPages = self.formatInfo.customVariants.isLandscape ? 3 : 2
        var daysBeforeMonth = 1 + numberYearPages
        var daysBeforeCount : Int = 1 + numberYearPages // calendar and year pages
        let topNavigationRects = self.plannerDiaryTopNavigationRectsInfo.plannerTopNavigationRects
        monthInfo.forEach { (eachMonth) in
            var numOfWeeksInMonth = eachMonth.getWeeksCount()
            if addWeekOffset {
                addWeekOffset = false
                if shouldAddWeekOffsetToCalendarWith(firstDay: eachMonth.weeklyInfo.first?.dayInfo.first){
                    numOfWeeksInMonth += 1
                }
            }
            daysBeforeCount += numOfWeeksInMonth + 1 // adding number of weeks and one month page
            let dayInfo = eachMonth.dayInfo;
            dayInfo.forEach { (eachDayInfo) in
                if eachDayInfo.belongsToSameMonth {
                    let dayPage = doc.page(at: daysBeforeCount)
                    let topNavigationMonthIndex = daysBeforeMonth
                    if let monthPage = doc.page(at: topNavigationMonthIndex), let monthRect = topNavigationRects[.month] {
                        dayPage?.addLinkAnnotation(bounds: monthRect, goToPage: monthPage, at: atPoint)
                    }
                    
                    let topNavigationNotesindex = daysBeforeMonth + numOfWeeksInMonth + eachMonth.dayInfo.filter({$0.belongsToSameMonth}).count + 1
                    if let notesPage = doc.page(at: topNavigationNotesindex), let notesRect = topNavigationRects[.notes] {
                        dayPage?.addLinkAnnotation(bounds: notesRect, goToPage:notesPage , at: atPoint)
                    }
                    if let trackerPage = doc.page(at: topNavigationNotesindex + 1), let trackerRect = topNavigationRects[.tracker] {
                        dayPage?.addLinkAnnotation(bounds: trackerRect, goToPage: trackerPage, at: atPoint)
                    }
                    
                    self.linkSideNavigationStrips(doc: doc,atPoint: atPoint, monthlyFormatter: monthlyFormatter, forPageAtIndex: daysBeforeCount)
                    daysBeforeCount += 1 // adding day
                }
            }
            //For Notes page
            let notesIndex = daysBeforeCount
            if let notesPage = doc.page(at: notesIndex){
                if let monthPage = doc.page(at: daysBeforeMonth),let monthRect = topNavigationRects[.month]{
                    notesPage.addLinkAnnotation(bounds: monthRect, goToPage: monthPage, at: atPoint)
                }
                if let weekPage = doc.page(at: daysBeforeMonth + 1),let weekRect = topNavigationRects[.week]{
                    notesPage.addLinkAnnotation(bounds: weekRect, goToPage: weekPage, at: atPoint)
                }
                if let dayPage = doc.page(at: daysBeforeMonth + numOfWeeksInMonth + 1),let dayRect = topNavigationRects[.day]{
                    notesPage.addLinkAnnotation(bounds: dayRect, goToPage: dayPage, at: atPoint)
                }
                if let trackerPage = doc.page(at: notesIndex + 1),let trackerRect = topNavigationRects[.tracker]{
                    notesPage.addLinkAnnotation(bounds: trackerRect, goToPage: trackerPage, at: atPoint)
                }
                
            }
            self.linkSideNavigationStrips(doc: doc,atPoint: atPoint, monthlyFormatter: monthlyFormatter, forPageAtIndex: daysBeforeCount)
            
            // For Tracker Page
            
            if let trackerPage = doc.page(at: notesIndex + 1){
                if let monthPage = doc.page(at: daysBeforeMonth),let monthRect = topNavigationRects[.month]{
                    trackerPage.addLinkAnnotation(bounds: monthRect, goToPage: monthPage, at: atPoint)
                }
                if let weekPage = doc.page(at: daysBeforeMonth + 1),let weekRect = topNavigationRects[.week]{
                    trackerPage.addLinkAnnotation(bounds: weekRect, goToPage: weekPage, at: atPoint)
                }
                if let dayPage = doc.page(at: daysBeforeMonth + numOfWeeksInMonth + 1),let dayRect = topNavigationRects[.day]{
                    trackerPage.addLinkAnnotation(bounds: dayRect, goToPage: dayPage, at: atPoint)
                }
                if let notesRect = topNavigationRects[.notes],let notesPage = doc.page(at: notesIndex){
                    trackerPage.addLinkAnnotation(bounds: notesRect, goToPage: notesPage, at: atPoint)
                }
                
            }
            
            self.linkSideNavigationStrips(doc: doc,atPoint: atPoint, monthlyFormatter: monthlyFormatter, forPageAtIndex: daysBeforeCount + 1)
            
            daysBeforeCount += 2
            daysBeforeMonth += numOfWeeksInMonth + eachMonth.dayInfo.filter({$0.belongsToSameMonth}).count + 2 + 1
        }
        
        // For extras Page
        for index in 0...2 {
            self.linkSideNavigationStrips(doc: doc,atPoint: atPoint, monthlyFormatter: monthlyFormatter, forPageAtIndex: daysBeforeCount + index)
        }
        let extrasPageNumRects = self.plannerDiaryExtrasTabRectsInfo.plannerExtrasRects
        for i in 0...2 {
            let extrasPageIndex = daysBeforeCount + i
            let extrasPage = doc.page(at: extrasPageIndex)
            for (index,rect) in extrasPageNumRects.enumerated() {
                let navigatingPageIndex = daysBeforeCount + index
                if let navigatingPage = doc.page(at: navigatingPageIndex){
                    print("linking from page index : \(extrasPageIndex) to page index : \(navigatingPageIndex)")
                    extrasPage?.addLinkAnnotation(bounds: rect, goToPage: navigatingPage, at: atPoint)
                }
            }
        }
        
    }
    private func shouldAvoidProcessingWeekFor( dayInfo : FTDayInfo , monthInfo : FTMonthlyCalendarInfo) -> Bool {
        return dayInfo.fullMonthString.uppercased() != monthInfo.fullMonth.uppercased()
    }
    func drawYearPageMonthColorBandsWith(xAxis : CGFloat, yAxis : CGFloat, context : CGContext, width : CGFloat,height: CGFloat, bandColor : UIColor){
        let whiteBandRect = CGRect(x: xAxis - 0.5, y: yAxis - 1 , width : width + 1, height: height + 1)
        context.setFillColor(UIColor(hexString: "#FEFEFE", alpha: 1.0).cgColor)
        context.fill(whiteBandRect)
        
        let monthBandRect = CGRect(x: xAxis - 0.5, y: yAxis - 1, width: width + 1 , height: height + 1)
        context.setFillColor(bandColor.cgColor)
        context.fill(monthBandRect)
    }
    func isA5LandscapeLayout() -> Bool {
        return (self.formatInfo.customVariants.selectedDevice.identifier == "standard4" && self.formatInfo.customVariants.isLandscape)
    }

}
extension FTPlannerDiaryFormat {
    
    func addBezierLineWith(rect: CGRect, toContext context: CGContext, withColor lineColor: UIColor, shadowColor: UIColor, shadowOffset : CGSize, shadowBlurRadius : CGFloat) {
        //Shadow Declarations
        let shadow = shadowColor
        let shadowOffset = shadowOffset
        let shadowBlurRadius: CGFloat = shadowBlurRadius

        //Bezier  Drawing
        let  bezierLinePath = UIBezierPath()
        let  p0 = CGPoint(x: rect.origin.x, y: rect.origin.y)
        bezierLinePath.move(to: p0)
        let  p1 = CGPoint(x: rect.origin.x , y: rect.minY + rect.width)
        bezierLinePath.addLine(to: p1)
        bezierLinePath.lineWidth = 0.5
        bezierLinePath.lineCapStyle = .butt
        lineColor.setStroke()
        context.addPath(bezierLinePath.cgPath)
        bezierLinePath.stroke()
        //context.setShadow(offset: shadowOffset, blur: shadowBlurRadius,  color: (shadow as UIColor).cgColor)
    }
}
class FTPlannerWeekNumber : NSObject {
    var weekNumber : String = ""
    var isActive : Bool = false
}

extension FTPlannerDiaryFormat {
    func getTextTintColor() -> UIColor {
        if isDarkTemplate {
            return self.darkPlannerTextTintColor
        }else {
            return self.textTintColor
        }
    }
    func getMonthStripColorsDict() -> [String:String] {
        if isDarkTemplate {
            return self.darkPlannerMonthStripColors
        }else {
            return self.monthStripColors
        }
    }
    func getSideStripMonthColorsDict() -> [String:String] {
        if isDarkTemplate {
            return darkPlannerSideStripMonthColorsDict
        }else {
            return sideStripMonthColorsDict
        }
    }
    func getCalenderSideStripBGColor() -> UIColor {
        if isDarkTemplate {
            return darkPlannerCalendarStripColor
        } else {
            return calendarStripColor
        }
    }
    func getStripHighlightBGColor() -> UIColor {
        if isDarkTemplate {
            return darkplannerStripHighlightColor
        }else {
            return stripHighlightColor
        }
    }
    func getPageNumberHightlightBGColor() -> UIColor {
        if isDarkTemplate {
            return darkPlannerPageNumberHighlightBGColor
        }else {
            return pageNumberHighlightBGColor
        }
    }
    func getWeekNumberStripBGColorsDict() -> [Int:String] {
        if isDarkTemplate {
            return darkPlannerWeekNumberStripColors
        }else {
            return weekNumberStripColors
        }
    }
    func getWeekDaysPastalColors() -> [String] {
        if isDarkTemplate {
            return darkPlannerWeekDaysPastalColors
        }else {
            return weekDaysPastalColors
        }
    }
    func getNotesBandBGColor() -> UIColor {
        if isDarkTemplate {
            return darkPlannerNotesBandBGColor
        }else {
            return notesBandBGColor
        }
    }
}
