//
//  FTShelfCollectioniCloud.swift
//  Noteshelf
//
//  Created by Amar on 17/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTDocumentFramework
import FTCommon

class FTShelfCollectioniCloud: NSObject, FTUniqueNameProtocol {

    weak var listenerDelegate: FTQueryListenerProtocol?

    fileprivate var shelfCollections = [FTShelfItemCollection]();
    fileprivate let iCloudDocumentsURL: URL

    fileprivate var hashTable = FTHashTable();

    //Temporary
    fileprivate var isInitialGatheringCompleted: Bool = false
    fileprivate var tempCompletionBlock = [(([FTShelfItemCollection]) -> Void)]();
    fileprivate var orphanMetadataItems = [NSMetadataItem]();
    deinit {
        hashTable.removeAll()
        #if DEBUG
            debugPrint("deinit \(self.classForCoder)");
        #endif
    }

    required init(rootURL: URL) {
        self.iCloudDocumentsURL = rootURL.appendingPathComponent("Documents").urlByDeleteingPrivate()
    }

    func refreshShelfCollection(onCompletion : @escaping (() -> Void))
    {
        self.shelfs { _ in
            onCompletion();
        }
    }

    func shelfs(_ onCompletion: @escaping (([FTShelfItemCollection]) -> Void)) {
        objc_sync_enter(self);
        if isInitialGatheringCompleted {
            DispatchQueue.main.async(execute: {
                onCompletion(self.shelfCollections);
            })
        } else {
            tempCompletionBlock.append(onCompletion)
        }
        objc_sync_exit(self);
    }

    func collection(withTitle title: String) -> FTShelfItemCollection? {
        for eachItem in self.shelfCollections {
            if(eachItem.URL.deletingPathExtension().lastPathComponent == title) {
                return eachItem;
            }
        }
        return nil;
    }

    func documentsDirectory() -> URL {
        return self.iCloudDocumentsURL;
    }

    func disableUpdates() {
        self.listenerDelegate?.disableUpdates()
    }

    func enableUpdates() {
        self.listenerDelegate?.enableUpdates()
    }
}

// MARK: - FTShelfCollection -
extension FTShelfCollectioniCloud: FTShelfCollection {

    func createShelf(_ title: String, onCompletion: @escaping ((NSError?, FTShelfItemCollection?) -> Void)) {
        self.disableUpdates()
        self.shelfs { items in
            let name = self.uniqueFileName(title+".shelf", inItems: items);
            self.createNewShelf(name) { error, collecttion in
                if(nil == error) {
                    onCompletion(nil, collecttion);
                } else {
                    onCompletion(error, nil);
                }
                self.enableUpdates();
            }
        };
    }

    func renameShelf(_ collection: FTShelfItemCollection, title: String, onCompletion: @escaping ((NSError?, FTShelfItemCollection?) -> Void)) {
        self.disableUpdates()
        self.shelfs { items in
            let name = self.uniqueFileName(title+".shelf", inItems: items);
            let destURL = self.iCloudDocumentsURL.appendingPathComponent(name)
            DispatchQueue.global().async(execute: {
                let fileCoordinator = NSFileCoordinator(filePresenter: nil);
                fileCoordinator.coordinate(writingItemAt: collection.URL, options: NSFileCoordinator.WritingOptions.forMoving, writingItemAt: destURL, options: NSFileCoordinator.WritingOptions.forReplacing, error: nil, byAccessor: { newURL1, newURL2 in
                    var error: NSError?;
                    do {
                        try FileManager().moveItem(at: newURL1, to: newURL2);
                        _ = self.moveItemInCache(collection, toURL: newURL2);
                    } catch let failError as NSError {
                        error = failError;
                    }

                    DispatchQueue.main.async(execute: {
                        onCompletion(error, collection);
                        self.enableUpdates();
                    });
                });
            });
        };
    }

    func deleteShelf(_ collection: FTShelfItemCollection, onCompletion: @escaping ((NSError?, FTShelfItemCollection?) -> Void)) {
        self.disableUpdates()
        DispatchQueue.global().async(execute: {
            let fileCordinator = NSFileCoordinator(filePresenter: nil);

            fileCordinator.coordinate(writingItemAt: collection.URL as URL,
                options: NSFileCoordinator.WritingOptions.forDeleting,
                error: nil,
                byAccessor: { writingURL in
                    var error: NSError?;
                    do {
                        _ = try FileManager().removeItem(at: writingURL);
                        self.removeItemFromCache(collection.URL as URL, shelfItem: collection);
                    } catch let failError as NSError {
                        error = failError;
                    }
                    DispatchQueue.main.async(execute: {
                        onCompletion(error, collection);
                        self.enableUpdates()
                    });
            });
        });
    }
}

// MARK: - FTMetadataCachingProtocol
extension FTShelfCollectioniCloud: FTMetadataCachingProtocol {
    
    var canHandleAudio: Bool {
        return false
    }
    
    func willBeginFetchingInitialData() {
        self.shelfCollections.removeAll();
        self.hashTable.removeAll()
    }
    
    func didEndFetchingInitialData() {
        
        isInitialGatheringCompleted = true
        self.tempCompletionBlock.forEach { eachBlock in
            self.shelfs(eachBlock);
        }
        self.tempCompletionBlock.removeAll();
    }
    
    func addMetadataItemsToCache(_ metadataItems: [NSMetadataItem], isBuildingCache: Bool) {
        var updatedDocumentURLs = [URL]();

        for eachItem in metadataItems {
                let fileURL = eachItem.URL();
                if(fileURL.pathExtension == FTFileExtension.shelf) {
                    if(eachItem.downloadStatus() == NSMetadataUbiquitousItemDownloadingStatusNotDownloaded) {
                        try? FileManager().startDownloadingUbiquitousItem(at: fileURL);
                    }
                    //Check if the document reference is present in documentMetadataItemHashTable.If the reference is found, its already added to cache. We just need to update the document with this metadataItem
                    var shelfItem = self.hashTable.itemFromHashTable(eachItem) as? FTShelfItemCollection;
                    if(shelfItem == nil) {
                        if(!isBuildingCache) {
                            shelfItem = self.collectionForURL(fileURL);
                        }
                        if(shelfItem == nil) {
                            shelfItem = self.addItemToCache(fileURL) as? FTShelfItemCollection;
                            checkAndUpdateOrphans()
                        }

                        if(shelfItem != nil) {
                            if(!eachItem.isItemDownloaded()) {
                                //If in cache, use that object and set it to the documentMetadataItemHashTable.
                                do {
                                    _ = try FileManager().startDownloadingUbiquitousItem(at: fileURL as URL);
                                } catch let error as NSError {
                                    FTLogError("Notebook Download failed", attributes: error.userInfo);
                                }
                            }
                            self.hashTable.addItemToHashTable(shelfItem!, forKey: eachItem);
                        }
                        updatedDocumentURLs.append(fileURL);
                    }

                    (shelfItem as? FTDocumentItemProtocol)?.updateShelfItemInfo(eachItem);
                    if(ENABLE_SHELF_RPOVIDER_LOGS) {
                        #if DEBUG
                        debugPrint("\(self.classForCoder): Added:\(fileURL.lastPathComponent)");
                        #endif
                    }
                }
                else if(fileURL.pathExtension == FTFileExtension.sortIndex) {
                    if(self.belongsToDocumentsFolder(fileURL)) {
                       if let itemCollection = collectionForURL(fileURL) as? FTShelfItemCollectionICloud {
                            itemCollection.handleSortIndexFileUpdates(eachItem)
                       }
                    }
                } else if (fileURL.pathExtension == FTFileExtension.group) {
                    _ = self.addShelfItemToCache(eachItem, isBuildingCache: isBuildingCache) as? FTShelfItemCollection;
                } else {
                    _ = self.addShelfItemToCache(eachItem, isBuildingCache: isBuildingCache) as? FTShelfItemCollection;
                }

            if(!updatedDocumentURLs.isEmpty) {
                runInMainThread({
                    NotificationCenter.default.post(name: Notification.Name.collectionAdded, object: self, userInfo: [FTShelfItemsKey: updatedDocumentURLs]);
                });
            }
        }
    }

    func removeMetadataItemsFromCache(_ metadataItems: [NSMetadataItem]) {

        var updatedDocumentURLs = [URL]();

        for eachItem in metadataItems {
            autoreleasepool {
                let fileURL = eachItem.URL();
                if fileURL.pathExtension == FTFileExtension.shelf {
                    
                    let shelfItem = self.hashTable.itemFromHashTable(eachItem) as? FTShelfItemCollection;
                    updatedDocumentURLs.append(fileURL as URL);
                    
                    if(nil != shelfItem) {
                        self.removeItemFromCache(fileURL, shelfItem: shelfItem!);
                        self.hashTable.removeItemFromHashTable(eachItem);
                        if(ENABLE_SHELF_RPOVIDER_LOGS) {
                            #if DEBUG
                            debugPrint("\(self.classForCoder): Removed:\(fileURL.lastPathComponent)");
                            #endif
                        }
                    }
                } else {
                    if let shelfItem = self.collectionForMetadata(eachItem) as? FTShelfItemCollectionICloud {
                        shelfItem.removeItemsFromCache([eachItem])
                    }
                }
            }
        }
        if(!updatedDocumentURLs.isEmpty) {
            runInMainThread({
                NotificationCenter.default.post(name: Notification.Name.collectionRemoved, object: self, userInfo: [FTShelfItemsKey: updatedDocumentURLs]);
            });
        }
    }

    func updateMetadataItemsInCache(_ metadataItems: [NSMetadataItem]) {
        var updatedDocumentURLs = [URL]();
        var addedItems = [NSMetadataItem]();
        var deletedItems = [NSMetadataItem]();

        for eachItem in metadataItems {
            autoreleasepool {
                let fileURL = eachItem.URL();
                if fileURL.pathExtension == FTFileExtension.shelf {
                    var shelfItem = self.hashTable.itemFromHashTable(eachItem) as? FTShelfItemCollection;
                    if(nil == shelfItem) {
                        shelfItem = self.collectionForURL(fileURL);
                    }
                    
                    if(shelfItem != nil) {
                        let success = self.moveItemInCache(shelfItem!, toURL: fileURL);
                        if(success) {
                            //Update the document document attributes
                            (shelfItem as? FTDocumentItemProtocol)?.updateShelfItemInfo(eachItem);
                            updatedDocumentURLs.append((shelfItem?.URL)!);
                        }
                    }
                    if(ENABLE_SHELF_RPOVIDER_LOGS) {
                        #if DEBUG
                        debugPrint("\(self.classForCoder): Updated:\(fileURL.lastPathComponent)");
                        #endif
                    }
                }
                else if(fileURL.pathExtension == FTFileExtension.sortIndex) {
                    if(self.belongsToDocumentsFolder(fileURL)) {
                        if let itemCollection = collectionForURL(fileURL) as? FTShelfItemCollectionICloud {
                            itemCollection.handleSortIndexFileUpdates(eachItem)
                        }
                    }
                }
                else {
                    if let previousShelfItemCollection = self.collectionForMetadata(eachItem) as? FTShelfItemCollectionICloud {
                        let currentShelfItemCollection = self.collectionForURL(fileURL) as? FTShelfItemCollectionICloud
                        if currentShelfItemCollection == previousShelfItemCollection {
                            currentShelfItemCollection?.updateItemsInCache([eachItem])
                        } else {
                            deletedItems.append(eachItem)
                            addedItems.append(eachItem)
                        }
                    }
                }
            }
        }
        shelfCollections.forEach { collection in
            if !deletedItems.isEmpty {
                (collection as? FTShelfItemCollectionICloud)?.removeItemsFromCache(deletedItems)
            }
            if !addedItems.isEmpty {
                (collection as? FTShelfItemCollectionICloud)?.addItemsToCache(addedItems)
            }
        }
        if (!updatedDocumentURLs.isEmpty) {
            runInMainThread({
                NotificationCenter.default.post(name: .collectionUpdated,
                                                object: self,
                                                userInfo: [FTShelfItemsKey: updatedDocumentURLs]);
            });
        }
    }
}

// MARK: - FTShelfCacheProtocol -
extension FTShelfCollectioniCloud: FTShelfCacheProtocol {

    func addItemToCache(_ inFileURL: URL) -> FTDiskItemProtocol? {
        let fileURL = inFileURL.standardizedFileURL;
        if(!self.belongsToDocumentsFolder(fileURL)) {
            return nil;
        }
        if(fileURL.pathExtension != FTFileExtension.shelf) {
            assert(false, "Only shelfs needs to be passed: Use addShelfItemToCache");
        }

        objc_sync_enter(self);
        let fileItemURL = fileURL;
        var collectionItem = self.collectionForURL(fileItemURL);
        if(nil == collectionItem) {
            let item = FTShelfItemCollectionICloud(fileURL: fileItemURL);
            item.parent = self
            self.shelfCollections.append(item);

            collectionItem = item
        }
        objc_sync_exit(self);
        return collectionItem;
    }
        
    fileprivate func addShelfItemToCache(_ item: NSMetadataItem, isBuildingCache: Bool = false) -> FTDiskItemProtocol? {
        let fileURL = item.URL()
        if(!self.belongsToDocumentsFolder(fileURL)) {
            return nil;
        }

        if(fileURL.pathExtension == FTFileExtension.shelf) {
            assert(false, "Only shelf items needs to be passed: Use addItemToCache");
        }
        if let itemCollection = collectionForURL(fileURL) as? FTShelfItemCollectionICloud {
            itemCollection.addItemsToCache([item], isBuildingCache: isBuildingCache)
            return itemCollection
        } else {
            orphanMetadataItems.append(item)
            #if DEBUG
            print("Orphan found", fileURL)
            #endif
            return nil;
        }
    }

    fileprivate func checkAndUpdateOrphans() {
        var mappedOrphans = [NSMetadataItem]()
        for orphan in orphanMetadataItems {
            let shelfItem = addShelfItemToCache(orphan)
            if shelfItem != nil && !mappedOrphans.contains(orphan) {
                #if DEBUG
                print("Orphan Mapped", orphan.URL())
                #endif
                mappedOrphans.append(orphan)
            }
        }
        orphanMetadataItems.removeAll { orphan -> Bool in
            return mappedOrphans.contains(orphan)
        }
    }

    func removeItemFromCache(_ fileURL: URL, shelfItem: FTDiskItemProtocol) {
        objc_sync_enter(self);
        (shelfItem as? FTSortIndexContainerProtocol)?.indexCache?.handleDeletionUpdate()
        let index = self.shelfCollections.firstIndex(where: { $0.uuid == shelfItem.uuid });
        if(nil != index) {
            self.shelfCollections.remove(at: index!);
        }
        objc_sync_exit(self);
    }

    func moveItemInCache(_ item: FTDiskItemProtocol, toURL: URL) -> Bool {
        if(!self.belongsToDocumentsFolder(toURL) || (toURL.pathExtension != FTFileExtension.shelf)) {
            return false;
        }
        objc_sync_enter(self);
        if(item.URL != toURL) {
            item.URL = toURL;
            let collection = item as! FTShelfItemCollection;
            (collection as? FTSortIndexContainerProtocol)?.indexCache?.handleRenameUpdate()
            for eachItem in collection.childrens {
                let newURL = toURL.appendingPathComponent(eachItem.URL.lastPathComponent);
                _ = (collection as! FTShelfCacheProtocol).moveItemInCache(eachItem, toURL: newURL);
            }
        }
        objc_sync_exit(self);
        return true;
    }
}

// MARK: - Private Methods
extension FTShelfCollectioniCloud {

    fileprivate func collectionForURL(_ url: URL) -> FTShelfItemCollection? {
        var collectionName = url.lastPathComponent;
        if url.pathExtension != FTFileExtension.shelf,let newName = url.collectionURL()?.lastPathComponent {
            collectionName =  newName;
        }
        if collectionName.pathExtension == FTFileExtension.shelf {
            let item = self.shelfCollections.first { item -> Bool in
                return item.URL.lastPathComponent == collectionName
            }
            return item
        } else {
            let params = ["Path" : url.path]
            FTLogError("Location Issue", attributes: params)
        }
        return nil
    }

    fileprivate func collectionForMetadata(_ metadata: NSMetadataItem) -> FTShelfItemCollection? {
        let itemCollection = self.shelfCollections.filter { colletion -> Bool in
            let itemCollection = (colletion as? FTShelfItemCollectionICloud)?.shelfItemCollection(for: metadata)
            return itemCollection != nil
        }
        return itemCollection.first
    }

    func belongsToDocumentsFolder(_ url: URL) -> Bool {
        if(url.urlByDeleteingPrivate().path.hasPrefix(self.iCloudDocumentsURL.path)) {
            return true;
        }
        return false;
    }

    // MARK: - Private Shelf Create
    fileprivate func createNewShelf(_ shelfName: String, onCompletion : @escaping (NSError?, FTShelfItemCollection?) -> Void) {
        let defaultCollectionURL = self.iCloudDocumentsURL.appendingPathComponent(shelfName);
        DispatchQueue.global().async(execute: {

            let fileManager = FileManager();

            let fileCoordinator = NSFileCoordinator(filePresenter: nil);
            fileCoordinator.coordinate(writingItemAt: defaultCollectionURL, options: NSFileCoordinator.WritingOptions(rawValue: 0), error: nil, byAccessor: { writingURL in

                // Simple delete to start
                var isDir = ObjCBool(false);
                if(!fileManager.fileExists(atPath: writingURL.path, isDirectory: &isDir) || !isDir.boolValue) {
                    do {
                        try fileManager.createDirectory(at: writingURL, withIntermediateDirectories: true, attributes: nil);
                        let model = self.addItemToCache(writingURL);
                        DispatchQueue.main.async(execute: {
                            onCompletion(nil, model as? FTShelfItemCollection);
                        });

                        if(ENABLE_SHELF_RPOVIDER_LOGS) {
                            #if DEBUG
                            debugPrint("\(self.classForCoder): Created Shelf: \(shelfName)");
                            #endif
                        }
                    } catch let error as NSError {
                        DispatchQueue.main.async(execute: {
                            onCompletion(error, nil);
                        });
                        if(ENABLE_SHELF_RPOVIDER_LOGS) {
                            #if DEBUG
                            debugPrint("\(self.classForCoder): Created Shelf: \(shelfName) Failed");
                            #endif
                        }
                        return;
                    }
                } else {
                    var collectionModel = self.collectionForURL(writingURL);
                    if(nil == collectionModel) {
                        collectionModel = self.addItemToCache(writingURL) as? FTShelfItemCollection;
                    }
                    DispatchQueue.main.async(execute: {
                        onCompletion(nil, collectionModel);
                    });
                    if(ENABLE_SHELF_RPOVIDER_LOGS) {
                        #if DEBUG
                        debugPrint("\(self.classForCoder): Created Shelf: \(shelfName) Available");
                        #endif
                    }
                }
            });
        });
    }
}
