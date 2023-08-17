//
//  FTClassicDiaryCalendarTemplate.swift
//  Noteshelf
//
//  Created by Ramakrishna on 09/09/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//
import Foundation

class FTClassicDiaryCalendarTemplate : FTClassicDiaryTemplateFormat {
    
    // Below values are in terms of percentages
    var boxWidth : CGFloat =  28.65
    var boxHeight : CGFloat = 19.27
    var horizontalGapBWBoxes : CGFloat = 2.15
    var verticalGapBWBoxes : CGFloat = 2.19
    var startingXAxis : CGFloat = 4.67
    var startingYAxis : CGFloat = 11.73
    
    override func renderTemplate(context: CGContext) {
        super.renderTemplate(context: context)
        self.renderiPadTemplate(context: context)
    }
    private func renderiPadTemplate(context : CGContext){
        let isLandscaped = templateInfo.customVariants.isLandscape
        boxWidth = isLandscaped ? 21.31 : 28.41
        boxHeight = isLandscaped ? 24.76 : 19.69
        startingXAxis = isLandscaped ? 3.68 : 5.15
        startingYAxis = isLandscaped ? 16.49 : 11.83
        horizontalGapBWBoxes = isLandscaped ? 2.42 : 2.39
        verticalGapBWBoxes = isLandscaped ? 1.87 :1.79
        
        // For A5 sized templates only
        
        if templateInfo.customVariants.selectedDevice.identifier == "standard4" && isLandscaped
        {
            startingYAxis = 14.67
        }
        
        let xAxis : CGFloat = templateInfo.screenSize.width*startingXAxis/100
        var calenderYearBoxesYAxis : CGFloat = templateInfo.screenSize.height*startingYAxis/100
        var calenderYearBoxesXAXis : CGFloat = xAxis
        
        let widthPerBox = templateInfo.screenSize.width*boxWidth/100
        let heightPerBox = templateInfo.screenSize.height*boxHeight/100
        
        let numberOfColumns : Int = isLandscaped ? 4 : 3
        // Year boxes rendering
        for index in 1...12 {
            let bezierRect = CGRect(x: calenderYearBoxesXAXis, y: calenderYearBoxesYAxis, width: widthPerBox, height: heightPerBox)
            self.addBezierBoxWithBorder(rect: bezierRect, toContext: context, rectBGColor: bezierBoxesBGColor,borderColor: UIColor(hexString: "#D4D4CB", alpha: 1.0))
            calenderYearBoxesXAXis += widthPerBox + templateInfo.screenSize.width*horizontalGapBWBoxes/100
            if index % numberOfColumns == 0 {
                calenderYearBoxesXAXis = xAxis
                calenderYearBoxesYAxis += heightPerBox + templateInfo.screenSize.height*verticalGapBWBoxes/100
            }
        }
    }
}
