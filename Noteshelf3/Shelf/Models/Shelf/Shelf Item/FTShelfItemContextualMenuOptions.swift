//
//  FTShelfItemContextualMenuOptions.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 07/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

enum FTShelfItemContexualOption {
    case showEnclosingFolder
    case openInNewWindow
    case rename
    case changeCover
    case tags
    case duplicate
    case move
    case addToStarred
    case removeFromStarred
    case getInfo
    case share
    case trash
    case restore
    case delete
    case removeFromRecents

    var displayTitle: String {
        let title: String
        switch self {
        case .showEnclosingFolder:
            title = NSLocalizedString("shelfItem.contexualMenu.showEnclosingFolder", comment: "Show Enclosing Folder")
        case .openInNewWindow:
            title = NSLocalizedString("shelfItem.contexualMenu.openInNewWindow", comment: "Open in New Window")
        case .rename:
            title = NSLocalizedString("shelfItem.contexualMenu.rename", comment: "Rename")
        case .changeCover:
            title = NSLocalizedString("shelfItem.contexualMenu.changeCover", comment: "Change Cover")
        case .tags:
            title = NSLocalizedString("shelfItem.contexualMenu.tags", comment: "Tags")
        case .duplicate:
            title = NSLocalizedString("duplicate", comment: "Duplicate")
        case .move:
            title = NSLocalizedString("move", comment: "Move")
        case .addToStarred:
            title = NSLocalizedString("shelfItem.contexualMenu.addToStarred", comment: "Add to Starred")
        case .removeFromStarred:
            title = NSLocalizedString("shelfItem.contexualMenu.removeFromStarred", comment: "Remove from Starred")
        case .getInfo:
            title = NSLocalizedString("shelfItem.contexualMenu.getInfo", comment: "Get Info")
        case .share:
            title = NSLocalizedString("share", comment: "share")
        case .trash:
            title = NSLocalizedString("Trash", comment: "Trash")
        case .restore:
            title = NSLocalizedString("shelf.bottomBar.restore", comment: "Restore")
        case .delete:
            title = NSLocalizedString("delete", comment: "Delete")
        case .removeFromRecents:
            title = NSLocalizedString("RemoveFromRecents", comment: "Remove from Recents")
        }
        return title
    }

    var icon: FTIcon {
        let icon: FTIcon
        switch self {
        case .openInNewWindow:
            icon = FTIcon.openInNewWindow
        case .rename:
            icon = FTIcon.rename
        case .changeCover:
            icon = FTIcon.changeCover
        case .tags:
            icon = FTIcon.number
        case .duplicate:
            icon = FTIcon.duplicate
        case .move:
            icon = FTIcon.move
        case .addToStarred:
            icon = FTIcon.addToFavorites
        case .removeFromStarred:
            icon = FTIcon.removeFromFavorites
        case .getInfo:
            icon = FTIcon.infoCircle
        case .share:
            icon = FTIcon.share
        case .trash:
            icon = FTIcon.trash
        case .restore:
            icon = FTIcon(systemName:"arrow.counterclockwise")
        case .delete:
            icon = FTIcon.trash
        case .showEnclosingFolder:
            icon = FTIcon.showEnclosingFolder
        case .removeFromRecents:
            icon = FTIcon.trash
        }
        return icon
    }
    var foreGroundColor: UIColor {
        let color  : UIColor
        if self == .trash || self == .removeFromRecents {
            color = UIColor.appColor(.destructiveRed)
        }else {
            color = UIColor.label
        }
        return color
    }
    var isDestructiveOption: Bool {
        if self == .trash || self == .delete || self == .removeFromRecents{
            return true
        }
        return false
    }
}
struct FTShelfItemContextualMenuOptions: Identifiable {
    
    var id: ObjectIdentifier
    var shelfItem: FTShelfItemViewModel
    var shelfItemCollection: FTShelfItemCollection?
    var longPressActions: [[FTShelfItemContexualOption]] {
        if shelfItemCollection?.isStarred ?? false {
            return favoritedBookOptions
        } else if shelfItemCollection?.isTrash ?? false {
            return trashedBookOptions
        } else {
            if shelfItem.type == .notebook {
                return noteBookOptions
            }
            return groupOptions
        }
    }
    var noteBookOptions: [[FTShelfItemContexualOption]] {
        var section1: [FTShelfItemContexualOption] = [.openInNewWindow]
        if !shelfItem.isNotDownloaded {
            section1.append((shelfItem.isFavorited ? .removeFromStarred : .addToStarred))
        }

        return [
            section1,
            [.rename, .changeCover, .tags,],
            [.duplicate, .move, .getInfo, .share,],
            [.trash]]
    }
    var groupOptions: [[FTShelfItemContexualOption]] {
        return [[.openInNewWindow],[.rename],[.duplicate,.move,.share],[.trash]]
    }
    var trashedBookOptions: [[FTShelfItemContexualOption]]{
        return [[.restore],[.delete]]
    }
    var favoritedBookOptions: [[FTShelfItemContexualOption]] {
        [[.openInNewWindow,.showEnclosingFolder,  .removeFromStarred],[.rename,.changeCover,.tags],[.getInfo,.share],[.trash]]
    }
}
