//
//  FTModernDiaryiPadFormat.swift
//  Noteshelf
//
//  Created by Narayana on 28/09/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

class FTModernDiaryiPadFormat : FTModernDiaryFormat {
    
    override func renderWeekPage(context: CGContext, weeklyInfo: FTWeekInfo) {
        super.renderWeekPage(context: context, weeklyInfo: weeklyInfo)
        
        let templateInfo = screenInfo.spacesInfo.weekPageSpacesInfo
        let isLandscape = self.formatInfo.customVariants.isLandscape
        let weekDayfont = UIFont.robotoRegular(screenInfo.fontsInfo.weekPageDetails.dayFontSize)
        let weekDayNewFontSize = UIFont.getScaledFontSizeFor(font: weekDayfont, screenSize: currentPageRect.size, minPointSize: 10)
        let weekAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.robotoRegular(weekDayNewFontSize),
                                                        .kern: 0.0,
                                                        .foregroundColor: UIColor.init(hexString:"35383D")]
        
        let numberOfColumns: Int = 3
        let weekDayXOffset: CGFloat = isLandscape ? 0.89 : 1.19
        let weekDayYOffset: CGFloat = isLandscape ? 1.03 : 0.66

        var weekDayInfoX = currentPageRect.width*templateInfo.baseBoxX/100 + currentPageRect.width*weekDayXOffset/100
        var weekDayInfoY = currentPageRect.height*templateInfo.baseBoxY/100 + currentPageRect.height*weekDayYOffset/100
        if self.customVariants.selectedDevice.identifier == "standard4" {
            let extraOffset: CGFloat = 10.0
            weekDayInfoY -= extraOffset
        }

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

            weekDayInfoX += currentPageRect.width*templateInfo.cellWidth/100 + (currentPageRect.width*templateInfo.cellOffsetX/100)
            
            if let index = weeklyInfo.dayInfo.index(of: weekDay), (index+1) % numberOfColumns == 0 {
                weekDayInfoX = currentPageRect.width*templateInfo.baseBoxX/100 + currentPageRect.width*weekDayXOffset/100
                weekDayInfoY += currentPageRect.height*templateInfo.cellHeight/100 + (currentPageRect.height*templateInfo.cellOffsetY/100)
            }
        }))
        currentWeekRectInfo.weekDayRects.append(contentsOf: weekDayRects)
        weekRectsInfo.append(currentWeekRectInfo)
    }
    
}
