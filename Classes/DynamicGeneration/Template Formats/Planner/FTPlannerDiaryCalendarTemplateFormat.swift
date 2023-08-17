//
//  FTPlannerDiaryCalendarTemplate.swift
//  Noteshelf
//
//  Created by Ramakrishna on 09/11/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

class FTPlannerDiaryCalendarTemplateFormat : FTPlannerDiaryTemplateFormat {
    
    // Below values are in terms of percentages
    var boxWidth : CGFloat =  26.61
    var boxHeight : CGFloat = 14.97
    var horizontalGapBWBoxes : CGFloat = 2.87
    var verticalGapBWBoxes : CGFloat = 6.39
    var startingXAxis : CGFloat = 4.91
    var startingYAxis : CGFloat = 14.41
    
    override func renderTemplate(context: CGContext) {
        super.renderTemplate(context: context)
        self.renderiPadTemplate(context: context)
    }
    private func renderiPadTemplate(context : CGContext){
        let isLandscaped = templateInfo.customVariants.isLandscape
        boxWidth = isLandscaped ? 19.96 : 26.61
        boxHeight = isLandscaped ? 20.38 : 14.97
        startingXAxis = isLandscaped ? 4.94 : 4.91
        startingYAxis = isLandscaped ? 17.40 : 14.41
        horizontalGapBWBoxes = isLandscaped ? 2.24 : 2.87
        verticalGapBWBoxes = isLandscaped ? 8.05 :6.39
        
        let xAxis : CGFloat = templateInfo.screenSize.width*startingXAxis/100
        var calenderYearBoxesYAxis : CGFloat = templateInfo.screenSize.height*startingYAxis/100
        var calenderYearBoxesXAXis : CGFloat = xAxis
        
        let widthPerBox = templateInfo.screenSize.width*boxWidth/100
        let heightPerBox = templateInfo.screenSize.height*boxHeight/100
        
        let numberOfColumns : Int = isLandscaped ? 4 : 3
        // Month boxes rendering
        for index in 1...12 {
            let bezierRect = CGRect(x: calenderYearBoxesXAXis, y: calenderYearBoxesYAxis, width: widthPerBox, height: heightPerBox)
            self.addBezierBoxWithBorder(rect: bezierRect, toContext: context, rectBGColor: self.getBezierBoxesBGColor(), borderColor: self.getBezierlinesTintColor(), cornerRadius: 0.0,withLineWidth: 0.5)
            self.drawLinesWithInitial(xAxis: calenderYearBoxesXAXis, yAxis: calenderYearBoxesYAxis, context: context, outerBoxWidth: widthPerBox, outerBoxHeight: heightPerBox)
            calenderYearBoxesXAXis += widthPerBox + templateInfo.screenSize.width*horizontalGapBWBoxes/100
            if index % numberOfColumns == 0 {
                calenderYearBoxesXAXis = xAxis
                calenderYearBoxesYAxis += heightPerBox + templateInfo.screenSize.height*verticalGapBWBoxes/100
            }
        }
    }
    private func drawMonthColorBandsWith(xAxis : CGFloat, yAxis : CGFloat, context : CGContext, width : CGFloat, bandColor : UIColor){
        let isLandscaped = templateInfo.customVariants.isLandscape
        let colorBandHeightPercnt = isLandscaped ? 2.59 : 1.90
        let colrbndYAxisPercnt = isLandscaped ? 5.71 : 4.00
        
        let colorBandHeight = templateInfo.screenSize.height*colorBandHeightPercnt/100
        let colorBandYAxis = templateInfo.screenSize.height*colrbndYAxisPercnt/100
        let colrbndYAxisWRTMnthBx = yAxis - colorBandYAxis
        
        let monthBandRect = CGRect(x: xAxis, y: colrbndYAxisWRTMnthBx, width: width, height: colorBandHeight)
        context.setFillColor(bandColor.cgColor)
        context.fill(monthBandRect)
    }
    private func drawLinesWithInitial(xAxis : CGFloat, yAxis : CGFloat ,context : CGContext, outerBoxWidth : CGFloat, outerBoxHeight : CGFloat){
        let verticalGapBWHorizantalLines: CGFloat = (outerBoxHeight/6)
        let horizontalLineX: CGFloat = xAxis
        var horizontalLineY: CGFloat = yAxis + verticalGapBWHorizantalLines
//        if templateInfo.customVariants.selectedDevice.identifier == "standard4" && !isLandscaped {
//            let extraOffset: CGFloat = 10.0
//            horizontalLineY -= extraOffset
//        }

        let horizontalLineWidth: CGFloat = outerBoxWidth
        

        // Drawing horizantal lines
        let numberOfHorizantalLines =  5
        for _ in 1...numberOfHorizantalLines
        {
            let bezierlineRect = CGRect(x: horizontalLineX, y: horizontalLineY + 0.5, width: horizontalLineWidth, height: 1)
            self.addHorizantalBezierLine(rect: bezierlineRect, toContext: context, withColor: self.getBezierlinesTintColor(),withLineWidth: 0.5)
            horizontalLineY +=  verticalGapBWHorizantalLines
        }

        // Drawing vertical lines
        let horizantalGapBWVerticalLines: CGFloat = (outerBoxWidth/7)
        var verticalLineX: CGFloat = xAxis + horizantalGapBWVerticalLines
        var verticalLineY = yAxis
//        if templateInfo.customVariants.selectedDevice.identifier == "standard4" && !isLandscaped {
//            let extraOffset: CGFloat = 10.0
//            verticalLineY -= extraOffset
//        }

        let verticalLineHeight: CGFloat = outerBoxHeight
        let numberOfVerticalLines = 6
        for _ in 1...numberOfVerticalLines {
            let bezierlineRect = CGRect(x: verticalLineX + 0.5 , y: verticalLineY, width: 1, height: verticalLineHeight)
            self.addVerticalBezierLine(rect: bezierlineRect, toContext: context, withColor: self.getBezierlinesTintColor(),withLineWidth: 0.5)
            verticalLineX +=  horizantalGapBWVerticalLines
        }
    }
}
