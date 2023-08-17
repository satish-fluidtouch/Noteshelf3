//
//  FTModernDiaryDayTemplate.swift
//  Noteshelf
//
//  Created by Narayana on 04/10/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTModernDiaryDayTemplate: FTModernDiaryTemplateFormat {
    
    override func renderTemplate(context: CGContext) {
        super.renderTemplate(context: context)
        let isIpad = self.templateInfo.customVariants.selectedDevice.isiPad
        // Draw horizantal lines
        let isLandScape = self.templateInfo.customVariants.isLandscape
        let lineXposPercentage: CGFloat = isIpad ? (isLandScape ? 3.77 : 5.03) : 5.33
        let lineYposPercentage: CGFloat = isIpad ? (isLandScape ? 22.2 : 18.32) : 18.37
        let bottomOffsetPercentage: CGFloat = isIpad ? (isLandScape ? 5.71 : 4.00) : 4.97
        let widthPercentage: CGFloat = isIpad ? (isLandScape ? 92.62 : 89.92) : 89.06
        let verticalGapPercentage: CGFloat = isIpad ? (isLandScape ? 4.80 : 3.53) : 5.11
        
        let lineXpos: CGFloat = self.templateInfo.screenSize.width*lineXposPercentage/100
        var lineYpos: CGFloat = self.templateInfo.screenSize.height*lineYposPercentage/100
        var bottomOffset: CGFloat = self.templateInfo.screenSize.height*bottomOffsetPercentage/100
        if templateInfo.customVariants.selectedDevice.identifier == "standard4" {
            let extraOffset: CGFloat = 10.0
            bottomOffset += extraOffset
        }
        if UIDevice.current.isPhone() && ((self.templateInfo.customVariants.selectedDevice.identifier == "standard4") || (self.templateInfo.customVariants.selectedDevice.identifier == "standard1" && !isLandScape)) {
            lineYpos += 20.0
        }
        
        let lineWidth: CGFloat = self.templateInfo.screenSize.width*widthPercentage/100
        let verticalGap: CGFloat = self.templateInfo.screenSize.height*verticalGapPercentage/100
        
        while lineYpos < (self.templateInfo.screenSize.height - bottomOffset) {
            let bezierlineRect = CGRect(x: lineXpos, y: lineYpos, width: lineWidth, height: 1)
            self.addHorizantalBezierLine(rect: bezierlineRect, toContext: context, withColor: UIColor(hexString: "A2A2A2"))
            lineYpos +=  verticalGap
        }
    }

}
