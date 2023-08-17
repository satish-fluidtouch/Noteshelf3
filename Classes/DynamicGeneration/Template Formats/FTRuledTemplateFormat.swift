//
//  FTBasicRuledTemplateFormat.swift
//  DynamicTemplateGeneration
//
//  Created by sreenu cheedella on 24/02/20.
//  Copyright © 2020 sreenu cheedella. All rights reserved.
//

import UIKit

class FTRuledTemplateFormat: FTDynamicTemplateFormat {
    override func renderTemplate(context: CGContext) {
        super.renderTemplate(context: context)
        
        let horizLineCount = horizontalLineCount()
        var yPos = pageRect.height - templateInfo.codableInfo.bottomMargin
                
        //Drawing for horizontal lines
        let cellHeight = self.lineHeight
        context.saveGState()
        context.setLineWidth(templateInfo.lineWidth)
        context.setStrokeColor(UIColor.init(hexWithAlphaString: templateInfo.horizontalLineColor).cgColor)
        
        for _ in 0...horizLineCount {
            context.move(to: CGPoint(x: 0, y: yPos))
            context.addLine(to: CGPoint(x: pageRect.width, y: yPos))
            yPos -= cellHeight
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
        return difference > cellHeight - 3 ? actualCount : actualCount - 1
    }
}

extension CGFloat {
    func toInt() -> Int {
        return Int(Double(self))
    }
}

extension Int {
    func toCGFloat() -> CGFloat {
        return CGFloat(self)
    }
}

