//
//  FTModernDiaryMonthTemplate.swift
//  Noteshelf
//
//  Created by Narayana on 30/09/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTModernDiaryMonthTemplate : FTModernDiaryTemplateFormat {

    override func renderTemplate(context: CGContext) {
        super.renderTemplate(context: context)
        if templateInfo.customVariants.selectedDevice.isiPad {
            self.renderiPadTemplate(context: context)
        }
        else {
            self.renderiPhoneTemplate(context: context)
        }
    }

    private func renderiPadTemplate(context : CGContext) {
        let isLandscaped = templateInfo.customVariants.isLandscape

        // Outer Box rendering
        let outerBoxXPercentage: CGFloat = isLandscaped ? 42.08 : 17.14
        let outerBoxYPercentage: CGFloat = isLandscaped ? 29.37 : 42.55
        let outerBoxWidthPecentage: CGFloat = isLandscaped ? 54.24 : 76.27
        let outerBoxHeightPecentage: CGFloat = isLandscaped ? 48.42 : 53.62
        
        let outerBoxX : CGFloat = templateInfo.screenSize.width*outerBoxXPercentage/100
        var outerBoxY : CGFloat = templateInfo.screenSize.height*outerBoxYPercentage/100
        if templateInfo.customVariants.selectedDevice.identifier == "standard4" && !isLandscaped {
            let extraOffset: CGFloat = 10.0
            outerBoxY -= extraOffset
        }
        
        let outerBoxWidth = templateInfo.screenSize.width*outerBoxWidthPecentage/100
        let outerBoxHeight = templateInfo.screenSize.height*outerBoxHeightPecentage/100

        let bezierRect = CGRect(x: outerBoxX, y: outerBoxY, width: outerBoxWidth, height: outerBoxHeight)
        self.addBezierBoxWithBorder(rect: bezierRect, toContext: context, rectBGColor: bezierBoxesBGColor, borderColor: UIColor(hexString: "A2A2A2"), cornerRadius: 0.0)
        
        let horizantalLineXPercentage: CGFloat = outerBoxXPercentage
        let boxHeightPercentage: CGFloat = isLandscaped ? 8.07 : 8.93
        let horizantalLineYPercentage: CGFloat = outerBoxYPercentage + boxHeightPercentage
        let horizantalLineWidthPercentage: CGFloat = outerBoxWidthPecentage

        let horizontalLineX: CGFloat = templateInfo.screenSize.width*horizantalLineXPercentage/100.0
        var horizontalLineY: CGFloat = templateInfo.screenSize.height*horizantalLineYPercentage/100.0
        if templateInfo.customVariants.selectedDevice.identifier == "standard4" && !isLandscaped {
            let extraOffset: CGFloat = 10.0
            horizontalLineY -= extraOffset
        }

        let horizontalLineWidth: CGFloat = templateInfo.screenSize.width*horizantalLineWidthPercentage/100.0
        let verticalGapBWHorizantalLines: CGFloat = templateInfo.screenSize.height*boxHeightPercentage/100.0

        // Drawing horizantal lines
        let numberOfHorizantalLines =  5
        for _ in 1...numberOfHorizantalLines
        {
            let bezierlineRect = CGRect(x: horizontalLineX, y: horizontalLineY, width: horizontalLineWidth, height: 1)
            self.addHorizantalBezierLine(rect: bezierlineRect, toContext: context, withColor: UIColor(hexString: "A2A2A2"))
            horizontalLineY +=  verticalGapBWHorizantalLines
        }

        // Drawing vertical lines
        let boxWidthPercentage: CGFloat = isLandscaped ? 7.74 : 10.89
        let verticalLineXPercentage: CGFloat = outerBoxXPercentage + boxWidthPercentage
        var verticalLineX: CGFloat = templateInfo.screenSize.width*verticalLineXPercentage/100.0
        let verticalLineYPercentage: CGFloat = outerBoxYPercentage
        var verticalLineY = templateInfo.screenSize.height*verticalLineYPercentage/100.0
        if templateInfo.customVariants.selectedDevice.identifier == "standard4" && !isLandscaped {
            let extraOffset: CGFloat = 10.0
            verticalLineY -= extraOffset
        }

        let verticalLineHeightPercentage: CGFloat = outerBoxHeightPecentage
        let verticalLineHeight: CGFloat = templateInfo.screenSize.height*verticalLineHeightPercentage/100.0
        let horizantalGapBWVerticalLines: CGFloat = templateInfo.screenSize.width*boxWidthPercentage/100.0

        let numberOfVerticalLines = 6
        for _ in 1...numberOfVerticalLines {
            let bezierlineRect = CGRect(x: verticalLineX, y: verticalLineY, width: 1, height: verticalLineHeight)
            self.addVerticalBezierLine(rect: bezierlineRect, toContext: context, withColor: UIColor(hexString: "A2A2A2"))
            verticalLineX +=  horizantalGapBWVerticalLines
        }

    }

    private func renderiPhoneTemplate(context : CGContext) {
        // Outer Box rendering
        let outerBoxXPercentage: CGFloat = 20.53
        let outerBoxYPercentage: CGFloat = 38.55
        let outerBoxWidthPecentage: CGFloat = 73.72
        let outerBoxHeightPecentage: CGFloat = 35.48
        
        let outerBoxX : CGFloat = templateInfo.screenSize.width*outerBoxXPercentage/100
        let outerBoxY : CGFloat = templateInfo.screenSize.height*outerBoxYPercentage/100
        let outerBoxWidth = templateInfo.screenSize.width*outerBoxWidthPecentage/100
        let outerBoxHeight = templateInfo.screenSize.height*outerBoxHeightPecentage/100

        let bezierRect = CGRect(x: outerBoxX, y: outerBoxY, width: outerBoxWidth, height: outerBoxHeight)
        self.addBezierBoxWithBorder(rect: bezierRect, toContext: context, rectBGColor: bezierBoxesBGColor, borderColor: UIColor(hexString: "A2A2A2"), cornerRadius: 0.0)
        
        let horizantalLineXPercentage: CGFloat = outerBoxXPercentage
        let boxHeightPercentage: CGFloat = 5.91
        let horizantalLineYPercentage: CGFloat = outerBoxYPercentage + boxHeightPercentage
        let horizantalLineWidthPercentage: CGFloat = outerBoxWidthPecentage

        let horizontalLineX: CGFloat = templateInfo.screenSize.width*horizantalLineXPercentage/100.0
        var horizontalLineY: CGFloat = templateInfo.screenSize.height*horizantalLineYPercentage/100.0
        let horizontalLineWidth: CGFloat = templateInfo.screenSize.width*horizantalLineWidthPercentage/100.0
        let verticalGapBWHorizantalLines: CGFloat = templateInfo.screenSize.height*boxHeightPercentage/100.0

        // Drawing horizantal lines
        let numberOfHorizantalLines =  5
        for _ in 1...numberOfHorizantalLines
        {
            let bezierlineRect = CGRect(x: horizontalLineX, y: horizontalLineY, width: horizontalLineWidth, height: 1)
            self.addHorizantalBezierLine(rect: bezierlineRect, toContext: context, withColor: UIColor(hexString: "A2A2A2"))
            horizontalLineY +=  verticalGapBWHorizantalLines
        }

        // Drawing vertical lines
        let boxWidthPercentage: CGFloat = 10.53
        let verticalLineXPercentage: CGFloat = outerBoxXPercentage + boxWidthPercentage
        var verticalLineX: CGFloat = templateInfo.screenSize.width*verticalLineXPercentage/100.0
        let verticalLineYPercentage: CGFloat = outerBoxYPercentage
        let verticalLineY = templateInfo.screenSize.height*verticalLineYPercentage/100.0
        let verticalLineHeightPercentage: CGFloat = outerBoxHeightPecentage
        let verticalLineHeight: CGFloat = templateInfo.screenSize.height*verticalLineHeightPercentage/100.0
        let horizantalGapBWVerticalLines: CGFloat = templateInfo.screenSize.width*boxWidthPercentage/100.0

        let numberOfVerticalLines = 6
        for _ in 1...numberOfVerticalLines {
            let bezierlineRect = CGRect(x: verticalLineX, y: verticalLineY, width: 1, height: verticalLineHeight)
            self.addVerticalBezierLine(rect: bezierlineRect, toContext: context, withColor: UIColor(hexString: "A2A2A2"))
            verticalLineX +=  horizantalGapBWVerticalLines
        }
    }

}
