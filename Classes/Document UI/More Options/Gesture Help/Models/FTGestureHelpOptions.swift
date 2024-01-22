//
//  FTGestureModel.swift
//  Noteshelf
//
//  Created by Sameer on 30/08/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

enum FTGestureType: String {
    case basic
}

enum FTGestureHelpOptions: Int {
    case showPageThumbnails
    case showQuickAccessSideBar
    case activeFocusMode
    case fitPageToScreen
    case undo
    case redo
    
    var localizedTitle: String {
        var title:String;
        switch self {
        case .showPageThumbnails:
            title = "gesture.show.thumbnails".localized
        case .showQuickAccessSideBar:
            title = "gesture.show.quickAccessSideBar".localized
        case .undo:
            title = "gesture.undo.title".localized
        case .fitPageToScreen:
            title = "gesture.fitPageToScreen".localized
        case .activeFocusMode:
            title = "gesture.activate.focusMode".localized
        case .redo:
            title = "gesture.redo.title".localized
        }
        return title;
    }

    var localizedSubTitle: String {
        var title:String;
        switch self {
        case .showPageThumbnails:
            title = "gesture.show.thumbnails.hint".localized
        case .showQuickAccessSideBar:
            title = "gesture.show.quickAccessSideBar.hint".localized
        case .undo:
            title = "gesture.undo.hint".localized
        case .fitPageToScreen:
            title = "gesture.fitPageToScreen.hint".localized
        case .activeFocusMode:
            title = "gesture.activate.focusMode.hint".localized
        case .redo:
            title = "gesture.redo.hint".localized
        }
        return title;
    }
    var thumbnail: UIImage? {
        var image: UIImage?;
        switch self {
        case .showPageThumbnails:
           image = UIImage(named: "gesture-swipe-left")
        case .showQuickAccessSideBar:
            image = UIImage(named: "gesture-long-swipe-left")
        case .undo:
            image = UIImage(named: "gesture-two-finger-tap")
        case .fitPageToScreen:
            return UIImage(named: "gesture-fit-screen")
        case .activeFocusMode:
            image = UIImage(named: "gesture-focus-mode")
        case .redo:
            image = UIImage(named: "gesture-three-finger-tap")
        }
        return image;
    }

    var type: FTGestureType {
        var type:FTGestureType;
        switch self {
        case .showPageThumbnails, .showQuickAccessSideBar, .undo, .redo,.fitPageToScreen, .activeFocusMode:
            type = .basic
            return type;
        }
    }
}
