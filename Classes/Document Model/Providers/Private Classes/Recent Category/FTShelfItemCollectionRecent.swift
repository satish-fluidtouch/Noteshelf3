//
//  FTShelfItemCollectionRecent.swift
//  Noteshelf
//
//  Created by Amar on 11/06/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

extension Notification.Name {
    static let shelfItemDidGetDeletedInternal = Notification.Name("FTShelfItemDidGetDeletedInternalNotification");

    static let shelfItemDidGetMovedInternal = Notification.Name("FTShelfItemDidGetMovedInternalNotification");
}

let FTOldURLS = "FTOldURLS";
let FTNewURLS = "FTNewURLS";

class  FTShelfItemCollectionRecent: NSObject,FTShelfItemCollection,FTShelfItemSorting,
    FTShelfItemSearching,FTShelfItemDocumentStatusChangePublisher
{
    var downloadStatusChangedItems = FTHashTable();
    var timer : Timer?
    var title: String {
        return (collectionType == .starred) ? NSLocalizedString("sidebar.topSection.starred", comment: "Starred") : self.URL.title
    }
    internal var recentCollectionLocal : FTShelfItemCollectionRecentPrivate?;

    fileprivate var executionQueue = DispatchQueue(label: "com.fluidtouch.cloudShelfItemCollection");

    required init(fileURL: Foundation.URL)
    {
        URL = fileURL;
        super.init();
        NotificationCenter.default.addObserver(self, selector: #selector(self.itemsDidGetDeleted(_:)), name: .shelfItemDidGetDeletedInternal, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(self.itemsDidGetMoved(_:)), name: .shelfItemDidGetMovedInternal, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(self.itemsDidGetDownloaded(_:)), name: NSNotification.Name(rawValue: "RefreshRecent"), object: nil);
    }
    
    deinit {
        #if DEBUG
            debugPrint("deinit \(self.classForCoder)");
        #endif
    }

    var URL: URL;
    
    var uuid: String = FTUtils.getUUID();
    
    var type: RKShelfItemType = RKShelfItemType.shelfCollection;
    
    //shelf collection attributes
    var childrens : [FTShelfItemProtocol] {
        get {
            return self.recentCollectionLocal?.childrens ?? [FTShelfItemProtocol]();
        }
        set {
            self.recentCollectionLocal?.childrens = newValue;
        }
    };
    
    var collectionType : FTShelfItemCollectionType {
        return .recent;
    };
    
    var items : [FTDiskRecentItem] {
        return FTRecentEntries.allRecentEntries();
    }
    
    func shelfItems(_ sortOrder : FTShelfSortOrder,
                    parent : FTGroupItemProtocol?,
                    searchKey : String?,
                    onCompletion completionBlock: @escaping (([FTShelfItemProtocol]) -> Void))
    {
        self.executionQueue.async {
            let recentItems = self.items;
            let paths = NSURL.urlPaths(recentItems);
            if(nil == self.recentCollectionLocal) {
                self.recentCollectionLocal = FTShelfItemCollectionRecentPrivate(withURLs: paths,
                                                                                collection: self);
            }
            else {
                self.updateQueryForChangeInRecentEntries()
            }
            self.recentCollectionLocal?.shelfItems(sortOrder,
                                                   searchKey: searchKey,
                                                   onCompletion:
                                                    { (items) in
                var shelfItems = [FTShelfItemProtocol]();
                shelfItems.append(contentsOf: items);
                shelfItems.sort(by: { (item1, item2) -> Bool in
                    if let index1 = recentItems.firstIndex(where: { (eachInfo) -> Bool in
                        let eachPath = eachInfo.filePath
                        let pathURL = NSURL.init(fileURLWithPath: eachPath!) as URL;
                        return (pathURL == item1.URL);
                    }),
                       let index2 = recentItems.firstIndex(where: { (eachInfo) -> Bool in
                           let eachPath = eachInfo.filePath
                           let pathURL = NSURL.init(fileURLWithPath: eachPath!) as URL;
                           return (pathURL == item2.URL);
                       }) {
                        return (index1 < index2);
                    } else {
                        return false
                    }
                });
                DispatchQueue.main.async {
                    completionBlock(shelfItems);
                }
            });
        }
    }
    
    //MARK:- Recent
    @discardableResult func addShelfItemToList(_ inurl : URL) -> NSError?
    {
        let url = inurl.urlByDeleteingPrivate();
        if FTRecentEntries.saveEntry(url, mode: .recent) {            
            var item1 : FTShelfItemProtocol?;
            item1 = self.recentCollectionLocal?.shelfItemForURL(url);
            var isPositionUpdated = true;
            if(nil == item1) {
                item1 = self.recentCollectionLocal?.addItemToCache(url, addToLocalCache: true);
                isPositionUpdated = false;
            }
            
            if let shelfItem = item1,isPositionUpdated {
                runInMainThread {
                    NotificationCenter.default.post(name: NSNotification.Name.recentFavoriteUpdated,
                                                    object: self,
                                                    userInfo: [FTShelfItemsKey:[shelfItem]]);
                }
            }
        }
        return nil;
    }
    
    func removeShelfItemFromList(_ urls : [URL])
    {
        for eachURL in urls {
            if(FTRecentEntries.deleteEntry(eachURL, mode: .recent)) {
                self.recentCollectionLocal?.removeItemFromCache(eachURL);
            }
        }
    }
    
    func updateQueryForChangeInRecentEntries()
    {
        let items = FTRecentEntries.allRecentEntries();
        let paths = NSURL.urlPaths(items);
        self.recentCollectionLocal?.updateQuery(searchPaths: paths);
    }

    func isNS2Collection() -> Bool {
        return false
    }
}

extension FTShelfItemCollectionRecent
{
    @objc func itemsDidGetDownloaded(_ notification : NSNotification)
    {
        DispatchQueue.global().async { [weak self] in
            if let not = notification.object as? FTDocumentItem {
                if let item = self?.recentCollectionLocal?.shelfItemForURL(not.URL) {
                    runInMainThread {
                        NotificationCenter.default.post(name: NSNotification.Name.recentFavoriteAdded,
                                                        object: self,
                                                        userInfo: nil);
                    }
                }
            }
        }
    }

    @objc func itemsDidGetDeleted(_ notification : NSNotification)
    {
        if let userInfo = notification.userInfo {
            let newURLS = userInfo[FTNewURLS] as! [URL];
            self.removeShelfItemFromList(newURLS);
        }
    }
    
    @objc func itemsDidGetMoved(_ notification : NSNotification)
    {
        if let userInfo = notification.userInfo,
            let oldURLS = userInfo[FTOldURLS] as? [URL],
            let newURLS = userInfo[FTNewURLS] as? [URL] {
            
            let mode: FTRecentItemType = (self.collectionType == .starred) ? .favorites : .recent;

            oldURLS.enumerated().forEach { eachURLElement in
                let oldURL = eachURLElement.element;
                let index = eachURLElement.offset;
                let newURL = newURLS[index];
                if FTRecentEntries.updateEntry(oldURL, with: newURL, mode: mode) {
                    self.moveItemFrom(oldURL: oldURL, toNewURL: newURL);
                }
            }
        }
    }
    
    private func moveItemFrom(oldURL : URL, toNewURL newURL : URL)
    {
        self.recentCollectionLocal?.moveCacheFromURL(oldURL: oldURL, toURL: newURL);
    }
}

extension NSURL
{
    static func urlPaths(_ paths : [FTDiskRecentItem]) -> [String]
    {
        var localPaths = [String]();
        for eachInfo in paths {
            if let eachPath = eachInfo.filePath {
                localPaths.append(eachPath);
            }
        }
        return localPaths;
    }
}

extension URL {
    static func aliasData(_ sourceURL : URL) -> Data? {
        do {
            let bookmarkdata = try sourceURL.bookmarkData(options: .suitableForBookmarkFile);
            return bookmarkdata;
        }
        catch {
            // Soft handling of the undownloaded books trying to be starred.
            return nil
            //fatalError("Bookmark creation failed");
        }
    }
    
    static func resolvingAliasData(_ data: Data,isStale: inout Bool) -> URL? {
        if(Thread.current.isMainThread) {
            fatalError("resolvingAliasData should not be called on main thread")
        }
        do {
            let resolvedURL = try URL(resolvingBookmarkData: data, bookmarkDataIsStale: &isStale);
            return resolvedURL;
        }
        catch {
            
        }
        return nil;
    }
}
