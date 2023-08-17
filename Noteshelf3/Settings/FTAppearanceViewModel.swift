//
//  FTAppearanceViewModel.swift
//  Noteshelf3
//
//  Created by Rakesh on 10/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTNewNotebook

enum FTShelfTheme: Int {
    case System,Light,Dark

    static var allThemes: [FTShelfTheme] {
        return [.System,.Light,.Dark];
    }

    var localizedString: String {
        let title: String
        switch(self) {
        case .System:
            title =  "appearance.useSystemTheme"
        case .Light:
            title =  "appearance.lightTheme"
        case .Dark:
            title =  "appearance.darkTheme"
        }
        return title.localized
    }
}

class FTAppearanceViewModel: NSObject {
    let appearanceHeader = "GeneralSettingsAppearance".localized
    let showDateonShelf = "SettingShowDateOnShelf".localized
}

