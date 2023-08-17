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
    case paginationNoteBook,addNewPge, activeFocusMode,undo_redo, fitPageToScreen;
    var localizedTitle: String {
        var title:String;
        switch self {
        case .paginationNoteBook:
            title = NSLocalizedString("PaginateNotebook", comment: "PaginateNotebook")
        case .addNewPge:
            title = NSLocalizedString("AddNewPage", comment: "AddNewPage")
        case .undo_redo:
            title = NSLocalizedString("gesture.undoredo.title", comment: "RedoUndo")
        case .fitPageToScreen:
            title = NSLocalizedString("FitPageToScreen", comment: "FitPageToScreen")
        case .activeFocusMode:
            title = NSLocalizedString("gesture.activeFocusMode.title", comment: "activeFocusMode")
        }
        return title;
    }

    var localizedSubTitle: String {
        var title:String;
        switch self {
        case .paginationNoteBook:
            if isDeviceSupportsApplePencil(), FTStylusPenApplePencil().isConnected {
                title = NSLocalizedString("PaginatePencilConnectedNotebookHint", comment: "PaginatePencilConnectedNotebookHint")
            } else {
                title = NSLocalizedString("PaginateNotebookHint", comment: "PaginateNotebookHint")
            }
        case .addNewPge:
            title = NSLocalizedString("AddNewPageHint", comment: "AddNewPageHint")
        case .undo_redo:
            title = NSLocalizedString("gesture.undoredo.subTitle", comment: "RedoUndoHint")
        case .fitPageToScreen:
            title = NSLocalizedString("FitPageToScreenHint", comment: "FitPageToScreenHint")
        case .activeFocusMode:
            title = NSLocalizedString("gesture.activeFocusMode.subTitle", comment: "activeFocusMode")
        }
        return title;
    }
    var thumbnail: UIImage? {
        var image: UIImage?;
        switch self {
        case .paginationNoteBook:
           image = UIImage(named: "gesture-swipe-horizontal")
        case .addNewPge:
            image = UIImage(named: "gesture-two-fingers-scroll")
        case .undo_redo:
            image = UIImage(named: "gesture-two-finger-tap")
        case .fitPageToScreen:
            return UIImage(named: "gesture-tap")
        case .activeFocusMode:
            image = UIImage(named: "cursor-hand")
        }
        return image;
    }

    var type: FTGestureType {
        var type:FTGestureType;
        switch self {
        case .paginationNoteBook, .addNewPge, .undo_redo, .fitPageToScreen, .activeFocusMode:
            type = .basic
            return type;
        }
    }
}
