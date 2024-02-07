//
//  FTSidebarSectionUserShelfs.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 12/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTSidebarSectionUserShelfs: FTSidebarSection {
    private var categoryBookmarksData: FTCategoryBookmarkData = FTCategoryBookmarkData(bookmarksData: [])
    private var recursiveLock = NSRecursiveLock();
    private var currentSaveOperation: DispatchWorkItem?
    
    override var type: FTSidebarSectionType {
        return .categories
    }
    
    override var supportsRearrangeOfItems: Bool {
        return true
    }
    
    required init() {
        super.init();
        
        let sideBarDict = FTSidebarManager.getSideBarData()
        if let sideBarItemsOrderDict = sideBarDict["SideBarItemsOrder"] as? [String: Any], let categoryBookmarkRawData = sideBarItemsOrderDict["categories"] as? Data, let categoryBookmarkData = try? PropertyListDecoder().decode(FTCategoryBookmarkData.self, from: categoryBookmarkRawData) {
            self.categoryBookmarksData = categoryBookmarkData;
        }
        
        self.prepreItems(false);
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.categoryDidUpdate(_:)), name: .categoryItemsDidUpdateNotification, object: nil)
    }
    
    override func fetchItems() {
        self.prepreItems();
    }
    
    override func moveItem(fromOrder: Int, toOrder: Int) -> Bool {
        let success = super.moveItem(fromOrder: fromOrder, toOrder: toOrder)
        if success {
            self.saveSortOrderInBackground();
        }
        return success
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .categoryItemsDidUpdateNotification, object: nil)
    }
    
}

private extension FTSidebarSectionUserShelfs {
    private func prepreItems(_ inbackground: Bool = false) {
        userCreatedSidebarItems(inbackground) { [weak self] sidebarItems in
            guard let self = self else { return }
            if Thread.current.isMainThread {
                self.items = sidebarItems;
            }
            else {
                runInMainThread {
                    self.items = sidebarItems;
                }
            }
        }
    }
    
    private func userCreatedSidebarItems(_ inbackground: Bool,onCompeltion : @escaping([FTSideBarItem]) -> Void) {
        let currentItems = Array(self.items);
        FTNoteshelfDocumentProvider.shared.fetchAllCollections { collections in
            func performAction() {
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
                let itemsToSet = self.sortItems(sidebarItems);
                onCompeltion(itemsToSet);
            }
            if inbackground {
                DispatchQueue.global().async {
                    performAction();
                }
            }
            else {
                performAction();
            }
        }
    }

    @objc func categoryDidUpdate(_ notification : Notification) {
        self.prepreItems(true)
    }
}

private extension FTSidebarSectionUserShelfs {
    func sortItems(_ sidebarItems:[FTSideBarItem]) -> [FTSideBarItem] {
        recursiveLock.lock()
        let bookmarkData = self.categoryBookmarksData.bookmarksData;
        recursiveLock.unlock();
        
        let sortedItems = sidebarItems.sorted { sidebaritem1, sidebaritem2 in
            func bookmarkItem(_ item: FTSideBarItem) -> FTCategoryBookmarkDataItem? {
                let item1 = bookmarkData.first { eachItem in
                    if let url = eachItem.resolvedURL(), url.title == item.title {
                        return true;
                    }
                    return false
                }
                return item1;
            }
            let item1 = bookmarkItem(sidebaritem1)
            let item2 = bookmarkItem(sidebaritem2)
            
            if let _item1 = item1, let _item2 = item2 {
                return _item1.sortOrder < _item2.sortOrder;
            }
            if nil != item1 {
                return true;
            }
            if let item1URL = sidebaritem1.shelfCollection?.URL, let item2URL = sidebaritem2.shelfCollection?.URL {
                return item1URL.fileCreationDate.compare(item2URL.fileCreationDate) == .orderedAscending
            }
            return sidebaritem1.title.compare(sidebaritem2.title, options: [.caseInsensitive,.numeric], range: nil, locale: nil) == .orderedAscending;
        }
        return sortedItems;
    }
}

private extension FTSidebarSectionUserShelfs {
    func saveSortOrderInBackground() {
        currentSaveOperation?.cancel();
        let items = self.items;
        var _operation: DispatchWorkItem? = nil;
        _operation = DispatchWorkItem(block: {
            if _operation?.isCancelled  ?? true {
                self.recursiveLock.unlock();
                return;
            }
            var bookmarksData = [FTCategoryBookmarkDataItem]();
            items.enumerated().forEach { eachItem in
                if let url = eachItem.element.shelfCollection?.URL, let aliasData = URL.aliasData(url) {
                    let data = FTCategoryBookmarkDataItem(bookmarkData: aliasData, sortOrder: eachItem.offset, name: url.title, fileURL: url);
                    bookmarksData.append(data);
                }
            }
            let catagorySortData = FTCategoryBookmarkData(bookmarksData: bookmarksData);
            self.recursiveLock.lock()
            self.categoryBookmarksData = catagorySortData;
            self.recursiveLock.unlock();
            do {
                try FTSidebarManager.saveCategoriesBookmarData(catagorySortData)
            }
            catch {
                debugLog("save failed \(error.localizedDescription)");
            }
        })
        self.currentSaveOperation = _operation;
        if let operation = self.currentSaveOperation {
            DispatchQueue.global(qos: .background).asyncAfter(deadline: DispatchTime.now() + .milliseconds(500), execute: operation);
        }
    }
}
