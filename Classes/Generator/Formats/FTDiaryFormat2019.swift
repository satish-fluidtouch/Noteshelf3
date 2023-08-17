//
//  FTDiaryFormat2019Ipad.swift
//  Template Generator
//
//  Created by sreenu cheedella on 11/12/19.
//  Copyright © 2019 Amar. All rights reserved.
//

import UIKit
import PDFKit
import FTStyles

class FTDiaryFormat2019: FTDairyFormat {
    override func renderYearPage(context: CGContext, months: [FTMonthInfo], calendarYear: FTYearFormatInfo) {
        super.renderYearPage(context: context, months: months, calendarYear: calendarYear)
        let templateInfo = screenInfo.spacesInfo.yearPageSpacesInfo
        
        let yearAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.baskervilleMedium(screenInfo.fontsInfo.yearPageDetails.yearFontSize),
                                                        .kern : 0.0,
                                                        .foregroundColor : UIColor.black.withAlphaComponent(0.8)]
        let yearString = NSMutableAttributedString(string: calendarPageYear, attributes: yearAttrs)
        let yearX = currentPageRect.width/2 - yearString.size().width/2
        let location = CGPoint(x: yearX, y: templateInfo.yearY)
        yearString.draw(at: location)
        yearRectsInfo.yearRect = getLinkRect(location: location, frameSize: yearString.size())
        
        var currMonthIndex = CGFloat(0)
        let columnCount = getColumnCount()
        let rowCount = getRowCount()
        let cellWidth = getYearCellWidth(columnCount: columnCount)
        let cellHeight = getYearCellHeight(rowCount: rowCount)
        
        months.forEach { (month) in
            let monthAttrs : [NSAttributedString.Key: Any] = [.font : UIFont.baskervilleMedium(screenInfo.fontsInfo.yearPageDetails.titleMonthFontSize),
                                                              NSAttributedString.Key.kern : 0.0,
                                                              .foregroundColor : UIColor.black.withAlphaComponent(0.8)]
            let monthString = NSMutableAttributedString(string: "\(formatInfo.screenType == FTScreenType.Ipad ? month.monthTitle : month.monthShortTitle)", attributes: monthAttrs)
            let widthFactor = currMonthIndex.truncatingRemainder(dividingBy: columnCount) * (cellWidth + templateInfo.cellOffsetX)
            let heightFactor = (CGFloat(Int(currMonthIndex/columnCount))) * (cellHeight + templateInfo.cellOffsetY)
            let monthX = templateInfo.baseBoxX + widthFactor
            let monthY = templateInfo.baseBoxY + heightFactor
            let location = CGPoint(x: monthX + (cellWidth - monthString.size().width)/2, y: monthY + (cellHeight - monthString.size().height)/2)
            monthString.draw(at: location)
            yearRectsInfo.monthRects.append(getLinkRect(location: CGPoint(x: monthX, y: monthY), frameSize: CGSize(width: cellWidth,height: cellHeight)))
            currMonthIndex+=1
        }
    }
    
    override func renderMonthPage(context: CGContext, monthInfo: FTMonthlyCalendarInfo, calendarYear: FTYearFormatInfo) {
        super.renderMonthPage(context: context, monthInfo: monthInfo, calendarYear: calendarYear)
        let currentMonthRectsInfo = FTDiaryMonthRectsInfo()
        let templateInfo = screenInfo.spacesInfo.monthPageSpacesInfo
        let cellWidth = (currentPageRect.width - templateInfo.baseBoxX - templateInfo.boxRightOffset)/7
        let cellHeight = (currentPageRect.height - templateInfo.baseBoxY - templateInfo.boxBottomOffset)/6
        
        let monthAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.baskervilleMedium(screenInfo.fontsInfo.monthPageDetails.monthFontSize),
                                                        .kern: 0.0,
                                                        .foregroundColor: UIColor.black.withAlphaComponent(0.8)]
        let monthString = NSMutableAttributedString.init(string: monthInfo.fullMonth, attributes: monthAttrs)
        let monthLocation = CGPoint(x: templateInfo.baseBoxX + cellWidth/2 - 8,
                                    y: templateInfo.baseBoxY - cellHeight - 12 - (cellHeight - 25)/2 - monthString.size().height)
        monthString.draw(at: monthLocation)
        currentMonthRectsInfo.monthRect = getLinkRect(location: monthLocation, frameSize: monthString.size())
        
        let yearAttrs: [NSAttributedString.Key: Any] = monthAttrs
        let yearString = NSMutableAttributedString.init(string: monthInfo.year, attributes: yearAttrs)
        let yearLocation = CGPoint(x: currentPageRect.width - templateInfo.boxRightOffset - yearString.size().width - cellWidth/2 + 8, y: monthLocation.y)
        yearString.draw(at: yearLocation)
        currentMonthRectsInfo.yearRect = getLinkRect(location: yearLocation, frameSize: yearString.size())
        
        let symbols = getWeekSymbols(monthInfo: monthInfo)
        
        let paragraphStyle = NSMutableParagraphStyle.init()
        paragraphStyle.alignment = .center
        let symbolAttrs: [NSAttributedString.Key : Any] =  [.font :UIFont.montserratFont(for: .light, with: screenInfo.fontsInfo.monthPageDetails.weekFontSize),
                                                           NSAttributedString.Key.kern : 0.0,
                                                           .foregroundColor : UIColor.black.withAlphaComponent(0.3),
                                                           .paragraphStyle: paragraphStyle];
        
        var symbolX = templateInfo.baseBoxX
        symbols.forEach({(symbol) in
            let symbolString = NSMutableAttributedString.init(string: symbol,attributes: symbolAttrs)
            symbolString.draw(in: CGRect(x: symbolX, y: templateInfo.baseBoxY - cellHeight - 12 + (cellHeight - symbolString.size().height)/2, width: cellWidth, height: cellHeight))
            symbolX += cellWidth
            }
        )
        
        var dayX = templateInfo.baseBoxX
        var dayY = templateInfo.baseBoxY
        var index = 1;
        monthInfo.dayInfo.forEach({(day) in
            if day.belongsToSameMonth {
                let dayAttrs: [NSAttributedString.Key: Any] = [.font :UIFont.baskervilleRegular(screenInfo.fontsInfo.monthPageDetails.dayFontSize),
                                                               NSAttributedString.Key.kern : 0.0,
                                                               .foregroundColor : UIColor.black.withAlphaComponent(0.6),
                                                               .paragraphStyle: paragraphStyle];
                let dayString = NSMutableAttributedString.init(string: day.dayString, attributes: dayAttrs)
                let drawRect = CGRect(x: dayX, y: dayY + (cellHeight - dayString.size().height)/2, width: cellWidth, height: cellHeight)
                dayString.draw(in: drawRect)
                currentMonthRectsInfo.dayRects.append(getLinkRect(location: CGPoint(x: dayX, y: dayY), frameSize: CGSize(width: cellWidth, height: cellHeight)))
            }
            index += 1;
            if(index > 7) {
                index = 1;
                dayX = templateInfo.baseBoxX;
                dayY += cellHeight;
            }
            else {
                dayX += cellWidth;
            }
        })
        
        monthRectsInfo.append(currentMonthRectsInfo)
    }
    
    override func renderWeekPage(context: CGContext, weeklyInfo: FTWeekInfo) {
        super.renderWeekPage(context: context, weeklyInfo: weeklyInfo)
        let currentWeekRectInfo: FTDiaryWeekRectsInfo = FTDiaryWeekRectsInfo()
        let templateInfo = screenInfo.spacesInfo.weekPageSpacesInfo
        
        let monthAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.baskervilleRegular(screenInfo.fontsInfo.weekPageDetails.monthFontSize),
                                                        .kern: 0.0,
                                                        .foregroundColor: UIColor.black.withAlphaComponent(0.8)]
        let monthString = NSMutableAttributedString.init(string: weeklyInfo.dayInfo[0].fullMonthString, attributes: monthAttrs)
        let monthLocation = CGPoint(x: 16, y: 15)
        monthString.draw(at: monthLocation)
        currentWeekRectInfo.monthRect = getLinkRect(location: monthLocation, frameSize: monthString.size())
        
        let yearAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.baskervilleRegular(screenInfo.fontsInfo.weekPageDetails.yearFontSize),
                                                       .kern: 2.0,
                                                       .foregroundColor: UIColor.black]
        let yearString = NSMutableAttributedString.init(string: weeklyInfo.dayInfo[0].yearString, attributes: yearAttrs)
        let yearLocation = CGPoint(x: pageRect().width - yearString.size().width - 25, y: 25)
        yearString.draw(at: yearLocation)
        currentWeekRectInfo.yearRect = getLinkRect(location: yearLocation, frameSize: yearString.size())
        
        var index = CGFloat(0)
        let weekAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.baskervilleRegular(screenInfo.fontsInfo.weekPageDetails.weekFontSize),
                                                       .kern: 0.0,
                                                       .foregroundColor: UIColor.black.withAlphaComponent(0.6)]
        let dayAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.baskervilleRegular(screenInfo.fontsInfo.weekPageDetails.dayFontSize),
                                                      .kern: 0.0,
                                                      .foregroundColor: UIColor.black.withAlphaComponent(0.3)]
        weeklyInfo.dayInfo.forEach(({(weekDay) in
            let weekString = NSMutableAttributedString.init(string: weekDay.weekString, attributes: weekAttrs)
            let weekFrameLocation = CGPoint(x: templateInfo.baseBoxX + (index == 6 ? templateInfo.cellWidth/2:0),
                                            y: templateInfo.baseBoxY + (index >= 6 ? index - 1:index)*templateInfo.cellHeight)
            let weekOffsetX = CGFloat(16)
            let weekOffsetY = CGFloat(9)
            let weekLocation = CGPoint(x: weekFrameLocation.x + weekOffsetX, y: weekFrameLocation.y + weekOffsetY)
            weekString.draw(at: weekLocation)
            let linkRectWidth = 2*weekOffsetX + weekString.size().width
            let linkRectHeight = 2*weekOffsetY + weekString.size().height
            if isBelongToCalendarYear(currentDate: weeklyInfo.dayInfo[Int(index)].date) {
                currentWeekRectInfo.weekDayRects.append(getLinkRect(location: weekFrameLocation,
                                                                    frameSize: CGSize(width: linkRectWidth, height: linkRectHeight)))
            }
            
            let dayString = NSMutableAttributedString.init(string: weekDay.dayString, attributes: dayAttrs)
            dayString.draw(at: CGPoint(x: weekFrameLocation.x + 16 ,
                                       y: weekFrameLocation.y + templateInfo.cellHeight - 9 - dayString.size().height))
            index += 1
        }))
        weekRectsInfo.append(currentWeekRectInfo)
    }
    
    override func renderDayPage(context: CGContext, dayInfo: FTDayInfo) {
        if !dayInfo.belongsToSameMonth {
            return
        }
        super.renderDayPage(context: context, dayInfo: dayInfo);
        let currentDayRectsInfo: FTDiaryDayRectsInfo = FTDiaryDayRectsInfo()
        let templateInfo = screenInfo.spacesInfo.dayPageSpacesInfo
        
        let dayAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.baskervilleRegular(screenInfo.fontsInfo.dayPageDetails.dayFontSize),
                                                       NSAttributedString.Key.kern : 0,
                                                       .foregroundColor : UIColor.black.withAlphaComponent(0.8)];
        let dayString = NSMutableAttributedString.init(string: dayInfo.dayString, attributes: dayAttrs)
        let dayLocation = CGPoint(x: templateInfo.baseX, y: templateInfo.baseY)
        dayString.draw(at: dayLocation)
        
        let monthAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.baskervilleSemiBold(screenInfo.fontsInfo.dayPageDetails.monthFontSize),
                                                         NSAttributedString.Key.kern : 0.0,
                                                         .foregroundColor : UIColor.black.withAlphaComponent(0.8)];
        let monthString = NSMutableAttributedString.init(string: dayInfo.fullMonthString.uppercased(), attributes: monthAttrs)
        let monthLocation = CGPoint(x: templateInfo.baseX , y: dayLocation.y + dayString.size().height - 3)
        monthString.draw(at: monthLocation)
        currentDayRectsInfo.monthRect = getLinkRect(location: monthLocation, frameSize: monthString.size())
        
        let weekAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.montserratFont(for: .light, with: screenInfo.fontsInfo.dayPageDetails.weekFontSize),
                                                        NSAttributedString.Key.kern : 3.0,
                                                        .foregroundColor : UIColor.black.withAlphaComponent(0.8)];
        let weekString = NSMutableAttributedString.init(string: dayInfo.weekString, attributes: weekAttrs)
        let weekLocation = CGPoint(x: templateInfo.baseX , y: monthLocation.y + monthString.size().height + 14)
        weekString.draw(at: weekLocation)
        currentDayRectsInfo.weekRect = getLinkRect(location: weekLocation, frameSize: weekString.size())
        
        let yearAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.montserratFont(for: .light, with: screenInfo.fontsInfo.dayPageDetails.yearFontSize),
                                                        NSAttributedString.Key.kern : 2.0,
                                                        .foregroundColor : UIColor.black];
        let yearString = NSMutableAttributedString.init(string: dayInfo.yearString, attributes: yearAttrs)
        let yearLocation = CGPoint(x: currentPageRect.width - (templateInfo.baseX + 9 + yearString.size().width),
                                   y: weekLocation.y)
        yearString.draw(at: yearLocation)
        currentDayRectsInfo.yearRect = getLinkRect(location: yearLocation, frameSize: yearString.size())
        dayRectsInfo.append(currentDayRectsInfo)
    }
}
