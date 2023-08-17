//
//  FTFiveMinJournaliPhoneFormat.swift
//  Noteshelf
//
//  Created by Ramakrishna on 05/07/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTStyles

class FTFiveMinJournaliPhoneFormat : FTFiveMinJournalFormat {
    override var isiPad : Bool {
        return false
    }
    override func renderYearPage(context: CGContext, months: [FTMonthInfo], calendarYear: FTYearFormatInfo) {
        super.renderYearPage(context: context, months: months, calendarYear: calendarYear)
        let templateInfo = screenInfo.spacesInfo.yearPageSpacesInfo
        
        var currMonthIndex = CGFloat(0)
        let columnCount = getColumnCount()
        let rowCount = getRowCount()
        let cellWidth = getYearCellWidth(columnCount: columnCount)
        let cellHeight = getYearCellHeight(rowCount: rowCount)
        let font = UIFont.LoraRegular(screenInfo.fontsInfo.yearPageDetails.yearFontSize)
        let minimumFontSize : CGFloat = 16
        let newFontSize = UIFont.getScaledFontSizeFor(font: font, screenSize: currentPageRect.size, minPointSize: minimumFontSize)
        let yearAttrs: [NSAttributedString.Key: Any] = [.font:UIFont.LoraRegular(newFontSize) ,
                                                        .kern: 0.0,
                                                        .foregroundColor: UIColor.init(hexString: "#78787B")]
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
        }
        
        var monthY = currentPageRect.height*templateInfo.baseBoxY/100
        var monthX = currentPageRect.width*templateInfo.baseBoxX/100
        months.forEach { (month) in
            let monthFont = UIFont.montserratFont(for: .bold, with: screenInfo.fontsInfo.yearPageDetails.titleMonthFontSize)
            let monthNewFontSize = UIFont.getScaledFontSizeFor(font: monthFont, screenSize: currentPageRect.size, minPointSize: 8)
            let monthAttrs : [NSAttributedString.Key: Any] = [.font : UIFont.montserratFont(for: .bold, with: monthNewFontSize),
                                                              NSAttributedString.Key.kern : 0.0,
                                                              .foregroundColor : UIColor.init(hexString: "#0B93BE")]
            let monthString = NSMutableAttributedString(string: month.monthTitle.uppercased() , attributes: monthAttrs)
            if formatInfo.customVariants.isLandscape{
                let location = CGPoint(x: monthX + monthString.size().height/2 , y: monthY + monthString.size().height/2)
                monthString.draw(at: location)
                yearRectsInfo.monthRects.append(getLinkRect(location: CGPoint(x: monthX + monthString.size().height/3, y: monthY + monthString.size().height/3), frameSize: CGSize(width: monthString.size().width + monthString.size().height/2 ,height: monthString.size().height + monthString.size().height/2)))
            }
            else {
                let location = CGPoint(x: monthX + monthString.size().height , y: monthY + monthString.size().height)
                monthString.draw(at: location)
                yearRectsInfo.monthRects.append(getLinkRect(location: CGPoint(x: monthX + monthString.size().height/2, y: monthY + monthString.size().height/2), frameSize: CGSize(width: monthString.size().width + monthString.size().height ,height: monthString.size().height + monthString.size().height)))
            }
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
    override func renderMonthPage(context: CGContext, monthInfo: FTMonthlyCalendarInfo, calendarYear: FTYearFormatInfo) {
        super.renderMonthPage(context: context, monthInfo: monthInfo, calendarYear: calendarYear)
        let currentMonthRectsInfo = FTDiaryMonthRectsInfo()
        let templateInfo = screenInfo.spacesInfo.monthPageSpacesInfo
        let yearXPercentage : CGFloat = formatInfo.customVariants.isLandscape ? 3.74 : 5.6
        
        let cellWidth = (currentPageRect.width - (currentPageRect.width*templateInfo.baseBoxX/100) - (currentPageRect.width*templateInfo.boxRightOffset/100) - 6*(currentPageRect.width*templateInfo.cellOffsetX/100))/7
        let cellHeight = (currentPageRect.height - (currentPageRect.height*templateInfo.baseBoxY/100) - (currentPageRect.height*templateInfo.boxBottomOffset/100) -
                            5*(currentPageRect.height*templateInfo.cellOffsetY/100))/6
        let yearFont = UIFont.LoraRegular(screenInfo.fontsInfo.monthPageDetails.yearFontSize)
        let yearNewFontSize = UIFont.getScaledFontSizeFor(font: yearFont, screenSize: currentPageRect.size, minPointSize: 16)
        
        let yearAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.LoraRegular(yearNewFontSize),
                                                        .kern: 0.0,
                                                        .foregroundColor: UIColor.init(hexString: "#0B93BE")]
        
        let yearString = NSMutableAttributedString.init(string: monthInfo.year, attributes: yearAttrs)
        let yearLocation = CGPoint(x: (currentPageRect.width*yearXPercentage/100), y: (currentPageRect.height*templateInfo.monthY/100) )
        yearString.draw(at: yearLocation)
        currentMonthRectsInfo.yearRect = getLinkRect(location: yearLocation, frameSize: yearString.size())
        
        let navigationStringAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.LoraRegular(yearNewFontSize),
                                                                    .kern: 0.0,
                                                                    .foregroundColor: UIColor.init(hexString: "#78787B", alpha: 1.0)]
        
        let navigationString = NSMutableAttributedString.init(string: "/", attributes: navigationStringAttrs)
        let navigationLocation = CGPoint(x: (yearLocation.x) + yearString.size().width + 7, y: (currentPageRect.height*templateInfo.monthY/100) )
        navigationString.draw(at: navigationLocation)
        
        let monthStringAttrs = navigationStringAttrs
        let monthAttrs: [NSAttributedString.Key: Any] = monthStringAttrs
        let monthString = NSMutableAttributedString.init(string: monthInfo.fullMonth, attributes: monthAttrs)
        let monthLocation = CGPoint(x: navigationLocation.x  + navigationString.size().width + 8,
                                    y:(currentPageRect.height*templateInfo.monthY/100))
        monthString.draw(at: monthLocation)
        
        let symbols = getWeekSymbols(monthInfo: monthInfo)
        
        let paragraphStyle = NSMutableParagraphStyle.init()
        paragraphStyle.alignment = .center
        let weekSymbolFont = UIFont.montserratFont(for: .bold, with: screenInfo.fontsInfo.monthPageDetails.dayFontSize)
        let weekSymbolNewFontSize = UIFont.getScaledFontSizeFor(font: weekSymbolFont, screenSize: currentPageRect.size, minPointSize: 7)
        let symbolAttrs: [NSAttributedString.Key : Any] =  [.font :UIFont.montserratFont(for: .bold, with: weekSymbolNewFontSize),
                                                            NSAttributedString.Key.kern : 0.0,
                                                            .foregroundColor : UIColor.init(hexString: "#78787B"),
                                                            .paragraphStyle: paragraphStyle];
        
        var symbolX = (currentPageRect.width*templateInfo.baseBoxX/100)
        symbols.forEach({(symbol) in
            let symbolString = NSMutableAttributedString.init(string: symbol,attributes: symbolAttrs)
            let symbolY =  (currentPageRect.height*templateInfo.baseBoxY/100) - cellHeight/2 - symbolString.size().height/2
            symbolString.draw(in: CGRect(x: symbolX, y:symbolY , width: cellWidth, height: cellHeight))
            symbolX += cellWidth + (currentPageRect.width*templateInfo.cellOffsetX/100)
        }
        )
        
        var dayX = (currentPageRect.width*templateInfo.baseBoxX/100)
        var linkX = (currentPageRect.width*templateInfo.baseBoxX/100)
        var dayY = (currentPageRect.height*templateInfo.baseBoxY/100)
        var index = 1;
        
        monthInfo.dayInfo.forEach({(day) in
            let dayForeGroundColor = day.belongsToSameMonth ? UIColor.init(hexString: "#0B93BE") :UIColor.init(hexString: "#B6B6B9")
            let dayRect = CGRect(x: dayX, y: dayY, width: cellWidth , height: cellHeight)
            self.addBezierPathWithRect(rect: dayRect, toContext: context, title: day.dayString,tileColor: dayForeGroundColor)
            if day.belongsToSameMonth {
                currentMonthRectsInfo.dayRects.append(getLinkRect(location: CGPoint(x: linkX, y: dayY), frameSize: CGSize(width: cellWidth, height: cellHeight)))
            }
            if(index % 7 == 0) {
                dayX = (currentPageRect.width*templateInfo.baseBoxX/100);
                linkX = (currentPageRect.width*templateInfo.baseBoxX/100)
                dayY += cellHeight + (currentPageRect.height*templateInfo.cellOffsetY/100);
            }
            else {
                dayX += cellWidth + (currentPageRect.width*templateInfo.cellOffsetX/100)
                linkX += cellWidth + (currentPageRect.width*templateInfo.cellOffsetX/100)
            }
            index += 1;
        })
        monthRectsInfo.append(currentMonthRectsInfo)
    }
    private func addBezierPathWithRect( rect : CGRect, toContext context : CGContext, title:String?, tileColor : UIColor ){
        let bezierpath = UIBezierPath(roundedRect: rect, cornerRadius: 10)
        context.saveGState()
        context.addPath(bezierpath.cgPath)
        context.translateBy(x: 0, y: CGFloat(currentPageRect.height))
        context.scaleBy(x: 1, y: -1)
        context.setFillColor(UIColor(hexString: "#E1E9E8").cgColor)
        context.fillPath()
        context.restoreGState()
        if let boxTitle = title{
            let paragraphStyle = NSMutableParagraphStyle.init()
            paragraphStyle.alignment = .center
            let dayFont = UIFont.montserratFont(for: .bold, with: screenInfo.fontsInfo.monthPageDetails.dayFontSize)
            let dayNewFontSize = UIFont.getScaledFontSizeFor(font: dayFont, screenSize: currentPageRect.size, minPointSize: 7)
            let textAttribute: [NSAttributedString.Key : Any] = [.font : UIFont.montserratFont(for: .bold, with: dayNewFontSize),
                                                                 .foregroundColor : tileColor,
                                                                 .paragraphStyle : paragraphStyle]
            let dayString = NSMutableAttributedString(string: boxTitle, attributes: textAttribute)
            let location = CGPoint(x: rect.origin.x + rect.width/2 - dayString.size().width/2  , y: rect.origin.y + rect.height/2 - dayString.size().height/2)
            dayString.draw(at: location)
        }
    }
    
    override func renderDayPage(context: CGContext, dayInfo: FTDayInfo) {
        
        if !dayInfo.belongsToSameMonth {
            return
        }
        super.renderDayPage(context: context, dayInfo: dayInfo)
        currentDayRectsInfo = FTDiaryDayRectsInfo()
        let templateInfo = screenInfo.spacesInfo.journalDayPageSpacesInfo
        
        let titleX = currentPageRect.width*templateInfo.baseX/100
        let titleY = currentPageRect.height*templateInfo.baseY/100
        
        let font =  UIFont.LoraRegular(screenInfo.fontsInfo.dayPageDetails.yearFontSize)
        let minimumFontSize : CGFloat = 14
        let titleNewFontSize = UIFont.getScaledFontSizeFor(font: font, screenSize: currentPageRect.size, minPointSize: minimumFontSize)
        let titleAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.LoraRegular(titleNewFontSize),
                                                         NSAttributedString.Key.kern : 0.0,
                                                         .foregroundColor : UIColor.init(hexString: "#78787B")];
        
        let yearStringAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.LoraRegular(titleNewFontSize),
                                                         NSAttributedString.Key.kern : 0.0,
                                                         .foregroundColor : UIColor.init(hexString: "#0B93BE")];
        
        let yearText = "\(dayInfo.yearString)"
        let yearString = NSMutableAttributedString.init(string: yearText, attributes: yearStringAttrs)
        let dayOfMonth = Int(dayInfo.dayString)
        let daySuffix = self.getDaySuffix(dayOfMonth)
        
        let yearRect = CGRect(x: titleX , y: titleY, width: yearString.size().width, height: yearString.size().height)
        yearString.draw(in: yearRect)
        currentDayRectsInfo.yearRect = getLinkRect(location: CGPoint(x: yearRect.origin.x, y: yearRect.origin.y), frameSize: CGSize(width: yearString.size().width, height: yearString.size().height))
        
        let seperatorText = " / "
        let seperatorString = NSAttributedString(string: seperatorText, attributes: titleAttrs)
        let seperatorLocation = CGPoint(x: titleX + yearString.size().width,
                                   y: titleY)
        seperatorString.draw(at: seperatorLocation)
        
        let monthStringAttrs = yearStringAttrs
        let monthText = dayInfo.fullMonthString
        let monthString = NSMutableAttributedString.init(string: monthText, attributes: monthStringAttrs)
        let monthLocation = CGPoint(x: titleX + yearString.size().width + seperatorString.size().width,
                                   y: titleY)
        let monthRect = CGRect(x: titleX + yearString.size().width + seperatorString.size().width, y: titleY, width: monthString.size().width, height: monthString.size().height)
        monthString.draw(in: monthRect)
        currentDayRectsInfo.monthRect = getLinkRect(location: CGPoint(x: monthRect.origin.x, y: monthRect.origin.y), frameSize: monthRect.size)
        let dayText = " " + "\(dayInfo.dayString)" + "\(daySuffix)"
        let dayString = NSMutableAttributedString.init(string: dayText, attributes: titleAttrs)
        let dayLocation = CGPoint(x: monthLocation.x + monthString.size().width,
                                   y: titleY)
        dayString.draw(at: dayLocation)
        dayRectsInfo.append(currentDayRectsInfo)
    }
    override func renderHelpPage(context : CGContext){
        super.renderFiveMinJournalPDF(context: context, pdfTemplatePath: self.helpTemplate)
        
        let isLandscape = self.formatInfo.customVariants.isLandscape
        let quoteYPercentage : CGFloat = isLandscape ? 10.27 : 8.14
        let quoteY = currentPageRect.height*quoteYPercentage/100
        
        let style = NSMutableParagraphStyle.init()
        style.alignment = NSTextAlignment.center
        style.lineBreakMode = .byWordWrapping
        
        let font = UIFont.LoraItalic(11)
        let minimumFontSize : CGFloat = 8
        let quoteNewFontSize = UIFont.getScaledFontSizeFor(font: font, screenSize: currentPageRect.size, minPointSize: minimumFontSize)
        let quoteAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.LoraItalic(quoteNewFontSize),
                                                         NSAttributedString.Key.kern : 0.0,
                                                         .foregroundColor : UIColor.init(hexString: "#78787B")];
        let quoteString=NSAttributedString.init(string: self.helpPageQuote, attributes: quoteAttrs);
        let expectedSize:CGSize=quoteString.requiredSizeForAttributedStringConStraint(to: CGSize(width: quoteString.size().width, height:110))
        quoteString.draw(in: CGRect(x: (currentPageRect.width/2) - (quoteString.size().width/2), y: quoteY, width: quoteString.size().width, height: expectedSize.height))
        
        let authorFont = UIFont.montserratFont(for: .regular, with: 10)
        let authorMinimumFontSize : CGFloat = 8
        let authorNewFontSize = UIFont.getScaledFontSizeFor(font: authorFont, screenSize: currentPageRect.size, minPointSize: authorMinimumFontSize)
        let authorAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.montserratFont(for: .regular, with: authorNewFontSize),
                                                         NSAttributedString.Key.kern : 0.0,
                                                         .foregroundColor : UIColor.init(hexString: "#78787B"),
                                                         .paragraphStyle : style];
        
        let authorString = NSAttributedString.init(string: self.helpPageQuoteAuthor, attributes: authorAttrs);
        let topGapBWQuoteAndAuthor : CGFloat = (self.formatInfo.customVariants.isLandscape ? 7 : 8)
        let authorY = quoteY + expectedSize.height + topGapBWQuoteAndAuthor
        let authorRect = CGRect(x: (currentPageRect.width/2) - (authorString.size().width/2), y: authorY , width: authorString.size().width, height: 12)
        authorString.draw(in: authorRect)
        
        let titleY : CGFloat = isLandscape ? 34 : 27.48
        let titleYValue = currentPageRect.height*titleY/100
        
        
        let titleFont = UIFont.LoraMedium(18)
        let titleMinimumFontSize : CGFloat = 14
        let titleNewFontSize = UIFont.getScaledFontSizeFor(font: titleFont, screenSize: currentPageRect.size, minPointSize: titleMinimumFontSize)
        style.alignment = .justified
        let titleQuoteAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.LoraMedium(titleNewFontSize),
                                                         NSAttributedString.Key.kern : 0.0,
                                                         .foregroundColor : UIColor.init(hexString: "#78787B"),
                                                         .paragraphStyle : style];
        
        let titleString=NSAttributedString.init(string: self.helpPageTitle, attributes: titleQuoteAttrs)
        titleString.draw(in: CGRect(x: (currentPageRect.width/2) - (titleString.size().width/2), y: titleYValue, width: titleString.size().width, height: 38 ))
        
        let highlightsX : CGFloat = isLandscape ? 6.89 : 10.26
        let highlightsY : CGFloat = isLandscape ? 46.82 : 38.95
        let highlightsWidth : CGFloat = isLandscape ? 86.42 : 81.20
        
        let hightlightsXValue = currentPageRect.width*highlightsX/100
        let highlightsYValue = currentPageRect.height*highlightsY/100
        let highightsWidthValue = currentPageRect.width*highlightsWidth/100
        
        let highlightsFont = UIFont.LoraRegular(14)
        let highlightsMinimumFontSize : CGFloat = 11
        let highlightsNewFontSize = UIFont.getScaledFontSizeFor(font: highlightsFont, screenSize: currentPageRect.size, minPointSize: highlightsMinimumFontSize)
        let bulletPointString = NSAttributedString(string: "\u{2022}  ", attributes: [NSAttributedString.Key.font : UIFont.LoraRegular(highlightsNewFontSize)])
        style.maximumLineHeight = 22
        style.alignment = .left
        style.headIndent = bulletPointString.size().width
        style.tabStops = [NSTextTab(textAlignment: .left, location: bulletPointString.size().width)]
        let highlightsAttr  = [
            NSAttributedString.Key.font: UIFont.LoraRegular(highlightsNewFontSize),
            NSAttributedString.Key.foregroundColor: UIColor.init(hexString: "#78787B"),
            NSAttributedString.Key.kern : 0.0,
            NSAttributedString.Key.paragraphStyle : style] as [NSAttributedString.Key : Any]
        let highlights1String = NSAttributedString(string: self.helpPagehighlights[0], attributes: highlightsAttr)
        let highlightsExpectedSize:CGSize = highlights1String.requiredSizeForAttributedStringConStraint(to: CGSize(width: highightsWidthValue, height:42))
        let highlightsRect = CGRect(x: hightlightsXValue, y: highlightsYValue, width: highightsWidthValue, height: highlightsExpectedSize.height)
        highlights1String.draw(in: highlightsRect)
        
        let highlights2String = NSAttributedString(string: self.helpPagehighlights[1], attributes: highlightsAttr)
        let highlights2ExpectedSize:CGSize = highlights2String.requiredSizeForAttributedStringConStraint(to: CGSize(width: highightsWidthValue, height:42))
        let highlights2YValue = highlightsYValue + highlightsExpectedSize.height + 12
        let highlights2Rect = CGRect(x: hightlightsXValue, y: highlights2YValue, width: highightsWidthValue, height: highlights2ExpectedSize.height)
        highlights2String.draw(in: highlights2Rect)
        
        let highlights3String = NSAttributedString(string: self.helpPagehighlights[2], attributes: highlightsAttr)
        let highlights3ExpectedSize:CGSize = highlights3String.requiredSizeForAttributedStringConStraint(to: CGSize(width: highightsWidthValue, height:42))
        let highlights3YValue = highlights2Rect.origin.y + highlights2ExpectedSize.height + 12
        let highlights3Rect = CGRect(x: hightlightsXValue, y: highlights3YValue, width: highightsWidthValue, height: highlights3ExpectedSize.height)
        highlights3String.draw(in: highlights3Rect)
        
        
        
        let infoY : CGFloat = isLandscape ? 4.22 : 6.21
        let infoX : CGFloat = isLandscape ? 5.99 : 9.86
        let infoWidth : CGFloat = isLandscape ? 87.95 : 79.73
        let infoXvalue = currentPageRect.width*infoX/100
        let infoYValue = currentPageRect.height*infoY/100 + highlights3Rect.origin.y + highlights3ExpectedSize.height
        let infoWidthValue = currentPageRect.width*infoWidth/100
        
        let infoStyle = NSMutableParagraphStyle.init()
        infoStyle.alignment = NSTextAlignment.left
        infoStyle.lineBreakMode = .byWordWrapping
        infoStyle.minimumLineHeight = 22
        let infoAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.LoraRegular(highlightsNewFontSize),
                                                         NSAttributedString.Key.kern : 0.0,
                                                         .foregroundColor : UIColor.init(hexString: "#78787B"),
                                                            .paragraphStyle : infoStyle];
        let infoString = NSAttributedString.init(string: helpPageInfoString, attributes: infoAttrs);
        let infoExpectedSize:CGSize = infoString.requiredSizeForAttributedStringConStraint(to: CGSize(width: highightsWidthValue, height:152))
        infoString.draw(in: CGRect(x: infoXvalue, y: infoYValue, width: infoWidthValue, height: infoExpectedSize.height))
    }
    override func addCalendarLinks(url : URL,format : FTDairyFormat,pageRect: CGRect, calenderYear: FTYearFormatInfo, isToDisplayOutOfMonthDate: Bool,monthlyFormatter : FTYearInfoMonthly, weeklyFormatter : FTYearInfoWeekly) {
        let doc = PDFDocument.init(url: url);
        var pageIndex: Int = 2; // As we have help and sample entry page before year page
        var nextIndex:Int = 0;
        let offset = 1;
        let atPoint:CGPoint = CGPoint(x: 0, y: pageRect.height)
        let calendar = NSCalendar.gregorian()
        let startDate = calendar.date(month: calenderYear.startMonth.month, year: calenderYear.startMonth.year)!
        let endFirstDate = calendar.date(month: calenderYear.endMonth.month, year: calenderYear.endMonth.year)!
        let endDate = endFirstDate.offsetDate(endFirstDate.numberOfDaysInMonth() - 1)
        var yearMonthsCount = 0
        nextIndex = 2
        
        //Linking the year page
        let yearPage = doc?.page(at: pageIndex);
        for monthRect in format.yearRectsInfo.monthRects{
            if let page = (doc?.page(at: yearMonthsCount + nextIndex + offset)) {
                yearPage?.addLinkAnnotation(bounds: monthRect, goToPage: page, at: atPoint)
            }
            yearMonthsCount += 1
        }
        pageIndex += 1
        
        //Linking the month pages
        pageIndex = linkMonthPages(doc: doc!, index: pageIndex, format: format,
                                   startDate: startDate, endDate: endDate, atPoint: atPoint,monthlyFormatter: monthlyFormatter, weeklyFormatter: weeklyFormatter)
        //Linking the day pages
        linkDayPages(doc: doc!, startDate: startDate, index: pageIndex, format: format, atPoint: atPoint, yearMonthsCount: yearMonthsCount,monthlyFormatter: monthlyFormatter)
        
        doc?.write(to: url);
    }
    private func linkMonthPages(doc: PDFDocument, index: Int, format: FTDairyFormat,
                                  startDate: Date, endDate: Date, atPoint: CGPoint,monthlyFormatter : FTYearInfoMonthly, weeklyFormatter : FTYearInfoWeekly) -> Int {
        var pageIndex = index
        let calendarMonths = monthlyFormatter.monthCalendarInfo;
        var monthRectsCount = 0
        
        let daysBeforeCount = 3 + startDate.numberOfMonths(endDate) // help, sample entry and year pages are before month pages
        
        calendarMonths.forEach { (eachMonth) in
            let monthPage = doc.page(at: pageIndex);
            let monthRectsInfo = format.monthRectsInfo[monthRectsCount]
            let yearPage = doc.page(at: 2)
            monthPage?.addLinkAnnotation(bounds: monthRectsInfo.yearRect, goToPage: yearPage!, at : atPoint)
            var dayRectsCount = 0
            eachMonth.dayInfo.forEach({(eachDay) in
                if isBelongToCalendar(currentDate: eachDay.date, startDate: startDate, endDate: endDate) {
                    if eachDay.belongsToSameMonth {
                        if monthRectsInfo.dayRects.count > dayRectsCount {
                            let dayIndex = eachDay.date.daysBetween(date: startDate) + daysBeforeCount
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
}
