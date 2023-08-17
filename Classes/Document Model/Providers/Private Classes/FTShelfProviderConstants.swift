//
//  FTShelfProviderConstants.swift
//  Noteshelf
//
//  Created by Amar on 24/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

let ENABLE_SHELF_RPOVIDER_LOGS : Bool = false; //only for debugging, enable to true

extension NSNotification.Name  {
    static let recentFavoriteUpdated = NSNotification.Name(rawValue: "FTRecentFavoriteShelfItemDidUpdatedNotification")
    static let recentFavoriteAdded = NSNotification.Name(rawValue: "FTRecentFavoriteShelfItemDidAddedNotification")
    static let recentFavoriteRemoved = NSNotification.Name(rawValue: "FTRecentFavoriteShelfItemDidRemovedNotification")
    
    static let collectionUpdated = NSNotification.Name(rawValue: "FTShelfCollectionDidUpdatedNotification")
    static let collectionRemoved = NSNotification.Name(rawValue: "FTShelfCollectionDidRemovedNotification")
    static let collectionAdded = NSNotification.Name(rawValue: "FTShelfCollectionDidAddedNotification")
    static let collectionAddedOrUpdated = NSNotification.Name(rawValue: "collectionAddedOrUpdated")
    
    static let shelfItemUpdated = NSNotification.Name(rawValue: "FTShelfItemDidUpdatedNotification")
    static let shelfItemRemoved = NSNotification.Name(rawValue: "FTShelfItemDidRemovedNotification")
    static let shelfItemAdded = NSNotification.Name(rawValue: "FTShelfItemDidAddedNotification")
    static let shelfItemRemoveLoader = NSNotification.Name(rawValue: "FTShelfItemRemoveLoadernotification")
    static let shelfItemMakeFavorite = NSNotification.Name(rawValue: "FTShelfItemMakeFavoritenotification")
    static let shelfItemUpdateCover = NSNotification.Name(rawValue: "FTShelfItemUpdateCovernotification")
    
    static let sortIndexPlistUpdated = NSNotification.Name(rawValue: "FTIndexItemDidUpdatedNotification")
}

let FTIndexItemCollectionKey = "FTIndexItemCollection";
let FTShelfItemsKey = "items";
let FTShelfUUIDKey = "shelfUUID";

