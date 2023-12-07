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

        //goals box rendering

        let boxWidth : CGFloat = 38.93
        let boxHeight : CGFloat = 18.82
        let startingXAxis : CGFloat = 7.46
        let startingYAxis : CGFloat = 19.66
        let pageWidth = templateInfo.screenSize.width
        let pageHeight = templateInfo.screenSize.height

        let goalXAxis : CGFloat = pageWidth*startingXAxis/100
        let goalYAxis : CGFloat = pageHeight*startingYAxis/100
        let goalBoxWidth = pageWidth*boxWidth/100
        let goalBoxHeight = pageHeight*boxHeight/100

        let bezierRect = CGRect(x: goalXAxis, y: goalYAxis, width: goalBoxWidth, height: goalBoxHeight)
        self.addBezierBoxWithBorder(rect: bezierRect, toContext: context, rectBGColor: getBezierBoxesBGColor(), borderColor: getBezierlinesTintColor(), cornerRadius: 2.0,withLineWidth: 0.5)


        // To do colors rendering

        let toDoColorsRectYOffsetPercnt : CGFloat = 4.43
        let toDoColorsRectWidthPercnt : CGFloat = 38.93
        let toDoColorsRectHeightPercnt : CGFloat = 4.31
        let toDoCircleXOffsetPercnt : CGFloat = 0.89


        let toDoColorsRectXAxis = goalXAxis
        var toDoColorsRectYAxis : CGFloat = pageHeight*toDoColorsRectYOffsetPercnt/100 + goalYAxis + goalBoxHeight
        let toDoColorsRectWidth = pageWidth*toDoColorsRectWidthPercnt/100
        let toDoColorsRectHeight = pageHeight*toDoColorsRectHeightPercnt/100
        let toDoCircleRectXOffset = pageWidth*toDoCircleXOffsetPercnt/100
        var widthOfToDoCircle : CGFloat = 15
        if templateInfo.customVariants.selectedDevice.identifier == "standard4"
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

        let scheduleBandHeightPercnt = 2.39
        let scheduleBandWidthPercnt = 38.93
        let scheduleBandXOffsetPercnt = 7.19

        let scheduleBandBGColor = UIColor(hexString: "#EBA899")

        let scheduleBandHeight = pageHeight*scheduleBandHeightPercnt/100
        let scheduleBandWidth = pageWidth*scheduleBandWidthPercnt/100
        let scheduleBandXAxis =  goalXAxis + goalBoxWidth + pageWidth*scheduleBandXOffsetPercnt/100
        self.drawColorRectWith(xAxis: scheduleBandXAxis, yAxis: goalYAxis, context: context, width: scheduleBandWidth, height: scheduleBandHeight, bandColor: scheduleBandBGColor, cornerRadius: 3)

        // Notes box rendering

        let notesYAxisPercnt : CGFloat = 74.94
        let notesBoxHeightPercnt : CGFloat = 19.06

        let notesXAxis : CGFloat = goalXAxis
        let notesYAxis : CGFloat = pageHeight*notesYAxisPercnt/100
        let notesBoxWidth = goalBoxWidth
        let notesBoxHeight : CGFloat = pageHeight*notesBoxHeightPercnt/100

        let notesRect = CGRect(x: notesXAxis, y: notesYAxis, width: notesBoxWidth, height: notesBoxHeight)
        self.addBezierBoxWithBorder(rect: notesRect, toContext: context, rectBGColor: bezierBoxesBGColor, borderColor: bezierLinesTintColor, cornerRadius: 2.0,withLineWidth: 0.5)


        // Notes lines rendering

        let horizontalGapBWBoxesPercnt : CGFloat = 8.18
        let verticalGapBWLinesPercnt : CGFloat = 4.43
        let writingAreaYAxisPercnt : CGFloat = 26.49
        let writingAreaLineWidthPercnt : CGFloat = 36.96
        let writingAreaLineBottomPercnt : CGFloat = 6.59

        let writingAreaLinesXAxis = notesXAxis + notesBoxWidth + (pageWidth*horizontalGapBWBoxesPercnt/100)
        var writingAreaLineYAxis = (pageHeight*writingAreaYAxisPercnt/100)
        let writingAreaLineWidth = pageWidth*writingAreaLineWidthPercnt/100
        let verticalGapBWbezierlines = pageHeight*verticalGapBWLinesPercnt/100
        let bezierlinesBottom = pageHeight*writingAreaLineBottomPercnt/100

        let numberOfDashedLines = Int((pageHeight - bezierlinesBottom - writingAreaLineYAxis)/verticalGapBWbezierlines) + 1
        for _ in 1...numberOfDashedLines
        {
            let bezierlineRect = CGRect(x: writingAreaLinesXAxis, y: writingAreaLineYAxis, width: writingAreaLineWidth, height: 0.5)
            self.addBezierDashedlinePathWith(rect: bezierlineRect, toContext: context, withColor: getBezierlinesTintColor(), dashPattern: [1,2])
            writingAreaLineYAxis +=  verticalGapBWbezierlines
        }
        addSpreadLineSeperator(toContext: context)
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
