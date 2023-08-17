//
//  FTBasicClassicLegalTemplateFormat.swift
//  DynamicTemplateGeneration
//
//  Created by sreenu cheedella on 24/02/20.
//  Copyright © 2020 sreenu cheedella. All rights reserved.
//

import UIKit
import PDFKit

class FTLegalTemplateFormat: FTDynamicTemplateFormat {
    
    override func renderTemplate(context: CGContext) {
        super.renderTemplate(context: context)
        
        let horizLineCount = horizontalLineCount()
        
        var xPos = getLeftMargin()
//        if UIDevice.deviceScreenType() == FTScreenType.Iphone {
//            xPos -= 40
//        }
        var yPos = pageRect.height - templateInfo.codableInfo.bottomMargin
        
        //Drawing for horizontal lines
        context.saveGState()
        context.setLineWidth(templateInfo.lineWidth)
        context.setStrokeColor(UIColor.init(hexWithAlphaString: templateInfo.horizontalLineColor).cgColor)
        for _ in 0...horizLineCount {
            context.move(to: CGPoint(x: 0, y: yPos))
            context.addLine(to: CGPoint(x: pageRect.width, y: yPos))
            yPos -= self.lineHeight
        }
        context.strokePath()
        context.restoreGState()
        
        //Drawing for vertical lines
        context.saveGState()
        context.setLineWidth(templateInfo.lineWidth)
        context.setStrokeColor(UIColor.init(hexWithAlphaString: templateInfo.verticalLineColor).cgColor)
        for _  in 0...1 {
            context.move(to: CGPoint(x: xPos, y: 0))
            context.addLine(to: CGPoint(x: xPos, y: pageRect.height - templateInfo.codableInfo.bottomMargin))
            xPos += templateInfo.codableInfo.verticalSpacing;
        }
        context.strokePath()
        context.restoreGState()
    }
    
    
    override func updatePageProperties() {
        super.updatePageProperties();
        self.pageProperties.leftMargin = Int(getLeftMargin() + templateInfo.codableInfo.verticalSpacing);
    }
    
    override var lineHeight: CGFloat {
        return templateInfo.customVariants.lineType.horizontalLineSpacing
//        return templateInfo.customVariants.lineType.horizontalLineSpacing + templateInfo.lineWidth
    }
    
    override func horizontalLineCount() -> Int {
        let cellHeight = self.lineHeight
        let consideredPageHeight = pageRect.height - templateInfo.codableInfo.bottomMargin
        let actualCount = (consideredPageHeight / cellHeight).toInt()
        return actualCount - 2
    }
    
    private func getLeftMargin() -> CGFloat {
        let consideredWidth = pageRect.width
        return consideredWidth * 0.14
    }
}
