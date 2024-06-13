//
//  FTShelfViewModel+ShelfUpdateHandlers.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 26/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTCommon
class FTShelfRefreshOperation : NSObject
{
    var newShelfItems = [FTShelfItemProtocol]();
    var updatedItemsURL = [URL]() ;
    var shelfCollectionID = UUID().uuidString;
    var onCompletions = [(() -> Void)]();
    var updatedItems: [FTShelfItemProtocol]?;
}

//MARK: Handlers for shelf items added, updated and removed
extension FTShelfViewModel {
    @objc func shelfSortIndexUpdated(_ notification: Notification) {
        if self.sortOption == .manual
            ,let collection = notification.object as? FTShelfItemCollection
            ,(self.collection.isAllNotesShelfItemCollection || self.collection.uuid == collection.uuid) {
            self.reloadItems(force: true);
        }
    }
    
    @objc func shelfItemDidGetAdded(_ notification: Notification) {
        if let userInfo = notification.userInfo, let shelfCollection = notification.object as? FTShelfItemCollection {
            if(self.collection.uuid == shelfCollection.uuid ||
               self.collection.isAllNotesShelfItemCollection) { // To handle updates from other categories to All
                if let items = userInfo[FTShelfItemsKey] as? [FTShelfItemProtocol] {
                    items.forEach { (eachItem) in
                        if let parent = eachItem.parent as? FTGroupItem, !parent.isDownloading {
                            parent.invalidateTop3Notebooks()
                            parent.isUpdated = true
                        }
                    }
                }
                self.reloadItems(force: true);
            }
        }
    }
    
    @objc func shelfitemDidgetUpdated(_ notification: Notification){
        guard self.delegate?.canProcessNotification() == true else {
            return
        }

        guard let userInfo = notification.userInfo,
              let shelfCollection = notification.object as? FTShelfItemCollection else {
            return
        }

        //**************** To handle updates from other categories to All
        if self.collection.isAllNotesShelfItemCollection {
            self.reloadItems(force: false)
        } else {
            //****************
            if(self.collection.uuid == shelfCollection.uuid) {
                if let items = userInfo[FTShelfItemsKey] as? [FTShelfItemProtocol] {
                    var shouldReload = (nil != self.groupItem) ? false : true;
                    var parentsUpdated = Set<FTGroupItem>();
                    items.forEach { (eachItem) in
                        if let parent = eachItem.parent as? FTGroupItem, !parent.isDownloading {
                            parentsUpdated.insert(parent);
                            if let curGroup = self.groupItem as? FTGroupItem, curGroup == parent {
                                shouldReload = true;
                            }
                        }
                    }
                    parentsUpdated.forEach { eachItem in
                        eachItem.invalidateTop3Notebooks()
                        eachItem.isUpdated = true
                        eachItem.resetCachedDates()
                    }
                    if shouldReload {
                        self.reloadItems(force: false)
                    }
                }
            }
        }
    }
    
    @objc func groupitemDidgetAdded(_ notification: Notification){
        if let shelfCollection = notification.object as? FTShelfItemCollection {
            //**************** To handle updates from other categories to All
            if self.collection.isAllNotesShelfItemCollection {
                self.reloadItems(force: true);
            } else {
                //****************
                if(self.collection.uuid == shelfCollection.uuid) {
                    self.reloadItems(force: true)
                }
            }
        }
    }
    
    @objc func groupitemDidgetRemoved(_ notification: Notification){
        if let shelfCollection = notification.object as? FTShelfItemCollection {
            //**************** To handle updates from other categories to All
            if self.collection.isAllNotesShelfItemCollection {
                self.reloadItems(force: true);
            } else {
                //****************
                if(self.collection.uuid == shelfCollection.uuid) {
                    self.reloadItems(force: true)
                }
            }
        }
    }

    @objc func shelfItemDidGetRemoved(_ notification: Notification) {
        /*if self.isInSearchMode {
         return
         }*/
        if let userInfo = notification.userInfo, let shelfCollection = notification.object as? FTShelfItemCollection {
            //**************** To handle updates from other categories to All
            if self.collection.isAllNotesShelfItemCollection {
                self.reloadItems(force: true);
                return
            }
            //****************

            if(self.collection.uuid == shelfCollection.uuid) {
                if let removedItems = userInfo[FTShelfItemsKey] as? [FTShelfItemProtocol] {
                    removedItems.forEach { (eachItem) in
                        if let parent = eachItem.parent as? FTGroupItem, !parent.isDownloading  {
                            parent.invalidateTop3Notebooks()
                            parent.isUpdated = true
                        }
                    }
                    self.reloadItems(force: true)
                }
                else {
                    self.reloadItems(force: true)
                }
            }
            else if self.collection.isStarred {
                self.reloadShelf() // useful in case of favorites collection. As updates related to shelf items come under its own parent(Collection).
            }
        }
    }
        
    @objc func shelfItemDropOperationFinished(_ notification: Notification){
        self.fadeDraggedShelfItem = nil
    }
}

private extension FTShelfViewModel {
    private func hideGroup() {
        self.resetShelfModeTo(.normal)
        self.delegate?.hideCurrentGroup(animated: true, onCompletion: {
        })
    }

    private func itemBelongsToGroup(_ items: [FTShelfItemProtocol]) -> Bool {
        var shouldRefresh = false
        if let group = self.groupItem,!items.isEmpty {
            let groupURL = group.URL.relativePath
            for eachItem in items {
                let itemUrl = eachItem.URL.relativePath
                if itemUrl.hasPrefix(groupURL) {
                    shouldRefresh = true
                    break
                }
            }
        }
        return shouldRefresh;
    }
}
