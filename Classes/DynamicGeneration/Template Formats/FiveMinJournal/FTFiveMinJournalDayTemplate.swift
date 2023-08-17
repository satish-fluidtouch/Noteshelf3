//
//  FTFiveMinJournalDayTemplate.swift
//  Noteshelf
//
//  Created by Ramakrishna on 08/07/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTFiveMinJournalDayTemplate: FTFiveMinJournalTemplateFormat {
   
    
    override func renderTemplate(context: CGContext) {
        super.renderTemplate(context: context)
        if templateInfo.customVariants.selectedDevice.isiPad {
            self.renderiPadTemplate(context: context)
        }
        else {
            self.renderiPhoneTemplate(context: context)
        }
    }
    
    func renderiPadTemplate(context: CGContext){
        //In percentages
        let qustn1WrtngAreaDashedLinesY : CGFloat =  templateInfo.customVariants.isLandscape ? 24.61 : 26.81
        let WrtngAreaDashedLinesX : CGFloat = templateInfo.customVariants.isLandscape ? 4.82 : 5.99
        let qustn2WrtngAreaDashedLinesY : CGFloat = templateInfo.customVariants.isLandscape ? 38.53 : 40.83
        let qustn3WrtngAreaDashedLinesY : CGFloat = templateInfo.customVariants.isLandscape ? 52.30 : 54.86
        let qustn4WrtngAreaDashedLinesY : CGFloat = templateInfo.customVariants.isLandscape ? 70.49 : 73.66
        let qustn5WrtngAreaDashedLinesY : CGFloat = templateInfo.customVariants.isLandscape ? 88.50 : 87.69
        let dashedLinesVerticalGapY : CGFloat = templateInfo.customVariants.isLandscape ? 4.15 : 3.24
        let dashedLinesWidth : CGFloat = templateInfo.customVariants.isLandscape ? 90.34 : 88.00
        
        let dashedLinesWidthValue = templateInfo.screenSize.width*CGFloat(dashedLinesWidth)/100
        let dashedLinesVerticalGapValue = templateInfo.screenSize.height*CGFloat(dashedLinesVerticalGapY)/100
        let dashedLiensXAxis = templateInfo.screenSize.width*CGFloat(WrtngAreaDashedLinesX)/100
        
        
        let bottomBGColorY = templateInfo.customVariants.isLandscape ? 61.03 : 65.83
        let bottomBGHeight = templateInfo.customVariants.isLandscape ? 38.96 : 34.16
        
        //bottomBG color rendering
        
        let bottomBGColorYValue = templateInfo.screenSize.height*CGFloat(bottomBGColorY)/100
        let bottomBGHeightValue = templateInfo.screenSize.height*CGFloat(bottomBGHeight)/100
        
        let bgRect = CGRect(x: 0, y: bottomBGColorYValue, width: templateInfo.screenSize.width, height: bottomBGHeightValue)
        context.setFillColor(self.bezierBoxesBGColor.cgColor)
        context.fill(bgRect)
        
        //qustn1 dashed lines rendering
        
        var qustn1WrtngAreaYAxis = templateInfo.screenSize.height*CGFloat(qustn1WrtngAreaDashedLinesY)/100
        let numberOfquestion1Lines : Int = templateInfo.customVariants.isLandscape ? 2 : 3
        for _ in 1...numberOfquestion1Lines {
            let bezierlineRect = CGRect(x: dashedLiensXAxis, y: qustn1WrtngAreaYAxis , width:dashedLinesWidthValue , height: 1)
            self.addBezierDashedlinePathWith(rect: bezierlineRect, toContext: context, withColor: UIColor(red: 120/255, green: 120/255, blue: 123/255, alpha: 1.0))
            qustn1WrtngAreaYAxis += dashedLinesVerticalGapValue
        }
        
        //qustn2 for dashed lines rendering
        
        var qustn2WrtngAreaYAxis = templateInfo.screenSize.height*CGFloat(qustn2WrtngAreaDashedLinesY)/100
        let numberOfquestion2WrtngAreaLines : Int = templateInfo.customVariants.isLandscape ? 2 : 3
        for _ in 1...numberOfquestion2WrtngAreaLines {
            let bezierlineRect = CGRect(x: dashedLiensXAxis, y:qustn2WrtngAreaYAxis , width:dashedLinesWidthValue , height: 1)
            self.addBezierDashedlinePathWith(rect: bezierlineRect, toContext: context, withColor: UIColor(red: 120/255, green: 120/255, blue: 123/255, alpha: 1.0))
            qustn2WrtngAreaYAxis += dashedLinesVerticalGapValue
        }
        //qustn3 dashed lines rendering
        
        var qustn3WrtngAreaYAxis = templateInfo.screenSize.height*CGFloat(qustn3WrtngAreaDashedLinesY)/100
        let numberOfquestion3WrtngAreaLines : Int = templateInfo.customVariants.isLandscape ? 2 : 3
        
        for _ in 1...numberOfquestion3WrtngAreaLines {
            let bezierlineRect = CGRect(x: dashedLiensXAxis, y: qustn3WrtngAreaYAxis , width:dashedLinesWidthValue , height: 1)
            self.addBezierDashedlinePathWith(rect: bezierlineRect, toContext: context, withColor: UIColor(red: 120/255, green: 120/255, blue: 123/255, alpha: 1.0))
            qustn3WrtngAreaYAxis += dashedLinesVerticalGapValue
        }
        //qustn4 dashed lines rendering
        
        var qustn4WrtngAreaYAxis = templateInfo.screenSize.height*CGFloat(qustn4WrtngAreaDashedLinesY)/100
        
        for _ in 1...3 {
            let bezierlineRect = CGRect(x: dashedLiensXAxis, y: qustn4WrtngAreaYAxis , width:dashedLinesWidthValue , height: 1)
            self.addBezierDashedlinePathWith(rect: bezierlineRect, toContext: context, withColor: UIColor(red: 120/255, green: 120/255, blue: 123/255, alpha: 1.0))
            qustn4WrtngAreaYAxis += dashedLinesVerticalGapValue
        }
        
        //qustn5 dashed lines rendering
        var qustn5WrtngAreaYAxis = templateInfo.screenSize.height*CGFloat(qustn5WrtngAreaDashedLinesY)/100
        let numberOfqustn5WrtngAreaLines : Int = templateInfo.customVariants.isLandscape ? 2 : 3
        for _ in 1...numberOfqustn5WrtngAreaLines {
            let bezierlineRect = CGRect(x: dashedLiensXAxis, y: qustn5WrtngAreaYAxis , width:dashedLinesWidthValue , height: 1)
            self.addBezierDashedlinePathWith(rect: bezierlineRect, toContext: context, withColor: UIColor(red: 120/255, green: 120/255, blue: 123/255, alpha: 1.0))
            qustn5WrtngAreaYAxis += dashedLinesVerticalGapValue
        }
        
    }
    func renderiPhoneTemplate(context: CGContext){
        let isLandscape = templateInfo.customVariants.isLandscape
        let qustn1WrtngAreaDashedLinesY : CGFloat = isLandscape ? 29.76 : 26.24
        var wrtngAreaDashedLinesX : CGFloat =  isLandscape ? 2.99 : 6.4
        let qustn2WrtngAreaDashedLinesY : CGFloat =  isLandscape ? 52.87 : 41.57
        let qustn3WrtngAreaDashedLinesY : CGFloat =  isLandscape ?  76.70 : 56.90
        let qustn4WrtngAreaDashedLiensY : CGFloat =  isLandscape ? 29.76 :  74.72
        let qustn5WrtngAreaDashedLinesY : CGFloat = isLandscape ? 52.87 : 90.05
        let dashedLinesVerticalGapY : CGFloat = isLandscape ? 9.06 : 4.14
        let dashedLinesWidth : CGFloat = isLandscape ? 45.57 :  86.96
        
        let dashedLinesWidthValue = templateInfo.screenSize.width*CGFloat(dashedLinesWidth)/100
        let dashedLinesVerticalGapValue = templateInfo.screenSize.height*CGFloat(dashedLinesVerticalGapY)/100
        var dashedLiensXAxis = templateInfo.screenSize.width*CGFloat(wrtngAreaDashedLinesX)/100
        
        
        let themeBGColorY = isLandscape ? 0 : 65.60
        let themeBGColorHeight = isLandscape ? 100 : 34.39
        let themeBGColorX = isLandscape ? 50.07 : 0.0
        let themeBGColorWidth =  isLandscape ? 49.92 : 100
        
        
        //bottomBG color rendering
        
        let themeBGColorYValue = templateInfo.screenSize.height*CGFloat(themeBGColorY)/100
        let themeBGHeightValue = templateInfo.screenSize.height*CGFloat(themeBGColorHeight)/100
        let themeBGColorXValue = templateInfo.screenSize.width*CGFloat(themeBGColorX)/100
        let themeBGColorWidthValue = templateInfo.screenSize.width*CGFloat(themeBGColorWidth)/100
        
        
        let bgRect = CGRect(x: themeBGColorXValue, y: themeBGColorYValue, width: themeBGColorWidthValue, height: themeBGHeightValue)
        context.setFillColor(UIColor(hexString: "#E1E9E8", alpha: 1.0).cgColor)
        context.fill(bgRect)
        
        //question1 dashed lines rendering
        
        var qustn1WrtngAreaYAxis = templateInfo.screenSize.height*CGFloat(qustn1WrtngAreaDashedLinesY)/100
        for _ in 1...2 {
            let bezierlineRect = CGRect(x: dashedLiensXAxis, y: qustn1WrtngAreaYAxis , width:dashedLinesWidthValue , height: 1)
            self.addBezierDashedlinePathWith(rect: bezierlineRect, toContext: context, withColor: UIColor(red: 120/255, green: 120/255, blue: 123/255, alpha: 1.0))
            qustn1WrtngAreaYAxis += dashedLinesVerticalGapValue
        }
        
        //question2 dashed lines rendering
        
        var qustn2WrtngAreaYAxis = templateInfo.screenSize.height*CGFloat(qustn2WrtngAreaDashedLinesY)/100
        
        for _ in 1...2 {
            let bezierlineRect = CGRect(x: dashedLiensXAxis, y:qustn2WrtngAreaYAxis , width:dashedLinesWidthValue , height: 1)
            self.addBezierDashedlinePathWith(rect: bezierlineRect, toContext: context, withColor: UIColor(red: 120/255, green: 120/255, blue: 123/255, alpha: 1.0))
            qustn2WrtngAreaYAxis += dashedLinesVerticalGapValue
        }
        //question3 dashed lines rendering
        
        var qustn3WrtngAreaYAxis = templateInfo.screenSize.height*CGFloat(qustn3WrtngAreaDashedLinesY)/100
        
        for _ in 1...2 {
            let bezierlineRect = CGRect(x: dashedLiensXAxis, y: qustn3WrtngAreaYAxis , width:dashedLinesWidthValue , height: 1)
            self.addBezierDashedlinePathWith(rect: bezierlineRect, toContext: context, withColor: UIColor(red: 120/255, green: 120/255, blue: 123/255, alpha: 1.0))
            qustn3WrtngAreaYAxis += dashedLinesVerticalGapValue
        }
        //question4 for dashed lines rendering
        if isLandscape {
            wrtngAreaDashedLinesX = 52.19
            dashedLiensXAxis = templateInfo.screenSize.width*CGFloat(wrtngAreaDashedLinesX)/100
        }
        
        var qustn4WrtngAreaYAxis = templateInfo.screenSize.height*CGFloat(qustn4WrtngAreaDashedLiensY)/100
        let numberOfquestion4WrtngAreaLines : Int = 2
        
        for _ in 1...numberOfquestion4WrtngAreaLines {
            let bezierlineRect = CGRect(x: dashedLiensXAxis, y: qustn4WrtngAreaYAxis , width:dashedLinesWidthValue , height: 1)
            self.addBezierDashedlinePathWith(rect: bezierlineRect, toContext: context, withColor: UIColor(red: 120/255, green: 120/255, blue: 123/255, alpha: 1.0))
            qustn4WrtngAreaYAxis += dashedLinesVerticalGapValue
        }
        
        if isLandscape {
            //question5 dashed box rendering
            let qustn5WrtngAreaYAxis = templateInfo.screenSize.height*CGFloat(qustn5WrtngAreaDashedLinesY)/100
            let qustn5WrtngAreaBoxHeight = templateInfo.screenSize.height*CGFloat(34.13)/100
            let boxRect = CGRect(x: dashedLiensXAxis, y: qustn5WrtngAreaYAxis, width: dashedLinesWidthValue, height: qustn5WrtngAreaBoxHeight)
            let  bezierLinePath = UIBezierPath(rect: boxRect)
            let  dashes: [ CGFloat ] = [ 4,3 ]
            bezierLinePath.setLineDash(dashes, count: dashes.count, phase: 0.0)
            bezierLinePath.lineWidth = 1.0
            bezierLinePath.lineCapStyle = .butt
            UIColor(red: 120/255, green: 120/255, blue: 123/255, alpha: 1.0).setStroke()
            context.addPath(bezierLinePath.cgPath)
            bezierLinePath.stroke()
            
        }else{
            //question5 dashed lines rendering
            let numberOfqustn5WrtngAreaLines : Int = templateInfo.customVariants.isLandscape ? 3 : 2
            var qustn5WrtngAreaYAxis = templateInfo.screenSize.height*CGFloat(qustn5WrtngAreaDashedLinesY)/100
            
            for _ in 1...numberOfqustn5WrtngAreaLines {
                let bezierlineRect = CGRect(x: dashedLiensXAxis, y: qustn5WrtngAreaYAxis , width:dashedLinesWidthValue , height: 1)
                self.addBezierDashedlinePathWith(rect: bezierlineRect, toContext: context, withColor: UIColor(red: 120/255, green: 120/255, blue: 123/255, alpha: 1.0))
                qustn5WrtngAreaYAxis += dashedLinesVerticalGapValue
            }
        }
    }
}
