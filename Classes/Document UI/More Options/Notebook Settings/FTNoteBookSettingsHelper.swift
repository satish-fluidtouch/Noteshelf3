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
    case defaultCell
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
    case gestures
    case noteShelfHelp
    
    func cellType() -> FTNoteBookSettingCellTye {
        var cellType = FTNoteBookSettingCellTye.toggle
        switch self {
        case .autoBackup, .autoLock, .hideUiInPresentMode, .allowHyperLinks,.evernoteSync :
            cellType = .toggle
        case .password, .stylus, .addToSiri :
            cellType = .disclosure
        case .scrolling:
            cellType = .custom
        case .gestures,.noteShelfHelp:
            cellType = .defaultCell
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
        case .gestures:
            title = "Gesture"
        case .noteShelfHelp:
            title = "SettingsNoteShelfHelp"
        }
        return title.localized
    }
    
    var eventName: String {
        let title: String
        switch self {
        case .autoBackup:
            title = "autobackup"
        case .password:
            title = FTNotebookEventTracker.nbk_moresettings_password_tap
        case .autoLock:
            title = FTNotebookEventTracker.nbk_moresettings_autolock_toggle
        case .stylus:
            title = FTNotebookEventTracker.nbk_moresettings_stylus_tap
        case .addToSiri:
            title = FTNotebookEventTracker.nbk_moresettings_addtisiri_tap
        case .scrolling:
            title = FTNotebookEventTracker.nbk_moresettings_scrolling_tap
        case .hideUiInPresentMode:
            title = FTNotebookEventTracker.nbk_moresettings_hideappUI_toggle
        case .allowHyperLinks:
            title = FTNotebookEventTracker.nbk_moresettings_hyperlinks_toggle
        case .evernoteSync:
            title = FTNotebookEventTracker.nbk_moresettings_synctoevernote_tap
        case .gestures:
            title = FTNotebookEventTracker.nbk_more_gestures_tap
        case .noteShelfHelp:
            title = FTNotebookEventTracker.nbk_more_help_tap
        }
        return title
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

