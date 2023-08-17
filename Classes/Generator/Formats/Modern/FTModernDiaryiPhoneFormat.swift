//
//  FTModernDiaryiPhoneFormat.swift
//  Noteshelf
//
//  Created by Narayana on 28/09/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTModernDiaryiPhoneFormat : FTModernDiaryFormat {

    override var isiPad: Bool {
        return false
    }
    
    override func renderWeekPage(context: CGContext, weeklyInfo: FTWeekInfo) {
        super.renderWeekPage(context: context, weeklyInfo: weeklyInfo)
        let templateInfo = screenInfo.spacesInfo.weekPageSpacesInfo

        let weekDayfont = UIFont.robotoRegular(screenInfo.fontsInfo.weekPageDetails.dayFontSize)
        let weekDayNewFontSize = UIFont.getScaledFontSizeFor(font: weekDayfont, screenSize: currentPageRect.size, minPointSize: 10)
        let weekAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.robotoRegular(weekDayNewFontSize),
                                                        .kern: 0.0,
                                                        .foregroundColor: UIColor.init(hexString:"35383D")]
        
        let weekDayXOffset: CGFloat = 1.72
        let weekDayYOffset: CGFloat = 0.92

        let weekDayInfoX = currentPageRect.width*templateInfo.baseBoxX/100 + currentPageRect.width*weekDayXOffset/100
        var weekDayInfoY = currentPageRect.height*templateInfo.baseBoxY/100 + currentPageRect.height*weekDayYOffset/100

        var weekDayRects : [CGRect] = []
        weeklyInfo.dayInfo.forEach(({(weekDay) in
            let weekAndDayString = NSMutableAttributedString.init(string: weekDay.weekString.uppercased(), attributes: weekAttrs)
            let weekAndDayFrameLocation = CGPoint(x: weekDayInfoX,
                                                  y: weekDayInfoY)
            weekAndDayString.draw(at: weekAndDayFrameLocation)
            
            if isBelongToCalendarYear(currentDate: weekDay.date) {
                weekDayRects.append(getLinkRect(location: weekAndDayFrameLocation,
                                                frameSize: CGSize(width: weekAndDayString.size().width, height: weekAndDayString.size().height)))
            }
            weekDayInfoY += currentPageRect.height*templateInfo.cellHeight/100 + (currentPageRect.height*templateInfo.cellOffsetY/100)
        }))
        currentWeekRectInfo.weekDayRects.append(contentsOf: weekDayRects)
        weekRectsInfo.append(currentWeekRectInfo)
    }
    
}
