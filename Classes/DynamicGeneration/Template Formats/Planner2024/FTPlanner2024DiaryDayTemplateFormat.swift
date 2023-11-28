//
//  FTPlannerDiaryDayTemplateFormat.swift
//  Noteshelf
//
//  Created by Ramakrishna on 10/11/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

class FTPlanner2024DiaryDayTemplateFormat : FTPlanner2024DiaryTemplateFormat {
    
    override func renderTemplate(context: CGContext) {
        super.renderTemplate(context: context)
        self.renderiPadTemplate(context: context)
    }
    private func renderiPadTemplate(context : CGContext){
        let isLandscaped = templateInfo.customVariants.isLandscape
        
        //goals box rendering
        
        let boxWidth : CGFloat = isLandscaped ? 43.90 : 42.26
        var boxHeight : CGFloat = isLandscaped ? 19.81 : 20.33
        let startingXAxis : CGFloat = isLandscaped ? 3.59 : 4.79
        let startingYAxis : CGFloat = isLandscaped ? 16.62 : 12.21
        
        
        let goalXAxis : CGFloat = templateInfo.screenSize.width*startingXAxis/100
        let goalYAxis : CGFloat = templateInfo.screenSize.height*startingYAxis/100
        let goalBoxWidth = templateInfo.screenSize.width*boxWidth/100
        let goalBoxHeight = templateInfo.screenSize.height*boxHeight/100
        
        let bezierRect = CGRect(x: goalXAxis, y: goalYAxis, width: goalBoxWidth, height: goalBoxHeight)
        self.addBezierBoxWithBorder(rect: bezierRect, toContext: context, rectBGColor: getBezierBoxesBGColor(), borderColor: getBezierlinesTintColor(), cornerRadius: 2.0,withLineWidth: 0.5)

        
        // To do colors rendering
        
        var toDoColorsRectYOffsetPercnt : CGFloat = isLandscaped ? 5.55 : 4.09
        let toDoColorsRectWidthPercnt : CGFloat = isLandscaped ? 43.84 :42.20
        var toDoColorsRectHeightPercnt : CGFloat = isLandscaped ? 3.97 :3.81
        let toDoCircleXOffsetPercnt : CGFloat = isLandscaped ? 0.74 : 0.71
        
        
        let toDoColorsRectXAxis = goalXAxis
        var toDoColorsRectYAxis : CGFloat = templateInfo.screenSize.height*toDoColorsRectYOffsetPercnt/100 + goalYAxis + goalBoxHeight
        let toDoColorsRectWidth = templateInfo.screenSize.width*toDoColorsRectWidthPercnt/100
        let toDoColorsRectHeight = templateInfo.screenSize.height*toDoColorsRectHeightPercnt/100
        let toDoCircleRectXOffset = templateInfo.screenSize.width*toDoCircleXOffsetPercnt/100
        var widthOfToDoCircle : CGFloat = 15
        if templateInfo.customVariants.selectedDevice.identifier == "standard4" && isLandscaped
        {
            widthOfToDoCircle = 11
        }
        let toDoCircleBGColor = UIColor(hexString: "#FEFEFE")
        for color in toDoColors {
            let bandColor = UIColor(hexString: color,alpha: 0.5)
            self.drawToDoColorBandsWith(xAxis: toDoColorsRectXAxis, yAxis: toDoColorsRectYAxis, context: context, width: toDoColorsRectWidth, bandColor: bandColor, height: toDoColorsRectHeight)
            self.drawColorRectWith(xAxis: toDoColorsRectXAxis + toDoCircleRectXOffset, yAxis: (toDoColorsRectYAxis +  toDoColorsRectHeight/2) - widthOfToDoCircle/2, context: context, width: widthOfToDoCircle, height: widthOfToDoCircle, bandColor: toDoCircleBGColor, cornerRadius: widthOfToDoCircle*0.5)
            toDoColorsRectYAxis += toDoColorsRectHeight
        }
        
        //schedule heading color
        
        let scheduleBandHeightPercnt = isLandscaped ? 2.59 : 1.97
        let scheduleBandWidthPercnt = isLandscaped ? 43.34 : 41.72
        let scheduleBandXOffsetPercnt = isLandscaped ? 1.68 : 1.61
        
        let scheduleBandBGColor = UIColor(hexString: "#F0CBC2")

        let scheduleBandHeight = templateInfo.screenSize.height*scheduleBandHeightPercnt/100
        let scheduleBandWidth = templateInfo.screenSize.width*scheduleBandWidthPercnt/100
        let scheduleBandXAxis =  goalXAxis + goalBoxWidth + templateInfo.screenSize.width*scheduleBandXOffsetPercnt/100
        self.drawColorRectWith(xAxis: scheduleBandXAxis, yAxis: goalYAxis, context: context, width: scheduleBandWidth, height: scheduleBandHeight, bandColor: scheduleBandBGColor, cornerRadius: 3)

        // Notes box rendering
        
        let notesYAxisPercnt : CGFloat = isLandscaped ? 71.77 : 65.17
        let notesBoxHeightPercnt : CGFloat = isLandscaped ? 23.03 : 28.62
        
        let notesXAxis : CGFloat = goalXAxis
        let notesYAxis : CGFloat = templateInfo.screenSize.height*notesYAxisPercnt/100
        let notesBoxWidth = goalBoxWidth
        let notesBoxHeight : CGFloat = templateInfo.screenSize.height*notesBoxHeightPercnt/100
        
        let notesRect = CGRect(x: notesXAxis, y: notesYAxis, width: notesBoxWidth, height: notesBoxHeight)
        self.addBezierBoxWithBorder(rect: notesRect, toContext: context, rectBGColor: getBezierBoxesBGColor(), borderColor: getBezierlinesTintColor(), cornerRadius: 2.0,withLineWidth: 0.5)

        
        // Notes lines rendering	
        
        let horizontalGapBWBoxesPercnt : CGFloat = isLandscaped ? 3.03 : 2.93
        let verticalGapBWLinesPercnt : CGFloat = isLandscaped ? 3.97 : 2.99
        let writingAreaYAxisPercnt : CGFloat = isLandscaped ? 23.19 : 17.18
        let writingAreaLineWidthPercnt : CGFloat = isLandscaped ? 40.91 : 39.36
        let writingAreaLineBottomPercnt : CGFloat = isLandscaped ? 5.19 : 7.2
        
        let writingAreaLinesXAxis = notesXAxis + notesBoxWidth + (templateInfo.screenSize.width*horizontalGapBWBoxesPercnt/100)
        var writingAreaLineYAxis = (templateInfo.screenSize.height*writingAreaYAxisPercnt/100)
        let writingAreaLineWidth = templateInfo.screenSize.width*writingAreaLineWidthPercnt/100
        let verticalGapBWbezierlines = templateInfo.screenSize.height*verticalGapBWLinesPercnt/100
        let bezierlinesBottom = templateInfo.screenSize.height*writingAreaLineBottomPercnt/100
        
        let numberOfDashedLines = Int((templateInfo.screenSize.height - bezierlinesBottom - writingAreaLineYAxis)/verticalGapBWbezierlines) + 1
        for _ in 1...numberOfDashedLines
        {
            let bezierlineRect = CGRect(x: writingAreaLinesXAxis, y: writingAreaLineYAxis, width: writingAreaLineWidth, height: 0.5)
            self.addBezierDashedlinePathWith(rect: bezierlineRect, toContext: context, withColor: getBezierlinesTintColor(), dashPattern: [1,2])
            writingAreaLineYAxis +=  verticalGapBWbezierlines
        }
    }
    private func drawToDoColorBandsWith(xAxis : CGFloat, yAxis : CGFloat, context : CGContext, width : CGFloat, bandColor : UIColor, height : CGFloat){
        let monthBandRect = CGRect(x: xAxis, y: yAxis, width: width, height: height)
        context.setFillColor(bandColor.cgColor)
        context.fill(monthBandRect)
    }
    private func drawColorRectWith(xAxis  :CGFloat, yAxis : CGFloat, context : CGContext, width : CGFloat, height : CGFloat,bandColor: UIColor, cornerRadius : CGFloat){
        let circlePath = UIBezierPath(roundedRect: CGRect(x: xAxis, y: yAxis, width: width, height: height), cornerRadius: cornerRadius)
        context.addPath(circlePath.cgPath)
        context.setFillColor(bandColor.cgColor)
        context.fillPath()
    }
}
