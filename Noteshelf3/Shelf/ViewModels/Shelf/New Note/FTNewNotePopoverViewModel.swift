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
    var newNoteOptions: [FTNewNotePopoverModel] {
        var options = [
            FTNewNotePopoverModel(newNoteOption: .newGroup),
            FTNewNotePopoverModel(newNoteOption: .photoLibrary),
            FTNewNotePopoverModel(newNoteOption: .audioNote),
            FTNewNotePopoverModel(newNoteOption: .scanDocument),
            FTNewNotePopoverModel(newNoteOption: .takePhoto)
//            FTNewNotePopoverModel(newNoteOption: .appleWatch)
        ]
        if (NSUbiquitousKeyValueStore.default.isWatchPaired() && NSUbiquitousKeyValueStore.default.isWatchAppInstalled()) {
            options.append(FTNewNotePopoverModel(newNoteOption: .appleWatch))
        }
        return options
    }

    weak var delegate: FTNewNotePopoverDelegate?
    weak var viewDelegate: FTShelfNewNotePopoverViewDelegate?

    var displayableOptions: [FTNewNotePopoverModel] {
#if !targetEnvironment(macCatalyst)
        return newNoteOptions
#else
        return newNoteOptions.filter { $0.newNoteOption != .scanDocument }
#endif
        }
}
