//
//  FTTagsViewController_MacExtension.swift
//  Noteshelf3
//
//  Created by Narayana on 03/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

#if targetEnvironment(macCatalyst)
extension FTShelfTagsViewController: FTToolbarActionDelegate {
    func toolbar(_ toolbar: NSToolbar, toolbarItem item: NSToolbarItem) {
        if item.itemIdentifier == FTSelectToolbarItem.identifier {
            (toolbar as? FTShelfToolbar)?.switchMode(.selectNotes)
            self.handleSelectActionInMac()
            // self.observeSelectModeChanges(of: toolbar)
        } else if item.itemIdentifier == FTSelectDoneToolbarItem.identifier {
            self.handleSelectActionInMac()
            (toolbar as? FTShelfToolbar)?.switchMode(.tags)
        } else if item.itemIdentifier == FTSelectNotesToolbarItem.identifier {
            selectAndDeselect()
            if shouldSelectAll {
                item.title = "sidebar.allTags.navbar.selectAll".localized
            } else {
                item.title = "sidebar.allTags.navbar.selectNone".localized
            }
        }
    }

    private func handleSelectActionInMac() {
        if self.viewState == .edit {
            activateViewMode()
        } else {
            activeEditMode()
        }
        clearContextMenuIndex()
        collectionView.reloadData()
        enableToolbarItemsIfNeeded()
    }
}
#endif
