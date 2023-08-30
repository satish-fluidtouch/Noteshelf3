//
//  FTShelfCollectionSystem.swift
//  Noteshelf
//
//  Created by Amar on 16/08/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//
import FTCommon
import UIKit

let trashCollectionTitle = "Trash.shelf";

class FTShelfItemCollectionSystem: FTShelfItemCollectionLocal {
    override var collectionType: FTShelfItemCollectionType {
        return FTShelfItemCollectionType.system;
    }
}

class FTShelfCollectionSystem : NSObject,FTShelfCollection,FTLocalQueryGatherDelegate,FTShelfCacheProtocol,FTShelfItemSorting {

    func belongsToNS2() -> Bool {
        false
    }

    static func TrashCollectionURL() -> URL
    {
        return self.systenFolderURL().appendingPathComponent(trashCollectionTitle);
    }
    
    fileprivate static func systenFolderURL() -> URL
    {
        let noteshelfURL = FTUtils.noteshelfDocumentsDirectory();
        let systemURL = noteshelfURL.appendingPathComponent("System");
        let fileManger = FileManager();
        var isDir = ObjCBool.init(false);
        if(!fileManger.fileExists(atPath: systemURL.path, isDirectory: &isDir) || !isDir.boolValue) {
            try? fileManger.createDirectory(at: systemURL, withIntermediateDirectories: true, attributes: nil);
        }
        return systemURL.urlByDeleteingPrivate();
    }
    
    fileprivate var shelfCollections = [FTShelfItemCollection]();
    fileprivate var localDocumentsURL : URL!;
    fileprivate var query : FTLocalQueryGather?;
    
    fileprivate var tempCompletionBlock : (([FTShelfItemCollection])->Void)? = nil;
    
    static func shelfCollection(_ onCompletion: @escaping ((FTShelfCollection) -> Void))
    {
        let systemURL = self.systenFolderURL();
        let fileManger = FileManager();
        let trashShelfURL = systemURL.appendingPathComponent(trashCollectionTitle);
        var isDir = ObjCBool.init(false);
        if(!fileManger.fileExists(atPath: trashShelfURL.path, isDirectory: &isDir) || !isDir.boolValue) {
            try? fileManger.createDirectory(at: trashShelfURL, withIntermediateDirectories: true, attributes: nil);
        }
        
        let provider = FTShelfCollectionSystem();
        provider.localDocumentsURL =  systemURL;
        onCompletion(provider);
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
            onCompletion(self.shelfCollections);
        }
        else {
            self.tempCompletionBlock = onCompletion;
            self.query = FTLocalQueryGather(rootURL: self.localDocumentsURL,
                                            extensionsToListen: [FTFileExtension.shelf],
                                            skipSubFolder : true,
                                            delegate: self);
            self.query?.startQuery();
        }
        objc_sync_exit(self);
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
    
    func trashCollection(_ onCompletion : ((FTShelfItemCollection) -> Void))
    {
        self._createShelf(trashCollectionTitle, onCompletion: { (error, collection) in
            if(nil != error) {
                if(ENABLE_SHELF_RPOVIDER_LOGS) {
                    #if DEBUG
                    debugPrint("error: \(String(describing: error))");
                    #endif
                }
            }
            onCompletion(collection!);
        });
    }
        
    func createShelf(_ title: String, onCompletion:  @escaping ((NSError?, FTShelfItemCollection?) -> Void))
    {
        assert(false, "Create Shelf is not supported on System Shelfs")
    }
    
    func renameShelf(_ collection: FTShelfItemCollection,title: String, onCompletion: @escaping ((NSError?, FTShelfItemCollection?) -> Void))
    {
        assert(false, "Rename shelf is not supported on System Shelfs")
    }
    
    func deleteShelf(_ collection: FTShelfItemCollection, onCompletion:  @escaping ((NSError?, FTShelfItemCollection?) -> Void))
    {
        assert(false, "Delete shelf is not supported on System Shelfs")
    }
    
    //MARK:- FTLocalQueryGatherDelegate
    func ftLocalQueryGather(_ query: FTLocalQueryGather, didFinishGathering results: [URL]?) {
        self.buildCache(results);
        if(tempCompletionBlock != nil) {
            self.shelfs(self.tempCompletionBlock!);
            self.tempCompletionBlock = nil;
        }
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
            var shelfItem = self.collectionForURL(fileURL);
            if(shelfItem == nil) {
                shelfItem = self.addItemToCache(fileURL) as? FTShelfItemCollection;
            }
            updatedDocumentURLs.append(fileURL);
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
            collectionItem = FTShelfItemCollectionSystem.init(fileURL:fileItemURL);
            self.shelfCollections.append(collectionItem!);
        }
        objc_sync_exit(self);
        if(ENABLE_SHELF_RPOVIDER_LOGS) {
            #if DEBUG
            debugPrint("\(#file.components(separatedBy: "/").last ?? ""): Added :\(fileURL.lastPathComponent)");
            #endif
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
            #if DEBUG
            debugPrint("\(#file.components(separatedBy: "/").last ?? ""): Removed :\(fileURL.lastPathComponent)");
            #endif
        }
    }
    
    
    func moveItemInCache(_ item: FTDiskItemProtocol, toURL: URL) -> Bool {
        objc_sync_enter(self);
        item.URL = toURL;
        let collection = item as! FTShelfItemCollection;
        for eachItem in collection.childrens {
            let newURL = toURL.appendingPathComponent(eachItem.URL.lastPathComponent);
            _ = (collection as! FTShelfCacheProtocol).moveItemInCache(eachItem, toURL: newURL);
        }
        objc_sync_exit(self);
        if(ENABLE_SHELF_RPOVIDER_LOGS) {
            #if DEBUG
            debugPrint("\(#file.components(separatedBy: "/").last ?? ""): Updated :\(toURL.lastPathComponent)");
            #endif
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
                    #if DEBUG
                    debugPrint("\(#file.components(separatedBy: "/").last ?? ""): Created shelf :\(shelfName)");
                    #endif
                }
            }
            catch let error as NSError{
                onCompletion(error,nil);
                if(ENABLE_SHELF_RPOVIDER_LOGS) {
                    #if DEBUG
                    debugPrint("\(#file.components(separatedBy: "/").last ?? ""): Create Shelf :\(shelfName) Failed");
                    #endif
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
                #if DEBUG
                debugPrint("\(#file.components(separatedBy: "/").last ?? ""): Create Shelf :\(shelfName) Availbale");
                #endif
            }
        }
    }
}
