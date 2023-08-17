//
//  FTSidebarItemContextualOption.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 17/04/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
enum FTSidebarItemContextualOption {
    case openInNewWindow
    case renameCategory
    case trashCategory
    case emptyTrash
    case renameTag
    case deleteTag

    var displayTitle: String {
        let title: String
        switch self {
        case .openInNewWindow:
            title = NSLocalizedString("shelfItem.contexualMenu.openInNewWindow", comment: "Open In New Window")
        case .renameCategory:
            title = NSLocalizedString("Rename", comment: "Rename")
        case .trashCategory:
            title = NSLocalizedString("Trash", comment: "Trash")
        case .emptyTrash:
            title = NSLocalizedString("shelf.emptyTrash", comment: "Empty Trash")
        case .deleteTag:
            title = NSLocalizedString("sidebar.contextualMenu.deleteTag", comment: "Delete Tag")
        case .renameTag:
            title = NSLocalizedString("Rename", comment: "Rename")
        }
        return title
    }
    var icon: FTIcon {
        let icon: FTIcon
        switch self {
        case .openInNewWindow:
            icon = FTIcon(systemName: "rectangle.badge.plus")
        case .renameCategory:
            icon = FTIcon(systemName: "pencil")
        case .trashCategory:
            icon = FTIcon(systemName: "trash")
        case .emptyTrash:
            icon = FTIcon(systemName: "trash")
        case .deleteTag:
            icon = FTIcon(systemName: "tag.slash")
        case .renameTag:
            icon = FTIcon(systemName: "tag")
        }
        return icon
    }

  var foreGroundColor: UIColor {
        let color  : UIColor
      if self == .trashCategory || self == .deleteTag || self == .emptyTrash {
            color = UIColor.appColor(.destructiveRed)
        }else {
            color = UIColor.label
        }
        return color
    }
    var isDestructiveOption: Bool {
        if self == .trashCategory || self == .deleteTag || self == .emptyTrash {
            return true
        }
        return false
    }
}
