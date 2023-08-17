//
//  FTMidnightWeekTemplate.swift
//  Beizerpaths
//
//  Created by Ramakrishna on 06/05/21.
//

import Foundation
import PDFKit

class FTMidnightDiaryWeekTemplate : FTMidnightDiaryTemplateFormat {
    
    //All percentages are based on template width and height
    var weekDayBeizerPathWidthPercentage : CGFloat = 52.28
    var weekDayBeizerPathHeightPercentage : CGFloat = 10.50
    var mainFocusBeizerPathWidthPercentage : CGFloat = 35.74
    var mainFocusBeizerPathHeightPercentage : CGFloat = 10.50
    var prioritiesFocusBeizerPathWidthPercentage : CGFloat = 35.74
    var prioritiesFocusBeizerPathHeightPercentage : CGFloat = 22.80
    var notesBeizerPathWidthPercentage : CGFloat = 35.74
    var notesBeizerPathHeightPercentage : CGFloat = 47.43
    var horizontalGapBWBoxes : CGFloat = 2.16
    var verticalGapBWBoxes : CGFloat = 1.82
    var startingXAxis : CGFloat = 4.80
    var startingYAxis : CGFloat = 11.74
    
    override func renderTemplate(context: CGContext) {
        super.renderTemplate(context: context)
        if templateInfo.customVariants.selectedDevice.isiPad {
            self.renderiPadTemplate(context: context)
        }else{
            self.renderiPhoneTemplate(context: context)
        }
    }
    private func renderiPhoneTemplate(context : CGContext) {
        let isLandscaped = templateInfo.customVariants.isLandscape
        weekDayBeizerPathWidthPercentage = isLandscaped ? 46.17 : 89.06
        weekDayBeizerPathHeightPercentage = isLandscaped ? 15.10 : 10.88
        startingXAxis = isLandscaped ? 2.99 : 5.6
        startingYAxis = isLandscaped ? 20.84 : 10.35
        verticalGapBWBoxes = isLandscaped ? 3.32 : 1.43
        let horizontalGapBWBoxes : CGFloat =  1.49
        
        var boxesXAXis : CGFloat = templateInfo.screenSize.width*startingXAxis/100
        var boxesYAxis : CGFloat = templateInfo.screenSize.height*startingYAxis/100
        let weekDayWidthPerBox = templateInfo.screenSize.width*weekDayBeizerPathWidthPercentage/100
        let weekDayHeightPerBox = templateInfo.screenSize.height*weekDayBeizerPathHeightPercentage/100
        let boxesVerticalGapHeight = templateInfo.screenSize.height*verticalGapBWBoxes/100
        let boxesHorizontalGapWidth = templateInfo.screenSize.width*horizontalGapBWBoxes/100
        
        //weekDay boxes rendering
        let numberOfWeekBoxes = isLandscaped ? 8 : 7
        for index in 1...numberOfWeekBoxes {
            let bezierRect = CGRect(x: boxesXAXis, y: boxesYAxis, width: weekDayWidthPerBox, height: weekDayHeightPerBox)
            self.addBezierPathWithRect(rect: bezierRect, toContext: context, rectBGColor: bezierBoxesBGColor)
            if isLandscaped, index % 4 == 0 {
                boxesXAXis += weekDayWidthPerBox + boxesHorizontalGapWidth
                boxesYAxis = templateInfo.screenSize.height*startingYAxis/100
            }
            else{
                boxesYAxis += weekDayHeightPerBox + boxesVerticalGapHeight
            }
        }
    }
    private func renderiPadTemplate(context: CGContext){
        let isLandscaped = templateInfo.customVariants.isLandscape
        weekDayBeizerPathWidthPercentage = isLandscaped ? 53.77 : 52.28
        weekDayBeizerPathHeightPercentage = isLandscaped ? 9.74 : 10.50
        mainFocusBeizerPathWidthPercentage = isLandscaped ? 36.78 : 35.74
        mainFocusBeizerPathHeightPercentage = isLandscaped ? 9.74 : 10.50
        prioritiesFocusBeizerPathWidthPercentage = isLandscaped ? 36.78 : 35.74
        prioritiesFocusBeizerPathHeightPercentage = isLandscaped ? 21.29 : 22.80
        notesBeizerPathWidthPercentage = isLandscaped ? 36.78 : 35.74
        notesBeizerPathHeightPercentage = isLandscaped ? 44.41 : 47.43
        verticalGapBWBoxes = isLandscaped ? 1.78 : 1.82
        startingYAxis = isLandscaped ? 15.84 : 11.74
        startingXAxis = isLandscaped ? 3.59 : 4.80
        
        let xAxis : CGFloat = templateInfo.screenSize.width*startingXAxis/100
        let yAxis : CGFloat = templateInfo.screenSize.height*startingYAxis/100
        var boxesYAxis : CGFloat = yAxis
        var boxesXAXis : CGFloat = xAxis
        let weekDayWidthPerBox = templateInfo.screenSize.width*weekDayBeizerPathWidthPercentage/100
        let weekDayHeightPerBox = templateInfo.screenSize.height*weekDayBeizerPathHeightPercentage/100
        let mainFocusBoxWidth = templateInfo.screenSize.width*mainFocusBeizerPathWidthPercentage/100
        let mainFocusBoxHeight = templateInfo.screenSize.height*mainFocusBeizerPathHeightPercentage/100
        let prioritiesBoxWidth = templateInfo.screenSize.width*prioritiesFocusBeizerPathWidthPercentage/100
        let prioritiesBoxHeight = templateInfo.screenSize.height*prioritiesFocusBeizerPathHeightPercentage/100
        let notesBoxWidth = templateInfo.screenSize.width*notesBeizerPathWidthPercentage/100
        let notesBoxHeight = templateInfo.screenSize.height*notesBeizerPathHeightPercentage/100
        let boxesHorizontalGapWidth = templateInfo.screenSize.width*horizontalGapBWBoxes/100
        let boxesVerticalGapHeight = templateInfo.screenSize.height*verticalGapBWBoxes/100
        
        //weekDay boxes rendering
        for _ in 1...7 {
            let bezierRect = CGRect(x: boxesXAXis, y: boxesYAxis, width: weekDayWidthPerBox, height: weekDayHeightPerBox)
            self.addBezierPathWithRect(rect: bezierRect, toContext: context, rectBGColor: bezierBoxesBGColor)
            boxesYAxis += weekDayHeightPerBox + boxesVerticalGapHeight
        }
        //main focus box rendering
        boxesYAxis = yAxis
        boxesXAXis +=  weekDayWidthPerBox + boxesHorizontalGapWidth
        let focusBezierRect = CGRect(x: boxesXAXis, y: boxesYAxis, width: mainFocusBoxWidth, height: mainFocusBoxHeight)
        self.addBezierPathWithRect(rect: focusBezierRect, toContext: context, rectBGColor: bezierBoxesBGColor)
        self.renderTextWith(rect: focusBezierRect, text:"MAIN FOCUS", MaxFontSize: 11, minFointSize: 8)
        
        //Proiorities box rendering
        boxesYAxis +=  mainFocusBoxHeight + boxesVerticalGapHeight
        let prioritiesBezierRect = CGRect(x: boxesXAXis, y: boxesYAxis, width: prioritiesBoxWidth, height: prioritiesBoxHeight)
        self.addBezierPathWithRect(rect: prioritiesBezierRect, toContext: context, rectBGColor: bezierBoxesBGColor)
        self.renderTextWith(rect: prioritiesBezierRect, text:"PRIORITIES", MaxFontSize: 11, minFointSize: 8)
        
        //Notes box rendering
        boxesYAxis +=  prioritiesBoxHeight + boxesVerticalGapHeight
        let notesBezierRect = CGRect(x: boxesXAXis, y: boxesYAxis, width: notesBoxWidth, height: notesBoxHeight)
        self.addBezierPathWithRect(rect: notesBezierRect, toContext: context, rectBGColor: bezierBoxesBGColor)
        self.renderTextWith(rect: notesBezierRect, text:"NOTES", MaxFontSize: 11, minFointSize: 8)
    }
}
