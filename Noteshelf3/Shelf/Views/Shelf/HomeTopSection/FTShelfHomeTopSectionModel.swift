//
//  ShelfHomeItemModel.swift
//  DynamicGridView
//
//  Created by Rakesh on 12/04/23.
//

import Foundation
import UIKit

enum FTShelfHomeTopSectionModel {
    case quicknote
    case newNotebook
    case importFile
    
    var displayTitle: String {
        let title: String
        switch self {
        case .quicknote:
            title = NSLocalizedString("quickNotesSave.quickNote", comment: "Quick Note")
        case .newNotebook:
            title = NSLocalizedString("shelf.newNote.Newnotebook", comment: "New Notebook")
        case .importFile:
            title =  NSLocalizedString("shelf.newNote.importFile", comment: "Import File")
        }
        return title
    }
    var iconName: String {
        let name: String
        switch self {
        case .quicknote:
            name = "Quicknote"
        case .newNotebook:
            name = "notebook"
        case .importFile:
            name = "importFile"
        }
        return name
        
    }
    var largeiconName: String {
        let name: String
        switch self {
        case .quicknote:
            name = "QuicknoteLarge"
        case .newNotebook:
            name = "notebookLarge"
        case .importFile:
            name = "importFileLarge"
        }
        return name

    }
    var description: String {
        let description: String
        switch self {
        case .quicknote:
            description = "shelf.quickcreate.description".localized
        case .newNotebook:
            description = "shelf.newnotebook.description".localized
        case .importFile:
            description = "shelf.importfile.description".localized
        }
        return description
        
    }
}
