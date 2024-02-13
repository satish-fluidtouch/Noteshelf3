//
//  FTWidgetActionType.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 08/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

public enum FTWidgetActionType {
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
}
