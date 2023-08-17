//
//  FTGlobalSettingsOptions.swift
//  Noteshelf3
//
//  Created by Narayana on 06/01/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

enum FTNewSettingsOptions: String {
    case handwriting = "SettingOptionHandwriting"
    case stylus = "Settings"
    case cloudAndBackup = "CloudAndBackup"
    case whatsNew = "AboutOptionWhatsNew"
    case support = "Support"
    case aboutNoteshelf = "AboutNoteshelf"
    case settingsGeneral = "SettingsGeneral"
    case settingsAppearance = "SettingOptionTheme"
    case applePencil  = "SettingsApplePencil"
    case rateOnTheAppstore = "SettingsRateOnTheAppstore"
    case noteShelfHelp = "SettingsNoteShelfHelp"
    case developerOptions = "🛠 Developer Options"


    //General Settings View
    case Privacy = "GeneralSettingsPrivacy"
    case appearance = "GeneralSettingsAppearance"
    case showDateonShelf = "SettingShowDateOnShelf"
    case lockwithFaceidandPasscode = "lockwithfaceIDandPasscode"

}
enum FTGlobalSettingsOptions: String {
    // Section - 0
   // case general
    case appearance
    case applePencil
    case handwriting
    case cloudAndBackup

    // Section - 1
    case about
    case whatsNew
    case rateOnAppStore
    case noteshelfHelp

    //Section - 2
    case developerOptions

    var displayTitle:String{
        let title: FTNewSettingsOptions
        switch self {
//        case .general:
//            title = .settingsGeneral
        case .appearance:
            title = .settingsAppearance
        case .applePencil:
            title = .applePencil
        case .handwriting:
            title = .handwriting
        case .cloudAndBackup:
            title = .cloudAndBackup
        case .about:
            title = .aboutNoteshelf
        case .whatsNew:
            title = .whatsNew
        case .rateOnAppStore:
            title = .rateOnTheAppstore
        case .noteshelfHelp:
            title = .noteShelfHelp
        case .developerOptions:
            title = .developerOptions
        }
        return title.rawValue.localized
    }

    var imageName: String {
        let name: String
        switch self {
//        case .general:
//            name = "general"
        case .applePencil:
            name = "stylus"
        case .handwriting:
            name = "handWriting"
        case .cloudAndBackup:
            name = "cloudAndBackup"
        case .noteshelfHelp:
            name = "noteshelfHelp"
        case .about:
            name = "about"
        case .whatsNew:
            name = "whatsnew"
        case .rateOnAppStore:
            name = "rateOnAppstore"
        case .developerOptions:
            name = "beta_program"
        case .appearance:
            name = "appearance"
        }
        return "Settings/\(name)"
    }

    var accessoryType: UITableViewCell.AccessoryType {
        let accessoryType: UITableViewCell.AccessoryType
        switch self {
        case .noteshelfHelp, .rateOnAppStore:
            accessoryType = .none
        default:
            accessoryType = .disclosureIndicator
        }
        return accessoryType
    }
}
