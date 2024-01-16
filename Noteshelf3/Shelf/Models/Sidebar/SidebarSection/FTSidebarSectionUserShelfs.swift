//
//  FTSidebarSectionUserShelfs.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 12/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTSidebarSectionUserShelfs: FTSidebarSection {
    private var sidebarItemsBookmarksData: [FTCategorySortOrderInfo] = []
    private var categoryBookmarksData: FTCategoryBookmarkData = FTCategoryBookmarkData(bookmarksData: [])

    override var type: FTSidebarSectionType {
        get {return .categories}
        set {}
    }
    
    override var supportsRearrangeOfItems: Bool {
        get { return true}
        set {}
    }
    
    init() {
        super.init(type: .all, items: [], supportsRearrangeOfItems: false);
        self.prepreItems();
        NotificationCenter.default.addObserver(self, selector: #selector(self.categoryDidUpdate(_:)), name: .categoryItemsDidUpdateNotification, object: nil)
    }
    
    required init(type: FTSidebarSectionType, items: [FTSideBarItem], supportsRearrangeOfItems: Bool) {
        fatalError("init(type:items:supportsRearrangeOfItems:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .categoryItemsDidUpdateNotification, object: nil)
    }
    
}

private extension FTSidebarSectionUserShelfs {
    private func prepreItems() {
        userCreatedSidebarItems { [weak self] sidebarItems in
            guard let self = self else { return }
            runInMainThread { [weak self] in
                self?.items = sidebarItems;
            }
        }
    }
    
    private func userCreatedSidebarItems(onCompeltion : @escaping([FTSideBarItem]) -> Void) {
        var currentItems = Array(self.items);
        FTNoteshelfDocumentProvider.shared.fetchAllCollections { collections in
            DispatchQueue.global().async {
                var sidebarItems = [FTSideBarItem]();
                collections.forEach { eachCollection in
                    guard !eachCollection.isUnfiledNotesShelfItemCollection else {
                        return;
                    }
                    if let item = currentItems.first(where: {$0.id == eachCollection.uuid}) {
                        sidebarItems.append(item);
                        if item.title != eachCollection.title {
                            item.title = eachCollection.title
                        }
                    }
                    else {
                        let item = FTSideBarItem(shelfCollection: eachCollection);
                        sidebarItems.append(item);
                    }
                }
                let itemsToSet = sidebarItems;//self.sortCategoriesBasedOnStoredPlistOrder(sidebarItems,performURLResolving: true)
                onCompeltion(itemsToSet);
            }
        }
    }

    @objc func categoryDidUpdate(_ notification : Notification) {
        self.prepreItems()
    }
}

private extension FTSidebarSectionUserShelfs {
    func sortCategoriesBasedOnStoredPlistOrder(_ sidebarItems:[FTSideBarItem],performURLResolving:Bool = false) -> [FTSideBarItem] {
        var orderedSideBarItems : [FTSideBarItem: Int] = [:]
        let sortInfo = FTCategoryBookmarkData.categoriesOrderBasedOn(plistfechtedBookmarkData: self.categoryBookmarksData,performURLResolving: performURLResolving)
        sidebarItemsBookmarksData =  sortInfo.categorySortOrderInfo
        self.categoryBookmarksData = FTCategoryBookmarkData(bookmarksData: sortInfo.plistBookmarkData)
        var bookmarksData: [FTCategoryBookmarkDataItem] = self.categoryBookmarksData.bookmarksData
        for sideBarItem in sidebarItems {
            if let collection = sideBarItem.shelfCollection {
                if var existingCollectionInPlistIndex = bookmarksData.firstIndex(where:{$0.name == collection.URL.lastPathComponent}) {
                    let existingCollectionInPlist = bookmarksData[existingCollectionInPlistIndex]
                    let collectionOrder = existingCollectionInPlist.sortOrder
                    if existingCollectionInPlist.fileURL != collection.URL, let newBookmarkItem = newCategoryBookmarkDataItemForCollection(collection, sortOrder: collectionOrder) { // updating url in already collection existing plist data
                        bookmarksData.remove(at: existingCollectionInPlistIndex)
                        bookmarksData.append(newBookmarkItem)
                    }
                    orderedSideBarItems[sideBarItem] = collectionOrder
                } else {
                    let maxOrderValue = bookmarksData.map({$0.sortOrder}).max() ?? 0
                    let newOrderValue = bookmarksData.isEmpty ? 0 : maxOrderValue + 1
                    if let newBookmarkItem = newCategoryBookmarkDataItemForCollection(collection, sortOrder: newOrderValue){
                        bookmarksData.append(newBookmarkItem)
                        orderedSideBarItems[sideBarItem] = newOrderValue
                    }
                }
            }
        }
        self.updateSidebarCategoriesOrderUsingDict(FTCategoryBookmarkData(bookmarksData: bookmarksData))
        return orderedSideBarItems.sorted(by: {$0.value < $1.value}).compactMap({$0.key})
    }
    
    func newCategoryBookmarkDataItemForCollection(_ collection: FTShelfItemCollection, sortOrder: Int) -> FTCategoryBookmarkDataItem? {
        if let bookmarkData = URL.aliasData(collection.URL){
            return FTCategoryBookmarkDataItem(bookmarkData: bookmarkData,
                                       sortOrder: sortOrder,
                                       name: collection.URL.lastPathComponent,
                                       fileURL: collection.URL)
        }
        return nil
    }
    
    func updateSidebarCategoriesOrderUsingDict(_ categoriesBookmarData:FTCategoryBookmarkData){
        do {
            try FTSidebarManager.saveCategoriesBookmarData(categoriesBookmarData)
            self.categoryBookmarksData = categoriesBookmarData
        }
        catch {
            debugPrint("Failed to save categories order to plist.")
        }
    }
}
