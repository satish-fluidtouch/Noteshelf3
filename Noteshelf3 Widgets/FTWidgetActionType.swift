//
//  FTNotebookCreateWidgetActionType.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 08/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

protocol FTWidgetActionType {
    var iconName: String { get }
}

public enum FTNotebookCreateWidgetActionType: FTWidgetActionType {
    case quickNote
    case newNotebook
    case audioNote
    case scan
    case search

    var title : String {
        let title : String
        switch self {
        case .quickNote:
            title = "Quick Note"
        case .newNotebook:
            title = "New Notebook"
        case .audioNote:
            title = "Audio Note"
        case .scan:
            title = "Scan"
        case .search:
            title = "Search"
        }
        return title
    }
    var iconName : String {
        let iconName : String
        switch self {
        case .quickNote:
            iconName = "quickNoteIcon" //"plus.circle"//"quickNoteIcon"
        case .newNotebook:
            iconName = "newNotebookIcon"
        case .audioNote:
            iconName = "audioNoteIcon" //"mic"//"audioNoteIcon"
        case .scan:
            iconName = "scanIcon" //"scanner"//"scanIcon"
        case .search:
            iconName = "searchIcon"
        }
        return iconName
    }
    var hasASystemIcon : Bool {
        let isSystemIcon : Bool
        switch self {
        case .quickNote:
            isSystemIcon = false
        case .newNotebook:
            isSystemIcon = false
        case .audioNote:
            isSystemIcon = false
        case .scan:
            isSystemIcon = false
        case .search:
            isSystemIcon = false
        }
        return isSystemIcon
    }

    public var relativePath: String {
        return ""
    }
}

public enum FTPinndedWidgetActionType: FTWidgetActionType {
    case pen(String)
    case audio(String)
    case openAI(String)
    case text(String)

    var iconName : String {
        let iconName: String
        switch self {
        case .pen:
            iconName = "pinned_pen"
        case .audio:
            iconName = "pinned_audio"
        case .openAI:
            iconName = "pinned_openAI"
        case .text:
            iconName = "pinned_text"
        }
        return iconName
    }

    public var relativePath: String {
        get {
            switch self {
            case .pen(let path), .audio(let path), .openAI(let path), .text(let path):
                return path
            }
        }
        set {
            switch self {
            case .pen:
                self = .pen(newValue)
            case .audio:
                self = .audio(newValue)
            case .openAI:
                self = .openAI(newValue)
            case .text:
                self = .text(newValue)
            }
        }
    }
}
