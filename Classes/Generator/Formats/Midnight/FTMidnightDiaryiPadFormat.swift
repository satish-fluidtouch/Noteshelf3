//
//  FTMidnightiPadFormat.swift
//  Noteshelf
//
//  Created by Ramakrishna on 31/05/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTStyles

class FTMidnightDiaryiPadFormat : FTMidnightDairyFormat {
    
    override func renderCalendarPage(context: CGContext, months: [FTMonthlyCalendarInfo], calendarYear: FTYearFormatInfo) {
        
        self.renderMidnightDiaryPDF(context: context, pdfTemplatePath: self.yearTemplate)
        
        let templateInfo = screenInfo.spacesInfo.yearPageSpacesInfo
        var currMonthIndex = CGFloat(0)
        let columnCount = getColumnCount()
        let rowCount = getRowCount()
        let cellWidth = getYearCellWidth(columnCount: columnCount)
        let monthStringY = (currentPageRect.height*1.19)/100
        let monthStringX = (currentPageRect.width*2.03)/100
        let weekStringY = (currentPageRect.height*1.09)/100
        let weekDayStringY = (currentPageRect.height*3.40)/100
        
        let yearFont = UIFont.robotoMedium(screenInfo.fontsInfo.yearPageDetails.yearFontSize)
        let yearNewFontSize = UIFont.getScaledFontSizeFor(font: yearFont, screenSize: currentPageRect.size, minPointSize: 33)
        let yearAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.robotoMedium(yearNewFontSize),
                                                        .kern: 0.0,
                                                        .foregroundColor: UIColor.init(hexString: "#C4C4C4")]
        if let startYear = months.first?.year {
            var year: String = "\(startYear)"
            if let endYear = months.last?.year, endYear != startYear {
                let endYearXX = "\(endYear)".suffix(2)
                year = "\(startYear)" +  "-" + "\(endYearXX)"
            }
            let yearString = NSMutableAttributedString.init(string: year, attributes: yearAttrs)
            let yearRect = CGRect(x: (currentPageRect.width*templateInfo.baseBoxX/100), y: (currentPageRect.height*templateInfo.yearY/100), width: yearString.size().width, height: yearString.size().height)
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
                                                              .foregroundColor : UIColor.init(hexString: "#E5E5E5")]
            let monthString = NSMutableAttributedString(string: month.fullMonth.uppercased(), attributes: monthAttrs)
            let widthFactor = currMonthIndex.truncatingRemainder(dividingBy: columnCount) * (cellWidth + (currentPageRect.size.width*templateInfo.cellOffsetX/100))
            let cellWidth = getYearCellWidth(columnCount: columnCount)
            let cellHeight = getYearCellHeight(rowCount: rowCount)
            let dayCellWidth = (cellWidth - 2*monthStringX)/7
            let dayCellHeight = (cellHeight - (currentPageRect.height*3.59)/100 - (currentPageRect.height*1.29)/100)/7
            
            let monthX = (currentPageRect.size.width*templateInfo.baseBoxX/100) + widthFactor + monthStringX
            let location = CGPoint(x: monthX + dayCellWidth/3, y: monthY)
            monthString.draw(at: location)
            calendarRectsInfo.monthRects.append(getLinkRect(location: location, frameSize: CGSize(width: monthString.size().width, height: monthString.size().height)))
            
            let symbols = getWeekSymbols(monthInfo: month)
            
            let paragraphStyle = NSMutableParagraphStyle.init()
            paragraphStyle.alignment = .center
            let weekSymbolFont = UIFont.montserratFont(for: .bold, with: 11)
            let weekSymbolNewFontSize = UIFont.getScaledFontSizeFor(font: weekSymbolFont, screenSize: currentPageRect.size, minPointSize: 8)
            
            let symbolAttrs: [NSAttributedString.Key : Any] =  [.font :UIFont.montserratFont(for: .bold, with: weekSymbolNewFontSize),
                                                                NSAttributedString.Key.kern : 0.0,
                                                                .foregroundColor : UIColor.init(hexString: "#7B7B78"),
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
            
            month.dayInfo.forEach({(day) in
                
                
                if day.belongsToSameMonth {
                    let dayAttrs: [NSAttributedString.Key: Any] = [.font :UIFont.montserratFont(for: .bold, with: weekSymbolNewFontSize),
                                                                   NSAttributedString.Key.kern : 0.0,
                                                                   .foregroundColor : UIColor.init(hexString: "#E5E5E5"),
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
            }
        }
        self.addTodayPillToCalenderPageWith(context: context)
        self.diaryPagesInfo.append(FTDiaryPageInfo(type: .calendar))
    }
    
    override func renderPrioritiesPage(context: CGContext, weeklyInfo: FTWeekInfo?, dayInfo: FTDayInfo?) {
        if let dayInfo = dayInfo, !dayInfo.belongsToSameMonth {
            return
        }
        self.renderMidnightDiaryPDF(context: context, pdfTemplatePath: self.prioritiesTemplate)
        let prioritiesTemplateInfo = screenInfo.spacesInfo.prioritiesPageSpacesInfo
        let bezierBGWidth = (currentPageRect.width*prioritiesTemplateInfo.boxWidth)/100
        let bezierBGXAxis = (currentPageRect.width*prioritiesTemplateInfo.boxX)/100
        
        // title drawing
        let titleX = currentPageRect.width*prioritiesTemplateInfo.titleX/100
        let titleY = currentPageRect.height*prioritiesTemplateInfo.titleY/100
        let font = UIFont.robotoMedium(screenInfo.fontsInfo.prioritiesPageDetails.yearFontSize)
        let newFontSize = UIFont.getScaledFontSizeFor(font: font, screenSize: currentPageRect.size, minPointSize: 33)
        let titleAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.robotoMedium(newFontSize),
                                                          NSAttributedString.Key.kern : 0.0,
                                                          .foregroundColor : UIColor.init(hexString: "#C4C4C4")];
        
        let dayFont = UIFont.robotoMedium(screenInfo.fontsInfo.prioritiesPageDetails.dayFontSize)
        let dayNewFontSize = UIFont.getScaledFontSizeFor(font: dayFont, screenSize: currentPageRect.size, minPointSize: 25)
        let weekInfoAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.robotoMedium(dayNewFontSize),
                                                             NSAttributedString.Key.kern : 0.0,
                                                             .foregroundColor : UIColor.init(hexString: "#4FA4FF")];
        let todayPillXOffsetPercnt = formatInfo.customVariants.isLandscape ? 1.25 : 1.67 // gap between today pill and day/week info

        if let weekInfo = weeklyInfo{
            
            let titleString = NSMutableAttributedString.init(string: "Weekly Priorities", attributes: titleAttrs)
            let titleLocation = CGPoint(x: titleX,
                                        y: titleY)
            titleString.draw(at: titleLocation)
            
            // week info drawing
            
            let weekFirstDate = weekInfo.dayInfo.first
            let weekLastDate = weekInfo.dayInfo.last
            var weekDurationText : String = ""
            if weekFirstDate?.month == weekLastDate?.month {
                weekDurationText =  weekInfo.dayInfo.first?.monthString ?? ""
                weekDurationText += " " + (weekInfo.dayInfo.first?.fullDayString ?? "") + " - "
                weekDurationText += (weekInfo.dayInfo.last?.fullDayString ?? "")
            }
            else{
                weekDurationText += (weekInfo.dayInfo.first?.monthString ?? "") + " " + (weekInfo.dayInfo.first?.fullDayString ?? "") + " - "
                weekDurationText +=  (weekInfo.dayInfo.last?.monthString ?? "") + " " + (weekInfo.dayInfo.last?.fullDayString ?? "")
            }
            let weekInfoAttrString = NSMutableAttributedString.init(string:weekDurationText , attributes: weekInfoAttrs)
            let weekInfoRectX = bezierBGXAxis + bezierBGWidth - weekInfoAttrString.size().width
            let weekInfoRectY = (currentPageRect.height*prioritiesTemplateInfo.dayInfoY)/100
            let weekInfoRect = CGRect(x: weekInfoRectX, y: weekInfoRectY, width: weekInfoAttrString.size().width, height: weekInfoAttrString.size().height)
            let weekInfoDrawLocation = CGPoint(x: weekInfoRect.origin.x, y: weekInfoRect.origin.y)
            weekInfoAttrString.draw(at: weekInfoDrawLocation)
            self.weekPrioritiesInfo.append(FTDiaryWeeklyPrioritiesRectInfo(weekRect: getLinkRect(location: weekInfoDrawLocation, frameSize: weekInfoAttrString.size())))
            //Today pill
            let weekInfoXPercnt = (weekInfoRect.origin.x/currentPageRect.width)*100
            let rightXOffsetPercnt = 100.0 - (weekInfoXPercnt - todayPillXOffsetPercnt)
            self.addTodayPillWith(rightXOffsetPercent: rightXOffsetPercnt, toContext: context)
        }
        if let dayInfo = dayInfo {
            let title = formatInfo.customVariants.selectedDevice.isiPad ? "Daily Priorities" : "Daily Plan"
            let titleString = NSMutableAttributedString.init(string: title , attributes: titleAttrs)
            let titleLocation = CGPoint(x: titleX,
                                        y: titleY)
            titleString.draw(at: titleLocation)
            
            // day info drawing
            
            let monthString = dayInfo.monthString
            let weekString = dayInfo.dayString
            let dayInfoString = monthString + " " + weekString
            let dayInfoAttrString = NSMutableAttributedString.init(string:dayInfoString , attributes: weekInfoAttrs)
            let dayInfoRectX = bezierBGXAxis + bezierBGWidth - dayInfoAttrString.size().width
            let dayInfoRectY = (currentPageRect.height*prioritiesTemplateInfo.dayInfoY)/100
            let dayInfoRect = CGRect(x: dayInfoRectX, y: dayInfoRectY, width: dayInfoAttrString.size().width, height: dayInfoAttrString.size().height)
            let dayInfoDrawLocation = CGPoint(x: dayInfoRect.origin.x, y: dayInfoRect.origin.y)
            dayInfoAttrString.draw(at: dayInfoDrawLocation)
            dailyPrioritiesInfo.append(FTDiaryDailyPrioritiesRectInfo(dayRect: getLinkRect(location: dayInfoDrawLocation, frameSize: dayInfoAttrString.size())))

            //Today pill
            let dayInfoXPercnt = (dayInfoRect.origin.x/currentPageRect.width)*100
            let rightXOffsetPercnt = 100.0 - (dayInfoXPercnt - todayPillXOffsetPercnt)
            self.addTodayPillWith(rightXOffsetPercent: rightXOffsetPercnt, toContext: context)
        }
    }
    override func renderMonthPage(context: CGContext, monthInfo: FTMonthlyCalendarInfo, calendarYear: FTYearFormatInfo) {
        super.renderMonthPage(context: context, monthInfo: monthInfo, calendarYear: calendarYear)
        let currentMonthRectsInfo = FTDiaryMonthRectsInfo()
        let templateInfo = screenInfo.spacesInfo.monthPageSpacesInfo
        let cellWidth = (currentPageRect.width - (currentPageRect.width*templateInfo.baseBoxX/100) - (currentPageRect.width*templateInfo.boxRightOffset/100) - 6*(currentPageRect.width*templateInfo.cellOffsetX/100))/7
        let cellHeight = (currentPageRect.height - (currentPageRect.height*templateInfo.baseBoxY/100) - (currentPageRect.height*templateInfo.boxBottomOffset/100) -
                            5*(currentPageRect.height*templateInfo.cellOffsetY/100))/6
        let font = UIFont.robotoMedium(screenInfo.fontsInfo.monthPageDetails.yearFontSize)
        let newFontSize = UIFont.getScaledFontSizeFor(font: font, screenSize: currentPageRect.size, minPointSize: 33)
        let paragraphStyle = NSMutableParagraphStyle.init()
        paragraphStyle.alignment = .center
        let yearAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.robotoMedium(newFontSize),
                                                        .kern: 0.0,
                                                        .foregroundColor: UIColor.init(hexString: "#C4C4C4"),.paragraphStyle : paragraphStyle]

        let yearString = NSMutableAttributedString.init(string: monthInfo.year, attributes: yearAttrs)
        let yearLocation = CGPoint(x: (currentPageRect.width*templateInfo.baseBoxX/100), y: (currentPageRect.height*templateInfo.monthY/100) )
        yearString.draw(in: CGRect(x: yearLocation.x, y: yearLocation.y, width: yearString.size().width, height: yearString.size().height))
        currentMonthRectsInfo.yearRect = getLinkRect(location: yearLocation, frameSize: yearString.size())
        
        let navigationStringAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.robotoMedium(newFontSize),
                                                                    .kern: 0.0,
                                                                    .foregroundColor: UIColor.init(hexString: "#C4C4C4", alpha: 0.4)]
        
        let navigationString = NSMutableAttributedString.init(string: "/", attributes: navigationStringAttrs)
        let navigationLocation = CGPoint(x: (yearLocation.x) + yearString.size().width + 11, y: (currentPageRect.height*templateInfo.monthY/100) )
        navigationString.draw(at: navigationLocation)
        
        let monthAttrs: [NSAttributedString.Key: Any] = yearAttrs
        let monthString = NSMutableAttributedString.init(string: monthInfo.shortMonth, attributes: monthAttrs)
        let monthLocation = CGPoint(x: navigationLocation.x  + navigationString.size().width + 13,
                                    y:(currentPageRect.height*templateInfo.monthY/100))
        monthString.draw(in: CGRect(x: monthLocation.x, y: monthLocation.y, width: monthString.size().width, height: monthString.size().height))
        currentMonthRectsInfo.monthRect = getLinkRect(location: monthLocation, frameSize: monthString.size())
        
        // For week Number drawing
        let weekFont = UIFont.montserratFont(for: .bold, with: 11)
        let weekNewFontSize = UIFont.getScaledFontSizeFor(font: weekFont, screenSize: currentPageRect.size, minPointSize: 8)
        let weekNumberTextAttribute: [NSAttributedString.Key : Any] = [.font : UIFont.montserratFont(for: .bold, with: weekNewFontSize),
                                                                       NSAttributedString.Key.kern : 0.0,
                                                                       .foregroundColor : UIColor(hexString: "4FA4FF")]
        let weekX = (currentPageRect.width*templateInfo.baseBoxX/100)
        var weekY = (currentPageRect.height*templateInfo.baseBoxY/100)

        var weekNumbers : [String] = []
        var weekNumber : Int = 0
        for (index, day) in monthInfo.dayInfo.enumerated() {
            let weekNumberOBJ = FTPlannerWeekNumber()
            if index == 0 {
                weekNumber += 1
                weekNumbers.append("WEEK \(weekNumber)")
            }
            else if index % 7 == 0, day.fullMonthString == monthInfo.fullMonth {
                weekNumber += 1
                weekNumbers.append("WEEK \(weekNumber)")
            }
        }

        for week in weekNumbers {
            let weekString = NSMutableAttributedString.init(string: week,attributes: weekNumberTextAttribute)
            let location = CGPoint(x: weekX + 5, y: weekY - weekString.size().height - 2)
            weekString.draw(at: location)
            weekY += cellHeight + (currentPageRect.height*templateInfo.cellOffsetY/100)
            currentMonthRectsInfo.weekRects.append(getLinkRect(location: location, frameSize: weekString.size()))
        }
        
        
        let symbols = getWeekSymbols(monthInfo: monthInfo)
        let weekSymbolFont = UIFont.montserratFont(for: .bold, with: screenInfo.fontsInfo.monthPageDetails.weekFontSize)
        let weekSymbolNewFontSize = UIFont.getScaledFontSizeFor(font: weekSymbolFont, screenSize: currentPageRect.size, minPointSize: 8)
        
        let symbolAttrs: [NSAttributedString.Key : Any] =  [.font :UIFont.montserratFont(for: .bold, with: weekSymbolNewFontSize),
                                                            NSAttributedString.Key.kern : 0.0,
                                                            .foregroundColor : UIColor.init(hexString: "#7B7B78"),
                                                            .paragraphStyle: paragraphStyle];
        
        var symbolX = (currentPageRect.width*templateInfo.baseBoxX/100) + cellWidth
        symbols.forEach({(symbol) in
            let symbolString = NSMutableAttributedString.init(string: symbol,attributes: symbolAttrs)
            let symbolY = (currentPageRect.height*templateInfo.baseBoxY/100) - ( symbolString.size().height)
            symbolString.draw(in: CGRect(x: symbolX - symbolString.size().width - 6, y:symbolY , width: symbolString.size().width, height: symbolString.size().height))
            symbolX += cellWidth + (currentPageRect.width*templateInfo.cellOffsetX/100)
        }
        )
        
        var dayX = (currentPageRect.width*templateInfo.baseBoxX/100) + cellWidth
        var linkX = (currentPageRect.width*templateInfo.baseBoxX/100)
        var dayY = (currentPageRect.height*templateInfo.baseBoxY/100)
        var index = 1;
        
        monthInfo.dayInfo.forEach({(day) in
            let dayForeGroundColor = day.belongsToSameMonth ? UIColor.init(hexString: "#E5E5E5") :UIColor.init(hexString: "#7B7B78")
            let dayFont = UIFont.montserratFont(for: .bold, with: screenInfo.fontsInfo.monthPageDetails.dayFontSize)
            let dayNewFontSize = UIFont.getScaledFontSizeFor(font: dayFont, screenSize: currentPageRect.size, minPointSize: 10)
            let dayAttrs: [NSAttributedString.Key: Any] = [.font :UIFont.montserratFont(for: .bold, with: dayNewFontSize),
                                                           NSAttributedString.Key.kern : 0.0,
                                                           .foregroundColor : dayForeGroundColor,
                                                           .paragraphStyle: paragraphStyle];
            let dayString = NSMutableAttributedString.init(string: day.dayString, attributes: dayAttrs)
            let drawRect = CGRect(x: dayX - 6 - dayString.size().width, y: dayY + 6, width: dayString.size().width, height: dayString.size().height)
            let drawLocation = CGPoint(x: drawRect.origin.x, y: drawRect.origin.y)
            if day.belongsToSameMonth {
                let tappableHeight = formatInfo.customVariants.isLandscape ? cellHeight/3 : cellHeight/4
                currentMonthRectsInfo.dayRects.append(getLinkRect(location: CGPoint(x: (linkX + cellWidth - cellWidth/3), y: dayY), frameSize: CGSize(width: cellWidth/3, height: tappableHeight)))
                dayString.draw(at:drawLocation)
            }
            if(index % 7 == 0) {
                dayX = (currentPageRect.width*templateInfo.baseBoxX/100) + cellWidth;
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
        self.addTodayPillToMonthPageWith(context: context)
    }
    override func renderWeekPage(context: CGContext, weeklyInfo: FTWeekInfo) {
        super.renderWeekPage(context: context, weeklyInfo: weeklyInfo)
        let templateInfo = screenInfo.spacesInfo.weekPageSpacesInfo
        let prioritiesBoxY =  currentPageRect.height*templateInfo.prioritiesBoxY/100
        let prioritiesBoxX =  currentPageRect.width*templateInfo.prioritiesBoxX/100
        let prioritiesBoxWidth : CGFloat = currentPageRect.width*templateInfo.priorityBoxWidth/100
        let prioritiesBoxHeight : CGFloat = currentPageRect.height*templateInfo.priorityBoxHeight/100
        let notesBoxX = prioritiesBoxX
        let notesBoxY = prioritiesBoxY + prioritiesBoxHeight + currentPageRect.height*templateInfo.cellOffsetY/100
        let notesBoxWidth : CGFloat = currentPageRect.width*templateInfo.notesBoxWidth/100
        let notesBoxHeight : CGFloat = currentPageRect.height*templateInfo.notesBoxHeight/100
        let prioritiesRect = CGRect(x: prioritiesBoxX, y: prioritiesBoxY, width: prioritiesBoxWidth, height: prioritiesBoxHeight)
        var index = CGFloat(0)
        let weekDayfont = UIFont.montserratFont(for: .bold, with: screenInfo.fontsInfo.weekPageDetails.dayFontSize)
        let weekDayNewFontSize = UIFont.getScaledFontSizeFor(font: weekDayfont, screenSize: currentPageRect.size, minPointSize: 8)
        let weekAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.montserratFont(for: .bold, with: weekDayNewFontSize),
                                                        .kern: 0.0,
                                                        .foregroundColor: UIColor.init(hexString:"#E5E5E5")]
        var weekDayInfoY = currentPageRect.height*templateInfo.baseBoxY/100
        let weekDayInfoX = currentPageRect.width*templateInfo.baseBoxX/100
        var weekDayRects : [CGRect] = []
        weeklyInfo.dayInfo.forEach(({(weekDay) in
            let weekAndDayText = weekDay.fullDayString + " " + weekDay.weekString
            let weekAndDayString = NSMutableAttributedString.init(string: weekAndDayText, attributes: weekAttrs)
            let weekAndDayFrameLocation = CGPoint(x: weekDayInfoX + 11,
                                                  y: weekDayInfoY + 8)
            weekAndDayString.draw(at: weekAndDayFrameLocation)
            if isBelongToCalendarYear(currentDate: weekDay.date) {
                weekDayRects.append(getLinkRect(location: weekAndDayFrameLocation,
                                                frameSize: CGSize(width: weekAndDayString.size().width, height: weekAndDayString.size().height)))
            }
            index += 1
            weekDayInfoY += currentPageRect.height*templateInfo.cellHeight/100 + (currentPageRect.height*templateInfo.cellOffsetY/100)
        }))
        currentWeekRectInfo.weekDayRects.append(contentsOf: weekDayRects)
        let chevronImage = UIImage(named: "right_chevron")
        let prioritiesChevronRect = CGRect(x: (prioritiesRect.origin.x + prioritiesBoxWidth - 4 - 24), y: (prioritiesRect.origin.y + 4), width: 24, height: 24)
        chevronImage?.draw(at: CGPoint(x: prioritiesChevronRect.origin.x, y: prioritiesChevronRect.origin.y))
        currentWeekRectInfo.prioritiesRect = getLinkRect(location: CGPoint(x: prioritiesChevronRect.origin.x, y: prioritiesChevronRect.origin.y), frameSize: prioritiesChevronRect.size)
        
        let notesChevronRect = CGRect(x: (notesBoxX + notesBoxWidth - 4 - 24), y: notesBoxY + 4, width: 24, height: 24)
        chevronImage?.draw(at: CGPoint(x: notesChevronRect.origin.x, y: notesChevronRect.origin.y))
        currentWeekRectInfo.notesRect = getLinkRect(location: CGPoint(x: notesChevronRect.origin.x, y: notesChevronRect.origin.y), frameSize: notesChevronRect.size)
        weekRectsInfo.append(currentWeekRectInfo)
        self.addTodayPillToWeekPageWith(context: context)
    }
    override func renderDayPage(context: CGContext, dayInfo: FTDayInfo) {
        if !dayInfo.belongsToSameMonth {
            return
        }
        super.renderDayPage(context: context, dayInfo: dayInfo)
        let templateInfo = screenInfo.spacesInfo.dayPageSpacesInfo
        let prioritiesBoxY =  currentPageRect.height*templateInfo.prioritiesBoxY/100
        let prioritiesBoxX =  currentPageRect.width*templateInfo.prioritiesBoxX/100
        let prioritiesBoxWidth : CGFloat = currentPageRect.width*templateInfo.priorityBoxWidth/100
        let prioritiesBoxHeight : CGFloat = currentPageRect.height*templateInfo.priorityBoxHeight/100
        let prioritiesRect = CGRect(x: prioritiesBoxX, y: prioritiesBoxY, width: prioritiesBoxWidth, height: prioritiesBoxHeight)
        let chevronImage = UIImage(named: "right_chevron")
        let prioritiesChevronRect = CGRect(x: (prioritiesRect.origin.x + prioritiesBoxWidth - 4 - 24), y: (prioritiesRect.origin.y + 4), width: 24, height: 24)
        chevronImage?.draw(at: CGPoint(x: prioritiesChevronRect.origin.x, y: prioritiesChevronRect.origin.y))
        currentDayRectsInfo.prioritiesRect = getLinkRect(location: CGPoint(x: prioritiesChevronRect.origin.x, y: prioritiesChevronRect.origin.y), frameSize: prioritiesChevronRect.size)
        dayRectsInfo.append(currentDayRectsInfo)
        self.addTodayPillToDayPageWith(context: context)
    }
    override func renderNotesPage(context: CGContext, weeklyInfo: FTWeekInfo?, dayInfo: FTDayInfo?) {
        
        if let dayInfo = dayInfo, !dayInfo.belongsToSameMonth {
            return
        }
        self.renderMidnightDiaryPDF(context: context, pdfTemplatePath: self.notesTemplate)
        let notesTemplateInfo = screenInfo.spacesInfo.notesPageSpacesInfo
        let bezierBGWidth = (currentPageRect.width*notesTemplateInfo.boxWidth)/100
        let bezierBGXAxis = (currentPageRect.width*notesTemplateInfo.boxX)/100
        
        // title drawing
        let titleX = currentPageRect.width*notesTemplateInfo.titleX/100
        let titleY = currentPageRect.height*notesTemplateInfo.titleY/100
        let yearFont = UIFont.robotoMedium(screenInfo.fontsInfo.prioritiesPageDetails.yearFontSize)
        let yearNewFontSize = UIFont.getScaledFontSizeFor(font: yearFont, screenSize: currentPageRect.size, minPointSize: 33)
        let titleAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.robotoMedium(yearNewFontSize),
                                                          NSAttributedString.Key.kern : 0.0,
                                                          .foregroundColor : UIColor.init(hexString: "#C4C4C4")];
        let titleString = NSMutableAttributedString.init(string: "Notes", attributes: titleAttrs)
        let titleLocation = CGPoint(x: titleX,
                                    y: titleY)
        titleString.draw(at: titleLocation)
        
        let dayFont = UIFont.robotoMedium(screenInfo.fontsInfo.prioritiesPageDetails.dayFontSize)
        let dayNewFontSize = UIFont.getScaledFontSizeFor(font: dayFont, screenSize: currentPageRect.size, minPointSize: 25)
        
        let weekInfoAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.robotoMedium(dayNewFontSize),
                                                             NSAttributedString.Key.kern : 0.0,
                                                             .foregroundColor : UIColor.init(hexString: "#4FA4FF")];
        let todayPillXOffsetPercnt = formatInfo.customVariants.isLandscape ? 1.25 : 1.67 // gap between today pill and day/week info
        if let weekInfo = weeklyInfo{
            // week info drawing
            let weekFirstDate = weekInfo.dayInfo.first
            let weekLastDate = weekInfo.dayInfo.last
            var weekDurationText : String = ""
            if weekFirstDate?.month == weekLastDate?.month {
                weekDurationText =  weekInfo.dayInfo.first?.monthString ?? ""
                weekDurationText += " " + (weekInfo.dayInfo.first?.fullDayString ?? "") + " - "
                weekDurationText += (weekInfo.dayInfo.last?.fullDayString ?? "")
            }
            else{
                weekDurationText += (weekInfo.dayInfo.first?.monthString ?? "") + " " + (weekInfo.dayInfo.first?.fullDayString ?? "") + " - "
                weekDurationText +=  (weekInfo.dayInfo.last?.monthString ?? "") + " " + (weekInfo.dayInfo.last?.fullDayString ?? "")
            }
            let weekInfoAttrString = NSMutableAttributedString.init(string:weekDurationText , attributes: weekInfoAttrs)
            let weekInfoRectX = bezierBGXAxis + bezierBGWidth - weekInfoAttrString.size().width
            let weekInfoRectY = (currentPageRect.height*notesTemplateInfo.dayInfoY)/100
            let weekInfoRect = CGRect(x: weekInfoRectX, y: weekInfoRectY, width: weekInfoAttrString.size().width, height: weekInfoAttrString.size().height)
            let weekInfoDrawLocation = CGPoint(x: weekInfoRect.origin.x, y: weekInfoRect.origin.y)
            weekInfoAttrString.draw(at: weekInfoDrawLocation)
            weekNotesInfo.append(FTDiaryWeeklyNotesRectInfo(weekRect:getLinkRect(location: weekInfoDrawLocation, frameSize: weekInfoAttrString.size())))
            //Today pill
            let weekInfoXPercnt = (weekInfoRect.origin.x/currentPageRect.width)*100
            let rightXOffsetPercnt = 100.0 - (weekInfoXPercnt - todayPillXOffsetPercnt)
            self.addTodayPillWith(rightXOffsetPercent: rightXOffsetPercnt, toContext: context)
        }
        if let dayInfo = dayInfo {
            let monthString = dayInfo.monthString
            let weekString = dayInfo.dayString
            let dayInfoString = monthString + " " + weekString
            let dayInfoAttrString = NSMutableAttributedString.init(string:dayInfoString , attributes: weekInfoAttrs)
            let dayInfoRectX = bezierBGXAxis + bezierBGWidth - dayInfoAttrString.size().width
            let dayInfoRectY = (currentPageRect.height*notesTemplateInfo.dayInfoY)/100
            let dayInfoRect = CGRect(x: dayInfoRectX, y: dayInfoRectY, width: dayInfoAttrString.size().width, height: dayInfoAttrString.size().height)
            let dayInfoDrawLocation = CGPoint(x: dayInfoRect.origin.x, y: dayInfoRect.origin.y)
            dayInfoAttrString.draw(at: dayInfoDrawLocation)
            dailyNotesInfo.append(FTDiaryDailyNotesRectInfo(dayRect: getLinkRect(location: dayInfoDrawLocation, frameSize: dayInfoAttrString.size())))
            //Today pill
            let dayInfoXPercnt = (dayInfoRect.origin.x/currentPageRect.width)*100
            let rightXOffsetPercnt = 100.0 - (dayInfoXPercnt - todayPillXOffsetPercnt)
            self.addTodayPillWith(rightXOffsetPercent: rightXOffsetPercnt, toContext: context)
        }
    }
}
