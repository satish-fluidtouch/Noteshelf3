//
//  FTPlannerDiaryiPadFormat.swift
//  Noteshelf
//
//  Created by Ramakrishna on 09/11/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

class FTPlanner2024DiaryiPadFormat : FTPlanner2024DiaryFormat {

    let twoSpreadHorizontalGap: CGFloat = 7.19
    var twoSpreadGap: CGFloat {
        return currentPageRect.width*twoSpreadHorizontalGap/100
    }

    override func renderCalendarPage(context: CGContext, months: [FTMonthlyCalendarInfo], calendarYear: FTYearFormatInfo) {

        self.renderPlannerDiaryPDF(context: context, pdfTemplatePath: self.calendarTemplate,pdfTemplate: nil)

        // today link
        self.addTodayLink(toContext : context)


        let templateInfo = screenInfo.spacesInfo.calendarSpacesInfo
        var currMonthIndex = CGFloat(0)
        let columnCount = getColumnCount()
        let rowCount = getRowCount()
        let cellWidth = getYearCellWidth(columnCount: columnCount)
        let cellHeight = getYearCellHeight(rowCount: rowCount)

        // Rendering year
        let yearFont = UIFont.clearFaceFont(for: .regular, with:screenInfo.fontsInfo.yearPageDetails.yearFontSize)
        var yearNewFontSize = UIFont.getScaledFontSizeFor(font: yearFont, screenSize: currentPageRect.size, minPointSize: 18)
        if self.layoutRequiresExplicitFont(){
            yearNewFontSize = 15
        }
        let yearAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.clearFaceFont(for: .regular, with: yearNewFontSize),
                                                        .kern: 1.6,
                                                        .foregroundColor: textTintColor]
        if let startYear = months.first?.year {
            var year: String = "\(startYear)"
            if let endYear = months.last?.year, endYear != startYear {
                let endYearXX = "\(endYear)".suffix(2)
                year = "\(startYear)" +  "-" + "\(endYearXX)"
            }
            let yearString = NSMutableAttributedString.init(string: year, attributes: yearAttrs)
            let yearRect = CGRect(x: (currentPageRect.width*templateInfo.yearX/100), y: (currentPageRect.height*templateInfo.yearY/100), width: yearString.size().width, height: yearString.size().height)
            let yearLocation = CGPoint(x: yearRect.origin.x, y: yearRect.origin.y)
            yearString.draw(at: yearLocation)
        }

        let monthStringOffsetYPercnt = 5.03
        let monthStringOffsetY = (currentPageRect.height*monthStringOffsetYPercnt)/100

        let  baseBoxY = templateInfo.baseBoxY

        var monthY = (currentPageRect.height*baseBoxY/100) - monthStringOffsetY
        var dayRects : [CGRect] = []
        let paragraphStyle = NSMutableParagraphStyle.init()
        paragraphStyle.alignment = .center

        var monthX = (currentPageRect.size.width*templateInfo.baseBoxX/100)
        var dayX = (currentPageRect.size.width*templateInfo.baseBoxX/100)
        let horizontalGapBetweenSplitColumns: CGFloat = 7.19
        months.forEach { (month) in
            dayRects.removeAll()

            // rendering month
            let monthFont = UIFont.InterMedium(screenInfo.fontsInfo.yearPageDetails.titleMonthFontSize)
            let monthNewFontSize = UIFont.getScaledFontSizeFor(font: monthFont, screenSize: currentPageRect.size, minPointSize: 8)
            let monthAttrs : [NSAttributedString.Key: Any] = [.font : UIFont.clearFaceFont(for: .regular, with: 11),
                                                              NSAttributedString.Key.kern : 1.6,
                                                              .foregroundColor : textTintColor,
                                                              .paragraphStyle :paragraphStyle]
            let monthString = NSMutableAttributedString(string: month.fullMonth.uppercased(), attributes: monthAttrs)
            var widthFactor = currMonthIndex.truncatingRemainder(dividingBy: 2) * (cellWidth + (currentPageRect.size.width*templateInfo.cellOffsetX/100))
            if  currMonthIndex > 5 {
                let noOfCellsToConsider = (currMonthIndex.truncatingRemainder(dividingBy: 2) + 2)
                let cellsWidth = (noOfCellsToConsider * cellWidth)
                let cellsXOffset = (noOfCellsToConsider - 1) * (currentPageRect.size.width*templateInfo.cellOffsetX/100)
                widthFactor =  cellsWidth + cellsXOffset + currentPageRect.size.width*horizontalGapBetweenSplitColumns/100
            }
            if formatInfo.customVariants.selectedDevice.identifier == "standard4"{
                widthFactor += 0.5
            }
            monthX = (currentPageRect.size.width*templateInfo.baseBoxX/100) + widthFactor
            let monthRectHeighPercnt = 2.39
            let monthRectHeight = currentPageRect.size.height*monthRectHeighPercnt/100
            let monthRect =  CGRect(x: monthX, y: monthY + (monthRectHeight/2) - (monthString.size().height/2), width: cellWidth, height: monthRectHeight)
            if let bandColor = monthStripColors["\(month.fullMonth.uppercased())"] {
                self.drawColorBandsWith(xAxis: monthX, yAxis: monthY, context: context, width: cellWidth, height: monthRectHeight, bandColor: UIColor(hexString: bandColor))
            }
            monthString.draw(in: monthRect)
            calendarRectsInfo.monthRects.append(getLinkRect(location: CGPoint(x:monthX, y: monthY), frameSize:CGSize(width: cellWidth, height: monthRectHeight)))


            // Rendering week symbol
            var dayCellWidth = (cellWidth - 7*0.5)/7 // deducting day box border width
            let dayCellHeight = (cellHeight - 6*0.5)/6 // deducting day box border height

            let symbols = getWeekSymbols(monthInfo: month)
            let weekStringOffsetYPercnt = formatInfo.customVariants.isLandscape ? 1.16 : 0.85
            let weekSymbolFont = UIFont.InterLight(8)
            var weekSymbolNewFontSize = UIFont.getScaledFontSizeFor(font: weekSymbolFont, screenSize: currentPageRect.size, minPointSize: 8)

            if self.layoutRequiresExplicitFont() {
                weekSymbolNewFontSize = 6
                dayCellWidth = cellWidth/7
            }

            let symbolAttrs: [NSAttributedString.Key : Any] =  [.font :UIFont.clearFaceFont(for: .regular, with:10),
                                                                NSAttributedString.Key.kern : 1.6,
                                                                .foregroundColor : textTintColor,
                                                                .paragraphStyle: paragraphStyle];

            var symbolX = (currentPageRect.size.width*templateInfo.baseBoxX/100) + widthFactor //+ monthStringX

            symbols.forEach({(symbol) in
                let symbolString = NSMutableAttributedString.init(string: symbol,attributes: symbolAttrs)
                let symbolY = monthY + monthRect.size.height + (currentPageRect.size.height*weekStringOffsetYPercnt/100)
                let symbolStringHeight = (currentPageRect.size.height*weekStringOffsetYPercnt/100)
                if formatInfo.customVariants.selectedDevice.identifier == "standard2" && !formatInfo.customVariants.isLandscape{
                    symbolX += 0.5
                }
                symbolString.draw(in: CGRect(x: symbolX, y:symbolY  + (symbolStringHeight/2) - (symbolString.size().height/2), width: dayCellWidth, height: symbolString.size().height))
                symbolX += dayCellWidth
            }
            )
            var dayX = (currentPageRect.size.width*templateInfo.baseBoxX/100) + widthFactor //+ monthStringX
            var dayY = monthY + monthStringOffsetY + 0.5

            if isA5LandscapeLayout() {
                dayY += 1
            }
            var index = 1;

            month.dayInfo.forEach({(day) in
                if day.belongsToSameMonth {
                    let dayAttrs: [NSAttributedString.Key: Any] = symbolAttrs

                    let dayString = NSMutableAttributedString.init(string: day.dayString, attributes: dayAttrs)
                    if formatInfo.customVariants.selectedDevice.identifier == "standard2" && !formatInfo.customVariants.isLandscape {
                        dayX += 0.5
                    }
                    let drawRect = CGRect(x: dayX , y: dayY + dayCellHeight/2 - (dayString.size().height/2) , width: dayCellWidth, height: dayCellHeight)
                    dayString.draw(in: drawRect)
                    dayRects.append(getLinkRect(location: CGPoint(x: dayX, y: dayY), frameSize: CGSize(width: dayCellWidth, height: dayCellHeight)))
                }
                index += 1;
                if(index > 7) {
                    index = 1;
                    dayX = (currentPageRect.size.width*templateInfo.baseBoxX/100) + widthFactor
                    dayY += dayCellHeight + 0.5
                }
                else {
                    dayX += dayCellWidth
                }
            })
            calendarRectsInfo.dayRects.append(dayRects)
            currMonthIndex+=1
            let numberOfColunms = columnCount
            if currMonthIndex.truncatingRemainder(dividingBy: 2) == 0 {
                monthX = currMonthIndex < 6 ? (currentPageRect.size.width*templateInfo.baseBoxX/100) : ((currentPageRect.size.width*templateInfo.baseBoxX/100)  + 2*cellWidth + currentPageRect.size.height*templateInfo.cellOffsetX/100 + currentPageRect.size.width*horizontalGapBetweenSplitColumns/100)
                monthY = (currMonthIndex == 6) ? (currentPageRect.height*baseBoxY/100.0) - monthStringOffsetY : monthY + cellHeight + (currentPageRect.height*templateInfo.cellOffsetY/100.0)
            } else {
                monthX += cellWidth + (currentPageRect.size.width*templateInfo.cellOffsetX/100)
            }
        }
        self.renderTxtAndColorsOnSideNavigationStrip(context: context,type: FTPlannerDiaryTemplateType.calendar, activeMonth: nil)
    }
    override func renderYearPage(atIndex index: Int, context: CGContext, months: [FTMonthInfo], calendarYear: FTYearFormatInfo) {
        self.renderPlannerDiaryPDF(context: context, pdfTemplatePath: self.yearTemplate,pdfTemplate: nil)
        // today link
        self.addTodayLink(toContext : context)

        let templateInfoSpacesInfo = screenInfo.spacesInfo.yearPageSpacesInfo

        //title rendering

        let yearX = self.currentPageRect.width*templateInfoSpacesInfo.yearX/100
        var yearYPercnt = templateInfoSpacesInfo.yearY

        if isA5LandscapeLayout() {
            yearYPercnt = 4.00
        }
        let yearY = self.currentPageRect.height*yearYPercnt/100
        let paragraphStyle1 = NSMutableParagraphStyle.init()
        paragraphStyle1.alignment = .left

        let yearPlannerFont = UIFont.clearFaceFont(for: .regular, with:screenInfo.fontsInfo.yearPageDetails.yearFontSize)
        var yearPlannerNewFontSize = UIFont.getScaledFontSizeFor(font: yearPlannerFont, screenSize: currentPageRect.size, minPointSize: 18)
        if self.layoutRequiresExplicitFont(){
            yearPlannerNewFontSize = 15
        }

        let yearPlannerAttrs : [NSAttributedString.Key: Any] = [.font : UIFont.clearFaceFont(for: .regular, with:yearPlannerNewFontSize),
                                                          NSAttributedString.Key.kern : 1.6,
                                                          .foregroundColor : textTintColor,
                                                         .paragraphStyle : paragraphStyle1]

        let yearplannerString = NSMutableAttributedString(string: "Yearly Planner".uppercased(), attributes: yearPlannerAttrs)
        let yearPlannerRect = CGRect(x: yearX, y: yearY, width: yearplannerString.size().width, height: yearplannerString.size().height)
        yearplannerString.draw(in: yearPlannerRect)

        // months rendering
        let isLandscaped = self.formatInfo.customVariants.isLandscape
        let boxWidth : CGFloat = 18.34
        let boxHeight : CGFloat = 77.21
        let startingXAxis : CGFloat = templateInfoSpacesInfo.baseBoxX
        let startingYAxis : CGFloat = templateInfoSpacesInfo.baseBoxY
        let horizontalGapBWBoxes : CGFloat = templateInfoSpacesInfo.cellOffsetX
        let verticalGapBWBoxes : CGFloat = templateInfoSpacesInfo.cellOffsetY

        let xAxis : CGFloat = self.currentPageRect.size.width*startingXAxis/100
        var monthBoxesYAxis : CGFloat = self.currentPageRect.size.height*startingYAxis/100
        var monthBoxesXAXis : CGFloat = xAxis

        let widthPerBox = self.currentPageRect.size.width*boxWidth/100
        let heightPerBox = self.currentPageRect.size.height*boxHeight/100

        let colorBandHeightPercnt = 2.39

        let colorBandHeight = self.currentPageRect.size.height*colorBandHeightPercnt/100

        let numberOfColumns : Int = 4
        let numberOfMonthBoxes : Int = 4
        let paragraphStyle = NSMutableParagraphStyle.init()
        paragraphStyle.alignment = .center

        let monthFont = UIFont.clearFaceFont(for: .regular, with:screenInfo.fontsInfo.yearPageDetails.titleMonthFontSize)
        let monthNewFontSize = UIFont.getScaledFontSizeFor(font: monthFont, screenSize: currentPageRect.size, minPointSize: 8)
        let monthAttrs : [NSAttributedString.Key: Any] = [.font : UIFont.clearFaceFont(for: .regular, with:monthNewFontSize),
                                                          NSAttributedString.Key.kern : 1.6,
                                                          .foregroundColor : textTintColor,
                                                          .paragraphStyle :paragraphStyle]
        // month colors band rendering
        var monthRects : [CGRect] = []
        for i in 1...numberOfMonthBoxes {
            if let bandColor = monthStripColors["\(months[numberOfMonthBoxes*(index - 1) + (i - 1)].monthTitle.uppercased())"] {
                self.drawYearPageMonthColorBandsWith(xAxis: monthBoxesXAXis, yAxis: monthBoxesYAxis, context: context, width: widthPerBox, height: colorBandHeight, bandColor:UIColor(hexString: bandColor))
                monthRects.append(self.getLinkRect(location: CGPoint(x: monthBoxesXAXis, y: monthBoxesYAxis), frameSize: CGSize(width: widthPerBox, height: colorBandHeight)))
            }
            let monthString = NSMutableAttributedString(string: months[numberOfMonthBoxes*(index - 1) + (i - 1)].monthTitle.uppercased(), attributes: monthAttrs)
            let monthRect = CGRect(x: monthBoxesXAXis, y: monthBoxesYAxis + (colorBandHeight/2) - (monthString.size().height/2), width: widthPerBox, height: colorBandHeight)
            monthString.draw(in: monthRect)
            if i % 2 == 0 {
                monthBoxesXAXis = xAxis + 2*(widthPerBox) + (self.currentPageRect.size.width*horizontalGapBWBoxes/100) + twoSpreadGap
            } else {
                monthBoxesXAXis += widthPerBox + (self.currentPageRect.size.width*horizontalGapBWBoxes/100)
            }
        }
        yearRectsInfo.monthRects.append(contentsOf: monthRects)
        // Year at glance rendering
        self.renderTxtAndColorsOnSideNavigationStrip(context: context,type: FTPlannerDiaryTemplateType.year, activeMonth: nil)

        yearRectsInfo.yearPageNumRects = self.drawPageNumbersFor(type: FTPlannerDiaryTemplateType.year, currentPageIndex: index, context: context)
    }
    override func renderMonthPage(context: CGContext, monthInfo: FTMonthlyCalendarInfo, calendarYear: FTYearFormatInfo) {
        self.renderPlannerDiaryPDF(context: context, pdfTemplatePath: self.monthTemplate,pdfTemplate: self.monthPagePDFDocument)
        // today link
        self.addTodayLink(toContext : context)

        self.renderTxtAndColorsOnSideNavigationStrip(context: context,type: FTPlannerDiaryTemplateType.month, activeMonth: monthInfo)
        let currentMonthRectsInfo = FTDiaryMonthRectsInfo()
        let templateInfo = screenInfo.spacesInfo.monthPageSpacesInfo
        let isLandscape = self.formatInfo.customVariants.isLandscape

        let boxWidth : CGFloat = 8.90
        let boxHeight : CGFloat = 10.67

        let cellWidth = currentPageRect.width*boxWidth/100
        let cellHeight = currentPageRect.height*boxHeight/100

        let monthXPercnt : CGFloat = 7.46
        let monthX = self.currentPageRect.width*monthXPercnt/100
        let monthY = currentPageRect.height*templateInfo.monthY/100

        let font = UIFont.clearFaceFont(for: .regular, with: screenInfo.fontsInfo.monthPageDetails.monthFontSize)
        var newFontSize = UIFont.getScaledFontSizeFor(font: font, screenSize: currentPageRect.size, minPointSize: 18)
        if self.layoutRequiresExplicitFont() {
            newFontSize = 15
        }
        let monthAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.clearFaceFont(for: .regular, with:newFontSize),
                                                         .kern: 1.6,
                                                        .foregroundColor: textTintColor]

        let monthString = NSMutableAttributedString.init(string: monthInfo.fullMonth.uppercased() + " " + monthInfo.year, attributes: monthAttrs)
        let monthLocation = CGPoint(x: monthX, y: monthY )
        monthString.draw(in: CGRect(x: monthLocation.x, y: monthLocation.y, width: monthString.size().width, height: monthString.size().height))
        currentMonthRectsInfo.monthRect = getLinkRect(location: monthLocation, frameSize: monthString.size())

        // For week Number drawing
        let weekXPercnt : CGFloat = 7.55
        let weekRectheightPercnt : CGFloat = 2.39

        let weekX = (currentPageRect.width*weekXPercnt/100)
        let weekYPercnt = templateInfo.baseBoxY
        var weekY = (currentPageRect.height*weekYPercnt/100)
        let weekRectHeight = (currentPageRect.height*weekRectheightPercnt/100)

        let weekFont = UIFont.clearFaceFont(for: .regular, with: screenInfo.fontsInfo.monthPageDetails.weekFontSize)
        var weekNewFontSize = UIFont.getScaledFontSizeFor(font: weekFont, screenSize: currentPageRect.size, minPointSize: 8)
        let paragraphStyle = NSMutableParagraphStyle.init()
        paragraphStyle.alignment = .center
        var colorBGCornerRaidus : CGFloat = 4.0
        if self.formatInfo.customVariants.selectedDevice.identifier == "standard4" {
            weekNewFontSize = 7
        }
        if self.layoutRequiresExplicitCrnerRadiusFrColrdBG(){
            colorBGCornerRaidus = 3.0
        }
        var weekNumberTextAttribute: [NSAttributedString.Key : Any] = [.font : UIFont.clearFaceFont(for: .regular, with:weekNewFontSize),
                                                                       NSAttributedString.Key.kern : 1.3,
                                                                        .paragraphStyle : paragraphStyle]
        var weekRects : [CGRect] = []
        weekNumbers.removeAll()

        for (index, day) in monthInfo.dayInfo.enumerated() {
            let weekNumberOBJ = FTPlannerWeekNumber()
            if index == 0 {
                weekNumberOBJ.weekNumber = "WEEK \(day.weekNumber)"
                weekNumberOBJ.isActive = true
                weekNumbers.append(weekNumberOBJ)
            }
            else if index % 7 == 0  {
                if day.fullMonthString == monthInfo.fullMonth{
                    weekNumberOBJ.weekNumber = "WEEK \(day.weekNumber)"
                    weekNumberOBJ.isActive = true
                }
                else {
                    weekNumberOBJ.weekNumber = "WEEK \(day.weekNumber)"
                    weekNumberOBJ.isActive = false
                }
                weekNumbers.append(weekNumberOBJ)
            }
        }

        let cellOffsetY = templateInfo.cellOffsetY

        var weekNumberStripColorIndex  :Int = 1
        let weekNumberWidthPercent: CGFloat = 8.90
        let weekNumberWidth = currentPageRect.width*weekNumberWidthPercent/100
        for week in weekNumbers {
            let dayForeGroundColor = textTintColor
            weekNumberTextAttribute[.foregroundColor] = dayForeGroundColor
            let weekString = NSMutableAttributedString.init(string: week.weekNumber,attributes: weekNumberTextAttribute)
            let weekNumWidth = weekString.size().width
            let weekRect = CGRect(x: weekX + (weekNumberWidth/2) - (weekNumWidth/2), y: weekY + (weekRectHeight/2) - (weekString.size().height/2) + 0.5, width: weekNumWidth, height: weekRectHeight)
            if week.isActive, let stripColor = weekNumberStripColors[weekNumberStripColorIndex]{
                self.drawColorBandsWith(xAxis: weekX, yAxis: weekY, context: context, width: weekNumberWidth, height: weekRectHeight, bandColor: UIColor(hexString: stripColor),cornerRadius: colorBGCornerRaidus)
            }
            else{
                self.drawColorBandsWith(xAxis: weekX, yAxis: weekY, context: context, width: weekNumberWidth, height: weekRectHeight, bandColor: notesBandBGColor,cornerRadius: colorBGCornerRaidus)
            }
            weekNumberStripColorIndex += 1
            weekString.draw(in: weekRect)
            if (week.isActive){ // if weeks is active adding link to it
                weekRects.append(getLinkRect(location: CGPoint(x: weekX, y: weekY), frameSize: CGSize(width: weekNumberWidth, height: weekRectHeight)))
            }
            weekY += cellHeight + (currentPageRect.height*cellOffsetY/100)
        }
        currentMonthRectsInfo.weekRects.append(contentsOf: weekRects)


        let symbols = getWeekSymbols(monthInfo: monthInfo)

        let symbolAttrs: [NSAttributedString.Key : Any] = weekNumberTextAttribute
        let weekSymbolYOffsetPercent  : CGFloat = 1.19
        let weekSymbolYOffset = self.currentPageRect.height*weekSymbolYOffsetPercent/100
        var symbolX = (currentPageRect.width*templateInfo.baseBoxX/100)
        var symbolY = (currentPageRect.height*weekYPercnt/100) - weekSymbolYOffset
        let twoSpreadHorizontalGap: CGFloat = 7.19
        let twoSpreadGap = currentPageRect.width*twoSpreadHorizontalGap/100
        for i in 1...symbols.count {
            let symbol = symbols[i - 1]
            let symbolString = NSMutableAttributedString.init(string: symbol,attributes: symbolAttrs)
            let symbolHeight = symbolString.size().height
            symbolString.draw(in: CGRect(x: symbolX + (cellWidth/2) - symbolString.size().width/2 , y:symbolY - symbolHeight, width: symbolString.size().width, height: symbolHeight))
            symbolX += i == 3 ? cellWidth + twoSpreadGap : cellWidth + (currentPageRect.width*templateInfo.cellOffsetX/100)
        }

        let dayRectWidthpercnt = 1.70
        let dayRectHeightPercnt = 2.27

        let dayRectWidth = self.currentPageRect.width*dayRectWidthpercnt/100
        let dayrectHeight = self.currentPageRect.height*dayRectHeightPercnt/100

        var dayX = (currentPageRect.width*templateInfo.baseBoxX/100) + cellWidth
        var linkX = (currentPageRect.width*templateInfo.baseBoxX/100)
        var dayY = (currentPageRect.height*weekYPercnt/100) + cellHeight
        var index = 1;

        var weekDayBGColorIndex = 1;
        var weekDayBgColor = weekNumberStripColors[weekDayBGColorIndex];


        let dayFont = UIFont.clearFaceFont(for: .regular, with: screenInfo.fontsInfo.monthPageDetails.dayFontSize)
        var dayNewFontSize = UIFont.getScaledFontSizeFor(font: dayFont, screenSize: currentPageRect.size, minPointSize: 8)
        if self.formatInfo.customVariants.selectedDevice.identifier == "standard4"{
            dayNewFontSize = 6
        }
        var dayAttrs: [NSAttributedString.Key: Any] = [.font :UIFont.clearFaceFont(for: .regular, with:dayNewFontSize),
                                                       NSAttributedString.Key.kern : 1.15,
                                                       .paragraphStyle: paragraphStyle];

        var weekDayWidth : CGFloat = 0
        monthInfo.dayInfo.forEach({(day) in
            let dayString = NSMutableAttributedString.init(string: day.dayString, attributes: dayAttrs)
            if dayString.size().width > weekDayWidth {
                weekDayWidth = dayString
                    .size().width
            }
        })
        var counter: Int = 1
        monthInfo.dayInfo.forEach({(day) in
            let dayForeGroundColor = (day.belongsToSameMonth && isBelongToCalendarYear(currentDate: day.date)) ? textTintColor : textTintColor.withAlphaComponent(0.6)

            dayAttrs[.foregroundColor] = dayForeGroundColor
            let dayString = NSMutableAttributedString.init(string: day.dayString, attributes: dayAttrs)
            let dayColorRect = CGRect(x: dayX - 10 - weekDayWidth, y: dayY - dayrectHeight - 5, width: weekDayWidth + 6, height: dayrectHeight)
            let dayTextRect = CGRect(x: dayX - 10 - weekDayWidth + 3.5, y: dayY - 5 - (dayrectHeight/2) - (dayString.size().height/2), width: weekDayWidth , height: dayrectHeight)
            if let stripColor = weekDayBgColor,isBelongToCalendarYear(currentDate: day.date){
                if day.belongsToSameMonth {
                    self.drawColorBandsWith(xAxis: dayColorRect.origin.x, yAxis: dayColorRect.origin.y, context: context, width: dayColorRect.width, height: dayColorRect.height, bandColor: UIColor(hexString: stripColor),cornerRadius: colorBGCornerRaidus)
                    currentMonthRectsInfo.dayRects.append(getLinkRect(location: CGPoint(x: dayColorRect.origin.x, y: dayColorRect.origin.y), frameSize: CGSize(width: dayColorRect.width, height: dayColorRect.height)))
                }
            }
            dayString.draw(in:dayTextRect)

            if(index % 7 == 0) {
                counter = 1
                weekDayBGColorIndex += 1
                weekDayBgColor = weekNumberStripColors[weekDayBGColorIndex]
                dayX = (currentPageRect.width*templateInfo.baseBoxX/100) + cellWidth;
                linkX = (currentPageRect.width*templateInfo.baseBoxX/100)
                dayY += cellHeight + (currentPageRect.height*cellOffsetY/100);
            }
            else {
                dayX += counter == 3 ? (cellWidth + twoSpreadGap) : cellWidth + (currentPageRect.width*templateInfo.cellOffsetX/100)
                linkX += cellWidth + (currentPageRect.width*templateInfo.cellOffsetX/100)
                counter += 1
            }
            index += 1;
        })
        self.drawTopNavigationWidgetFor(type : FTPlannerDiaryTemplateType.month, context : context)
        monthRectsInfo.append(currentMonthRectsInfo)
    }
    override func renderWeekPage(context: CGContext, weeklyInfo: FTWeekInfo,monthInfo: FTMonthlyCalendarInfo) {
        currentWeekRectInfo = FTDiaryWeekRectsInfo()
        self.renderPlannerDiaryPDF(context: context, pdfTemplatePath: self.weekTemplate,pdfTemplate: self.weekPagePDFDocument)
        // today link
        self.addTodayLink(toContext : context)

        self.renderTxtAndColorsOnSideNavigationStrip(context: context,type: FTPlannerDiaryTemplateType.week, activeMonth: monthInfo)
        self.drawTopNavigationWidgetFor(type : FTPlannerDiaryTemplateType.week, context : context)

        let templateInfo = screenInfo.spacesInfo.weekPageSpacesInfo
        let isLandscaped = self.formatInfo.customVariants.isLandscape

        //Week Number rendering

        let titleY = currentPageRect.height*templateInfo.titleLineY/100
        let titleX = currentPageRect.width*templateInfo.baseBoxX/100

        let titleFont = UIFont.clearFaceFont(for: .regular, with:  screenInfo.fontsInfo.weekPageDetails.weekFontSize)
        let yearFont = UIFont.clearFaceFont(for: .regular, with:   screenInfo.fontsInfo.weekPageDetails.yearFontSize)
        var titleNewFontSize = UIFont.getScaledFontSizeFor(font: titleFont, screenSize: currentPageRect.size, minPointSize: 18)
        var yearNewFontSize = UIFont.getScaledFontSizeFor(font: yearFont, screenSize: currentPageRect.size, minPointSize: 12)
        if self.layoutRequiresExplicitFont(){
            titleNewFontSize = 15
            yearNewFontSize = 12
        }
        let titleAttrs: [NSAttributedString.Key: Any] = [.font :UIFont.clearFaceFont(for: .regular,with: titleNewFontSize),
                                                       NSAttributedString.Key.kern : 1.6,
                                                       .foregroundColor : textTintColor];
        let yearAttrs: [NSAttributedString.Key: Any] = [.font :UIFont.clearFaceFont(for: .regular,with: yearNewFontSize),
                                                       NSAttributedString.Key.kern : 1.6,
                                                       .foregroundColor : textTintColor];
        let yearString = monthInfo.year
        if let weekNumber = weeklyInfo.dayInfo.first?.weekNumber {

            let weekNum = "Week " + "\(weekNumber)"

            let titleString = NSMutableAttributedString.init(string: "\(monthInfo.fullMonth)".uppercased() + ", " + weekNum.uppercased() , attributes: titleAttrs)
            let titleRect = CGRect(x: titleX, y: titleY, width: titleString.size().width, height: titleString.size().height)
            titleString.draw(in: titleRect)

            let yearString = NSMutableAttributedString.init(string: "\(yearString)", attributes: yearAttrs)
            let yearYOffsetPercent: CGFloat = 0.83
            let yearYOffset = currentPageRect.height*yearYOffsetPercent/100
            let yearY = titleY + titleString.size().height + yearYOffset

            let yearRect = CGRect(x: titleX, y: yearY, width: yearString.size().width, height: yearString.size().height)
            yearString.draw(in: yearRect)
        }


        //days rendering
        var index = 0
        var weekDayfont = UIFont.clearFaceFont(for: .regular, with: screenInfo.fontsInfo.weekPageDetails.dayFontSize)
        if self.layoutRequiresExplicitFont(){
            weekDayfont = UIFont.clearFaceFont(for: .regular, with:6)
        }
        let weekDayRectWidthPercnt = isLandscaped ? 5.39  : 6.95
        let weekDayRectHeightPercnt = isLandscaped ? 2.33 : 1.94

        var weekDayInfoY = currentPageRect.height*templateInfo.baseBoxY/100
        var weekDayInfoX = currentPageRect.width*templateInfo.baseBoxX/100
        let weekDayRectWidth = currentPageRect.width*weekDayRectWidthPercnt/100
        let weekDayRectHeigth = currentPageRect.height*weekDayRectHeightPercnt/100

        var weekDayRects : [CGRect] = []
        let numberOfDaysInRow = isLandscaped ? 4 : 5
        weeklyInfo.dayInfo.forEach(({(weekDay) in
            let dayTextColor = isBelongToCalendarYear(currentDate: weekDay.date) ? textTintColor : textTintColor.withAlphaComponent(0.6)
            let weekAttrs: [NSAttributedString.Key: Any] = [.font: weekDayfont,
                                                            .kern: 1.6,
                                                            .foregroundColor: dayTextColor]
            let weekAndDayText = weekDay.weekShortString.uppercased() + " " + weekDay.fullDayString
            let weekAndDayString = NSMutableAttributedString.init(string: weekAndDayText, attributes: weekAttrs)

            let weekAndDayStringWidth = weekAndDayString.size().width

            let weekDayRect = CGRect(x: weekDayInfoX + 5 + 3.5 , y:weekDayInfoY + 5 + (weekDayRectHeigth/2) - (weekAndDayString.size().height/2), width: weekAndDayStringWidth, height: weekDayRectHeigth)
            if isBelongToCalendarYear(currentDate: weekDay.date){
                let weekDayPastalColorsDict = weekDaysPastalColors
                self.drawColorBandsWith(xAxis: weekDayInfoX + 5 , yAxis: weekDayInfoY + 5, context: context, width: weekAndDayStringWidth + 6, height: weekDayRectHeigth, bandColor: UIColor(hexString: weekDayPastalColorsDict[index]), cornerRadius: 5)
            } 
            weekAndDayString.draw(in: weekDayRect)

            if isBelongToCalendarYear(currentDate: weekDay.date) {
                weekDayRects.append(getLinkRect(location: CGPoint(x: weekDayInfoX + 5, y: weekDayInfoY + 5),
                                                frameSize: CGSize(width: weekAndDayStringWidth + 6, height: weekDayRectHeigth)))
            }
            index += 1
            if index % numberOfDaysInRow == 0{
                weekDayInfoY = currentPageRect.height*templateInfo.baseBoxY/100
                weekDayInfoX = currentPageRect.width*templateInfo.baseBoxX/100 + currentPageRect.width*templateInfo.cellOffsetX/100 + currentPageRect.width*templateInfo.cellWidth/100
            }
            else{
                let cellHeight = templateInfo.cellHeight
                let cellOffsetY = templateInfo.cellOffsetY
                weekDayInfoY += currentPageRect.height*cellHeight/100 + (currentPageRect.height*cellOffsetY/100)
            }
        }))
        let notesAttrs: [NSAttributedString.Key: Any] = [.font: weekDayfont,
                                                        .kern: 1.6,
                                                        .foregroundColor: textTintColor]
        // for rendering notes strip and text
        let notesString = NSMutableAttributedString.init(string: "NOTES", attributes: notesAttrs)

        let notesRect = CGRect(x: weekDayInfoX + 5 + 3.5 , y:weekDayInfoY + 5 + (weekDayRectHeigth/2) - (notesString.size().height/2), width: notesString.size().width + 6, height: weekDayRectHeigth)
        self.drawColorBandsWith(xAxis: weekDayInfoX + 5 , yAxis: weekDayInfoY + 5, context: context, width: notesString.size().width + 6, height: weekDayRectHeigth, bandColor: notesBandBGColor, cornerRadius: 5)
        notesString.draw(in: notesRect)

        currentWeekRectInfo.weekDayRects.append(contentsOf: weekDayRects)
        weekRectsInfo.append(currentWeekRectInfo)
    }
    override func renderDayPage(context: CGContext, dayInfo: FTDayInfo,monthInfo: FTMonthlyCalendarInfo) {
        if !dayInfo.belongsToSameMonth {
            return
        }
        self.renderPlannerDiaryPDF(context: context, pdfTemplatePath: self.dayTemplate,pdfTemplate: self.dayPagePDFDocument)
        self.renderTxtAndColorsOnSideNavigationStrip(context: context,type: FTPlannerDiaryTemplateType.day, activeMonth: monthInfo)
        self.drawTopNavigationWidgetFor(type : FTPlannerDiaryTemplateType.day, context : context)

        let templateInfo = screenInfo.spacesInfo.dayPageSpacesInfo

        // today link
        self.addTodayLink(toContext : context)

        //title rendering
        let isLandscaped = formatInfo.customVariants.isLandscape
        let titleYPercnt : CGFloat = 11.75
        let titleXPercnt : CGFloat = 7.46

        let titleX = currentPageRect.width*titleXPercnt/100
        let titleY = currentPageRect.height*titleYPercnt/100

        let titleText = monthInfo.fullMonth.uppercased() + " " + dayInfo.fullDayString + ", " + dayInfo.weekString.uppercased()

        let titleFont = UIFont.clearFaceFont(for: .regular, with: screenInfo.fontsInfo.dayPageDetails.monthFontSize)
        var letterSpacing : CGFloat = 1.6
        var titleNewFontSize = UIFont.getScaledFontSizeFor(font: titleFont, screenSize: currentPageRect.size, minPointSize: 18)
        if self.formatInfo.customVariants.selectedDevice.identifier == "standard4" && !isLandscaped{
            titleNewFontSize = 11.5
            letterSpacing = 1.3
        }
        if (self.formatInfo.customVariants.selectedDevice.identifier == "standard1" ||
            self.formatInfo.customVariants.selectedDevice.identifier == "standard2") && !isLandscaped{
            titleNewFontSize = 15
        }
        let titleAttrs: [NSAttributedString.Key: Any] = [.font :UIFont.clearFaceFont(for: .regular, with:titleNewFontSize),
                                                       NSAttributedString.Key.kern : letterSpacing,
                                                       .foregroundColor : textTintColor];
        let titleString = NSMutableAttributedString.init(string: titleText, attributes: titleAttrs)
        let titleRect = CGRect(x: titleX, y: titleY, width: titleString.size().width, height: titleString.size().height)
        titleString.draw(in: titleRect)

        let yearFont = UIFont.clearFaceFont(for: .regular, with:screenInfo.fontsInfo.dayPageDetails.yearFontSize)
        let yearNewFontSize = UIFont.getScaledFontSizeFor(font: yearFont, screenSize: currentPageRect.size, minPointSize: 12)

        let yearAttrs: [NSAttributedString.Key: Any] = [.font :UIFont.clearFaceFont(for: .regular, with:yearNewFontSize),
                                                       NSAttributedString.Key.kern : letterSpacing,
                                                       .foregroundColor : textTintColor];

        let yearString = NSMutableAttributedString.init(string: "\(monthInfo.year)", attributes: yearAttrs)
        let yearYOffsetPercent: CGFloat = 0.83
        let yearYOffset = currentPageRect.height*yearYOffsetPercent/100
        let yearY = titleY + titleString.size().height + yearYOffset

        let yearRect = CGRect(x: titleX, y: yearY, width: yearString.size().width, height: yearString.size().height)
        yearString.draw(in: yearRect)

        //goals title rendering

        let goalsRectWidthPercnt = 4.76
        let goalsRectHeightPercnt = 2.39

        let goalsRectWidth = currentPageRect.width*goalsRectWidthPercnt/100
        let goalsRectHeigth = currentPageRect.height*goalsRectHeightPercnt/100
        let goalsX = currentPageRect.width*templateInfo.baseX/100
        let goalsY = currentPageRect.height*templateInfo.baseY/100

        var goalsFont = UIFont.clearFaceFont(for: .regular, with: 10)
        if self.layoutRequiresExplicitFont(){
            goalsFont = UIFont.clearFaceFont(for: .regular, with:6)
        }
        let goalsAttr : [NSAttributedString.Key: Any] = [.font: goalsFont,
                                                                        .kern: 1.6,
                                                                        .foregroundColor: textTintColor]
        let goalsString = NSMutableAttributedString.init(string: "Goals".uppercased(), attributes: goalsAttr)
        let goalRect = CGRect(x: goalsX + 5 + 3.5, y: goalsY  + 5 +  (goalsRectHeigth/2) - (goalsString.size().height/2) , width: goalsString.size().width + 6, height: goalsRectHeigth)


        self.drawColorBandsWith(xAxis: goalsX + 5, yAxis: goalsY + 5, context: context, width: goalsString.size().width + 6, height: goalsRectHeigth, bandColor: notesBandBGColor, cornerRadius: 2)
        goalsString.draw(in: goalRect)

        //to do rendering

        let todoYPercnt = 40.28

        let todoX = currentPageRect.width*templateInfo.baseX/100
        let todoY = currentPageRect.height*todoYPercnt/100

        let todoString = NSMutableAttributedString.init(string: "To Do ".uppercased(), attributes: goalsAttr)
        let todoRect = CGRect(x: todoX , y: todoY , width: todoString.size().width, height: todoString.size().height)

        todoString.draw(in: todoRect)

        //notes rendering

        let notesX = currentPageRect.width*templateInfo.notesBoxX/100

        let notesYPercnt = templateInfo.notesBoxY

        let notesY = currentPageRect.height*notesYPercnt/100
        let notesString = NSMutableAttributedString.init(string: "Notes".uppercased(), attributes: goalsAttr)
        let notesRect = CGRect(x: notesX + 5 + 3.5, y: notesY  + 5 +  (goalsRectHeigth/2) - (goalsString.size().height/2) , width: notesString.size().width + 6, height: goalsRectHeigth)


        self.drawColorBandsWith(xAxis: notesX + 5, yAxis: notesY + 5, context: context, width: notesString.size().width + 6, height: goalsRectHeigth, bandColor: notesBandBGColor, cornerRadius: 2)
        notesString.draw(in: notesRect)

        //Schedule Rendering
        let scheduleStripOffsetXPercnt = 7.19
        let scheduleRectHeightPercnt = isLandscaped ? 2.46 : 1.87

        let scheduleX = currentPageRect.width*templateInfo.baseX/100 +  currentPageRect.width*templateInfo.notesBoxWidth/100 +
            currentPageRect.width*scheduleStripOffsetXPercnt/100
        let scheduleY = currentPageRect.height*templateInfo.baseY/100
        let scheduleRectHeight = currentPageRect.height*scheduleRectHeightPercnt/100


        let scheduleString = NSMutableAttributedString.init(string: "Schedule".uppercased(), attributes: goalsAttr)
        let scheduleRect = CGRect(x: scheduleX + 5, y: scheduleY  + 0.5 + (scheduleRectHeight/2) - (scheduleString.size().height/2) , width: scheduleString.size().width, height: scheduleRectHeight)
        scheduleString.draw(in: scheduleRect)
    }
    override func renderNotesPage(context: CGContext,monthInfo: FTMonthlyCalendarInfo) {
        self.renderPlannerDiaryPDF(context: context, pdfTemplatePath: self.notesTemplate,pdfTemplate: self.notesPagePDFDocument);
        // today link
        self.addTodayLink(toContext : context)

        self.renderTxtAndColorsOnSideNavigationStrip(context: context,type: FTPlannerDiaryTemplateType.notes, activeMonth: monthInfo)
        self.drawTopNavigationWidgetFor(type : FTPlannerDiaryTemplateType.notes, context : context)

        let templateInfo = screenInfo.spacesInfo.dayPageSpacesInfo
        //title rendering

        let titleXPercent : CGFloat = templateInfo.baseX
        let titleYPercent : CGFloat = 11.75

        let titleX = self.currentPageRect.width*titleXPercent/100
        let titleY = self.currentPageRect.height*titleYPercent/100

        let paragraphStyle1 = NSMutableParagraphStyle.init()
        paragraphStyle1.alignment = .left

        let titleFont = UIFont.clearFaceFont(for: .regular, with: screenInfo.fontsInfo.yearPageDetails.yearFontSize)
        var titleNewFontSize = UIFont.getScaledFontSizeFor(font: titleFont, screenSize: currentPageRect.size, minPointSize: 18)
        if self.layoutRequiresExplicitFont(){
            titleNewFontSize = 15
        }
        let titleAttrs : [NSAttributedString.Key: Any] = [.font : UIFont.clearFaceFont(for: .regular, with:titleNewFontSize),
                                                          NSAttributedString.Key.kern : 1.6,
                                                          .foregroundColor : textTintColor,
                                                         .paragraphStyle : paragraphStyle1]

        let titleString = NSMutableAttributedString(string: "Notes".uppercased(), attributes: titleAttrs)
        let titleRect = CGRect(x: titleX, y: titleY, width: titleString.size().width, height: titleString.size().height)
        titleString.draw(in: titleRect)

       // color BG rendering
        let verticalGapBWLinesPercnt : CGFloat = 4.43
        let notesXAxisPercnt : CGFloat = 7.46
        let writingAreaYAxisPercnt : CGFloat = 17.98
        let writingAreaLineWidthPercnt : CGFloat = 38.93
        let writingAreaLineBottomPercnt : CGFloat = 6.11

        var writingAreaLinesXAxis = self.currentPageRect.width*notesXAxisPercnt/100
        let writingAreaLineYAxis = (self.currentPageRect.height*writingAreaYAxisPercnt/100)
        let writingAreaLineWidth = self.currentPageRect.width*writingAreaLineWidthPercnt/100
        let verticalGapBWbezierlines = self.currentPageRect.height*verticalGapBWLinesPercnt/100
        let bezierlinesBottom = self.currentPageRect.height*writingAreaLineBottomPercnt/100

        let numberOfDashedLines = CGFloat(Int((self.currentPageRect.height - bezierlinesBottom - writingAreaLineYAxis)/verticalGapBWbezierlines))

        let heightToBeColored = currentPageRect.height - writingAreaLineYAxis - bezierlinesBottom //(numberOfDashedLines*verticalGapBWbezierlines) + (numberOfDashedLines*0.5)
        // first spread bg
        renderNotesBGColor()
        //second spread bg
        writingAreaLinesXAxis += writingAreaLineWidth + twoSpreadGap
        renderNotesBGColor()
        func renderNotesBGColor() {
            if let highlightColor = monthStripColors["\(monthInfo.fullMonth.uppercased())"] {
                self.drawColorBandsWith(xAxis: writingAreaLinesXAxis, yAxis: writingAreaLineYAxis, context: context, width: writingAreaLineWidth, height: heightToBeColored, bandColor: UIColor(hexString: highlightColor,alpha: 0.7))
            }
        }
    }
    override func renderTrackerPage(context: CGContext, monthInfo: FTMonthlyCalendarInfo, calendarYear: FTYearFormatInfo) {
        super.renderPlannerDiaryPDF(context: context, pdfTemplatePath: self.trackerTemplate,pdfTemplate: self.trackerPagePDFDocument)
        // today link
        self.addTodayLink(toContext : context)
        
        self.renderTxtAndColorsOnSideNavigationStrip(context: context,type: FTPlannerDiaryTemplateType.tracker, activeMonth: monthInfo)
        self.drawTopNavigationWidgetFor(type : FTPlannerDiaryTemplateType.tracker, context : context)

        let templateInfo = screenInfo.spacesInfo.dayPageSpacesInfo

        //title rendering
        let monthXPercent : CGFloat = templateInfo.baseX
        let monthYPercent : CGFloat = 11.75

        let monthX = self.currentPageRect.width*monthXPercent/100
        let monthY = self.currentPageRect.height*monthYPercent/100

        let paragraphStyle1 = NSMutableParagraphStyle.init()
        paragraphStyle1.alignment = .left

        let monthFont = UIFont.clearFaceFont(for: .regular, with: screenInfo.fontsInfo.yearPageDetails.yearFontSize)
        var monthNewFontSize = UIFont.getScaledFontSizeFor(font: monthFont, screenSize: currentPageRect.size, minPointSize: 18)
        if self.layoutRequiresExplicitFont(){
            monthNewFontSize = 15
        }
        let monthAttrs : [NSAttributedString.Key: Any] = [.font : UIFont.clearFaceFont(for: .regular, with:monthNewFontSize),
                                                          NSAttributedString.Key.kern : 1.6,
                                                          .foregroundColor : textTintColor,
                                                         .paragraphStyle : paragraphStyle1]

        let monthString = NSMutableAttributedString(string: monthInfo.fullMonth.uppercased() + " " + monthInfo.year, attributes: monthAttrs)
        let monthRect = CGRect(x: monthX, y: monthY, width: monthString.size().width, height: monthString.size().height)
        monthString.draw(in: monthRect)

        //habits rendering

        let habitsXPercnt = 53.59
        let habitsYPercnt = 16.18

        let habitsX = self.currentPageRect.width*habitsXPercnt/100
        let habitsY = self.currentPageRect.height*habitsYPercnt/100

        let habitsFont = UIFont.clearFaceFont(for: .regular, with: 11)
        let habitsNewFontSize = UIFont.getScaledFontSizeFor(font: habitsFont, screenSize: currentPageRect.size, minPointSize: 8)
        let habitsAttrs : [NSAttributedString.Key: Any] = [.font : UIFont.clearFaceFont(for: .regular, with:habitsNewFontSize),
                                                          NSAttributedString.Key.kern : 1.6,
                                                          .foregroundColor : textTintColor,
                                                         .paragraphStyle : paragraphStyle1]

        let habitsString = NSMutableAttributedString(string: "habits".uppercased(), attributes: habitsAttrs)
        let habitsRect = CGRect(x: habitsX, y: habitsY, width: habitsString.size().width, height: habitsString.size().height)
        habitsString.draw(in: habitsRect)

        // weeks rendering

        let moodBoxWidthPercnt = 5.21
        let moodBoxXPercnt = 7.19
        let moodBoxYPercnt = 30.57
        let moodBoxesXOffsetPercnt = 0.44
        let moodSymbolYOffsetPercnt = 1.19

        let moodBoxWidth = currentPageRect.width*moodBoxWidthPercnt/100
        let moodBoxX = currentPageRect.width*moodBoxXPercnt/100
        let moodBoxY = currentPageRect.height*moodBoxYPercnt/100
        let moodBoxesXOffset = currentPageRect.width*moodBoxesXOffsetPercnt/100
        let moodBoxesWeekSymbolYOffset = currentPageRect.width*moodSymbolYOffsetPercnt/100
        var moodBoxesXvalue = moodBoxX + 0.5

        let weekDayFont = UIFont.clearFaceFont(for: .regular, with: 9)
        let weekDayNewFontSize = UIFont.getScaledFontSizeFor(font: weekDayFont, screenSize: currentPageRect.size, minPointSize: 8)
        let weekDayAttrs : [NSAttributedString.Key: Any] = [.font : UIFont.clearFaceFont(for: .regular, with:weekDayNewFontSize),
                                                          NSAttributedString.Key.kern : 1.6,
                                                          .foregroundColor : textTintColor,
                                                         .paragraphStyle : paragraphStyle1]
        for weekDay in getWeekDayNames(monthInfo: monthInfo) {
            let WeekDayString = NSAttributedString(string: weekDay.uppercased(), attributes: weekDayAttrs)
            let WeekDayRect = CGRect(x: moodBoxesXvalue + (moodBoxWidth/2) - (WeekDayString.size().width/2), y: moodBoxY - moodBoxesWeekSymbolYOffset - WeekDayString.size().height, width: moodBoxWidth, height: WeekDayString.size().height)
            WeekDayString.draw(in: WeekDayRect)
            moodBoxesXvalue += moodBoxWidth + moodBoxesXOffset
        }


        // Days Rendering
        var dayFont = UIFont.clearFaceFont(for: .regular, with: 11)
        var minDayFont : CGFloat = 8
        if layoutRequiresExplicitFont() {
            dayFont = UIFont.clearFaceFont(for: .regular, with: 8)
            minDayFont = 6.5
        }
        let dayNewFontSize = UIFont.getScaledFontSizeFor(font: dayFont, screenSize: currentPageRect.size, minPointSize: minDayFont)
        let dayAttrs : [NSAttributedString.Key: Any] = [.font : UIFont.clearFaceFont(for: .regular, with:dayNewFontSize),
                                                          NSAttributedString.Key.kern : 1.6,
                                                          .foregroundColor : textTintColor
                                                         ]

        let moodBoxHeightPercnt = 7.43
        let moodBoxesYOffsetPercnt = 0.59
        let dayXOffsetFromCornerPercnt = 0.62
        let dayYOffsetFromCornerPercnt = 0.62

        let moodBoxHeight = currentPageRect.height*moodBoxHeightPercnt/100
        let moodBoxesYOffset = currentPageRect.height*moodBoxesYOffsetPercnt/100
        let dayXOffsetFromCorner = currentPageRect.width*dayXOffsetFromCornerPercnt/100
        let dayYOffsetFromCorner = currentPageRect.height*dayYOffsetFromCornerPercnt/100

        var dayX = moodBoxX + moodBoxWidth
        var dayY = moodBoxY + moodBoxHeight

        var index = 1

        monthInfo.dayInfo.forEach({(day) in
            let dayString = NSMutableAttributedString.init(string: day.dayString, attributes: dayAttrs)
            let drawRect = CGRect(x: dayX - dayXOffsetFromCorner - dayString
                                    .size().width, y: dayY - dayYOffsetFromCorner - dayString
                                    .size().height, width: dayString.size().width, height: dayString.size().height)
            let drawLocation = CGPoint(x: drawRect.origin.x, y: drawRect.origin.y)
            if day.belongsToSameMonth {
                dayString.draw(at:drawLocation)
            }
            if(index % 7 == 0) {
                dayX = moodBoxX + moodBoxWidth
                dayY += moodBoxHeight + moodBoxesYOffset
            }
            else {
                dayX += moodBoxWidth + moodBoxesXOffset
            }
            index += 1
        })
    }
    func renderTxtAndColorsOnSideNavigationStrip(context: CGContext,type : FTPlannerDiaryTemplateType,activeMonth: FTMonthlyCalendarInfo?){

        let plannerDiarySideNavigationRectsInfo = FTPlannerDiarySideNavigationRectInfo()
        var highlightCalenderStrip : Bool = false
        var highlightYearStrip : Bool = false
        var highlightMonthStrip : Bool = false
        var highlightExtrasStrip : Bool = false
        switch type {
        case .calendar:
            highlightCalenderStrip  = true
        case .year:
            highlightYearStrip = true
        case .month,.week,.day,.notes,.tracker:
            highlightMonthStrip = true
        case .extras:
            highlightExtrasStrip = true
        }


        let isLandscaped = self.formatInfo.customVariants.isLandscape
        let monthStripTitles = ["jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec"]
        let monthStripColors : [String: String] = sideStripMonthColorsDict

        let stripColor =  UIColor(hexString: "#000000", alpha: 0.2)
        let stripShadowColor = UIColor(hexString: "#000000", alpha: 0.08)
        let shadowOffset = CGSize(width: 0, height: 2)
        let shadowBlurRadius : CGFloat = 4
        let stripWidthPercnt = 3.86
        let stripWidth = currentPageRect.size.width*stripWidthPercnt/100
        let currentpageWidth = currentPageRect.width
        var sideStripTextFont = UIFont.clearFaceFont(for: .regular, with: 10)
        if (formatInfo.customVariants.selectedDevice.identifier == "standard4" ||
            formatInfo.customVariants.selectedDevice.identifier == "standard2") && !formatInfo.customVariants.isLandscape {
            sideStripTextFont = UIFont.clearFaceFont(for: .regular, with: 7)
        }
        else if formatInfo.customVariants.selectedDevice.identifier == "standard4" && formatInfo.customVariants.isLandscape {
            sideStripTextFont = UIFont.clearFaceFont(for: .regular, with: 4.75)
        }
        else if formatInfo.customVariants.selectedDevice.identifier == "standard2" && formatInfo.customVariants.isLandscape {
            sideStripTextFont = UIFont.clearFaceFont(for: .regular, with: 7)
        }


        let attrs : [NSAttributedString.Key: Any] = [.font : sideStripTextFont,
                                                          NSAttributedString.Key.kern : 1.35,
                                                          .foregroundColor : textTintColor]


        var sideStripBandHeight : CGFloat = 0.0
        // For Left side strip
        context.saveGState()
        context.translateBy(x: 0, y: currentPageRect.height); // orgin is moved to left bottom
        context.rotate(by: -90.0 * CGFloat.pi / 180.0) // axis is rotated by -90 degrees

        // months rendering
        let monthStripHeightPercnt : CGFloat = 13.03
        let monthStripHeight = self.currentPageRect.size.height*monthStripHeightPercnt/100
        var monthRects : [String : CGRect] = [:]

        renderBandStripsAndTextsForMonths(monthCalendarInfo.prefix(5).reversed(), forPageLeftSide: true)

        //yearly planner side strip
        let yearStripHeightPercnt : CGFloat = 13.03
        let yearStripHeight = self.currentPageRect.size.height*yearStripHeightPercnt/100
        let yearTitleString = NSAttributedString.init(string: " yearly\nplanner".uppercased(), attributes: attrs)
        let yearTitleYAxis =  (stripWidth/2) - (yearTitleString.size().height/2)
        let yearTitleXAxis =  sideStripBandHeight + (yearStripHeight/2) - (yearTitleString.size().width/2)
        let yearStripColor = highlightYearStrip ? getTemplateBackgroundColor() : self.calendarStripColor
        self.drawColorBandsWith(xAxis: sideStripBandHeight, yAxis: 0, context: context, width:yearStripHeight , height: stripWidth, bandColor: yearStripColor)
        self.addBezierLineWith(rect: CGRect(x: sideStripBandHeight, y:0, width: stripWidth,height: 0.5), toContext: context, withColor: stripColor, shadowColor: stripShadowColor, shadowOffset: shadowOffset, shadowBlurRadius: shadowBlurRadius)
        yearTitleString.draw(at: CGPoint(x: yearTitleXAxis, y: yearTitleYAxis))

        plannerDiarySideNavigationRectsInfo.yearRect = CGRect(x: 0, y:sideStripBandHeight, width:stripWidth, height: yearStripHeight)
        sideStripBandHeight += yearStripHeight

        //calendar side strip
        let calendarStripHeightPercnt : CGFloat = 13.03
        let stripHeight = self.currentPageRect.size.height*calendarStripHeightPercnt/100
        let calendarTitleString = NSAttributedString.init(string: "Calendar".uppercased(), attributes: attrs)
        let stripYAxis =  (stripWidth/2) - (calendarTitleString.size().height/2)
        let stripXAxis = sideStripBandHeight + (stripHeight/2) - (calendarTitleString.size().width/2)
        let calendarStripColor = highlightCalenderStrip ? getTemplateBackgroundColor() : calendarStripColor
        self.drawColorBandsWith(xAxis: sideStripBandHeight, yAxis: 0, context: context, width: stripHeight , height: stripWidth, bandColor: calendarStripColor)
        self.addBezierLineWith(rect: CGRect(x: sideStripBandHeight, y:0, width: stripWidth,height: 0.5), toContext: context, withColor: stripColor, shadowColor: stripShadowColor, shadowOffset: shadowOffset, shadowBlurRadius: shadowBlurRadius)
        calendarTitleString.draw(at: CGPoint(x: stripXAxis, y: stripYAxis + 1 ))
        plannerDiarySideNavigationRectsInfo.calendarRect = CGRect(x: 0, y: sideStripBandHeight, width: stripWidth, height: stripHeight)
        sideStripBandHeight += stripHeight

        renderDummyStripsWithColor(dummyStrip1Color)
        self.addBezierLineWith(rect: CGRect(x: sideStripBandHeight, y:0, width: stripWidth,height: 0.5), toContext: context, withColor: stripColor, shadowColor: stripShadowColor, shadowOffset: shadowOffset, shadowBlurRadius: shadowBlurRadius)
        context.restoreGState()

        // For Right side strip
        context.saveGState()
        context.translateBy(x: currentpageWidth, y: 0); // orgin is moved to right top
        context.rotate(by: 90.0 * CGFloat.pi / 180.0) // axis is rotated by 90 degrees
        sideStripBandHeight = 0
        renderDummyStripsWithColor(dummyStrip2Color)
        renderBandStripsAndTextsForMonths(monthCalendarInfo.suffix(7), forPageLeftSide: false)
        context.restoreGState()
        plannerDiarySideNavigationRectsInfo.monthRects = monthRects
        self.plannerDiarySideNavigationRectsInfo = plannerDiarySideNavigationRectsInfo
        func renderBandStripsAndTextsForMonths(_ months: [FTMonthlyCalendarInfo], forPageLeftSide: Bool) {
            for month in months {
                let monthTitleString = NSAttributedString.init(string: month.shortMonth.uppercased(), attributes: attrs)
                let monthTitleYAxis =  (stripWidth/2) - (monthTitleString.size().height/2)
                let monthTitleXAxis =  sideStripBandHeight + (monthStripHeight/2) - (monthTitleString.size().width/2)
                let monthRect = CGRect(x: sideStripBandHeight, y: 0, width: stripWidth, height: 0.5)
                if highlightMonthStrip ,month.shortMonth.lowercased() == activeMonth?.shortMonth.lowercased(){
                    self.drawColorBandsWith(xAxis: sideStripBandHeight, yAxis:0, context: context, width:monthStripHeight , height: stripWidth , bandColor: getTemplateBackgroundColor())
                    highlightMonthStrip = false
                }
                else{
                    if let stripColor = monthStripColors[month.shortMonth.lowercased()] {
                        self.drawColorBandsWith(xAxis: sideStripBandHeight, yAxis:0, context: context, width:monthStripHeight , height: stripWidth , bandColor: UIColor(hexString: stripColor))
                    }
                }
                self.addBezierLineWith(rect: monthRect, toContext: context, withColor: stripColor, shadowColor: stripShadowColor, shadowOffset: shadowOffset, shadowBlurRadius: shadowBlurRadius)
                monthTitleString.draw(at: CGPoint(x: monthTitleXAxis, y: monthTitleYAxis))
                let linkXAxis = forPageLeftSide ? 0 : (currentPageRect.width - stripWidth)
                let linkYAxis = forPageLeftSide ? sideStripBandHeight : (currentPageRect.height - sideStripBandHeight - monthStripHeight)
                monthRects[month.shortMonth.uppercased()] =  CGRect(x: linkXAxis, y: linkYAxis, width:stripWidth, height: monthStripHeight)
                sideStripBandHeight += monthStripHeight
            }
        }
        func renderDummyStripsWithColor(_ color: UIColor) {
            //Dummy strip below notebook toolbar
            let dummyStrip1HeightPercnt : CGFloat =  8.75
            let dummyStrip1Height = self.currentPageRect.size.height*dummyStrip1HeightPercnt/100
            let dummyStrip1Color = dummyStrip1Color
            self.drawColorBandsWith(xAxis: sideStripBandHeight, yAxis: 0, context: context, width: dummyStrip1Height , height: stripWidth, bandColor: color)
            self.addBezierLineWith(rect: CGRect(x: sideStripBandHeight, y:0, width: stripWidth,height: 0.5), toContext: context, withColor: stripColor, shadowColor: stripShadowColor, shadowOffset: shadowOffset, shadowBlurRadius: shadowBlurRadius)
            sideStripBandHeight += dummyStrip1Height
        }
    }
    func getLinkRectForModifiedAxis(location at: CGPoint, frameSize: CGSize) -> CGRect {
        return CGRect(x: at.x, y:at.y, width: frameSize.width, height: frameSize.height)
    }
    func drawPageNumbersFor(type : FTPlannerDiaryTemplateType,currentPageIndex : Int, context : CGContext) -> [CGRect] {


        var currentPageNumRects : [CGRect]  = []
        let isLandscaped = self.formatInfo.customVariants.isLandscape
        let numberOfExtrasPages : Int = 3
        let numberOfYearPages : Int = 3
        let numberOfPages : Int = type == .year ? numberOfYearPages : numberOfExtrasPages
        let xAxisPercnt : CGFloat = isLandscaped ? 81.65 : 80.81
        let yAxisPercnt : CGFloat = isLandscaped ? 12.35 : 5.24
        let pageNumWidthPercnt : CGFloat = isLandscaped ? 3.59 : 4.79
        let pageNumHeightPercnt : CGFloat = isLandscaped ? 1.79 : 1.43

        var xAxis = self.currentPageRect.width*xAxisPercnt/100
        let yAxis = self.currentPageRect.height*yAxisPercnt/100
        let pageNumWidth = self.currentPageRect.width*pageNumWidthPercnt/100
        let pageNumHeight = self.currentPageRect.height*pageNumHeightPercnt/100

        var pageNumFont = UIFont.clearFaceFont(for: .regular, with: 9)
        var pageNumBGCornerRadius : CGFloat = 3.0
        if self.layoutRequiresExplicitFont(){
            pageNumFont = UIFont.clearFaceFont(for: .regular, with:7)
        }
        if self.layoutRequiresExplicitCrnerRadiusFrColrdBG(){
            pageNumBGCornerRadius = 2.0
        }
        let pageNumAttr : [NSAttributedString.Key: Any] = [.font : pageNumFont,
                                                          NSAttributedString.Key.kern : 1.6,
                                                          .foregroundColor : textTintColor]
        for index in 1...numberOfPages {
            if index == currentPageIndex {
                self.drawColorBandsWith(xAxis: xAxis, yAxis: yAxis, context: context, width: pageNumWidth, height: pageNumHeight, bandColor: pageNumberHighlightBGColor, cornerRadius: pageNumBGCornerRadius)
            }
            currentPageNumRects.append(getLinkRect(location: CGPoint(x: xAxis, y: yAxis - pageNumHeight/2), frameSize: CGSize(width: pageNumWidth, height: pageNumHeight*2)))
            let pageNumString = NSAttributedString.init(string: "\(index)", attributes: pageNumAttr)
            let pageNumRect = CGRect(x: xAxis + (pageNumWidth/2) - (pageNumString.size().width/2), y: yAxis + (pageNumHeight/2) - (pageNumString.size().height/2), width: pageNumString.size().width, height: pageNumString.size().height)
            pageNumString.draw(in: pageNumRect)
            xAxis += pageNumWidth
        }
        return currentPageNumRects
    }
    func drawTopNavigationWidgetFor(type : FTPlannerDiaryTemplateType, context : CGContext){

        var pageNavigationRects : [FTPlannerDiaryTemplateType : CGRect] = [:]
        let isLandscaped = self.formatInfo.customVariants.isLandscape
        let widgetsTitles : [FTPlannerDiaryTemplateType : String] = [.month  : "MONTHLY",.week : "WEEKLY",.day :"DAILY",.notes : "NOTES",.tracker : "TRACKER"]
        let widgetElementTypes : [FTPlannerDiaryTemplateType] = [.tracker,.notes,.day,.week,.month]

        let xAxisPercnt : CGFloat = 92.53
        let yAxisPercnt : CGFloat = 12.35
        let widgetElementsXOffsetPercnt = 1.25
        let widgetElementHeightPercnt : CGFloat = 1.79

        var xAxis = self.currentPageRect.width*xAxisPercnt/100
        let yAxis = self.currentPageRect.height*yAxisPercnt/100
        let widgetElementsXOffset = self.currentPageRect.width*widgetElementsXOffsetPercnt/100
        let widgetElementHeight = self.currentPageRect.height*widgetElementHeightPercnt/100

        var widgetElementsFont = UIFont.clearFaceFont(for: .regular, with: 9)
        var widgetElementsBGCornerRadius : CGFloat = 3.0
        var letterSpacing : CGFloat = 1.5
        if self.formatInfo.customVariants.selectedDevice.identifier == "standard4" {
            widgetElementsFont = UIFont.clearFaceFont(for: .regular, with:5)
            letterSpacing = 1.4
        }
        if self.layoutRequiresExplicitCrnerRadiusFrColrdBG(){
            widgetElementsBGCornerRadius = 2.0
        }
        var widgetElementAttr : [NSAttributedString.Key: Any] = [.font : widgetElementsFont,
                                                          NSAttributedString.Key.kern : letterSpacing]
        var elementTextForegroundColor = textTintColor.withAlphaComponent(0.6)
        for element in widgetElementTypes {
            if element == type {
                elementTextForegroundColor = textTintColor
            }else{
                elementTextForegroundColor = textTintColor.withAlphaComponent(0.6)
            }
            widgetElementAttr[.foregroundColor] = elementTextForegroundColor
            if let widgetTitle = widgetsTitles[element] {
                let widgetElementString = NSAttributedString.init(string: widgetTitle, attributes: widgetElementAttr)
                xAxis -= widgetElementString.size().width
                if element == type {
                    self.drawColorBandsWith(xAxis: xAxis, yAxis: yAxis, context: context, width: widgetElementString.size().width + 6, height: widgetElementHeight, bandColor: widgetHightlightBGColor, cornerRadius: widgetElementsBGCornerRadius)
                }
                pageNavigationRects[element] = getLinkRect(location: CGPoint(x: xAxis, y: yAxis - widgetElementHeight/2), frameSize: CGSize(width: widgetElementString.size().width + 6, height: widgetElementHeight*2))
                let widgetElementRect = CGRect(x: xAxis + 3.5, y: yAxis + (widgetElementHeight/2) - (widgetElementString.size().height/2), width: widgetElementString.size().width, height: widgetElementString.size().height)
                widgetElementString.draw(in: widgetElementRect)
                xAxis -= widgetElementsXOffset
            }
        }
        self.plannerDiaryTopNavigationRectsInfo.plannerTopNavigationRects = pageNavigationRects
    }
    private func layoutRequiresExplicitFont() -> Bool {

        if self.formatInfo.customVariants.selectedDevice.identifier == "standard4" ||
            self.formatInfo.customVariants.selectedDevice.identifier == "standard2" ||
            self.formatInfo.customVariants.selectedDevice.identifier == "standard1"{
           return true
        }
        return false
    }
    private  func layoutRequiresExplicitCrnerRadiusFrColrdBG() -> Bool {
        if self.formatInfo.customVariants.selectedDevice.identifier == "standard1" ||
            self.formatInfo.customVariants.selectedDevice.identifier == "standard2" || self.formatInfo.customVariants.selectedDevice.identifier == "standard4" {
           return true
        }
        return false
    }
    func drawColorBandsWith(xAxis : CGFloat, yAxis : CGFloat, context : CGContext, width : CGFloat,height: CGFloat, bandColor : UIColor){
        let monthBandRect = CGRect(x: xAxis , y: yAxis , width: width , height: height )
        context.setFillColor(bandColor.cgColor)
        context.fill(monthBandRect)
    }
    func drawColorBandsWith(xAxis : CGFloat, yAxis : CGFloat, context : CGContext, width : CGFloat,height: CGFloat, bandColor : UIColor, cornerRadius: CGFloat){
        let monthBandRect = CGRect(x: xAxis , y: yAxis , width: width , height: height)
        let bezierRect = UIBezierPath(roundedRect: monthBandRect, cornerRadius: cornerRadius)
        context.addPath(bezierRect.cgPath)
        context.setFillColor(bandColor.cgColor)
        context.fillPath()
    }
    private func addTodayLink(toContext context: CGContext){

        let todayLinkRectYPercnt : CGFloat = 12.35
        let todayLinkRectXPercnt : CGFloat = 41.79
        let todayLinkRectHeightPercnt  : CGFloat = 1.79
        let twospredLinesXPercent: CGFloat = 50.0
        let twoSpreadLineXOffset: CGFloat = 3.59
        let todayPillHorizontalPaddingPercnt: CGFloat = 0.35

        let todayLinkRectX = self.currentPageRect.width*todayLinkRectXPercnt/100
        let todayLinkRectY = self.currentPageRect.height*todayLinkRectYPercnt/100
        let todayLinkRectHeight = self.currentPageRect.height*todayLinkRectHeightPercnt/100

        let towSpreadLineXOffset = self.currentPageRect.width*twoSpreadLineXOffset/100
        let towSpreadLineX = self.currentPageRect.width*twospredLinesXPercent/100
        let todayPillHorizontalPadding = self.currentPageRect.width*todayPillHorizontalPaddingPercnt/100

        var todayFont = UIFont.clearFaceFont(for: .regular, with:9)
        var todayRectCornerRadius : CGFloat = 3
        if self.layoutRequiresExplicitFont(){
            todayFont = UIFont.clearFaceFont(for: .regular, with:5)
            todayRectCornerRadius = 2
        }

        let todayAttrs: [NSAttributedString.Key: Any] = [.font: todayFont,
                                                        .kern: 1.6,
                                                        .foregroundColor: UIColor.init(hexString: "#363636")]
        let todayString = NSAttributedString.init(string: "TODAY",attributes: todayAttrs)
        let tpdayPillX = towSpreadLineX - towSpreadLineXOffset - (todayString.size().width + todayPillHorizontalPadding*2)
        let todayPillRect = CGRect(x: tpdayPillX, y: todayLinkRectY, width: todayString.size().width + todayPillHorizontalPadding*2, height: todayLinkRectHeight)

        self.drawColorBandsWith(xAxis: todayPillRect.origin.x, yAxis: todayPillRect.origin.y, context: context, width: todayPillRect.width, height: todayPillRect.height, bandColor: UIColor(hexString: "#80CCCB"), cornerRadius: todayRectCornerRadius)

        let todayRect = CGRect(x: todayPillRect.origin.x + (todayPillRect.width - todayString.size().width)/2 , y: todayLinkRectY + (todayPillRect.height - todayString.size().height)/2, width: todayString.size().width, height: todayString.size().height)
        todayString.draw(at:CGPoint(x: todayRect.origin.x + 1, y: todayRect.origin.y + 1))


        let todayLinkRect = getLinkRect(location: CGPoint(x:todayPillRect.origin.x - 3, y: todayPillRect.origin.y - 3), frameSize:CGSize(width: todayPillRect.width + 6 , height: todayPillRect.height + 6))
        let urlString = FTSharedGroupID.getAppGroupID() + "://todayLink"
        if let todayURL = URL(string: urlString){
            UIGraphicsSetPDFContextURLForRect(todayURL, todayLinkRect)
        }
    }
}
