//
//  FTMidnightiPhoneFormat.swift
//  Noteshelf
//
//  Created by Ramakrishna on 01/06/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTStyles

class FTMidnightDiaryiPhoneFormat : FTMidnightDairyFormat {
    
    override var isiPad: Bool {
        return false
    }

    override func renderMonthPage(context: CGContext, monthInfo: FTMonthlyCalendarInfo, calendarYear: FTYearFormatInfo) {
        super.renderMonthPage(context: context, monthInfo: monthInfo, calendarYear: calendarYear)
        let currentMonthRectsInfo = FTDiaryMonthRectsInfo()
        let templateInfo = screenInfo.spacesInfo.monthPageSpacesInfo
        let yearXPercentage : CGFloat = formatInfo.customVariants.isLandscape ? 3.14 : 5.6
        
        let cellWidth = (currentPageRect.width - (currentPageRect.width*templateInfo.baseBoxX/100) - (currentPageRect.width*templateInfo.boxRightOffset/100) - 6*(currentPageRect.width*templateInfo.cellOffsetX/100))/7
        let cellHeight = (currentPageRect.height - (currentPageRect.height*templateInfo.baseBoxY/100) - (currentPageRect.height*templateInfo.boxBottomOffset/100) -
                            5*(currentPageRect.height*templateInfo.cellOffsetY/100))/6
        let yearFont = UIFont.robotoMedium(screenInfo.fontsInfo.monthPageDetails.yearFontSize)
        let yearNewFontSize = UIFont.getScaledFontSizeFor(font: yearFont, screenSize: currentPageRect.size, minPointSize: 16)
        
        let yearAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.robotoMedium(yearNewFontSize),
                                                        .kern: 0.0,
                                                        .foregroundColor: UIColor.init(hexString: "#C4C4C4")]
        
        let yearString = NSMutableAttributedString.init(string: monthInfo.year, attributes: yearAttrs)
        let yearLocation = CGPoint(x: (currentPageRect.width*yearXPercentage/100), y: (currentPageRect.height*templateInfo.monthY/100) )
        yearString.draw(at: yearLocation)
        currentMonthRectsInfo.yearRect = getLinkRect(location: yearLocation, frameSize: yearString.size())
        
        let navigationStringAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.robotoMedium(yearNewFontSize),
                                                                    .kern: 0.0,
                                                                    .foregroundColor: UIColor.init(hexString: "#C4C4C4", alpha: 0.4)]
        
        let navigationString = NSMutableAttributedString.init(string: "/", attributes: navigationStringAttrs)
        let navigationLocation = CGPoint(x: (yearLocation.x) + yearString.size().width + 7, y: (currentPageRect.height*templateInfo.monthY/100) )
        navigationString.draw(at: navigationLocation)
        
        let monthAttrs: [NSAttributedString.Key: Any] = yearAttrs
        let monthString = NSMutableAttributedString.init(string: monthInfo.shortMonth, attributes: monthAttrs)
        let monthLocation = CGPoint(x: navigationLocation.x  + navigationString.size().width + 8,
                                    y:(currentPageRect.height*templateInfo.monthY/100))
        monthString.draw(at: monthLocation)
        currentMonthRectsInfo.monthRect = getLinkRect(location: monthLocation, frameSize: monthString.size())
        
        
        let symbols = getWeekSymbols(monthInfo: monthInfo)
        
        let paragraphStyle = NSMutableParagraphStyle.init()
        paragraphStyle.alignment = .center
        let weekSymbolFont = UIFont.montserratFont(for: .bold, with: screenInfo.fontsInfo.monthPageDetails.dayFontSize)
        let weekSymbolNewFontSize = UIFont.getScaledFontSizeFor(font: weekSymbolFont, screenSize: currentPageRect.size, minPointSize: 7)
        let symbolAttrs: [NSAttributedString.Key : Any] =  [.font :UIFont.montserratFont(for: .bold, with: weekSymbolNewFontSize),
                                                            NSAttributedString.Key.kern : 0.0,
                                                            .foregroundColor : UIColor.init(hexString: "#626465"),
                                                            .paragraphStyle: paragraphStyle];
        
        var symbolX = (currentPageRect.width*templateInfo.baseBoxX/100)
        //let symbolheight = (currentPageRect.height*4.14/100)
        symbols.forEach({(symbol) in
            let symbolString = NSMutableAttributedString.init(string: symbol,attributes: symbolAttrs)
            let symbolY =  (currentPageRect.height*templateInfo.baseBoxY/100) - cellHeight/2 - symbolString.size().height/2
            symbolString.draw(in: CGRect(x: symbolX, y:symbolY , width: cellWidth, height: cellHeight))
            symbolX += cellWidth + (currentPageRect.width*templateInfo.cellOffsetX/100)
        }
        )
        
        let weekNumberAttrs: [NSAttributedString.Key : Any] =  [.font :UIFont.montserratFont(for: .bold, with: weekSymbolNewFontSize),
                                                                NSAttributedString.Key.kern : 0.0,
                                                                .foregroundColor : UIColor.init(hexString: "#4FA4FF"),
                                                                .paragraphStyle: paragraphStyle];
        
        let weekXPercentage : CGFloat = formatInfo.customVariants.isLandscape ? 3.14 : 5.6
        let weekX = (currentPageRect.width*weekXPercentage/100)
        var weekY = (currentPageRect.height*templateInfo.baseBoxY/100)
        let weekWidthPercentage : CGFloat = formatInfo.customVariants.isLandscape ? 2.69 : 5.33
        let weekSymbolWidth = (currentPageRect.width*weekWidthPercentage/100)

        var weekNumbers : [String] = []
        var weekNumber : Int = 0
        for (index, day) in monthInfo.dayInfo.enumerated() {
            let weekNumberOBJ = FTPlannerWeekNumber()
            if index == 0 {
                weekNumber += 1
                weekNumbers.append("wk\(weekNumber)")
            }
            else if index % 7 == 0, day.fullMonthString == monthInfo.fullMonth {
                weekNumber += 1
                weekNumbers.append("wk\(weekNumber)")
            }
        }

        for week in weekNumbers {
            let weekString = NSMutableAttributedString.init(string: week,attributes: weekNumberAttrs)
            let weekNumberRect = CGRect(x: weekX + weekSymbolWidth/2 - weekString.size().width/2, y: weekY + cellHeight/2 - weekString.size().height/2 , width: weekSymbolWidth , height: cellHeight)
            let location = CGPoint(x: weekNumberRect.origin.x, y: weekNumberRect.origin.y)
            weekString.draw(at: location)
            weekY += cellHeight + (currentPageRect.height*templateInfo.cellOffsetY/100)
            currentMonthRectsInfo.weekRects.append(getLinkRect(location: location, frameSize: weekString.size()))
        }
        
        var dayX = (currentPageRect.width*templateInfo.baseBoxX/100)
        var linkX = (currentPageRect.width*templateInfo.baseBoxX/100)
        var dayY = (currentPageRect.height*templateInfo.baseBoxY/100)
        var index = 1;
        
        monthInfo.dayInfo.forEach({(day) in
            let dayForeGroundColor = day.belongsToSameMonth ? UIColor.init(hexString: "#E5E5E5") :UIColor.init(hexString: "#7B7B78")
            let dayRect = CGRect(x: dayX, y: dayY, width: cellWidth , height: cellHeight)
            self.addBezierPathWithRect(rect: dayRect, toContext: context, title: day.dayString,tileColor: dayForeGroundColor)
            //let drawLocation = CGPoint(x: drawRect.origin.x, y: drawRect.origin.y)
            //dayString.draw(at:drawLocation)
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
        self.addTodayPillToMonthPageWith(context: context)
    }
    override func renderDayPage(context: CGContext, dayInfo: FTDayInfo) {
        if !dayInfo.belongsToSameMonth {
            return
        }
        super.renderDayPage(context: context, dayInfo: dayInfo)
        let templateInfo = screenInfo.spacesInfo.dayPageSpacesInfo
        let dailyPlanBoxWidth : CGFloat = currentPageRect.width*templateInfo.dailyPlanBoxWidth/100
        let dailyplanBoxHeight : CGFloat = currentPageRect.height*templateInfo.dailyPlanBoxHeight/100
        let dailyPlanBoxX : CGFloat = currentPageRect.width*templateInfo.dailyPlanBoxX/100
        let dailyPlanBoxY : CGFloat = currentPageRect.height*templateInfo.dailyPlanBoxY/100
        let dailyPlanRect = CGRect(x: dailyPlanBoxX, y: dailyPlanBoxY, width: dailyPlanBoxWidth, height: dailyplanBoxHeight)
        let chevronImage = UIImage(named: "right_chevron")
        let dailyPlanChevronRect = CGRect(x: (dailyPlanRect.origin.x + dailyPlanBoxWidth - 4 - 24), y: (dailyPlanRect.origin.y + 4), width: 24, height: 24)
        chevronImage?.draw(at: CGPoint(x: dailyPlanChevronRect.origin.x, y: dailyPlanChevronRect.origin.y))
        currentDayRectsInfo.dailyPlanRect = getLinkRect(location: CGPoint(x: dailyPlanChevronRect.origin.x, y: dailyPlanChevronRect.origin.y), frameSize: dailyPlanChevronRect.size)
        dayRectsInfo.append(currentDayRectsInfo)
        self.addTodayPillToDayPageWith(context: context)
    }
    override func renderDailyPlanPage(context : CGContext, dayInfo : FTDayInfo){
        if !dayInfo.belongsToSameMonth {
            return
        }
        self.renderMidnightDiaryPDF(context: context, pdfTemplatePath: self.prioritiesTemplate)
        let prioritiesTemplateInfo = screenInfo.spacesInfo.prioritiesPageSpacesInfo
        let bezierBGWidth = (currentPageRect.width*prioritiesTemplateInfo.boxWidth)/100
        let bezierBGXAxis = (currentPageRect.width*prioritiesTemplateInfo.boxX)/100
        
        // title drawing
        let titleX = currentPageRect.width*prioritiesTemplateInfo.titleX/100
        let titleY = currentPageRect.height*prioritiesTemplateInfo.titleY/100
        let titleFont = UIFont.robotoMedium(screenInfo.fontsInfo.prioritiesPageDetails.yearFontSize)
        let titleNewFontSize = UIFont.getScaledFontSizeFor(font: titleFont, screenSize: currentPageRect.size, minPointSize: 16)
        let titleAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.robotoMedium(titleNewFontSize),
                                                          NSAttributedString.Key.kern : 0.0,
                                                          .foregroundColor : UIColor.init(hexString: "#C4C4C4")];
        
        let titleString = NSMutableAttributedString.init(string: "Daily Plan" , attributes: titleAttrs)
        let titleLocation = CGPoint(x: titleX,
                                    y: titleY)
        titleString.draw(at: titleLocation)
        
        // day info drawing
        let dayFont = UIFont.robotoMedium(screenInfo.fontsInfo.prioritiesPageDetails.dayFontSize)
        let dayNewFontSize = UIFont.getScaledFontSizeFor(font: dayFont, screenSize: currentPageRect.size, minPointSize: 12)
        let dayInfoAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.robotoMedium(dayNewFontSize),
                                                            NSAttributedString.Key.kern : 0.0,
                                                            .foregroundColor : UIColor.init(hexString: "#4FA4FF")];
        let monthString = dayInfo.monthString
        let weekString = dayInfo.dayString
        let dayInfoString = monthString + " " + weekString
        let dayInfoAttrString = NSMutableAttributedString.init(string:dayInfoString , attributes: dayInfoAttrs)
        let dayInfoRectX = bezierBGXAxis + bezierBGWidth - dayInfoAttrString.size().width
        let dayInfoRectY = (currentPageRect.height*prioritiesTemplateInfo.dayInfoY)/100
        let dayInfoRect = CGRect(x: dayInfoRectX, y: dayInfoRectY, width: dayInfoAttrString.size().width, height: dayInfoAttrString.size().height)
        let dayInfoDrawLocation = CGPoint(x: dayInfoRect.origin.x, y: dayInfoRect.origin.y)
        dayInfoAttrString.draw(at: dayInfoDrawLocation)
        dailyPrioritiesInfo.dayRect = getLinkRect(location: dayInfoDrawLocation, frameSize: dayInfoAttrString.size())
        //Today pill
        let todayPillXOffsetPercnt = 3.73 // gap between today pill and day info
        let dayInfoXPercnt = (dayInfoRect.origin.x/currentPageRect.width)*100
        let rightXOffsetPercnt = 100.0 - (dayInfoXPercnt - todayPillXOffsetPercnt)
        self.addTodayPillWith(rightXOffsetPercent: rightXOffsetPercnt, toContext: context)
    }
    override func renderWeekPage(context: CGContext, weeklyInfo: FTWeekInfo) {
        super.renderWeekPage(context: context, weeklyInfo: weeklyInfo)
        let templateInfo = screenInfo.spacesInfo.weekPageSpacesInfo
        var index = CGFloat(0)
        let weekDayfont = UIFont.montserratFont(for: .bold, with: screenInfo.fontsInfo.weekPageDetails.dayFontSize)
        let weekDayNewFontSize = UIFont.getScaledFontSizeFor(font: weekDayfont, screenSize: currentPageRect.size, minPointSize: 8)
        let weekAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.montserratFont(for: .bold, with: weekDayNewFontSize),
                                                        .kern: 0.0,
                                                        .foregroundColor: UIColor.init(hexString:"#E5E5E5")]
        var weekDayInfoY = currentPageRect.height*templateInfo.baseBoxY/100
        var weekDayInfoX = currentPageRect.width*templateInfo.baseBoxX/100
        var weekDayRects : [CGRect] = []
        weeklyInfo.dayInfo.forEach(({(weekDay) in
            let weekAndDayText = weekDay.fullDayString + " " + weekDay.weekShortString
            let weekAndDayString = NSMutableAttributedString.init(string: weekAndDayText, attributes: weekAttrs)
            let weekAndDayFrameLocation = CGPoint(x: weekDayInfoX + 11,
                                                  y: weekDayInfoY + 8)
            weekAndDayString.draw(at: weekAndDayFrameLocation)
            if isBelongToCalendarYear(currentDate: weekDay.date) {
                weekDayRects.append(getLinkRect(location: weekAndDayFrameLocation,
                                                frameSize: CGSize(width: weekAndDayString.size().width, height: weekAndDayString.size().height)))
            }
            index += 1
            if formatInfo.orientation == FTScreenOrientation.Land.rawValue, index > 3 {
                index = 0
                weekDayInfoX += (currentPageRect.width*templateInfo.cellWidth/100) + (currentPageRect.width*templateInfo.cellOffsetX/100)
                weekDayInfoY = currentPageRect.height*templateInfo.baseBoxY/100
            }else{
                weekDayInfoY += currentPageRect.height*templateInfo.cellHeight/100 + (currentPageRect.height*templateInfo.cellOffsetY/100)
            }
            
        }))
        currentWeekRectInfo.weekDayRects.append(contentsOf: weekDayRects)
        weekRectsInfo.append(currentWeekRectInfo)
        self.addTodayPillToWeekPageWith(context: context)
    }
    override func renderDailyNotesPage(context : CGContext, dayInfo : FTDayInfo) {
        
        if !dayInfo.belongsToSameMonth {
            return
        }
        self.renderMidnightDiaryPDF(context: context, pdfTemplatePath: self.notesTemplate)
        let notesTemplateInfo = screenInfo.spacesInfo.notesPageSpacesInfo
        let bezierBGWidth = (currentPageRect.width*notesTemplateInfo.boxWidth)/100
        let bezierBGXAxis = (currentPageRect.width*notesTemplateInfo.boxX)/100
        
        // title drawing
        let titleX = currentPageRect.width*notesTemplateInfo.titleX/100
        let titleY = currentPageRect.height*notesTemplateInfo.titleY/100
        let titleFont = UIFont.robotoMedium(screenInfo.fontsInfo.prioritiesPageDetails.yearFontSize)
        let titleNewFontSize = UIFont.getScaledFontSizeFor(font: titleFont, screenSize: currentPageRect.size, minPointSize: 16)
        let titleAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.robotoMedium(titleNewFontSize),
                                                          NSAttributedString.Key.kern : 0.0,
                                                          .foregroundColor : UIColor.init(hexString: "#C4C4C4")];
        let titleString = NSMutableAttributedString.init(string: "Notes", attributes: titleAttrs)
        let titleLocation = CGPoint(x: titleX,
                                    y: titleY)
        titleString.draw(at: titleLocation)
        
        let dayFont = UIFont.robotoMedium(screenInfo.fontsInfo.prioritiesPageDetails.dayFontSize)
        let dayNewFontSize = UIFont.getScaledFontSizeFor(font: dayFont, screenSize: currentPageRect.size, minPointSize: 12)
        let dayInfoAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.robotoMedium(dayNewFontSize),
                                                            NSAttributedString.Key.kern : 0.0,
                                                            .foregroundColor : UIColor.init(hexString: "#4FA4FF")];
        let monthString = dayInfo.monthString
        let weekString = dayInfo.dayString
        let dayInfoString = monthString + " " + weekString
        let dayInfoAttrString = NSMutableAttributedString.init(string:dayInfoString , attributes: dayInfoAttrs)
        let dayInfoRectX = bezierBGXAxis + bezierBGWidth - dayInfoAttrString.size().width
        let dayInfoRectY = (currentPageRect.height*notesTemplateInfo.dayInfoY)/100
        let dayInfoRect = CGRect(x: dayInfoRectX, y: dayInfoRectY, width: dayInfoAttrString.size().width, height: dayInfoAttrString.size().height)
        let dayInfoDrawLocation = CGPoint(x: dayInfoRect.origin.x, y: dayInfoRect.origin.y)
        dayInfoAttrString.draw(at: dayInfoDrawLocation)
        dailyNotesInfo.dayRect = getLinkRect(location: dayInfoDrawLocation, frameSize: dayInfoAttrString.size())
        //Today pill
        let todayPillXOffsetPercnt = 3.73 // gap between today pill and day info
        let dayInfoXPercnt = (dayInfoRect.origin.x/currentPageRect.width)*100
        let rightXOffsetPercnt = 100.0 - (dayInfoXPercnt - todayPillXOffsetPercnt)
        self.addTodayPillWith(rightXOffsetPercent: rightXOffsetPercnt, toContext: context)
    }
    private func addBezierPathWithRect( rect : CGRect, toContext context : CGContext, title:String?, tileColor : UIColor ){
        let bezierpath = UIBezierPath(roundedRect: rect, cornerRadius: 10)
        context.saveGState()
        context.addPath(bezierpath.cgPath)
        context.translateBy(x: 0, y: CGFloat(currentPageRect.height))
        context.scaleBy(x: 1, y: -1)
        context.setFillColor(UIColor(hexString: "#282E39").cgColor)
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
}
