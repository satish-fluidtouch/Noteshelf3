//
//  FTFiveMinJournal.swift
//  Noteshelf
//
//  Created by Ramakrishna on 05/07/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTFiveMinJournalFormat : FTDairyFormat {
    var customVariants : FTPaperVariants
    var currentDayRectsInfo: FTDiaryDayRectsInfo = FTDiaryDayRectsInfo()
    
    var isiPad : Bool {
        return true
    }
    let dayPageHeadings : [String] = ["My affirmations for the day","Today I will accomplish","I am thankful for","Three things that made me happy today","Today I learnt"]
    let helpPagehighlights : [String] = ["\u{2022}  A mindfulness journal that helps you set goals for the day and reflect on them.","\u{2022}  Write down your daily thoughts and affirmations in the morning.","\u{2022}  Reflect and ponder upon your achievements and express your gratitude at night."]
    let helpPageInfoString : String = "This journal has a page for every day of the chosen timeline and a yearly calendar view for easy navigation. Make mindful journaling a daily habit to lead a happy and successful life."
    let helpPageTitle : String = "Day and Night Journal"
    let helpPageQuote : String = "“Mindfulness, the Root of Happiness.”"
    let helpPageQuoteAuthor : String = "-Joseph Goldstein"
    
    required init(customVariants : FTPaperVariants){
        self.customVariants = customVariants
        super.init()
    }
    class func getFormatBasedOn(variants: FTPaperVariants) -> FTFiveMinJournalFormat{
        if !variants.selectedDevice.isiPad  || variants.selectedDevice.identifier == "standard4" {
            return FTFiveMinJournaliPhoneFormat(customVariants: variants)
        }
        return  FTFiveMinJournaliPadFormat(customVariants: variants)
    }
    func renderCalendarPage(context : CGContext,months : [FTMonthlyCalendarInfo],calendarYear : FTYearFormatInfo){
        
    }
    func renderHelpPage(context : CGContext){
        
    }
    func renderSamplePage(context : CGContext){
        //_ = self.getFiveMiinuteJournalAssetPDFPath(ofType: .sample, customVariants: formatInfo.customVariants)
        self.renderFiveMinJournalPDF(context: context, pdfTemplatePath: self.sampleTemplate)
    }
    var calendarTemplate: String {
        return getFiveMiinuteJournalAssetPDFPath(ofType: FTFiveMinJournalTemplateType.calendar, customVariants: formatInfo.customVariants)
    }
    override var yearTemplate: String {
        return getFiveMiinuteJournalAssetPDFPath(ofType: FTFiveMinJournalTemplateType.year, customVariants: formatInfo.customVariants)
    }
    override var monthTemplate: String {
        return getFiveMiinuteJournalAssetPDFPath(ofType: FTFiveMinJournalTemplateType.monthly, customVariants: formatInfo.customVariants)
    }
    override var dayTemplate: String {
        let templateType : FTFiveMinJournalTemplateType = .daily
        return getFiveMiinuteJournalAssetPDFPath(ofType: templateType, customVariants: formatInfo.customVariants)
    }
    var helpTemplate: String {
        return getFiveMiinuteJournalAssetPDFPath(ofType: .help, customVariants: formatInfo.customVariants)
    }
    var sampleTemplate: String {
        return getFiveMiinuteJournalAssetPDFPath(ofType: .sample, customVariants: formatInfo.customVariants)
    }
    override func getTemplateBackgroundColor() -> UIColor {
        return UIColor(red: 247/255, green: 247/255, blue: 242/255, alpha: 1.0)
    }
    override func getYearCellHeight(rowCount: CGFloat) -> CGFloat {
        let templateInfo = screenInfo.spacesInfo.yearPageSpacesInfo
        return (currentPageRect.size.height - (currentPageRect.size.height*templateInfo.baseBoxY/100) - (currentPageRect.size.height*templateInfo.boxBottomOffset/100) - ((rowCount - 1) * (currentPageRect.size.height*templateInfo.cellOffsetY/100)))/rowCount
    }
    override func getYearCellWidth(columnCount: CGFloat) -> CGFloat {
        let templateInfo = screenInfo.spacesInfo.yearPageSpacesInfo
        return (currentPageRect.size.width - (2 * (currentPageRect.size.width*templateInfo.baseBoxX/100)) - ((columnCount - 1) * (currentPageRect.size.width*templateInfo.cellOffsetX/100)))/columnCount
    }
    func getFiveMiinuteJournalAssetPDFPath(ofType type : FTFiveMinJournalTemplateType, customVariants variants: FTPaperVariants) -> String {
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
        let pdfURL = self.rootPath.appendingPathComponent(key).appendingPathExtension("pdf")
        if FileManager.default.fileExists(atPath: pdfURL.path){
            return pdfURL.path
        }else{
            let templateDiaryInfo = FTFiveMinJournalTemplateInfo(templateType: type,customVariants: customVariants)
            let generator = FTFiveMinJournalTemplateAssetGenerator(templateInfo: templateDiaryInfo)
            let generatedPDFURL = generator.generate()
            return generatedPDFURL.path
        }
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
    override func renderDayPage(context: CGContext, dayInfo: FTDayInfo) {
        if !dayInfo.belongsToSameMonth {
            return
        }
        super.renderDayPage(context: context, dayInfo: dayInfo);
        let templateInfo = screenInfo.spacesInfo.journalDayPageSpacesInfo

        //Drawing the quote data
        let quoteFont = self.isiPad ? UIFont.LoraRegular(20) : UIFont.LoraRegular(14)
        let quoteminimumFontSize : CGFloat = self.isiPad ? 15 : 11
        let quoteNewFontSize = UIFont.getScaledFontSizeFor(font: quoteFont, screenSize: currentPageRect.size, minPointSize: quoteminimumFontSize)
        var quoteAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.LoraItalic(quoteNewFontSize),
                                                         NSAttributedString.Key.kern : 0.0,
                                                         .foregroundColor : UIColor.init(hexString: "#78787B")];
        
        let quote:FTQuoteInfo = quoteProvider.getQutote()
        
        let style=NSMutableParagraphStyle.init()
        style.alignment = formatInfo.customVariants.isLandscape ? NSTextAlignment.right : NSTextAlignment.center
        style.lineBreakMode = .byWordWrapping
        quoteAttrs[.paragraphStyle] = style
        
        let quoteX = currentPageRect.width*templateInfo.quoteX/100
        let quoteY = currentPageRect.height*templateInfo.quoteY/100
        let quoteRectWidth = currentPageRect.width*templateInfo.quoteWidth/100
        
        let quoteString=NSAttributedString.init(string: quote.quote, attributes: quoteAttrs);
        let expectedSize:CGSize=quoteString.requiredSizeForAttributedStringConStraint(to: CGSize(width: quoteRectWidth, height: 60))
        quoteString.draw(in: CGRect(x: quoteX, y: quoteY, width: quoteRectWidth, height: expectedSize.height))
        
        let authorFont = self.isiPad ? UIFont.LoraItalic(18) :  UIFont.LoraItalic(14)
        let authorMinimumFontSize : CGFloat = self.isiPad ? 15 : 11
        let authorNewFontSize = UIFont.getScaledFontSizeFor(font: authorFont, screenSize: currentPageRect.size, minPointSize: authorMinimumFontSize)
        let authorAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.LoraItalic(authorNewFontSize),
                                                         NSAttributedString.Key.kern : 0.0,
                                                         .foregroundColor : UIColor.init(hexString: "#78787B"),
                                                         .paragraphStyle : style];
        
        let authorString=NSAttributedString.init(string: "-" + quote.author, attributes: authorAttrs);
        let topGapBWQuoteAndAuthor : CGFloat = self.isiPad ? (self.formatInfo.customVariants.isLandscape ? 7 : 10) :(self.formatInfo.customVariants.isLandscape ? 4 : 6)
        let authorY = quoteY + expectedSize.height + topGapBWQuoteAndAuthor
        let authorRect = CGRect(x: quoteX, y: authorY , width: quoteRectWidth, height: 30)
        authorString.draw(in: authorRect)
        
        
        style.alignment = NSTextAlignment.left
        let headingRectWidth = currentPageRect.width*templateInfo.headingWidth/100
        let headingsFont = self.isiPad ? UIFont.LoraRegular(20) : UIFont.LoraRegular(12)
        let headingsminimumFontSize : CGFloat = self.isiPad ? 16 : 10
        let headingsNewFontSize = UIFont.getScaledFontSizeFor(font: headingsFont, screenSize: currentPageRect.size, minPointSize: headingsminimumFontSize)
        
        let headingsAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.LoraRegular(headingsNewFontSize),
                                                         NSAttributedString.Key.kern : 0.0,
                                                         .foregroundColor : UIColor.init(hexString: "#78787B"),
                                                         .paragraphStyle : style];
        var headingX = currentPageRect.width*templateInfo.headingX/100
        let heading1Y = currentPageRect.height*templateInfo.heading1Y/100
        
        let heading1String = NSAttributedString.init(string: dayPageHeadings[0], attributes: headingsAttrs);
        let heading1Rect = CGRect(x: headingX, y: heading1Y , width: headingRectWidth, height: 30)
        heading1String.draw(in: heading1Rect)
        
        
        let heading2Y = currentPageRect.height*templateInfo.heading2Y/100
        
        let heading2String = NSAttributedString.init(string: dayPageHeadings[1], attributes: headingsAttrs);
        let heading2Rect = CGRect(x: headingX, y: heading2Y , width: headingRectWidth, height: 30)
        heading2String.draw(in: heading2Rect)
        
        let heading3Y = currentPageRect.height*templateInfo.heading3Y/100
        
        let heading3String = NSAttributedString.init(string: dayPageHeadings[2], attributes: headingsAttrs);
        let heading3Rect = CGRect(x: headingX, y: heading3Y , width: headingRectWidth, height: 30)
        heading3String.draw(in: heading3Rect)
        
        if !isiPad, formatInfo.customVariants.isLandscape {
            headingX = currentPageRect.width*52.19/100
        }
        let heading4Y = currentPageRect.height*templateInfo.heading4Y/100
        let heading4String = NSAttributedString.init(string: dayPageHeadings[3], attributes: headingsAttrs);
        let heading4Rect = CGRect(x: headingX, y: heading4Y , width: headingRectWidth, height: 30)
        heading4String.draw(in: heading4Rect)
        
        let heading5Y = currentPageRect.height*templateInfo.heading5Y/100
        
        let heading5String = NSAttributedString.init(string: dayPageHeadings[4], attributes: headingsAttrs);
        let heading5Rect = CGRect(x: headingX, y: heading5Y , width: headingRectWidth, height: 30)
        heading5String.draw(in: heading5Rect)
        //dayRectsInfo.append(currentDayRectsInfo)
    }
    //MARK:- PDF Generation and linking between pages
    override func generateCalendar(context : CGContext, monthlyFormatter : FTYearInfoMonthly, weeklyFormatter : FTYearInfoWeekly){
        
        self.renderHelpPage(context: context)
        self.diaryPagesInfo.append(FTDiaryPageInfo(type: .help , isCurrentPage: true))
        
        self.renderSamplePage(context : context)
        self.diaryPagesInfo.append(FTDiaryPageInfo(type: .sample))
        
        self.renderCalendarPage(context: context, months: monthlyFormatter.monthCalendarInfo, calendarYear: self.formatInfo)
    
        self.renderYearPage(context: context, months: monthlyFormatter.monthInfo, calendarYear: formatInfo);
        
        let calendarMonths = monthlyFormatter.monthCalendarInfo;
        calendarMonths.forEach { (calendarMonth) in
            self.renderMonthPage(context: context, monthInfo: calendarMonth, calendarYear: formatInfo)
        }
        
        let monthInfo = monthlyFormatter.monthCalendarInfo;
        monthInfo.forEach { (eachMonth) in
            let dayInfo = eachMonth.dayInfo;
            dayInfo.forEach { (eachDayInfo) in
                if eachDayInfo.belongsToSameMonth {
                    self.renderDayPage(context: context, dayInfo: eachDayInfo);
                    //For Today link
                    if let utcDate = eachDayInfo.date.utcDate() {
                        diaryPagesInfo.append(FTDiaryPageInfo(type: .day,date: utcDate.timeIntervalSinceReferenceDate))
                    }
                }
            }
        }
    }
    override func calendarOffsetCount() -> Int {
        return 0;
    }
    func linkDayPages(doc: PDFDocument, startDate: Date, index: Int, format: FTDairyFormat, atPoint: CGPoint, yearMonthsCount: Int, monthlyFormatter : FTYearInfoMonthly) {
        var pageIndex = index
        let monthInfo = monthlyFormatter.monthCalendarInfo;
        var dayRectsCount = 0
    
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
                    
                    let yearPage = doc.page(at: 2)
                    dayPage?.addLinkAnnotation(bounds: dayRectsInfo.yearRect, goToPage: yearPage!, at : atPoint)
                    
                    let monthPageIndex = 2 + eachDayInfo.date.numberOfMonths(startDate);
            
                    if let page = doc.page(at: monthPageIndex) {
                        dayPage?.addLinkAnnotation(bounds: dayRectsInfo.monthRect, goToPage:  page, at : atPoint)
                    }
                    pageIndex += 1
                    dayRectsCount += 1
                }
            }
        }
    }
}
extension FTFiveMinJournalFormat {
    func getDaySuffix(_ day : Int?) -> String{
        var daySuffix = ""
        switch day {
        case 1, 21, 31:
            daySuffix =  "st"
        case 2, 22:
            daySuffix = "nd"
        case 3, 23:
            daySuffix = "rd"
        default:
            daySuffix = "th"
        }
        return daySuffix
    }
}
extension FTFiveMinJournalFormat {
    func addTodayPillRelativeToRect(_ rect : CGRect, YAxisPercnt : CGFloat, toContext context : CGContext) {
        // Today Pill
        let isLandscape = self.formatInfo.customVariants.isLandscape
        let todayPillXOffsetPercnt : CGFloat = isLandscape ? 1.79 : 2.39
        let todayPillYPercnt : CGFloat = YAxisPercnt
        let todayPillHeightPercnt : CGFloat = isLandscape ? 2.08 : 1.53

        let todayPillXOffset = currentPageRect.width*todayPillXOffsetPercnt/100
        let todayPillY = currentPageRect.height*todayPillYPercnt/100
        let todayPillHeight = currentPageRect.height*todayPillHeightPercnt/100
        let todayPillX = rect.origin.x + rect.width + todayPillXOffset
        let todayPillRect = CGRect(x: todayPillX, y: todayPillY, width: 0, height: todayPillHeight)
        self.addTodayLink(toContext: context, withRect: todayPillRect, withFont: UIFont.LoraRegular(9), withTextColor: UIColor.init(hexString: "#78787B"), WithBackgroundColor: UIColor.init(hexString: "#E1E9E8"))
    }
}
