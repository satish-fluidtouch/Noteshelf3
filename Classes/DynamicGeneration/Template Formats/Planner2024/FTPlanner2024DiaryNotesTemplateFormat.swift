//
//  FTPlannerDiaryNotesTemplateFormat.swift
//  Noteshelf
//
//  Created by Ramakrishna on 11/11/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTPlanner2024DiaryNotesTemplateFormat : FTPlanner2024DiaryTemplateFormat {
    override func renderTemplate(context: CGContext) {
        super.renderTemplate(context: context)
        self.renderiPadTemplate(context: context)
    }
    private func renderiPadTemplate(context : CGContext){
        // Notes lines rendering

        let verticalGapBWLinesPercnt : CGFloat = 4.43
        let notesXAxisPercnt : CGFloat = 7.46
        let writingAreaYAxisPercnt : CGFloat = 22.90
        let writingAreaLineWidthPercnt : CGFloat = 38.93
        let writingAreaLineBottomPercnt : CGFloat = 6.11
        let twoSpredGapWidthPercent: CGFloat = 7.19
        let pageWidth = templateInfo.screenSize.width
        let pageHeight = templateInfo.screenSize.height

        var writingAreaLinesXAxis = pageWidth*notesXAxisPercnt/100
        var writingAreaLineYAxis = (pageHeight*writingAreaYAxisPercnt/100)
        let writingAreaLineWidth = pageWidth*writingAreaLineWidthPercnt/100
        let verticalGapBWbezierlines = pageHeight*verticalGapBWLinesPercnt/100
        let bezierlinesBottom = pageHeight*writingAreaLineBottomPercnt/100
        let twoSpredGapWidth = pageWidth*twoSpredGapWidthPercent/100

        let numberOfDashedLines = Int((pageHeight - bezierlinesBottom - writingAreaLineYAxis)/verticalGapBWbezierlines) + 1
        let dashedLinesTintColor = UIColor(hexString: "#363636", alpha: 0.4)

        // First spread lines column
        drawDashedLinesFrom(x: writingAreaLinesXAxis, y: writingAreaLineYAxis, numberOfDashedLines: numberOfDashedLines)

        // Second spread lines column
        writingAreaLinesXAxis += writingAreaLineWidth + twoSpredGapWidth
        writingAreaLineYAxis = (pageHeight*writingAreaYAxisPercnt/100)
        drawDashedLinesFrom(x: writingAreaLinesXAxis, y: writingAreaLineYAxis, numberOfDashedLines: numberOfDashedLines)

        func drawDashedLinesFrom(x xAxis: CGFloat,y yAxis: CGFloat, numberOfDashedLines: Int){
            var writingLinesYAxis = yAxis
            for _ in 1...numberOfDashedLines
            {
                let bezierlineRect = CGRect(x: xAxis, y: writingLinesYAxis, width: writingAreaLineWidth, height: 0.5)
                self.addBezierDashedlinePathWith(rect: bezierlineRect, toContext: context, withColor: dashedLinesTintColor, dashPattern: [1,2])
                writingLinesYAxis +=  verticalGapBWbezierlines
            }
        }
        addSpreadLineSeperator(toContext: context)
    }
}
