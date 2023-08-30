//
//  FTShelfItemCollectionICloud.swift
//  Noteshelf
//
//  Created by Amar on 21/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import FTCommon
import FTDocumentFramework
import UIKit

class FTShelfItemCollectionICloud: NSObject, FTShelfItemSorting, FTShelfItemSearching, FTUniqueNameProtocol, FTShelfItemDocumentStatusChangePublisher {
    
    private(set) lazy var indexPlistContent: FTSortingIndexPlistContent? = {
        return FTSortingIndexPlistContent.init(parent: self)
    }()
    lazy var indexCache: FTCustomSortingCache? = {
        if self.collectionType == .default || self.collectionType == .migrated {
            return FTCustomSortingCache(withContainer: self)
        }
        return nil
    }()

    var downloadStatusChangedItems = FTHashTable();
    var timer: Timer?

    var childrens = [FTShelfItemProtocol]();
    var URL: Foundation.URL;
    var uuid: String = FTUtils.getUUID();
    var type: RKShelfItemType {
        return RKShelfItemType.shelfCollection;
    };

    weak var parent: FTShelfCollectioniCloud?

    fileprivate var hashTable = FTHashTable();
    fileprivate var localHashTable = FTHashTable();
//    fileprivate var groupsHashTable = FTHashTable();

    fileprivate var executionQueue = DispatchQueue(label: "com.fluidtouch.cloudShelfItemCollection");

    required init(fileURL: Foundation.URL)
    {
        URL = fileURL;
        super.init()
    }

    deinit {
        self.timer?.invalidate();
        self.timer = nil;
        #if DEBUG
            debugPrint("deinit \(self.classForCoder)");
        #endif
    }
}

// MARK: - FTShelfItemCollection -
extension FTShelfItemCollectionICloud: FTShelfItemCollection {
    func isNS2Collection() -> Bool {
        //TODO: (AK) Think about a refactor
        let belongs = self.parent?.belongsToNS2()
        return belongs ?? false
    }

    func shelfItemCollection(for metadata: NSMetadataItem) -> FTShelfItemProtocol? {
        return self.hashTable.itemFromHashTable(metadata) as? FTShelfItemProtocol
    }

    func shelfItems(_ sortOrder: FTShelfSortOrder,
                    parent: FTGroupItemProtocol?,
                    searchKey: String?,
                    onCompletion completionBlock:@escaping (([FTShelfItemProtocol]) -> Void)) {
            self.executionQueue.async {
                objc_sync_enter(self);
                var shelfItems = self.childrens;
                if let parent = parent {
                    shelfItems = parent.childrens;
                }

                if let searchKey = searchKey, !searchKey.isEmpty {
                    shelfItems = self.searchShelfItems(shelfItems, skipGroupItems: false, searchKey: searchKey);
                }
                shelfItems = self.sortItems(shelfItems, sortOrder: sortOrder);
                objc_sync_exit(self);
                DispatchQueue.main.async {
                    completionBlock(shelfItems);
                }
            }
    }

    func addShelfItemForDocument(_ path: Foundation.URL,
                                 toTitle: String,
                                 toGroup: FTGroupItemProtocol?,
                                 onCompletion block: @escaping (NSError?, FTDocumentItemProtocol?) -> Void) {
        self.parent?.disableUpdates()
        self.uniqueName(name: toTitle + ".\(FTFileExtension.ns3)", inGroup: toGroup) { packageName -> Void in
            DispatchQueue.global().async(execute: {
                do {
                    let fileURL = self.documentURLWithFileName(packageName, inGroup: toGroup, collection: self);

                    let dict = NSDictionary(contentsOf: (path.appendingPathComponent(METADATA_FOLDER_NAME).appendingPathComponent(PROPERTIES_PLIST)));
                    let documentUUID = dict![DOCUMENT_ID_KEY] as! String;

                    try FileManager().setUbiquitous(true, itemAt: path, destinationURL: fileURL);
                    let model = self.addItemToCache(fileURL);
                    (model as? FTDocumentItemProtocol)?.documentUUID = documentUUID;
                    (model as? FTDocumentItemProtocol)?.isDownloaded = true;
                    
                    var indexFolderItem: FTSortIndexContainerProtocol = self
                    if let groupItem = toGroup as? FTSortIndexContainerProtocol {
                        indexFolderItem = groupItem
                    }
                    if let shelfItem = model as? FTShelfItemProtocol {
                        indexFolderItem.indexCache?.addNewNotebookTitle(shelfItem.sortIndexHash, atIndex: 0)
                    }

                    DispatchQueue.main.async(execute: {
                        block(nil, model as? FTDocumentItemProtocol);
                        self.parent?.enableUpdates()
                    });
                } catch let error as NSError {
                    DispatchQueue.main.async(execute: {
                        block(error, nil);
                        self.parent?.enableUpdates()
                    });
                }
            });
        }
    }
    
    func moveShelfItems(_ shelfItems: [FTShelfItemProtocol],
                           toGroup: FTShelfItemProtocol?,
                           toCollection: FTShelfItemCollection!,
                           onCompletion block:@escaping (NSError?, [FTShelfItemProtocol]) -> Void){
        var itemsToMove = shelfItems;
        var movedItems = [FTShelfItemProtocol]()
        var removedItems = [FTShelfItemProtocol]();
        var removedItemsCollections = Set<FTShelfItemCollectionICloud>();

        func moveItem()
        {
            if let item = itemsToMove.first {
                if let childItems = (item as? FTGroupItemProtocol)?.childrens, item.URL.pathExtension == FTFileExtension.group, toCollection.isTrash {
                    self.moveShelfItems(childItems, toGroup: toGroup, toCollection: toCollection) { (_, moved) in
                        movedItems.append(contentsOf: moved)
                        itemsToMove.removeFirst();
                        moveItem()
                    }
                } else {
                    guard let shelfCollection = item.shelfCollection as? FTShelfItemCollectionICloud else  {
                        itemsToMove.removeFirst();
                        moveItem()
                        return;
                    }
                    
                    shelfCollection.moveShelfItem(item,
                                                  toGroup: toGroup as? FTGroupItemProtocol,
                                                  toCollection: toCollection)
                    { (_, movedItem, removedItem) in
                        if let moved = movedItem {
                            movedItems.append(moved)
                        }
                        if let removed = removedItem {
                            removedItems.append(removed)
                            removedItemsCollections.insert(shelfCollection);
                        }
                        itemsToMove.removeFirst();
                        moveItem()
                    }
                }
            }
            else {
                DispatchQueue.main.async(execute: {
                    block(nil, movedItems)
                    if(movedItems.isEmpty == false) {
                        NotificationCenter.default.post(name: Notification.Name.shelfItemUpdated, object: toCollection, userInfo: [FTShelfItemsKey : movedItems]);
                    }
                    
                    if(removedItems.isEmpty == false) {
                        removedItemsCollections.forEach { (collection) in
                            NotificationCenter.default.post(name: Notification.Name.shelfItemRemoved,
                                                            object: collection,
                                                            userInfo: [FTShelfItemsKey : removedItems]);
                        }
                    }
                    self.parent?.enableUpdates()
                });
            }
        };
        self.parent?.disableUpdates()
        moveItem();
    }
    
    fileprivate func moveShelfItem(_ shelfItem: FTShelfItemProtocol,
                       toGroup: FTGroupItemProtocol?,
                       toCollection: FTShelfItemCollection!,
                       onCompletion block:@escaping (NSError?, FTShelfItemProtocol?, FTShelfItemProtocol?) -> Void) {
        if let item = shelfItem as? FTDocumentItemProtocol {
            if toCollection.isTrash && !item.isDownloaded {
                shelfItem.shelfCollection.removeShelfItem(shelfItem, onCompletion: {(error, removedItem) in
                    block(error,item,removedItem);
                });
            }
            else {
                self.moveDocumentItem(item,
                                      toGroup: toGroup,
                                      toCollection: toCollection,
                                      onCompletion: block);
            }
        }
        else if let groupItem = shelfItem as? FTGroupItemProtocol {
            self.moveGroupItem(groupItem,
                               toGroup: toGroup,
                               toCollection: toCollection,
                               onCompletion: block);
        }
        else {
            NSException(name: NSExceptionName(rawValue: "Failed"), reason: "", userInfo: nil).raise();
        }
    }
    
    func renameShelfItem(_ shelfItem: FTShelfItemProtocol,
                         toTitle: String,
                         onCompletion block:@escaping (NSError?, FTShelfItemProtocol?) -> Void) {
        if let item = shelfItem as? FTDocumentItemProtocol {
            self.renameDocumentItem(item,
                                    toTitle: toTitle,
                                    onCompletion: block);
        } else if let item = shelfItem as? FTGroupItemProtocol{
            self.renameGroupItem(item,
                                 toGroupName: toTitle,
                                 onCompletion: block);
        }
        else {
            NSException(name: NSExceptionName(rawValue: "Failed"), reason: "", userInfo: nil).raise();
        }
    }

    func removeShelfItem(_ shelfItem: FTShelfItemProtocol,
                         onCompletion block:@escaping (NSError?, FTShelfItemProtocol?) -> Void) {
        var indexFolderItem: FTSortIndexContainerProtocol = self
        if let groupItem = shelfItem.parent as? FTSortIndexContainerProtocol {
            indexFolderItem = groupItem
        }
        indexFolderItem.indexCache?.deleteNotebookTitle(shelfItem.sortIndexHash)

        if(shelfItem is FTDocumentItemProtocol) {
            self.removeDocumentItem(shelfItem as! FTDocumentItemProtocol,
                                    onCompletion: block);
        } else {
            self.removeGroupItem(shelfItem as! FTGroupItemProtocol,
                                 onCompletion: block);
        }
    }

    func createGroupItem(_ groupName: String,
                         inGroup: FTGroupItemProtocol?,
                         shelfItemsToGroup items: [FTShelfItemProtocol]?,
                                           onCompletion block: @escaping (NSError?, FTGroupItemProtocol?) -> Void) {
        self.parent?.disableUpdates()
        self.shelfItems(.byName, parent: nil, searchKey: nil) { _ in

            self.uniqueName(name: groupName+".group", inGroup: inGroup, onCompletion: { newGroupName -> Void in
                let groupURL = self.documentURLWithFileName(newGroupName, inGroup: inGroup, collection: self);

                var tempURL = NSURL(fileURLWithPath: NSTemporaryDirectory()) as URL;
                tempURL = tempURL.appendingPathComponent(newGroupName);
                let fileManager = FileManager();
                do {
                    if self.isEmptyGroupNameExists(at: groupURL.path) == false {
                        try fileManager.createDirectory(at: tempURL, withIntermediateDirectories: true, attributes: nil);
                        try fileManager.setUbiquitous(true, itemAt: tempURL, destinationURL: groupURL);
                    }
                    let groupModel = self.addItemToCache(groupURL.standardizedFileURL) as? FTGroupItemProtocol;

                    if let _items = items, !_items.isEmpty {
                        self.moveShelfItems(_items,
                                            toGroup: groupModel,
                                            toCollection: self) { (error, _) in
                            DispatchQueue.main.async(execute: {
                                block(error, groupModel);
                                self.parent?.enableUpdates()
                            });
                        }
                    }
                    else {
                        DispatchQueue.main.async(execute: {
                            block(nil, groupModel);
                            self.parent?.enableUpdates()
                        });
                    }
                } catch let createError as NSError {
                    DispatchQueue.main.async(execute: {
                        block(createError, nil);
                        self.parent?.enableUpdates()
                    });
                }
            });
        };
    }

    // MARK: - Private Methods -
    fileprivate func moveDocumentItem(_ shelfItem: FTDocumentItemProtocol,
                                      toGroup: FTGroupItemProtocol?,
                                      toCollection: FTShelfItemCollection!,
                                      onCompletion block:@escaping (NSError?, FTShelfItemProtocol?, FTShelfItemProtocol?) -> Void)
    {
        var removedItem: FTShelfItemProtocol?
        var movedItem : FTShelfItemProtocol?;
        (toCollection as? FTUniqueNameProtocol)?.uniqueName(name: shelfItem.URL.lastPathComponent,
                                inGroup: toGroup)
        { destFileName -> Void in
            let destURL = self.documentURLWithFileName(destFileName, inGroup: toGroup, collection: toCollection);
            self.fileOperationMoveFileAtPath(shelfItem.URL, toPath: destURL) { error in
                DispatchQueue.main.async(execute: {
                    if(nil == error) {
                        if(toCollection.isTrash) {
                            let recoveryURL = destURL.appendingPathComponent(NOTEBOOK_RECOVERY_PLIST);
                            let plist = FTNotebookRecoverPlist(url: recoveryURL, isDirectory: false);
                            plist?.recovertType = .book;
                            plist?.recoverLocation = shelfItem.URL.relativePathWRTCollection().deletingLastPathComponent;
                            plist?.saveContentsOfFileItem();
                        }
                        if(self.URL != toCollection.URL) {
                            //Recent:
                            let oldURL = shelfItem.URL;
                            //Recent:
                            
                            self.removeItemFromCache(shelfItem.URL, shelfItem: shelfItem);
                            removedItem = shelfItem
                            movedItem = (toCollection as? FTShelfCacheProtocol)?.addItemToCache(destURL) as? FTShelfItemProtocol ;
                            (movedItem as? FTDocumentItemProtocol)?.documentUUID = shelfItem.documentUUID;
                            #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
                            //Recent:
                            if(toCollection.isTrash) {
                                NotificationCenter.default.post(name: .shelfItemDidGetDeletedInternal, object: self, userInfo: [FTNewURLS: [oldURL]]);
                            } else {
                                NotificationCenter.default.post(name: .shelfItemDidGetMovedInternal, object: self, userInfo: [FTOldURLS: [oldURL], FTNewURLS: [destURL]]);
                            }
                            //Recent:
                            #endif
                        } else {
                            _ = self.moveItemInCache(shelfItem, toURL: destURL);
                        }
                    }
                    if(nil == movedItem) {
                        movedItem = shelfItem;
                    }
                    block(error, movedItem, removedItem);
                });
            }
        }
    }

    fileprivate func renameDocumentItem(_ shelfItem: FTDocumentItemProtocol,
                                    toTitle: String,
                                    onCompletion block:@escaping (NSError?, FTDocumentItemProtocol?) -> Void) {
        self.parent?.disableUpdates()
        let fromTitle = shelfItem.sortIndexHash
        self.uniqueName(name: toTitle+".\(FTFileExtension.ns3)", inGroup: shelfItem.parent) { destFileName -> Void in
            let destURL = self.documentURLWithFileName(destFileName, inGroup: shelfItem.parent, collection: self);
            self.fileOperationMoveFileAtPath(shelfItem.URL, toPath: destURL) { error in
                DispatchQueue.main.async(execute: {
                    if(nil == error) {
                        _ = self.moveItemInCache(shelfItem, toURL: destURL);
                        var indexFolderItem: FTSortIndexContainerProtocol = self
                        if let groupItem = shelfItem.parent as? FTSortIndexContainerProtocol {
                            indexFolderItem = groupItem
                        }
                        indexFolderItem.indexCache?.updateNotebookTitle(from: fromTitle, to: shelfItem.sortIndexHash)
                    }
                    block(error, shelfItem);
                    self.parent?.enableUpdates()
                });
            };
        };
    }

    fileprivate func removeDocumentItem(_ shelfItem: FTDocumentItemProtocol,
                                    onCompletion block:@escaping (NSError?, FTDocumentItemProtocol?) -> Void) {
        self.parent?.disableUpdates()
        DispatchQueue.global().async(execute: {
            let fileCordinator = NSFileCoordinator(filePresenter: nil);

            fileCordinator.coordinate(writingItemAt: shelfItem.URL as URL,
                options: NSFileCoordinator.WritingOptions.forDeleting,
                error: nil,
                byAccessor: { writingURL in
                    do {
                        _ = try FileManager().removeItem(at: writingURL);
                        self.removeItemFromCache(shelfItem.URL as URL, shelfItem: shelfItem);
                        DispatchQueue.main.async(execute: {
                            block(nil, shelfItem);
                            self.parent?.enableUpdates()
                        });
                    } catch let error as NSError {
                        DispatchQueue.main.async(execute: {
                            block(error, shelfItem);
                            self.parent?.enableUpdates()
                        });
                    }
            });
        });
    }

    fileprivate func renameGroupItem(_ groupItem: FTGroupItemProtocol,
                                 toGroupName: String,
                                 onCompletion block:@escaping (NSError?, FTGroupItemProtocol?) -> Void) {
        self.parent?.disableUpdates()
        let fromTitle = groupItem.sortIndexHash
        self.uniqueName(name: toGroupName+".group",
                        inGroup: groupItem.parent) { uniqueGroupName -> Void in
                            
                            let destURL = self.documentURLWithFileName(uniqueGroupName, inGroup: groupItem.parent, collection: self);

                            if self.isEmptyGroupNameExists(at: destURL.path) {
                                var renamedGroupItem : FTGroupItemProtocol? = groupItem;
                                self.fileOperationMoveDocuments(nil,
                                                                index: 0,
                                                                shelfItems: groupItem.childrens,
                                                                toGroupURL: destURL,
                                                                onCompletion: { error in
                                                                    if(nil == error) {
                                                                        renamedGroupItem = self.groupItemForURL(destURL.standardizedFileURL);
                                                                    }
                                                                    if let renamedGroupTitle = renamedGroupItem?.sortIndexHash {
                                                                        self.indexCache?.updateNotebookTitle(from: fromTitle, to: renamedGroupTitle)
                                                                    }
                                                                    DispatchQueue.main.async(execute: {
                                                                        block(error, renamedGroupItem);
                                                                        self.parent?.enableUpdates()
                                                                        NotificationCenter.default.post(name: Notification.Name.shelfItemUpdated, object: self, userInfo: [FTShelfItemsKey: [renamedGroupItem]]);
                                                                    });
                                })
                            } else {
                                self.fileOperationMoveFileAtPath(groupItem.URL,
                                                                 toPath: destURL,
                                                                 onCompletion: { (error) in
                                                                    self.indexCache?.updateNotebookTitle(from: fromTitle, to: groupItem.sortIndexHash)
                                                                    DispatchQueue.main.async(execute: {
                                                                        if(nil == error) {
                                                                            _ = self.moveItemInCache(groupItem, toURL: destURL.standardizedFileURL);
                                                                        }
                                                                        block(error, groupItem);
                                                                        self.parent?.enableUpdates()
                                                                        NotificationCenter.default.post(name: Notification.Name.shelfItemUpdated, object: self, userInfo: [FTShelfItemsKey: [groupItem]]);
                                                                    });
                                })
                            }
        }
    }

    fileprivate func moveGroupItem(_ groupItem : FTGroupItemProtocol,
                                   toGroup: FTGroupItemProtocol?,
                                   toCollection : FTShelfItemCollection!,
                                   onCompletion block:@escaping (NSError?, FTShelfItemProtocol?, FTShelfItemProtocol?) -> Void)
    {
        var toCreateFileName: Bool = true
        var createdGroupItem: FTShelfItemProtocol?
        
        toCollection?.shelfItems(.byName, parent: toGroup, searchKey: nil, onCompletion: { localItems in
            for item in localItems where item.title == groupItem.title {
                createdGroupItem = item
                toCreateFileName = false
                break
            }
            if toCreateFileName {
                (toCollection as? FTUniqueNameProtocol)?.uniqueName(name: groupItem.URL.lastPathComponent,
                                                                    inGroup: toGroup)
                { (uniqueGroupName) -> (Void) in
                    toCollection.createGroupItem(uniqueGroupName.deletingPathExtension,
                                                 inGroup: toGroup,
                                                 shelfItemsToGroup: groupItem.childrens)
                    {(error, newGroupItem) in
                        self.moveShelfItems(groupItem.childrens, toGroup: newGroupItem, toCollection: toCollection) { _, _ in
                            block(error, newGroupItem, groupItem)
                        }
                    }
                }
            } else if let createdGroup = createdGroupItem as? FTGroupItemProtocol {
                self.moveShelfItems(groupItem.childrens, toGroup: createdGroup, toCollection: toCollection) { error, _ in
                    block(error, createdGroup, groupItem)
                }
            }
        })
    }

    fileprivate func removeGroupItem(_ groupItem: FTGroupItemProtocol,
                                 onCompletion block:@escaping (NSError?, FTGroupItemProtocol?) -> Void) {
        self.parent?.disableUpdates()
        let tempLocationURL = NSURL.fileURL(withPath: NSTemporaryDirectory()).appendingPathComponent(groupItem.URL.lastPathComponent);

        var fileError: NSError?;
        do {
            let fileManger = FileManager();
            try? fileManger.removeItem(at: tempLocationURL);
            try fileManger.evictUbiquitousItem(at: groupItem.URL);
            try fileManger.setUbiquitous(false, itemAt: groupItem.URL, destinationURL: tempLocationURL);
            _ = try fileManger.removeItem(at: tempLocationURL);
            self.removeItemFromCache(groupItem.URL as URL, shelfItem: groupItem);
        } catch let error as NSError {
            fileError = error;
        }
        self.indexCache?.deleteNotebookTitle(groupItem.sortIndexHash)
        DispatchQueue.main.async(execute: {
            self.parent?.enableUpdates()
            block(fileError, groupItem);
        });
    }
}

// MARK: - Private Cache mgmt -
extension FTShelfItemCollectionICloud {

    // MARK: - Private Cache mgmt -
    fileprivate func buildCache(_ metadataItems: [NSMetadataItem]?) {
        self.childrens.removeAll();
        self.hashTable.removeAll();
//        self.groupsHashTable.removeAll();
        self.localHashTable.removeAll();
        if(nil != metadataItems) {
            // The query reports all files found, every time.
            self.addItemsToCache(metadataItems!, isBuildingCache: true);
        }
    }

    func addItemsToCache(_ metadataItems: [NSMetadataItem], isBuildingCache: Bool = false) {
        var addedItems = [AnyObject]();
        for eachItem in metadataItems {
            autoreleasepool {

                let fileURL = eachItem.URL();
                //Check if the document reference is present in documentMetadataItemHashTable.If the reference is found, its already added to cache. We just need to update the document with this metadataItem
                var shelfItem = self.hashTable.itemFromHashTable(eachItem) as? FTShelfItemProtocol;
                if(shelfItem == nil) {
                    if(!isBuildingCache) {
                        shelfItem = self.shelfItemForURL(fileURL);
                    }

                    if(shelfItem == nil) {
                        shelfItem = self.addItemToCache(fileURL, addToLocalCache: false) as? FTShelfItemProtocol;
                    }

                    if(shelfItem != nil) {
                        self.hashTable.addItemToHashTable(shelfItem!, forKey: eachItem);
                        self.localHashTable.removeItemFromHashTable(fileURL);
                    }
                }

                (shelfItem as? FTDocumentItemProtocol)?.updateShelfItemInfo(eachItem);
                if(nil != shelfItem) {
                    addedItems.append(shelfItem!);
                }

                if(ENABLE_SHELF_RPOVIDER_LOGS) {
                    #if DEBUG
                    debugPrint("\(#file.components(separatedBy: "/").last ?? ""): Added :\(fileURL.lastPathComponent)");
                    #endif
                }
            }
        }
        if !addedItems.isEmpty {
            runInMainThread({
                NotificationCenter.default.post(name: Notification.Name.shelfItemAdded, object: self, userInfo: [FTShelfItemsKey: addedItems]);
            });
        }
    }

    func removeItemsFromCache(_ metadataItems: [NSMetadataItem]) {
        var removedItems = [AnyObject]();

        for eachItem in metadataItems {
            autoreleasepool {
                let fileURL = eachItem.URL();
                let shelfItem = self.hashTable.itemFromHashTable(eachItem) as? FTShelfItemProtocol;
                
                if(nil != shelfItem) {
                    removedItems.append(shelfItem!);
                    self.removeItemFromCache(shelfItem!.URL, shelfItem: shelfItem!);
                    self.hashTable.removeItemFromHashTable(eachItem);
                    
                    if(ENABLE_SHELF_RPOVIDER_LOGS) {
                        #if DEBUG
                        debugPrint("\(#file.components(separatedBy: "/").last ?? ""): Removed :\(fileURL.lastPathComponent)");
                        #endif
                    }
                }
            }
        }
        if !removedItems.isEmpty {
            runInMainThread({
                NotificationCenter.default.post(name: Notification.Name.shelfItemRemoved, object: self, userInfo: [FTShelfItemsKey: removedItems]);
            });
        }
    }

    func updateItemsInCache(_ metadataItems: [NSMetadataItem]) {
        var updatedItems = [AnyObject]();

        for eachItem in metadataItems {
            autoreleasepool {
                let fileURL = eachItem.URL();
                #if DEBUG
//                print("Updated :\(fileURL.path.removingPercentEncoding ?? "")");
                #endif
                
                let shelfItem = self.hashTable.itemFromHashTable(eachItem) as? FTShelfItemProtocol;
                
                if(shelfItem != nil) {
                    let success = self.moveItemInCache(shelfItem!, toURL: fileURL);
                    if(success) {
                        //Update the document document attributes
                        (shelfItem as? FTDocumentItemProtocol)?.updateShelfItemInfo(eachItem);
                        let isItemDownloaded = eachItem.isItemDownloaded() && ((shelfItem as? FTDocumentItemProtocol)?.isUploaded ?? true);
                        if(isItemDownloaded ) {
                            updatedItems.append(shelfItem!);
                        }
                        if let groupItem = shelfItem?.parent, !updatedItems.contains(where: { (eachDiskItem) -> Bool in
                            if let diskItem = eachDiskItem as? FTDiskItemProtocol {
                                return diskItem.uuid == groupItem.uuid
                            }
                            return false
                        }) {
                            if(isItemDownloaded) {
                                updatedItems.append(groupItem);
                            }
                        }
                    }
                }
                if(ENABLE_SHELF_RPOVIDER_LOGS) {
                    #if DEBUG
                    print("Updated :\(fileURL.lastPathComponent)");
                    #endif
                }
            }
        }
        runInMainThread({
            if (!updatedItems.isEmpty) {
                NotificationCenter.default.post(name: Notification.Name.shelfItemUpdated, object: self, userInfo: [FTShelfItemsKey: updatedItems]);
            }
        });
    }
}

// MARK: - FTShelfCacheProtocol -
extension FTShelfItemCollectionICloud: FTShelfCacheProtocol {

    func addItemToCache(_ fileURL: Foundation.URL) -> FTDiskItemProtocol? {
        return self.addItemToCache(fileURL, addToLocalCache: true);
    }

    fileprivate func addItemToCache(_ fileURL: Foundation.URL, addToLocalCache: Bool) -> FTDiskItemProtocol? {
        if(!self.belongsToCollection(fileURL)) {
            return nil;
        }
        var shelfItem: FTShelfItemProtocol?;

        objc_sync_enter(self);
        let fileItemURL = fileURL;
        if(self.isGroup(fileItemURL)) {
            shelfItem = self.addGroupItemForURL(fileItemURL);
        } else if(fileURL.isSuportedBookExtension) {
            shelfItem = self.addBookItemForURL(fileURL);
            if(addToLocalCache) {
                self.localHashTable.addItemToHashTable(shelfItem!, forKey: fileURL);
            }
        }
        objc_sync_exit(self);
        return shelfItem;
    }
    
    func removeItemFromCache(_ fileURL: Foundation.URL, shelfItem: FTDiskItemProtocol) {
        if(!self.belongsToCollection(fileURL)) {
            return ;
        }
        let item = (shelfItem as! FTShelfItemProtocol);
        objc_sync_enter(self);
        if(self.docBelongsToGroup(fileURL)) {
            if let groupItem = item.parent {
                groupItem.removeChild(item);
                if groupItem.childrens.isEmpty {
                    (groupItem as? FTSortIndexContainerProtocol)?.indexCache?.handleDeletionUpdate()
                    self.removeItemFromCache(groupItem.URL, shelfItem: groupItem);
                }
            }
        } else {
//            if(self.isGroup(fileURL)) {
//                self.groupsHashTable.removeItemFromHashTable(shelfItem.URL!);
//            }
            self.removeChild((item));
        }
        objc_sync_exit(self);
    }

    func moveItemInCache(_ shelfItem: FTDiskItemProtocol, toURL: Foundation.URL) -> Bool {
        if(!self.belongsToCollection(toURL)) {
            return false;
        }
        let item = (shelfItem as! FTShelfItemProtocol);
        objc_sync_enter(self);
        if(self.isGroup(toURL)) {
            //Change the url of the document to new url.
//            self.groupsHashTable.removeItemFromHashTable(item.URL!);
            item.URL = toURL;
//            self.groupsHashTable.addItemToHashTable(item, forKey: item.URL!);
            let groupItem = shelfItem as! FTGroupItemProtocol;
            for eachItem in groupItem.childrens {
                let newURL = toURL.appendingPathComponent(eachItem.URL.lastPathComponent);
                _ = self.moveItemInCache(eachItem, toURL: newURL);
            }
        } else {
            let currentGroup = item.parent;
            //Get the new group item it should be moved to. Create if not present
            var newGroupItem: FTGroupItemProtocol?
            if(self.docBelongsToGroup(toURL)) {
                newGroupItem = self.groupItemForURL(toURL.deletingLastPathComponent());
                if(nil == newGroupItem) {
                   newGroupItem = self.addGroupItemForURL(toURL.deletingLastPathComponent());
                    if(nil == newGroupItem) {
                        NSException(name: NSExceptionName(rawValue: "Group not found"), reason: "Group should be created first in metadata update callback before book", userInfo: nil).raise();
                    }
                }
            }

            //Add the document to new group by removing from previous group
            if(currentGroup?.uuid != newGroupItem?.uuid) {
                if let _currentGroup = currentGroup {
                    _currentGroup.removeChild(item);
                    if _currentGroup.childrens.isEmpty {
                        self.removeItemFromCache(_currentGroup.URL, shelfItem: _currentGroup);
                    }
                }else {
                    self.removeChild(item);
                }

                if(newGroupItem != nil) {
                    newGroupItem?.addChild(item);
                } else {
                    self.addChild(item);
                }
            }
            #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
            //Recent:
            if(toURL != item.URL) {
                NotificationCenter.default.post(name: .shelfItemDidGetMovedInternal, object: self, userInfo: [FTOldURLS: [item.URL], FTNewURLS: [toURL]]);
            }
            //Recent:
            #endif
            //Change the url of the document to new url.
            item.URL = toURL;
            (item.parent as? FTSortIndexContainerProtocol)?.indexCache?.handleRenameUpdate()
        }
        objc_sync_exit(self);
        return true;
    }
}

// MARK: - Fetching Items -
extension FTShelfItemCollectionICloud {

    fileprivate func shelfItemForURL(_ url: Foundation.URL) -> FTShelfItemProtocol? {
        var shelfItem: FTShelfItemProtocol? = nil;

        if(self.isGroup(url)) {
            shelfItem = self.groupItemForURL(url);
        } else {
            shelfItem = self.localHashTable.itemFromHashTable(url) as? FTShelfItemProtocol;
            if(nil == shelfItem) {
                var rootItems: [FTShelfItemProtocol]? = self.childrens;
                if(self.docBelongsToGroup(url)) {
                    let groupItem = self.groupItemForURL(url.deletingLastPathComponent());
                    rootItems = groupItem?.childrens;
                }
                if(nil != rootItems) {
                    for eachItem in rootItems! {
                        if(eachItem.URL == url) {
                            shelfItem = eachItem;
                            break;
                        }
                    }
                }
            }
        }
        return shelfItem;
    }
}

// MARK: - Adding Items -
private extension FTShelfItemCollectionICloud {
    func addGroupItemForURL(_ fileURL: Foundation.URL) -> FTGroupItemProtocol? {
        var itemToReturn: FTGroupItemProtocol?;
        if let groupItem = self.groupItemForURL(fileURL) {
            if nil == groupItem.shelfCollection {
                self.addChild(groupItem);
            }
            return groupItem;
        }
        
        if let first = fileURL.pathRelativeTo(self.URL).components(separatedBy: "/").first {
            if let item = self.groupItemWithName(title: first) {
                itemToReturn = item
            }
            else {
                let url = self.URL.appendingPathComponent(first);
                let item = FTGroupItem(fileURL: url);
                self.addChild(item);
                itemToReturn = item;
            }
            if let item = itemToReturn {
                if item.URL.urlByDeleteingPrivate() == fileURL.urlByDeleteingPrivate() {
                    return item;
                }
                return (item as? FTGroupItem)?.addGroupItemForURL(fileURL,addToCache: nil)
            }
        }
        return nil;
    }
    
    func addBookItemForURL(_ url: Foundation.URL) -> FTShelfItemProtocol {
        let shelfItem: FTDocumentItemProtocol;
        if(self.docBelongsToGroup(url)) {
            let groupURL = url.deletingLastPathComponent().urlByDeleteingPrivate()
            var groupItem = self.groupItemForURL(groupURL);
            
            if(nil == groupItem) {
                groupItem = self.addGroupItemForURL(groupURL)
            }
            shelfItem = FTDocumentItem(fileURL: url);
            groupItem?.addChild(shelfItem);
        } else {
            shelfItem = FTDocumentItem(fileURL: url);
            self.addChild(shelfItem);
        }
        return shelfItem;
    }
}

// MARK: - Private Methods -
extension FTShelfItemCollectionICloud {

    fileprivate func docBelongsToGroup(_ fileURL: Foundation.URL) -> Bool {
        let dirURL = fileURL.deletingLastPathComponent();
        return self.isGroup(dirURL);
    }

    fileprivate func isGroup(_ fileURL: Foundation.URL) -> Bool {
        let fileItemURL = fileURL.urlByDeleteingPrivate();
        if(fileItemURL.pathExtension == FTFileExtension.group) {
            return true;
        }
        return false;
    }

    fileprivate func belongsToCollection(_ fileURL: Foundation.URL) -> Bool {
        var belongs = false;

        let collectionName = self.URL.lastPathComponent;

        var collectionURL = fileURL;
        while((collectionURL.pathExtension != FTFileExtension.shelf) && !belongs) {
            collectionURL = collectionURL.deletingLastPathComponent();
            if(collectionURL.lastPathComponent == collectionName) {
                belongs = true;
            }
        }
        return belongs;
    }

    func documentURLWithFileName(_ fileName: String, inGroup: FTGroupItemProtocol?, collection: FTShelfItemCollection) -> Foundation.URL {
        var rootURL = collection.URL
        if let _group = inGroup {
            rootURL = _group.URL
        }
        let urlToReturn = rootURL.urlByDeleteingPrivate().appendingPathComponent(fileName);
        return urlToReturn;
    }
}

// MARK: - File operations -
extension FTShelfItemCollectionICloud {

    fileprivate func fileOperationMoveFileAtPath(_ fileURL: Foundation.URL, toPath: Foundation.URL, onCompletion:@escaping (NSError?) -> Void) {
        DispatchQueue.global().async(execute: {
            let fileCoordinator = NSFileCoordinator(filePresenter: nil);

            fileCoordinator.coordinate(writingItemAt: fileURL, options: NSFileCoordinator.WritingOptions.forMoving, writingItemAt: toPath, options: NSFileCoordinator.WritingOptions.forReplacing, error: nil, byAccessor: { newURL1, newURL2 in
                do {
                    fileCoordinator.item(at: newURL1, willMoveTo: newURL2);
                    try FileManager().moveItem(at: newURL1, to: newURL2);
                    fileCoordinator.item(at: newURL1, didMoveTo: newURL2);
                    DispatchQueue.main.async(execute: {
                        onCompletion(nil);
                    });
                } catch let error as NSError {
                    DispatchQueue.main.async(execute: {
                        onCompletion(error);
                    });
                }
            });
        });
    }

    fileprivate func fileOperationMoveDocuments(_ coordinator: NSFileCoordinator?,
                                            index: Int,
                                            shelfItems: [FTShelfItemProtocol]?,
                                            toGroupURL: Foundation.URL,
                                                  onCompletion block : @escaping ((NSError?) -> Void)) {
        if((shelfItems == nil) || (index >= shelfItems!.count)) {
            block(nil);
            return;
        }

        let shelfItem = shelfItems![index];
        let newURL = toGroupURL.appendingPathComponent(shelfItem.URL.lastPathComponent);

        DispatchQueue.global().async(execute: {
            var fileCoordinator = coordinator;
            if(nil == fileCoordinator) {
                fileCoordinator = NSFileCoordinator(filePresenter: nil);
            }
            fileCoordinator!.coordinate(writingItemAt: shelfItem.URL, options: NSFileCoordinator.WritingOptions.forMoving, writingItemAt: newURL, options: NSFileCoordinator.WritingOptions.forReplacing, error: nil, byAccessor: { newURL1, newURL2 in
            do {
                try FileManager().moveItem(at: newURL1, to: newURL2);
                _ = self.moveItemInCache(shelfItem, toURL: newURL2);
                self.fileOperationMoveDocuments(fileCoordinator,
                    index: index + 1,
                    shelfItems: shelfItems,
                    toGroupURL: toGroupURL,
                    onCompletion: block);
            } catch let error as NSError {
                block(error);
            }
        });
        });
    }

    func uniqueName(name: String, inGroup: FTGroupItemProtocol?, onCompletion : @escaping (String) -> Void) {
        self.shelfItems(.byName, parent: inGroup, searchKey: nil) { contents in
            let packageName = self.uniqueFileName(name, inItems: contents);
            onCompletion(packageName);
        };
    }
    
    fileprivate func isEmptyGroupNameExists(at path: String) -> Bool {
        var emptyGroupExists = false;
        let newURL: URL = Foundation.URL.init(fileURLWithPath: path).urlByDeleteingPrivate()
        var isDir : ObjCBool = false;
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir) {
            if isDir.boolValue {
                do {
                    let contents = try FileManager.default.contentsOfDirectory(at: newURL, includingPropertiesForKeys: [URLResourceKey.contentModificationDateKey], options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
                    let notebooks = contents.filter { $0.pathExtension == FTFileExtension.ns3 }
                    if notebooks.isEmpty {
                        emptyGroupExists = true
                    }
                } catch {
                    
                }
            }
        }
        return emptyGroupExists
    }
    
}
//MARK:- Manual Sorting
extension FTShelfItemCollectionICloud: FTSortIndexContainerProtocol {
    func handleSortIndexFileUpdates(_ infoItem: Any?) {
        if let metadata = infoItem as? NSMetadataItem {
            let fileURL = metadata.URL()
            if let groupItem = self.groupItemForURL(fileURL.deletingLastPathComponent()) {
                (groupItem as? FTSortIndexContainerProtocol)?.handleSortIndexFileUpdates(metadata)
            }
            else {
                self.indexPlistContent?.handleSortIndexFileUpdates(metadata)
            }
        }
    }
}
