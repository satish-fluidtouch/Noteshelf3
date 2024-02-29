//
//  FTNotebookOption.swift
//  Noteshelf
//
//  Created by Akshay on 08/02/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import Intents

enum FTNotebookMoreOptionType {
    case basic
    case toggleAccessory
    case disclosure
}

protocol FTNotebookMoreOption {
    var type: FTNotebookMoreOptionType { get }
    var localizedTitle: String { get }
    var identifier: String { get }
    var localizedSubtitle: String? { get }
    var imageIcon: FTIcon { get }
    var isViewed: Bool { get set }
    var eventName: String {get}
}

extension UserDefaults {
    static func registerNotebookSettingDefaultsForFreshInstall() {
        UserDefaults.standard.set(true, forKey: "\(FTNotebookOptionGesture().identifier)_viewed")
        UserDefaults.standard.synchronize()
    }
}

protocol FTNotebookOptionToggle: FTNotebookMoreOption {
    var isToggleTurnedOn: Bool { get }

    func updateToggleStatus(with isOn: Bool)
}

extension FTNotebookMoreOption {
    var localizedSubtitle: String? {
        return nil
    }
}

extension FTNotebookMoreOption {
    var isViewed: Bool {
        get {
            UserDefaults.standard.register(defaults: ["\(identifier)_viewed": true])
            return UserDefaults.standard.bool(forKey: "\(identifier)_viewed")
        }
        set {}
    }
}

class FTNotebookOptionChangeTemplate: FTNotebookMoreOption {
    var eventName: String {
        return FTNotebookEventTracker.nbk_more_changetemplate_tap
    }
    
    var type: FTNotebookMoreOptionType {
        return .basic
    }
    var imageIcon: FTIcon {
        return FTIcon.docText
    }
    var localizedTitle: String {
        return NSLocalizedString("ChangeTemplate", comment: "Change Template")
    }
    var identifier: String {
        return "changeTemplate"
    }
}

class FTNotebookOptionTag: FTNotebookMoreOption {
    var eventName: String {
        return ""
    }
    
    var type: FTNotebookMoreOptionType {
        return .disclosure
    }
    
    var imageIcon: FTIcon {
        return .tags
    }
    
    var identifier: String {
           return "tag"
       }
    
    var localizedTitle: String {
        return NSLocalizedString("Tag", comment: "Tag")
    }
}

class FTNotebookOptionSaveAsTemplate: FTNotebookMoreOption {
    var eventName: String {
        return FTNotebookEventTracker.nbk_more_saveastemplate_tap
    }
    
    var type: FTNotebookMoreOptionType {
        return .basic
    }
    
    var imageIcon: FTIcon {
        return .saveAsTemplate
    }
    
    var identifier: String {
           return "saveAsTemplate"
       }
    
    var localizedTitle: String {
        return "SaveAsTemplate".localized
    }
}

class FTNotebookOptionRotate: FTNotebookMoreOption {
    var eventName: String {
        return FTNotebookEventTracker.nbk_more_rotatepage_tap
    }
    
    var type: FTNotebookMoreOptionType {
        return .disclosure
    }
    
    var imageIcon: FTIcon {
        return .rotateRight
    }
    
    var identifier: String {
           return "rotate"
    }
    
    var localizedTitle: String {
        return NSLocalizedString("Rotate Page", comment: "Rotate Page")
    }

    private var angle: UInt

    init(with angle: UInt) {
        self.angle = angle
    }
}
class FTNotebookOptionGoToPage: FTNotebookMoreOption {
    var eventName: String {
        return FTNotebookEventTracker.nbk_more_gotopage_tap
    }
    
    var type: FTNotebookMoreOptionType {
        return .basic
    }
    
    var imageIcon: FTIcon {
        return .textMagnifyingglass
    }
    
    var localizedTitle: String {
        return NSLocalizedString("GoToPage", comment: "Go to Page")
    }
    
    var localizedSubtitle: String? {
        return subtitle
    }
    
    var identifier: String {
        return "goToPage"
    }
    
    private var subtitle: String
    
    init(with string: String) {
        self.subtitle = string
    }
}

class FTNotebookOptionRotationAngle: FTNotebookMoreOption {
    var eventName: String {
        let stringToReturn : String
        switch rotation {
        case .nintetyClockwise:
            stringToReturn = FTNotebookEventTracker.nbk_more_rotate_clockwise_tap
        case .nintetyCounterClockwise:
            stringToReturn = FTNotebookEventTracker.nbk_more_rotate_anticlockwise_tap
        case .oneEighty:
            stringToReturn = FTNotebookEventTracker.nbk_more_rotate_180_tap
        }
        return stringToReturn
    }
    
    var type: FTNotebookMoreOptionType {
        return .basic
    }
    
    var imageIcon: FTIcon {
        switch rotation {
        case .nintetyClockwise:
            return .rotateRight
        case .nintetyCounterClockwise:
            return .rotateLeft
        case .oneEighty:
            return .arrowCounterclockwise
        }
    }
    
    var localizedTitle: String {
        return rotation.localizedTitle
    }
    
    var identifier: String {
        return "rotationAngle"
    }

    private(set) var rotation: FTPageRotation

    init(rotation: FTPageRotation) {
        self.rotation = rotation
    }

}

class FTNotebookOptionGetInfo: FTNotebookMoreOption {
    var eventName: String {
        return FTNotebookEventTracker.nbk_more_getinfo_tap
    }
    
    var type: FTNotebookMoreOptionType {
        return .disclosure
    }
    var imageIcon: FTIcon {
        return .infoCircle
    }
    var localizedTitle: String {
        return NSLocalizedString("GetInfo", comment: "Get Info")
    }
    
    var identifier: String {
        return "info"
    }
}

class FTNotebookOptionSettings: FTNotebookMoreOption {
    var eventName: String {
        return FTNotebookEventTracker.nbk_more_moresettings_tap
    }
    
    var type: FTNotebookMoreOptionType {
        return .disclosure
    }
    var imageIcon: FTIcon {
        return .gearShape
    }
    var localizedTitle: String {
        return "notebook.settings.moresettings".localized
    }
    
    var identifier: String {
        return "setting"
    }
}

class FTNotebookOptionShare: FTNotebookMoreOption {
    var eventName: String {
        return FTNotebookEventTracker.nbk_more_share_tap
    }
    
    var type: FTNotebookMoreOptionType {
        return .disclosure
    }
    var imageIcon: FTIcon {
        return .squareAarrowUp
    }
    var localizedTitle: String {
        return NSLocalizedString("Share", comment: "Share")
    }
    
    var identifier: String {
           return "share"
       }
}

class FTNotebookOptionGesture: FTNotebookMoreOption {
    var eventName: String {
        return FTNotebookEventTracker.nbk_more_gestures_tap
    }
    
    var type: FTNotebookMoreOptionType {
        return .basic
    }
    var imageIcon: FTIcon {
        return .handTap
    }
    var localizedTitle: String {
        return NSLocalizedString("Gesture", comment: "Gestures")
    }
    
    var identifier: String {
        return "gestures"
    }
    
    var isViewed: Bool {
       get {
           UserDefaults.standard.register(defaults: ["\(identifier)_viewed": false])
           return UserDefaults.standard.bool(forKey: "\(identifier)_viewed")
       }
       
       set {
           UserDefaults.standard.set(newValue, forKey: "\(identifier)_viewed")
       }
    }
}

class FTNotebookOptionHelp: FTNotebookMoreOption {
    var eventName: String {
        return FTNotebookEventTracker.nbk_more_help_tap
    }
    
    var type: FTNotebookMoreOptionType {
        return .basic
    }
    var imageIcon: FTIcon {
        return .questionmarkCircle
    }
    var localizedTitle: String {
        return NSLocalizedString("SettingsNoteShelfHelp", comment: "Settings NoteShelf Help")
    }
    
    var identifier: String {
        return "help"
    }
    
    var isViewed: Bool {
       get {
           UserDefaults.standard.register(defaults: ["\(identifier)_viewed": false])
           return UserDefaults.standard.bool(forKey: "\(identifier)_viewed")
       }
       
       set {
           UserDefaults.standard.set(newValue, forKey: "\(identifier)_viewed")
       }
    }
}

class FTNotebookOptionZoomBox : FTNotebookOptionToggle {
    var eventName: String {
        return FTNotebookEventTracker.nbk_more_zoombox_tap
    }
    
    var type: FTNotebookMoreOptionType {
        return .basic
    }
    var imageIcon: FTIcon {
        return .rectangleTextMagnifyingglass
    }
    var localizedTitle: String {
        return NSLocalizedString("ZoomBox", comment: "Zoom Box")
    }
    var identifier: String {
        return "zoomBox"
    }
    var isToggleTurnedOn: Bool {
        return isSwitchOn
    }

    func updateToggleStatus(with isOn: Bool) {
        self.isSwitchOn = !isOn
    }

    fileprivate var isSwitchOn: Bool

    init(isEnabled: Bool) {
        self.isSwitchOn = isEnabled
    }
}

class FTNotebookOptionPresentMode : FTNotebookMoreOption {
    var eventName: String {
        return FTNotebookEventTracker.nbk_more_present_tap
    }
    
    var type: FTNotebookMoreOptionType {
        return .basic
    }
    
    var localizedTitle: String {
        return "customizeToolbar.present".localized
    }
    
    var identifier: String {
        return "PresentMode"
    }
    
    var imageIcon: FTIcon {
        return .present
    }
    var isViewed: Bool {
       get {
           UserDefaults.standard.register(defaults: ["\(identifier)_viewed": false])
           return UserDefaults.standard.bool(forKey: "\(identifier)_viewed")
       }
       
       set {
           UserDefaults.standard.set(newValue, forKey: "\(identifier)_viewed")
       }
    }
}

class FTCustomizeToolbarSetting: FTNotebookMoreOption {
    var eventName: String {
        return ""
    }
    
    var type: FTNotebookMoreOptionType {
        return .basic
    }

    var imageIcon: FTIcon {
        return .customizeToolBar
    }

    var localizedTitle: String {
        return NSLocalizedString("notebookSetting.customizeToolbar", comment: "Customize Toolbar")
    }

    var identifier: String {
        return "customizeToolbar"
    }

    var isViewed: Bool {
        get {
            UserDefaults.standard.register(defaults: ["\(identifier)_viewed": false])
            return UserDefaults.standard.bool(forKey: "\(identifier)_viewed")
        }

        set {
            UserDefaults.standard.set(newValue, forKey: "\(identifier)_viewed")
        }
    }
}
