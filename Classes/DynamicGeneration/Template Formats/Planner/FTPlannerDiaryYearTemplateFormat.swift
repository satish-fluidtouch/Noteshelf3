//
//  FTPlannerDiaryYearTemplateFormat.swift
//  Noteshelf
//
//  Created by Ramakrishna on 10/11/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTPlannerDiaryYearTemplateFormat : FTPlannerDiaryTemplateFormat {
    
    override func renderTemplate(context: CGContext) {
        super.renderTemplate(context: context)
        self.renderiPadTemplate(context: context)
    }
    private func renderiPadTemplate(context : CGContext){
        let isLandscaped = templateInfo.customVariants.isLandscape
        let boxWidth : CGFloat = isLandscaped ? 20.59 : 26.61
        var boxHeight : CGFloat = isLandscaped ? 82.20 : 41.33
        let startingXAxis : CGFloat = isLandscaped ? 3.59 : 4.91
        let startingYAxis : CGFloat = isLandscaped ? 12.20 : 11.35
        let horizontalGapBWBoxes : CGFloat = isLandscaped ? 2.24 : 2.87
        let verticalGapBWBoxes : CGFloat = isLandscaped ? 8.05 :1.90
        
        
        let xAxis : CGFloat = templateInfo.screenSize.width*startingXAxis/100
        var monthBoxesYAxis : CGFloat = templateInfo.screenSize.height*startingYAxis/100
        var monthBoxesXAXis : CGFloat = xAxis
        
        let widthPerBox = templateInfo.screenSize.width*boxWidth/100
        let heightPerBox = templateInfo.screenSize.height*boxHeight/100
        
        let numberOfColumns : Int = isLandscaped ? 4 : 3
        let numberOfMonthBoxes : Int = isLandscaped ? 4 : 6
        // Year boxes rendering
        for index in 1...numberOfMonthBoxes {
            let bezierRect = CGRect(x: monthBoxesXAXis, y: monthBoxesYAxis, width: widthPerBox, height: heightPerBox)
            self.addBezierBoxWithBorder(rect: bezierRect, toContext: context, rectBGColor: self.getBezierBoxesBGColor(), borderColor: self.getBezierlinesTintColor(), cornerRadius: 2.0,withLineWidth: 0.5)
            self.drawLinesWithInitial(xAxis: monthBoxesXAXis, yAxis: monthBoxesYAxis, context: context, outerBoxHeight: heightPerBox)
            monthBoxesXAXis += widthPerBox + templateInfo.screenSize.width*horizontalGapBWBoxes/100
            if index % numberOfColumns == 0 {
                monthBoxesXAXis = xAxis
                monthBoxesYAxis += heightPerBox + templateInfo.screenSize.height*verticalGapBWBoxes/100
            }
        }
    }
    private func drawLinesWithInitial(xAxis : CGFloat, yAxis : CGFloat ,context : CGContext, outerBoxHeight : CGFloat){
        let isLandscaped = templateInfo.customVariants.isLandscape
        let lineXOffset : CGFloat = isLandscaped ? 1.02 : 1.31
        let lineYOffset : CGFloat = isLandscaped ? 7.01 : 4.96
        let lineWidthPercnt : CGFloat = isLandscaped ? 18.57 : 23.98
        let verticalGapPercnt : CGFloat = isLandscaped ? 4.41 : 3.05
        let bottomYPercnt : CGFloat = isLandscaped ? 4.54 : 2.78
        
        let bezierLineXAxis = xAxis +  (templateInfo.screenSize.width*lineXOffset/100)
        var bezierLineYAxis = yAxis +  (templateInfo.screenSize.height*lineYOffset/100)
        
        let bezierLineWidth = templateInfo.screenSize.width*lineWidthPercnt/100
        let verticalGapBWbezierlines = templateInfo.screenSize.height*verticalGapPercnt/100
        let bezierlinesBottom = templateInfo.screenSize.height*bottomYPercnt/100
        
        let numberOfDashedLines = Int((outerBoxHeight - bezierlinesBottom)/verticalGapBWbezierlines)
        for _ in 1...numberOfDashedLines
        {
            let bezierlineRect = CGRect(x: bezierLineXAxis, y: bezierLineYAxis, width: bezierLineWidth, height: 0.5)
            self.addHorizantalBezierLine(rect: bezierlineRect, toContext: context, withColor: self.getBezierlinesTintColor(),withLineWidth: 0.5)
            bezierLineYAxis +=  verticalGapBWbezierlines
        }
    }
}
