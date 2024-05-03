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
            title = "Notebook"
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
    
    var eventName: String {
        var value = ""
        switch self {
        case .quickNote, .newNotebook, .audioNote, .scan:
            value = "widget_takenotes_action_tap"
        case .search:
            value = "widget_takenotes_search_tap"
        }
        return value
    }
    
    var parameterName: String {
        var value = ""
        switch self {
        case .quickNote:
            value = "quick note"
        case .newNotebook:
            value = "notebook"
        case .audioNote:
            value = "audio note"
        case .scan:
            value = "scan"
        case .search:
            value = "search"

        }
        return value
    }
}

public enum FTPinndedWidgetActionType: FTWidgetActionType {
    case pen(String)
    case audio(String)
    case openAI(String)
    case text(String)
    case bookOpen(String)

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
        case .bookOpen(_):
            iconName = ""
        }
        return iconName
    }

    public var docId: String {
        get {
            switch self {
            case .pen(let docId), .audio(let docId), .openAI(let docId), .text(let docId),.bookOpen(let docId):
                return docId
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
            case .bookOpen:
                self = .bookOpen(newValue)
            }
        }
    }
    
    func shouldAddNewPage() -> Bool {
        let boolValue: Bool
        switch self {
        case .pen, .audio, .text, .openAI:
            boolValue = true
        case .bookOpen:
            boolValue = false
        }
        return boolValue
    }
    
    var eventName: String {
        var value = ""
        switch self {
        case .pen, .audio, .text, .openAI:
            value = "widget_bignbk_tool_tap"
        case .bookOpen:
            value = "widget_bignbk_book_tap"
        }
        return value
    }
    
    var parameterName: String {
        var value = ""
        switch self {
        case .pen:
            value = "pen"
        case .audio:
            value = "audio"
        case .text:
            value = "text"
        case .openAI:
            value = "openAI"
        case .bookOpen:
            value = ""
        }
        return value
    }
}
