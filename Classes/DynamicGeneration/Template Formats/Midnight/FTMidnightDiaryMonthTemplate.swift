//
//  FTMidnightMonthTemplate.swift
//  Beizerpaths
//
//  Created by Ramakrishna on 05/05/21.
//

import Foundation
import PDFKit

class FTMidnightDiaryMonthTemplate : FTMidnightDiaryTemplateFormat {
    var yearBeizerPathWidthPercentageWRTMainView : CGFloat = 11.87
    var yearBeizerPathHeightPercentageWRTMainView : CGFloat = 11.92
    var horizontalGapBWBoxes : CGFloat = 1.19
    var verticalGapBWBoxes : CGFloat = 2.58
    var startingXAxis : CGFloat = 4.79
    var startingYAxis : CGFloat = 11.73
    
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
        let notesBoxX : CGFloat = isLandscaped ? 55.17 : 5.33
        let notesBoxY : CGFloat = isLandscaped ? 20.84 : 49.72
        let notesBoxWidth : CGFloat =  isLandscaped ? 40.77 : 89.33
        let notesBoxHeight : CGFloat = isLandscaped ? 70.99 : 45.30
        let horizontalDashedLineY : CGFloat = isLandscaped ? 9.06 : 4.0
        let gapBWDashedLines : CGFloat = isLandscaped ? 9.06 : 4.14
        
        let notesBoxXValue = templateInfo.screenSize.width*notesBoxX/100
        let notesBoxYValue = templateInfo.screenSize.height*notesBoxY/100
        let notesBoxWidthValue = templateInfo.screenSize.width*notesBoxWidth/100
        let notesBoxHeightValue = templateInfo.screenSize.height*notesBoxHeight/100
        let gapBWDashedLinesValue =  templateInfo.screenSize.height*gapBWDashedLines/100
        var horizontalDashedLinesYValue = notesBoxYValue +  templateInfo.screenSize.height*horizontalDashedLineY/100
        //Notes boxes rendering
    
        let bezierRect = CGRect(x: notesBoxXValue, y: notesBoxYValue, width: notesBoxWidthValue, height: notesBoxHeightValue)
        self.addBezierPathWithRect(rect: bezierRect, toContext: context, rectBGColor: bezierBoxesBGColor)
        
        //Dashed lines inside day plan box
        let numberOfDashedLines =  Int((notesBoxHeightValue)/gapBWDashedLinesValue)
        for _ in 1...numberOfDashedLines
        {
            let bezierlineRect = CGRect(x: notesBoxXValue, y: horizontalDashedLinesYValue, width: notesBoxWidthValue, height: 1)
            self.addBezierDashedlinePathWith(rect: bezierlineRect, toContext: context, withColor: UIColor(red: 229/255, green: 229/255, blue: 229/255, alpha: 0.2))
            horizontalDashedLinesYValue +=  gapBWDashedLinesValue
        }
        
    }
    private func renderiPadTemplate(context : CGContext){
        let isLandscaped = templateInfo.customVariants.isLandscape
        yearBeizerPathWidthPercentageWRTMainView = isLandscaped ? 12.20 : 11.87
        yearBeizerPathHeightPercentageWRTMainView = isLandscaped ? 11.06 : 11.92
        horizontalGapBWBoxes = isLandscaped ? 1.23 : 1.19
        verticalGapBWBoxes = isLandscaped ? 2.39 : 2.58
        startingXAxis = isLandscaped ? 3.59 : 4.79
        startingYAxis = isLandscaped ? 16.39 : 11.73
    
        let xAxis : CGFloat = templateInfo.screenSize.width*startingXAxis/100
        var calenderYearBoxesYAxis : CGFloat = templateInfo.screenSize.height*startingYAxis/100
        var calenderYearBoxesXAXis : CGFloat = xAxis
        let widthPerBox = templateInfo.screenSize.width*yearBeizerPathWidthPercentageWRTMainView/100
        let heightPerBox = templateInfo.screenSize.height*yearBeizerPathHeightPercentageWRTMainView/100
        
        for index in 1...42 {
            let bezierRect = CGRect(x: calenderYearBoxesXAXis, y: calenderYearBoxesYAxis, width: widthPerBox, height: heightPerBox)
            self.addBezierPathWithRect(rect: bezierRect, toContext: context, rectBGColor: bezierBoxesBGColor)
            calenderYearBoxesXAXis += widthPerBox + templateInfo.screenSize.width*horizontalGapBWBoxes/100
            if index % 7 == 0 {
                calenderYearBoxesXAXis = xAxis
                calenderYearBoxesYAxis += heightPerBox + templateInfo.screenSize.height*verticalGapBWBoxes/100
            }
        }
    }
}
