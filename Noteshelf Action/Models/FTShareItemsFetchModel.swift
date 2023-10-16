//
//  FTShareItemsFetchModel.swift
//  Noteshelf Action
//
//  Created by Sameer on 16/12/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTShareItemsFetchModel: NSObject {
    var collection: FTShelfItemCollection?
    var group: FTGroupItemProtocol?
    var noteBook: FTShelfItemProtocol?
    var type = FTShareItemType.category
    var isProviderUpdated = false
    
    func fetchUserCategories(onCompeltion : @escaping ([FTShareItem]) -> Void) {
        FTNoteshelfDocumentProvider.shared.updateProviderForNoteShelfAction { isUpdated in
           // if isUpdated {
                self.isProviderUpdated = isUpdated
            FTNoteshelfDocumentProvider.shared.fetchAllCollections() { collections in
                    let items: [FTShareItem] = collections.map { collection -> FTShareItem in
                        let title = collection.isUnfiledNotesShelfItemCollection ? collection.displayTitle.localized : collection.displayTitle
                        let item = FTCategoryShareItem(id: collection.uuid, title: title, type: .category, collection: collection)
                        return item
                    }
                    onCompeltion(items)
                }
           // }
        }
    }
    
    func fetchShelfItems(onCompletion: @escaping ([FTShareItem]) -> Void) {
        if let collection = collection {
            let fetchShelfItemsOptions = FTFetchShelfItemOptions()
            fetchShelfItemsOptions.includesGroupItems = true
            FTNoteshelfDocumentProvider.shared.fetchShelfItems(forCollections: [collection], option: fetchShelfItemsOptions, parent: self.group) { shelfItems in
                let items: [FTShareItem] = shelfItems.map { item -> FTShareItem in
                    if let groupItem = item as? FTGroupItemProtocol {
                        return FTShelfShareItem(id: groupItem.uuid, title: groupItem.displayTitle, type: .group, shelfItem: groupItem, collection: collection)
                    } else {
                        return FTShelfShareItem(id: item.uuid, title: item.displayTitle, type: .noteBook, shelfItem: item, collection: collection)
                    }
                }
                onCompletion(items)
            }
        }
    }
}

