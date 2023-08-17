//
//  FTMidnightLandscapeDayTemplate.swift
//  Noteshelf
//
//  Created by Ramakrishna on 20/05/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTStyles

class FTMidnightDiaryLandscapeDayTemplate :  FTMidnightDiaryTemplateFormat {
    
    // All values are in terms of percentages WRT selected device dimensions
    let dailyPlanBox1Width : CGFloat = 29.94
    let dailyPlanBox1Height : CGFloat = 78.44
    let dailyPlanBox2Width : CGFloat = 29.94
    let dailyPlanBox2Height : CGFloat = 52.85
    let dailyPlanBox1X : CGFloat =  3.68
    let dailyPlanBox1Y : CGFloat = 16.36
    let boxesXOffset : CGFloat = 1.76
    let boxesYOffset : CGFloat = 2.59
    let dailyMainFocusBoxWidth : CGFloat = 29.22
    let dailymainFocusBoxHeight : CGFloat = 12.98
    let prioritiesBoxWidth : CGFloat = 29.22
    let prioritiesBoxHeight : CGFloat = 37.27
    let notesBoxWidth : CGFloat = 60.97
    let notesBoxHeight : CGFloat = 22.98
    let horizontalDashedLineXAxis : CGFloat =  1.70
    let horizontalDashedLineYAxis : CGFloat = 5.71
    let horizontalDashedLineWidth : CGFloat = 26.70
    let verticalGapBWHorizontalDashedLine : CGFloat = 3.11
    let verticalDashedLineXAxis : CGFloat = 5.40
    let verticalDashedLineYAxis : CGFloat = 5.84
    let verticalDashedLine1Height : CGFloat = 70.51
    let verticalDashedLine2Height : CGFloat = 44.93
    let timeLineTimeValuesSet1 : [String] = ["06:00","07:00","08:00","09:00","10:00","11:00","12:00","13:00","14:00","15:00","16:00"]
    let timeLineTimeValuesSet2 : [String] = ["17:00","18:00","19:00","20:00","21:00","22:00","23:00"]
    let topGapForTimeLineTimings : CGFloat = 0.55
    let timeLineTimingsWidth : CGFloat = 4.71
    let timeLineTimingsHeight : CGFloat = 0.90
    
    override func renderTemplate(context: CGContext) {
        super.renderTemplate(context: context)
        let boxesXAXis : CGFloat = templateInfo.screenSize.width*dailyPlanBox1X/100
        let boxesYAxis : CGFloat = templateInfo.screenSize.height*dailyPlanBox1Y/100
        let dailyPlanBox1Width = templateInfo.screenSize.width*dailyPlanBox1Width/100
        let dailyPlanBox1Height = templateInfo.screenSize.height*dailyPlanBox1Height/100
        let dailyPlanBox2Width = templateInfo.screenSize.width*dailyPlanBox2Width/100
        let dailyPlanBox2Height = templateInfo.screenSize.height*dailyPlanBox2Height/100
        let mainFocusBoxWidth = templateInfo.screenSize.width*dailyMainFocusBoxWidth/100
        let mainFocusBoxHeight = templateInfo.screenSize.height*dailymainFocusBoxHeight/100
        let prioritiesBoxWidth = templateInfo.screenSize.width*prioritiesBoxWidth/100
        let prioritiesBoxHeight = templateInfo.screenSize.height*prioritiesBoxHeight/100
        let notesBoxWidth = templateInfo.screenSize.width*notesBoxWidth/100
        let notesBoxHeight = templateInfo.screenSize.height*notesBoxHeight/100
        let boxesHorizontalGapWidth = templateInfo.screenSize.width*boxesXOffset/100
        let boxesVerticalGapHeight = templateInfo.screenSize.height*boxesYOffset/100
        let dailyPlan2X = boxesXAXis + dailyPlanBox1Width + boxesHorizontalGapWidth
        let mainFocusBoxX = dailyPlan2X + dailyPlanBox2Width + boxesHorizontalGapWidth
        let prioritiesBoxY = boxesYAxis + mainFocusBoxHeight + boxesVerticalGapHeight
        let notesBoxX = boxesXAXis + dailyPlanBox1Width + boxesHorizontalGapWidth
        let notesBoxY = boxesYAxis + dailyPlanBox2Height + boxesVerticalGapHeight
        var horizontalDashedLineXAxisvalue = boxesXAXis + templateInfo.screenSize.width*horizontalDashedLineXAxis/100
        let horizontalDashedLineWidth = templateInfo.screenSize.width*horizontalDashedLineWidth/100
        var horizontalDashedLineYAxisValue = boxesYAxis +  templateInfo.screenSize.height*horizontalDashedLineYAxis/100
        var verticalDashedLineXAxisValue = boxesXAXis + templateInfo.screenSize.width*verticalDashedLineXAxis/100
        var verticalDashedLine1Height = templateInfo.screenSize.height*verticalDashedLine1Height/100
        var verticalDashedLine2Height = templateInfo.screenSize.height*verticalDashedLine2Height/100
        let verticalDashedLineYAxisValue = boxesYAxis + templateInfo.screenSize.height*verticalDashedLineYAxis/100
        let topGapForTimeLineTimings = templateInfo.screenSize.height*topGapForTimeLineTimings/100
        let timeLineTimingWidth = templateInfo.screenSize.width*timeLineTimingsWidth/100
        let timeLineTimingHeight = templateInfo.screenSize.height*timeLineTimingsHeight/100
        
        //Day plan box 1 rendering
        let dailyPlan1Rect = CGRect(x: boxesXAXis, y: boxesYAxis, width: dailyPlanBox1Width, height: dailyPlanBox1Height)
        self.addBezierPathWithRect(rect: dailyPlan1Rect, toContext: context, rectBGColor: bezierBoxesBGColor)
        self.renderTextWith(rect: dailyPlan1Rect, text: "DAILY PLAN", MaxFontSize: 11, minFointSize: 8)
        
        var timeLineStringIndex = 0
        for index in 1...23 {
            let bezierlineRect = CGRect(x: horizontalDashedLineXAxisvalue, y: horizontalDashedLineYAxisValue , width: horizontalDashedLineWidth, height: 1)
            self.addBezierlinePathWith(rect: bezierlineRect, toContext: context, isHorizontalDashedLine: true)
            if index % 2 != 0 && index != 23{ // As we need to add olny 11 time lines so excluding last timeline bezierpath
                let timeLineRect = CGRect(x: horizontalDashedLineXAxisvalue, y: horizontalDashedLineYAxisValue + topGapForTimeLineTimings, width: timeLineTimingWidth, height: timeLineTimingHeight)
                self.addTimeLineTimingsWith(rect: timeLineRect, withTimeLineTiming: self.timeLineTimeValuesSet1[timeLineStringIndex])
                timeLineStringIndex +=  1
            }
            horizontalDashedLineYAxisValue += templateInfo.screenSize.height*verticalGapBWHorizontalDashedLine/100
        }
        // Vertical time line rendering
        verticalDashedLine1Height = horizontalDashedLineYAxisValue - (boxesYAxis +  (templateInfo.screenSize.height*horizontalDashedLineYAxis/100)) - 24
        for _ in 1...2 {
            let bezierlineRect = CGRect(x: verticalDashedLineXAxisValue, y: verticalDashedLineYAxisValue , width:1 , height: verticalDashedLine1Height)
            self.addBezierlinePathWith(rect: bezierlineRect, toContext: context, isHorizontalDashedLine: false)
            verticalDashedLineXAxisValue += 3.0
        }
        
        //Day plan box 2 rendering
        let dailyPlan2Rect = CGRect(x: dailyPlan2X, y: boxesYAxis, width: dailyPlanBox2Width, height: dailyPlanBox2Height)
        self.addBezierPathWithRect(rect: dailyPlan2Rect, toContext: context, rectBGColor: bezierBoxesBGColor)
        
        horizontalDashedLineXAxisvalue = boxesXAXis + dailyPlanBox1Width + templateInfo.screenSize.width*boxesXOffset/100 + templateInfo.screenSize.width*horizontalDashedLineXAxis/100
        horizontalDashedLineYAxisValue = boxesYAxis +  templateInfo.screenSize.height*horizontalDashedLineYAxis/100
        timeLineStringIndex = 0
        for index in 1...15 {
            let bezierlineRect = CGRect(x: horizontalDashedLineXAxisvalue, y: horizontalDashedLineYAxisValue, width: horizontalDashedLineWidth, height: 1)
            self.addBezierlinePathWith(rect: bezierlineRect, toContext: context, isHorizontalDashedLine: true)
            if index % 2 != 0 && index != 15{ // As we need to add olny 7 time lines so excluding last timeline bezierpath
                let timeLineRect = CGRect(x: horizontalDashedLineXAxisvalue, y: horizontalDashedLineYAxisValue + topGapForTimeLineTimings, width: timeLineTimingWidth, height: timeLineTimingHeight)
                self.addTimeLineTimingsWith(rect: timeLineRect, withTimeLineTiming: self.timeLineTimeValuesSet2[timeLineStringIndex])
                timeLineStringIndex +=  1
            }
            horizontalDashedLineYAxisValue += templateInfo.screenSize.height*verticalGapBWHorizontalDashedLine/100
        }
        // Vertical time line rendering
        verticalDashedLine2Height = horizontalDashedLineYAxisValue - (boxesYAxis +  (templateInfo.screenSize.height*horizontalDashedLineYAxis/100)) - 20
        verticalDashedLineXAxisValue = boxesXAXis + dailyPlanBox1Width + boxesHorizontalGapWidth + templateInfo.screenSize.width*verticalDashedLineXAxis/100
        for _ in 1...2 {
            let bezierlineRect = CGRect(x: verticalDashedLineXAxisValue, y: verticalDashedLineYAxisValue , width:1 , height: verticalDashedLine2Height)
            self.addBezierlinePathWith(rect: bezierlineRect, toContext: context, isHorizontalDashedLine: false)
            verticalDashedLineXAxisValue += 3.0
        }
        
        //Main focus box rendering
        let mainFocus2Rect = CGRect(x: mainFocusBoxX, y: boxesYAxis, width: mainFocusBoxWidth, height: mainFocusBoxHeight)
        self.addBezierPathWithRect(rect: mainFocus2Rect, toContext: context, rectBGColor: bezierBoxesBGColor)
        self.renderTextWith(rect: mainFocus2Rect, text: "DAILY MAIN FOCUS", MaxFontSize: 11, minFointSize: 8)
        
        //Priorities box rendering
        let prioritesRect = CGRect(x: mainFocusBoxX, y: prioritiesBoxY, width: prioritiesBoxWidth, height: prioritiesBoxHeight)
        self.addBezierPathWithRect(rect: prioritesRect, toContext: context, rectBGColor: bezierBoxesBGColor)
        self.renderTextWith(rect: prioritesRect, text: "PRIORITIES", MaxFontSize: 11, minFointSize: 8)
        
        //Notes box rendering
        let notesRect = CGRect(x: notesBoxX, y: notesBoxY, width: notesBoxWidth, height: notesBoxHeight)
        self.addBezierPathWithRect(rect: notesRect, toContext: context, rectBGColor: bezierBoxesBGColor)
        self.renderTextWith(rect: notesRect, text: "NOTES", MaxFontSize: 11, minFointSize: 8)
        
    }
    
    func addBezierlinePathWith(rect:CGRect, toContext context : CGContext,isHorizontalDashedLine : Bool){
        let  bezierLinePath = UIBezierPath()
        let  p0 = CGPoint(x: rect.origin.x, y: rect.origin.y)
        bezierLinePath.move(to: p0)
        if isHorizontalDashedLine{
            let  p1 = CGPoint(x: rect.origin.x + rect.width , y: rect.origin.y)
            bezierLinePath.addLine(to: p1)
        }else{
            let  p1 = CGPoint(x: rect.minX  , y: rect.minY + rect.height)
            bezierLinePath.addLine(to: p1)
        }
        let  dashes: [ CGFloat ] = [ 4,3 ]
        bezierLinePath.setLineDash(dashes, count: dashes.count, phase: 0.0)
        bezierLinePath.lineWidth = 1.0
        bezierLinePath.lineCapStyle = .butt
        UIColor(red: 229/255, green: 229/255, blue: 229/255, alpha: 0.2).setStroke()
        context.addPath(bezierLinePath.cgPath)
        bezierLinePath.stroke()
        
    }
    func addTimeLineTimingsWith(rect:CGRect, withTimeLineTiming time:String){
        let font = UIFont.montserratFont(for: .bold, with: 10)
        let newFontSize = UIFont.getScaledFontSizeFor(font: font, screenSize: templateInfo.screenSize, minPointSize: 7.0)
        let newFont = UIFont.montserratFont(for: .bold, with: newFontSize)
        let textAttribute: [NSAttributedString.Key : Any] = [.font : newFont ,
                                                             NSAttributedString.Key.kern : 0.0,
                                                             .foregroundColor : UIColor(red: 229/255, green: 229/255, blue: 229/255, alpha: 1.0)]
            
        let mainFocusString = NSMutableAttributedString(string: time, attributes: textAttribute)
        let location = CGPoint(x: rect.origin.x, y: rect.origin.y)
        mainFocusString.draw(at: location)
    }
}
