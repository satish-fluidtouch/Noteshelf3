//
//  FTShelfItemCollectionRecent_Local.swift
//  Noteshelf
//
//  Created by Amar on 14/06/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTShelfItemCollectionRecentPrivate: NSObject,FTShelfItemCollectionRecentProtocol,FTShelfItemSearching,FTShelfItemSorting
{
    weak var collection: FTShelfItemCollectionRecent?;
    var childrens: [FTShelfItemProtocol] = [FTShelfItemProtocol]();
    var searchPaths: [String] = [String]();
    
    fileprivate var initialGathering = true;
    override required init() {
        super.init();
    }

    deinit {
        #if DEBUG
        debugPrint("deinit FTShelfItemCollectionRecentPrivate");
        #endif
    }
    
    func shelfItems(_ sortOrder: FTShelfSortOrder, searchKey: String?, onCompletion: @escaping (([FTShelfItemProtocol]) -> Void))
    {
        if(!initialGathering) {
            objc_sync_enter(self);
            var shelfItems = self.childrens;
            if((nil != searchKey) && (searchKey!.count > 0)) {
                shelfItems = self.searchShelfItems(shelfItems, skipGroupItems: true, searchKey: searchKey!);
            }
            shelfItems = self.sortItems(shelfItems, sortOrder: sortOrder);
            objc_sync_exit(self);
            onCompletion(shelfItems);
        }
        else {
            objc_sync_enter(self);
            self.initialGathering = false;
            for eachItem in self.searchPaths {
                _ = self.addItemToCache(NSURL.init(fileURLWithPath: eachItem) as URL, addToLocalCache: false);
            }
            objc_sync_exit(self);
            self.shelfItems(sortOrder, searchKey: searchKey, onCompletion: onCompletion);
        }
    }
    
    func updateQuery(searchPaths: [String]) {
        if(self.initialGathering) {
            self.searchPaths = searchPaths;
            return;
        }
        
        let currentPaths = Set.init(self.searchPaths);
        let newPaths = Set.init(searchPaths);

        let newItemsToAdd = newPaths.subtracting(currentPaths);
        
        for eachItem in newItemsToAdd {
            let url = NSURL.init(fileURLWithPath: eachItem) as URL;
            let item = self.shelfItemForURL(url);
            if(nil == item) {
                _ = self.addItemToCache(url, addToLocalCache: false);
            }
        }

        let itemsToDelete = currentPaths.subtracting(newPaths);
        for eachItem in itemsToDelete {
            let url = NSURL.init(fileURLWithPath: eachItem) as URL;
            self.removeItemFromCache(url);
        }
        self.searchPaths = searchPaths;
    }
}
