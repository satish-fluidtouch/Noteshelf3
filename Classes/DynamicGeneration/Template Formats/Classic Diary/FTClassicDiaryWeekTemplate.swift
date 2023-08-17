//
//  FTClassicDiaryWeekTemplate.swift
//  Noteshelf
//
//  Created by Ramakrishna on 17/08/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTClassicDiaryWeekTemplate : FTClassicDiaryTemplateFormat {
    override func renderTemplate(context: CGContext) {
        super.renderTemplate(context: context)
        
        if templateInfo.customVariants.selectedDevice.isiPad {
            self.renderiPadTemplate(context: context)
        }
        else {
            self.renderiPhoneTemplate(context: context)
        }
    }
    private func renderiPadTemplate(context:CGContext){
        let isLandscaped = templateInfo.customVariants.isLandscape
        
        // In percentages
        let boxX : CGFloat = isLandscaped ? 3.59 : 4.79
        var boxY : CGFloat = isLandscaped ? 12.04 : 10.40
        let boxWidth : CGFloat = isLandscaped ? 92.80 : 90.40
        var boxHeight : CGFloat = isLandscaped ? 83.11 : 85.87
        let weekDayBoxheight : CGFloat = isLandscaped ? 14.02 : 14.31
        let weekboxWidth : CGFloat = isLandscaped ? 50.08 : 59.35
        let notesBoxHeight : CGFloat = isLandscaped ? 4.54 : 2.86
        let notesboxWidth : CGFloat = isLandscaped ? 42.71 : 31.05
        
        if templateInfo.customVariants.selectedDevice.identifier == "standard4" && isLandscaped
        {
            boxY = 10.74
            boxHeight = 82.20
        }
        
        // Values referencing choosen device size
        
        let boxXValue = templateInfo.screenSize.width*boxX/100
        let boxYValue = templateInfo.screenSize.height*boxY/100
        let boxWidthValue = templateInfo.screenSize.width*boxWidth/100
        let boxHeightValue = templateInfo.screenSize.height*boxHeight/100
        let weekBoxHeightValue = templateInfo.screenSize.height*weekDayBoxheight/100
        let weekBoxWidthValue = templateInfo.screenSize.width*weekboxWidth/100
        let notesBoxWidthValue = templateInfo.screenSize.width*notesboxWidth/100
        let notesBoxheightValue = templateInfo.screenSize.height*notesBoxHeight/100
        let totalNumberOfNotesBoxes = isLandscaped ? 17 : 29
        //Main box rendering
        let mainBoxHeight = CGFloat(totalNumberOfNotesBoxes + 1)*notesBoxheightValue
        let mainBoxRect = CGRect(x: boxXValue, y: boxYValue, width: boxWidthValue, height: mainBoxHeight)
        self.addBezierBoxWith(rect: mainBoxRect, toContext: context, borderWidth: 1.0, borderColor: UIColor(hexString: "#D4D4CB"))
        //weekBoxes bottom line rendering
        let numberofNotesBoxesPerDay : CGFloat = isLandscaped ? 3 : 5
        var weekBoxesBottomLineYValue = boxYValue +  numberofNotesBoxesPerDay*notesBoxheightValue
        
        for i in 1...5 {
            let bezierlineRect = CGRect(x: boxXValue, y: weekBoxesBottomLineYValue, width:weekBoxWidthValue , height: 1)
            self.addBezierlinePathWith(rect: bezierlineRect, toContext: context, withColor: UIColor(hexString: "#D4D4CB"))
            if i != 5 {
                weekBoxesBottomLineYValue += numberofNotesBoxesPerDay*notesBoxheightValue
            }
        }
        
        // week day and notes seperator
        let seperatorLineRect = CGRect(x: boxXValue + weekBoxWidthValue, y: boxYValue, width: 1, height: CGFloat(totalNumberOfNotesBoxes + 1)*notesBoxheightValue)
        self.addBezierLineWith(rect: seperatorLineRect, toContext: context, borderWidth: 1, borderColor: UIColor(hexString: "#D4D4CB"))
        
        let seperatorLineRect1 = CGRect(x: boxXValue + weekBoxWidthValue/2 - 2 , y: weekBoxesBottomLineYValue , width: 1, height: numberofNotesBoxesPerDay*notesBoxheightValue)
        
        self.addBezierLineWith(rect: seperatorLineRect1, toContext: context, borderWidth: 1, borderColor: UIColor(hexString: "#D4D4CB"))
        
        //notes boxes rendering
        var notesDayBoxYValue = boxYValue +  notesBoxheightValue
        
        for _ in 1...totalNumberOfNotesBoxes {
            let bezierlineRect = CGRect(x: boxXValue + weekBoxWidthValue, y: notesDayBoxYValue, width:notesBoxWidthValue , height: 1)
            self.addBezierlinePathWith(rect: bezierlineRect, toContext: context, withColor: UIColor(hexString: "#D4D4CB"))
            notesDayBoxYValue += notesBoxheightValue
        }
        
    }
    private func renderiPhoneTemplate(context:CGContext){
        
        // In percentages
        let boxX : CGFloat = 5.33
        let boxY : CGFloat = 9.69
        let boxWidth : CGFloat = 89.33
        let boxHeight : CGFloat = 85.47
        let weekDayBoxheight : CGFloat = 14.24
        let weekDayboxWidth : CGFloat = 89.33
        
        // Values referencing choosen device size
        
        let boxXValue = templateInfo.screenSize.width*boxX/100
        let boxYValue = templateInfo.screenSize.height*boxY/100
        let boxWidthValue = templateInfo.screenSize.width*boxWidth/100
        let boxHeightValue = templateInfo.screenSize.height*boxHeight/100
        let weekBoxHeightValue = templateInfo.screenSize.height*weekDayBoxheight/100
        let weekBoxWidthValue = templateInfo.screenSize.width*weekDayboxWidth/100
        
        //Main box rendering
        let mainBoxRect = CGRect(x: boxXValue, y: boxYValue, width: boxWidthValue, height: boxHeightValue)
        self.addBezierBoxWith(rect: mainBoxRect, toContext: context, borderWidth: 1.0, borderColor: UIColor(hexString: "#D4D4CB"))
        //weekBoxes rendering
        var weekBoxesYValue = boxYValue +  weekBoxHeightValue
        
        for i in 1...5 {
            let bezierlineRect = CGRect(x: boxXValue, y: weekBoxesYValue, width:weekBoxWidthValue , height: 1)
            self.addBezierlinePathWith(rect: bezierlineRect, toContext: context, withColor: UIColor(hexString: "#D4D4CB"))
            if i != 5 {
                weekBoxesYValue += weekBoxHeightValue
            }
        }
        
        let seperatorLineRect = CGRect(x: boxXValue + weekBoxWidthValue/2, y: weekBoxesYValue , width: 1, height: weekBoxHeightValue)
        
        self.addBezierLineWith(rect: seperatorLineRect, toContext: context, borderWidth: 1, borderColor: UIColor(hexString: "#D4D4CB"))
    }
}
