//
//  FTPlannerDiaryNotesTemplateFormat.swift
//  Noteshelf
//
//  Created by Ramakrishna on 11/11/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTPlannerDiaryNotesTemplateFormat : FTPlannerDiaryTemplateFormat {
    override func renderTemplate(context: CGContext) {
        super.renderTemplate(context: context)
        self.renderiPadTemplate(context: context)
    }
    private func renderiPadTemplate(context : CGContext){
        let isLandscaped = templateInfo.customVariants.isLandscape
        
        // Notes lines rendering
        
        let verticalGapBWLinesPercnt : CGFloat = isLandscaped ? 4.54 : 2.99
        let notesXAxisPercnt : CGFloat = isLandscaped ? 3.59 : 4.79
        let writingAreaYAxisPercnt : CGFloat = isLandscaped ? 20.77 : 16.69
        let writingAreaLineWidthPercnt : CGFloat = isLandscaped ? 89.11 : 85.61
        let writingAreaLineBottomPercnt : CGFloat = isLandscaped ? 5.19 : 5.05
        
        
        let writingAreaLinesXAxis = templateInfo.screenSize.width*notesXAxisPercnt/100
        var writingAreaLineYAxis = (templateInfo.screenSize.height*writingAreaYAxisPercnt/100)
        let writingAreaLineWidth = templateInfo.screenSize.width*writingAreaLineWidthPercnt/100
        let verticalGapBWbezierlines = templateInfo.screenSize.height*verticalGapBWLinesPercnt/100
        let bezierlinesBottom = templateInfo.screenSize.height*writingAreaLineBottomPercnt/100
        
        let numberOfDashedLines = Int((templateInfo.screenSize.height - bezierlinesBottom - writingAreaLineYAxis)/verticalGapBWbezierlines) + 1
        let dashedLinesTintColor = isDarkTemplate ? UIColor(hexString: "#FEFEF5", alpha: 0.4) : UIColor(hexString: "#363636", alpha: 0.4)
        for _ in 1...numberOfDashedLines
        {
            let bezierlineRect = CGRect(x: writingAreaLinesXAxis, y: writingAreaLineYAxis, width: writingAreaLineWidth, height: 0.5)
            self.addBezierDashedlinePathWith(rect: bezierlineRect, toContext: context, withColor: dashedLinesTintColor, dashPattern: [1,2])
            writingAreaLineYAxis +=  verticalGapBWbezierlines
        }
    }
}
