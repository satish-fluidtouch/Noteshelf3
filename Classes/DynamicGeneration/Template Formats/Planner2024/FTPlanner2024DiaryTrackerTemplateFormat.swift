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
        let isLandscaped = templateInfo.customVariants.isLandscape
        
        let boxWidth : CGFloat = isLandscaped ? 2.39 : 3.40
        let boxHeight : CGFloat = isLandscaped ? 2.70 : 1.98
        let startingXAxis : CGFloat = isLandscaped ? 56.02 : 6.59
        let startingYAxis : CGFloat = isLandscaped ? 24.02 : 63.26
        let horizontalGapBWBoxes : CGFloat = isLandscaped ? 0.12 : 0.23
        let verticalGapBWBoxes : CGFloat = isLandscaped ? 0.25 :0.19
        let xOffsetBWHabitTrackersPercnt : CGFloat = isLandscaped ? 1.72 : 3.64
        let yOffsetBWHabitTrackersPercnt : CGFloat = isLandscaped ? 6.88 : 4.29
        let habitsStripWidthsPercnt : CGFloat = isLandscaped ? 17.54 : 24.94
        
        let xAxis : CGFloat = templateInfo.screenSize.width*startingXAxis/100
        var monthBoxesYAxis : CGFloat = templateInfo.screenSize.height*startingYAxis/100
        var monthBoxesXAXis : CGFloat = xAxis
        
        let widthPerBox = templateInfo.screenSize.width*boxWidth/100
        let heightPerBox = templateInfo.screenSize.height*boxHeight/100
        let xOffsetBWHabitTrackers = templateInfo.screenSize.width*xOffsetBWHabitTrackersPercnt/100
        let yOffsetBWHabitTrackers = templateInfo.screenSize.height*yOffsetBWHabitTrackersPercnt/100
        let habitsStripWidth = templateInfo.screenSize.width*habitsStripWidthsPercnt/100
        
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
                habbitBoxX += widthPerBox + templateInfo.screenSize.width*horizontalGapBWBoxes/100
                if index1 % 7 == 0 {
                    habbitBoxX = monthBoxesXAXis
                    habbitBoxY += heightPerBox + templateInfo.screenSize.height*verticalGapBWBoxes/100
                }
            }
            let numberOfColumns : Int = isLandscaped ? 2 : 3
            if index % numberOfColumns == 0 {
                monthBoxesXAXis = xAxis
                monthBoxesYAxis += 6*heightPerBox + 5*verticalGapBWBoxes + yOffsetBWHabitTrackers
            }else{
                monthBoxesXAXis += 7*widthPerBox + 6*horizontalGapBWBoxes + xOffsetBWHabitTrackers
            }
        }
        let stripWidthPercnt = isLandscaped ? 3.59 : 4.67
        let trackerYAxisPercnt = isLandscaped ? 0.0 : 11.16
        let trackerWidthPercnt = isLandscaped ? 0.0 : 58.89
        let trackerHeightPercnt = isLandscaped ? 0.0 : 	46.75
        
        let stripWidth = templateInfo.screenSize.width*stripWidthPercnt/100
        let trackerWidth = templateInfo.screenSize.width*trackerWidthPercnt/100
        let trackerHeight = templateInfo.screenSize.width*trackerHeightPercnt/100
        let trackerXAxis = ((templateInfo.screenSize.width - stripWidth)/2) - (trackerWidth/2)
        let trackerYAxis = templateInfo.screenSize.height*trackerYAxisPercnt/100
        
        
//        let trackerImage = UIImage(named: "moodTracker")
//        let trackerRect = CGRect(x: trackerXAxis, y: trackerYAxis, width: trackerWidth, height: trackerHeight)
//        trackerImage?.draw(at: CGPoint(x: trackerRect.origin.x, y: trackerRect.origin.y))
        
        // Mood Tracker Boxes rendering
        
        let moodBoxWidthPercnt = isLandscaped ? 5.21 : 6.95
        let moodBoxHeightPercnt = isLandscaped ? 7.01 : 5.15
        let moodBoxXPercnt = isLandscaped ?  9.98 : 24.94
        let moodBoxYPercnt = isLandscaped ?  30.12 : 18.89
        let moodBoxesXOffsetPercnt = isLandscaped ? 0.44 : 0.59
        let moodBoxesYOffsetPercnt = isLandscaped ? 0.64 : 0.47
        
        let moodBoxWidth = templateInfo.screenSize.width*moodBoxWidthPercnt/100
        let moodBoxHeight = templateInfo.screenSize.height*moodBoxHeightPercnt/100
        let moodBoxX = templateInfo.screenSize.width*moodBoxXPercnt/100
        let moodBoxY = templateInfo.screenSize.height*moodBoxYPercnt/100
        let moodBoxesXOffset = templateInfo.screenSize.width*moodBoxesXOffsetPercnt/100
        let moodBoxesYOffset = templateInfo.screenSize.height*moodBoxesYOffsetPercnt/100
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

    }
    private func drawhabitColorBandsWith(xAxis : CGFloat, yAxis : CGFloat, context : CGContext, width : CGFloat, bandColor : UIColor){
        let isLandscaped = templateInfo.customVariants.isLandscape
        let colorBandHeightPercnt = isLandscaped ? 2.59 : 1.90
        let colrbndYAxisPercnt = isLandscaped ? 3.63 : 2.38
        
        let colorBandHeight = templateInfo.screenSize.height*colorBandHeightPercnt/100
        let colorBandYAxis = templateInfo.screenSize.height*colrbndYAxisPercnt/100
        let colrbndYAxisWRTMnthBx = yAxis - colorBandYAxis
        
        let monthBandRect = CGRect(x: xAxis, y: colrbndYAxisWRTMnthBx, width: width, height: colorBandHeight)
        context.setFillColor(bandColor.cgColor)
        context.fill(monthBandRect)
    }
}
