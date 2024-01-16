//
//  FTClassicDiaryDayTemplate.swift
//  Noteshelf
//
//  Created by Ramakrishna on 17/08/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
class FTClassicDiaryDayTemplate : FTClassicDiaryTemplateFormat {
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
        let writingAreaX : CGFloat = isLandscaped ? 3.59 : 4.79
        var writingAreaY : CGFloat = isLandscaped ? 21.29 : 16.03
        let verticalGapBWWritingLines : CGFloat = isLandscaped ? 4.54 : 3.33
        var writingAreaBottom : CGFloat = isLandscaped ? 5.97 : 3.81
        if templateInfo.customVariants.selectedDevice.identifier == "standard4" && isLandscaped
        {
            writingAreaY = 21.77
            writingAreaBottom = 6.49
        }
        let writingAreaHeight : CGFloat = 100 - writingAreaY - writingAreaBottom
        let writingLineWidth : CGFloat = isLandscaped ? 92.80 : 90.40
        
        
        //Actaul values
        let writingAreaXValue = templateInfo.screenSize.width*writingAreaX/100
        var writingAreaYValue = templateInfo.screenSize.height*writingAreaY/100
        let verticalGapBWLinesValue = templateInfo.screenSize.height*verticalGapBWWritingLines/100
        let writingAreaHeightValue = templateInfo.screenSize.height*writingAreaHeight/100
        let numberOfWritingAreaLines = (Int)(writingAreaHeightValue/verticalGapBWLinesValue) + 1
        let writingLineWidthValue = templateInfo.screenSize.width*writingLineWidth/100
        let bezierLineTintColor = UIColor(red: 212/255, green: 212/255, blue: 203/255, alpha: 1.0)
        let headingBezieLineTintColot = UIColor(hexString: "#64645F")

        for index in 1...numberOfWritingAreaLines {
            let bezierlineRect = CGRect(x: writingAreaXValue, y: writingAreaYValue , width:writingLineWidthValue , height: 1)
            self.addBezierlinePathWith(rect: bezierlineRect, toContext: context, withColor : index == 1 ? headingBezieLineTintColot : bezierLineTintColor)
            writingAreaYValue += verticalGapBWLinesValue
        }
    }
    private func renderiPhoneTemplate(context:CGContext){

        let writingAreaX : CGFloat = 5.6
        let writingAreaY : CGFloat = 18.78
        let verticalGapBWWritingLines : CGFloat = 4.69
        let writingAreaBottom : CGFloat = 4.83
        let writingAreaHeight : CGFloat = 100 - writingAreaY - writingAreaBottom
        let writingLineWidth : CGFloat = 88.8
        
        //Actaul values
        let writingAreaXValue = templateInfo.screenSize.width*writingAreaX/100
        var writingAreaYValue = templateInfo.screenSize.height*writingAreaY/100
        let verticalGapBWLinesValue = templateInfo.screenSize.height*verticalGapBWWritingLines/100
        let writingAreaHeightValue = templateInfo.screenSize.height*writingAreaHeight/100
        let numberOfWritingAreaLines = (Int)(writingAreaHeightValue/verticalGapBWLinesValue) + 1
        let writingLineWidthValue = templateInfo.screenSize.width*writingLineWidth/100
        for _ in 1...numberOfWritingAreaLines {
            let bezierlineRect = CGRect(x: writingAreaXValue, y: writingAreaYValue , width:writingLineWidthValue , height: 1)
            self.addBezierlinePathWith(rect: bezierlineRect, toContext: context, withColor: UIColor(red: 212/255, green: 212/255, blue: 203/255, alpha: 1.0))
            writingAreaYValue += verticalGapBWLinesValue
        }
    }
}
