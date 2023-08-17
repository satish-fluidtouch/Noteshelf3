//
//  FTNewNotePopoverViewModel.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 20/05/22.
//

import Foundation

protocol FTNewNotePopoverDelegate: NSObject {
    func quickCreateNewNotebook()
    func showNewNotebookPopover()
}

class FTNewNotePopoverViewModel: ObservableObject {
    var newNoteOptions: [FTNewNotePopoverModel] = [
        FTNewNotePopoverModel(newNoteOption: .photoLibrary),
        FTNewNotePopoverModel(newNoteOption: .audioNote),
        FTNewNotePopoverModel(newNoteOption: .scanDocument),
        FTNewNotePopoverModel(newNoteOption: .takePhoto),
//        FTNewNotePopoverModel(newNoteOption: .appleWatch)
]
    weak var delegate: FTNewNotePopoverDelegate?

    var displayableOptions: [FTNewNotePopoverModel] {
        newNoteOptions
    }
}
