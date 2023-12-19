//
//  FTPlannerDiaryWeekTemplateFormat.swift
//  Noteshelf
//
//  Created by Ramakrishna on 10/11/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTPlanner2024DiaryWeekTemplateFormat : FTPlanner2024DiaryTemplateFormat {

    override func renderTemplate(context: CGContext) {
        super.renderTemplate(context: context)
        self.renderiPadTemplate(context: context)
    }
    private func renderiPadTemplate(context : CGContext){

        let boxWidth : CGFloat = 38.93
        let boxHeight : CGFloat = 17.62
        let startingXAxis : CGFloat = 7.46
        let startingYAxis : CGFloat = 19.90
        let horizontalGapBWBoxes : CGFloat = 7.19
        let verticalGapBWBoxes : CGFloat = 1.19
        let pageWidth = templateInfo.screenSize.width
        let pageHeight = templateInfo.screenSize.height

        let xAxis : CGFloat = pageWidth*startingXAxis/100
        let yAxis : CGFloat = pageHeight*startingYAxis/100
        var monthBoxesYAxis : CGFloat = yAxis
        var monthBoxesXAXis : CGFloat = xAxis

        let widthPerBox = pageWidth*boxWidth/100
        let heightPerBox = pageHeight*boxHeight/100

        // day boxes rendering
        let numberOfWeekBoxes : Int = 8
        for index in 1...numberOfWeekBoxes {
            let bezierRect = CGRect(x: monthBoxesXAXis, y: monthBoxesYAxis, width: widthPerBox, height: heightPerBox)
            self.addBezierBoxWithBorder(rect: bezierRect, toContext: context, rectBGColor: getBezierBoxesBGColor(), borderColor: getBezierlinesTintColor(), cornerRadius: 2.0,withLineWidth: 0.5)
            if index % numberOfWeekBoxes == 4 {
                monthBoxesYAxis = yAxis
                monthBoxesXAXis += widthPerBox + pageWidth*horizontalGapBWBoxes/100
            } else {
                monthBoxesYAxis += heightPerBox + pageHeight*verticalGapBWBoxes/100
            }
        }
        addSpreadLineSeperator(toContext: context)
    }
}
