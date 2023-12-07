//
//  FTPlannerDiaryYearTemplateFormat.swift
//  Noteshelf
//
//  Created by Ramakrishna on 10/11/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTPlanner2024DiaryYearTemplateFormat : FTPlanner2024DiaryTemplateFormat {

    override func renderTemplate(context: CGContext) {
        super.renderTemplate(context: context)
        self.renderiPadTemplate(context: context)
    }
    private func renderiPadTemplate(context : CGContext){

        let boxWidth : CGFloat = 18.34
        let boxHeight : CGFloat = 77.21
        let startingXAxis : CGFloat = 7.46
        let startingYAxis : CGFloat = 16.90
        let horizontalGapBWBoxes : CGFloat = 2.24
        let twoSpreadHorizontalGap: CGFloat = 7.19
        let pageWidth = templateInfo.screenSize.width
        let pageHeight = templateInfo.screenSize.height

        let xAxis : CGFloat = pageWidth*startingXAxis/100
        let monthBoxesYAxis : CGFloat = pageHeight*startingYAxis/100
        var monthBoxesXAXis : CGFloat = xAxis

        let widthPerBox = pageWidth*boxWidth/100
        let heightPerBox = pageHeight*boxHeight/100
        let twoSpreadGap = pageWidth*twoSpreadHorizontalGap/100

        let numberOfColumns : Int = 4
        let numberOfMonthBoxes : Int = 4
        // Year boxes rendering
        for index in 1...numberOfMonthBoxes {
            let bezierRect = CGRect(x: monthBoxesXAXis, y: monthBoxesYAxis, width: widthPerBox, height: heightPerBox)
            self.addBezierBoxWithBorder(rect: bezierRect, toContext: context, rectBGColor: self.getBezierBoxesBGColor(), borderColor: self.getBezierlinesTintColor(), cornerRadius: 2.0,withLineWidth: 0.5)
            self.drawLinesWithInitial(xAxis: monthBoxesXAXis, yAxis: monthBoxesYAxis, context: context, outerBoxHeight: heightPerBox)
            if index % numberOfColumns == 2 {
                monthBoxesXAXis += widthPerBox + twoSpreadGap
            } else {
                monthBoxesXAXis += widthPerBox + pageWidth*horizontalGapBWBoxes/100
            }
        }
        addSpreadLineSeperator(toContext: context)
    }
    private func drawLinesWithInitial(xAxis : CGFloat, yAxis : CGFloat ,context : CGContext, outerBoxHeight : CGFloat){

        let lineXOffset : CGFloat = 0.89
        let lineYOffset : CGFloat = 6.59
        let lineWidthPercnt : CGFloat = 16.54
        let verticalGapPercnt : CGFloat = 4.43
        let bottomYPercnt : CGFloat = 4.07
        let pageWidth = templateInfo.screenSize.width
        let pageHeight = templateInfo.screenSize.height

        let bezierLineXAxis = xAxis +  (pageWidth*lineXOffset/100)
        var bezierLineYAxis = yAxis +  (pageHeight*lineYOffset/100)

        let bezierLineWidth = pageWidth*lineWidthPercnt/100
        let verticalGapBWbezierlines = pageHeight*verticalGapPercnt/100
        let bezierlinesBottom = pageHeight*bottomYPercnt/100

        let numberOfDashedLines = Int((outerBoxHeight - bezierlinesBottom)/verticalGapBWbezierlines)
        for _ in 1...numberOfDashedLines
        {
            let bezierlineRect = CGRect(x: bezierLineXAxis, y: bezierLineYAxis, width: bezierLineWidth, height: 0.5)
            self.addHorizantalBezierLine(rect: bezierlineRect, toContext: context, withColor: self.getBezierlinesTintColor(),withLineWidth: 0.5)
            bezierLineYAxis +=  verticalGapBWbezierlines
        }
    }
}
