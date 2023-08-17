//
//  FTModernDiaryYearTemplate.swift
//  Noteshelf
//
//  Created by Narayana on 28/09/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import PDFKit

class FTModernDiaryYearTemplate : FTModernDiaryTemplateFormat {
    // Below values are in terms of percentages
    var boxWidth : CGFloat =  28.65
    var boxHeight : CGFloat = 19.27
    var horizontalGapBWBoxes : CGFloat = 2.15
    var verticalGapBWBoxes : CGFloat = 2.19
    var startingXAxis : CGFloat = 4.67
    var startingYAxis : CGFloat = 11.73
    var titleYAxisPercentage : CGFloat = 3.91
    var titleXAxisPercentage : CGFloat = 4.79
    var titleWidthPercentage : CGFloat = 72.66
    var titleHeightPercentage : CGFloat = 7.25
    
    override func renderTemplate(context: CGContext) {
        super.renderTemplate(context: context)
        if templateInfo.customVariants.selectedDevice.isiPad {
            self.renderiPadTemplate(context: context)
        }
        else {
            self.renderiPhoneTemplate(context: context)
        }
    }
    
    private func renderiPhoneTemplate(context : CGContext) {
        boxWidth = 27.13
        boxHeight = 16.79
        startingXAxis = 6.66
        startingYAxis = 23.65
        horizontalGapBWBoxes = 2.66
        verticalGapBWBoxes = 1.38
        
        let boxX : CGFloat = templateInfo.screenSize.width*startingXAxis/100
        var calenderYearBoxesYAxis : CGFloat = templateInfo.screenSize.height*startingYAxis/100
        var calenderYearBoxesXAXis : CGFloat = boxX
        
        let widthPerBox = templateInfo.screenSize.width*boxWidth/100
        let heightPerBox = templateInfo.screenSize.height*boxHeight/100
        
        let numberOfColumns: Int = 3
        
        // Year boxes rendering
        for index in 1...12 {
            let bezierRect = CGRect(x: calenderYearBoxesXAXis, y: calenderYearBoxesYAxis, width: widthPerBox, height: heightPerBox)
            self.addBezierBoxWithBorder(rect: bezierRect, toContext: context, rectBGColor: bezierBoxesBGColor, borderColor: UIColor(hexString: "A2A2A2"), cornerRadius: 5.0)
            calenderYearBoxesXAXis += widthPerBox + templateInfo.screenSize.width*horizontalGapBWBoxes/100
            if index % numberOfColumns == 0 {
                calenderYearBoxesXAXis = boxX
                calenderYearBoxesYAxis += heightPerBox + templateInfo.screenSize.height*verticalGapBWBoxes/100
            }
        }
    }
    
    private func renderiPadTemplate(context : CGContext){
        let isLandscaped = templateInfo.customVariants.isLandscape
        boxWidth = isLandscaped ? 21.54 : 27.45
        boxHeight = isLandscaped ? 16.44 : 14.40
        startingXAxis = isLandscaped ? 4.22 : 5.15
        startingYAxis = isLandscaped ? 40.12 : 29.96
        horizontalGapBWBoxes = isLandscaped ? 1.79 : 3.59
        verticalGapBWBoxes = isLandscaped ? 2.59 : 2.86

        let xAxis : CGFloat = templateInfo.screenSize.width*startingXAxis/100
        var calenderYearBoxesYAxis : CGFloat = templateInfo.screenSize.height*startingYAxis/100
        var calenderYearBoxesXAXis : CGFloat = xAxis
        
        if templateInfo.customVariants.selectedDevice.identifier == "standard4" {
            let extraOffset: CGFloat = 30.0
            calenderYearBoxesYAxis -= extraOffset
        }

        let widthPerBox = templateInfo.screenSize.width*boxWidth/100
        let heightPerBox = templateInfo.screenSize.height*boxHeight/100
        
        let numberOfColumns : Int = isLandscaped ? 4 : 3
        // Year boxes rendering
        for index in 1...12 {
            let bezierRect = CGRect(x: calenderYearBoxesXAXis, y: calenderYearBoxesYAxis, width: widthPerBox, height: heightPerBox)
            self.addBezierBoxWithBorder(rect: bezierRect, toContext: context, rectBGColor: bezierBoxesBGColor, borderColor: UIColor(hexString: "A2A2A2"), cornerRadius: 5.0)
            calenderYearBoxesXAXis += widthPerBox + templateInfo.screenSize.width*horizontalGapBWBoxes/100
            if index % numberOfColumns == 0 {
                calenderYearBoxesXAXis = xAxis
                calenderYearBoxesYAxis += heightPerBox + templateInfo.screenSize.height*verticalGapBWBoxes/100
            }
        }
    }

}
