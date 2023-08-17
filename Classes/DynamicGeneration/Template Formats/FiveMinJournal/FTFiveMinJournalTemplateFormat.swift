//
//  FTFiveMinJournalTemplateFormat.swift
//  Noteshelf
//
//  Created by Ramakrishna on 05/07/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

import PDFKit

enum FTFiveMinJournalTemplateType {
    case calendar
    case year
    case monthly
    case daily
    case help
    case sample
    
    var className : String {
        
        switch self {
        case .calendar:
            return "FTFiveMinJournalCalendarTemplate"
        case .year:
            return "FTFiveMinJournalYearTemplate"
        case .monthly:
            return "FTFiveMinJournalMonthTemplate"
        case .daily:
            return "FTFiveMinJournalDayTemplate"
        case .help:
            return "FTFiveMinJournalHelpTemplate"
        case .sample:
            return "FTFiveMinJournalSampleTemplate"
        }
    }
    
    var displayName : String {
        switch self {
        case .calendar:
            return "FiveMinJournalCalendar"
        case .year:
            return "FiveMinDigitalDiaryYear"
        case .monthly:
            return "FiveMinJournalMonth"
        case .daily:
            return "FiveMinJournalDay"
        case .help:
            return "FiveMinJournalHelp"
        case .sample:
            return "FiveMinJournalSample"
        }
    }
}
class FTFiveMinJournalTemplateFormat : FTDigitalDiaryTemplateFormat {
    
    var bezierBoxesBGColor : UIColor = UIColor(hexString: "#E1E9E8", alpha: 1.0)
    
    class func getFormatFrom(templateInfo : FTFiveMinJournalTemplateInfo) -> FTFiveMinJournalTemplateFormat{
        if let templateFormateClass = ClassFromString.getClass(fromString: templateInfo.templateType.className) as? FTFiveMinJournalTemplateFormat.Type{
            return templateFormateClass.init(templateInfo : templateInfo)
        }
        return FTFiveMinJournalTemplateFormat(templateInfo: templateInfo)
    }
    
    required init(templateInfo : FTFiveMinJournalTemplateInfo){
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
}
