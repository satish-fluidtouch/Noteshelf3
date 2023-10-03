//
//  FTShelfNewNotePopoverModel.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 20/05/22.
//

import Foundation

enum FTNewNotePopoverOptions {
    case quickNote
    case newNotebook
    case importFromFiles
    case photoLibrary
    case audioNote
    case scanDocument
    case takePhoto
    case appleWatch
    case newGroup

    var displayTitle: String {
        let title: String
        switch self {
        case .quickNote:
            title = NSLocalizedString("quickNotesSave.quickNote", comment: "Quick Note")
        case .newNotebook:
            title = NSLocalizedString("shelf.newNote.Newnotebook", comment: "New Notebook")
        case .importFromFiles:
            title =  NSLocalizedString("shelf.newNote.importFile", comment: "Import File")
        case .photoLibrary:
            title = NSLocalizedString("shelf.newNote.photoTemplate", comment: "Photo Template")
        case .audioNote:
            title = NSLocalizedString("AudioNote", comment: "Audio Note")
        case .scanDocument:
            title = NSLocalizedString("shelf.newNote.scanDocument", comment: "Scan Document")
        case .appleWatch:
            title = NSLocalizedString("shelf.newNote.appleWatch", comment: "Apple Watch")
        case .takePhoto:
            title = NSLocalizedString("shelf.newNote.takePhoto", comment: "Take Photo")
        case .newGroup:
            title = "New Group".localized
        }
        return title
    }

    var icon: FTIcon {
        let icon: FTIcon
        switch self {
        case .quickNote:
            icon =  FTIcon.quickNote
        case .newNotebook:
            icon = FTIcon.notebook
        case .importFromFiles:
            icon = FTIcon.importFromFiles
        case .photoLibrary:
            icon = FTIcon.photoLibrary
        case .audioNote:
            icon = FTIcon.audioNote
        case .scanDocument:
            icon = FTIcon.scanDocument
        case .appleWatch:
            icon = FTIcon.appleWatch
        case .takePhoto:
            icon = FTIcon.takePhoto
        case .newGroup:
            icon = FTIcon.emptyGroup
        }
        return icon
    }
    var showChevron: Bool{
        switch self {
        case .photoLibrary,.appleWatch :
            return true
        default:
            return false
        }
    }
}
struct FTNewNotePopoverModel: Hashable {
    var newNoteOption: FTNewNotePopoverOptions
}
