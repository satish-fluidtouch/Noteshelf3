//
//  FTToolbarDataSource.swift
//  Noteshelf3
//
//  Created by Narayana on 20/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

@objc enum FTScreenMode: Int, Equatable {
    case normal
    case focus
    case shortCompact
    case none
}

@objc enum FTDeskToolbarMode: Int {
    case normal
    case readonly
}

enum FTDeskLeftPanelTool: Int {
    //Left panel
    case back = 100
    case finder = 101
    case undo = 102
    case redo = 103

    func iconName() -> String {
        var name: String = ""
        switch self {
        case .back:
            name = "desk_tool_back"
        case .finder :
            name = "desk_tool_finder"
        case .undo :
            name = "desk_tool_undo"
        case .redo :
            name = "desk_tool_redo"
        }
        return name
    }
}

@objc enum FTDeskRightPanelTool: Int {
    //Right Panel
    case add = 300
    case share = 301
    case more = 302
    case focus = 303

    func iconName() -> String {
        var name: String = ""
        switch self {
        case .add:
            name = "desk_tool_add"
        case .share:
            name = "desk_tool_share"
        case .more :
            name = "desk_tool_more"
        case .focus:
            name = "desk_tool_collapse"
        }
        return name
    }
}

enum FTDeskPanel: String {
    case left
    case center
    case right
}
