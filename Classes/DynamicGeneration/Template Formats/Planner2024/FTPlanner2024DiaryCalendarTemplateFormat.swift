//
//  FTPlannerDiaryCalendarTemplate.swift
//  Noteshelf
//
//  Created by Ramakrishna on 09/11/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

class FTPlanner2024DiaryCalendarTemplateFormat : FTPlanner2024DiaryTemplateFormat {

        override func renderTemplate(context: CGContext) {
            super.renderTemplate(context: context)
            self.renderiPadTemplate(context: context)
        }
        private func renderiPadTemplate(context : CGContext){

            // Below values are in terms of percentages
            let boxWidth = 18.34
            let boxHeight = 19.06
            let startingXAxis = 7.46
            let startingYAxis = 21.94
            let horizontalGapBWBoxes = 2.24
            let verticalGapBWBoxes = 7.43
            let spredLinesImagePercent: CGFloat = 50.0
            let horizontalGapBetweenSplitColumns: CGFloat = 7.19


            let xAxis : CGFloat = CGFloat(templateInfo.screenSize.width)*startingXAxis/100
            let yAxis  = CGFloat(templateInfo.screenSize.height)*startingYAxis/100
            var calenderYearBoxesXAXis = xAxis
            var calenderYearBoxesYAxis = yAxis

            let widthPerBox = templateInfo.screenSize.width*(boxWidth)/100
            let heightPerBox = templateInfo.screenSize.height*(boxHeight)/100
            let spredLinesX = CGFloat(templateInfo.screenSize.width)*spredLinesImagePercent/100

            var counter: Int = 1
            // Month boxes rendering
            for index in 1...12 {
                let bezierRect = CGRect(x: calenderYearBoxesXAXis, y: calenderYearBoxesYAxis, width: widthPerBox, height: heightPerBox)
                self.addBezierBoxWithBorder(rect: bezierRect, toContext: context, rectBGColor: UIColor(hexString: "#FEFEFE", alpha: 1.0), borderColor: UIColor(hexString: "#363636", alpha: 0.4), cornerRadius: 0.0,withLineWidth: 0.5)
                self.drawLinesWithInitial(xAxis: calenderYearBoxesXAXis, yAxis: calenderYearBoxesYAxis, context: context, outerBoxWidth: CGFloat(widthPerBox), outerBoxHeight: CGFloat(heightPerBox))
                if index % 2 == 0 {
                    counter += 1
                    calenderYearBoxesXAXis = index < 6 ? xAxis : (xAxis + 2*widthPerBox + templateInfo.screenSize.width*horizontalGapBWBoxes/100 + templateInfo.screenSize.width*horizontalGapBetweenSplitColumns/100)

                    calenderYearBoxesYAxis = index == 6 ? yAxis : (calenderYearBoxesYAxis + (heightPerBox + templateInfo.screenSize.height*verticalGapBWBoxes/100))
                    print("x values", calenderYearBoxesXAXis)
                } else {
                    calenderYearBoxesXAXis += widthPerBox + templateInfo.screenSize.width*horizontalGapBWBoxes/100
                }
            }
            addSpreadLineSeperator(toContext: context)
        }

        private func drawLinesWithInitial(xAxis : CGFloat, yAxis : CGFloat ,context : CGContext, outerBoxWidth : CGFloat, outerBoxHeight : CGFloat){
            let verticalGapBWHorizantalLines: CGFloat = (outerBoxHeight/6)
            let horizontalLineX: CGFloat = xAxis
            var horizontalLineY: CGFloat = yAxis + verticalGapBWHorizantalLines
            let horizontalLineWidth: CGFloat = outerBoxWidth


            // Drawing horizantal lines
            let numberOfHorizantalLines =  5
            for _ in 1...numberOfHorizantalLines
            {
                let bezierlineRect = CGRect(x: horizontalLineX, y: horizontalLineY + 0.5, width: horizontalLineWidth, height: 1)
                self.addHorizantalBezierLine(rect: bezierlineRect, toContext: context, withColor: UIColor(hexString: "#363636", alpha: 0.4),withLineWidth: 0.5)
                horizontalLineY +=  verticalGapBWHorizantalLines
            }

            // Drawing vertical lines
            let horizantalGapBWVerticalLines: CGFloat = (outerBoxWidth/7)
            var verticalLineX: CGFloat = xAxis + horizantalGapBWVerticalLines
            var verticalLineY = yAxis
            let verticalLineHeight: CGFloat = outerBoxHeight
            let numberOfVerticalLines = 6
            for _ in 1...numberOfVerticalLines {
                let bezierlineRect = CGRect(x: verticalLineX + 0.5 , y: verticalLineY, width: 1, height: verticalLineHeight)
                self.addVerticalBezierLine(rect: bezierlineRect, toContext: context, withColor: UIColor(hexString: "#363636", alpha: 0.4),withLineWidth: 0.5)
                verticalLineX +=  horizantalGapBWVerticalLines
            }
        }
}
