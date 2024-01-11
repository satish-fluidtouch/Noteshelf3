//
//  FTClassicDiaryiPadFormat.swift
//  Noteshelf
//
//  Created by Ramakrishna on 03/08/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

class FTClassicDiaryiPadFormat : FTClassicDiaryFormat{
    
    override var isiPad : Bool {
        return true
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
        let yearMonthsCount = startDate.numberOfMonths(endDate)
        nextIndex = 1
        
        //Linking the calendar page
        pageIndex = self.linkCalendarPages(doc: doc!, index: pageIndex, format: format, startDate: startDate, endDate: endDate, atPoint: atPoint,monthlyFormatter: monthlyFormatter, weeklyFormatter: weeklyFormatter)
        
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
    override func renderYearPage(context: CGContext, months: [FTMonthInfo], calendarYear: FTYearFormatInfo) {
        return
    }
    override func renderCalendarPage(context: CGContext, months: [FTMonthlyCalendarInfo], calendarYear: FTYearFormatInfo) {
        
        self.renderFiveMinJournalPDF(context: context, pdfTemplatePath: self.calendarTemplate)
        self.diaryPagesInfo.append(FTDiaryPageInfo(type: .calendar))
        
        let templateInfo = screenInfo.spacesInfo.yearPageSpacesInfo
        var currMonthIndex = CGFloat(0)
        let columnCount = getColumnCount()
        let rowCount = getRowCount()
        let cellWidth = getYearCellWidth(columnCount: columnCount)
        let monthStringYPercentage : CGFloat = formatInfo.customVariants.isLandscape ? 1.50 : 1.02
        let monthStringY = (currentPageRect.height*monthStringYPercentage)/100
        let monthStringX = (currentPageRect.width*2.03)/100
        let weekStringY = (currentPageRect.height*1.09)/100
        let weekDayStringY = (currentPageRect.height*3.40)/100
        let landscaped = formatInfo.customVariants.isLandscape
        
        let yearFont = UIFont.SpectralMedium(withFontSize:screenInfo.fontsInfo.yearPageDetails.yearFontSize)
        let yearNewFontSize = UIFont.getScaledFontSizeFor(font: yearFont, screenSize: currentPageRect.size, minPointSize: 18)
        let yearAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.SpectralMedium(withFontSize:yearNewFontSize),
                                                        .kern: 0.0,
                                                        .foregroundColor: UIColor.init(hexString: "#64645F")]
        if let diaryStartYear = months.first?.year, let diaryEndYear = months.last?.year{
            let yearText = diaryStartYear + "-" + diaryEndYear.suffix(2)
            let yearString = NSMutableAttributedString.init(string: yearText, attributes: yearAttrs)
            let yearXValue = currentPageRect.width*CGFloat(50)/100 - yearString.size().width/2
            var yearY : CGFloat = templateInfo.yearY
            if formatInfo.customVariants.selectedDevice.identifier == "standard4" && landscaped {
                yearY = 4.15
            }
            let yearRect = CGRect(x: yearXValue, y: (currentPageRect.height*yearY/100), width: yearString.size().width, height: yearString.size().height)
            let yearLocation = CGPoint(x: yearRect.origin.x, y: yearRect.origin.y)
            yearString.draw(at: yearLocation)
            calendarRectsInfo.yearRect = getLinkRect(location: CGPoint(x: yearLocation.x, y: yearLocation.y), frameSize: CGSize(width: yearRect.width   ,height: yearRect.height))
        }
        var baseBoxY  : CGFloat = templateInfo.baseBoxY
        if formatInfo.customVariants.selectedDevice.identifier == "standard4" && landscaped {
            baseBoxY = 14.67
        }
        var monthY = currentPageRect.height*baseBoxY/100 + monthStringY
        var dayRects : [CGRect] = []
        months.forEach { (month) in
            dayRects.removeAll()
            let selectedDeviceIdentifier = formatInfo.customVariants.selectedDevice.identifier
            let needsFontScaling : Bool = (selectedDeviceIdentifier == "standard1" || selectedDeviceIdentifier == "standard2" || selectedDeviceIdentifier == "standard4")
            
            let monthFont = needsFontScaling ? UIFont.SpectralMedium(withFontSize: 11) :
            UIFont.SpectralMedium(withFontSize:screenInfo.fontsInfo.yearPageDetails.titleMonthFontSize)
            let monthMinFont : CGFloat = needsFontScaling ? 8 : 10
            let monthNewFontSize = UIFont.getScaledFontSizeFor(font: monthFont, screenSize: currentPageRect.size, minPointSize: monthMinFont)
            let monthAttrs : [NSAttributedString.Key: Any] = [.font : UIFont.SpectralMedium(withFontSize: monthNewFontSize),
                                                              NSAttributedString.Key.kern : 0.0,
                                                              .foregroundColor : UIColor.init(hexString: "#64645F")]
            let monthString = NSMutableAttributedString(string: month.fullMonth.uppercased(), attributes: monthAttrs)
            let widthFactor = currMonthIndex.truncatingRemainder(dividingBy: columnCount) * (cellWidth + (currentPageRect.size.width*templateInfo.cellOffsetX/100))
            let cellWidth = getYearCellWidth(columnCount: columnCount)
            var boxBottomOffset : CGFloat = templateInfo.boxBottomOffset
            if formatInfo.customVariants.selectedDevice.identifier == "standard4" && landscaped {
                boxBottomOffset = 7.14
            }
            let cellHeight = (currentPageRect.size.height - (currentPageRect.size.height*templateInfo.baseBoxY/100) - (currentPageRect.size.height*boxBottomOffset/100) - ((rowCount - 1) * (currentPageRect.size.height*templateInfo.cellOffsetY/100)))/rowCount
            let dayCellWidth = (cellWidth - 2*monthStringX)/7
            let dayCellHeight = (cellHeight - (currentPageRect.height*3.59)/100 - (currentPageRect.height*1.29)/100)/7
            
            let monthX = (currentPageRect.size.width*templateInfo.baseBoxX/100) + widthFactor + monthStringX
            let location = CGPoint(x: monthX + dayCellWidth/3, y: monthY)
            monthString.draw(at: location)
            
            calendarRectsInfo.monthRects.append(getLinkRect(location: location, frameSize: CGSize(width: monthString.size().width, height: monthString.size().height)))
            
            let symbols = getWeekSymbols(monthInfo: month)
            
            let paragraphStyle = NSMutableParagraphStyle.init()
            paragraphStyle.alignment = .center
            
            let weekSymbolFont = needsFontScaling ? UIFont.hanumanFont(for: .bold, with: 10) : UIFont.hanumanFont(for: .bold, with: 11)
            let weekSymbolNewFontSize = UIFont.getScaledFontSizeFor(font: weekSymbolFont, screenSize: currentPageRect.size, minPointSize: 8)
            
            let symbolAttrs: [NSAttributedString.Key : Any] =  [.font :UIFont.hanumanFont(for: .bold, with: weekSymbolNewFontSize),
                                                                NSAttributedString.Key.kern : 0.0,
                                                                .foregroundColor : UIColor.init(hexString: "#AEAEA6"),
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
            
            let dayFont = needsFontScaling ? UIFont.SpectralMedium(withFontSize:10) : UIFont.SpectralMedium(withFontSize:11)
            let dayNewFontSize = UIFont.getScaledFontSizeFor(font: dayFont, screenSize: currentPageRect.size, minPointSize: 8)
            
            month.dayInfo.forEach({(day) in
                
                
                if day.belongsToSameMonth {
                    let dayAttrs: [NSAttributedString.Key: Any] = [.font :UIFont.SpectralMedium(withFontSize:dayNewFontSize),
                                                                   NSAttributedString.Key.kern : 0.0,
                                                                   .foregroundColor : UIColor.init(hexString: "#64645F"),
                                                                   .paragraphStyle: paragraphStyle];
                    let dayString = NSMutableAttributedString.init(string: day.dayString, attributes: dayAttrs)
                    let drawRect = CGRect(x: dayX , y: dayY , width: dayCellWidth, height: dayCellHeight)
                    dayString.draw(in: drawRect)
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
                if formatInfo.customVariants.selectedDevice.identifier == "standard4" && landscaped {
                    monthY += 2
                }
            }
        }
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
        let monthNewFontSize = UIFont.getScaledFontSizeFor(font: monthFont, screenSize: currentPageRect.size, minPointSize: 18)
        
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
        let weekSymbolFont = UIFont.SpectralRegular(withFontSize:screenInfo.fontsInfo.monthPageDetails.weekFontSize)
        let weekSymbolNewFontSize = UIFont.getScaledFontSizeFor(font: weekSymbolFont, screenSize: currentPageRect.size, minPointSize: 16)
        let symbolAttrs: [NSAttributedString.Key : Any] =  [.font :UIFont.SpectralRegular(withFontSize: weekSymbolNewFontSize),
                                                            NSAttributedString.Key.kern : 0.0,
                                                            .foregroundColor : UIColor.init(hexString: "#AEAEA6"),
                                                            .paragraphStyle: paragraphStyle];
        
        var symbolX = (currentPageRect.width*templateInfo.baseBoxX/100)
        symbols.forEach({(symbol) in
            let symbolString = NSMutableAttributedString.init(string: symbol,attributes: symbolAttrs)
            let symbolY =  (currentPageRect.height*templateInfo.baseBoxY/100) - (currentPageRect.height*templateInfo.cellOffsetY/100) - symbolString.size().height
            symbolString.draw(in: CGRect(x: symbolX, y:symbolY , width: 23, height: cellHeight))
            symbolX += cellWidth + (currentPageRect.width*templateInfo.cellOffsetX/100)
        }
        )
        
        var dayX = (currentPageRect.width*templateInfo.baseBoxX/100)
        var linkX = (currentPageRect.width*templateInfo.baseBoxX/100)
        var dayY = (currentPageRect.height*templateInfo.baseBoxY/100)
        var index = 1;
        
        let dayFont = UIFont.SpectralMedium(withFontSize:screenInfo.fontsInfo.monthPageDetails.dayFontSize)
        let dayNewFontSize = UIFont.getScaledFontSizeFor(font: dayFont, screenSize: currentPageRect.size, minPointSize: 18)
        let dayAttrs: [NSAttributedString.Key : Any] =  [.font :UIFont.SpectralMedium(withFontSize: dayNewFontSize),
                                                            NSAttributedString.Key.kern : 0.0,
                                                            .foregroundColor : UIColor.init(hexString: "#64645F"),
                                                            .paragraphStyle: paragraphStyle]
        var weekNumbers : [Any] = []
        monthInfo.dayInfo.forEach({(day) in
            let dayString = NSMutableAttributedString.init(string: day.dayString,attributes: dayAttrs)
            let dayRect = CGRect(x: dayX, y: dayY, width: 23 , height: cellHeight)
            if day.belongsToSameMonth {
                weekNumbers.append(day.weekNumber)
                dayString.draw(in: dayRect)
                currentMonthRectsInfo.dayRects.append(getLinkRect(location: CGPoint(x: linkX, y: dayY), frameSize: CGSize(width: 23, height: cellHeight - cellHeight/4)))
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
        let weekNumberFont = UIFont.SpectralMedium(withFontSize:16)
        let weekNumberNewFontSize = UIFont.getScaledFontSizeFor(font: weekNumberFont, screenSize: currentPageRect.size, minPointSize: 12)
        let weekNumberAttrs: [NSAttributedString.Key: Any] = [.font :UIFont.SpectralMedium(withFontSize:weekNumberNewFontSize),
                                                              NSAttributedString.Key.kern : 0.0,
                                                              .foregroundColor : UIColor(hexString: "#64645F", alpha: 1.0),
                                                              .paragraphStyle: paragraphStyle];
        let weekNumberXPercentage : CGFloat = formatInfo.customVariants.isLandscape ? 3.59 : 5.39
        let weekNumberX = (currentPageRect.width*weekNumberXPercentage/100)
        var weekNumberY = (currentPageRect.height*templateInfo.baseBoxY/100)
        let weekWidthPercentage : CGFloat = formatInfo.customVariants.isLandscape ? 4.13 : 5.51
        let weekSymbolWidth = (currentPageRect.width*weekWidthPercentage/100)
        weekNumbers = Array(NSOrderedSet(array: weekNumbers))
        for weekNumber in weekNumbers {
            let weekText = "Wk " + "\(weekNumber)"
            let weekString = NSMutableAttributedString.init(string: weekText,attributes: weekNumberAttrs)
            let weekNumberRect = CGRect(x: weekNumberX + weekSymbolWidth/2 - weekString.size().width/2, y: weekNumberY + weekString.size().height/3 , width: weekSymbolWidth , height: cellHeight)
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
        let landscaped = formatInfo.customVariants.isLandscape
        
        if let weekdaysInfo = weeklyInfo.dayInfo.first {
            let monthX = currentPageRect.size.width*templateInfo.baseBoxX/100
            let monthFont = UIFont.SpectralSemiBold(withFontSize: screenInfo.fontsInfo.weekPageDetails.monthFontSize)
            let monthNewFontSize = UIFont.getScaledFontSizeFor(font: monthFont, screenSize: currentPageRect.size, minPointSize: 18)
            let monthAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.SpectralSemiBold(withFontSize: monthNewFontSize),
                                                            .kern: 0.0,
                                                            .foregroundColor: UIColor.init(hexString:"#64645F")]
            let monthText = weeklyInfo.dayInfo.first?.fullMonthString ?? ""
            let monthString = NSMutableAttributedString.init(string: monthText, attributes: monthAttrs)
            var monthY : CGFloat = templateInfo.titleLineY
            if formatInfo.customVariants.selectedDevice.identifier == "standard4" && landscaped {
                monthY = 4.40
            }
            let monthYValue = currentPageRect.size.height*monthY/100
            let monthLocation = CGPoint(x: monthX, y: monthYValue)
            monthString.draw(at: monthLocation)
            currentWeekRectInfo.monthRect = getLinkRect(location: monthLocation, frameSize: CGSize(width: monthString.size().width, height: monthString.size().height))
            let weekNumberText = "  \u{2022}   " + "Week" + " \(weekdaysInfo.weekNumber)"
            
            let weekNumberFont = UIFont.SpectralMedium(withFontSize: 15)
            let weekNumberNewFontSize = UIFont.getScaledFontSizeFor(font: weekNumberFont, screenSize: currentPageRect.size, minPointSize: 12)
            let weekNumberAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.SpectralMedium(withFontSize: weekNumberNewFontSize),
                                                            .kern: 0.0,
                                                            .foregroundColor: UIColor.init(hexString:"#64645F")]
            
            let weekNumberString = NSMutableAttributedString.init(string: weekNumberText, attributes: weekNumberAttrs)
            let weekNumberLocation = CGPoint(x: monthX + monthString.size().width + 5, y: monthLocation.y + monthString.size().height/2 - weekNumberString.size().height/2)
            weekNumberString.draw(at: weekNumberLocation)
            
            let yearText = weeklyInfo.dayInfo.first?.yearString ?? ""
            let yearString = NSMutableAttributedString.init(string: yearText, attributes: monthAttrs)
            let yearX = currentPageRect.size.width*templateInfo.baseBoxX/100 + currentPageRect.size.width*templateInfo.cellWidth/100 - yearString.size().width
            let yearY = currentPageRect.size.height*monthY/100
            yearString.draw(at: CGPoint(x: yearX, y: yearY))
            currentWeekRectInfo.yearRect = getLinkRect(location: CGPoint(x: yearX, y: yearY), frameSize: CGSize(width: yearString.size().width, height: yearString.size().height))
        }
        
        let weekDayfont = UIFont.SpectralMedium(withFontSize:screenInfo.fontsInfo.weekPageDetails.weekFontSize)
        let weekDayNewFontSize = UIFont.getScaledFontSizeFor(font: weekDayfont, screenSize: currentPageRect.size, minPointSize: 13)
        let weekAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.SpectralMedium(withFontSize: weekDayNewFontSize),
                                                        .kern: 0.0,
                                                        .foregroundColor: UIColor.init(hexString:"#64645F")]
        
        let weekDatefont = UIFont.SpectralMedium(withFontSize:screenInfo.fontsInfo.weekPageDetails.dayFontSize)
        let weekDateNewFontSize = UIFont.getScaledFontSizeFor(font: weekDatefont, screenSize: currentPageRect.size, minPointSize: 12)
        let weekDateAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.SpectralMedium(withFontSize: weekDateNewFontSize),
                                                        .kern: 0.0,
                                                        .foregroundColor: UIColor.init(hexString:"#AEAEA6")]
        let weekDayStringXOffsetPercent = formatInfo.customVariants.isLandscape ? 0.89 : 1.19
        let weekDayStringXOffset = currentPageRect.width*CGFloat(weekDayStringXOffsetPercent)/100
        let weekDayStringYOffsetPercent = formatInfo.customVariants.isLandscape ? 0.54 : 0.0
        let weekDayStringYOffset = currentPageRect.width*CGFloat(weekDayStringYOffsetPercent)/100
        var weekDayInfoYPercent = templateInfo.baseBoxY
        let notesBoxHeightPercent : CGFloat = landscaped ? 4.54 : 2.86
        let notesBoxheightValue = currentPageRect.height*notesBoxHeightPercent/100
        let numberofNotesBoxesPerDay : CGFloat = landscaped ? 3 : 5
        let weekBoxesHeightValue = numberofNotesBoxesPerDay*notesBoxheightValue
        if formatInfo.customVariants.selectedDevice.identifier == "standard4" && landscaped {
            weekDayInfoYPercent = 10.74
        }
        var weekDayInfoY = currentPageRect.height*weekDayInfoYPercent/100
        var weekDayInfoX = currentPageRect.width*templateInfo.baseBoxX/100
        
        
        
        var weekDateInfoX = currentPageRect.width*templateInfo.baseBoxX/100
        var weekDateInfoY = currentPageRect.height*weekDayInfoYPercent/100 + weekBoxesHeightValue
        
        
        var weekDayRects : [CGRect] = []
        weeklyInfo.dayInfo.forEach(({(weekDay) in
            let weekDayText = weekDay.weekString
            let weekDayString = NSMutableAttributedString.init(string: weekDayText, attributes: weekAttrs)
            
            let weekDayRect = CGRect(x: weekDayInfoX + weekDayStringXOffset, y: weekDayInfoY + weekDayStringYOffset, width: weekDayString.size().width, height: 24)
            weekDayString.draw(in: weekDayRect)
            
            let weekDateText = weekDay.dayString
            let weekDateString = NSMutableAttributedString.init(string: weekDateText, attributes: weekDateAttrs)
            let weekDateRectFigma = CGSize(width: 15, height: 21)
            let weekDateInfoYWithYOffset = landscaped ? (weekDateInfoY - weekDateString.size().height) : (weekDateInfoY - weekDayStringYOffset - weekDateRectFigma.height)
            
            let weekDateRect = CGRect(x: weekDateInfoX + weekDayStringXOffset, y: weekDateInfoYWithYOffset, width: weekDateString.size().width, height: weekDateString.size().height)
            weekDateString.draw(in: weekDateRect)
            
            if isBelongToCalendarYear(currentDate: weekDay.date) {
                weekDayRects.append(getLinkRect(location: CGPoint(x: weekDayRect.origin.x, y: weekDayRect.origin.y),
                                                frameSize: CGSize(width: weekDayString.size().width, height: weekDayString.size().height)))
            }
            index += 1
            
            if index < 6 {
                weekDateInfoY += weekBoxesHeightValue
                weekDayInfoY += weekBoxesHeightValue
                if !formatInfo.customVariants.isLandscape{
                    weekDayInfoY += 1
                }
            }else{
                // As 7th day rect is beside 6th day rect
                let weekDayInfoXPercent = formatInfo.customVariants.isLandscape ? 24.67 : 29.61
                weekDayInfoX += currentPageRect.width*CGFloat(weekDayInfoXPercent)/100 + 1
                weekDateInfoX += currentPageRect.width*CGFloat(weekDayInfoXPercent)/100 + 1
            }
            
        }))
        currentWeekRectInfo.weekDayRects.append(contentsOf: weekDayRects)
        weekRectsInfo.append(currentWeekRectInfo)
    }
    override func renderDayPage(context: CGContext, dayInfo: FTDayInfo) {
        
        super.renderDayPage(context: context, dayInfo: dayInfo);
        currentDayRectsInfo = FTDiaryDayRectsInfo()
        let isLandscaped = formatInfo.customVariants.isLandscape
        let templateInfo = screenInfo.spacesInfo.dayPageSpacesInfo

        //Day Rendering
        let selectedDeviceIdentifier = formatInfo.customVariants.selectedDevice.identifier
        let needsFontScaling : Bool = (selectedDeviceIdentifier == "standard1" || selectedDeviceIdentifier == "standard2" || selectedDeviceIdentifier == "standard4")
        let dayFont = needsFontScaling ? UIFont.SpectralSemiBold(withFontSize: 35) : UIFont.SpectralSemiBold(withFontSize: screenInfo.fontsInfo.dayPageDetails.dayFontSize)
        
        let dayMinFontSize : CGFloat = needsFontScaling ? 28 : 35
        let dayNewFontSize = UIFont.getScaledFontSizeFor(font: dayFont, screenSize: currentPageRect.size, minPointSize: dayMinFontSize)
        let dayAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.SpectralSemiBold(withFontSize:dayNewFontSize),
                                                         NSAttributedString.Key.kern : 0.0,
                                                         .foregroundColor : UIColor.init(hexString: "#64645F")];
        var baseYPercent = templateInfo.baseY
        if formatInfo.customVariants.selectedDevice.identifier == "standard4" && isLandscaped {
            baseYPercent = 3.11
        }
        
        let dayX = currentPageRect.width*templateInfo.baseX/100
        let dayY = currentPageRect.height*baseYPercent/100
        
        let dayString = NSAttributedString.init(string: dayInfo.dayString, attributes: dayAttrs);
        dayString.draw(in: CGRect(x: dayX, y: dayY, width: dayString.size().width, height: 68))
        
        let monthFont = needsFontScaling ? UIFont.SpectralSemiBold(withFontSize: 18) : UIFont.SpectralSemiBold(withFontSize: screenInfo.fontsInfo.dayPageDetails.monthFontSize)
        let monthMinFontSize : CGFloat = needsFontScaling ? 14 : 18
        let monthNewFontSize = UIFont.getScaledFontSizeFor(font: monthFont, screenSize: currentPageRect.size, minPointSize: monthMinFontSize)
        let monthAttr : [NSAttributedString.Key : Any] = [.font : UIFont.SpectralSemiBold(withFontSize:monthNewFontSize),
                                                          NSAttributedString.Key.kern : 0.0,
                                                          .foregroundColor : UIColor.init(hexString: "#64645F")];
        let monthString = NSAttributedString.init(string: dayInfo.fullMonthString, attributes: monthAttr);
        var monthY : CGFloat =   isLandscaped ? 10 : 7.15
        if formatInfo.customVariants.selectedDevice.identifier == "standard4" && isLandscaped {
            monthY = 10.38
        }
        let monthYvalue = currentPageRect.height*monthY/100
        let monthRect = CGRect(x : dayX, y: monthYvalue , width: monthString.size().width, height: monthString.size().height)
        monthString.draw(in: monthRect)
        currentDayRectsInfo.monthRect = getLinkRect(location: CGPoint(x: monthRect.origin.x, y: monthRect.origin.y), frameSize: monthString.size())
        
        let weekFont = needsFontScaling ? UIFont.SpectralMedium(withFontSize: 13) :UIFont.SpectralMedium(withFontSize: screenInfo.fontsInfo.dayPageDetails.weekFontSize)
        let weekMinFontSize : CGFloat = needsFontScaling ? 9 : 12
        let weekNewFontSize = UIFont.getScaledFontSizeFor(font: weekFont, screenSize: currentPageRect.size, minPointSize: weekMinFontSize)
        let weekAttr : [NSAttributedString.Key : Any] = [.font : UIFont.SpectralMedium(withFontSize:weekNewFontSize),
                                                          NSAttributedString.Key.kern : 0.0,
                                                          .foregroundColor : UIColor.init(hexString: "#64645F")];
        let weekString = NSAttributedString.init(string: dayInfo.weekString, attributes: weekAttr);
        var weekY : CGFloat = isLandscaped ? 14.15 : 10.49
        if formatInfo.customVariants.selectedDevice.identifier == "standard4" && isLandscaped {
            weekY = 14.54
        }
        let weekYValue = currentPageRect.height*weekY/100
        let weekRect = CGRect(x : dayX, y: weekYValue, width: weekString.size().width, height: 23)
        weekString.draw(in: weekRect)
        
        let bulletText = " \u{2022}  "
        let bulletString = NSAttributedString.init(string: bulletText, attributes: weekAttr);
        let weekNumText = "Week" + " \(dayInfo.weekNumber)"
        let weekNumString = NSAttributedString.init(string: weekNumText, attributes: weekAttr);
        let weekNumberText =  bulletText + weekNumText
        let weekNumberString = NSAttributedString.init(string: weekNumberText, attributes: weekAttr);
        let weekNumberRect = CGRect(x : dayX + weekString.size().width + 7, y: weekYValue, width: weekNumberString.size().width, height: 23)
        weekNumberString.draw(in: weekNumberRect)
        currentDayRectsInfo.weekRect = getLinkRect(location: CGPoint(x: weekNumberRect.origin.x + bulletString.size().width, y: weekNumberRect.origin.y), frameSize: CGSize(width: weekNumString.size().width, height: weekNumberString.size().height))
        
        let yearXPercentFromRightSide : CGFloat = formatInfo.customVariants.isLandscape ? 2.87 : 4.55
        let yearX = self.currentPageRect.width - (self.currentPageRect.width*yearXPercentFromRightSide/100)
        let yearYPercent : CGFloat = formatInfo.customVariants.isLandscape ? 5.19 : 3.33
        let yearY = self.currentPageRect.height*yearYPercent/100
        let yearFont = UIFont.SpectralSemiBold(withFontSize: screenInfo.fontsInfo.dayPageDetails.yearFontSize)
        let yearMinFontSize : CGFloat = 18
        let yearNewFontSize = UIFont.getScaledFontSizeFor(font: yearFont, screenSize: currentPageRect.size, minPointSize: yearMinFontSize)
        let yearAttr : [NSAttributedString.Key : Any] = [.font : UIFont.SpectralSemiBold(withFontSize:yearNewFontSize),
                                                          NSAttributedString.Key.kern : 0.0,
                                                          .foregroundColor : UIColor.init(hexString: "#64645F")];
        let yearString = NSAttributedString.init(string: dayInfo.yearString, attributes: yearAttr);
        let yearRect = CGRect(x : yearX - yearString.size().width, y: yearY, width: yearString.size().width, height: 33)
        currentDayRectsInfo.yearRect = getLinkRect(location: CGPoint(x: yearRect.origin.x, y: yearRect.origin.y), frameSize: yearString.size())
        yearString.draw(in: yearRect)
        dayRectsInfo.append(currentDayRectsInfo)
    }
}
