//
//  FTShelfViewModel+BottomBarOptions.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 10/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

extension FTShelfViewModel {
    func getMoreOptionsBasedOnCurrentCollection() -> [FTShelfBottomBarOption] {
        if collection.isAllNotesShelfItemCollection {
            return [.changeCover,.duplicate, .tags, .rename]
        }
        else if collection.isStarred {
            return [.changeCover,.tags, .rename]
        } else {
            let allmoreOptions: [FTShelfBottomBarOption] = [.createGroup,.changeCover,.duplicate, .tags, .rename]
            var bottomBarOptions: [FTShelfBottomBarOption] = []
            for option in allmoreOptions where self.shouldSupportBottomBarOption(option){
                bottomBarOptions.append(option)
            }
            return bottomBarOptions
        }
    }
    func shouldSupportBottomBarOption(_ option: FTShelfBottomBarOption) -> Bool{
        var status: Bool = true

        if disableBottomBarItems {
            status = false
        }
        else if (!disableBottomBarItems && self.hasAGroupShelfItemAmongSelectedShelfItems(selectedShelfItems)){
            // Selection list contains a group
            let hasAnEmptyGroup: Bool = selectedShelfItems.filter({($0 is FTGroupItemViewModel)}).first(where: {($0.model as? FTGroupItemProtocol)?.childrens.count == 0}) != nil
            if option == .changeCover || option == .tags || (hasAnEmptyGroup && option == .share) {
                status = false
            } else {
                status = true
            }
        }

        if collection.isAllNotesShelfItemCollection {
            if (option == .share ||
                option == .move ||
                option == .trash ||
                option == .changeCover ||
                option == .duplicate ||
                option == .tags ||
                option == .rename) && (!disableBottomBarItems) {
                status = true
            } else {
                status = false
            }
        }
        else if collection.isStarred {
            if (option == .rename ||
                option == .share ||
                option == .trash ||
                option == .tags ||
                option == .changeCover) && (!disableBottomBarItems) {
                status = true
            } else {
                status = false
            }
        }
        return status
    }
}
//MARK: Shelf Bottom tool operations
extension FTShelfViewModel: FTShelfBottomToolbarDelegate {
    func deleteShelfItems() {
        let deletedItems :[FTShelfItemProtocol] = self.selectedShelfItems.compactMap({$0.model})
        deleteShelfItems(deletedItems)
    }
    func deleteShelfItems(_ items: [FTShelfItemProtocol]){
        self.removeObserversForShelfItems()
        self.delegate?.deleteItems(items, shouldEmptyTrash: false, onCompletion: { [weak self] _ in
            self?.addObserversForShelfItems()
            self?.resetShelfModeTo(.normal)
        })
    }
    func restoreShelfItems() {
        self.removeObserversForShelfItems()
        var restoreItems :[FTShelfItemProtocol] = self.selectedShelfItems.compactMap({$0.model})
        if restoreItems.isEmpty, let updateItem = updateItem {
            restoreItems = [updateItem.model]
        }
        self.delegate?.restoreShelfItem(items: restoreItems, onCompletion: { [weak self] success, removedItems in
            self?.addObserversForShelfItems()
            self?.mode = .normal
            if !removedItems.isEmpty {
                self?.reloadShelfItems(animate: true, nil);
            }
        })
    }

    func moveShelfItems() {
        let selectedShelfItems = self.selectedShelfItems.compactMap({$0.model})
        self.moveShelfItems(selectedShelfItems)
    }
    func shareShelfItems() {
        let shareItems :[FTShelfItemProtocol] = self.selectedShelfItems.compactMap({$0.model})
        self.shareShelfItems(shareItems)
    }
    func shareShelfItems(_ items:[FTShelfItemProtocol]){
        self.removeObserversForShelfItems()
        self.delegate?.shareShelfItems(items, onCompletion: { [weak self] in
            self?.addObserversForShelfItems()
            self?.resetShelfModeTo(.normal)
        })
    }
    func trashShelfItems() {
        let deletedItems :[FTShelfItemProtocol] = self.selectedShelfItems.compactMap({$0.model})
        trashShelfItems(deletedItems)
    }
    func trashShelfItems(_ items: [FTShelfItemProtocol]){
        self.removeObserversForShelfItems()
        self.delegate?.moveItemsToTrash(items: items, { [weak self] _ in
            self?.addObserversForShelfItems()
            self?.resetShelfModeTo(.normal)
             // After trashing, we are not getting updates on current collection, instead its gives on trash collection so explicitly refreshing the shelf
                self?.reloadItems()
        })
    }

    func changeCover() {
        let selectedItems :[FTShelfItemViewModel] = self.selectedShelfItems
        self.delegate?.showCoverViewOnShelfWith(models: selectedItems)
    }

    func createGroup() {
        self.removeObserversForShelfItems()
        let groupItems :[FTShelfItemProtocol] = self.selectedShelfItems.compactMap({$0.model})
        self.delegate?.groupShelfItems(groupItems, ofColection: collection, parentGroup: groupItem, withGroupTitle: "", showAlertForGroupName: true, onCompletion: { [weak self] in
            self?.addObserversForShelfItems()
            self?.resetShelfModeTo(.normal)
        })
    }
    func renameShelfItems(){
        let selectedItems :[FTShelfItemProtocol] = self.selectedShelfItems.compactMap({$0.model})
        renameShelfItems(selectedItems)
    }
    func renameShelfItems(_ items: [FTShelfItemProtocol]){
        self.removeObserversForShelfItems()
        self.delegate?.renameDocuments(items, onCompletion: { [weak self] in
            self?.addObserversForShelfItems()
            self?.resetShelfModeTo(.normal)
            #if targetEnvironment(macCatalyst)
            self?.reloadItems()
            #endif
        })
    }
    func renameShelfItem(_ shelfItem: FTShelfItemViewModel){
        if collection.isTrash { // Renaming notebook in trash is not supported.
            return
        }
        let item = shelfItem.model
        self.renameShelfItems([item])
    }
    func duplicateShelfItems(){
        let selectedItems :[FTShelfItemProtocol] = self.selectedShelfItems.compactMap({$0.model})
        duplicateShelfItems(selectedItems)
    }
    func duplicateShelfItems(_ items: [FTShelfItemProtocol]){
        self.removeObserversForShelfItems()
        self.delegate?.duplicateDocuments(items, onCompletion: { [weak self] _ in
            self?.addObserversForShelfItems()
            self?.resetShelfModeTo(.normal)
            self?.reloadShelf()
        })
    }

    func tagsShelfItems() {
        let selectedItems :[FTShelfItemProtocol] = self.selectedShelfItems.compactMap({$0.model})
        self.tagsControllerDelegate?.tagsViewControllerFor(items: selectedItems, onCompletion: { [weak self] _ in
            self?.resetShelfModeTo(.normal)
        })
    }
}
