//
//  FTClassicDiaryiPhoneFormat.swift
//  Noteshelf
//
//  Created by Ramakrishna on 03/08/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTStyles

class FTClassicDiaryiPhoneFormat : FTClassicDiaryFormat{
    
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
        let font = UIFont.SpectralSemiBold(withFontSize: screenInfo.fontsInfo.yearPageDetails.yearFontSize)
        let minimumFontSize : CGFloat = 13
        let newFontSize = UIFont.getScaledFontSizeFor(font: font, screenSize: currentPageRect.size, minPointSize: minimumFontSize)
        let yearAttrs: [NSAttributedString.Key: Any] = [.font:UIFont.SpectralSemiBold(withFontSize:newFontSize) ,
                                                        .kern: 0.0,
                                                        .foregroundColor: UIColor.init(hexString: "#64645F")]
        if let startYear = months.first?.year, let endYear = months.last?.year {
            let lastYearString : String = "\(endYear)"
            let yearString = NSMutableAttributedString.init(string: "\(startYear)" + "-" + lastYearString.suffix(2), attributes: yearAttrs)
            let yearRect = CGRect(x: (currentPageRect.width*50/100) - (yearString.size().width/2), y: (currentPageRect.height*templateInfo.yearY/100), width: yearString.size().width, height: yearString.size().height)
            let yearLocation = CGPoint(x: yearRect.origin.x, y: yearRect.origin.y)
            yearString.draw(at: yearLocation)
        }
        
        var monthY = currentPageRect.height*templateInfo.baseBoxY/100
        var monthX = currentPageRect.width*templateInfo.baseBoxX/100
        months.forEach { (month) in
            let monthFont = UIFont.SpectralMedium(withFontSize:screenInfo.fontsInfo.yearPageDetails.titleMonthFontSize)
            let monthNewFontSize = UIFont.getScaledFontSizeFor(font: monthFont, screenSize: currentPageRect.size, minPointSize: 12)
            let monthAttrs : [NSAttributedString.Key: Any] = [.font : UIFont.SpectralMedium(withFontSize: monthNewFontSize),
                                                              NSAttributedString.Key.kern : 0.0,
                                                              .foregroundColor : UIColor.init(hexString: "#64645F")]
            let monthString = NSMutableAttributedString(string: month.monthTitle , attributes: monthAttrs)
            let location = CGPoint(x: monthX + cellWidth/2 - monthString.size().width/2 , y: (monthY + cellHeight/2 - monthString.size().height/2))
            monthString.draw(at: location)
            yearRectsInfo.monthRects.append(getLinkRect(location: CGPoint(x: monthX + cellWidth/2 - monthString.size().width/2, y: monthY + cellHeight/2 - monthString.size().height/2), frameSize: CGSize(width: monthString.size().width ,height: monthString.size().height)))
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
    override func renderCalendarPage(context: CGContext, months: [FTMonthlyCalendarInfo], calendarYear: FTYearFormatInfo) {
        return
    }
    override func renderMonthPage(context: CGContext, monthInfo: FTMonthlyCalendarInfo, calendarYear: FTYearFormatInfo) {
        super.renderMonthPage(context: context, monthInfo: monthInfo, calendarYear: calendarYear)
        let currentMonthRectsInfo = FTDiaryMonthRectsInfo()
        let templateInfo = screenInfo.spacesInfo.monthPageSpacesInfo
        let monthXPercentage : CGFloat = formatInfo.customVariants.isLandscape ? 3.59 : 5.27
        
        let cellWidth = (currentPageRect.width - (currentPageRect.width*templateInfo.baseBoxX/100) - (currentPageRect.width*templateInfo.boxRightOffset/100) - 6*(currentPageRect.width*templateInfo.cellOffsetX/100))/7
        let cellHeight = (currentPageRect.height - (currentPageRect.height*templateInfo.baseBoxY/100) - (currentPageRect.height*templateInfo.boxBottomOffset/100) -
                            4*(currentPageRect.height*templateInfo.cellOffsetY/100))/6
        let monthFont = UIFont.SpectralSemiBold(withFontSize: screenInfo.fontsInfo.monthPageDetails.monthFontSize)
        let monthNewFontSize = UIFont.getScaledFontSizeFor(font: monthFont, screenSize: currentPageRect.size, minPointSize: 13)
        
        let monthAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.SpectralSemiBold(withFontSize: monthNewFontSize),
                                                        .kern: 0.0,
                                                        .foregroundColor: UIColor.init(hexString: "#64645F")]
        
        let monthString = NSMutableAttributedString.init(string: monthInfo.fullMonth, attributes: monthAttrs)
        let monthLocation = CGPoint(x: (currentPageRect.width*monthXPercentage/100),
                                    y:(currentPageRect.height*templateInfo.monthY/100))
        monthString.draw(at: monthLocation)
        
        let yearString = NSMutableAttributedString.init(string: monthInfo.year, attributes: monthAttrs)
        let yearX = currentPageRect.width - (currentPageRect.width*templateInfo.boxRightOffset/100) - yearString.size().width
        
        let yearLocation = CGPoint(x: yearX, y: (currentPageRect.height*templateInfo.monthY/100) )
        yearString.draw(at: yearLocation)
        currentMonthRectsInfo.yearRect = getLinkRect(location: yearLocation, frameSize: yearString.size())
        
        
        let symbols = getWeekSymbols(monthInfo: monthInfo)
        
        let paragraphStyle = NSMutableParagraphStyle.init()
        paragraphStyle.alignment = .center
        let weekSymbolFont = UIFont.hanumanFont(for: .regular, with: 15)
        let weekSymbolNewFontSize = UIFont.getScaledFontSizeFor(font: weekSymbolFont, screenSize: currentPageRect.size, minPointSize: 12)
        let symbolAttrs: [NSAttributedString.Key : Any] =  [.font :UIFont.hanumanFont(for: .regular, with: weekSymbolNewFontSize),
                                                            NSAttributedString.Key.kern : 0.0,
                                                            .foregroundColor : UIColor.init(hexString: "#AEAEA6"),
                                                            .paragraphStyle: paragraphStyle];
        
        var symbolX = (currentPageRect.width*templateInfo.baseBoxX/100)
        symbols.forEach({(symbol) in
            let symbolString = NSMutableAttributedString.init(string: symbol,attributes: symbolAttrs)
            let symbolY =  (currentPageRect.height*templateInfo.baseBoxY/100) - (currentPageRect.height*templateInfo.cellOffsetY/100) - symbolString.size().height
            symbolString.draw(in: CGRect(x: symbolX, y:symbolY , width: 15, height: cellHeight))
            symbolX += cellWidth + (currentPageRect.width*templateInfo.cellOffsetX/100)
        }
        )
        
        var dayX = (currentPageRect.width*templateInfo.baseBoxX/100)
        var linkX = (currentPageRect.width*templateInfo.baseBoxX/100)
        var dayY = (currentPageRect.height*templateInfo.baseBoxY/100)
        var index = 1;
        
        let dayFont = UIFont.SpectralMedium(withFontSize:screenInfo.fontsInfo.monthPageDetails.dayFontSize)
        let dayNewFontSize = UIFont.getScaledFontSizeFor(font: dayFont, screenSize: currentPageRect.size, minPointSize: 12)
        let dayAttrs: [NSAttributedString.Key : Any] =  [.font :UIFont.SpectralMedium(withFontSize: dayNewFontSize),
                                                            NSAttributedString.Key.kern : 0.0,
                                                            .foregroundColor : UIColor.init(hexString: "#64645F"),
                                                            .paragraphStyle: paragraphStyle]
        var weekNumbers : [Any] = []
        monthInfo.dayInfo.forEach({(day) in
            let dayString = NSMutableAttributedString.init(string: day.dayString,attributes: dayAttrs)
            let dayRect = CGRect(x: dayX, y: dayY, width: 15 , height: cellHeight)
            //self.addBezierPathWithRect(rect: dayRect, toContext: context, title: day.dayString,tileColor: dayForeGroundColor)
            if day.belongsToSameMonth {
                weekNumbers.append(day.weekNumber)
                dayString.draw(in: dayRect)
                currentMonthRectsInfo.dayRects.append(getLinkRect(location: CGPoint(x: linkX - cellHeight/4, y: dayY - cellHeight/4), frameSize: CGSize(width: cellHeight, height: cellHeight)))
            }   
            index += 1;
            if(index > 7) {
                index = 1;
                dayX = (currentPageRect.width*templateInfo.baseBoxX/100);
                linkX = (currentPageRect.width*templateInfo.baseBoxX/100)
                dayY += cellHeight + (currentPageRect.height*templateInfo.cellOffsetY/100);
            }
            else {
                dayX += cellWidth + (currentPageRect.width*templateInfo.cellOffsetX/100)
                linkX += cellWidth + (currentPageRect.width*templateInfo.cellOffsetX/100)
            }
        })
        let weekNumberFont = UIFont.SpectralMedium(withFontSize:13)
        let weekNumberNewFontSize = UIFont.getScaledFontSizeFor(font: weekNumberFont, screenSize: currentPageRect.size, minPointSize: 11)
        let weekNumberAttrs: [NSAttributedString.Key: Any] = [.font :UIFont.SpectralMedium(withFontSize:weekNumberNewFontSize),
                                                              NSAttributedString.Key.kern : 0.0,
                                                              .foregroundColor : UIColor(hexString: "#64645F", alpha: 1.0),
                                                              .paragraphStyle: paragraphStyle];
        let weekNumberXPercentage : CGFloat = formatInfo.customVariants.isLandscape ? 3.59 : 6.93
        let weekNumberX = (currentPageRect.width*weekNumberXPercentage/100)
        var weekNumberY = (currentPageRect.height*templateInfo.baseBoxY/100)
        let weekWidthPercentage : CGFloat = formatInfo.customVariants.isLandscape ? 4.13 : 9.86
        let weekSymbolWidth = (currentPageRect.width*weekWidthPercentage/100)
        weekNumbers = Array(NSOrderedSet(array: weekNumbers))
        for weekNumber in weekNumbers {
            let weekText = "Wk " + "\(weekNumber)"
            let weekString = NSMutableAttributedString.init(string: weekText,attributes: weekNumberAttrs)
            let weekNumberRect = CGRect(x: weekNumberX , y: weekNumberY, width: weekString.size().width , height: cellHeight)
            let location = CGPoint(x: weekNumberRect.origin.x, y: weekNumberRect.origin.y)
            weekString.draw(at: location)
            weekNumberY += cellHeight + (currentPageRect.height*templateInfo.cellOffsetY/100)
            currentMonthRectsInfo.weekRects.append(getLinkRect(location: location, frameSize: weekString.size()))
        }
        monthRectsInfo.append(currentMonthRectsInfo)
    }
    override func renderWeekPage(context: CGContext, weeklyInfo: FTWeekInfo) {
        super.renderWeekPage(context: context, weeklyInfo: weeklyInfo)
        let templateInfo = screenInfo.spacesInfo.weekPageSpacesInfo
        var index = CGFloat(0)
        
        //Header part text rendering
        currentWeekRectInfo = FTDiaryWeekRectsInfo()
        if let weekdaysInfo = weeklyInfo.dayInfo.first {
            let monthX = currentPageRect.size.width*templateInfo.baseBoxX/100
            let monthY = currentPageRect.size.height*templateInfo.titleLineY/100
            
            let monthFont = UIFont.SpectralSemiBold(withFontSize: screenInfo.fontsInfo.weekPageDetails.monthFontSize)
            let monthNewFontSize = UIFont.getScaledFontSizeFor(font: monthFont, screenSize: currentPageRect.size, minPointSize: 13)
            let monthAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.SpectralSemiBold(withFontSize: monthNewFontSize),
                                                            .kern: 0.0,
                                                            .foregroundColor: UIColor.init(hexString:"#64645F")]
            let monthText = weeklyInfo.dayInfo.first?.fullMonthString ?? ""
            let monthString = NSMutableAttributedString.init(string: monthText, attributes: monthAttrs)
            let monthLocation = CGPoint(x: monthX, y: monthY)
            monthString.draw(at: monthLocation)
            currentWeekRectInfo.monthRect = getLinkRect(location: monthLocation, frameSize: CGSize(width: monthString.size().width, height: monthString.size().height))
    
            
            let yearText = weeklyInfo.dayInfo.first?.yearString ?? ""
            let yearString = NSMutableAttributedString.init(string: yearText, attributes: monthAttrs)
            let yearX = currentPageRect.size.width*templateInfo.baseBoxX/100 + currentPageRect.size.width*templateInfo.cellWidth/100 - yearString.size().width
            let yearY = currentPageRect.size.height*templateInfo.titleLineY/100
            yearString.draw(at: CGPoint(x: yearX, y: yearY))
            currentWeekRectInfo.yearRect = getLinkRect(location: CGPoint(x: yearX, y: yearY), frameSize: CGSize(width: yearString.size().width, height: yearString.size().height))
        }
        
        let weekDayfont = UIFont.SpectralMedium(withFontSize:screenInfo.fontsInfo.weekPageDetails.weekFontSize)
        let weekDayNewFontSize = UIFont.getScaledFontSizeFor(font: weekDayfont, screenSize: currentPageRect.size, minPointSize: 12)
        let weekAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.SpectralMedium(withFontSize: weekDayNewFontSize),
                                                        .kern: 0.0,
                                                        .foregroundColor: UIColor.init(hexString:"#64645F")]
        
        let weekDatefont = UIFont.SpectralMedium(withFontSize:screenInfo.fontsInfo.weekPageDetails.dayFontSize)
        let weekDateNewFontSize = UIFont.getScaledFontSizeFor(font: weekDatefont, screenSize: currentPageRect.size, minPointSize: 12)
        let weekDateAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.SpectralMedium(withFontSize: weekDateNewFontSize),
                                                        .kern: 0.0,
                                                        .foregroundColor: UIColor.init(hexString:"#D4D4CB")]
        let weekDayStringXOffsetPercent = 1.18
        let weekDayStringXOffset = currentPageRect.width*CGFloat(weekDayStringXOffsetPercent)/100
        let weekDayStringYOffsetPercent = 0.51
        let weekDayStringYOffset = currentPageRect.width*CGFloat(weekDayStringYOffsetPercent)/100
        var weekDayInfoY = currentPageRect.height*templateInfo.baseBoxY/100
        var weekDayInfoX = currentPageRect.width*templateInfo.baseBoxX/100
        
        var weekDateInfoX = currentPageRect.width*templateInfo.baseBoxX/100
        var weekDateInfoY = currentPageRect.height*templateInfo.baseBoxY/100 + currentPageRect.height*templateInfo.cellHeight/100
        
        
        var weekDayRects : [CGRect] = []
        weeklyInfo.dayInfo.forEach(({(weekDay) in
            let weekDayText = weekDay.weekString
            let weekDayString = NSMutableAttributedString.init(string: weekDayText, attributes: weekAttrs)
            
            let weekDayRect = CGRect(x: weekDayInfoX + weekDayStringXOffset, y: weekDayInfoY + weekDayStringYOffset, width: weekDayString.size().width, height: 21)
            weekDayString.draw(in: weekDayRect)
            
            let weekDateText = weekDay.dayString
            let weekDateString = NSMutableAttributedString.init(string: weekDateText, attributes: weekDateAttrs)
            let weekDateRect = CGRect(x: weekDateInfoX + weekDayStringXOffset, y: weekDateInfoY - weekDayStringYOffset - weekDateString.size().height, width: weekDateString.size().width, height: 18)
            weekDateString.draw(in: weekDateRect)
            
            if isBelongToCalendarYear(currentDate: weekDay.date) {
                weekDayRects.append(getLinkRect(location: CGPoint(x: weekDayRect.origin.x, y: weekDayRect.origin.y),
                                                frameSize: CGSize(width: weekDayString.size().width, height: weekDayString.size().height)))
            }
            index += 1
            
            if index < 6 {
                weekDateInfoY += currentPageRect.height*templateInfo.cellHeight/100
                weekDayInfoY += currentPageRect.height*templateInfo.cellHeight/100 + 1
            }else{
                // As 7th day rect is beside 6th day rect
                let weekDayInfoPercent = 44.99
                weekDayInfoX += currentPageRect.width*CGFloat(weekDayInfoPercent)/100
                weekDateInfoX += currentPageRect.width*CGFloat(weekDayInfoPercent)/100
            }
            
        }))
        currentWeekRectInfo.weekDayRects.append(contentsOf: weekDayRects)
        weekRectsInfo.append(currentWeekRectInfo)
    }
    override func renderDayPage(context: CGContext, dayInfo: FTDayInfo) {
        if !dayInfo.belongsToSameMonth {
            return
        }
        super.renderDayPage(context: context, dayInfo: dayInfo);
        let templateInfo = screenInfo.spacesInfo.dayPageSpacesInfo
        currentDayRectsInfo = FTDiaryDayRectsInfo()
        //Day Rendering
        let dayFont = UIFont.SpectralSemiBold(withFontSize: screenInfo.fontsInfo.dayPageDetails.dayFontSize)
        let dayMinFontSize : CGFloat = 18
        let dayNewFontSize = UIFont.getScaledFontSizeFor(font: dayFont, screenSize: currentPageRect.size, minPointSize: dayMinFontSize)
        let dayAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.SpectralSemiBold(withFontSize:dayNewFontSize),
                                                         NSAttributedString.Key.kern : 0.0,
                                                         .foregroundColor : UIColor.init(hexString: "#64645F")];
        
        
        let dayX = currentPageRect.width*templateInfo.baseX/100
        let dayY = currentPageRect.height*templateInfo.baseY/100
        
        let dayString = NSAttributedString.init(string: dayInfo.dayString, attributes: dayAttrs);
        let expectedSize:CGSize = dayString.requiredSizeForAttributedStringConStraint(to: CGSize(width: 24, height: 33))
        dayString.draw(in: CGRect(x: dayX, y: dayY, width: dayString.size().width, height: expectedSize.height))
        
        let monthFont = UIFont.SpectralSemiBold(withFontSize: screenInfo.fontsInfo.dayPageDetails.monthFontSize)
        let monthMinFontSize : CGFloat = 13
        let monthNewFontSize = UIFont.getScaledFontSizeFor(font: monthFont, screenSize: currentPageRect.size, minPointSize: monthMinFontSize)
        let monthAttr : [NSAttributedString.Key : Any] = [.font : UIFont.SpectralSemiBold(withFontSize:monthNewFontSize),
                                                          NSAttributedString.Key.kern : 0.0,
                                                          .foregroundColor : UIColor.init(hexString: "#64645F")];
        let monthString = NSAttributedString.init(string: dayInfo.fullMonthString, attributes: monthAttr);
        let monthRect = CGRect(x : dayX, y: dayY + dayString.size().height, width: monthString.size().width, height: 24)
        monthString.draw(in: monthRect)
        currentDayRectsInfo.monthRect = getLinkRect(location: CGPoint(x: monthRect.origin.x, y: monthRect.origin.y), frameSize: monthString.size())
        
        let weekFont = UIFont.SpectralMedium(withFontSize: screenInfo.fontsInfo.dayPageDetails.weekFontSize)
        let weekMinFontSize : CGFloat = 10
        let weekNewFontSize = UIFont.getScaledFontSizeFor(font: weekFont, screenSize: currentPageRect.size, minPointSize: weekMinFontSize)
        let weekAttr : [NSAttributedString.Key : Any] = [.font : UIFont.SpectralMedium(withFontSize:weekNewFontSize),
                                                          NSAttributedString.Key.kern : 0.0,
                                                          .foregroundColor : UIColor.init(hexString: "#64645F")];
        let weekString = NSAttributedString.init(string: dayInfo.weekString, attributes: weekAttr);
        let weekRect = CGRect(x : dayX, y: monthRect.origin.y + monthString.size().height + 3, width: weekString.size().width, height: 18)
        weekString.draw(in: weekRect)
        
        let yearXPercentFromRightSide : CGFloat = 4.85
        let yearX = self.currentPageRect.width - (self.currentPageRect.width*yearXPercentFromRightSide/100)
        let yearYPercent : CGFloat = 2.82
        let yearY = self.currentPageRect.height*yearYPercent/100
        let yearFont = UIFont.SpectralSemiBold(withFontSize: screenInfo.fontsInfo.dayPageDetails.yearFontSize)
        let yearMinFontSize : CGFloat = 13
        let yearNewFontSize = UIFont.getScaledFontSizeFor(font: yearFont, screenSize: currentPageRect.size, minPointSize: yearMinFontSize)
        let yearAttr : [NSAttributedString.Key : Any] = [.font : UIFont.SpectralSemiBold(withFontSize:yearNewFontSize),
                                                          NSAttributedString.Key.kern : 0.0,
                                                          .foregroundColor : UIColor.init(hexString: "#64645F")];
        let yearString = NSAttributedString.init(string: dayInfo.yearString, attributes: yearAttr);
        let yearRect = CGRect(x : yearX - yearString.size().width, y: yearY, width: yearString.size().width, height: 24)
        currentDayRectsInfo.yearRect = getLinkRect(location: CGPoint(x: yearRect.origin.x, y: yearRect.origin.y), frameSize: yearString.size())
        yearString.draw(in: yearRect)
        dayRectsInfo.append(currentDayRectsInfo)
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
        
        //Linking the year page
        nextIndex = 1
        let yearPage = doc?.page(at: pageIndex);
        var yearMonthsCount = 0
        for monthRect in format.yearRectsInfo.monthRects{
            if let page = (doc?.page(at: yearMonthsCount + nextIndex + offset)) {
                yearPage?.addLinkAnnotation(bounds: monthRect, goToPage: page, at: atPoint)
            }
            yearMonthsCount += 1
        }
        pageIndex += 1
        
        //Linking the month pages
        pageIndex = linkMonthPages(doc: doc!, index: pageIndex, format: format, isToDisplayOutOfMonthDate: isToDisplayOutOfMonthDate,
                                   startDate: startDate, endDate: endDate, atPoint: atPoint,monthlyFormatter : monthlyFormatter)
        
        //Linking the week pages
        pageIndex = linkWeekPages(_nextIndex: nextIndex, yearMonthsCount: yearMonthsCount, index: pageIndex, doc: doc!, format: format,
                                  startDate: startDate, endDate: endDate, atPoint: atPoint, weeklyFormatter: weeklyFormatter)
        
        //Linking the day pages
        linkDayPages(doc: doc!, startDate: startDate, index: pageIndex, format: format, atPoint: atPoint, yearMonthsCount: yearMonthsCount,monthlyFormatter: monthlyFormatter)
        
        doc?.write(to: url);
    }
}
