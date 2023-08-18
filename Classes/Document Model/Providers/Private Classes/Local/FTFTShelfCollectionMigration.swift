//
//  FTFTShelfCollectionMigration.swift
//  Noteshelf
//
//  Created by Amar on 16/08/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTShelfItemCollectionMigration: FTShelfItemCollectionLocal {
    override var collectionType: FTShelfItemCollectionType {
        return FTShelfItemCollectionType.migrated;
    }
}

class FTShelfCollectionMigration : NSObject,FTShelfCollection,FTLocalQueryGatherDelegate,FTShelfCacheProtocol,FTShelfItemSorting
{
    func ns2Shelfs(_ onCompletion: @escaping (([FTShelfItemCollection]) -> Void)) {
        onCompletion([])
    }

    fileprivate var shelfCollections = [FTShelfItemCollection]();
    fileprivate var localDocumentsURL : URL!;
    fileprivate var query : FTLocalQueryGather?;
    
    fileprivate var tempCompletionBlock : (([FTShelfItemCollection])->Void)? = nil;
    
    fileprivate static func migratedFolderURL() -> URL
    {
        let noteshelfURL = FTUtils.noteshelfDocumentsDirectory();
        let systemURL = noteshelfURL.appendingPathComponent("Migrated Documents");
        let fileManger = FileManager();
        var isDir = ObjCBool.init(false);
        if(!fileManger.fileExists(atPath: systemURL.path, isDirectory: &isDir) || !isDir.boolValue) {
            try? fileManger.createDirectory(at: systemURL, withIntermediateDirectories: true, attributes: nil);
        }
        return systemURL;
    }
    
    override init() {
        super.init();

        let notificationBlock : (_ notification:Notification) -> Void =  { [weak self](notification) in
            if(UserDefaults.standard.bool(forKey: WelcomeScreenViewed)) {
                self?.processMigratedShelfCollection({ (_) in
                });
            }
        }
        NotificationCenter.default.addObserver(forName: UIScene.didActivateNotification, object: nil, queue: nil, using: notificationBlock)
    }
    
    static func shelfCollection(_ onCompletion: @escaping ((FTShelfCollection?) -> Void))
    {
        let migratedFolderURL = self.migratedFolderURL();
        let provider = FTShelfCollectionMigration();
        provider.localDocumentsURL = migratedFolderURL;
        provider.processMigratedShelfCollection { (success) in
            onCompletion(provider);
        }
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
                                            extensionsToListen: [shelfExtension],
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
    
    func createShelf(_ title: String, onCompletion:  @escaping ((NSError?, FTShelfItemCollection?) -> Void))
    {
        let uniqueName = FileManager.uniqueFileName(title+".shelf", inFolder: self.localDocumentsURL);
        self._createShelf(uniqueName, onCompletion: onCompletion);
    }
    
    func renameShelf(_ collection: FTShelfItemCollection,title: String, onCompletion: @escaping ((NSError?, FTShelfItemCollection?) -> Void))
    {
        let uniqueName = FileManager.uniqueFileName(title+".shelf", inFolder: self.localDocumentsURL);
        let destURL = self.localDocumentsURL.appendingPathComponent(uniqueName);
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
//            (collection as? FTSortIndexContainerProtocol)?.indexCache?.handleDeletionUpdate()
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
            collectionItem = FTShelfItemCollectionMigration.init(fileURL:fileItemURL);
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
    
    //MARK:- Migrated Collection -
    fileprivate static func sharedMigratedShelfCollectionPath() -> URL?
    {
        let fileManger = FileManager();
        var path = fileManger.containerURL(forSecurityApplicationGroupIdentifier: FTSharedGroupID.getAppGroupIdForNS1Migration());
        if(nil != path) {
            path = path!.appendingPathComponent("Migrated Documents");
        }
        return path;
    }
    
    fileprivate func processMigratedShelfCollection(_ onCompletion : @escaping (Bool)->Void)
    {
        if(FTShelfCollectionMigration.migrateShelfCollectionPresent()) {
            do {
                let migrationRootPath = FTShelfCollectionMigration.sharedMigratedShelfCollectionPath();
                let contents = try FileManager().contentsOfDirectory(atPath: migrationRootPath!.path);
                if(contents.count > 0) {
                    var pathsToAdd = [URL]();
                    var success = true;
                    for eachItem in contents {
                        if(eachItem.hasSuffix(".shelf")) {
                            let uniqueName = FileManager.uniqueFileName(migratedShelfName, inFolder: self.localDocumentsURL);
                            let endPath = self.localDocumentsURL.appendingPathComponent(uniqueName);
                            let sourcePath = migrationRootPath!.appendingPathComponent(eachItem);
                            
                            do {
                                try FileManager().moveItem(at: sourcePath, to: endPath);
                                pathsToAdd.append(endPath)
                            }
                            catch {
                                success = true;
                                break;
                            }
                        }
                    }
                    if(success) {
                        if(!pathsToAdd.isEmpty) {
                            self.addItemsToCache(pathsToAdd as [AnyObject])
                        }
                        runInMainThread {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: FTSuccessfullyMigratedNS1Notification), object: nil);
                        }
                    }
                    onCompletion(success);
                }
            }
            catch {
                onCompletion(false);
            }
        }
        else {
            onCompletion(true);
        }
    }
    
    static func migrateShelfCollectionPresent() -> Bool
    {
        var hasMigratedDocs : Bool = false;
        let migrationPath = self.sharedMigratedShelfCollectionPath();
        if(nil != migrationPath) {
            do {
                let contents = try FileManager().contentsOfDirectory(atPath: migrationPath!.path);
                if(contents.count > 0) {
                    for eachContent in contents {
                        if(eachContent.hasSuffix(".shelf")) {
                            hasMigratedDocs = true;
                            break;
                        }
                    }
                }
            }
            catch {
                hasMigratedDocs = false;
            }
        }
        return hasMigratedDocs;
    }
}
