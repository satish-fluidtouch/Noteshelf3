//
//  FTShelfCategoryCollection.swift
//  Noteshelf
//
//  Created by Amar on 18/12/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTShelfCategoryCollectionRecent: FTShelfCategoryCollection {
    private weak var shelfCollection : FTShelfItemCollection?;
    private var recentItems : [FTShelfItemProtocol] = [FTShelfItemProtocol]();
    override var canAdd : Bool {
        return false;
    }
    
    override var items: [FTDiskItemProtocol] {
        get {
            if type == .recent {
                return self.recentItems
            }
            return super.items
        }
        set {

        }
    }
    
    override init(name: String = "", type: FTShelfCategoryType = .none, categories inCategories: [FTShelfItemCollection]) {
        super.init(name: name, type: type, categories: inCategories)
        shelfCollection = inCategories.first
        self.loadShelfItems();
        self.addNotificationObserver();
    }
    
    private func loadShelfItems() {
        shelfCollection?.shelfItems(.byModifiedDate,
                                    parent: nil,
                                    searchKey: nil,
                                    onCompletion: { [weak self] (items) in
                                    self?.recentItems = items
        });
    }
    
    deinit {
        NSObject.cancelPreviousPerformRequests(withTarget: self);
    }
    
    private func addNotificationObserver()
    {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didUpdateRecentitems(_:)),
                                               name: NSNotification.Name.recentFavoriteAdded,
                                               object: nil);

        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didUpdateRecentitems(_:)),
                                               name: NSNotification.Name.recentFavoriteRemoved,
                                               object: nil);
        

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didUpdateRecentitems(_:)),
                                               name: NSNotification.Name.recentFavoriteUpdated,
                                               object: nil);
    }
    
    @objc private func didUpdateRecentitems(_ notification : Notification)
    {
        if let item = notification.object as? FTShelfItemCollection,
            item.uuid == self.shelfCollection?.uuid {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.scheduleTrigger), object: nil);
            self.perform(#selector(self.scheduleTrigger), with: nil, afterDelay: 0.1);
        }
    }
    
    @objc private func scheduleTrigger()
    {
        self.loadShelfItems();
        if self.type == .starred {
            self.notifyUpdatedItems(ofType: FTShelfCollectionAndEventType(collectionEventType: FTShelfEventType.other, collectionType: FTShelfCategoryType.starred))
        }
        else {
            self.notifyUpdatedItems(ofType: FTShelfCollectionAndEventType(collectionEventType: FTShelfEventType.other, collectionType: FTShelfCategoryType.recent))
        }
    }
}
