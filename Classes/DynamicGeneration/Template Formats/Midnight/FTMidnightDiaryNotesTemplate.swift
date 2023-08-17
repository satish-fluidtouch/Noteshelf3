//
//  FTMidnightNotesTemplate.swift
//  Noteshelf
//
//  Created by Ramakrishna on 13/05/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTMidnightDiaryNotesTemplate : FTMidnightDiaryTemplateFormat {
    
    override func renderTemplate(context: CGContext) {
        super.renderTemplate(context: context)
        if templateInfo.customVariants.selectedDevice.isiPad{
            self.renderiPadTemplate(context: context)
        }
        else {
            self.renderiPhoneTemplate(context: context)
        }
    }
    private func renderiPhoneTemplate(context : CGContext){
        let isLandscaped = templateInfo.customVariants.isLandscape
        let bezierBoxWidthPercentage : CGFloat = isLandscaped ? 94.0 : 89.33
        let bezierBoxHeightPercentage : CGFloat = isLandscaped ? 71.60 : 84.80
        let boxXPercentage : CGFloat = isLandscaped ? 2.99 : 5.33
        let boxYPercentage : CGFloat = isLandscaped ? 20.24 : 10.35
        
        //notes bezier box
        let bezierBoxWidth = templateInfo.screenSize.width*bezierBoxWidthPercentage/100
        let bezierBoxHeight = templateInfo.screenSize.height*bezierBoxHeightPercentage/100
        let boxXValue = templateInfo.screenSize.width*boxXPercentage/100
        let boxYValue = templateInfo.screenSize.height*boxYPercentage/100
        
        let bezierBoxRect = CGRect(x: boxXValue, y: boxYValue, width: bezierBoxWidth, height: bezierBoxHeight)
        self.addBezierPathWithRect(rect: bezierBoxRect, toContext: context, rectBGColor: bezierBoxesBGColor)
    }
    private func renderiPadTemplate(context : CGContext){
        // values are in terms of percentages
        let isLandscaped = templateInfo.customVariants.isLandscape
        let bezierBoxWidth : CGFloat = isLandscaped ? 92.80 : 90.28
        let bezierBoxHeight : CGFloat = isLandscaped ? 78.96 : 84.35
        let boxX : CGFloat = isLandscaped ? 3.59 : 4.79
        let boxY : CGFloat = isLandscaped ? 15.84 : 11.83
        let bezierlinepathXWRTBox : CGFloat = isLandscaped ? 2.06 : 2.75
        let bezierlinepathYWRTBox : CGFloat = isLandscaped ? 5.84 :4.29
        let gapBWBezierlinepaths : CGFloat = isLandscaped ? 4.93 : 3.53
        let bezierlinepathWidth : CGFloat = isLandscaped ? 88.66 : 84.65
        let dashedLineBottom : CGFloat = isLandscaped ? 4.02 : 2.38
        // Bezier box BG
        let bezierBoxWidthWRTTemplateWidth = templateInfo.screenSize.width*bezierBoxWidth/100
        let bezierBoxHeightWRTTemplateHeight = templateInfo.screenSize.height*bezierBoxHeight/100
        let boxXValue = templateInfo.screenSize.width*boxX/100
        let boxYValue = templateInfo.screenSize.height*boxY/100
        
        let bezierBoxRect = CGRect(x: boxXValue, y: boxYValue, width: bezierBoxWidthWRTTemplateWidth, height: bezierBoxHeightWRTTemplateHeight)
        self.addBezierPathWithRect(rect: bezierBoxRect, toContext: context, rectBGColor: bezierBoxesBGColor)
        
        // Bezier line path
        
        let bezierLineXAxis = (templateInfo.screenSize.width*boxX/100) +  (templateInfo.screenSize.width*bezierlinepathXWRTBox/100)
        var bezierLineYAxis = (templateInfo.screenSize.height*boxY/100) +  (templateInfo.screenSize.height*bezierlinepathYWRTBox/100)
        let bezierLineWidth = templateInfo.screenSize.width*bezierlinepathWidth/100
        let verticalGapBWbezierlines = templateInfo.screenSize.height*gapBWBezierlinepaths/100
        let bezierlinesBottom = templateInfo.screenSize.height*dashedLineBottom/100
        
        let numberOfDashedLines = Int((bezierBoxHeightWRTTemplateHeight - bezierlinesBottom)/verticalGapBWbezierlines)
        for _ in 1...numberOfDashedLines
        {
            let bezierlineRect = CGRect(x: bezierLineXAxis, y: bezierLineYAxis, width: bezierLineWidth, height: 1)
            self.addBezierDashedlinePathWith(rect: bezierlineRect, toContext: context, withColor: UIColor(red: 229/255, green: 229/255, blue: 229/255, alpha: 0.2))
            bezierLineYAxis +=  verticalGapBWbezierlines
        }
    }
}
