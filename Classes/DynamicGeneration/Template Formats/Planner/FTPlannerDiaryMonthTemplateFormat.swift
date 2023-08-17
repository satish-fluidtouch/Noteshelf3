//
//  FTPlannerDiaryMonthTemplateFormat.swift
//  Noteshelf
//
//  Created by Ramakrishna on 10/11/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTPlannerDiaryMonthTemplateFormat : FTPlannerDiaryTemplateFormat{
    override func renderTemplate(context: CGContext) {
        super.renderTemplate(context: context)
        self.renderiPadTemplate(context: context)
    }
    private func renderiPadTemplate(context : CGContext){
        let isLandscaped = templateInfo.customVariants.isLandscape
        let boxWidth : CGFloat = isLandscaped ? 11.59 : 10.78
        let boxHeight : CGFloat = isLandscaped ? 12.78 : 13.34
        let startingXAxis : CGFloat = isLandscaped ? 8.27 : 11.15
        let startingYAxis : CGFloat = isLandscaped ? 14.28 : 12.30
        let horizontalGapBWBoxes : CGFloat = isLandscaped ? 0.44 : 0.59
        let verticalGapBWBoxes : CGFloat = isLandscaped ? 0.71 :0.49
        
        let xAxis : CGFloat = templateInfo.screenSize.width*startingXAxis/100
        var monthBoxesYAxis : CGFloat = templateInfo.screenSize.height*startingYAxis/100
        var monthBoxesXAXis : CGFloat = xAxis
        
        let widthPerBox = templateInfo.screenSize.width*boxWidth/100
        let heightPerBox = templateInfo.screenSize.height*boxHeight/100
        
        let numberOfColumns : Int = 7
        // day boxes rendering
        for index in 1...42 {
            let bezierRect = CGRect(x: monthBoxesXAXis, y: monthBoxesYAxis, width: widthPerBox, height: heightPerBox)
            self.addBezierBoxWithBorder(rect: bezierRect, toContext: context, rectBGColor: self.getBezierBoxesBGColor(), borderColor: self.getBezierlinesTintColor(), cornerRadius: 2.0,withLineWidth: 0.5)
            monthBoxesXAXis += widthPerBox + templateInfo.screenSize.width*horizontalGapBWBoxes/100
            if index % numberOfColumns == 0 {
                monthBoxesXAXis = xAxis
                monthBoxesYAxis += heightPerBox + templateInfo.screenSize.height*verticalGapBWBoxes/100
            }
        }
    }
}
