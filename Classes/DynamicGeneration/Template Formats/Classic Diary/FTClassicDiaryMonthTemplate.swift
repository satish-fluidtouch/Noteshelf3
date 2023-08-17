//
//  FTClassicDiaryMonthTemplate.swift
//  Noteshelf
//
//  Created by Ramakrishna on 04/08/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import PDFKit
class FTClassicDiaryMonthTemplate : FTClassicDiaryTemplateFormat {
    
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
        //In percentages
        let isLandscaped = templateInfo.customVariants.isLandscape
        let writingAreaX : CGFloat = isLandscaped ? 65.55 : 4.79
        let writingAreaY : CGFloat = isLandscaped ? 9.87 : 68.98
        let verticalGapBWWritingLines : CGFloat = isLandscaped ? 4.67 : 3.43
        var writingAreaBottom : CGFloat = isLandscaped ? 5.19 : 3.53
        if templateInfo.customVariants.selectedDevice.identifier == "standard4" && isLandscaped
        {
            writingAreaBottom = 9.87
        }
        let writingAreaHeight : CGFloat = 100 - writingAreaY - writingAreaBottom
        let writingLineWidth : CGFloat =  isLandscaped ? 30.84 : 90.40
        
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
    private func renderiPhoneTemplate(context:CGContext){
        //In percentages
        let isLandscaped = templateInfo.customVariants.isLandscape
        let writingAreaX : CGFloat = isLandscaped ? 65.55 : 5.33
        let writingAreaY : CGFloat = isLandscaped ? 9.87 : 53.31
        let verticalGapBWWritingLines : CGFloat = isLandscaped ? 4.67 : 4.55
        let writingAreaBottom : CGFloat = isLandscaped ? 5.19 : 5.66
        let writingAreaHeight : CGFloat = 100 - writingAreaY - writingAreaBottom
        let writingLineWidth : CGFloat =  isLandscaped ? 30.84 : 89.33
        
        //Actaul values
        let writingAreaXValue = templateInfo.screenSize.width*writingAreaX/100
        var writingAreaYValue = templateInfo.screenSize.height*writingAreaY/100
        let verticalGapBWLinesValue = templateInfo.screenSize.height*verticalGapBWWritingLines/100
        let writingAreaHeightValue = templateInfo.screenSize.height*writingAreaHeight/100
        let numberOfWritingAreaLines = (Int)(writingAreaHeightValue/verticalGapBWLinesValue) + 1
        let writingLineWidthValue = templateInfo.screenSize.width*writingLineWidth/100
        for _ in 1...numberOfWritingAreaLines {
            let bezierlineRect = CGRect(x: writingAreaXValue, y: writingAreaYValue , width:writingLineWidthValue , height: 1)
            self.addBezierlinePathWith(rect: bezierlineRect, toContext: context, withColor: UIColor(hexString: "#D4D4CB", alpha: 1.0))
            writingAreaYValue += verticalGapBWLinesValue
        }
    }
}
