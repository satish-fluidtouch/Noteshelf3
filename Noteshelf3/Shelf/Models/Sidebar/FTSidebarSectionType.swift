//
//  FTSideMenuItemsModel.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 14/04/22.
//

import Foundation
import SwiftUI

enum FTSidebarSectionType: String {
    case all
    case categories
    case ns2Categories
    case tags
    case media

    var displayTitle: String? {
        let title: String?
        switch self {
        case .all:
            title = nil
        case .categories:
            title = NSLocalizedString("Categories", comment: "Categories")
        case .ns2Categories:
            title = "Noteshelf 2"
        case .tags:
            title = NSLocalizedString("Tags", comment: "Tags")
        case .media:
            title = NSLocalizedString("shelf.sidebar.content", comment: "Content")
        }
        return title
    }
}

enum FTSideBarItemType: String {
    case home
    case templates
    case unCategorized
    case trash
    case category
    case ns2Category
    case starred
    case media
    case audio
    case tag
    case bookmark

    var displayTitle: String {
        let title: String
        switch self {
        case .home:
            title = NSLocalizedString("sidebar.topSection.home", comment: "Home")
        case .starred:
            title = NSLocalizedString("sidebar.topSection.starred", comment: "Starred")
        case .trash:
            title = NSLocalizedString("Trash", comment: "Trash")
        case .unCategorized:
            title = NSLocalizedString("sidebar.topSection.unfiled", comment: "Unfiled")
        default:
            title = ""
        }
        return title
    }
    var iconName: String {
        let name: String
        switch self {
        case .home:
            name = "homeIcon"
        case .starred:
            name = "star"
        case .trash:
            name = "trash"
        case .unCategorized:
            name = "tray"
        default:
            name = ""
        }
        return name
    }
    var activeBGColor: Color {
        let color: Color
        switch self {
        case .home:
            color = Color.appColor(.homeSelectedBG)
        case .starred:
            color = Color.appColor(.starredSelectedBG)
        case .trash:
            color = Color.appColor(.trashSelectedBG)
        case .unCategorized:
            color = Color.appColor(.unfiledSelectedBG)
        default:
            color = Color.white
        }
        return color
    }
    var bgColor: Color {
        let color: Color
        switch self {
        case .home:
            color = Color.appColor(.homeBG)
        case .starred:
            color = Color.appColor(.starredBG)
        case .trash:
            color = Color.appColor(.trashBG)
        case .unCategorized:
            color = Color.appColor(.unfiledBG)
        default:
            color = Color.white
        }
        return color
    }
    var iconTint: Color {
        let color: Color
        switch self {
        case .home:
            color = Color.appColor(.homeIconTint)
        case .starred:
            color = Color.appColor(.starredIconTint)
        case .trash:
            color = Color.appColor(.trashIconTint)
        case .unCategorized:
            color = Color.appColor(.unfiledIconTint)
        default:
            color = Color.white
        }
        return color
    }
    var shadowColor: Color {
        let color: Color
        switch self {
        case .home:
            color = Color.appColor(.homeShadow)
        case .starred:
            color = Color.appColor(.starredShadow)
        case .trash:
            color = Color.appColor(.trashShadow)
        case .unCategorized:
            color = Color.appColor(.unfiledShadow)
        case .templates:
            color = Color.appColor(.templatesShadow)
        default:
            color = Color.white
        }
        return color
    }
    var activeDropItemBGColor: Color {
            let color: Color
            switch self {
            case .home:
                color = Color.appColor(.homeBG).opacity(0.5)
            case .starred:
                color = Color.appColor(.starredBG).opacity(0.5)
            case .trash:
                color = Color.appColor(.trashBG).opacity(0.5)
            case .unCategorized:
                color = Color.appColor(.unfiledBG).opacity(0.5)
            default:
                color = Color.white
            }
            return color
    }
}
