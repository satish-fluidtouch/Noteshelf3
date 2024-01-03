//
//  FTMidnightFormat.swift
//  Noteshelf
//
//  Created by Ramakrishna on 10/05/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTStyles

class FTMidnightDairyFormat : FTDairyFormat {
    
    var customVariants : FTPaperVariants
    
    let weekNumberStrings : [String] = ["WEEK 1", "WEEK 2","WEEK 3","WEEK 4","WEEK 5","WEEK 6"]
    
    var currentWeekRectInfo: FTDiaryWeekRectsInfo = FTDiaryWeekRectsInfo()
    var currentDayRectsInfo: FTDiaryDayRectsInfo = FTDiaryDayRectsInfo()
    
    var isiPad : Bool {
        return true
    }
    
    required init(customVariants : FTPaperVariants){
        self.customVariants = customVariants
        super.init()
    }
    func renderCalendarPage(context : CGContext,months : [FTMonthlyCalendarInfo],calendarYear : FTYearFormatInfo){
        
    }
    func renderPrioritiesPage(context : CGContext, weeklyInfo : FTWeekInfo?, dayInfo : FTDayInfo?){
        
    }
    func renderDailyPlanPage(context : CGContext, dayInfo : FTDayInfo){
        
    }
    func renderNotesPage(context : CGContext, weeklyInfo : FTWeekInfo?, dayInfo : FTDayInfo?){
        
    }
    func renderDailyNotesPage(context : CGContext, dayInfo : FTDayInfo){
        
    }
    class func getFormatBasedOn(variants: FTPaperVariants) -> FTMidnightDairyFormat{
        if !variants.selectedDevice.isiPad  || variants.selectedDevice.identifier == "standard4" {
            return FTMidnightDiaryiPhoneFormat(customVariants: variants)
        }
        return  FTMidnightDiaryiPadFormat(customVariants: variants)
    }
    override var yearTemplate: String {
        return getMidnightAssetPDFPath(ofType: FTDigitalDiaryTemplateType.yearly, customVariants: formatInfo.customVariants)
    }
    override var dayTemplate: String {
        let templateType : FTDigitalDiaryTemplateType = (formatInfo.screenType == .Ipad && formatInfo.customVariants.isLandscape) ? .iPadLandscapeDaily : .daily
        return getMidnightAssetPDFPath(ofType: templateType, customVariants: formatInfo.customVariants)
    }
    override var weekTemplate: String {
        return getMidnightAssetPDFPath(ofType: FTDigitalDiaryTemplateType.weekly, customVariants: formatInfo.customVariants)
    }
    override var monthTemplate: String {
        return getMidnightAssetPDFPath(ofType: FTDigitalDiaryTemplateType.monthly, customVariants: formatInfo.customVariants)
    }
    var prioritiesTemplate : String {
        return getMidnightAssetPDFPath(ofType: FTDigitalDiaryTemplateType.priorities,customVariants: formatInfo.customVariants)
    }
    var notesTemplate : String {
        return getMidnightAssetPDFPath(ofType: FTDigitalDiaryTemplateType.notes,customVariants: formatInfo.customVariants)
    }
    
    override func renderYearPage(context: CGContext, months: [FTMonthInfo], calendarYear: FTYearFormatInfo) {
        super.renderYearPage(context: context, months: months, calendarYear: calendarYear)
        let templateInfo = screenInfo.spacesInfo.yearPageSpacesInfo
        
        var currMonthIndex = CGFloat(0)
        let columnCount = getColumnCount()
        let rowCount = getRowCount()
        let cellWidth = getYearCellWidth(columnCount: columnCount)
        let cellHeight = getYearCellHeight(rowCount: rowCount)
        let font = UIFont.robotoMedium(screenInfo.fontsInfo.yearPageDetails.yearFontSize)
        let minimumFontSize : CGFloat = self.isiPad ? 33 : 16
        let newFontSize = UIFont.getScaledFontSizeFor(font: font, screenSize: currentPageRect.size, minPointSize: minimumFontSize)
        let yearAttrs: [NSAttributedString.Key: Any] = [.font:UIFont.robotoMedium(newFontSize) ,
                                                        .kern: 0.0,
                                                        .foregroundColor: UIColor.init(hexString: "#C4C4C4")]
        if let startYear = months.first?.year {
            var year: String = "\(startYear)"
            if let endYear = months.last?.year, endYear != startYear {
                let endYearXX = "\(endYear)".suffix(2)
                year = "\(startYear)" +  "-" + "\(endYearXX)"
            }
            let yearString = NSMutableAttributedString.init(string: "\(year)", attributes: yearAttrs)
            let yearRect = CGRect(x: (currentPageRect.width*templateInfo.baseBoxX/100), y: (currentPageRect.height*templateInfo.yearY/100), width: yearString.size().width, height: yearString.size().height)
            let yearLocation = CGPoint(x: yearRect.origin.x, y: yearRect.origin.y)
            yearString.draw(at: yearLocation)
            calendarRectsInfo.yearRect = getLinkRect(location: CGPoint(x: yearLocation.x, y: yearLocation.y), frameSize: CGSize(width: yearRect.width   ,height: yearRect.height))
            if self.isiPad {
                let navigationStringAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.robotoMedium(newFontSize),
                                                                            .kern: 0.0,
                                                                            .foregroundColor: UIColor.init(hexString: "#C4C4C4", alpha: 0.4)]
                let navigationString = NSMutableAttributedString.init(string: "/", attributes: navigationStringAttrs)
                let navigationLocation = CGPoint(x: (yearLocation.x) + yearString.size().width + 11, y: yearLocation.y)
                navigationString.draw(at: navigationLocation)
                
                let overViewString = NSMutableAttributedString(string: "Overview", attributes: yearAttrs)
                let overViewStringLocation = CGPoint(x: navigationLocation.x + navigationString.size().width + 20 , y: yearLocation.y)
                overViewString.draw(at: overViewStringLocation)
            }
            yearRectsInfo.yearRect = getLinkRect(location: yearLocation, frameSize: yearString.size())
        }
        
        var monthY = currentPageRect.height*templateInfo.baseBoxY/100
        var monthX = currentPageRect.width*templateInfo.baseBoxX/100
        months.forEach { (month) in
            let monthFont = UIFont.montserratFont(for: .bold, with: screenInfo.fontsInfo.yearPageDetails.titleMonthFontSize)
            let monthNewFontSize = UIFont.getScaledFontSizeFor(font: monthFont, screenSize: currentPageRect.size, minPointSize: 7)
            let monthAttrs : [NSAttributedString.Key: Any] = [.font : UIFont.montserratFont(for: .bold, with: monthNewFontSize),
                                                              NSAttributedString.Key.kern : 0.0,
                                                              .foregroundColor : UIColor.init(hexString: "#E5E5E5")]
            let monthString = NSMutableAttributedString(string: month.monthTitle.uppercased() , attributes: monthAttrs)
            let location = CGPoint(x: monthX + monthString.size().height , y: monthY + monthString.size().height)
            monthString.draw(at: location)
            yearRectsInfo.monthRects.append(getLinkRect(location: CGPoint(x: monthX + monthString.size().height/2, y: monthY + monthString.size().height/2), frameSize: CGSize(width: monthString.size().width + monthString.size().height ,height: monthString.size().height + monthString.size().height)))
            currMonthIndex+=1
            let numberOfColunms = columnCount
            if currMonthIndex.truncatingRemainder(dividingBy: numberOfColunms) == 0{
                monthY += cellHeight + (currentPageRect.height*templateInfo.cellOffsetY/100)
                monthX = currentPageRect.width*templateInfo.baseBoxX/100
            }
            else{
                monthX += cellWidth + (currentPageRect.size.width*templateInfo.cellOffsetX/100)
            }
        }
    }
    override func getTemplateBackgroundColor() -> UIColor {
        return UIColor(red: 40/255, green: 46/255, blue: 57/255, alpha: 1.0)
    }
    override func getYearCellHeight(rowCount: CGFloat) -> CGFloat {
        let templateInfo = screenInfo.spacesInfo.yearPageSpacesInfo
        return (currentPageRect.size.height - (currentPageRect.size.height*templateInfo.baseBoxY/100) - (currentPageRect.size.height*templateInfo.boxBottomOffset/100) - ((rowCount - 1) * (currentPageRect.size.height*templateInfo.cellOffsetY/100)))/rowCount
    }
    override func getYearCellWidth(columnCount: CGFloat) -> CGFloat {
        let templateInfo = screenInfo.spacesInfo.yearPageSpacesInfo
        return (currentPageRect.size.width - (2 * (currentPageRect.size.width*templateInfo.baseBoxX/100)) - ((columnCount - 1) * (currentPageRect.size.width*templateInfo.cellOffsetX/100)))/columnCount
    }
    override func renderWeekPage(context: CGContext, weeklyInfo: FTWeekInfo) {
        super.renderWeekPage(context: context, weeklyInfo: weeklyInfo)
        currentWeekRectInfo = FTDiaryWeekRectsInfo()
        let templateInfo = screenInfo.spacesInfo.weekPageSpacesInfo
        let font = UIFont.robotoMedium(screenInfo.fontsInfo.weekPageDetails.yearFontSize)
        let minimumFontSize : CGFloat = self.isiPad ? 33 : 16
        let newFontSize = UIFont.getScaledFontSizeFor(font: font, screenSize: currentPageRect.size, minPointSize: minimumFontSize)
        
        let yearAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.robotoMedium(newFontSize),
                                                        .kern: 0.0,
                                                        .foregroundColor: UIColor.init(hexString: "#C4C4C4")]
        
        let yearString = NSMutableAttributedString.init(string: weeklyInfo.dayInfo[0].yearString, attributes: yearAttrs)
        let yearLocation = CGPoint(x: (currentPageRect.width*templateInfo.baseBoxX/100), y: (currentPageRect.height*templateInfo.titleLineY/100) )
        yearString.draw(at: yearLocation)
        currentWeekRectInfo.yearRect = getLinkRect(location: yearLocation, frameSize: yearString.size())
        let navigationStringAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.robotoMedium(newFontSize),
                                                                    .kern: 0.0,
                                                                    .foregroundColor: UIColor.init(hexString: "#C4C4C4", alpha: 0.4)]
        let navigationString = NSMutableAttributedString.init(string: "/", attributes: navigationStringAttrs)
        let navigationLocation = CGPoint(x: (yearLocation.x) + yearString.size().width + 11, y: (currentPageRect.height*templateInfo.titleLineY/100) )
        navigationString.draw(at: navigationLocation)
        
        
        let monthAttrs: [NSAttributedString.Key: Any] = yearAttrs
        let weekDurationAttrs: [NSAttributedString.Key: Any] = yearAttrs
        let weekFirstDate = weeklyInfo.dayInfo.first
        let weekLastDate = weeklyInfo.dayInfo.last
        var weekDurationText : String = ""
        if weekFirstDate?.month == weekLastDate?.month {
            let monthString = NSMutableAttributedString.init(string: weeklyInfo.dayInfo.first?.monthString ?? "", attributes: monthAttrs)
            let monthLocation = CGPoint(x: navigationLocation.x  + navigationString.size().width + 8,
                                        y:(currentPageRect.height*templateInfo.titleLineY/100))
            currentWeekRectInfo.weekStartDaysMonthRect = getLinkRect(location: monthLocation, frameSize: monthString.size())
            
            weekDurationText =  monthString.string
            weekDurationText += "  " + (weeklyInfo.dayInfo.first?.fullDayString ?? "") + " - "
            weekDurationText += (weeklyInfo.dayInfo.last?.fullDayString ?? "")
        }
        else{
            let weekFirstDaysMonth = NSMutableAttributedString.init(string: weeklyInfo.dayInfo.first?.monthString ?? "", attributes: monthAttrs)
            weekDurationText += weekFirstDaysMonth.string + " " + (weeklyInfo.dayInfo.first?.fullDayString ?? "") + " " + "-" + " "
            let firstMonthLocation = CGPoint(x: navigationLocation.x  + navigationString.size().width + 8,
                                             y:(currentPageRect.height*templateInfo.titleLineY/100))
            currentWeekRectInfo.weekStartDaysMonthRect = getLinkRect(location: firstMonthLocation, frameSize: weekFirstDaysMonth.size())
            let weekLastDaysMonth = NSMutableAttributedString.init(string: weeklyInfo.dayInfo.last?.monthString ?? "", attributes: monthAttrs)
            let weekDurationAttributedText = NSMutableAttributedString.init(string: weekDurationText, attributes: monthAttrs)
            let secondMonthLocation = CGPoint(x: firstMonthLocation.x + weekDurationAttributedText.size().width ,
                                              y:(currentPageRect.height*templateInfo.titleLineY/100))
            currentWeekRectInfo.weekEndDaysMonthRect = getLinkRect(location: secondMonthLocation, frameSize: weekLastDaysMonth.size())
            weekDurationText +=   weekLastDaysMonth.string + " " + (weeklyInfo.dayInfo.last?.fullDayString ?? "")
        }
        
        let weekDurationString = NSMutableAttributedString.init(string: weekDurationText, attributes: weekDurationAttrs)
        let weekDurationLocation = CGPoint(x: navigationLocation.x  + navigationString.size().width + 8,
                                           y:(currentPageRect.height*templateInfo.titleLineY/100))
        weekDurationString.draw(at: weekDurationLocation)
    }
    
    override func renderDayPage(context: CGContext, dayInfo: FTDayInfo) {

        super.renderDayPage(context: context, dayInfo: dayInfo);
        let templateInfo = screenInfo.spacesInfo.dayPageSpacesInfo
        
        let titleX = currentPageRect.width*templateInfo.baseX/100
        let titleY = currentPageRect.height*templateInfo.baseY/100
        let notesBoxX = currentPageRect.width*templateInfo.notesBoxX/100
        let notesBoxY = currentPageRect.height*templateInfo.notesBoxY/100
        let notesBoxWidth : CGFloat = currentPageRect.width*templateInfo.notesBoxWidth/100
        let notesBoxHeight : CGFloat = currentPageRect.height*templateInfo.notesBoxHeight/100
        
        let font = UIFont.robotoMedium(screenInfo.fontsInfo.dayPageDetails.yearFontSize)
        let minimumFontSize : CGFloat = self.isiPad ? 33 : 16
        let newFontSize = UIFont.getScaledFontSizeFor(font: font, screenSize: currentPageRect.size, minPointSize: minimumFontSize)
        let yearAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.robotoMedium(newFontSize),
                                                         NSAttributedString.Key.kern : 0.0,
                                                         .foregroundColor : UIColor.init(hexString: "#C4C4C4")];
        let yearString = NSMutableAttributedString.init(string: dayInfo.yearString, attributes: yearAttrs)
        let yearLocation = CGPoint(x: titleX,
                                   y: titleY)
        yearString.draw(at: yearLocation)
        currentDayRectsInfo.yearRect = getLinkRect(location: yearLocation, frameSize: yearString.size())
        
        let navigationStringAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.robotoMedium(newFontSize),
                                                                    .kern: 0.0,
                                                                    .foregroundColor: UIColor.init(hexString: "#C4C4C4", alpha: 0.4)]
        
        let navigationString = NSMutableAttributedString.init(string: "/", attributes: navigationStringAttrs)
        let navigationLocation = CGPoint(x: (yearLocation.x) + yearString.size().width + 7, y: titleY )
        navigationString.draw(at: navigationLocation)
        
        let monthAttrs: [NSAttributedString.Key : Any] = yearAttrs
        let monthString = NSMutableAttributedString.init(string: dayInfo.monthString, attributes: monthAttrs)
        let monthLocation = CGPoint(x: navigationLocation.x + navigationString.size().width + 8 , y: titleY)
        monthString.draw(at: monthLocation)
        currentDayRectsInfo.monthRect = getLinkRect(location: monthLocation, frameSize: monthString.size())
        
        let navigation1String = NSMutableAttributedString.init(string: "/", attributes: navigationStringAttrs)
        let navigation1Location = CGPoint(x: (monthLocation.x) + monthString.size().width + 7, y: titleY )
        navigation1String.draw(at: navigation1Location)
        
        let dayAndWeekAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.robotoMedium(newFontSize),
                                                               NSAttributedString.Key.kern : 0.0,
                                                               .foregroundColor : UIColor.init(hexString: "#4FA4FF")
        ];
        
        var dayAndWeekText = dayInfo.dayString + " "
        dayAndWeekText += dayInfo.weekString
        let dayAndWeekString = NSMutableAttributedString.init(string: dayAndWeekText, attributes: dayAndWeekAttrs)
        let dayAndWeekLocation = CGPoint(x: navigation1Location.x + navigation1String.size().width + 8, y: titleY)
        dayAndWeekString.draw(at: dayAndWeekLocation)
        let notesRect = CGRect(x: notesBoxX , y: notesBoxY, width: notesBoxWidth, height: notesBoxHeight)
        let chevronImage = UIImage(named: "right_chevron")
        let notesChevronRect = CGRect(x: (notesRect.origin.x + notesBoxWidth - 4 - 24), y: (notesRect.origin.y + 4), width: 24, height: 24)
        chevronImage?.draw(at: CGPoint(x: notesChevronRect.origin.x, y: notesChevronRect.origin.y))
        currentDayRectsInfo.notesRect = getLinkRect(location: CGPoint(x: notesChevronRect.origin.x, y: notesChevronRect.origin.y), frameSize: notesChevronRect.size)
    }
    private func getMidnightAssetPDFPath(ofType type : FTDigitalDiaryTemplateType, customVariants variants: FTPaperVariants) -> String {
        var customVariants = variants
        let MidnightScreenType : String =  self.isiPad ? "ipad" :"iphone"
        let isiPad = (MidnightScreenType == "ipad") ? "1" : "0"
        customVariants.selectedDevice = FTDeviceModel(dictionary: ["displayName" : variants.selectedDevice.displayName.displayTitle,
                                                                   "dimension" : variants.selectedDevice.dimension,
                                                                   "identifier" : variants.selectedDevice.identifier,
                                                                   "dimension_land": variants.selectedDevice.dimension_land,
                                                                   "dimension_port":variants.selectedDevice.dimension_port,
                                                                   "isiPad" : isiPad])
        let orientation = customVariants.isLandscape ? "Land" : "Port"
        let screenType = customVariants.selectedDevice.isiPad ? "iPad" : "iPhone"
        let screenSize = FTMidnightDairyFormat.getScreenSize(fromVariants: customVariants)
        let key = type.displayName + "_" + screenType + "_" + orientation +  "_" + "\(screenSize.width)" + "_"
            + "\(screenSize.height)"
        let pdfURL = self.rootPath.appendingPathComponent(key).appendingPathExtension("pdf")
        if FileManager.default.fileExists(atPath: pdfURL.path){
            return pdfURL.path
        }else{
            let templateDiaryInfo = FTMidnightDiaryInfo(templateType: type,customVariants: customVariants)
            let generator = FTMidnightDiaryTemplateAssetGenerator(templateInfo: templateDiaryInfo)
            let generatedPDFURL = generator.generate()
            return generatedPDFURL.path
        }
    }
    class func getScreenSize(fromVariants variants: FTPaperVariants) -> CGSize {
        let dimension = variants.isLandscape ? variants.selectedDevice.dimension_land : variants.selectedDevice.dimension_port
        let measurements = dimension.split(separator: "_")
        return CGSize(width: Int(measurements[0])!, height: Int(Double(measurements[1])!))
    }
    func renderMidnightDiaryPDF(context: CGContext, pdfTemplatePath path:String){
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
        
        self.renderCalendarPage(context: context, months: monthlyFormatter.monthCalendarInfo, calendarYear: self.formatInfo)
        self.diaryPagesInfo.append(FTDiaryPageInfo(type: .calendar))

        self.renderYearPage(context: context, months: monthlyFormatter.monthInfo, calendarYear: formatInfo);
        self.diaryPagesInfo.append(FTDiaryPageInfo(type: .year))
        
        let calendarMonths = monthlyFormatter.monthCalendarInfo;
        calendarMonths.forEach { (calendarMonth) in
            self.renderMonthPage(context: context, monthInfo: calendarMonth, calendarYear: formatInfo)
            self.diaryPagesInfo.append(FTDiaryPageInfo(type: .month))
        }
        
        let weeklyInfo = weeklyFormatter.weeklyInfo;
        weeklyInfo.forEach { (weekInfo) in
            self.renderWeekPage(context: context, weeklyInfo: weekInfo)
            self.renderPrioritiesPage(context: context, weeklyInfo: weekInfo, dayInfo: nil)
            self.renderNotesPage(context: context, weeklyInfo: weekInfo, dayInfo: nil)

            self.diaryPagesInfo.append(FTDiaryPageInfo(type: .week))
            self.diaryPagesInfo.append(FTDiaryPageInfo(type: .weeklyPriorities))
            self.diaryPagesInfo.append(FTDiaryPageInfo(type: .weeklyNotes))
        }
        
        let monthInfo = monthlyFormatter.monthCalendarInfo;
        monthInfo.forEach { (eachMonth) in
            let dayInfo = eachMonth.dayInfo;
            dayInfo.forEach { (eachDayInfo) in
                if eachDayInfo.belongsToSameMonth {
                    self.renderDayPage(context: context, dayInfo: eachDayInfo);
                    self.renderPrioritiesPage(context: context, weeklyInfo: nil, dayInfo: eachDayInfo)
                    self.renderDailyPlanPage(context : context, dayInfo : eachDayInfo)
                    self.renderNotesPage(context: context, weeklyInfo: nil, dayInfo: eachDayInfo)
                    self.renderDailyNotesPage(context : context, dayInfo : eachDayInfo)

                    //pages info
                    if let utcDate = eachDayInfo.date.utcDate() {
                        diaryPagesInfo.append(FTDiaryPageInfo(type: .day,date: utcDate.timeIntervalSinceReferenceDate))
                    }
                    self.diaryPagesInfo.append(FTDiaryPageInfo(type: .dailyPriorities))
                    self.diaryPagesInfo.append(FTDiaryPageInfo(type: .dailyNotes))
                }
            }
        }
    }
    override func calendarOffsetCount() -> Int {
        return self.offsetCount
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
        if self.isiPad {
            pageIndex = self.linkCalendarPages(doc: doc!, index: pageIndex, format: format, startDate: startDate, endDate: endDate, atPoint: atPoint,monthlyFormatter: monthlyFormatter, weeklyFormatter: weeklyFormatter)
            nextIndex += 1
        }
        //Linking the year page
        let yearPage = doc?.page(at: pageIndex);
        if self.isiPad, let calendarPage = doc?.page(at: 0){
            yearPage?.addLinkAnnotation(bounds: format.yearRectsInfo.yearRect, goToPage: calendarPage, at: atPoint)
        }
        var yearMonthsCount = 0
        for monthRect in format.yearRectsInfo.monthRects{
            if let page = (doc?.page(at: yearMonthsCount + nextIndex + offset)) {
                yearPage?.addLinkAnnotation(bounds: monthRect, goToPage: page, at: atPoint)
            }
            yearMonthsCount += 1
        }
        pageIndex += 1
        
        //Linking the month pages
        pageIndex = linkMidnightMonthPages(doc: doc!, index: pageIndex, format: format,
                                             startDate: startDate, endDate: endDate, atPoint: atPoint,monthlyFormatter: monthlyFormatter, weeklyFormatter: weeklyFormatter)
        //Linking the week pages
        pageIndex = linkMidnightWeekPages(_nextIndex: nextIndex, yearMonthsCount: yearMonthsCount, index: pageIndex, doc: doc!, format: format,startDate: startDate, endDate: endDate, atPoint: atPoint,weeklyFormatter: weeklyFormatter)
        
        //Linking the day pages
        linkMidnightDayPages(doc: doc!, startDate: startDate, index: pageIndex, format: format, atPoint: atPoint, yearMonthsCount: yearMonthsCount,monthlyFormatter: monthlyFormatter)
        
        doc?.write(to: url);
    }
    private func linkCalendarPages(doc: PDFDocument, index: Int, format: FTDairyFormat,
                           startDate: Date, endDate: Date, atPoint: CGPoint, monthlyFormatter : FTYearInfoMonthly, weeklyFormatter : FTYearInfoWeekly) -> Int{
        let pageIndex = index
        let nextIndex = 1
        let calendarMonths = monthlyFormatter.monthCalendarInfo;
        let calendarWeeks = weeklyFormatter.weeklyInfo
        var daysBeforeCount = 2 + startDate.numberOfMonths(endDate) + calendarWeeks.count
        daysBeforeCount += 2*(calendarWeeks.count) // for adding weekly priorities and notes page count
        
        let calendarPage = doc.page(at: pageIndex);
        if let page = (doc.page(at:nextIndex)){
            calendarPage?.addLinkAnnotation(bounds: format.calendarRectsInfo.yearRect, goToPage: page, at: atPoint)
        }
        var calenderMonthsCount = 1
        for monthRect in format.calendarRectsInfo.monthRects {
            if let page = (doc.page(at: calenderMonthsCount + nextIndex)){
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
                            let numberOfPrioritiesAndNotes = eachDay.date.daysBetween(date: startDate)*2
                            if let page = doc.page(at: eachDay.date.daysBetween(date: startDate) + daysBeforeCount + numberOfPrioritiesAndNotes) {
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
    private func linkMidnightMonthPages(doc: PDFDocument, index: Int, format: FTDairyFormat,
                                  startDate: Date, endDate: Date, atPoint: CGPoint,monthlyFormatter : FTYearInfoMonthly, weeklyFormatter : FTYearInfoWeekly) -> Int {
        var pageIndex = index
        let calendarMonths = monthlyFormatter.monthCalendarInfo;
        let weeklyFormatter = weeklyFormatter
        var monthRectsCount = 0
        
        let lastDate = calendarMonths[calendarMonths.count - 1].dayInfo[calendarMonths[calendarMonths.count - 1].dayInfo.count - 1].date
        
        var daysBeforeCount = 1 + startDate.numberOfMonths(endDate) + calendarMonths[0].dayInfo[0].date.numberOfWeeks(lastDate)
        if endDate.daysBetween(date: lastDate) + 1 > 7 {
            daysBeforeCount -= 1
        }
        if self.isiPad {
            daysBeforeCount += 1 + weeklyFormatter.weeklyInfo.count*2 // adding calendar, weekly priorities and notes count
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
        let weekBeforeDaysCount : Int = (self.isiPad ? 2 : 1) + calendarMonths.count
        calendarMonths.forEach { (eachMonth) in
            let monthPage = doc.page(at: pageIndex);
            let monthRectsInfo = format.monthRectsInfo[monthRectsCount]
            let weekRectsInfo = monthRectsInfo.weekRects
            if !weekRectsInfo.isEmpty {
                for (weekIndex, weekRect) in weekRectsInfo.enumerated() {
                    let numberofWeeks = eachMonth.dayInfo[weekIndex*7].date.numberOfWeeks(weekcalStartDate) - 1
                    var weekPageIndex = weekBeforeDaysCount + numberofWeeks
                    if self.isiPad {
                        weekPageIndex += numberofWeeks*2
                    }
                    if let page = doc.page(at: weekPageIndex), eachMonth.dayInfo[weekIndex*7].date < endDate {
                        monthPage?.addLinkAnnotation(bounds: weekRect, goToPage: page, at: atPoint)
                    }
                }
            }
            var yearPage = doc.page(at: 0)
            if isiPad {
                yearPage = doc.page(at: 1)
            }
            monthPage?.addLinkAnnotation(bounds: monthRectsInfo.yearRect, goToPage: yearPage!, at : atPoint)
            var dayRectsCount = 0
            eachMonth.dayInfo.forEach({(eachDay) in
                if isBelongToCalendar(currentDate: eachDay.date, startDate: startDate, endDate: endDate) {
                    if eachDay.belongsToSameMonth {
                        if monthRectsInfo.dayRects.count > dayRectsCount {
                            let numberOfPrioritiesAndNotes = eachDay.date.daysBetween(date: startDate)*2
                            var dayIndex = eachDay.date.daysBetween(date: startDate) + daysBeforeCount
                            dayIndex += numberOfPrioritiesAndNotes // adding weekly priorities and notes count
                            if let page = doc.page(at: dayIndex) {
                                monthPage?.addLinkAnnotation(bounds: monthRectsInfo.dayRects[dayRectsCount], goToPage: page, at: atPoint)
                            }
                        }
                        dayRectsCount += 1
                    }
                }
            })
            pageIndex += 1
            monthRectsCount += 1
        }
        return pageIndex
    }
    private func linkMidnightWeekPages(_nextIndex: Int, yearMonthsCount: Int, index: Int, doc: PDFDocument, format:FTDairyFormat,
                                 startDate: Date, endDate: Date, atPoint: CGPoint, weeklyFormatter : FTYearInfoWeekly) -> Int {
        var pageIndex = index
        var nextIndex = _nextIndex
        nextIndex = 1 + yearMonthsCount + weeklyFormatter.weeklyInfo.count
        if self.isiPad {
            nextIndex += 1 + weeklyFormatter.weeklyInfo.count*2 // adding calendar,weekly priorities and notes count
        }
        let weeklyInfo = weeklyFormatter.weeklyInfo;
        var weekRectsCount = 0
        var prioritiesAndNotesCounter = 0
        weeklyInfo.forEach { (weekInfo) in
            let weekPage = doc.page(at: pageIndex);
            let weekRectsInfo:FTDiaryWeekRectsInfo = format.weekRectsInfo[weekRectsCount]
            
            if isBelongToCalendar(currentDate: weekInfo.dayInfo[0].date, startDate: startDate, endDate: endDate){
                var monthTo = weekInfo.dayInfo[0].date.numberOfMonths(startDate)
                if self.isiPad {
                    monthTo += 1 // adding calendar page count
                }
                weekPage?.addLinkAnnotation(bounds: weekRectsInfo.weekStartDaysMonthRect, goToPage: (doc.page(at: monthTo))!, at : atPoint)
            }
            if weekRectsInfo.weekEndDaysMonthRect.size != CGSize.zero,let weekLastDay = weekInfo.dayInfo.last, isBelongToCalendar(currentDate: weekLastDay.date, startDate: startDate, endDate: endDate){
                var  monthTo = weekLastDay.date.numberOfMonths(startDate)
                if self.isiPad {
                    monthTo += 1 // adding calendar page count
                }
                weekPage?.addLinkAnnotation(bounds: weekRectsInfo.weekEndDaysMonthRect, goToPage: (doc.page(at: monthTo ))!, at : atPoint)
            }
            var yearOverviewPage = doc.page(at: 0)
            if self.isiPad {
                yearOverviewPage = doc.page(at: 1)
            }
            weekPage?.addLinkAnnotation(bounds: weekRectsInfo.yearRect, goToPage: yearOverviewPage!, at : atPoint)
            var currentWeekDaysCount=0
            for weekDayRect in weekRectsInfo.weekDayRects{
                var dayIndex = currentWeekDaysCount + nextIndex
                let numberOfPrioritiesAndNotes = prioritiesAndNotesCounter*2
                dayIndex += numberOfPrioritiesAndNotes // adding daily priorities and notes count
                prioritiesAndNotesCounter += 1
                if let page = (doc.page(at: dayIndex)) {
                    weekPage?.addLinkAnnotation(bounds: weekDayRect, goToPage: page, at : atPoint)
                }
                currentWeekDaysCount+=1
            }
            
            if weekRectsInfo.prioritiesRect.size != CGSize.zero , let weekPrioritiesPage = doc.page(at: pageIndex + 1){
                
                weekPage?.addLinkAnnotation(bounds: weekRectsInfo.prioritiesRect, goToPage: weekPrioritiesPage, at: atPoint)
                pageIndex += 1
            }
            if format.weekPrioritiesInfo.weekRect.size != CGSize.zero, let weekPrioritiesPage = doc.page(at: pageIndex),let weekPage = weekPage{
                weekPrioritiesPage.addLinkAnnotation(bounds: format.weekPrioritiesInfo.weekRect, goToPage: weekPage, at: atPoint)
            }
            if format.weekNotesInfo.weekRect.size != CGSize.zero, let weekNotesPage = doc.page(at: pageIndex + 1),let weekPage = weekPage{
                weekNotesPage.addLinkAnnotation(bounds: format.weekPrioritiesInfo.weekRect, goToPage: weekPage, at: atPoint)
            }
            if weekRectsInfo.notesRect.size != CGSize.zero, let notesPage = doc.page(at: pageIndex + 1){
                
                weekPage?.addLinkAnnotation(bounds: weekRectsInfo.notesRect, goToPage: notesPage, at: atPoint)
                pageIndex += 1
            }
            nextIndex += currentWeekDaysCount
            
            pageIndex += 1
            weekRectsCount += 1
        }
        return pageIndex
    }
    private func linkMidnightDayPages(doc: PDFDocument, startDate: Date, index: Int, format: FTDairyFormat, atPoint: CGPoint, yearMonthsCount: Int, monthlyFormatter : FTYearInfoMonthly) {
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
                    
                    var monthPageIndex = eachDayInfo.date.numberOfMonths(startDate);
                    if self.isiPad {
                        monthPageIndex += 1 // as we have a calendar page extra as a first page of black diary
                    }
                    if let page = doc.page(at: monthPageIndex) {
                        dayPage?.addLinkAnnotation(bounds: dayRectsInfo.monthRect, goToPage:  page, at : atPoint)
                    }
                    
                    let weekPage = eachDayInfo.date.numberOfWeeks(weekcalStartDate) - 1;
                    if let page = doc.page(at: 1 + yearMonthsCount + weekPage) {
                        dayPage?.addLinkAnnotation(bounds: dayRectsInfo.weekRect, goToPage:  page, at : atPoint)
                    }
                    
                    let yearPage = self.isiPad ? doc.page(at: 1) : doc.page(at: 0)
                    dayPage?.addLinkAnnotation(bounds: dayRectsInfo.yearRect, goToPage: yearPage!, at : atPoint)
                    
                    if dayRectsInfo.prioritiesRect.size != CGSize.zero , let weekPrioritiesPage = doc.page(at: pageIndex + 1){
                        dayPage?.addLinkAnnotation(bounds: dayRectsInfo.prioritiesRect, goToPage: weekPrioritiesPage, at: atPoint)
                        pageIndex += 1
                    }
                    if dayRectsInfo.dailyPlanRect.size != CGSize.zero , let dailyPlanPage = doc.page(at: pageIndex + 1){
                        dayPage?.addLinkAnnotation(bounds: dayRectsInfo.dailyPlanRect, goToPage: dailyPlanPage, at: atPoint)
                        pageIndex += 1
                    }
                    if format.dailyPrioritiesInfo.dayRect.size != CGSize.zero, let dailyPrioritiesPage = doc.page(at: pageIndex),let dayPage = dayPage{
                        dailyPrioritiesPage.addLinkAnnotation(bounds: format.dailyPrioritiesInfo.dayRect, goToPage: dayPage, at: atPoint)
                    }
                    if format.dailyNotesInfo.dayRect.size != CGSize.zero, let dailyNotesPage = doc.page(at: pageIndex + 1),let dayPage = dayPage{
                        dailyNotesPage.addLinkAnnotation(bounds: format.dailyNotesInfo.dayRect, goToPage: dayPage, at: atPoint)
                    }
                    if dayRectsInfo.notesRect.size != CGSize.zero, let notesPage = doc.page(at: pageIndex + 1){
                        dayPage?.addLinkAnnotation(bounds: dayRectsInfo.notesRect, goToPage: notesPage, at: atPoint)
                        pageIndex += 1
                    }
                    pageIndex += 1
                    dayRectsCount += 1
                }
            }
        }
    }
}
