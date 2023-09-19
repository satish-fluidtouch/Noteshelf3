//
//  FTShelfViewModel+ShelfItemContextualOperations.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 10/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

//MARK: Shelf Item Contexual Menu operations
extension FTShelfViewModel {
    func getContexualOptionsForShelfItem(_ item: FTShelfItemViewModel) -> [[FTShelfItemContexualOption]] {
        if self.mode == .selection {
            let selectedShelfItems = self.shelfItems.filter({ $0.isSelected })
            if selectedShelfItems.count > 1 {
                if item.model.shelfCollection.isTrash {
                    return [[.restore],[.delete]]
                } else {
                    if self.hasAGroupShelfItemAmongSelectedShelfItems(selectedShelfItems) {
                        let hasAnEmptyGroup: Bool = selectedShelfItems.filter({($0 is FTGroupItemViewModel)}).first(where: {($0.model as? FTGroupItemProtocol)?.childrens.count == 0}) != nil
                        if hasAnEmptyGroup {
                            return [[.openInNewWindow],[.rename],[.duplicate,.move],[.trash]]
                        } else {
                            return [[.openInNewWindow],[.rename],[.duplicate,.move,.share],[.trash]]
                        }
                    }else {
                        return [[.rename,.changeCover, .tags,],[.duplicate,.move,.share,],[.trash]]
                    }
                }
            }else {
                if self.hasAGroupShelfItemAmongSelectedShelfItems(selectedShelfItems) {
                    let hasAnEmptyGroup: Bool = selectedShelfItems.filter({($0 is FTGroupItemViewModel)}).first(where: {($0.model as? FTGroupItemProtocol)?.childrens.count == 0}) != nil
                    if hasAnEmptyGroup {
                        return [[.openInNewWindow],[.rename],[.duplicate,.move],[.trash]]
                    } else {
                        return [[.openInNewWindow],[.rename],[.duplicate,.move,.share],[.trash]]
                    }
                }else {
                    return contexualMenuOptionsInNormalModeForShelfItem(item)
                }
            }
        }
        else {
            return contexualMenuOptionsInNormalModeForShelfItem(item)
        }
    }
    func performContexualMenuOperation(_ option: FTShelfItemContexualOption){
        sleep(UInt32(0.7))
        guard let shelfItem = shelfItemContextualMenuViewModel.shelfItem  else {
            return
        }
        self.updateItem = shelfItem
        let selectedItems: [FTShelfItemProtocol] = self.getShelfItemsForContexualMenuOperations().0
        let shelfItemViewModels = self.getShelfItemsForContexualMenuOperations().1
        self.currentDraggedItem = nil

        // Track Event
        trackEventForContexualOption(option: option, item: shelfItem)

        switch option {
        case .openInNewWindow:
            self.openShelfItemInNewWindow(shelfItem.model)
        case .rename:
            self.renameShelfItems(selectedItems)
        case .changeCover:
            self.delegate?.showCoverViewOnShelfWith(models: shelfItemViewModels)
        case .tags:
            if selectedItems.count > 1 {
                self.tagsShelfItems()
            }else {
                self.showTagsView()
            }
        case .duplicate:
            self.duplicateShelfItems(selectedItems)
        case .move:
            self.resetShelfModeTo(.normal)
            self.moveShelfItems(selectedItems)
        case .addToStarred, .removeFromStarred:
            if let favoriteItem = shelfItemContextualMenuViewModel.shelfItem {
                self.favoriteOrUnFavoriteShelfItem(favoriteItem)
            }
        case .getInfo:
            shelfItemContextualMenuViewModel.shelfItem?.popoverType = .getInfo
        case .share:
            self.shareShelfItems(selectedItems)
        case .trash:
            self.trashShelfItems(selectedItems)
        case .restore:
            self.restoreShelfItems()
        case .delete:
            self.deleteShelfItems(selectedItems)
        case .showEnclosingFolder:
            self.showEnclosingFolderFor(shelfItem.model)
        case .removeFromRecents:
            self.removeRecentItemsFromRecents([shelfItem.model])
        }
    }
    func favoriteOrUnFavoriteShelfItem(_ item: FTShelfItemViewModel){
        let toPin = !item.isFavorited
        self.delegate?.favoriteShelfItem(item.model, toPin: toPin)
        if self.collection.isStarred {
            self.reloadShelf()
        }
    }
}
private extension FTShelfViewModel {
    func contexualMenuOptionsInNormalModeForShelfItem(_ item: FTShelfItemViewModel) -> [[FTShelfItemContexualOption]] {
        if collection.isAllNotesShelfItemCollection {
            var section1: [FTShelfItemContexualOption] = [.openInNewWindow,.showEnclosingFolder]
            if !item.isNotDownloaded {
                section1.append((item.isFavorited ? .removeFromStarred : .addToStarred))
            }
            return [
                section1,
                [.rename,.changeCover,.tags],
                [.duplicate,.move,.getInfo,.share],
                [.trash]
            ]
        }else {
            return item.longPressOptions
        }
    }
   
    func getShelfItemsForContexualMenuOperations() -> ([FTShelfItemProtocol], [FTShelfItemViewModel]) {
        var shelfItemProtocols: [FTShelfItemProtocol] = []
        var shelfItemViewModels: [FTShelfItemViewModel] = []

        //** Incase of select mode contextual menu operations will be performed on all the selected notebooks/groups ***//
            if let longpressedShelfItem = self.updateItem {
                if self.mode == .selection {
                    // if long pressed item is selected, we need to perform operation considering all selected items. if long pressed item is not selected, then operation need to be performed on only long presses item ignoring selected items
                    if ((self.shelfItems.first(where: {$0.id == longpressedShelfItem.model.uuid})?.isSelected) != nil) {
                        shelfItemProtocols = self.shelfItems.filter({$0.isSelected}).compactMap({$0.model})
                        shelfItemViewModels = self.shelfItems.filter({$0.isSelected})
                    } else {
                        shelfItemProtocols = [longpressedShelfItem.model]
                        shelfItemViewModels = [longpressedShelfItem]
                    }
                }else {
                    shelfItemProtocols = [longpressedShelfItem.model]
                    shelfItemViewModels = [longpressedShelfItem]
                }
            }
        return (shelfItemProtocols,shelfItemViewModels)
    }
}
