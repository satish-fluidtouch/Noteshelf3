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
    
    func segmentName() -> String {
        var name = "thumbnails"
        switch self {
        case .pages:
            name = "thumbnails"
        case .bookmark:
            name = "bookmark"
        case .outlines:
            name = "outline"
        case .search:
            name = "search"
        case .none:
            name = "thumbnails"
        }
        return name
    }
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
    
    var eventTrackdescription: String {
        switch self {
        case .copyPages:
            return  "finder_page_copy_tap"
        case .pastePages:
            return  "finder_page_pastebelow_tap"
        case .sharePages:
            return  "finder_page_share_tap"
        case .insertAbove:
            return  "finder_page_addpagebefore_tap"
        case .insertBelow:
            return  "finder_page_addpageafter_tap"
        case .duplicatePages:
            return  "finder_page_duplicate_tap"
        case .movePages:
            return  "finder_page_move_tap"
        case .rotatePages:
            return  "finder_page_rotate_tap"
        case .tagPages:
            return  "finder_page_tag_tap"
        case .bookmark:
            return  "finder_page_bookmarkicon_longpress"
        case .deletePages:
            return  "finder_page_delete_tap"
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
