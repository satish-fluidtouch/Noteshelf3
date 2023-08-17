//
//  FTNewSettingsConstant.swift
//  Noteshelf
//
//  Created by Matra on 10/01/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

let BGColor: UIColor = UIColor.appColor(.secondaryBG)

let settingsTitle = "Settings"
let FTEmptyDisplayName = "<Empty>";

let FTShelfShowDateChangeNotification = "FTShelfShowDateChangeNotification";

@objc class FTSettingsConstants: NSObject {
    @objc static let IndexPath_DocumentSettings = IndexPath(row: 0, section: 1);
    @objc static let IndexPath_StylusSettings = IndexPath(row: 2, section: 0);
    static let rowHeight = 44.0
    @objc static let SettingsStoryboard = FTSettingsConstants.Storyboard.Base.self
    class Storyboard {
        static let Base = storyboard(withName: "FTSettings")
    }

    @objc static let NotificationKey_StylusWillConnect = "StylusWillConnect"
    @objc static let NotificationKey_StylusDidConnect = "StylusDidConnect"
    @objc static let NotificationKey_StylusDidDisconnect = "StylusDidDisconnect"
    @objc static let NotificationKey_StylusDidBatteryLevelChange = "StylusDidBatteryLevelChange"
}

enum FTSettingsOptions: String {
    case theme = "SettingOptionTheme"
    case handwriting = "SettingOptionHandwriting"
    case stylus = "Settings"
    case cloudAndBackup = "CloudAndBackup"
    case advanced = "Advanced"
    case schoolwork = "SchoolWorkApp"
    case whatsNew = "AboutOptionWhatsNew"
    case freePaperCover = "SettingOptionCoverTemplate"
    case support = "Support"
    case aboutNoteshelf = "AboutNoteshelf"
    case betaProgram = "JoinOurBeta"
    case developerOptions = "🛠 Developer Options"

    static let all: [FTSettingsOptions] = [.theme,
                                           .handwriting,
                                           .stylus,
                                           .cloudAndBackup,
                                           .schoolwork,
                                           .advanced,
                                           .whatsNew,
                                           .freePaperCover,
                                           .support,
                                           .aboutNoteshelf];

    func image() -> UIImage? {
        switch self {
        case .theme:
            return UIImage(named: "theme")
        case .handwriting:
            return UIImage(named: "writing")
        case .stylus:
            return UIImage(named: "stylus")
        case .cloudAndBackup:
            return UIImage(named: "accounts")
        case .schoolwork:
            return UIImage(named: "schoolworksettings")
        case .advanced:
            return UIImage(named: "preferences")
        case .whatsNew:
            return UIImage(named: "whatsNew")
        case .freePaperCover:
            return UIImage(named: "welcome")
        case .support:
            return UIImage(named: "support")
        case .aboutNoteshelf:
            return UIImage(named: "noteshelfsmallicon")
        case .betaProgram:
            return UIImage(named: "beta_program")
        case .developerOptions:
            return UIImage(named: "beta_program")
        }
    }

    func segue() -> String {
        switch self {
        case .theme:
            return "SeguePushSettingOptionTheme"
        case .handwriting:
            return "SeguePushSettingOptionHandwriting"
        case .stylus:
            return "SeguePushSettingOptionStylus"
        case .cloudAndBackup:
            return "SeguePushSettingOptionCloudBackup"
        case .schoolwork:
            return "SeguePushInitialSchoolWork"
        case .advanced:
            return "SeguePushSettingOptionAdvanced"
        case .whatsNew:
            return "SeguePushSettingOptionWhatsNew"
        case .freePaperCover:
            return "SeguePushSettingOptionCoverTemplate"
        case .support:
            return "SeguePushSettingOptionSupport"
        case .aboutNoteshelf:
            return "SeguePushSettingOptionAbout"
        case .betaProgram:
            return "SeguePushSettingOptionBetaProgram"
        case .developerOptions:
            return "SeguePushSettingOptionDeveloper"
        }
    }
}

protocol NameObject {
    var className: String { get }
    static var className: String { get }
}

extension NameObject {
    var className: String {
        return String(describing: type(of: self))
    }

    static var className: String {
        return String(describing: self)
    }
}

extension NSObject: NameObject {}

enum SegueType: String {
    case initialSchoolworkSettings = "SeguePushInitialSchoolWork"
    case assignmentSchoolworkSettings = "SeguePushAssignmentSchoolWork"
    case initialToAssignment = "SeguePushInitialToAssignment"
    case support = "SeguePushSupport"
    case followUs = "SeguePushFollowUS"
    case developerOptions = "SeguePushDeveloperOptions"
}

enum AboutOptions: String {
//    case whatsNew = "AboutOptionWhatsNew"
    case visitWebsite = "AboutVisitNoteshelfWebsite"
    case rateOnAppStore = "AboutOptionRateOnAppStore"
    #if DEBUG || BETA
    case welcome = "Welcome"
    case MyScriptActivation = "MyScript - "
    #endif
    
    #if !targetEnvironment(macCatalyst)
        #if DEBUG || BETA
        static let all : [AboutOptions] = [.visitWebsite, .rateOnAppStore, .welcome]
        #else
            static let all : [AboutOptions] = [.visitWebsite, .rateOnAppStore]
        #endif
    #else
        #if DEBUG || BETA
        static let all : [AboutOptions] = [.visitWebsite, .welcome]
        #else
            static let all : [AboutOptions] = [.visitWebsite]
        #endif
    #endif
}

func storyboard(withName name: String) -> UIStoryboard {
    return UIStoryboard(name: name, bundle: nil)
}
