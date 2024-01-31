//
//  FTPlannerDiaryWeekTemplateFormat.swift
//  Noteshelf
//
//  Created by Ramakrishna on 10/11/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTPlannerDiaryWeekTemplateFormat : FTPlannerDiaryTemplateFormat {
    override func renderTemplate(context: CGContext) {
        super.renderTemplate(context: context)
        self.renderiPadTemplate(context: context)
    }
    private func renderiPadTemplate(context : CGContext){
        let isLandscaped = templateInfo.customVariants.isLandscape
        let boxWidth : CGFloat = isLandscaped ? 43.91 : 42.32
        let boxHeight : CGFloat = isLandscaped ? 19.12 : 15.66
        let startingXAxis : CGFloat = isLandscaped ? 3.86 : 4.79
        let startingYAxis : CGFloat = isLandscaped ? 14.28 : 13.35
        let horizontalGapBWBoxes : CGFloat = isLandscaped ? 0.87 : 1.07
        let verticalGapBWBoxes : CGFloat = isLandscaped ? 1.29 :0.98
        
        let xAxis : CGFloat = templateInfo.screenSize.width*startingXAxis/100
        let yAxis : CGFloat = templateInfo.screenSize.height*startingYAxis/100
        var monthBoxesYAxis : CGFloat = yAxis
        var monthBoxesXAXis : CGFloat = xAxis
        
        let widthPerBox = templateInfo.screenSize.width*boxWidth/100
        var heightPerBox = templateInfo.screenSize.height*boxHeight/100
        
        // first column day boxes rendering
        let numberOfFirstColumnBoxes : Int = isLandscaped ? 4 : 5
        for _ in 1...numberOfFirstColumnBoxes {
            let bezierRect = CGRect(x: monthBoxesXAXis, y: monthBoxesYAxis, width: widthPerBox, height: heightPerBox)
            self.addBezierBoxWithBorder(rect: bezierRect, toContext: context, rectBGColor: self.getBezierBoxesBGColor(), borderColor: self.getBezierlinesTintColor(), cornerRadius: 2.0,withLineWidth: 0.5)
            monthBoxesYAxis += heightPerBox + templateInfo.screenSize.height*verticalGapBWBoxes/100
        }
        // second column day boxes rendering
        monthBoxesYAxis = yAxis
        monthBoxesXAXis += widthPerBox + templateInfo.screenSize.width*horizontalGapBWBoxes/100
        let numberOfSecondColumnBoxes : Int = isLandscaped ? 4 : 3
        for index in 1...numberOfSecondColumnBoxes {
            let bezierRect = CGRect(x: monthBoxesXAXis, y: monthBoxesYAxis, width: widthPerBox, height: heightPerBox)
            self.addBezierBoxWithBorder(rect: bezierRect, toContext: context, rectBGColor: self.getBezierBoxesBGColor(), borderColor: self.getBezierlinesTintColor(), cornerRadius: 2.0,withLineWidth: 0.5)
            monthBoxesYAxis += heightPerBox + templateInfo.screenSize.height*verticalGapBWBoxes/100
            if !isLandscaped && index == 2 {
                heightPerBox += 2*heightPerBox + 2*(templateInfo.screenSize.height*verticalGapBWBoxes/100) // for notes box
            }
        }
    }
}
