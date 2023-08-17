//
//  SideBarTopSectionModel.swift
//  NewShelfSidebar
//
//  Created by Ramakrishna on 13/04/23.
//

import Foundation
import SwiftUI

enum SidebarTopSectionElement {
    case home
    case starred
    case trash
    case unfiled

    var displayTitle: String {
        let title: String
        switch self {
        case .home:
            title = "Home"
        case .starred:
            title = "Starred"
        case .trash:
            title = "Trash"
        case .unfiled:
            title = "Unfiled"
        }
        return title
    }
    var iconName: String {
        let name: String
        switch self {
        case .home:
            name = "star"
        case .starred:
            name = "star"
        case .trash:
            name = "trash"
        case .unfiled:
            name = "tray"
        }
        return name
    }
    var activeBGColor: Color {
        let color: Color
        switch self {
        case .home:
            color = Color("neutral")
        case .starred:
            color = Color("starredSelectedBG")
        case .trash:
            color = Color("trashSelectedBG")
        case .unfiled:
            color = Color("unfiledSelectedBG")
        }
        return color
    }
    var bgColor: Color {
        let color: Color
        switch self {
        case .home:
            color = Color("homeBG")
        case .starred:
            color = Color("starredBG")
        case .trash:
            color = Color("trashBG")
        case .unfiled:
            color = Color("unfiledBG")
        }
        return color
    }
    var iconTint: Color {
        let color: Color
        switch self {
        case .home:
            color = Color("homeIconTint")
        case .starred:
            color = Color("starredIconTint")
        case .trash:
            color = Color("trashIconTint")
        case .unfiled:
            color = Color("unfiledIconTint")
        }
        return color
    }
}
