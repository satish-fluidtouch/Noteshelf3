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
    let toDoColors : [String] = ["#FDDD9B","#F0CBC2","#A7E8DB","#80CCCB","#F0D295","#EBA899","#F0CBC2"]
    let monthStripColors : [String] = ["#80CCCB","#EBA899","#F0D295","#80CCCB","#EBA899","#F0D295"]
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
    class func getTemplateBackgroundColor() -> UIColor {
        return UIColor(hexString: "#FEFEFE")
    }
    func addSpreadLineSeperator(toContext context : CGContext){
        let spredLinesImagePercent: CGFloat = 50.0
        let spredLinesX = CGFloat(templateInfo.screenSize.width)*spredLinesImagePercent/100
        if let spredLinesImage = UIImage(named: "spreadLines")?.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 9, bottom: 0, right: 8),resizingMode: .stretch) {
            spredLinesImage.draw(in: CGRect(x: spredLinesX - spredLinesImage.size.width/2, y: 0, width: spredLinesImage.size.width, height: templateInfo.screenSize.height))
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
