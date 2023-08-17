//
//  FTModernDiaryWeekTemplate.swift
//  Noteshelf
//
//  Created by Narayana on 01/10/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

class FTModernDiaryWeekTemplate: FTModernDiaryTemplateFormat {
    // Below values are in terms of percentages
    var boxWidth : CGFloat =  29.73
    var boxHeight : CGFloat = 27.92
    var horizontalGapBWBoxes : CGFloat = 1.80
    var verticalGapBWBoxes : CGFloat = 1.80
    var startingXAxis : CGFloat = 3.59
    var startingYAxis : CGFloat = 15.58

    override func renderTemplate(context: CGContext) {
        super.renderTemplate(context: context)
        if templateInfo.customVariants.selectedDevice.isiPad {
            self.renderiPadTemplate(context: context)
        }
        else {
            self.renderiPhoneTemplate(context: context)
        }
    }
    
    private func renderiPadTemplate(context: CGContext) {
        let isLandscape = templateInfo.customVariants.isLandscape
        // Week day boxes rendering
        boxWidth = isLandscape ? 29.73 : 27.33
        boxHeight = isLandscape ? 27.92 : 32.44
        startingXAxis = isLandscape ? 3.59 : 5.39
        startingYAxis = isLandscape ? 15.58 : 13.93
        horizontalGapBWBoxes = isLandscape ? 1.80 : 3.59
        verticalGapBWBoxes = isLandscape ? 2.59 : 2.38

        let xAxis : CGFloat = templateInfo.screenSize.width*startingXAxis/100
        var calenderYearBoxesYAxis : CGFloat = templateInfo.screenSize.height*startingYAxis/100
        var calenderYearBoxesXAXis : CGFloat = xAxis
        if templateInfo.customVariants.selectedDevice.identifier == "standard4" {
            let extraOffset: CGFloat = 10.0
            calenderYearBoxesYAxis -= extraOffset
        }

        let widthPerBox = templateInfo.screenSize.width*boxWidth/100
        let heightPerBox = templateInfo.screenSize.height*boxHeight/100
        
        let numberOfColumns: Int = 3
        for index in 1...6 {
            let bezierRect = CGRect(x: calenderYearBoxesXAXis, y: calenderYearBoxesYAxis, width: widthPerBox, height: heightPerBox)
            self.addBezierBoxWithBorder(rect: bezierRect, toContext: context, rectBGColor: bezierBoxesBGColor, borderColor: UIColor(hexString: "A2A2A2"), cornerRadius: 0.0)
            calenderYearBoxesXAXis += widthPerBox + templateInfo.screenSize.width*horizontalGapBWBoxes/100
            if index % numberOfColumns == 0 {
                calenderYearBoxesXAXis = xAxis
                calenderYearBoxesYAxis += heightPerBox + templateInfo.screenSize.height*verticalGapBWBoxes/100
            }
        }
            
        // Sunday Box rendering
            let sundayBoxWidth = isLandscape ? 92.80 : 89.20
            let sundayBoxHeight = isLandscape ? 18.18 : 12.59
            let widthPerSundayBox = templateInfo.screenSize.width*sundayBoxWidth/100
            let heightPerSundayBox = templateInfo.screenSize.height*sundayBoxHeight/100
            let bezierRect = CGRect(x: calenderYearBoxesXAXis, y: calenderYearBoxesYAxis, width: widthPerSundayBox, height: heightPerSundayBox)
            self.addBezierBoxWithBorder(rect: bezierRect, toContext: context, rectBGColor: bezierBoxesBGColor, borderColor: UIColor(hexString: "A2A2A2"), cornerRadius: 0.0)
    }
    
    private func renderiPhoneTemplate(context: CGContext) {
        // Week day boxes rendering
        boxWidth = 88.53
        boxHeight = 10.35
        startingXAxis = 5.6
        startingYAxis = 12.43
        verticalGapBWBoxes = 1.65

        let xAxis : CGFloat = templateInfo.screenSize.width*startingXAxis/100
        var calenderYearBoxesYAxis : CGFloat = templateInfo.screenSize.height*startingYAxis/100
        let calenderYearBoxesXAXis : CGFloat = xAxis
        
        let widthPerBox = templateInfo.screenSize.width*boxWidth/100
        let heightPerBox = templateInfo.screenSize.height*boxHeight/100
        
        for _ in 1...7 {
            let bezierRect = CGRect(x: calenderYearBoxesXAXis, y: calenderYearBoxesYAxis, width: widthPerBox, height: heightPerBox)
            self.addBezierBoxWithBorder(rect: bezierRect, toContext: context, rectBGColor: bezierBoxesBGColor, borderColor: UIColor(hexString: "A2A2A2"), cornerRadius: 0.0)
            calenderYearBoxesYAxis += heightPerBox + templateInfo.screenSize.height*verticalGapBWBoxes/100
        }

    }
    
}
