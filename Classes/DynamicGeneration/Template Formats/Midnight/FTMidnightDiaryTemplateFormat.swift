//
//  FTMidnightThemeFormat.swift
//  Beizerpaths
//
//  Created by Ramakrishna on 05/05/21.
//

import PDFKit
import FTStyles

enum FTDigitalDiaryTemplateType {
    case yearly
    case monthly
    case weekly
    case daily
    case priorities
    case notes
    case iPadLandscapeDaily
    
    var className : String {
        
        switch self {
        case .yearly:
            return "FTDigitalDiaryYearTemplate"
        case .monthly:
            return "FTMidnightDiaryMonthTemplate"
        case .weekly:
            return "FTMidnightDiaryWeekTemplate"
        case .daily:
            return "FTMidnightDiaryDayTemplate"
        case .priorities:
            return "FTMidnightDiaryPrioritiesTemplate"
        case .notes:
            return "FTMidnightDiaryNotesTemplate"
        case .iPadLandscapeDaily:
            return "FTMidnightDiaryLandscapeDayTemplate"
        }
    }
    
    var displayName : String {
        switch self {
        case .yearly:
            return "MidnightDiaryYear"
        case .monthly:
            return "MidnightDiaryMonth"
        case .weekly:
            return "MidnightDiaryWeek"
        case .daily:
            return "MidnightDiaryDaily"
        case .priorities:
            return "MidnightDiaryPriorities"
        case .notes:
            return "MidnightDiaryNotes"
        case .iPadLandscapeDaily:
            return "MidnightDiaryLandscapeDaily"
        }
    }
}
class FTDigitalDiaryTemplateFormat : NSObject {
    var templateInfo : FTDigitalDiaryInfo
    init(templateInfo : FTDigitalDiaryInfo) {
        self.templateInfo = templateInfo
    }
    func addBezierPathWithRect( rect : CGRect, toContext context : CGContext, rectBGColor : UIColor){
        let bezierpath = UIBezierPath(roundedRect: rect, cornerRadius: 8.0)
        context.saveGState()
        context.addPath(bezierpath.cgPath)
        context.translateBy(x: 0, y: CGFloat(templateInfo.screenSize.height))
        context.scaleBy(x: 1, y: -1)
        context.setFillColor(rectBGColor.cgColor)
        context.fillPath()
        context.restoreGState()
        UIColor.black.setStroke()
        context.strokePath()
    }
    func addBezierBoxWithBorder( rect : CGRect, toContext context : CGContext, rectBGColor : UIColor, borderColor : UIColor){
        let bezierpath = UIBezierPath(roundedRect: rect, cornerRadius: 8.0)
        bezierpath.lineWidth = 1.0
        context.addPath(bezierpath.cgPath)
        context.saveGState()
        borderColor.setStroke()
        context.strokePath()
        rectBGColor.setFill()
        bezierpath.fill()
        //context.setFillColor(UIColor.green.cgColor)
        //rectBGColor.setFill()
        //context.fillPath()
        context.translateBy(x: 0, y: CGFloat(templateInfo.screenSize.height))
        context.scaleBy(x: 1, y: -1)
        
        //context.setFillColor(rectBGColor.cgColor)
        context.restoreGState()
        
    }
    func addBorderToBezierPathWith(rect : CGRect, toContext context : CGContext, borderWidth : CGFloat,borderColor : UIColor){
        let  bezierLinePath = UIBezierPath(roundedRect: rect,cornerRadius: 6.0)
        bezierLinePath.lineWidth = borderWidth
        context.addPath(bezierLinePath.cgPath)
        borderColor.setStroke()
        context.strokePath()
    }
    func addBezierBoxWith(rect : CGRect, toContext context : CGContext, borderWidth : CGFloat, borderColor : UIColor){
        let  bezierLinePath = UIBezierPath(rect: rect)
        bezierLinePath.lineWidth = borderWidth
        context.addPath(bezierLinePath.cgPath)
        borderColor.setStroke()
        context.strokePath()
    }
    func addBezierLineWith(rect : CGRect, toContext context : CGContext, borderWidth : CGFloat, borderColor : UIColor){
        let  bezierLinePath = UIBezierPath()
        let  p0 = CGPoint(x: rect.origin.x, y: rect.origin.y)
        bezierLinePath.move(to: p0)
        let  p1 = CGPoint(x: rect.minX  , y: rect.minY + rect.height)
        bezierLinePath.addLine(to: p1)
        bezierLinePath.lineWidth = 1.0
        borderColor.setStroke()
        context.addPath(bezierLinePath.cgPath)
        bezierLinePath.stroke()
    }
    func renderTextWith(rect : CGRect,text : String, MaxFontSize : CGFloat, minFointSize : CGFloat){
        let font = UIFont.montserratFont(for: .extraBold, with: MaxFontSize)
        let newFontSize = UIFont.getScaledFontSizeFor(font: font, screenSize: templateInfo.screenSize, minPointSize: minFointSize)
        let textAttribute: [NSAttributedString.Key : Any] = [.font : UIFont.montserratFont(for: .bold, with: newFontSize),
                                                             NSAttributedString.Key.kern : 0.0,
                                                             .foregroundColor : UIColor(red: 229/255, green: 229/255, blue: 229/255, alpha: 1.0)]
        let titleString = NSMutableAttributedString(string: text, attributes: textAttribute)
        let location = CGPoint(x: rect.origin.x + 10, y: rect.origin.y + 9)
        titleString.draw(at: location)
    }
    func addBezierDashedlinePathWith(rect:CGRect, toContext context : CGContext, withColor color : UIColor){
        let  bezierLinePath = UIBezierPath()
        let  p0 = CGPoint(x: rect.origin.x, y: rect.origin.y)
        bezierLinePath.move(to: p0)
        let  p1 = CGPoint(x: rect.origin.x + rect.width , y: rect.origin.y)
        bezierLinePath.addLine(to: p1)
        let  dashes: [ CGFloat ] = [4,3]
        bezierLinePath.setLineDash(dashes, count: dashes.count, phase: 0.0)
        bezierLinePath.lineWidth = 1.0
        bezierLinePath.lineCapStyle = .butt
        //UIColor(red: 229/255, green: 229/255, blue: 229/255, alpha: 0.2).setStroke()
        color.setStroke()
        context.addPath(bezierLinePath.cgPath)
        bezierLinePath.stroke()
    }
    func addBezierlinePathWith(rect:CGRect, toContext context : CGContext, withColor color : UIColor){
        let  bezierLinePath = UIBezierPath()
        let  p0 = CGPoint(x: rect.origin.x, y: rect.origin.y)
        bezierLinePath.move(to: p0)
        let  p1 = CGPoint(x: rect.origin.x + rect.width , y: rect.origin.y)
        bezierLinePath.addLine(to: p1)
        bezierLinePath.lineWidth = 1.0
        color.setStroke()
        context.addPath(bezierLinePath.cgPath)
        bezierLinePath.stroke()
    }
}
class FTMidnightDiaryTemplateFormat : FTDigitalDiaryTemplateFormat {
        
    var bezierBoxesBGColor : UIColor = UIColor(red: 40/255, green: 46/255, blue: 57/255, alpha: 1.0)
    
    class func getFormatFrom(templateInfo : FTMidnightDiaryInfo) -> FTMidnightDiaryTemplateFormat{
        if let templateFormateClass = ClassFromString.getClass(fromString: templateInfo.templateType.className) as? FTMidnightDiaryTemplateFormat.Type{
            return templateFormateClass.init(templateInfo : templateInfo)
        }
        return FTMidnightDiaryTemplateFormat(templateInfo: templateInfo)
    }
    
    required init(templateInfo : FTMidnightDiaryInfo){
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
    class func getTemplateBackgroundColor() -> UIColor {
        return UIColor(red: 40/255, green: 46/255, blue: 57/255, alpha: 1.0)
    }
}
