//
//  FTShelfBottomBarMoreOptions.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 19/05/22.
//

import Foundation
enum FTShelfBottomBarOption {
    case share
    case move
    case delete
    case createGroup
    case changeCover
    case duplicate
    case rename
    case restore
    case tags
    case trash

    var displayTitle: String {
        let title: String
        switch self {
        case .createGroup:
            title = NSLocalizedString("shelf.createGroup", comment: "Create Group")
        case .changeCover:
            title = NSLocalizedString("shelf.changeCover", comment: "Change Cover")
        case .duplicate:
            title = NSLocalizedString("shelf.duplicate", comment: "Duplicate")
        case .rename:
            title = NSLocalizedString("shelf.rename", comment: "Rename")
        case .share:
            title = NSLocalizedString("share", comment: "share")
        case .move:
            title = NSLocalizedString("shelf.bottomBar.Move", comment: "Move")
        case .delete:
            title = NSLocalizedString("shelf.bottomBar.delete", comment: "Delete")
        case .restore:
            title = NSLocalizedString("shelf.bottomBar.restore", comment: "Delete")
        case .tags:
            title = "Tags".localized
        case .trash:
            title = NSLocalizedString("shelf.bottomBar.trash", comment: "Trash")
    }
        return title
    }

    var icon: FTIcon {
        let icon: FTIcon
        switch self {
        case .createGroup:
            icon = FTIcon.createGroup
        case .changeCover:
            icon = FTIcon.changeCover
        case .duplicate:
            icon = FTIcon.duplicate
        case .rename:
            icon = FTIcon.rename
        case .share:
            icon = .share
        case .move:
            icon = .move
        case .delete:
            icon = .trash
        case .restore:
            icon = .restore
        case .tags:
            icon = .number
        case .trash:
            icon = .trash
        }
        return icon
    }
}
struct FTShelfBottomBarMoreOptions: Hashable {
    static var options: [FTShelfBottomBarOption] {
        [.createGroup,.changeCover,.duplicate, .tags, .rename]
    }
}
