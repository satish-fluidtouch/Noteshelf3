//
//  FTConvertToViewModel.swift
//  Noteshelf3
//
//  Created by Narayana on 15/02/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

enum FTConvertToTextViewModel: Int, CaseIterable {
    case fontSize
    case language
    case customDictionary

    var displayName: String {
        let name: String
        switch self {
        case .fontSize:
            name = "FontSize".localized
        case .language:
            name = "Language".localized
        case .customDictionary:
            name = "convertToText.customDictionary".localized
        }
        return name
    }

    var displayInfo: String {
        var info: String = ""
        switch self {
        case .fontSize:
           let fontPref = FTConvertFontSize.getFontPreference(prefValue: FTConvertToTextViewModel.convertPreferredFont)
            info = fontPref.displayTitle
        case .language:
            info = FTConvertToTextViewModel.convertPreferredLanguage.nativeDisplayName
        default:
            break
        }
        return info
    }

    var detailViewController: UIViewController {
        let requiredVc: UIViewController
        switch self {
        case .fontSize, .language:
            requiredVc = FTConvertPreferencesViewController(nibName: "FTConvertPreferencesViewController", bundle: nil)
        case .customDictionary:
            requiredVc = FTCustomDictViewController(nibName: "FTCustomDictViewController", bundle: nil)
        }
        return requiredVc
    }

    static var convertPreferredFont: String {
        if let preferredFont = UserDefaults.standard.string(forKey: "convertPreferredFont") {
            return preferredFont
        }
        let fontSizeType = FTConvertFontSize.fitToSelection.displayTitle
        UserDefaults.standard.set(fontSizeType, forKey: "convertPreferredFont")
        UserDefaults.standard.synchronize()
        return fontSizeType
    }

    static var convertPreferredLanguage: String {
        get {
            if let languageCode = UserDefaults.standard.value(forKey: "convertPreferredLanguage") as? String{
                return languageCode
            }

            if FTNotebookRecognitionHelper.shouldProceedRecognition {
                UserDefaults.standard.set(FTLanguageResourceManager.shared.currentLanguageCode, forKey: "convertPreferredLanguage")
            }
            else{
                UserDefaults.standard.set("en_US", forKey: "convertPreferredLanguage")
            }
            UserDefaults.standard.synchronize()
            return (UserDefaults.standard.value(forKey: "convertPreferredLanguage") as! String)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "convertPreferredLanguage")
            UserDefaults.standard.synchronize()
        }
    }
}

enum FTConvertFontSize: Int, CaseIterable {
    case `default`
    case fitToSelection

    var displayTitle: String {
        let title: String
        switch self {
        case .default:
            title = NSLocalizedString("DefaultKey", comment: "Default")
        case .fitToSelection:
            title = NSLocalizedString("FitToSelection", comment: "Fit to Selection")
        }
        return title
    }

    static func getFontPreference(prefValue: String) -> FTConvertFontSize {
        var fontPref: FTConvertFontSize = .default
        if prefValue == FTConvertFontSize.fitToSelection.displayTitle {
            fontPref = .fitToSelection
        }
        return fontPref
    }

    var preferenceDetails: String {
        let details: String
        switch self {
        case .default:
            details = NSLocalizedString("DefaultDetail", comment: "Default font size of the text tool")
        case .fitToSelection:
            details = NSLocalizedString("FitToSelectionDetail", comment: "Determine font size based on handwriting size")
        }
        return details
    }
}
