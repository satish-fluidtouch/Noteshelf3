//
//  FTShareContentModels.swift
//  Multi Platform Navigation
//
//  Created by Narayana on 01/11/22.
//

import Foundation

enum FTShareOption: Int, Identifiable {
    var id: RawValue { self.rawValue }

    case currentPage
    case allPages
    case selectPages
    // TODO: notebook case should be remove from this enum.
    case notebook

    var displayTitle: String {
        let title: String
        switch self {
        case .currentPage:
            title = "CurrentPage"
        case .allPages:
            title = "AllPages"
        case .selectPages:
            title = "SelectPages"
        case .notebook:
            title = ""
        }
        return title.localized
    }

    var showChevron: Bool {
        var toShow = false
        if self == .selectPages {
            toShow = true
        }
        return toShow
    }
}
