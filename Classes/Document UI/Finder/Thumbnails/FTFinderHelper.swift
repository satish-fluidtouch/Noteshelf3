//
//  FTFinderHelper.swift
//  Noteshelf3
//
//  Created by Sameer on 02/05/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

enum FTFinderPageState {
    case edit
    case none
    case selectPages
}

enum FTFinderSegment: Int {
    case pages
    case bookmark
    case outlines
    case search
    case none
}

enum FTFinderScreenMode {
    case normal
    case fullScreen
}

enum FTFinderContextMenuOperation : String {
    case copyPages
    case pastePages
    case sharePages
    case insertAbove
    case insertBelow
    case duplicatePages
    case movePages
    case rotatePages
    case tagPages
    case deletePages
    case bookmark

    var description: String {
        switch self {
        case .copyPages:
            return  "copy_page"
        case .pastePages:
            return  "paste_page"
        case .sharePages:
            return  "share_page"
        case .insertAbove:
            return  "insert_above"
        case .insertBelow:
            return  "insert_below"
        case .duplicatePages:
            return  "duplicate_page"
        case .movePages:
            return  "move_page"
        case .rotatePages:
            return  "rotate_page"
        case .tagPages:
            return  "tag_page"
        case .bookmark:
            return  "bookmark_page"
        case .deletePages:
            return  "delete_page"
        }
    }
}

enum FTBottomOption {
    case share
    case rotate
    case duplicate
    case more
    
    func title() -> String {
        var title = ""
        switch self {
        case .share:
            title = NSLocalizedString("finder.share", comment: "share")
        case .rotate:
            title = NSLocalizedString("finder.rotate", comment: "rotate")
        case .duplicate:
            title = NSLocalizedString("finder.duplicate", comment: "duplicate")
        case .more:
            title = NSLocalizedString("finder.more", comment: "more")
            return title
        }
        return title
    }
}
