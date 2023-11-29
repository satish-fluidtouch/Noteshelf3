//
//  FTPlannerDiaryTemplateFormat.swift
//  Noteshelf
//
//  Created by Ramakrishna on 09/11/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

enum FTPlanner2024DiaryTemplateType {
    case calendar
    case year
    case month
    case week
    case day
    case notes
    case tracker
    case extras
    
    var className : String {
        
        switch self {
        case .calendar:
            return "FTPlanner2024DiaryCalendarTemplateFormat"
        case .year:
            return "FTPlanner2024DiaryYearTemplateFormat"
        case .month:
            return "FTPlanner2024DiaryMonthTemplateFormat"
        case .week:
            return "FTPlanner2024DiaryWeekTemplateFormat"
        case .day:
            return "FTPlanner2024DiaryDayTemplateFormat"
        case .notes:
            return "FTPlanner2024DiaryNotesTemplateFormat"
        case .tracker:
            return "FTPlanner2024DiaryTrackerTemplateFormat"
        case .extras:
            return "FTPlanner2024DiaryExtrasTemplateFormat"
        }
    }
    
    var displayName : String {
        switch self {
        case .calendar:
            return "Planner2024DiaryCalendar"
        case .year:
            return "Planner2024DiaryYear"
        case .month:
            return "Planner2024DiaryMonth"
        case .week:
            return "Planner2024DiaryWeek"
        case .day:
            return "Planner2024DiaryDay"
        case .notes:
            return "Planner2024DiaryNotes"
        case .tracker:
            return "Planner2024DiaryTracker"
        case .extras :
            return "PlannerDiaryExtras"
        }
    }
}
class FTPlanner2024DiaryTemplateFormat : FTDigitalDiaryTemplateFormat {

    // ******* For normal Template ******//
    var bezierBoxesBGColor : UIColor = UIColor(hexString: "#FEFEFE", alpha: 1.0)
    var bezierLinesTintColor: UIColor = UIColor(hexString: "#363636", alpha: 0.4)
    let toDoColors : [String] = ["#AAEBF1","#C4F2E7","#F3E3B5","#F0CBC2","#F1C7EA","#DDC3F2","#AAEBF1"]
    let monthStripColors : [String] = ["#AAEBF1","#C4F2E7","#F3E3B5","#F0CBC2","#F1C7EA","#DDC3F2","#AAEBF1","#C4F2E7","#F3E3B5","#F0CBC2","#F1C7EA","#DDC3F2"]
    //***********************************//

    
    class func getFormatFrom(templateInfo : FTPlanner2024DiaryTemplateInfo) -> FTPlanner2024DiaryTemplateFormat{
        if let templateFormateClass = ClassFromString.getClass(fromString: templateInfo.templateType.className) as? FTPlanner2024DiaryTemplateFormat.Type{
            return templateFormateClass.init(templateInfo : templateInfo)
        }
        return FTPlanner2024DiaryTemplateFormat(templateInfo: templateInfo)
    }
    
    required init(templateInfo : FTPlanner2024DiaryTemplateInfo){
        super.init(templateInfo: templateInfo)
    }
    var pageRect : CGRect {
        return CGRect(x: 0, y: 0, width: templateInfo.screenSize.width, height: templateInfo.screenSize.height)
    }
    func renderTemplate(context: CGContext) {
        let pageRect = CGRect(x: 0, y: 0, width: templateInfo.screenSize.width, height: templateInfo.screenSize.height)
        UIGraphicsBeginPDFPageWithInfo(pageRect, nil)
        context.setFillColor(self.templateInfo.getTemplateBackgroundColor().cgColor)
        context.fill(pageRect)
    }
    func addBezierBoxWithBorder( rect : CGRect, toContext context : CGContext, rectBGColor : UIColor, borderColor : UIColor, cornerRadius: CGFloat = 0.0, withLineWidth width : CGFloat){
        let bezierpath = cornerRadius != 0.0 ? UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius): UIBezierPath(rect: rect)
        bezierpath.lineWidth = width
        context.addPath(bezierpath.cgPath)
        context.saveGState()
        borderColor.setStroke()
        context.strokePath()
        rectBGColor.setFill()
        bezierpath.fill()
        context.translateBy(x: 0, y: CGFloat(templateInfo.screenSize.height))
        context.scaleBy(x: 1, y: -1)
        context.restoreGState()
    }
    func addHorizantalBezierLine(rect:CGRect, toContext context : CGContext, withColor color : UIColor, withLineWidth width: CGFloat) {
        let  bezierLinePath = UIBezierPath()
        let  p0 = CGPoint(x: rect.origin.x, y: rect.origin.y)
        bezierLinePath.move(to: p0)
        let  p1 = CGPoint(x: rect.origin.x + rect.width , y: rect.origin.y)
        bezierLinePath.addLine(to: p1)
        bezierLinePath.lineWidth = width
        bezierLinePath.lineCapStyle = .butt
        color.setStroke()
        context.addPath(bezierLinePath.cgPath)
        bezierLinePath.stroke()
    }

    func addVerticalBezierLine(rect:CGRect, toContext context : CGContext, withColor color : UIColor, withLineWidth width: CGFloat) {
       let bezierLinePath = UIBezierPath()
       let p0 = CGPoint(x: rect.origin.x, y: rect.origin.y)
       bezierLinePath.move(to: p0)
       let p1 = CGPoint(x: rect.minX , y: rect.minY + rect.height)
       bezierLinePath.addLine(to: p1)
       bezierLinePath.lineWidth = width
       color.setStroke()
       context.addPath(bezierLinePath.cgPath)
       bezierLinePath.stroke()
   }
    func addBezierDashedlinePathWith(rect:CGRect, toContext context : CGContext, withColor color : UIColor, dashPattern : [CGFloat]){
        let  bezierLinePath = UIBezierPath()
        let  p0 = CGPoint(x: rect.origin.x, y: rect.origin.y)
        bezierLinePath.move(to: p0)
        let  p1 = CGPoint(x: rect.origin.x + rect.width , y: rect.origin.y)
        bezierLinePath.addLine(to: p1)
        let  dashes: [ CGFloat ] = dashPattern
        bezierLinePath.setLineDash(dashes, count: dashes.count, phase: 0.0)
        bezierLinePath.lineCapStyle = .butt
        color.setStroke()
        context.addPath(bezierLinePath.cgPath)
        bezierLinePath.stroke()
    }
    func addBezierLineWith(rect: CGRect, toContext context: CGContext, withColor lineColor: UIColor, shadowColor: UIColor, shadowOffset : CGSize, shadowBlurRadius : CGFloat) {
        //Shadow Declarations
        let shadow = shadowColor
        let shadowOffset = shadowOffset
        let shadowBlurRadius: CGFloat = shadowBlurRadius

        //Bezier  Drawing
        let  bezierLinePath = UIBezierPath()
        let  p0 = CGPoint(x: rect.origin.x, y: rect.origin.y)
        bezierLinePath.move(to: p0)
        let  p1 = CGPoint(x: rect.origin.x + rect.width , y: rect.origin.y)
        bezierLinePath.addLine(to: p1)
        bezierLinePath.lineWidth = 1
        bezierLinePath.lineCapStyle = .butt
        lineColor.setStroke()
        context.addPath(bezierLinePath.cgPath)
        bezierLinePath.stroke()
        context.setShadow(offset: shadowOffset, blur: shadowBlurRadius,  color: (shadow as UIColor).cgColor)
    }
    func setNavigationSideStripIn(context : CGContext){
        let isLandscaped = templateInfo.customVariants.isLandscape

        let stripWidthPercnt = isLandscaped ? 3.59 : 4.67
        let stripXAxisPrecnt = isLandscaped ? 96.40 : 95.32
        
        let stripXAxis = templateInfo.screenSize.width*stripXAxisPrecnt/100
        let stripWidth = templateInfo.screenSize.width*stripWidthPercnt/100
        let stripColor =  UIColor(hexString: "#000000", alpha: 0.2)
        let stripShadowColor = UIColor(hexString: "#000000", alpha: 0.08)
        let shadowOffset = CGSize(width: 0, height: 2)
        let shadowBlurRadius : CGFloat = 4
        
        var sideStripBandHeight : CGFloat = 0.0
        //calendar strip
        let calendarStripHeightPercnt = isLandscaped ? 9.09 : 9.25
        let calendarStripHeight = templateInfo.screenSize.height*calendarStripHeightPercnt/100
        sideStripBandHeight += calendarStripHeight
        let calendarStripYAxis = calendarStripHeight
        let calendarStripRect = CGRect(x: stripXAxis, y:calendarStripYAxis, width: stripWidth, height: 1)
        self.addBezierLineWith(rect: calendarStripRect, toContext: context, withColor: stripColor, shadowColor: stripShadowColor, shadowOffset: shadowOffset, shadowBlurRadius: shadowBlurRadius)

        let calendarRect = CGRect(x: stripXAxis, y: 0, width: stripWidth, height: calendarStripHeight)
        context.setFillColor(UIColor(hexString: "#FEFEFE").cgColor)
        context.fill(calendarRect)
        
        //year strip
        let yearStripHeightPercnt = isLandscaped ? 9.09 : 9.25
        let yearStripHeight = templateInfo.screenSize.height*yearStripHeightPercnt/100
        sideStripBandHeight += yearStripHeight
        let yearStripYAxis =   yearStripHeight + calendarStripYAxis
        let yearStripRect = CGRect(x: stripXAxis, y:yearStripYAxis, width: stripWidth, height: 1)
        self.addBezierLineWith(rect: yearStripRect, toContext: context, withColor: stripColor, shadowColor: stripShadowColor, shadowOffset: shadowOffset, shadowBlurRadius: shadowBlurRadius)
        
        let yearRect = CGRect(x: stripXAxis, y: calendarStripYAxis, width: stripWidth, height: yearStripHeight)
        context.setFillColor(UIColor(hexString: "#E7E7E7").cgColor)
        context.fill(yearRect)
        
        //month strip
        let monthStripHeightPercnt = isLandscaped ? 6.23 : 6.01
        let monthStripHeight = templateInfo.screenSize.height*monthStripHeightPercnt/100
        var monthStripYAxis = monthStripHeight + yearStripYAxis
        var monthBGColorStripYAxis = yearStripYAxis
        for index in 0...11 {
            let monthStripRect = CGRect(x: stripXAxis, y:monthStripYAxis, width: stripWidth, height: 1)
            let monthRect = CGRect(x: stripXAxis, y: monthBGColorStripYAxis, width: stripWidth, height: monthStripHeight)
            context.setFillColor(UIColor(hexString: monthStripColors[index]).cgColor)
            context.fill(monthRect)
            self.addBezierLineWith(rect: monthStripRect, toContext: context, withColor: stripColor, shadowColor: stripShadowColor, shadowOffset: shadowOffset, shadowBlurRadius: shadowBlurRadius)
            monthStripYAxis += monthStripHeight
            sideStripBandHeight += monthStripHeight
            monthBGColorStripYAxis += monthStripHeight
        }
        
        // Extras strip
        let extraStripHeight = templateInfo.screenSize.height - sideStripBandHeight
        let extraBGColorStripYAxis = sideStripBandHeight
        let extrasRect = CGRect(x: stripXAxis, y: extraBGColorStripYAxis, width: stripWidth, height: extraStripHeight)
        context.setFillColor(UIColor(hexString: "#E7E7E7").cgColor)
        context.fill(extrasRect)
    }
    class func getTemplateBackgroundColor() -> UIColor {
        return UIColor(hexString: "#FEFEFE")
    }
    func addSpreadLineSeperator(toContext context : CGContext){
        let spredLinesImagePercent: CGFloat = 50.0
        let spredLinesX = CGFloat(templateInfo.screenSize.width)*spredLinesImagePercent/100
        if let spredLinesImage = UIImage(named: "spreadLines") {
            spredLinesImage.draw(at: CGPoint(x: spredLinesX - spredLinesImage.size.width/2, y: 0))
        }
    }
    
}

extension FTPlanner2024DiaryTemplateFormat {
    func getBezierBoxesBGColor() -> UIColor {
        return bezierBoxesBGColor
    }
    func getBezierlinesTintColor() -> UIColor {
        return bezierLinesTintColor
    }
}
