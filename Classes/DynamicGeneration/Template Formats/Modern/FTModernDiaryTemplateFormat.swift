//
//  FTModernDiaryTemplateFormat.swift
//  Noteshelf
//
//  Created by Narayana on 28/09/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

enum FTModernDiaryTemplateType {
    case year
    case monthly
    case weekly
    case daily
    
    var className : String {
        
        switch self {
        case .year:
            return "FTModernDiaryYearTemplate"
        case .monthly:
            return "FTModernDiaryMonthTemplate"
        case .weekly:
            return "FTModernDiaryWeekTemplate"
        case .daily:
            return "FTModernDiaryDayTemplate"
        }
    }
    
    var displayName : String {
        switch self {
        case .year:
            return "ModernDiaryYear"
        case .monthly:
            return "ModernDiaryMonth"
        case .weekly:
            return "ModernDiaryWeek"
        case .daily:
            return "ModernDiaryDay"
        }
    }
}

class FTModernDiaryTemplateFormat : FTDigitalDiaryTemplateFormat {
    var bezierBoxesBGColor : UIColor = UIColor(hexString: "#FFFFFF", alpha: 1.0)

    class func getFormatFrom(templateInfo : FTModernDiaryTemplateInfo) -> FTModernDiaryTemplateFormat {
        if let templateFormateClass = ClassFromString.getClass(fromString: templateInfo.templateType.className) as? FTModernDiaryTemplateFormat.Type {
            return templateFormateClass.init(templateInfo : templateInfo)
        }
        return FTModernDiaryTemplateFormat(templateInfo: templateInfo)
    }

    required init(templateInfo : FTModernDiaryTemplateInfo) {
        super.init(templateInfo: templateInfo)
    }

    func renderTemplate(context: CGContext) {
        let pageRect = CGRect(x: 0, y: 0, width: templateInfo.screenSize.width, height: templateInfo.screenSize.height)
        UIGraphicsBeginPDFPageWithInfo(pageRect, nil)
        context.setFillColor(self.templateInfo.getTemplateBackgroundColor().cgColor)
        context.fill(pageRect)
    }

    func addBezierBoxWithBorder( rect : CGRect, toContext context : CGContext, rectBGColor : UIColor, borderColor : UIColor, cornerRadius: CGFloat){
        let bezierpath = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        bezierpath.lineWidth = 1.0
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

    func addHorizantalBezierLine(rect:CGRect, toContext context : CGContext, withColor color : UIColor, bezierLineWidth : CGFloat = 1.0) {
        let  bezierLinePath = UIBezierPath()
        let  p0 = CGPoint(x: rect.origin.x, y: rect.origin.y)
        bezierLinePath.move(to: p0)
        let  p1 = CGPoint(x: rect.origin.x + rect.width , y: rect.origin.y)
        bezierLinePath.addLine(to: p1)
        bezierLinePath.lineWidth = bezierLineWidth
        bezierLinePath.lineCapStyle = .butt
        color.setStroke()
        context.addPath(bezierLinePath.cgPath)
        bezierLinePath.stroke()
    }

    func addVerticalBezierLine(rect:CGRect, toContext context : CGContext, withColor color : UIColor) {
       let bezierLinePath = UIBezierPath()
       let p0 = CGPoint(x: rect.origin.x, y: rect.origin.y)
       bezierLinePath.move(to: p0)
       let p1 = CGPoint(x: rect.minX , y: rect.minY + rect.height)
       bezierLinePath.addLine(to: p1)
       bezierLinePath.lineWidth = 1.0
       color.setStroke()
       context.addPath(bezierLinePath.cgPath)
       bezierLinePath.stroke()
   }

}
