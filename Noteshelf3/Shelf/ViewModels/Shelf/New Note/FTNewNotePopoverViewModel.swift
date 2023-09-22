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
    func isAllNotesCollection() -> Bool
}

class FTNewNotePopoverViewModel: ObservableObject {
    var newNoteOptions: [FTNewNotePopoverModel] = [
        FTNewNotePopoverModel(newNoteOption: .newGroup),
        FTNewNotePopoverModel(newNoteOption: .photoLibrary),
        FTNewNotePopoverModel(newNoteOption: .audioNote),
        FTNewNotePopoverModel(newNoteOption: .scanDocument),
        FTNewNotePopoverModel(newNoteOption: .takePhoto),
        //        FTNewNotePopoverModel(newNoteOption: .appleWatch)
    ]
    weak var delegate: FTNewNotePopoverDelegate?

    var displayableOptions: [FTNewNotePopoverModel] {
#if !targetEnvironment(macCatalyst)
        if self.delegate?.isAllNotesCollection() ?? false {
            return newNoteOptions.filter { $0.newNoteOption != .newGroup }
        } else {
            return newNoteOptions
        }
#else
        return newNoteOptions.filter { $0.newNoteOption != .scanDocument }
#endif
        }
}
