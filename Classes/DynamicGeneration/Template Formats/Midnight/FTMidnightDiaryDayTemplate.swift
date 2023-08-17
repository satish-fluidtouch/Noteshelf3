//
//  FTMidnightDayTemplate.swift
//  Beizerpaths
//
//  Created by Ramakrishna on 06/05/21.
//

import UIKit
import FTStyles

class FTMidnightDiaryDayTemplate : FTMidnightDiaryTemplateFormat{
    
    //All percentages are based on template width and height
    var dailyPlanBeizerPathWidthPercentage : CGFloat = 52.28
    var dailyPlanBeizerPathHeightPercentage : CGFloat = 84.36
    var mainFocusBeizerPathWidthPercentage : CGFloat = 35.74
    var mainFocusBeizerPathHeightPercentage : CGFloat = 10.50
    let prioritiesFocusBeizerPathWidthPercentage : CGFloat = 35.74
    let prioritiesFocusBeizerPathHeightPercentage : CGFloat = 30.35
    var NotesBeizerPathWidthPercentage : CGFloat = 35.74
    var NotesBeizerPathHeightPercentage : CGFloat = 39.79
    var horizontalGapBWBoxes : CGFloat = 2.16
    var verticalGapBWBoxes : CGFloat = 1.82
    let topGapForNotesBox : CGFloat = 1.90
    var startingXAxis : CGFloat = 4.80
    var startingYAxis : CGFloat = 11.74
    var horizontalDashedLineXAxisPercentage : CGFloat =  7.0743
    let horizontalDashedLineEndPointXAxisPercentage : CGFloat =  54.19
    var horizontalDashedLineYAxisPercentage : CGFloat = 16.0305
    var horizontalDashedLineWidthPercentage : CGFloat = 47.1223
    var verticalGapBWHorizontalDashedLinePercentage : CGFloat = 2.29
    let verticalDashedLineXAxisPercentage : CGFloat = 11.39
    let verticalDashedLineHeightPercentage : CGFloat = 77.86
    let timeLineTimeValues : [String] = ["06:00","07:00","08:00","09:00","10:00","11:00","12:00","13:00","14:00","15:00","16:00","17:00","18:00","19:00","20:00","21:00","22:00"]
    let topGapForTimeLineTimingsPercentage = 0.55
    let timeLineTimingsWidthPercentage = 4.71
    let timeLineTimingsHeightPercentage = 0.90
    
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
        let isLandscape = templateInfo.customVariants.isLandscape
        startingXAxis =  isLandscape ? 2.99 : 5.33
        startingYAxis =  isLandscape ? 20.84 : 10.35
        var boxesYAxis : CGFloat = templateInfo.screenSize.height*startingYAxis/100
        var boxesXAXis : CGFloat = templateInfo.screenSize.width*startingXAxis/100
        mainFocusBeizerPathWidthPercentage = isLandscape ? 46.17 : 89.33
        mainFocusBeizerPathHeightPercentage = isLandscape ? 29.0 : 15.19
        dailyPlanBeizerPathWidthPercentage = isLandscape ? 46.17 :  89.33
        dailyPlanBeizerPathHeightPercentage = isLandscape ? 70.99 : 46.08
        NotesBeizerPathWidthPercentage = isLandscape ? 46.17 : 89.33
        NotesBeizerPathHeightPercentage = isLandscape ? 38.67 : 20.76
        verticalGapBWBoxes = isLandscape ? 3.32 : 1.39
        horizontalGapBWBoxes = 1.64
        horizontalDashedLineXAxisPercentage = isLandscape ? CGFloat(0.86 + startingXAxis + dailyPlanBeizerPathWidthPercentage + horizontalGapBWBoxes) : 6.99
        horizontalDashedLineYAxisPercentage = isLandscape ? 9.44 :  4.31
        horizontalDashedLineWidthPercentage = isLandscape ? 44.31 : 85.72
        verticalGapBWHorizontalDashedLinePercentage = isLandscape ? 9.06 : 3.34
        
        let dailyPlanWidth = templateInfo.screenSize.width*dailyPlanBeizerPathWidthPercentage/100
        let dailyPlanHeight = templateInfo.screenSize.height*dailyPlanBeizerPathHeightPercentage/100
        let mainFocusBoxWidth = templateInfo.screenSize.width*mainFocusBeizerPathWidthPercentage/100
        let mainFocusBoxHeight = templateInfo.screenSize.height*mainFocusBeizerPathHeightPercentage/100
        let notesBoxWidth = templateInfo.screenSize.width*NotesBeizerPathWidthPercentage/100
        let notesBoxHeight = templateInfo.screenSize.height*NotesBeizerPathHeightPercentage/100
        let boxesVerticalGapHeight = templateInfo.screenSize.height*verticalGapBWBoxes/100
        let boxesHorizontalGapWidth = templateInfo.screenSize.width*horizontalGapBWBoxes/100
        let horizontalDashedLineXAxis = templateInfo.screenSize.width*CGFloat(horizontalDashedLineXAxisPercentage)/100
        let horizontalDashedLineWidth = templateInfo.screenSize.width*CGFloat(horizontalDashedLineWidthPercentage)/100
        var horizontalDashedLineYAxis = boxesYAxis + templateInfo.screenSize.height*CGFloat(horizontalDashedLineYAxisPercentage)/100 + mainFocusBoxHeight + boxesVerticalGapHeight
        if isLandscape {
            horizontalDashedLineYAxis = boxesYAxis + templateInfo.screenSize.height*CGFloat(horizontalDashedLineYAxisPercentage)/100
        }
        let verticalGapBWDashedLines = templateInfo.screenSize.height*CGFloat(verticalGapBWHorizontalDashedLinePercentage)/100
        let dashedlinesBottom = templateInfo.screenSize.height * CGFloat(1.67)/100
        
        //main focus box rendering
        let focusBezierRect = CGRect(x: boxesXAXis, y: boxesYAxis, width: mainFocusBoxWidth, height: mainFocusBoxHeight)
        self.addBezierPathWithRect(rect: focusBezierRect, toContext: context, rectBGColor: bezierBoxesBGColor)
        self.renderTextWith(rect: focusBezierRect, text: "DAILY MAIN FOCUS", MaxFontSize: 10, minFointSize: 7)
        
        //Day plan boxes rendering
        boxesYAxis +=  mainFocusBoxHeight + boxesVerticalGapHeight
        if isLandscape {
            boxesYAxis =  templateInfo.screenSize.height*startingYAxis/100
            boxesXAXis += mainFocusBoxWidth + boxesHorizontalGapWidth
        }
        let bezierRect = CGRect(x: boxesXAXis, y: boxesYAxis, width: dailyPlanWidth, height: dailyPlanHeight)
        self.addBezierPathWithRect(rect: bezierRect, toContext: context, rectBGColor: bezierBoxesBGColor)
        self.renderTextWith(rect: bezierRect, text: "DAILY PLAN", MaxFontSize: 10, minFointSize: 7)
        
        //Dashed lines inside day plan box
        let numberOfDashedLines =  Int((dailyPlanHeight - dashedlinesBottom)/verticalGapBWDashedLines)
        for _ in 1...numberOfDashedLines
        {
            let bezierlineRect = CGRect(x: horizontalDashedLineXAxis, y: horizontalDashedLineYAxis, width: horizontalDashedLineWidth, height: 1)
            self.addBezierDashedlinePathWith(rect: bezierlineRect, toContext: context,withColor: UIColor(red: 229/255, green: 229/255, blue: 229/255, alpha: 0.2) )
            horizontalDashedLineYAxis +=  verticalGapBWDashedLines
        }
        //Notes box rendering
        if isLandscape {
            boxesYAxis +=  mainFocusBoxHeight + boxesVerticalGapHeight
            boxesXAXis =  templateInfo.screenSize.width*startingXAxis/100
        }
        else{
            boxesYAxis +=  dailyPlanHeight + boxesVerticalGapHeight
        }
        let notesBezierRect = CGRect(x: boxesXAXis, y: boxesYAxis, width: notesBoxWidth, height: notesBoxHeight)
        self.addBezierPathWithRect(rect: notesBezierRect, toContext: context, rectBGColor: bezierBoxesBGColor)
        self.renderTextWith(rect: notesBezierRect, text: "NOTES", MaxFontSize: 10, minFointSize: 7)
       
    }
    private func renderiPadTemplate(context : CGContext){
        let xAxis : CGFloat = templateInfo.screenSize.width*startingXAxis/100
        let yAxis : CGFloat = templateInfo.screenSize.height*startingYAxis/100
        var boxesYAxis : CGFloat = yAxis
        var boxesXAXis : CGFloat = xAxis
        let dailyPlanWidthPerBox = templateInfo.screenSize.width*dailyPlanBeizerPathWidthPercentage/100
        let dailyPlanHeightPerBox = templateInfo.screenSize.height*dailyPlanBeizerPathHeightPercentage/100
        let mainFocusBoxWidth = templateInfo.screenSize.width*mainFocusBeizerPathWidthPercentage/100
        let mainFocusBoxHeight = templateInfo.screenSize.height*mainFocusBeizerPathHeightPercentage/100
        let prioritiesBoxWidth = templateInfo.screenSize.width*prioritiesFocusBeizerPathWidthPercentage/100
        let prioritiesBoxHeight = templateInfo.screenSize.height*prioritiesFocusBeizerPathHeightPercentage/100
        let notesBoxWidth = templateInfo.screenSize.width*NotesBeizerPathWidthPercentage/100
        let notesBoxHeight = templateInfo.screenSize.height*NotesBeizerPathHeightPercentage/100
        let boxesHorizontalGapWidth = templateInfo.screenSize.width*horizontalGapBWBoxes/100
        let boxesVerticalGapHeight = templateInfo.screenSize.height*verticalGapBWBoxes/100
        let topGapForNotesBox = templateInfo.screenSize.height*topGapForNotesBox/100
        let horizontalDashedLineXAxis = templateInfo.screenSize.width*CGFloat(horizontalDashedLineXAxisPercentage)/100
        let horizontalDashedLineWidth = templateInfo.screenSize.width*CGFloat(horizontalDashedLineWidthPercentage)/100
        var horizontalDashedLineYAxis = templateInfo.screenSize.height*CGFloat(horizontalDashedLineYAxisPercentage)/100
        var verticalDashedLineXAxis = templateInfo.screenSize.width*CGFloat(verticalDashedLineXAxisPercentage)/100
        let verticalDashedLineHeight = templateInfo.screenSize.height*CGFloat(verticalDashedLineHeightPercentage)/100
        let verticalDashedLineYAxis = templateInfo.screenSize.height*CGFloat(horizontalDashedLineYAxisPercentage)/100
        let topGapForTimeLineTimings = templateInfo.screenSize.height*CGFloat(topGapForTimeLineTimingsPercentage)/100
        let timeLineTimingWidth = templateInfo.screenSize.width*CGFloat(timeLineTimingsWidthPercentage)/100
        let timeLineTimingHeight = templateInfo.screenSize.height*CGFloat(timeLineTimingsHeightPercentage)/100
        //Day plan boxes rendering
        let bezierRect = CGRect(x: boxesXAXis, y: boxesYAxis, width: dailyPlanWidthPerBox, height: dailyPlanHeightPerBox)
        self.addBezierPathWithRect(rect: bezierRect, toContext: context, rectBGColor: bezierBoxesBGColor)
        self.renderTextWith(rect: bezierRect, text: "DAILY PLAN", MaxFontSize: 11, minFointSize: 8)
    
        // horizontal Time line rendering
        
        var timeLineStringIndex = 0
        for index in 1...35 {
            let bezierlineRect = CGRect(x: horizontalDashedLineXAxis, y: horizontalDashedLineYAxis , width: horizontalDashedLineWidth, height: 1)
            self.addBezierlinePathWith(rect: bezierlineRect, toContext: context, isHorizontalDashedLine: true)
            if index % 2 != 0 && index != 35{ // As we need to add olny 17 time lines so excluding last timeline bezierpath
                let timeLineRect = CGRect(x: horizontalDashedLineXAxis, y: horizontalDashedLineYAxis + topGapForTimeLineTimings, width: timeLineTimingWidth, height: timeLineTimingHeight)
                self.addTimeLineTimingsWith(rect: timeLineRect, withTimeLineTiming: self.timeLineTimeValues[timeLineStringIndex])
                timeLineStringIndex +=  1
            }
            horizontalDashedLineYAxis +=  templateInfo.screenSize.height*CGFloat(verticalGapBWHorizontalDashedLinePercentage)/100
        }
        // Vertical time line rendering
        
        for _ in 1...2 {
            let bezierlineRect = CGRect(x: verticalDashedLineXAxis, y: verticalDashedLineYAxis , width:1 , height: verticalDashedLineHeight)
            self.addBezierlinePathWith(rect: bezierlineRect, toContext: context, isHorizontalDashedLine: false)
            verticalDashedLineXAxis += 3.0
        }
        //main focus box rendering
        boxesYAxis = yAxis
        boxesXAXis +=  dailyPlanWidthPerBox + boxesHorizontalGapWidth
        let focusBezierRect = CGRect(x: boxesXAXis, y: boxesYAxis, width: mainFocusBoxWidth, height: mainFocusBoxHeight)
        self.addBezierPathWithRect(rect: focusBezierRect, toContext: context, rectBGColor: bezierBoxesBGColor)
        self.renderTextWith(rect: focusBezierRect, text: "DAILY MAIN FOCUS", MaxFontSize: 11, minFointSize: 8)
        
        //Proiorities box rendering
        boxesYAxis +=  mainFocusBoxHeight + boxesVerticalGapHeight
        let prioritiesBezierRect = CGRect(x: boxesXAXis, y: boxesYAxis, width: prioritiesBoxWidth, height: prioritiesBoxHeight)
        self.addBezierPathWithRect(rect: prioritiesBezierRect, toContext: context, rectBGColor: bezierBoxesBGColor)
        self.renderTextWith(rect: prioritiesBezierRect, text: "PRIORITIES", MaxFontSize: 11, minFointSize: 8)
        
        //Notes box rendering
        boxesYAxis +=  prioritiesBoxHeight + topGapForNotesBox
        let notesBezierRect = CGRect(x: boxesXAXis, y: boxesYAxis, width: notesBoxWidth, height: notesBoxHeight)
        self.addBezierPathWithRect(rect: notesBezierRect, toContext: context, rectBGColor: bezierBoxesBGColor)
        self.renderTextWith(rect: notesBezierRect, text: "NOTES", MaxFontSize: 11, minFointSize: 8)
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

        //let newFont = getScaledFontSizeFor
        let font = UIFont.montserratFont(for: .bold, with: 10)
        let newFontSize = UIFont.getScaledFontSizeFor(font: font, screenSize: templateInfo.screenSize, minPointSize: 7.0)
        let newFont = UIFont.montserratFont(for: .bold, with: newFontSize)
        let textAttribute: [NSAttributedString.Key : Any] = [.font : newFont,
                                                             NSAttributedString.Key.kern : 0.0,
                                                             .foregroundColor : UIColor(red: 229/255, green: 229/255, blue: 229/255, alpha: 1.0)]
            
        let mainFocusString = NSMutableAttributedString(string: time, attributes: textAttribute)
        let location = CGPoint(x: rect.origin.x, y: rect.origin.y)
        mainFocusString.draw(at: location)
    }
}
extension UIFont {
    class func getScaledFontSizeFor(font : UIFont, screenSize size: CGSize,minPointSize : CGFloat) -> CGFloat{
        let screen = UIScreen.main.bounds;
        let refwidth = min(screen.width,screen.height);
        let scale =  CGFloat(size.width)/refwidth;
        let newPointSize = scale*font.pointSize
        if newPointSize > font.pointSize {
            return font.pointSize
        }
        else if newPointSize < minPointSize {
            return minPointSize
        }else{
            return newPointSize
        }
    }
}
