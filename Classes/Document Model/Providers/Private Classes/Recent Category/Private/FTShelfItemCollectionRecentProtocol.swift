//
//  FTShelfItemCollectionRecentProtocol.swift
//  Noteshelf
//
//  Created by Amar on 14/06/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

protocol FTShelfItemCollectionRecentProtocol  : NSObjectProtocol {
    var collection : FTShelfItemCollectionRecent? {get set};
    var searchPaths : [String] {get set};
    var childrens : [FTShelfItemProtocol] {get set};
    
    init();
    init(withURLs : [String],collection : FTShelfItemCollectionRecent);
    
    func shelfItems(_ sortOrder : FTShelfSortOrder,
                    searchKey : String?,
                    onCompletion: @escaping (([FTShelfItemProtocol]) -> Void));
    
    func updateQuery(searchPaths : [String]);
    func addItemToCache(_ url : URL,addToLocalCache localCache : Bool) -> FTShelfItemProtocol;
    func removeItemFromCache(_ fileURL: Foundation.URL);
    func removeItemFromCache(_ fileURL: Foundation.URL, shelfItem: FTShelfItemProtocol);
    func moveCacheFromURL(oldURL : URL ,toURL newURL : URL);
    func shelfItemForURL(_ url : Foundation.URL) -> FTShelfItemProtocol?;
}

extension FTShelfItemCollectionRecentProtocol
{
    init(withURLs : [String],collection : FTShelfItemCollectionRecent)
    {
        self.init();
        self.collection = collection;
        self.searchPaths = withURLs;
    }
    
    func addItemToCache(_ url : URL,addToLocalCache localCache : Bool) -> FTShelfItemProtocol
    {
        objc_sync_enter(self);
        let item = FTDocumentItem.init(fileURL:url);
        item.shelfCollection = self.collection;
        if(!url.isUbiquitousFileExists()) {
            item.isDownloaded = true;
        }
        else if(url.downloadStatus() == .downloaded) {
            item.isDownloaded = true;
        }
        
        self.childrens.append(item);
        runInMainThread {
            NotificationCenter.default.post(name: NSNotification.Name.recentFavoriteAdded,
                                            object: self.collection,
                                            userInfo: [FTShelfItemsKey:[item]]);
        }
        objc_sync_exit(self);
        return item as FTShelfItemProtocol;
    }
    
    func removeItemFromCache(_ fileURL: Foundation.URL)
    {
        objc_sync_enter(self);
        let shelfItem = self.shelfItemForURL(fileURL);
        if(nil != shelfItem) {
            self.removeItemFromCache(fileURL, shelfItem: shelfItem!);
        }
        objc_sync_exit(self);
    }
    
    func removeItemFromCache(_ fileURL: Foundation.URL, shelfItem: FTShelfItemProtocol)
    {
        objc_sync_enter(self);
        let index = self.childrens.index { (eachItem) -> Bool in
            if(eachItem.URL == shelfItem.URL) {
                return true;
            }
            return false;
        }
        
        if(nil != index) {
            shelfItem.parent = nil;
            shelfItem.shelfCollection = nil;
            self.childrens.remove(at: index!);
            runInMainThread {
                NotificationCenter.default.post(name: NSNotification.Name.recentFavoriteRemoved,
                                                object: self.collection,
                                                userInfo: [FTShelfItemsKey:[shelfItem]]);
            }

        }
        objc_sync_exit(self);
    }
    
    func moveCacheFromURL(oldURL : URL ,toURL newURL : URL)
    {
        if let shelfItem = self.shelfItemForURL(oldURL) {
            shelfItem.URL = newURL;
            if(oldURL.urlByDeleteingPrivate() != newURL.urlByDeleteingPrivate()) {
                runInMainThread {
                    NotificationCenter.default.post(name: NSNotification.Name.recentFavoriteUpdated,
                                                    object: self.collection,
                                                    userInfo: [FTShelfItemsKey:[shelfItem]]);
                }
            }
        }
    }

    func shelfItemForURL(_ inurl : Foundation.URL) -> FTShelfItemProtocol?
    {
        var shelfItem : FTShelfItemProtocol?;
        let url = inurl.urlByDeleteingPrivate();
        for eachItem in self.childrens {
            let eachItemURL = eachItem.URL.urlByDeleteingPrivate();
            if(eachItemURL == url) {
                shelfItem = eachItem;
                break;
            }
        }
        return shelfItem;
    }
}
