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
    func generate() async throws -> FTDocumentInputInfo
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

    func generate() async throws -> FTDocumentInputInfo {
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

    func generate() async throws -> FTDocumentInputInfo {
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
                                          theme: self.theme,
                                          weekFormat: self.theme.weekFormat)
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

    func generate() async throws -> FTDocumentInputInfo {
        do {
            let safeAreaInsets = try await FTSafeAreaInsetsController.safeAreaInset(isLandscape: theme.customvariants?.isLandscape ?? false)
            let generator = FTDynamicTemplateGenerator.init(safeAreaInsets: safeAreaInsets, self.theme, self.generationType)
            let docInfo = FTDocumentInputInfo()
            docInfo.inputFileURL = generator.generate()
            docInfo.isTemplate = true
            docInfo.footerOption = self.theme.footerOption
            docInfo.pageProperties = generator.pageProperties;
            return docInfo
        }
        catch {
            throw NSError(domain: "com.fluidtouch.tempaltes", code:-100,userInfo: [NSLocalizedDescriptionKey : "error in generation logic FTAutoDynamicTemplateGenerator"])
        }
    }
}

private class FTAutoStoreTemplateGenerator: NSObject, FTAutoTemplateGeneratorProtocol {
    private var theme: FTStoreTemplatePaperTheme

    required init(withTheme: FTTheme) {
        self.theme = withTheme as! FTStoreTemplatePaperTheme
    }

    func generate() async throws -> FTDocumentInputInfo {
        do {
            let safeAreaInsets = try await FTSafeAreaInsetsController.safeAreaInset(isLandscape: theme.customvariants!.isLandscape)
            let generator = FTStoreTemplateGenerator.init(safeAreaInsets: safeAreaInsets, theme: theme)
            let docInfo = FTDocumentInputInfo()
            docInfo.inputFileURL = theme.themeTemplateURL()
            docInfo.isTemplate = true
            docInfo.footerOption = self.theme.footerOption
            if let lineHeight = self.theme.lineHeight {
                docInfo.pageProperties.lineHeight = lineHeight
            }
            return docInfo
        }
        catch {
            throw NSError(domain: "com.fluidtouch.tempaltes", code:-100,userInfo: [NSLocalizedDescriptionKey : "error in generation logic FTAutoStoreTemplateGenerator"])
        }
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

 class FTSafeAreaInsetsController: UIViewController {
    #if NS2_SIRI_APP || NOTESHELF_ACTION
     static func safeAreaInset(isLandscape: Bool) async throws -> UIEdgeInsets {
       return UIEdgeInsets.zero
     }
    #else
    static func safeAreaInset(isLandscape: Bool) async throws -> UIEdgeInsets {
        guard let window = UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .compactMap({$0 as? UIWindowScene})
            .first?.windows
            .filter({$0.isKeyWindow}).first else {
            return .zero
        }

        var safeAreaInsets: UIEdgeInsets = window.safeAreaInsets

        guard let rootController = window.rootViewController else {
            return safeAreaInsets
        }

        let curValue: UIInterfaceOrientation = window.windowScene?.interfaceOrientation ?? .portrait
        var keyToFetch: String = !isLandscape ? UIEdgeInsets.SafeAreaPortraitKey : UIEdgeInsets.SafeAreaLandscapeKey

        if nil == UserDefaults.standard.value(forKey: keyToFetch) {
            UserDefaults.standard.set(safeAreaInsets.stringValue, forKey: keyToFetch)
            UserDefaults.standard.synchronize()
        }

        if(isLandscape && curValue.isPortrait) {
            keyToFetch = UIEdgeInsets.SafeAreaLandscapeKey
        }
        else if(!isLandscape && curValue.isLandscape) {
            keyToFetch = UIEdgeInsets.SafeAreaPortraitKey
        }

        if let val = UserDefaults.standard.value(forKey: keyToFetch) as? String {
            safeAreaInsets = UIEdgeInsets(string: val)
            return safeAreaInsets
        }

        let controller = FTSafeAreaInsetsController()
        controller.currentOrientation = curValue
        controller.modalPresentationStyle = .overFullScreen
        controller.view.backgroundColor = .clear

        return try await withCheckedThrowingContinuation({ continuation in
            rootController.present(controller, animated: false) {
                safeAreaInsets = rootController.view.safeAreaInsets
                UserDefaults.standard.set(safeAreaInsets.stringValue, forKey: keyToFetch)
                UserDefaults.standard.synchronize()
                controller.dismiss(animated: false, completion: nil)
                continuation.resume(returning: safeAreaInsets)
            }
        })
    }

    private var currentOrientation : UIInterfaceOrientation = .unknown

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return currentOrientation.isLandscape ? .portrait : .landscape
    }
#endif
}
