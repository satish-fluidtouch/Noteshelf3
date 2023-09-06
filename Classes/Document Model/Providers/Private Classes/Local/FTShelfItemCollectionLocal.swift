//
//  FTDocumentProviderLocal.swift
//  Noteshelf
//
//  Created by Amar on 21/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTDocumentFramework
import FTCommon

class FTShelfCallback: NSObject {
    var tempCompletionBlock : (([FTShelfItemProtocol]) -> Void)?
    var tempParent: FTGroupItemProtocol?;
    var tempSearchKey : String?
    var tempSorOrder = FTShelfSortOrder.byName;
}

class FTShelfItemCollectionLocal : NSObject,FTShelfItemCollection,FTLocalQueryGatherDelegate,FTShelfCacheProtocol,
    FTShelfItemSorting,FTShelfItemSearching,FTUniqueNameProtocol,FTShelfItemDocumentStatusChangePublisher
{
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
    var timer : Timer?
    weak var parent: FTShelfCollectionLocal?
    var childrens = [FTShelfItemProtocol]();
    var URL : Foundation.URL;
    var uuid : String = FTCommonUtils.getUUID();
    var type : RKShelfItemType {
        return RKShelfItemType.shelfCollection;
    };
    
    var collectionType: FTShelfItemCollectionType {
        return FTShelfItemCollectionType.default;
    }
    
    fileprivate var hashTable = FTHashTable();

    fileprivate var query : FTLocalQueryGather?;
    
    fileprivate var tempCompletionBlock = [FTShelfCallback]();

    fileprivate var executionQueue = DispatchQueue.init(label: "com.fluidtouch.localShelfItemCollection");

    required init(fileURL : Foundation.URL)
    {
        URL = fileURL.urlByDeleteingPrivate();
        super.init()
    }

    deinit {
        self.timer?.invalidate();
        self.timer = nil;
        #if DEBUG
            debugPrint("deinit \(self.classForCoder)");
        #endif
    }

    //MARK:- FTShelfItemCollection -
    func shelfItems(_ sortOrder : FTShelfSortOrder,
                    parent : FTGroupItemProtocol?,
                    searchKey : String?,
                    onCompletion completionBlock: @escaping (([FTShelfItemProtocol]) -> Void))
    {
        if(nil != self.query) {
            self.executionQueue.async {
                objc_sync_enter(self);
                var shelfItems = self.childrens;
                if(nil != parent) {
                    shelfItems = parent!.childrens;
                }
                
                if((nil != searchKey) && (searchKey!.isEmpty == false)) {
                    shelfItems = self.searchShelfItems(shelfItems, skipGroupItems: false, searchKey: searchKey!);
                }
                
                shelfItems = self.sortItems(shelfItems, sortOrder: sortOrder);
                objc_sync_exit(self);
                DispatchQueue.main.async {
                    completionBlock(shelfItems);
                }
            }
        }
        else {
            objc_sync_enter(self);
            let tempCallback = FTShelfCallback();
            tempCallback.tempParent = parent;
            tempCallback.tempSearchKey = searchKey;
            tempCallback.tempSorOrder = sortOrder;
            tempCallback.tempCompletionBlock = completionBlock;
            self.tempCompletionBlock.append(tempCallback);

            self.query = FTLocalQueryGather(rootURL: self.URL,
                                            extensionsToListen: [FTFileExtension.ns3, FTFileExtension.ns2, FTFileExtension.group],
                                            skipSubFolder : false,
                                            delegate: self);
            self.query?.startQuery();
            objc_sync_exit(self);
        }
    }
    
    func addShelfItemForDocument(_ path : Foundation.URL,
                                 toTitle : String,
                                 toGroup : FTGroupItemProtocol?,
                                 onCompletion block:@escaping (NSError?,FTDocumentItemProtocol?) -> Void)
    {
        var addedItems = [AnyObject]();
        self.uniqueName(name: toTitle + ".\(FTFileExtension.ns3)", inGroup: toGroup) { (packageName) -> (Void) in
            var fileError : NSError?;
            var shelfItem : FTDocumentItemProtocol?;
            
            do {
                let fileURL = self.documentURLWithFileName(packageName,inGroup: toGroup,collection: self);
                let dict = NSDictionary.init(contentsOf: (path.appendingPathComponent(METADATA_FOLDER_NAME).appendingPathComponent(PROPERTIES_PLIST)));
                
                if let documentUUID = dict?[DOCUMENT_ID_KEY] as? String {
                    try FileManager.init().moveItem(at: path, to: fileURL);
                    shelfItem = self.addItemToCache(fileURL) as? FTDocumentItemProtocol;
                    shelfItem?.documentUUID = documentUUID;
                    if let shelfTempItem = shelfItem {
                        self.hashTable.addItemToHashTable(shelfTempItem, forKey: fileURL);
                        addedItems.append(shelfTempItem);
                    }
                }
            }
            catch let error as NSError{
                fileError = error;
            }
            
            var indexFolderItem: FTSortIndexContainerProtocol = self
            if let groupItem = toGroup as? FTSortIndexContainerProtocol {
                indexFolderItem = groupItem
            }
            if let _shelfItem = shelfItem {
                indexFolderItem.indexCache?.addNewNotebookTitle(_shelfItem.sortIndexHash, atIndex: 0)
            }
            block(fileError,shelfItem);
            
            if(addedItems.isEmpty == false) {
                runInMainThread({
                    NotificationCenter.default.post(name: Notification.Name.shelfItemAdded, object: self, userInfo: [FTShelfItemsKey: addedItems]);
                });
            }
        }
    }
    
    func moveShelfItems(_ shelfItems : [FTShelfItemProtocol],
                       toGroup : FTShelfItemProtocol?,
                       toCollection : FTShelfItemCollection!,
                       onCompletion block: @escaping (NSError?, [FTShelfItemProtocol]) -> Void)
    {
        var itemsToMove = shelfItems;
        var movedItems = [FTShelfItemProtocol]()
        var removedItems = [FTShelfItemProtocol]();
        var removedItemsCollections = Set<FTShelfItemCollectionLocal>();

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
                    guard let shelfCollection = item.shelfCollection as? FTShelfItemCollectionLocal else  {
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
                });
            }
        };
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

    func renameShelfItem(_ shelfItem : FTShelfItemProtocol,
                         toTitle : String,
                         onCompletion block:@escaping (NSError?,FTShelfItemProtocol?) -> Void)
    {
        if(shelfItem is FTDocumentItemProtocol) {
            if let documentItem = shelfItem as? FTDocumentItemProtocol {
                self.renameDocumentItem(documentItem,
                                        toTitle: toTitle) { error, document in
                    if nil == error, let document = document {
                        block(error, document)
                    }
                }
            }
        }
        else {
            if let groupItem = shelfItem as? FTGroupItemProtocol {
                self.renameGroupItem(groupItem,
                                     toGroupName: toTitle) { error, group in
                    if nil == error {
                        block(error, group)
                    }
                }
            }
        }
    }

    func removeShelfItem(_ shelfItem : FTShelfItemProtocol,
                         onCompletion block:@escaping (NSError?, FTShelfItemProtocol?) -> Void)
    {
        var indexFolderItem: FTSortIndexContainerProtocol = self
        if let groupItem = shelfItem.parent as? FTSortIndexContainerProtocol {
            indexFolderItem = groupItem
        }
        indexFolderItem.indexCache?.deleteNotebookTitle(shelfItem.sortIndexHash)
        
        if let item = shelfItem as? FTDocumentItemProtocol {
            self.removeDocumentItem(item,
                                    onCompletion: block);
        } else if let groupItem = shelfItem as? FTGroupItemProtocol {
            self.removeGroupItem(groupItem,
                                 onCompletion: block);
        }
    }
    
    func createGroupItem(_ groupName : String,
                         inGroup: FTGroupItemProtocol?,
                         shelfItemsToGroup items : [FTShelfItemProtocol]?,
                                           onCompletion block: @escaping (NSError?,FTGroupItemProtocol?) -> Void)
    {
        self.uniqueName(name: groupName+".group",
                        inGroup: inGroup) { (newGroupName) -> (Void) in
                            let groupURL = self.documentURLWithFileName(newGroupName,inGroup: inGroup,collection: self);
                            
                            var fileError : NSError?;
                            var groupModel : FTGroupItemProtocol?;

                            let fileManager = FileManager.init();
                            do {
                                try fileManager.createDirectory(at: groupURL, withIntermediateDirectories: true, attributes: nil);
                                groupModel = self.addItemToCache(groupURL.standardizedFileURL) as? FTGroupItemProtocol;
                            }
                            catch let error as NSError {
                                fileError = error;
                            }
                            
                            if(nil == fileError) {
                                if let _items = items, !_items.isEmpty {
                                    self.moveShelfItems(_items,
                                                        toGroup: groupModel,
                                                        toCollection: self) { (error, _) in
                                        block(error,groupModel);
                                    };
                                }
                                else {
                                    block(nil,groupModel);
                                }
                            }
                            else {
                                block(fileError,groupModel);
                            }
                            if let destinationShelfItem = items?.first, let groupItem = groupModel {
                                self.indexCache?.updateNotebookTitle(from: destinationShelfItem.sortIndexHash, to: groupItem.sortIndexHash)
                            }
                            //block(fileError,groupModel);
        }
    }

    //MARK: - Private Methods -
    fileprivate func moveDocumentItem(_ shelfItem : FTDocumentItemProtocol,
                                  toGroup : FTGroupItemProtocol?,
                                  toCollection : FTShelfItemCollection!,
                                  onCompletion block:@escaping (NSError?, FTShelfItemProtocol?, FTShelfItemProtocol?) -> Void)
    {
        var removedItem: FTShelfItemProtocol?
        var movedItem : FTShelfItemProtocol?;
        (toCollection as? FTUniqueNameProtocol)?.uniqueName(name: shelfItem.URL.lastPathComponent,
                                inGroup: toGroup)
        { destFileName -> Void in
            let destURL = self.documentURLWithFileName(destFileName, inGroup: toGroup, collection: toCollection).urlByDeleteingPrivate();
            self.fileOperationMoveFileAtPath(shelfItem.URL.urlByDeleteingPrivate(), toPath: destURL) { error in
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
    

    fileprivate func renameDocumentItem(_ shelfItem : FTDocumentItemProtocol,
                                    toTitle : String,
                                    onCompletion block:@escaping (NSError?,FTDocumentItemProtocol?) -> Void)
    {
        var updatedItems = [AnyObject]();
        let fromTitle = shelfItem.sortIndexHash
        self.uniqueName(name: toTitle+".\(FTFileExtension.ns3)",
            inGroup: shelfItem.parent) { (destFileName) -> (Void) in
            let destURL = self.documentURLWithFileName(destFileName,inGroup: shelfItem.parent,collection: self).urlByDeleteingPrivate()
                
                var fileError : NSError?;
                do {
                    try FileManager.init().moveItem(at: shelfItem.URL, to: destURL);
                    _ = self.moveItemInCache(shelfItem, toURL: destURL);
                    updatedItems.append(shelfItem);
                }
                catch let error as NSError {
                    fileError = error;
                }
                //*******************
                var indexFolderItem: FTSortIndexContainerProtocol = self
                if let groupItem = shelfItem.parent as? FTSortIndexContainerProtocol {
                    indexFolderItem = groupItem
                }
                indexFolderItem.indexCache?.updateNotebookTitle(from: fromTitle, to: shelfItem.sortIndexHash)
                //*******************
                block(fileError,shelfItem);
                if(updatedItems.isEmpty == false) {
                    NotificationCenter.default.post(name: Notification.Name.shelfItemUpdated, object: self, userInfo: [FTShelfItemsKey : updatedItems]);
                }
        };
    }
    
    
    fileprivate func removeDocumentItem(_ shelfItem : FTDocumentItemProtocol,
                                    onCompletion block:@escaping (NSError?,FTDocumentItemProtocol?) -> Void)
    {
        var removedItems = [AnyObject]();

        DispatchQueue.global().async(execute: {
            let fileCordinator = NSFileCoordinator(filePresenter: nil);

            fileCordinator.coordinate(writingItemAt: shelfItem.URL as URL,
                options: NSFileCoordinator.WritingOptions.forDeleting,
                error: nil,
                byAccessor: { writingURL in
                    var fileError : NSError?;
                    do {
                        _ = try FileManager().removeItem(at: writingURL);
                        self.removeItemFromCache(shelfItem.URL as URL, shelfItem: shelfItem);
                        removedItems.append(shelfItem);
                    } catch let error as NSError {
                        fileError = error;
                    }
                    DispatchQueue.main.async(execute: {
                        block(fileError, shelfItem);
                        if(removedItems.isEmpty == false) {
                            NotificationCenter.default.post(name: Notification.Name.shelfItemRemoved, object: self, userInfo: [FTShelfItemsKey : removedItems]);
                        }
                    });
            });
        });
    }
    
    fileprivate func renameGroupItem(_ groupItem : FTGroupItemProtocol,
                                 toGroupName : String,
                                 onCompletion block:@escaping (NSError?,FTGroupItemProtocol?) -> Void)
    {
        var updatedItems = [AnyObject]();
        let fromTitle = groupItem.sortIndexHash
        self.uniqueName(name: toGroupName+".group",
                        inGroup: groupItem.parent) { (uniqueGroupName) -> (Void) in
                            let destURL = self.documentURLWithFileName(uniqueGroupName,inGroup: groupItem.parent,collection: self);
                            
                            let fileManager = FileManager.init();
                            var fileError : NSError?;
                            
                            do {
                                try fileManager.moveItem(at: groupItem.URL, to: destURL);
                                _ = self.moveItemInCache(groupItem, toURL: destURL);
                                updatedItems.append(groupItem);
                            }
                            catch let error as NSError {
                                fileError = error;
                            }
                            self.indexCache?.updateNotebookTitle(from: fromTitle, to: groupItem.sortIndexHash)
                            block(fileError,groupItem);
                            
                            if(updatedItems.isEmpty == false) {
                                NotificationCenter.default.post(name: Notification.Name.shelfItemUpdated, object: self, userInfo: [FTShelfItemsKey:updatedItems]);
                            }
        }
    }
    
    fileprivate func removeGroupItem(_ groupItem : FTGroupItemProtocol,
                                 onCompletion block:(NSError?,FTGroupItemProtocol?) -> Void)
    {
//        var removedItems = [AnyObject]();
        
        var  fileError : NSError?;
        
        let groupURL = groupItem.URL;
        do {
            _ = try FileManager().removeItem(at: groupURL);
            self.removeItemFromCache(groupURL,shelfItem: groupItem);
//            removedItems.append(groupItem);
            for eachItem in groupItem.childrens {
                self.removeItemFromCache(eachItem.URL as URL,shelfItem: eachItem);
//                removedItems.append(eachItem);
            }
        }
        catch let error as NSError {
            fileError = error;
        }
        self.indexCache?.deleteNotebookTitle(groupItem.sortIndexHash)
        block(fileError,groupItem);
//        if(removedItems.isEmpty == false) {
//            NotificationCenter.default.post(name: Notification.Name.shelfItemRemoved, object: self, userInfo: [FTShelfItemsKey:removedItems]);
//        }
    }

    fileprivate func moveGroupItem(_ groupItem : FTGroupItemProtocol,
                                   toGroup: FTGroupItemProtocol?,
                                   toCollection : FTShelfItemCollection!,
                                   onCompletion block:@escaping (NSError?, FTShelfItemProtocol?, FTShelfItemProtocol?) -> Void)
    {
        var toCreateFileName: Bool = true
        var createdGroupItem: FTShelfItemProtocol?
        
        toCollection?.shelfItems(.byName, parent: toGroup, searchKey: nil, onCompletion: { cloudItems in
            for item in cloudItems where item.title == groupItem.title {
                createdGroupItem = item
                toCreateFileName = false
                break
            }
            
            if toCreateFileName {
                (toCollection as? FTUniqueNameProtocol)?.uniqueName(name: groupItem.URL.lastPathComponent,
                                                                    inGroup: toGroup)
                { (uniqueGroupName) -> (Void) in
                    toCollection.createGroupItem(uniqueGroupName.deletingPathExtension, inGroup: toGroup,
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

    //MARK:- FTLocalQueryGatherDelegate -
    func ftLocalQueryGather(_ query: FTLocalQueryGather, didFinishGathering results: [Foundation.URL]?)
    {
        self.buildCache(results);
        self.tempCompletionBlock.forEach { eachItem in
            self.shelfItems(eachItem.tempSorOrder
                            , parent: eachItem.tempParent
                            , searchKey: eachItem.tempSearchKey
                            , onCompletion: eachItem.tempCompletionBlock!);
        }
        self.tempCompletionBlock.removeAll();
    }
    
    //MARK:- Private Cache Mgmt -
    fileprivate func buildCache(_ items: [URL]?) {
        self.childrens.removeAll();
        self.hashTable.removeAll();
        if let items, !items.isEmpty {
            self.addItemsToCache(items);
        }
    }

    // Removed fileprivate URL to build this for NS2 to NS3 Migration
    func addItemsToCache(_ items: [URL]) {
        var addedItems = [AnyObject]();
        for eachItem in items {
            let fileURL = eachItem;
            //Check if the document reference is present in documentMetadataItemHashTable.If the reference is found, its already added to cache. We just need to update the document with this metadataItem
            if(fileURL.pathExtension == FTFileExtension.sortIndex) {
                self.indexPlistContent?.handleSortIndexFileUpdates(nil)
            }
            else {
                var shelfItem = self.hashTable.itemFromHashTable(eachItem) as? FTShelfItemProtocol;
                if(shelfItem == nil) {
                    shelfItem = self.addItemToCache(fileURL) as? FTShelfItemProtocol;
                    
                    if(shelfItem != nil) {
                        self.hashTable.addItemToHashTable(shelfItem!, forKey: eachItem);
                    }
                }
                addedItems.append(shelfItem!);
            }
        }
        if(!addedItems.isEmpty) {
            runInMainThread({
                NotificationCenter.default.post(name: Notification.Name.shelfItemAdded, object: self, userInfo: [FTShelfItemsKey:addedItems]);
            });
        }
    }
    
    //MARK:- FTShelfCacheProtocol -
    func addItemToCache(_ fileURL: Foundation.URL) -> FTDiskItemProtocol? {

        var shelfItem : FTShelfItemProtocol?
        
        objc_sync_enter(self);
        let fileItemURL = fileURL;
        if(self.isGroup(fileItemURL)) {
            shelfItem = self.addGroupItemForURL(fileItemURL);
        }
        else if(fileURL.isSuportedBookExtension) {
            shelfItem = self.addBookItemForURL(fileURL);
            (shelfItem as? FTDocumentItemProtocol)?.isDownloaded = true;
        }
        objc_sync_exit(self);
        if(ENABLE_SHELF_RPOVIDER_LOGS) {
            debugPrint("\(#file.components(separatedBy: "/").last ?? ""): Added :\(fileURL.lastPathComponent)");
        }
        return shelfItem;
    }
    
    func removeItemFromCache(_ fileURL: Foundation.URL, shelfItem: FTDiskItemProtocol) {

        guard let item = shelfItem as? FTShelfItemProtocol else {
            return
        }
        objc_sync_enter(self);
        if(self.docBelongsToGroup(fileURL)) {
            if let groupItem = item.parent {
                groupItem.removeChild(item);
                self.hashTable.removeItemFromHashTable(item.URL);
                if(groupItem.childrens.isEmpty) {
                    self.removeGroupItem(groupItem, onCompletion: { (error, group) in
                        if(ENABLE_SHELF_RPOVIDER_LOGS) {
                            debugPrint("\(#file.components(separatedBy: "/").last ?? ""): Removed Group :\(groupItem.URL.lastPathComponent) child count 0");
                        }
                    });
                }
            }
        }
        else {
            self.removeChild((item));
            self.hashTable.removeItemFromHashTable(item.URL);
        }
        if(ENABLE_SHELF_RPOVIDER_LOGS) {
            debugPrint("\(#file.components(separatedBy: "/").last ?? ""): Removed :\(fileURL.lastPathComponent)");
        }
        objc_sync_exit(self);
    }
    
    func moveItemInCache(_ shelfItem: FTDiskItemProtocol, toURL: Foundation.URL) -> Bool {
        if let item = shelfItem as? FTShelfItemProtocol {
            objc_sync_enter(self);
            if(self.isGroup(toURL)) {
                //Change the url of the document to new url.
                self.hashTable.removeItemFromHashTable(item.URL);
                item.URL = toURL;
                self.hashTable.addItemToHashTable(item, forKey: item.URL);
                if let groupItem = shelfItem as? FTGroupItemProtocol {
                    for eachItem in groupItem.childrens {
                        let eachItemURL = eachItem.URL;
                        let newURL = toURL.appendingPathComponent(eachItemURL.lastPathComponent);
                        _ = self.moveItemInCache(eachItem,toURL: newURL);
                    }
                }
            }
            else {
                let currentGroup = item.parent;
                //Get the new group item it should be moved to. Create if not present
                var newGroupItem : FTGroupItemProtocol?
                if(self.docBelongsToGroup(toURL)) {
                    newGroupItem = self.groupItemForURL(toURL.deletingLastPathComponent());
                    if(nil == newGroupItem) {
                        newGroupItem = self.addGroupItemForURL(toURL.deletingLastPathComponent())
                        if nil == newGroupItem {
                            NSException.init(name: NSExceptionName(rawValue: "Group not found"), reason:"Group should be created first in metadata update callback before book", userInfo: nil).raise();
                        }
                    }
                }
                
                //Add the document to new group by removing from previous group
                if(currentGroup?.uuid != newGroupItem?.uuid) {
                    self.hashTable.removeItemFromHashTable(item.URL);
                    if(currentGroup != nil) {
                        currentGroup?.removeChild(item);
                        if(currentGroup!.childrens.isEmpty) {
                            self.removeGroupItem(currentGroup!, onCompletion: { (error, groupItem) in
                                if(ENABLE_SHELF_RPOVIDER_LOGS) {
                                    debugPrint("\(#file.components(separatedBy: "/").last ?? ""): Group Deleted :\(String(describing: groupItem?.URL.lastPathComponent)) child count 0");
                                }
                            });
                        }
                    }
                    else {
                        self.removeChild(item);
                    }
                    
                    if(newGroupItem != nil) {
                        newGroupItem?.addChild(item);
                    }
                    else {
                        self.addChild(item);
                    }
                    self.hashTable.addItemToHashTable(item, forKey: toURL);
                }
                #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
                //Recent:
                if(toURL != item.URL) {
                    NotificationCenter.default.post(name: .shelfItemDidGetMovedInternal, object: self, userInfo: [FTOldURLS : [item.URL],FTNewURLS : [toURL]]);
                }
                #endif
                //Recent:
                
                //Change the url of the document to new url.
                item.URL = toURL;
            }
            if(ENABLE_SHELF_RPOVIDER_LOGS) {
                debugPrint("\(#file.components(separatedBy: "/").last ?? ""): Updated :\(toURL.lastPathComponent)");
            }
            objc_sync_exit(self);
        }
        return true;
    }
    
    //MARK:- Adding Items -
    fileprivate func addGroupItemForURL(_ fileURL : Foundation.URL) -> FTGroupItemProtocol? {
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
    
    fileprivate func addBookItemForURL(_ url : Foundation.URL) -> FTShelfItemProtocol
    {
        var shelfItem : FTDocumentItemProtocol?;
        if(self.docBelongsToGroup(url)) {
            let groupURL = url.deletingLastPathComponent().urlByDeleteingPrivate()
            var groupItem = self.groupItemForURL(groupURL);
            
            if(nil == groupItem) {
                groupItem = self.addGroupItemForURL(groupURL)
            }
            shelfItem = FTDocumentItem.init(fileURL:url.urlByDeleteingPrivate());
            groupItem?.addChild(shelfItem!);
        }
        else {
            shelfItem = FTDocumentItem.init(fileURL:url.urlByDeleteingPrivate());
            self.addChild(shelfItem!);
        }
        return shelfItem!;
    }
    
    //MARK:- Checks based on URL
    fileprivate func docBelongsToGroup(_ url : Foundation.URL) -> Bool
    {
        let dirURL = url.urlByDeleteingPrivate().deletingLastPathComponent();
        return self.isGroup(dirURL);
    }
    
    fileprivate func isGroup(_ url:Foundation.URL) -> Bool
    {
        let fileItemURL = url.urlByDeleteingPrivate();
        if(fileItemURL.pathExtension == FTFileExtension.group)
        {
            return true;
        }
        return false;
    }
    
    func documentURLWithFileName(_ fileName : String,inGroup : FTGroupItemProtocol?,collection : FTShelfItemCollection) -> Foundation.URL
    {
        var rootURL = collection.URL
        if let _group = inGroup {
            rootURL = _group.URL;
        }
        let urlToReturn = rootURL.urlByDeleteingPrivate().appendingPathComponent(fileName);
        return urlToReturn;
    }
    
    fileprivate func fileOperationMoveFileAtPath(_ fileURL : Foundation.URL,toPath : Foundation.URL,onCompletion:@escaping (NSError?) -> Void)
    {
        DispatchQueue.global().async(execute: {
            let fileCoordinator = NSFileCoordinator.init(filePresenter: nil);
            
            fileCoordinator.coordinate(writingItemAt: fileURL, options: NSFileCoordinator.WritingOptions.forMoving, writingItemAt: toPath, options: NSFileCoordinator.WritingOptions.forReplacing, error: nil, byAccessor: { (newURL1, newURL2) in
                do {
                    fileCoordinator.item(at: newURL1, willMoveTo: newURL2);
                    try FileManager.init().moveItem(at: newURL1, to: newURL2);
                    fileCoordinator.item(at: newURL1, didMoveTo: newURL2);
                    DispatchQueue.main.async(execute: {
                        onCompletion(nil);
                    });
                }
                catch let error as NSError {
                    DispatchQueue.main.async(execute: {
                        onCompletion(error);
                    });
                }
            });
        });
    }
    
    func uniqueName(name : String,inGroup : FTGroupItemProtocol?,onCompletion : @escaping (String) -> (Void))
    {
        var rootURL = self.URL
        if let _group = inGroup {
            rootURL = self.URL.deletingLastPathComponent();
            rootURL = rootURL.appendingPathComponent(_group.URL.relativePathWRTCollection());
        }
        rootURL = rootURL.urlByDeleteingPrivate()
        let destFileName = FileManager.uniqueFileName(name, inFolder: rootURL);
        onCompletion(destFileName);
    }

    func isNS2Collection() -> Bool {
        let belongs = self.parent?.belongsToNS2()
        return belongs ?? false
    }
}

//MARK:- Manual Sorting
extension FTShelfItemCollectionLocal: FTSortIndexContainerProtocol {
    func handleSortIndexFileUpdates(_ infoItem: Any?) {
        if let fileURL = infoItem as? URL {
            if let groupItem = self.groupItemForURL(fileURL.deletingLastPathComponent()) {
                (groupItem as? FTSortIndexContainerProtocol)?.handleSortIndexFileUpdates(nil)
            }
            else {
                self.indexPlistContent?.handleSortIndexFileUpdates(nil)
            }
        }
    }
}
