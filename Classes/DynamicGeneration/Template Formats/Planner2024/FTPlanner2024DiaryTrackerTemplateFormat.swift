//
//  FTPlannerDiaryTrackerTemplateFormat.swift
//  Noteshelf
//
//  Created by Ramakrishna on 11/11/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTPlanner2024DiaryTrackerTemplateFormat  :FTPlanner2024DiaryTemplateFormat {
    override func renderTemplate(context: CGContext) {
        super.renderTemplate(context: context)
        self.renderiPadTemplate(context: context)
    }
    private func renderiPadTemplate(context : CGContext){

        let boxWidth : CGFloat = 2.49
        let boxHeight : CGFloat = 2.99
        let startingXAxis : CGFloat = 53.59
        let startingYAxis : CGFloat = 23.26
        let horizontalGapBWBoxes : CGFloat = 0.17
        let verticalGapBWBoxes : CGFloat = 0.23
        let xOffsetBWHabitTrackersPercnt : CGFloat = 1.79
        let yOffsetBWHabitTrackersPercnt : CGFloat = 6.59
        let habitsStripWidthsPercnt : CGFloat = 18.52
        let pageWidth = templateInfo.screenSize.width
        let pageHeight = templateInfo.screenSize.height

        let xAxis : CGFloat = pageWidth*startingXAxis/100
        var monthBoxesYAxis : CGFloat = pageHeight*startingYAxis/100
        var monthBoxesXAXis : CGFloat = xAxis

        let widthPerBox = pageWidth*boxWidth/100
        let heightPerBox = pageHeight*boxHeight/100
        let xOffsetBWHabitTrackers = pageWidth*xOffsetBWHabitTrackersPercnt/100
        let yOffsetBWHabitTrackers = pageHeight*yOffsetBWHabitTrackersPercnt/100
        let habitsStripWidth = pageWidth*habitsStripWidthsPercnt/100

        // tracker boxes rendering
        let habitColorbandsDict = monthStripColors
        for index in 1...6 {
            var habbitBoxX = monthBoxesXAXis
            var habbitBoxY = monthBoxesYAxis
            //let widthOfHabitEntireBoxes = (7*widthPerBox + 6*horizontalGapBWBoxes) + 14*0.5 // box widths + gap widths + box borders width
            self.drawhabitColorBandsWith(xAxis: monthBoxesXAXis, yAxis: monthBoxesYAxis, context: context, width: habitsStripWidth, bandColor: UIColor(hexString: habitColorbandsDict[index - 1]))
            for index1 in 1...42 {
                let bezierRect = CGRect(x: habbitBoxX, y: habbitBoxY, width: widthPerBox, height: heightPerBox)
                self.addBezierBoxWithBorder(rect: bezierRect, toContext: context, rectBGColor: getBezierBoxesBGColor(), borderColor: getBezierlinesTintColor(), cornerRadius: 1.0,withLineWidth: 0.5)
                habbitBoxX += widthPerBox + pageWidth*horizontalGapBWBoxes/100
                if index1 % 7 == 0 {
                    habbitBoxX = monthBoxesXAXis
                    habbitBoxY += heightPerBox + pageHeight*verticalGapBWBoxes/100
                }
            }
            let numberOfColumns : Int = 2
            if index % numberOfColumns == 0 {
                monthBoxesXAXis = xAxis
                monthBoxesYAxis += 6*heightPerBox + 5*verticalGapBWBoxes + yOffsetBWHabitTrackers + 5.5 //
            }else{
                monthBoxesXAXis += 7*widthPerBox + 6*horizontalGapBWBoxes + xOffsetBWHabitTrackers + 6.5 // 6.5 is count of each box line width.
            }
        }

        // Mood Tracker Boxes rendering

        let moodBoxWidthPercnt = 5.21
        let moodBoxHeightPercnt = 7.43
        let moodBoxXPercnt = 7.19
        let moodBoxYPercnt = 30.57
        let moodBoxesXOffsetPercnt = 0.44
        let moodBoxesYOffsetPercnt = 0.59

        let moodBoxWidth = pageWidth*moodBoxWidthPercnt/100
        let moodBoxHeight = pageHeight*moodBoxHeightPercnt/100
        let moodBoxX = pageWidth*moodBoxXPercnt/100
        let moodBoxY = pageHeight*moodBoxYPercnt/100
        let moodBoxesXOffset = pageWidth*moodBoxesXOffsetPercnt/100
        let moodBoxesYOffset = pageHeight*moodBoxesYOffsetPercnt/100
        var moodBoxesXvalue = moodBoxX
        var moodBoxesYvalue = moodBoxY


        for index2 in 1...42 {
            let bezierRect = CGRect(x: moodBoxesXvalue, y: moodBoxesYvalue, width: moodBoxWidth, height: moodBoxHeight)
            self.addBezierBoxWithBorder(rect: bezierRect, toContext: context, rectBGColor: getBezierBoxesBGColor(), borderColor: getBezierlinesTintColor(), cornerRadius: 2.0,withLineWidth: 0.8)
            moodBoxesXvalue += moodBoxWidth + moodBoxesXOffset
            if index2 % 7 == 0 {
                moodBoxesXvalue = moodBoxX
                moodBoxesYvalue += moodBoxHeight + moodBoxesYOffset
            }
        }
        addSpreadLineSeperator(toContext: context)
    }
    private func drawhabitColorBandsWith(xAxis : CGFloat, yAxis : CGFloat, context : CGContext, width : CGFloat, bandColor : UIColor){
        let pageWidth = templateInfo.screenSize.width
        let pageHeight = templateInfo.screenSize.height

        let colorBandHeightPercnt = 2.39
        let colrbndYAxisPercnt = 3.59

        let colorBandHeight = pageHeight*colorBandHeightPercnt/100
        let colorBandYAxis = pageHeight*colrbndYAxisPercnt/100
        let colrbndYAxisWRTMnthBx = yAxis - colorBandYAxis

        let monthBandRect = CGRect(x: xAxis, y: colrbndYAxisWRTMnthBx, width: width, height: colorBandHeight)
        context.setFillColor(bandColor.cgColor)
        context.fill(monthBandRect)
    }
}
