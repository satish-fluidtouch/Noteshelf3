//
//  FTCustomizeToolbarSections.swift
//  Noteshelf3
//
//  Created by Narayana on 23/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

enum FTCustomizeToolbarSectionType: Int, CaseIterable {
    case currentToolbar
    case basicTools
    case addMenu
    case shortcuts
    case shareAndSave

    func localizedString() -> String {
        var str = ""
        switch self {
        case .currentToolbar:
            str = NSLocalizedString("customizeToolbar.currentToolbar", comment: "ON TOOLBAR")
        case .basicTools:
            str = NSLocalizedString("customizeToolbar.basicTools", comment: "BASIC TOOLS")
        case .addMenu:
            str = NSLocalizedString("customizeToolbar.addMenu", comment: "ADD MENU")
        case .shortcuts:
            str = NSLocalizedString("customizeToolbar.shortcuts", comment: "SHORTCUTS")
        case .shareAndSave:
            str = NSLocalizedString("customizeToolbar.shareAndSave", comment: "SHARE AND SAVE")
        }
        return str
    }
}

@objc enum FTDeskCenterPanelToolMode: Int {
    case deskModeTool
    case shortcut
}

@objc enum FTDeskCenterPanelTool: Int, CaseIterable {
    // Basic Tools
    case pen
    case highlighter
    case eraser
    case shapes
    case textMode
    case presenter
    case lasso
    case zoomBox
    case share
    case hand
    case openAI

    // Add Menu
    case photo
    case audio
    case unsplash
    case pixabay
    case emojis
    case stickers

    // Shortcuts
    case page
    case bookmark
    case tag
    case rotatePage
    case duplicatePage

    // Share and Save
    case savePageAsPhoto
    case sharePageAsPng
    case shareNotebookAsPDF

    func iconName() -> String {
        var name: String = ""
        switch self {
        case .pen :
            name = "desk_tool_pen"
        case .highlighter :
            name = "desk_tool_highlighter"
        case .eraser :
            name = "desk_tool_eraser"
        case .shapes :
            name = "desk_tool_shape"
        case .textMode :
            name = "desk_tool_text"
        case .lasso :
            name = "desk_tool_lasso"
        case .presenter :
            name = "desk_tool_presenter"
        case .zoomBox:
            name = "desk_tool_zoomBox"
        case .hand:
            name = "desk_tool_viewMode"
        case .share:
            name = "desk_tool_share"
        case .openAI:
            name = "desk_tool_openAI"
        case .photo:
            name = "desk_tool_photo"
        case .audio:
            name = "desk_tool_audio"
        case .stickers:
            name = "desk_tool_stickers"
        case .unsplash:
            name = "desk_tool_unsplash"
        case .pixabay:
            name = "desk_tool_pixabay"
        case .emojis:
            name = "desk_tool_emojis"

        case .page:
            name = "desk_tool_page"
        case .bookmark:
            name = "desk_tool_bookmark"
        case .tag:
            name = "desk_tool_tag"
        case .rotatePage:
            name = "desk_tool_rotatePage"
        case .duplicatePage:
            name = "desk_tool_duplicatePage"

        case .savePageAsPhoto:
            name = "desk_tool_saveAsPhoto"
        case .sharePageAsPng:
            name = "desk_tool_shareAsPNG"
        case .shareNotebookAsPDF:
            name = "desk_tool_shareAsPDF"
        }
        return name
    }

    func selectedIconName() -> String? {
        var name: String?
        switch self {
        case .eraser:
            name = "desk_tool_eraserSelected"
        case .textMode:
            name = "desk_tool_textSelected"
        case .lasso:
            name = "desk_tool_lassoSelected"
        case .hand:
            name = "desk_tool_viewModeSelected"
        case .openAI:
            name = "desk_tool_openAISelected"
        case .presenter:
            name = "desk_tool_presenterSelected"
        case .photo:
            name = "desk_tool_photoSelected"
        case .audio:
            name = "desk_tool_audioSelected"
        case .stickers:
            name = "desk_tool_stickersSelected"
        case .zoomBox:
            name = "desk_tool_zoomBoxSelected"
        case .emojis:
            name = "desk_tool_emojisSelected"
        case .tag:
            name = "desk_tool_tagSelected"

        default:
            break
        }
        return name
    }

    func localizedString() -> String {
        var str: String = ""
        switch self {
            // Basic
        case .pen:
            str = "customizeToolbar.pen".localized
        case .highlighter:
            str = "customizeToolbar.highlighter".localized
        case .eraser:
            str = "customizeToolbar.eraser".localized
        case .shapes:
            str = "customizeToolbar.shapes".localized
        case .lasso:
            str = "customizeToolbar.lasso".localized
        case .textMode:
            str = "customizeToolbar.textBox".localized
        case .presenter:
            str = "customizeToolbar.present".localized
        case .zoomBox:
            str = "customizeToolbarzoombox".localized
        case .hand:
            str = "customizeToolbar.readOnlyMode".localized
        case .openAI:
            str = "noteshelf.ai.noteshelfAI".aiLocalizedString
        case .share:
            str = "customizeToolbar.share".localized

            // Media
        case .photo:
            str = "customizeToolbar.photo".localized
        case .audio:
            str = "customizeToolbar.audio".localized
        case .stickers:
            str = "customizeToolbar.stickers".localized
        case .unsplash:
            str = "Unsplash"
        case .pixabay:
            str = "Pixabay"
        case .emojis:
            str = "customizeToolbar.emojis".localized

            // Shortcuts
        case .page:
            str = "customizeToolbar.page".localized
        case .bookmark:
            str = "customizeToolbar.bookmark".localized
        case .tag:
            str = "customizeToolbar.tag".localized
        case .rotatePage:
            str = "customizeToolbar.rotatePage".localized
        case .duplicatePage:
            str = "customizeToolbar.duplicatePage".localized

        case .savePageAsPhoto:
            str = "customizeToolbar.savePageAsPhoto".localized
        case .sharePageAsPng:
            str = "customizeToolbar.sharePageAsPng".localized
        case .shareNotebookAsPDF:
            str = "customizeToolbar.shareNotebookAsPDF".localized
        }
        return str
    }

    var toolMode: FTDeskCenterPanelToolMode {
        var mode: FTDeskCenterPanelToolMode = .shortcut
        if self == .pen || self == .highlighter || self == .eraser || self == .shapes || self == .textMode || self == .presenter || self == .lasso || self == .hand {
            mode = .deskModeTool
        }
        return mode
    }

    func isColorEditTool() -> Bool {
        var isColorEditTool: Bool = false
        if self == .pen || self == .highlighter || self == .shapes {
            isColorEditTool = true
        }
        return isColorEditTool
    }

    func tintImage() -> UIImage? {
        var img: UIImage? = nil
        if self.isColorEditTool() {
            if self == .pen {
                img = UIImage(named: "desk_tool_penTint")
            } else if self == .highlighter {
                img = UIImage(named: "desk_tool_highlighterTint")
            } else if self == .shapes {
                img = UIImage(named: "desk_tool_shapeTint")
            }
        }
        return img
    }

    func backGroundImage() -> UIImage? {
        var img: UIImage? = nil
        if self.isColorEditTool() {
            if self == .pen {
                img = UIImage(named: "desk_tool_penBg")
            } else if self == .highlighter {
                img = UIImage(named: "desk_tool_highlighterBg")
            } else if self == .shapes {
                img = UIImage(named: "desk_tool_shapeBg")
            }
        }
        return img
    }
}

extension Array<FTDeskCenterPanelTool> {
    func subtract(arr: [FTDeskCenterPanelTool]) -> [FTDeskCenterPanelTool] {
        return self.filter { !arr.contains($0) }
    }
}
