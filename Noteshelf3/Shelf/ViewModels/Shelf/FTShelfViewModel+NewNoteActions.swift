//
//  FTShelfViewModel+NewNoteActions.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 10/10/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

extension FTShelfViewModel: FTNewNotePopoverDelegate {
    func quickCreateNewNotebook() {
        self.delegate?.createNewNotebookInside(collection: collection, group: groupItem, notebookDetails: nil, isQuickCreate: true,mode:.quickCreate, onCompletion: { [weak self] error, shelfItem in
            if error == nil, let item = shelfItem, !FTDeveloperOption.bookScaleAnim {
                self?.setcurrentActiveShelfItemUsing(item, isQuickCreated: true)
            }
        })
    }
    func showNewNotebookPopover() {
        self.delegate?.showNewBookPopverOnShelf()
    }
    
    func isAllNotesCollection() -> Bool {
        return self.collection.isAllNotesShelfItemCollection
    }

}
// MARK: New note popover operations
extension FTShelfViewModel {
    func presentNewNotebookPopover() {
        delegate?.showNewBookPopverOnShelf()
    }
    func createBookUsing(notebookDetails: FTNewNotebookDetails){
        self.delegate?.createNewNotebookInside(collection: collection, group: groupItem, notebookDetails: notebookDetails, isQuickCreate: false, mode: .basic, onCompletion: {[weak self] error, shelfItem in
            if error == nil, let item = shelfItem, !FTDeveloperOption.bookScaleAnim {
                self?.setcurrentActiveShelfItem(FTCurrentShelfItem(item, pin: notebookDetails.documentPin?.pin))
            }
        })
    }
}
