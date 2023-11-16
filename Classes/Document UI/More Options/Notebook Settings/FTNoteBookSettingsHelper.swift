//
//  FTNoteBookSettingsHelper.swift
//  Noteshelf3
//
//  Created by Sameer Hussain on 10/05/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

enum FTNoteBookSettingCellTye {
    case toggle
    case disclosure
    case custom
}

@objc enum FTNoteBookSettings: Int, CaseIterable {
    case autoBackup
    case password
    case autoLock
    case stylus
    case addToSiri
    case scrolling
    case hideUiInPresentMode
    case allowHyperLinks
    case evernoteSync
    
    func cellType() -> FTNoteBookSettingCellTye {
        var cellType = FTNoteBookSettingCellTye.toggle
        switch self {
        case .autoBackup, .autoLock, .hideUiInPresentMode, .allowHyperLinks,.evernoteSync :
            cellType = .toggle
        case .password, .stylus, .addToSiri :
            cellType = .disclosure
        case .scrolling:
            cellType = .custom
        }
        return cellType
    }
    
    func title() -> String {
        let title: String
        switch self {
        case .autoBackup:
            title = "notebookSettings.autoBackup"
        case .password:
            title = "notebookSettings.password"
        case .autoLock:
            title = "notebookSettings.disableAutoLock"
        case .stylus:
            title = "notebookSettings.stylus"
        case .addToSiri:
            title = "notebookSettings.addToSiri"
        case .scrolling:
            title = "notebookSettings.scrolling"
        case .hideUiInPresentMode:
            title = "notebookSettings.hideAppUIInPresentMode"
        case .allowHyperLinks:
            title = "notebookSettings.allowHyperlinks"
        case .evernoteSync:
            title = "EvernoteSync"
        }
        return title.localized
    }
}

enum FTNoteBookStylusSetting {
    case usePencil
    case pressureSensitivity
    case doubleTapActions
    case language
    case writingStyle
    
    func cellType() -> FTNoteBookSettingCellTye {
        var cellType = FTNoteBookSettingCellTye.toggle
        switch self {
        case .usePencil, .pressureSensitivity :
            cellType = .toggle
        case .language :
            cellType = .disclosure
        case .writingStyle, .doubleTapActions:
            cellType = .custom
        }
        return cellType
    }
    
    func title() -> String {
        var title = ""
        switch self {
        case .usePencil:
            title = NSLocalizedString("Use Apple Pencil", comment: "Use Apple Pencil")
        case .pressureSensitivity:
            title = NSLocalizedString("Pressure Sensitivity", comment: "Pressure Sensitivity")
        case .doubleTapActions:
            title = NSLocalizedString("Double - Tap Action", comment: "Double - Tap Action")
        case .language:
            title = NSLocalizedString("Language", comment: "Language")
        case .writingStyle:
            title = NSLocalizedString("Writing Style", comment: "Writing Style")
        }
        return title
    }
}

