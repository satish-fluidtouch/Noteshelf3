//
//  FTBasicCheckedTemplateFormat.swift
//  DynamicTemplateGeneration
//
//  Created by sreenu cheedella on 27/02/20.
//  Copyright © 2020 sreenu cheedella. All rights reserved.
//

import UIKit

class FTCheckedTemplateFormat: FTDynamicTemplateFormat {
    override func renderTemplate(context: CGContext) {
        super.renderTemplate(context: context)
        
        let horizLineCount = horizontalLineCount()
        let vertLineCount = verticalLineCount()
        var yPos = pageRect.height - templateInfo.codableInfo.bottomMargin
        var xPos = getXPos(lineCount: vertLineCount)
        
        //Drawing for horizontal lines
        context.saveGState()
        context.setLineWidth(templateInfo.lineWidth)
        context.setStrokeColor(UIColor.init(hexWithAlphaString: templateInfo.horizontalLineColor).cgColor)
        
        
        for _ in 0...horizLineCount {
            context.move(to: CGPoint(x: 0, y: yPos))
            context.addLine(to: CGPoint(x: pageRect.width, y: yPos))
            yPos -= templateInfo.customVariants.lineType.horizontalLineSpacing + templateInfo.lineWidth
        }
        
        for _ in 0...vertLineCount {
            context.move(to: CGPoint(x: xPos, y: yPos + templateInfo.customVariants.lineType.horizontalLineSpacing + templateInfo.lineWidth))
            context.addLine(to: CGPoint(x: xPos, y: pageRect.height - templateInfo.codableInfo.bottomMargin))
            xPos += templateInfo.customVariants.lineType.verticalLineSpacing + templateInfo.lineWidth
        }
        
        context.strokePath()
        context.restoreGState()
    }
    
    override var lineHeight: CGFloat {
//        let lineHeight = templateInfo.customVariants.lineType.horizontalLineSpacing + templateInfo.lineWidth;
        let lineHeight = templateInfo.customVariants.lineType.horizontalLineSpacing;
        return lineHeight;
    }

    override func horizontalLineCount() -> Int {
        let cellHeight = self.lineHeight
        let consideredPageHeight = pageRect.height - templateInfo.codableInfo.bottomMargin
        let actualCount = (consideredPageHeight / cellHeight).toInt()
        let difference = consideredPageHeight - (actualCount.toCGFloat() * cellHeight)
        return difference >= cellHeight - 3 ? actualCount : actualCount - 1
    }
    
    override func verticalLineCount() -> Int {
        let cellWidth = templateInfo.customVariants.lineType.verticalLineSpacing + templateInfo.lineWidth
        let actualCount = (pageRect.width/cellWidth).toInt()
        return actualCount - 1
    }
    
    func getXPos(lineCount: Int) -> CGFloat{
        let cellWidth = templateInfo.customVariants.lineType.verticalLineSpacing + templateInfo.lineWidth
        return ((pageRect.width.toInt() - ((lineCount)  * (cellWidth.toInt()))) / 2).toCGFloat()
    }
}

