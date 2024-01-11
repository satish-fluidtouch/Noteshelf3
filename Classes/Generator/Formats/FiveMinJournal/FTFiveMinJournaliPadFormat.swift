//
//  FTFiveMinJournaliPadFormat.swift
//  Noteshelf
//
//  Created by Ramakrishna on 05/07/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTStyles

class FTFiveMinJournaliPadFormat : FTFiveMinJournalFormat {
    override func renderCalendarPage(context: CGContext, months: [FTMonthlyCalendarInfo], calendarYear: FTYearFormatInfo) {
        
        self.renderFiveMinJournalPDF(context: context, pdfTemplatePath: self.calendarTemplate)
        
        let templateInfo = screenInfo.spacesInfo.yearPageSpacesInfo
        var currMonthIndex = CGFloat(0)
        let columnCount = getColumnCount()
        let rowCount = getRowCount()
        let isLandscaped = self.formatInfo.customVariants.isLandscape
        let cellWidth = getYearCellWidth(columnCount: columnCount)
        let monthStringYPercentage : CGFloat = formatInfo.customVariants.isLandscape ? 1.68 : 1.02
        let monthStringY = (currentPageRect.height*monthStringYPercentage)/100
        let monthStringX = (currentPageRect.width*2.03)/100
        let weekStringY = isLandscaped ? (currentPageRect.height*1.25)/100 : (currentPageRect.height*0.92)/100
        let weekDayStringY = isLandscaped ? (currentPageRect.height*4.33)/100 : (currentPageRect.height*3.37)/100
        
        let yearFont = UIFont.LoraRegular(screenInfo.fontsInfo.yearPageDetails.yearFontSize)
        let yearNewFontSize = UIFont.getScaledFontSizeFor(font: yearFont, screenSize: currentPageRect.size, minPointSize: 33)
        let yearAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.LoraRegular(yearNewFontSize),
                                                        .kern: 0.0,
                                                        .foregroundColor: UIColor.init(hexString: "#78787B")]
        var yearRect : CGRect = .zero
        if let startYear = months.first?.year {
            var year: String = "\(startYear)"
            if let endYear = months.last?.year, endYear != startYear {
                let endYearXX = "\(endYear)".suffix(2)
                year = "\(startYear)" +  "-" + "\(endYearXX)"
            }
            let yearString = NSMutableAttributedString.init(string: year, attributes: yearAttrs)
            yearRect = CGRect(x: (currentPageRect.width*templateInfo.baseBoxX/100), y: (currentPageRect.height*templateInfo.yearY/100), width: yearString.size().width, height: yearString.size().height)
            let yearLocation = CGPoint(x: yearRect.origin.x, y: yearRect.origin.y)
            yearString.draw(at: yearLocation)
            calendarRectsInfo.yearRect = getLinkRect(location: CGPoint(x: yearLocation.x, y: yearLocation.y), frameSize: CGSize(width: yearRect.width   ,height: yearRect.height))
        }
        
        var monthY = currentPageRect.height*templateInfo.baseBoxY/100 + monthStringY
        var dayRects : [CGRect] = []
        months.forEach { (month) in
            dayRects.removeAll()
            let monthFont = UIFont.montserratFont(for: .bold, with: screenInfo.fontsInfo.yearPageDetails.titleMonthFontSize)
            let monthNewFontSize = UIFont.getScaledFontSizeFor(font: monthFont, screenSize: currentPageRect.size, minPointSize: 10)
            let monthAttrs : [NSAttributedString.Key: Any] = [.font : UIFont.montserratFont(for: .bold, with: monthNewFontSize),
                                                              NSAttributedString.Key.kern : 0.0,
                                                              .foregroundColor : UIColor.init(hexString: "#78787B")]
            let monthString = NSMutableAttributedString(string: month.fullMonth.uppercased(), attributes: monthAttrs)
            let widthFactor = currMonthIndex.truncatingRemainder(dividingBy: columnCount) * (cellWidth + (currentPageRect.size.width*templateInfo.cellOffsetX/100))
            let cellWidth = getYearCellWidth(columnCount: columnCount)
            let cellHeight = getYearCellHeight(rowCount: rowCount)
            let dayCellWidth = (cellWidth - 2*monthStringX)/7
            let dayCellHeight = (cellHeight - (currentPageRect.height*3.59)/100 - (isLandscaped ? (currentPageRect.height*1.57)/100 : (currentPageRect.height*1.22)/100))/7
            
            let monthX = (currentPageRect.size.width*templateInfo.baseBoxX/100) + widthFactor + monthStringX
            let location = CGPoint(x: monthX + dayCellWidth/3, y: monthY)
            monthString.draw(at: location)
            
            let symbols = getWeekSymbols(monthInfo: month)
            
            let paragraphStyle = NSMutableParagraphStyle.init()
            paragraphStyle.alignment = .center
            let weekSymbolFont = UIFont.montserratFont(for: .bold, with: 10)
            let weekSymbolNewFontSize = UIFont.getScaledFontSizeFor(font: weekSymbolFont, screenSize: currentPageRect.size, minPointSize: 7)
            
            let symbolAttrs: [NSAttributedString.Key : Any] =  [.font :UIFont.montserratFont(for: .bold, with: weekSymbolNewFontSize),
                                                                NSAttributedString.Key.kern : 0.0,
                                                                .foregroundColor : UIColor.init(hexString: "#979494"),
                                                                .paragraphStyle: paragraphStyle];
            
            var symbolX = (currentPageRect.size.width*templateInfo.baseBoxX/100) + widthFactor + monthStringX
            symbols.forEach({(symbol) in
                let symbolString = NSMutableAttributedString.init(string: symbol,attributes: symbolAttrs)
                let symbolY = monthY + monthString.size().height + weekStringY
                symbolString.draw(in: CGRect(x: symbolX, y:symbolY , width: dayCellWidth, height: dayCellHeight))
                symbolX += dayCellWidth
            }
            )
            
            var dayX = (currentPageRect.size.width*templateInfo.baseBoxX/100) + widthFactor + monthStringX
            var dayY = monthY + monthString.size().height + weekDayStringY
            var index = 1;
            
            let dayFont = UIFont.montserratFont(for: .bold, with: 9)
            let dayNewFontSize = UIFont.getScaledFontSizeFor(font: dayFont, screenSize: currentPageRect.size, minPointSize: 7)
            
            month.dayInfo.forEach({(day) in
                
                
                if day.belongsToSameMonth {
                    let dayAttrs: [NSAttributedString.Key: Any] = [.font :UIFont.montserratFont(for: .bold, with: dayNewFontSize),
                                                                   NSAttributedString.Key.kern : 0.0,
                                                                   .foregroundColor : UIColor.init(hexString: "#0B93BE"),
                                                                   .paragraphStyle: paragraphStyle];
                    let dayString = NSMutableAttributedString.init(string: day.dayString, attributes: dayAttrs)
                    let drawRect = CGRect(x: dayX , y: dayY , width: dayCellWidth, height: dayCellHeight)
                    dayString.draw(in: drawRect)
                    //dayRects.append(drawRect)
                    dayRects.append(getLinkRect(location: CGPoint(x: dayX, y: dayY), frameSize: CGSize(width: dayCellWidth, height: dayCellHeight)))
                }
                index += 1;
                if(index > 7) {
                    index = 1;
                    dayX = (currentPageRect.size.width*templateInfo.baseBoxX/100) + widthFactor + monthStringX
                    dayY += dayCellHeight
                }
                else {
                    dayX += dayCellWidth
                }
            })
            calendarRectsInfo.dayRects.append(dayRects)
            currMonthIndex+=1
            let numberOfColunms = columnCount
            if currMonthIndex.truncatingRemainder(dividingBy: numberOfColunms) == 0{
                monthY += cellHeight + (currentPageRect.height*templateInfo.cellOffsetY/100)
            }
        }
        // Today Pill
        let todayPillYPercnt : CGFloat = self.formatInfo.customVariants.isLandscape ? 10.51 : 8.58
        self.addTodayPillRelativeToRect(yearRect, YAxisPercnt : todayPillYPercnt, toContext : context)
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
        
        let font = UIFont.LoraRegular(screenInfo.fontsInfo.dayPageDetails.yearFontSize)
        let minimumFontSize : CGFloat = 20
        let titleNewFontSize = UIFont.getScaledFontSizeFor(font: font, screenSize: currentPageRect.size, minPointSize: minimumFontSize)
        let titleAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.LoraRegular(titleNewFontSize),
                                                         NSAttributedString.Key.kern : 0.0,
                                                         .foregroundColor : UIColor.init(hexString: "#78787B")];
        let yearAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.LoraRegular(titleNewFontSize),
                                                         NSAttributedString.Key.kern : 0.0,
                                                         .foregroundColor : UIColor.init(hexString: "#0B93BE")];
        let yearText = "\(dayInfo.yearString)"
        let yearString = NSMutableAttributedString.init(string: yearText, attributes: yearAttrs)
        let dayOfMonth = Int(dayInfo.dayString)
        let daySuffix = self.getDaySuffix(dayOfMonth)
        let dayAndMonthText = "Date : " + "\(dayInfo.fullMonthString)" + " " + "\(dayInfo.dayString)" + "\(daySuffix)" + ", "
        let dayAndMonthString = NSMutableAttributedString.init(string: dayAndMonthText, attributes: titleAttrs)
        let dayAndMonthRect = CGRect(x: titleX, y: titleY, width: dayAndMonthString.size().width, height: dayAndMonthString.size().height)
        dayAndMonthString.draw(in: dayAndMonthRect)
        let yearRect = CGRect(x: dayAndMonthRect.origin.x + dayAndMonthRect.size.width, y: titleY, width: yearString.size().width, height: yearString.size().height)
        let yearLocation = CGPoint(x: yearRect.origin.x, y: yearRect.origin.y)
        yearString.draw(in: yearRect)
        currentDayRectsInfo.yearRect = getLinkRect(location: yearLocation, frameSize: yearRect.size)
        dayRectsInfo.append(currentDayRectsInfo)

        // Today Pill
        let todayPillYPercnt : CGFloat = self.formatInfo.customVariants.isLandscape ? 9.48 : 8.20
        self.addTodayPillRelativeToRect(yearRect, YAxisPercnt : todayPillYPercnt, toContext : context)
    }
    override func renderYearPage(context: CGContext, months: [FTMonthInfo], calendarYear: FTYearFormatInfo) {
        if isiPad {
            return
        }
    }
    override func renderMonthPage(context: CGContext, monthInfo: FTMonthlyCalendarInfo, calendarYear: FTYearFormatInfo) {
        if isiPad {
            return
        }
    }
    override func renderHelpPage(context : CGContext){
        super.renderFiveMinJournalPDF(context: context, pdfTemplatePath: self.helpTemplate)
        
        let isLandscape = self.formatInfo.customVariants.isLandscape
        let quoteXPercentage : CGFloat = isLandscape ? 17.44 : 11.51
        let quoteYPercentage : CGFloat = isLandscape ? 12.01 : 12.21
        let quoteWidthPercentage : CGFloat = isLandscape ? 65.01 : 79.61
        
        let quoteX = currentPageRect.width*quoteXPercentage/100
        let quoteY = currentPageRect.height*quoteYPercentage/100
        let quoteWidth = currentPageRect.width*quoteWidthPercentage/100
        
        let style = NSMutableParagraphStyle.init()
        style.alignment = NSTextAlignment.center
        style.lineBreakMode = .byWordWrapping
        
        
        var font = UIFont.LoraItalic(25)
        var minimumFontSize : CGFloat = 20
        if self.formatInfo.customVariants.selectedDevice.identifier == "standard1" || self.formatInfo.customVariants.selectedDevice.identifier == "standard2"{
            font = UIFont.LoraItalic(18)
            minimumFontSize = 15
        }
        
        let quoteNewFontSize = UIFont.getScaledFontSizeFor(font: font, screenSize: currentPageRect.size, minPointSize: minimumFontSize)
        let quoteAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.LoraItalic(quoteNewFontSize),
                                                         NSAttributedString.Key.kern : 0.0,
                                                         .foregroundColor : UIColor.init(hexString: "#78787B")];
        let quoteString=NSAttributedString.init(string: self.helpPageQuote, attributes: quoteAttrs);
        let expectedSize:CGSize=quoteString.requiredSizeForAttributedStringConStraint(to: CGSize(width: quoteWidth, height:110))
        quoteString.draw(in: CGRect(x: (currentPageRect.width/2) - (quoteString.size().width/2), y: quoteY, width: quoteWidth, height: expectedSize.height))
        
        var authorFont = UIFont.montserratFont(for: .regular, with: 22)
        var authorMinimumFontSize : CGFloat = 18
        if self.formatInfo.customVariants.selectedDevice.identifier == "standard1" || self.formatInfo.customVariants.selectedDevice.identifier == "standard2"{
            authorFont = UIFont.montserratFont(for: .regular, with: 14)
            authorMinimumFontSize = 12
        }
        
        let authorNewFontSize = UIFont.getScaledFontSizeFor(font: authorFont, screenSize: currentPageRect.size, minPointSize: authorMinimumFontSize)
        let authorAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.montserratFont(for: .regular, with: authorNewFontSize),
                                                         NSAttributedString.Key.kern : 0.0,
                                                         .foregroundColor : UIColor.init(hexString: "#78787B"),
                                                         .paragraphStyle : style];
        
        let authorString = NSAttributedString.init(string: self.helpPageQuoteAuthor, attributes: authorAttrs);
        let topGapBWQuoteAndAuthor : CGFloat = (self.formatInfo.customVariants.isLandscape ? 7 : 10)
        let authorY = quoteY + expectedSize.height + topGapBWQuoteAndAuthor
        let authorRect = CGRect(x: quoteX, y: authorY , width: quoteWidth, height: 27)
        authorString.draw(in: authorRect)
        
        let titleY : CGFloat = isLandscape ? 36.62 : 37.97
        let titleYValue = currentPageRect.height*titleY/100
        
        
        var titleFont = UIFont.LoraRegular(35)
        var titleMinimumFontSize : CGFloat = 30
        if self.formatInfo.customVariants.selectedDevice.identifier == "standard1" || self.formatInfo.customVariants.selectedDevice.identifier == "standard2"{
            titleFont = UIFont.LoraRegular(30)
            titleMinimumFontSize = 25
        }
        
        let titleNewFontSize = UIFont.getScaledFontSizeFor(font: titleFont, screenSize: currentPageRect.size, minPointSize: titleMinimumFontSize)

        let titleQuoteAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.LoraRegular(titleNewFontSize),
                                                         NSAttributedString.Key.kern : 0.0,
                                                         .foregroundColor : UIColor.init(hexString: "#78787B"),
                                                         ];
        
        let titleString=NSAttributedString.init(string: self.helpPageTitle, attributes: titleQuoteAttrs)
        titleString.draw(in: CGRect(x: (currentPageRect.width/2) - (titleString.size().width/2), y: titleYValue, width: titleString.size().width, height: titleString.size().height ))
        
        let highlightsX : CGFloat = isLandscape ? 7.64 : 7.91
        let highlightsY : CGFloat = isLandscape ? 46.75 : 45.41
        let highlightsWidth : CGFloat = isLandscape ? 86.42 : 84.17
        
        let hightlightsXValue = currentPageRect.width*highlightsX/100
        let highlightsYValue = currentPageRect.height*highlightsY/100
        let highightsWidthValue = currentPageRect.width*highlightsWidth/100
        
        var highlightsFont = UIFont.LoraRegular(25)
        var highlightsMinimumFontSize : CGFloat = 18
        if self.formatInfo.customVariants.selectedDevice.identifier == "standard1" || self.formatInfo.customVariants.selectedDevice.identifier == "standard2" {
            highlightsFont = UIFont.LoraRegular(18)
            highlightsMinimumFontSize = 18
        }
        let highlightsNewFontSize = UIFont.getScaledFontSizeFor(font: highlightsFont, screenSize: currentPageRect.size, minPointSize: highlightsMinimumFontSize)
        let bulletPointString = NSAttributedString(string: "\u{2022}  ", attributes: [NSAttributedString.Key.font : UIFont.LoraRegular(highlightsNewFontSize)])
        style.maximumLineHeight = 38
        style.alignment = .left
        style.headIndent = bulletPointString.size().width
        style.tabStops = [NSTextTab(textAlignment: .left, location: bulletPointString.size().width)]
        let highlightsAttr  = [
            NSAttributedString.Key.font: UIFont.LoraRegular(highlightsNewFontSize),
            NSAttributedString.Key.foregroundColor: UIColor.init(hexString: "#78787B"),
            NSAttributedString.Key.kern : 0.0,
            NSAttributedString.Key.paragraphStyle : style] as [NSAttributedString.Key : Any]
        let highlights1String = NSAttributedString(string: self.helpPagehighlights[0], attributes: highlightsAttr)
        let highlightsExpectedSize:CGSize = highlights1String.requiredSizeForAttributedStringConStraint(to: CGSize(width: highightsWidthValue, height:68))
        let highlightsRect = CGRect(x: hightlightsXValue, y: highlightsYValue, width: highightsWidthValue, height: highlightsExpectedSize.height)
        highlights1String.draw(in: highlightsRect)
        
        let highlights2String = NSAttributedString(string: self.helpPagehighlights[1], attributes: highlightsAttr)
        let highlights2ExpectedSize:CGSize = highlights2String.requiredSizeForAttributedStringConStraint(to: CGSize(width: highightsWidthValue, height:68))
        let highlights2YValue = highlightsYValue + highlightsExpectedSize.height + 15
        let highlights2Rect = CGRect(x: hightlightsXValue, y: highlights2YValue, width: highightsWidthValue, height: highlights2ExpectedSize.height)
        highlights2String.draw(in: highlights2Rect)
        
        let highlights3String = NSAttributedString(string: self.helpPagehighlights[2], attributes: highlightsAttr)
        let highlights3ExpectedSize:CGSize = highlights3String.requiredSizeForAttributedStringConStraint(to: CGSize(width: highightsWidthValue, height:68))
        let highlights3YValue = highlights2Rect.origin.y + highlights2ExpectedSize.height + 15
        let highlights3Rect = CGRect(x: hightlightsXValue, y: highlights3YValue, width: highightsWidthValue, height: highlights3ExpectedSize.height)
        highlights3String.draw(in: highlights3Rect)
        
        
        
        let infoY : CGFloat = isLandscape ? 5.19 : 3.81
        let infoX : CGFloat = isLandscape ? 7.19 : 6.59
        let infoWidth : CGFloat = isLandscape ? 86.81 : 85.52
        let infoYValue = currentPageRect.height*infoY/100 + highlights3Rect.origin.y + highlights3ExpectedSize.height
        let infoXvalue = currentPageRect.width*infoX/100
        let infoWidthValue = currentPageRect.width*infoWidth/100
        
        let infoStyle = NSMutableParagraphStyle.init()
        infoStyle.lineBreakMode = .byWordWrapping
        infoStyle.minimumLineHeight = 38
        infoStyle.alignment = .left
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
        var pageIndex: Int = 2; // As we have help and sample entry page before calendar page
        var nextIndex:Int = 0;
        let offset = 0;
        let atPoint:CGPoint = CGPoint(x: 0, y: pageRect.height)
        let calendar = NSCalendar.gregorian()
        let startDate = calendar.date(month: calenderYear.startMonth.month, year: calenderYear.startMonth.year)!
        let endFirstDate = calendar.date(month: calenderYear.endMonth.month, year: calenderYear.endMonth.year)!
        let endDate = endFirstDate.offsetDate(endFirstDate.numberOfDaysInMonth() - 1)
        let yearMonthsCount = 0
        nextIndex = 1
        
        //Linking the calendar page
            pageIndex = self.linkCalendarPages(doc: doc!, index: pageIndex, format: format, startDate: startDate, endDate: endDate, atPoint: atPoint,monthlyFormatter: monthlyFormatter, weeklyFormatter: weeklyFormatter)
            nextIndex += 1

        //Linking the day pages
        self.linkDayPages(doc: doc!, startDate: startDate, index: pageIndex, format: format, atPoint: atPoint, yearMonthsCount: yearMonthsCount,monthlyFormatter: monthlyFormatter)
        
        doc?.write(to: url);
    }
    private func linkCalendarPages(doc: PDFDocument, index: Int, format: FTDairyFormat,
                           startDate: Date, endDate: Date, atPoint: CGPoint, monthlyFormatter : FTYearInfoMonthly, weeklyFormatter : FTYearInfoWeekly) -> Int{
        let pageIndex = index
        let calendarMonths = monthlyFormatter.monthCalendarInfo;
        let daysBeforeCount = 3
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
}
