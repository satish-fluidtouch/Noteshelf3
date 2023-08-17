//
//  FTMidnightBrainDumpTemplate.swift
//  Beizerpaths
//
//  Created by Ramakrishna on 07/05/21.
//

import Foundation
import PDFKit

class FTMidnightDiaryPrioritiesTemplate : FTMidnightDiaryTemplateFormat {
    
    
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
        
        let boxWidthPercentage : CGFloat = isLandscaped ? 94.0 : 89.33
        let boxHeightPercentage : CGFloat = isLandscaped ? 71.60 : 84.80
        let boxXAxisPercentage : CGFloat = isLandscaped ? 2.99 : 5.33
        let boxYAxisPercentage : CGFloat = isLandscaped ? 20.24 : 10.35
        let horizontalDashedLineXAxisPercentage : CGFloat = isLandscaped ? 3.37 : 3.21 // With respect to box
        let horizontalDashedLineYAxisPercentage : CGFloat = isLandscaped ? 9.21 : 4.27
        let horizontalDashedLineWidthPercentage : CGFloat = isLandscaped ? 87.24 : 82.91
        let verticalGapBWDashedLinesPercentage : CGFloat = isLandscaped ?9.06 : 3.30
        let dashedlineBottomPercentage : CGFloat = isLandscaped ? 7.70 : 3.30
        
        let boxWidth = templateInfo.screenSize.width*boxWidthPercentage/100
        let boxHeight = templateInfo.screenSize.height*boxHeightPercentage/100
        let boxX = templateInfo.screenSize.width*boxXAxisPercentage/100
        let boxY = templateInfo.screenSize.height*boxYAxisPercentage/100
        let horizontalDashedLineX = boxX + templateInfo.screenSize.width*horizontalDashedLineXAxisPercentage/100
        var horizontalDashedLineY = boxY + templateInfo.screenSize.height*horizontalDashedLineYAxisPercentage/100
        let horizontalDashedLineWidth = templateInfo.screenSize.width*horizontalDashedLineWidthPercentage/100
        let verticalGapBWDashedLines = templateInfo.screenSize.height*verticalGapBWDashedLinesPercentage/100
        let dashedlinesBottom = templateInfo.screenSize.height*dashedlineBottomPercentage/100
    
        //Day plan boxes rendering
        let bezierRect = CGRect(x: boxX, y: boxY, width: boxWidth, height: boxHeight)
        self.addBezierPathWithRect(rect: bezierRect, toContext: context, rectBGColor: bezierBoxesBGColor)
        
        //Dashed lines inside day plan box
        let numberOfDashedLines =  Int((boxHeight - dashedlinesBottom)/verticalGapBWDashedLines)
        for _ in 1...numberOfDashedLines
        {
            let bezierlineRect = CGRect(x: horizontalDashedLineX, y: horizontalDashedLineY, width: horizontalDashedLineWidth, height: 1)
            self.addBezierDashedlinePathWith(rect: bezierlineRect, toContext: context, withColor: UIColor(red: 229/255, green: 229/255, blue: 229/255, alpha: 0.2))
            horizontalDashedLineY +=  verticalGapBWDashedLines
        }
        
    }
    private func renderiPadTemplate(context : CGContext){
        let isLandscaped = templateInfo.customVariants.isLandscape
        let boxWidthPercentage : CGFloat =  isLandscaped ? 92.80 : 90.40
        let boxHeightPercentage : CGFloat = isLandscaped ? 78.96 : 84.35
        let boxXAxisPercentage : CGFloat = isLandscaped ? 3.59 : 5.15
        let boxYAxisPercentage : CGFloat = isLandscaped ? 15.71 : 11.73
        let circleBezierPathWidthPercentage : CGFloat = isLandscaped ? 2.15 :  2.87
        let circleBezierPathYAxisPercentage : CGFloat =  isLandscaped ? 18.57 : 13.83
        let circleBezierPathXAxisPercentage : CGFloat = isLandscaped ? 5.48 :  7.55
        let circleBezierPathSequenceTopGapPercentage : CGFloat = isLandscaped ? 1.94 : 1.24
        let bezierLineWidthPercentage : CGFloat =  isLandscaped ? 85.43 : 80.57
        let bezierLineXAxisPercentage : CGFloat = isLandscaped ? 8.54: 11.63
        let bezierLineSequenceTopGapPercentage : CGFloat = isLandscaped ? 4.93 : 3.53      //5.06 : 3.53
        
        //BG BezierPath
        let boxXAxis = templateInfo.screenSize.width*boxXAxisPercentage/100
        let boxYAxis = templateInfo.screenSize.height*boxYAxisPercentage/100
        let boxWidth = templateInfo.screenSize.width*boxWidthPercentage/100
        let boxHeight = templateInfo.screenSize.height*boxHeightPercentage/100
        
        let boxRect = CGRect(x:boxXAxis , y: boxYAxis, width: boxWidth, height: boxHeight)
        self.addBezierPathWithRect(rect: boxRect, toContext: context, rectBGColor: bezierBoxesBGColor)
        
        //circle BezierPaths
        let circleBezierPathXAxis = templateInfo.screenSize.width*circleBezierPathXAxisPercentage/100
        var circleBezierPathYAxis = templateInfo.screenSize.height*circleBezierPathYAxisPercentage/100
        let circleBezierPathWidth = templateInfo.screenSize.width*circleBezierPathWidthPercentage/100
        let circleBezierSequenceGap = templateInfo.screenSize.height*circleBezierPathSequenceTopGapPercentage/100
        
        // For horizontal dashed line
        let dashedLineXAxis = templateInfo.screenSize.width*bezierLineXAxisPercentage/100
        let dashedLineWidth = templateInfo.screenSize.width*bezierLineWidthPercentage/100
        let dashedLineSequenceGap = templateInfo.screenSize.height*bezierLineSequenceTopGapPercentage/100
        let circleBezierYWRTBGBezier = templateInfo.screenSize.height*2.85/100
        
        let numberOfCircles = Int((boxHeight)/circleBezierYWRTBGBezier)
        
        for _ in 1...numberOfCircles
        {
            if circleBezierPathYAxis > (boxYAxis + boxHeight - dashedLineSequenceGap){
                break
            }
            let circlePathRect = CGRect(x: circleBezierPathXAxis, y: circleBezierPathYAxis, width: circleBezierPathWidth, height: circleBezierPathWidth)
            self.addCircleBezierPathWith(rect: circlePathRect, toContext: context)
            
            let dashedLineYAxis = circleBezierPathYAxis + circlePathRect.height
            
            circleBezierPathYAxis +=  circlePathRect.height +  circleBezierSequenceGap
            let bezierDashedLineRect = CGRect(x: dashedLineXAxis, y: dashedLineYAxis, width: dashedLineWidth, height: 1)
            self.addBezierDashedlinePathWith(rect: bezierDashedLineRect, toContext: context, withColor: UIColor(red: 229/255, green: 229/255, blue: 229/255, alpha: 0.2))
        }
    }
    func addCircleBezierPathWith(rect:CGRect, toContext context:CGContext){
        let circlePath = UIBezierPath(roundedRect: rect, cornerRadius: rect.width*0.5)
        circlePath.lineWidth = 1
        context.saveGState()
        context.addPath(circlePath.cgPath)
        context.translateBy(x: 0, y: templateInfo.screenSize.height)
        context.scaleBy(x: 1, y: -1)
        context.setStrokeColor(red: 229/255, green: 229/255, blue: 229/255, alpha: 0.2)
        context.strokePath()
        context.restoreGState()
    }
}
