//
//  FTClassicDiaryTemplateFormat.swift
//  Noteshelf
//
//  Created by Ramakrishna on 03/08/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

enum FTClassicDiaryTemplateType {
    case calendar
    case year
    case month
    case week
    case day
    
    var className : String {
        
        switch self {
        case .calendar:
            return "FTClassicDiaryCalendarTemplate"
        case .year:
            return "FTClassicDiaryYearTemplate"
        case .month:
            return "FTClassicDiaryMonthTemplate"
        case .week:
            return "FTClassicDiaryWeekTemplate"
        case .day:
            return "FTClassicDiaryDayTemplate"
        }
    }
    
    var displayName : String {
        switch self {
        case .calendar:
            return "ClassicDiaryCalendar"
        case .year:
            return "ClassicDiaryYear"
        case .month:
            return "ClassicDiaryMonth"
        case .week:
            return "ClassicDiaryWeek"
        case .day:
            return "ClassicDiaryDay"
        }
    }
}
class FTClassicDiaryTemplateFormat : FTDigitalDiaryTemplateFormat {
    
    var bezierBoxesBGColor : UIColor = UIColor(hexString: "#FCFCF7", alpha: 1.0)
    
    class func getFormatFrom(templateInfo : FTClassicDiaryTemplateInfo) -> FTClassicDiaryTemplateFormat{
        if let templateFormateClass = ClassFromString.getClass(fromString: templateInfo.templateType.className) as? FTClassicDiaryTemplateFormat.Type{
            return templateFormateClass.init(templateInfo : templateInfo)
        }
        return FTClassicDiaryTemplateFormat(templateInfo: templateInfo)
    }
    
    required init(templateInfo : FTClassicDiaryTemplateInfo){
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
        return UIColor(hexString: "#FAFAEF")
    }
}
