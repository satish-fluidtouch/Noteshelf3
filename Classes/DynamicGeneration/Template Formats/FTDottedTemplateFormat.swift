//
//  FTBasicDottedTemplateFormat.swift
//  DynamicTemplateGeneration
//
//  Created by sreenu cheedella on 26/02/20.
//  Copyright © 2020 sreenu cheedella. All rights reserved.
//

import UIKit

class FTDottedTemplateFormat: FTDynamicTemplateFormat {
    override func renderTemplate(context: CGContext) {
        super.renderTemplate(context: context)
        
        
        let horizLineCount = horizontalLineCount()
        let vertLineCount = verticalLineCount()
        let yPos = getYPos(lineCount: horizLineCount) + (templateInfo.customVariants.lineType.verticalLineSpacing/2)
        let xPos = getXPos(lineCount: vertLineCount) + (templateInfo.customVariants.lineType.horizontalLineSpacing/2)
        
        var dotRect = CGRect(x: xPos, y: yPos, width: templateInfo.dottedWidth, height: templateInfo.dottedWidth)
        
        context.saveGState()
        context.setFillColor(UIColor.init(hexWithAlphaString: templateInfo.horizontalLineColor).cgColor)
        
        for _ in 0...horizLineCount {
            for _ in 0...vertLineCount - 1 {
                context.addEllipse(in: dotRect)
                dotRect = dotRect.offsetBy(dx: templateInfo.customVariants.lineType.verticalLineSpacing + templateInfo.dottedWidth, dy: 0)
            }
            dotRect.origin = CGPoint(x: xPos, y: dotRect.origin.y)
            dotRect = dotRect.offsetBy(dx: 0, dy: self.lineHeight)
        }
        context.fillPath()
        context.restoreGState()
    }
    
    override var lineHeight: CGFloat {
//        return templateInfo.customVariants.lineType.horizontalLineSpacing + templateInfo.dottedWidth;
        return templateInfo.customVariants.lineType.horizontalLineSpacing;
    }
    override func horizontalLineCount() -> Int {
        let cellHeight = self.lineHeight;
        let consideredHeight = pageRect.height - templateInfo.codableInfo.bottomMargin
        let actualCount = (consideredHeight/cellHeight).toInt()
        return actualCount - 1
    }
    
    override func verticalLineCount() -> Int {
        let cellWidth = templateInfo.customVariants.lineType.verticalLineSpacing + templateInfo.dottedWidth
        let actualCount = (pageRect.width/cellWidth).toInt()
        return actualCount - 1
    }
    
    func getXPos(lineCount: Int) -> CGFloat{
        let cellWidth = templateInfo.customVariants.lineType.verticalLineSpacing + templateInfo.dottedWidth
        return ((pageRect.width.toInt() - ((lineCount)  * (cellWidth.toInt()))) / 2).toCGFloat()
    }
    
    func getYPos(lineCount: Int) -> CGFloat{
        let cellHeight = self.lineHeight
        let consideredHeight = pageRect.height - templateInfo.codableInfo.bottomMargin
        return ((consideredHeight.toInt() - ((lineCount)  * (cellHeight.toInt()))) / 2).toCGFloat()
    }
}

