//
//  FTShelfCollectionLocal.swift
//  Noteshelf
//
//  Created by Amar on 17/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon
#if  !NS2_SIRI_APP && !NOTESHELF_ACTION
import ZipArchive
#endif

class FTShelfCollectionLocal : NSObject,FTShelfCollection,FTLocalQueryGatherDelegate,FTShelfCacheProtocol,FTShelfItemSorting
{
    fileprivate var shelfCollections = [FTShelfItemCollection]();

    fileprivate var localDocumentsURL: URL
    fileprivate let isNS2Collection: Bool

    fileprivate var query : FTLocalQueryGather?;

    fileprivate var tempCompletionBlock = [(([FTShelfItemCollection])->Void)]();

    required init(rootURL: URL, isNS2Collection: Bool) {
        self.localDocumentsURL = rootURL
        self.isNS2Collection = isNS2Collection
    }

    func refreshShelfCollection(onCompletion : @escaping (() -> Void))
    {
        self.query = nil;
        self.shelfs { (_) in
            onCompletion();
        }
    }
    
    func shelfs(_ onCompletion: @escaping (([FTShelfItemCollection]) -> Void)) {
        objc_sync_enter(self);
        if(nil != self.query) {
            #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
            if(self.shelfCollections.count == 0 && !UserDefaults.standard.bool(forKey: "DefaultShelfCreated")) {
                self.createDefaultShelfs({
                    onCompletion(self.shelfCollections);
                });
            }
            else {
                onCompletion(self.shelfCollections);
            }
            #else
                onCompletion(self.shelfCollections);
            #endif
        }
        else {            
            self.tempCompletionBlock.append(onCompletion);
            self.query = FTLocalQueryGather(rootURL: self.localDocumentsURL,
                                            extensionsToListen: [FTFileExtension.shelf],
                                            skipSubFolder : true,
                                            delegate: self);
            self.query?.startQuery();
        }
        objc_sync_exit(self);
    }

    func belongsToNS2() -> Bool {
        isNS2Collection
    }

    func collection(withTitle title : String) -> FTShelfItemCollection?
    {
        if(nil == self.query) {
            fatalError("shelfs should be called before calling this method");
        }
        for eachItem in self.shelfCollections {
            if(eachItem.URL.deletingPathExtension().lastPathComponent == title) {
                return eachItem;
            }
        }
        return nil;
    }
    
    func documentsDirectory() -> URL
    {
        return self.localDocumentsURL;
    }
    //TODO: RK Remove this default collection creation once we get confirmation from amar or akshay.
    fileprivate func defaultCollection(_ onCompletion : @escaping ((FTShelfItemCollection) -> Void))
    {
        let myNotesCollectionName = NSLocalizedString("MyNotes", comment: "My Notes");
        self._createShelf(myNotesCollectionName.appending(".shelf"), onCompletion: { (error, collection) in
            guard let collection = collection else {
                debugPrint("error: \(String(describing: error))")
                return
            }
            if(nil != error) {
                if(ENABLE_SHELF_RPOVIDER_LOGS) {
                    debugPrint("error: \(String(describing: error))");
                }
                onCompletion(collection);
            }
            else {
                UserDefaults.standard.set(true, forKey: "DefaultShelfCreated");
                UserDefaults.standard.synchronize();
                onCompletion(collection);
            }
        });
    }
    
    func createShelf(_ title: String, onCompletion:  @escaping ((NSError?, FTShelfItemCollection?) -> Void))
    {
        let uniqueName = FileManager.uniqueFileName(title+".shelf", inFolder: self.localDocumentsURL);
        
        func postNotification(_ url: URL) {
            if !Thread.current.isMainThread {
                runInMainThread {
                    postNotification(url);
                }
                return;
            }
            NotificationCenter.default.post(name: Notification.Name.collectionAdded,
                                            object: self,
                                            userInfo: [FTShelfItemsKey: [url]]);
        }
        
        self._createShelf(uniqueName) { (error, collection) in
            if let collectionURL = collection?.URL {
                postNotification(collectionURL);
            }
            onCompletion(error, collection)
        }
    }
    
    func renameShelf(_ collection: FTShelfItemCollection,title: String, onCompletion: @escaping ((NSError?, FTShelfItemCollection?) -> Void))
    {
        let uniqueName = FileManager.uniqueFileName(title+".shelf", inFolder: self.localDocumentsURL);
        let destURL = self.localDocumentsURL.appendingPathComponent(uniqueName).urlByDeleteingPrivate();
        var fileError : NSError?;
        
        do {
            try FileManager.init().moveItem(at: collection.URL, to: destURL);
            _ = self.moveItemInCache(collection, toURL: destURL);
        }
        catch let error as NSError {
            fileError = error;
        }
        onCompletion(fileError,collection);
        NotificationCenter.default.post(name: Notification.Name.collectionUpdated, object: self, userInfo: [FTShelfItemsKey : [collection.URL]])
    }
    
    func deleteShelf(_ collection: FTShelfItemCollection, onCompletion:  @escaping ((NSError?, FTShelfItemCollection?) -> Void))
    {
        var fileError : NSError?;
        
        do {
            try FileManager.init().removeItem(at: collection.URL as URL);
            self.removeItemFromCache(collection.URL as URL, shelfItem: collection);
        }
        catch let error as NSError {
            fileError = error;
        }
        onCompletion(fileError,collection);
        NotificationCenter.default.post(name: Notification.Name.collectionRemoved, object: self, userInfo: [FTShelfItemsKey : [collection.URL]])
    }
    
    //MARK:- FTLocalQueryGatherDelegate
    func ftLocalQueryGather(_ query: FTLocalQueryGather, didFinishGathering results: [URL]?) {
        self.buildCache(results);
        tempCompletionBlock.forEach { eachBlock in
            self.shelfs(eachBlock);
        }
        tempCompletionBlock.removeAll();
    }
    
    //MARK:- Cache Mgmt -
    fileprivate func buildCache(_ items: [URL]?) {
        self.shelfCollections.removeAll();
        if(nil != items) {
            if(items!.count > 0) {
                self.addItemsToCache(items! as [AnyObject]);
            }
        }
    }
    
    fileprivate func addItemsToCache(_ items: [AnyObject]) {
        objc_sync_enter(self);
        var updatedDocumentURLs = [URL]();
        
        let urls = items as! [URL];
        
        for eachItem in urls {
            let fileURL = eachItem;
            //Check if the document reference is present in documentMetadataItemHashTable.If the reference is found, its already added to cache. We just need to update the document with this metadataItem
            if(fileURL.pathExtension == FTFileExtension.shelf) {
                var shelfItem = self.collectionForURL(fileURL);
                if(shelfItem == nil) {
                    shelfItem = self.addItemToCache(fileURL) as? FTShelfItemCollection;
                }
                updatedDocumentURLs.append(fileURL);
            }
            else if(fileURL.pathExtension == FTFileExtension.sortIndex) {
               if let itemCollection = collectionForURL(fileURL) as? FTShelfItemCollectionLocal {
                    itemCollection.handleSortIndexFileUpdates(fileURL)
               }
            }
        }
        objc_sync_exit(self);
        if(updatedDocumentURLs.count > 0) {
            runInMainThread({
                NotificationCenter.default.post(name: Notification.Name.collectionAdded, object: self, userInfo: [FTShelfItemsKey:updatedDocumentURLs]);
            });
        }

    }

    //MARK: - FTShelfCacheProtocol -
    func addItemToCache(_ fileURL: URL) -> FTDiskItemProtocol? {
        objc_sync_enter(self);
        let fileItemURL = fileURL;
        var collectionItem = self.collectionForURL(fileItemURL);
        if(nil == collectionItem) {
            let item = FTShelfItemCollectionLocal(fileURL:fileItemURL);
            item.parent = self
            self.shelfCollections.append(item);
            collectionItem = item
        }
        objc_sync_exit(self);
        if(ENABLE_SHELF_RPOVIDER_LOGS) {
            debugPrint("\(#file.components(separatedBy: "/").last ?? ""): Added :\(fileURL.lastPathComponent)");
        }
        return collectionItem;
    }
    
    
    func removeItemFromCache(_ fileURL: URL, shelfItem: FTDiskItemProtocol) {
        objc_sync_enter(self);
        let index = self.shelfCollections.index(where: { (eachItem) -> Bool in
            if(eachItem.URL == shelfItem.URL) {
                return true;
            }
            return false;
        });
        if(nil != index) {
            self.shelfCollections.remove(at: index!);
        }
        objc_sync_exit(self);
        if(ENABLE_SHELF_RPOVIDER_LOGS) {
            debugPrint("\(#file.components(separatedBy: "/").last ?? ""): Removed :\(fileURL.lastPathComponent)");
        }
    }
    
    
    func moveItemInCache(_ item: FTDiskItemProtocol, toURL: URL) -> Bool {
        objc_sync_enter(self);
        item.URL = toURL.urlByDeleteingPrivate();
        let collection = item as! FTShelfItemCollection;
        for eachItem in collection.childrens {
            let newURL = toURL.urlByDeleteingPrivate().appendingPathComponent(eachItem.URL.lastPathComponent);
            _ = (collection as! FTShelfCacheProtocol).moveItemInCache(eachItem, toURL: newURL);
        }
        objc_sync_exit(self);
        if(ENABLE_SHELF_RPOVIDER_LOGS) {
            debugPrint("\(#file.components(separatedBy: "/").last ?? ""): Updated :\(toURL.lastPathComponent)");
        }
        return true;
    }

    //MARK:- private Methods -
    fileprivate func collectionForURL(_ url : URL) -> FTShelfItemCollection?
    {
        let items = self.shelfCollections.filter { (item) -> Bool in
            if(item.URL == url) {
                return true;
            }
            return false;
        }
        return items.first;
    }
    
    fileprivate func _createShelf(_ shelfName : String,onCompletion : (NSError?,FTShelfItemCollection?)->Void)
    {
        let defaultCollectionURL = self.localDocumentsURL.appendingPathComponent(shelfName);
        let fileManager = FileManager.init();
        // Simple delete to start
        var isDir = ObjCBool.init(false);
        if(!fileManager.fileExists(atPath: defaultCollectionURL.path, isDirectory: &isDir) || !isDir.boolValue) {
            do {
                try fileManager.createDirectory(at: defaultCollectionURL, withIntermediateDirectories: true, attributes: nil);
                let model = self.addItemToCache(defaultCollectionURL);
                onCompletion(nil,model as? FTShelfItemCollection);
                if(ENABLE_SHELF_RPOVIDER_LOGS) {
                    debugPrint("\(#file.components(separatedBy: "/").last ?? ""): Created shelf :\(shelfName)");
                }
            }
            catch let error as NSError{
                onCompletion(error,nil);
                if(ENABLE_SHELF_RPOVIDER_LOGS) {
                    debugPrint("\(#file.components(separatedBy: "/").last ?? ""): Create Shelf :\(shelfName) Failed");
                }
                return;
            }
        }
        else {
            var collectionModel = self.collectionForURL(defaultCollectionURL);
            if(nil == collectionModel) {
                collectionModel = self.addItemToCache(defaultCollectionURL) as? FTShelfItemCollection;
            }
            onCompletion(nil,collectionModel);
            if(ENABLE_SHELF_RPOVIDER_LOGS) {
                debugPrint("\(#file.components(separatedBy: "/").last ?? ""): Create Shelf :\(shelfName) Availbale");
            }
        }
    }
    
    fileprivate func createDefaultShelfs(_ onCompletion :@escaping (()->Void))
    {
        //createDefaultShelfCollection;
        self.defaultCollection { (defaultItem) in
            onCompletion();
        };
    }
}
