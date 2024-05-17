//
//  FTAutoTemplateGenerator.swift
//  Noteshelf
//
//  Created by sreenu cheedella on 16/01/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

enum FTGenrationType: String {
    case thumbnail
    case template
    case preview
}
enum FTTemplateType : Int {
    case customTemplate = 0
    case dairyTemplate = 1
    case autoTemplate = 2
    case storeTemplate = 3
}

protocol FTAutoTemplateGeneratorProtocol {
    init(withTheme: FTTheme)
    func generate() -> FTDocumentInputInfo
}

class FTAutoTemplateGenerator: NSObject {
    static func autoTemplateGenerator(theme : FTTheme, generationType: FTGenrationType) -> FTAutoTemplateGeneratorProtocol {
        guard let templateType = FTTemplateType.init(rawValue:theme.dynamicId) else {
            fatalError("Invalid dynamic id passed")
        }
        switch templateType {
        case .customTemplate:
            return FStandardTemplateDiaryGenerator(withTheme: theme)
        case .dairyTemplate:
            #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
            return FTAutoTemplateDiaryGenerator(withTheme: theme)
            #else
            let dynamicTemplate = FTAutoDynamicTemplateGenerator(withTheme: theme)
            dynamicTemplate.generationType = generationType
            return dynamicTemplate
            #endif
        case .autoTemplate:
            let dynamicTemplate = FTAutoDynamicTemplateGenerator(withTheme: theme)
            dynamicTemplate.generationType = generationType
            return dynamicTemplate
        case .storeTemplate:
            return FTAutoStoreTemplateGenerator.init(withTheme: theme)
        }
    }
}
private class FStandardTemplateDiaryGenerator : NSObject,FTAutoTemplateGeneratorProtocol {
    private var theme : FTPaperTheme

    required init(withTheme inTheme: FTTheme) {
        theme = inTheme as! FTPaperTheme
    }

    func generate() -> FTDocumentInputInfo {
        let docInfo = FTDocumentInputInfo()
        docInfo.inputFileURL = theme.themeTemplateURL()
        docInfo.isTemplate = true
        docInfo.footerOption = theme.footerOption
        if let lineHeight = theme.lineHeight {
            docInfo.pageProperties.lineHeight = lineHeight;
        }
        return docInfo
    }
}

#if !NS2_SIRI_APP && !NOTESHELF_ACTION
private class FTAutoTemplateDiaryGenerator: NSObject,FTAutoTemplateGeneratorProtocol {
    private var theme : FTAutoTemlpateDiaryTheme
    deinit {
        #if DEBUG
            debugPrint("deinit \(self.classForCoder)")
        #endif
    }
    required init(withTheme inTheme: FTTheme) {
        theme = inTheme as! FTAutoTemlpateDiaryTheme
    }

    func generate() -> FTDocumentInputInfo {
        var startDate = theme.startDate
        var endDate = theme.endDate

        if startDate == nil || endDate == nil {
            if FTUserDefaults.getDiaryRecentStartMonth() != 0,
               FTUserDefaults.getDiaryRecentStartYear() != 0,
               FTUserDefaults.getDiaryRecentEndMonth() != 0,
               FTUserDefaults.getDiaryRecentEndYear() != 0{
                // retreiving month and year instead of previous dates format
                let calender = NSCalendar.gregorian()
                startDate = calender.date(month: FTUserDefaults.getDiaryRecentStartMonth(), year: FTUserDefaults.getDiaryRecentStartYear())!
                endDate = calender.date(month: FTUserDefaults.getDiaryRecentEndMonth(), year: FTUserDefaults.getDiaryRecentEndYear())!
            }
            else if let _startDate = FTUserDefaults.getDiaryRecentStartDate(), let _endDate = FTUserDefaults.getDiaryRecentEndDate(){
                // transfering already existed month and year data from startDate, endDate to newly created month, year persistance form
                FTUserDefaults.saveDiaryRecentStartMonth(_startDate.month())
                FTUserDefaults.saveDiaryRecentEndMonth(_endDate.month())
                FTUserDefaults.saveDiaryRecentStartYear(_startDate.year())
                FTUserDefaults.saveDiaryRecentEndYear(_endDate.year())
                UserDefaults.standard.removeObject(forKey: DigitalDiaryStartDateKey)
                UserDefaults.standard.removeObject(forKey: DigitalDiaryEndDateKey)
                let calender = NSCalendar.gregorian()
                startDate = calender.date(month: FTUserDefaults.getDiaryRecentStartMonth(), year: FTUserDefaults.getDiaryRecentStartYear())!
                endDate = calender.date(month: FTUserDefaults.getDiaryRecentEndMonth(), year: FTUserDefaults.getDiaryRecentEndYear())!
            }
            else {
                let currentdate = Date()
                let month = currentdate.month()
                let year = currentdate.year()

                FTUserDefaults.saveDiaryRecentStartMonth(month)
                FTUserDefaults.saveDiaryRecentStartYear(year)

                let calendar = NSCalendar.gregorian()
                startDate = calendar.date(month: month, year: year)!
                endDate = calendar.date(byAdding: .month, value: 11, to: startDate!)
                FTUserDefaults.saveDiaryRecentEndMonth(endDate!.month())
                FTUserDefaults.saveDiaryRecentEndYear(endDate!.year())
            }
        }

        let formatInfo = FTYearFormatInfo(startDate: startDate!,
                                          endDate: endDate!,
                                          theme: self.theme)
        let generator = FTDairyGenerator.init(self.theme,format: FTDairyFormat.getFormat(formatInfo: formatInfo), formatInfo: formatInfo)

        let docInfo = FTDocumentInputInfo()
        docInfo.inputFileURL = generator.generate()
        docInfo.isTemplate = true
        docInfo.footerOption = self.theme.footerOption
        docInfo.backgroundColor = FTDairyFormat.getFormat(formatInfo: formatInfo).getTemplateBackgroundColor()
        docInfo.diaryPagesInfo = generator.diaryPagesInfo
        if let lineHeight = self.theme.lineHeight {
            docInfo.pageProperties.lineHeight = lineHeight
        }
        return docInfo
    }
}
#endif

private class FTAutoDynamicTemplateGenerator: NSObject, FTAutoTemplateGeneratorProtocol {
    private var theme: FTDynamicTemplateTheme
    var generationType: FTGenrationType = .template
    required init(withTheme: FTTheme) {
        self.theme = withTheme as! FTDynamicTemplateTheme
    }

    func generate() -> FTDocumentInputInfo {
        let generator = FTDynamicTemplateGenerator(self.theme, self.generationType)
        let docInfo = FTDocumentInputInfo()
        docInfo.inputFileURL = generator.generate()
        docInfo.isTemplate = true
        docInfo.footerOption = self.theme.footerOption
        docInfo.pageProperties = generator.pageProperties;
        return docInfo
    }
}

private class FTAutoStoreTemplateGenerator: NSObject, FTAutoTemplateGeneratorProtocol {
    private var theme: FTStoreTemplatePaperTheme

    required init(withTheme: FTTheme) {
        self.theme = withTheme as! FTStoreTemplatePaperTheme
    }

    func generate() -> FTDocumentInputInfo {
        let docInfo = FTDocumentInputInfo()
        docInfo.inputFileURL = theme.themeTemplateURL()
        docInfo.isTemplate = true
        docInfo.footerOption = self.theme.footerOption
        if let lineHeight = self.theme.lineHeight {
            docInfo.pageProperties.lineHeight = lineHeight
        }
        return docInfo
    }
}

private extension UIEdgeInsets {
    static let SafeAreaLandscapeKey = "SafeArea_Landscape"
    static let SafeAreaPortraitKey = "SafeArea_Portrait"

    var stringValue: String {
        return NSCoder.string(for: self)
    }

    init(string: String) {
        self = NSCoder.uiEdgeInsets(for: string)
    }
}
