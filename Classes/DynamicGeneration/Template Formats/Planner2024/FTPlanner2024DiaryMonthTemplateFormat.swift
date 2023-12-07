//
//  FTPlannerDiaryMonthTemplateFormat.swift
//  Noteshelf
//
//  Created by Ramakrishna on 10/11/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTPlanner2024DiaryMonthTemplateFormat : FTPlanner2024DiaryTemplateFormat{
    override func renderTemplate(context: CGContext) {
        super.renderTemplate(context: context)
        self.renderiPadTemplate(context: context)
    }
    private func renderiPadTemplate(context : CGContext){

        let boxWidth : CGFloat = 8.90
        let boxHeight : CGFloat = 12.94
        let startingXAxis : CGFloat = 17.53
        let startingYAxis : CGFloat = 19.66
        let horizontalGapBWBoxes : CGFloat = 1.07
        let verticalGapBWBoxes : CGFloat = 2.39
        let pageWidth = templateInfo.screenSize.width
        let pageHeight = templateInfo.screenSize.height
        let twoSpreadHorizontalGap: CGFloat = 7.19


        let twoSpreadGap = pageWidth*twoSpreadHorizontalGap/100
        let horizontalGap = pageWidth*horizontalGapBWBoxes/100
        let xAxis : CGFloat = pageWidth*startingXAxis/100
        var monthBoxesYAxis : CGFloat = pageHeight*startingYAxis/100
        var monthBoxesXAXis : CGFloat = xAxis

        let widthPerBox = pageWidth*boxWidth/100
        let heightPerBox = pageHeight*boxHeight/100

        let numberOfColumns : Int = 7
        // day boxes rendering
        var counter: Int = 1
        for index in 1...42 {
            let bezierRect = CGRect(x: monthBoxesXAXis, y: monthBoxesYAxis, width: widthPerBox, height: heightPerBox)
            self.addBezierBoxWithBorder(rect: bezierRect, toContext: context, rectBGColor: getBezierBoxesBGColor(), borderColor: getBezierlinesTintColor(), cornerRadius: 2.0,withLineWidth: 0.5)
            if index % numberOfColumns == 0 {
                counter = 1
                monthBoxesXAXis = xAxis
                monthBoxesYAxis += heightPerBox + pageHeight*verticalGapBWBoxes/100
            } else {
                monthBoxesXAXis +=  counter == 3 ? widthPerBox + twoSpreadGap : widthPerBox + horizontalGap
                counter += 1
            }
        }
        addSpreadLineSeperator(toContext: context)
    }
}
