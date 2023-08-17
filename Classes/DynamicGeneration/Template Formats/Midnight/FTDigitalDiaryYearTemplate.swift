//
//  FTMidnightYearTheme.swift
//  Beizerpaths
//
//  Created by Ramakrishna on 05/05/21.
//

import Foundation
import PDFKit

class FTDigitalDiaryYearTemplate : FTMidnightDiaryTemplateFormat {
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
    private func renderiPhoneTemplate(context : CGContext){
        let isLandscaped = templateInfo.customVariants.isLandscape
        boxWidth = isLandscaped ? 22.59 : 28.19
        boxHeight = isLandscaped ? 21.93 : 19.84
        startingXAxis = isLandscaped ? 3.14 : 5.33
        startingYAxis = isLandscaped ? 20.84 : 10.35
        horizontalGapBWBoxes = isLandscaped ? 1.19 : 2.37
        verticalGapBWBoxes =  isLandscaped ? 2.59 : 1.81
        
        let boxX : CGFloat = templateInfo.screenSize.width*startingXAxis/100
        var calenderYearBoxesYAxis : CGFloat = templateInfo.screenSize.height*startingYAxis/100
        var calenderYearBoxesXAXis : CGFloat = boxX
        
        let widthPerBox = templateInfo.screenSize.width*boxWidth/100
        let heightPerBox = templateInfo.screenSize.height*boxHeight/100
        
        let numberOfColumns : Int = isLandscaped ? 4 : 3
        
        // Year boxes rendering
        for index in 1...12 {
            let bezierRect = CGRect(x: calenderYearBoxesXAXis, y: calenderYearBoxesYAxis, width: widthPerBox, height: heightPerBox)
            self.addBezierPathWithRect(rect: bezierRect, toContext: context, rectBGColor: bezierBoxesBGColor)
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
            self.addBezierPathWithRect(rect: bezierRect, toContext: context, rectBGColor: bezierBoxesBGColor)
            calenderYearBoxesXAXis += widthPerBox + templateInfo.screenSize.width*horizontalGapBWBoxes/100
            if index % numberOfColumns == 0 {
                calenderYearBoxesXAXis = xAxis
                calenderYearBoxesYAxis += heightPerBox + templateInfo.screenSize.height*verticalGapBWBoxes/100
            }
        }
    }
}
