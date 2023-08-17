//
//  FTClassicDiaryYearTemplate.swift
//  Noteshelf
//
//  Created by Ramakrishna on 03/08/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import PDFKit

class FTClassicDiaryYearTemplate : FTClassicDiaryTemplateFormat {
    // Below values are in terms of percentages
    var boxWidth : CGFloat =  0.0
    var boxHeight : CGFloat = 0.0
    var horizontalGapBWBoxes : CGFloat = 0.0
    var verticalGapBWBoxes : CGFloat = 0.0
    var startingXAxis : CGFloat = 0.0
    var startingYAxis : CGFloat = 0.0
    
    override func renderTemplate(context: CGContext) {
        super.renderTemplate(context: context)
        if templateInfo.customVariants.selectedDevice.isiPad {
            self.renderiPadTemplate(context: context)
        }
        else {
            self.renderiPhoneTemplate(context: context)
        }
    }
    private func renderiPhoneTemplate(context : CGContext){
        let isLandscaped = templateInfo.customVariants.isLandscape
        boxWidth = isLandscaped ? 22.18 : 26.40
        boxHeight = isLandscaped ? 20.24 : 19.48
        startingXAxis = isLandscaped ? 3.14 : 5.33
        startingYAxis = isLandscaped ? 20.84 : 9.53
        horizontalGapBWBoxes = isLandscaped ? 1.64 : 5.06
        verticalGapBWBoxes =  isLandscaped ? 3.12 : 2.47
        
        let boxX : CGFloat = templateInfo.screenSize.width*startingXAxis/100
        var calenderYearBoxesYAxis : CGFloat = templateInfo.screenSize.height*startingYAxis/100
        var calenderYearBoxesXAXis : CGFloat = boxX
        
        let widthPerBox = templateInfo.screenSize.width*boxWidth/100
        let heightPerBox = templateInfo.screenSize.height*boxHeight/100
        
        let numberOfColumns : Int = isLandscaped ? 4 : 3
        
        // Year boxes rendering
        for index in 1...12 {
            let bezierRect = CGRect(x: calenderYearBoxesXAXis, y: calenderYearBoxesYAxis, width: widthPerBox, height: heightPerBox)
            self.addBezierBoxWithBorder(rect: bezierRect, toContext: context, rectBGColor: bezierBoxesBGColor, borderColor: UIColor(hexString: "#D4D4CB", alpha: 1.0))
            calenderYearBoxesXAXis += widthPerBox + templateInfo.screenSize.width*horizontalGapBWBoxes/100
            if index % numberOfColumns == 0 {
                calenderYearBoxesXAXis = boxX
                calenderYearBoxesYAxis += heightPerBox + templateInfo.screenSize.height*verticalGapBWBoxes/100
            }
        }
    }
    private func renderiPadTemplate(context : CGContext){
        let isLandscaped = templateInfo.customVariants.isLandscape
        boxWidth = isLandscaped ? 21.31 : 28.65
        boxHeight = isLandscaped ? 24.76 : 19.27
        startingXAxis = isLandscaped ? 3.68 : 4.67
        startingYAxis = isLandscaped ? 16.49 : 11.73
        horizontalGapBWBoxes = isLandscaped ? 2.42 : 2.15
        verticalGapBWBoxes = isLandscaped ? 1.99 :2.19
        
        let xAxis : CGFloat = templateInfo.screenSize.width*startingXAxis/100
        var calenderYearBoxesYAxis : CGFloat = templateInfo.screenSize.height*startingYAxis/100
        var calenderYearBoxesXAXis : CGFloat = xAxis
        
        let widthPerBox = templateInfo.screenSize.width*boxWidth/100
        let heightPerBox = templateInfo.screenSize.height*boxHeight/100
        
        let numberOfColumns : Int = isLandscaped ? 4 : 3
        // Year boxes rendering
        for index in 1...12 {
            let bezierRect = CGRect(x: calenderYearBoxesXAXis, y: calenderYearBoxesYAxis, width: widthPerBox, height: heightPerBox)
            self.addBezierBoxWithBorder(rect: bezierRect, toContext: context, rectBGColor: bezierBoxesBGColor, borderColor: UIColor(hexString: "#D4D4CB", alpha: 1.0))
            calenderYearBoxesXAXis += widthPerBox + templateInfo.screenSize.width*horizontalGapBWBoxes/100
            if index % numberOfColumns == 0 {
                calenderYearBoxesXAXis = xAxis
                calenderYearBoxesYAxis += heightPerBox + templateInfo.screenSize.height*verticalGapBWBoxes/100
            }
        }
    }
}
