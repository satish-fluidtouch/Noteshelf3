//
//  FTShelfCategoryCollection.swift
//  Noteshelf
//
//  Created by Siva on 30/08/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

enum FTShelfCategoryType : Int
{
    case none
    case user
    case starred
    case recent
    case systemDefault
}
enum FTShelfEventType : String{
    case collectionAdded
    case other
}
struct FTShelfCollectionAndEventType {
    let collectionEventType : FTShelfEventType
    let collectionType : FTShelfCategoryType
}

let FTCategoryItemsDidUpdateNotification = NSNotification.Name.init(rawValue: "FTCategoryItemsDidUpdateNotification");

class FTShelfCategoryCollection: NSObject {
    var name: String;
    var title: String {
        var sectionTitle: String = self.name
        switch (self.type) {
            case .user:
                sectionTitle = NSLocalizedString("Categories", comment: "Categories")
            default:
                sectionTitle = self.name
        }
        return sectionTitle;
    }

    var categories: [FTShelfItemCollection] {
        if let shelfs = self.items as? [FTShelfItemCollection] {
            return shelfs
        }
        return []
    }
    var items: [FTDiskItemProtocol];
    var type : FTShelfCategoryType = .none
    var canAdd : Bool {
        return (self.type != .none);
    }
    
    var isCollapsed : Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: "collapsed_category_\(self.type)");
            UserDefaults.standard.synchronize();
        }
        get {
            return UserDefaults.standard.bool(forKey: "collapsed_category_\(self.type)") ;
        }
    }
    
    init(name: String = "", type: FTShelfCategoryType = .none, categories inCategories: [FTShelfItemCollection]) {
        items = inCategories;
        self.name = name;
        self.type = type
        
        super.init()
        if self.type == .user {
            NotificationCenter.default.addObserver(self, selector: #selector(handleShelfCategoryUpdates(_:)), name: NSNotification.Name.collectionAdded, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handleShelfCategoryUpdates(_:)), name: NSNotification.Name.collectionUpdated, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handleShelfCategoryUpdates(_:)), name: NSNotification.Name.collectionRemoved, object: nil)
        }
    }
    
    @objc func handleShelfCategoryUpdates(_ notification: Notification) {
        FTNoteshelfDocumentProvider.shared.userShelfCollections { [weak self] (shelfs) in
            guard let self = self else { return }
            self.items = shelfs
            let eventType = (notification.name.rawValue == Notification.Name.collectionAdded.rawValue) ? FTShelfEventType.collectionAdded : FTShelfEventType.other
            self.notifyUpdatedItems(ofType: FTShelfCollectionAndEventType(collectionEventType: eventType, collectionType: FTShelfCategoryType.user))
        }
    }

    func indexOfItem(_ item : FTDiskItemProtocol) -> Int?
    {
        let rowIndex = self.items.firstIndex(where: { (eachItem) -> Bool in
            return (eachItem.uuid == item.uuid)
        })
        return rowIndex;
    }

    func notifyUpdatedItems(ofType type: FTShelfCollectionAndEventType) {
        NotificationCenter.default.post(name: FTCategoryItemsDidUpdateNotification, object: type)
    }
}
