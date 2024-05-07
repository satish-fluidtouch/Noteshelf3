//
//  FTTagsProvider.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 10/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension Notification.Name {
    static let didUpdateTags = Notification.Name(rawValue:"didupdateTagsNotification");
}

class FTTagsProvider: NSObject {
    static let shared = FTTagsProvider();
    private var lock = NSRecursiveLock();
    var rootDocumentsURL: URL?;
    
    private var taggedEntitiesInfo = [String:FTTaggedEntity]();

    private(set) lazy var allTag: FTAllTag = {
        return FTAllTag(name: "AllTags");
    }();
    
    private lazy var userTags: [String:FTTag] = {
        lock.lock()
        let items = load();
        lock.unlock()
        return items;
    }()
        
    func renameTag(_ tag: FTTag,to newName: String) {
        lock.lock();
        if let currentTag = userTags.removeValue(forKey: tag.tagKey) {
            currentTag.setTagName(newName);
            userTags[tag.tagKey] = currentTag;
            save()
            self.postTagUpdateNotification(["operation" : "rename", "tags" : [currentTag]])
        }
        lock.unlock();
    }
    
    func deleteTags(_ tag: [FTTag]) {
        lock.lock();
        var deletedTags = [FTTag]();
        tag.forEach { eachTag in
            if let tag = userTags.removeValue(forKey: eachTag.tagKey) {
                tag.markAsDeleted();
                deletedTags.append(tag)
            }
        }
        if !deletedTags.isEmpty {
            save()
            self.postTagUpdateNotification(["operation" : "delete", "tags" : deletedTags])
        }
        lock.unlock();
    }
        
    func getTags(_ includeAllTags: Bool = false,sort:Bool = false) -> [FTTag] {
        lock.lock();
        var userCreatedTags = Array(self.userTags.values);
        userCreatedTags = sort ? userCreatedTags.sortedTags() : userCreatedTags;
        if includeAllTags {
            userCreatedTags.insert(self.allTag, at: 0);
        }
        lock.unlock();
        return userCreatedTags;
    }
    
    func getTagsfor(_ names:[String],shouldCreate: Bool) -> [FTTag] {
        lock.lock();
        var tagItems = [FTTag]();
        var tagsToAdd = [FTTag]();
        names.forEach { eachName in
            if eachName.caseInsensitiveCompare(self.allTag.tagName) == .orderedSame {
                tagItems.append(self.allTag)
            }
            else if let tag = self.userTags[eachName.lowercased()] {
                tagItems.append(tag)
            }
            else if shouldCreate {
                let tag =  FTTag(name: eachName);
                tagsToAdd.append(tag);
                tagItems.append(tag)
            }
        }
        self.addTags(tagsToAdd);
        lock.unlock();
        return tagItems;
    }
}

private extension FTTagsProvider {
    func load() -> [String:FTTag] {
        var allTags = [String:FTTag]();
        let filePath = self.cacheLocation;
        let filemanager = FileManager();
        if filemanager.fileExists(atPath: filePath.path(percentEncoded: false)) {
            do {
                let data = try Data(contentsOf: filePath)
                if let tagsInfo = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: [String]] {
                    tagsInfo.forEach { eachItem in
                        let tag = FTTag(name: eachItem.key, documentUUIDs: eachItem.value);
                        allTags[tag.tagKey] = tag;
                    }
                }
            }
            catch {
                
            }
        }
        return allTags;
    }
    
    func save() {
        let tags = self.userTags;
        DispatchQueue.global().async {
            var infoToStore = [String: [String]]();
            tags.values.forEach { eachItem in
                infoToStore[eachItem.tagName] = Array(eachItem.documentIDs);
            }
            do {
                let data = try PropertyListSerialization.data(fromPropertyList: infoToStore, format: .xml, options: 0);
                try data.write(to: self.cacheLocation)
            }
            catch {
                fatalError("FTTagsProvider: Failed to write tags cache");
            }
        }
    }
}

private extension FTTagsProvider {
    func addTags(_ tags: [FTTag]) {
        lock.lock();
        tags.forEach { eachTag in
            self.userTags[eachTag.tagKey] = eachTag;
        }
        if !tags.isEmpty {
            save();
            self.postTagUpdateNotification(["operation" : "add", "tags" : tags])
        }
        lock.unlock();
    }
    
    func addTaggedEntityToCache(_ entity: FTTaggedEntity) {
        lock.lock();
        var key = entity.documentUUID;
        if let _pageEntity = entity as? FTPageTaggedEntity {
            key = key.appending("_\(_pageEntity.pageUUID)");
        }
        self.taggedEntitiesInfo[key] = entity;
        lock.unlock();
    }
    
    private func postTagUpdateNotification(_ userInfo: [AnyHashable:Any]) {
        if !Thread.current.isMainThread {
            runInMainThread {
                self.postTagUpdateNotification(userInfo)
            }
            return;
        }
        NotificationCenter.default.post(name: .didUpdateTags, object: nil, userInfo: userInfo)
    }
}

private extension FTTagsProvider {
    func syncNotebookTagsWithLocalCache(documentID: String
                                        , documentItem: FTShelfItemProtocol
                                        , tagNames: Set<FTTag>) {
        guard let documentEntity = self.tagggedEntity(documentID
                                                      , docuemntItem: documentItem
                                                      , pageID: nil
                                                      , createIfNotPresent: true) else {
            return;
        }
        let currentTags = Set(documentEntity.tags);
        let tagsToRemove = currentTags.subtracting(tagNames);
        tagsToRemove.forEach { eachTag in
            eachTag.removeTaggedItem(documentEntity)
        }
        
        let tagsToAdd = tagNames.subtracting(currentTags);
        tagsToAdd.forEach { eachTag in
            eachTag.addTaggedItem(documentEntity);
        }
    }
    
    func syncPageTagsWithLocalCache(documentID: String
                                    , documentItem: FTShelfItemProtocol
                                    , pageID: String
                                    , tagNames: Set<FTTag>
                                    , pageProperties: FTTaggedPageProperties) {
        guard let pageEntity = self.tagggedEntity(documentID
                                                  , docuemntItem: documentItem
                                                  , pageID: pageID
                                                  , createIfNotPresent: true) else {
            return;
        }
        let currentTags = Set(pageEntity.tags);
        let tagsToRemove = currentTags.subtracting(tagNames);
        tagsToRemove.forEach { eachTag in
            eachTag.removeTaggedItem(pageEntity)
        }
        
        let tagsToAdd = tagNames.subtracting(currentTags);
        tagsToAdd.forEach { eachTag in
//            pageEntity.relativePath = documentPath;
            (pageEntity as? FTPageTaggedEntity)?.updatePageProties(pageProperties);
            eachTag.addTaggedItem(pageEntity);
        }
        
        let oldOnces = tagNames.subtracting(tagsToAdd)
        oldOnces.forEach { eachTag in
//            pageEntity.relativePath = documentPath;
            (pageEntity as? FTPageTaggedEntity)?.updatePageProties(pageProperties);
            if pageEntity.tags.contains(eachTag), nil == eachTag.pageTaggedEntity(documentID, pageUUID: pageID) {
                debugLog("tag present item missing")
            }
        }
    }
}

private extension FTTagsProvider {
    var cacheLocation: URL {
        guard NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last != nil else {
            fatalError("Unable to find cache directory")
        }
        let cacheFolderURL = FTDocumentCache.shared.sharedCacheFolderURL
        let cachedTagsPlistURL = cacheFolderURL.appendingPathComponent(FTCacheFiles.cacheTagsPlist)
        return cachedTagsPlistURL
    }
}

private extension FTTag {
    var tagKey: String {
        return self.tagName.lowercased();
    }
}

internal extension FTTagsProvider {
    @discardableResult
    func syncTagWithDocument(_ cacheDocument: FTDocumentProtocol,documentItem: FTShelfItemProtocol) -> Set<FTTag> {
        var updatedTags = Set<FTTag>()
        let documentID = cacheDocument.documentUUID
        let currentTags = Set(self.userTags.values.filter{$0.documentIDs.contains(documentID)});
        var newTagsSet = Set(self.getTagsfor(cacheDocument.documentTags(),shouldCreate: true))
        
        var shouldSave = false;
        self.syncNotebookTagsWithLocalCache(documentID: documentID
                                            , documentItem: documentItem
                                            , tagNames: newTagsSet);
        let pages = cacheDocument.pages();
        if pages.isEmpty {
            self.removeAllTaggedItemsOfDocumentUUID(documentID);
        }
        else {
            pages.enumerated().forEach { eachItem in
                let eachpage = eachItem.element;
                if let tagpage = eachpage as? FTPageTagsProtocol {
                    let index = eachItem.offset;
                    let pageSet = Set(self.getTagsfor(tagpage.tags(), shouldCreate: true))
                    
                    let pageProperties = FTTaggedPageProperties();
                    pageProperties.pageSize = eachpage.pdfPageRect;
                    pageProperties.pageIndex = index;
                    
                    self.syncPageTagsWithLocalCache(documentID: documentID
                                                    , documentItem: documentItem
                                                    , pageID: eachpage.uuid
                                                    , tagNames: pageSet
                                                    , pageProperties: pageProperties);
                    newTagsSet.formUnion(pageSet);
                }
            }
        }
        let tagsToremove = currentTags.subtracting(newTagsSet);
        tagsToremove.forEach { eachItem in
            eachItem.removeDocumentID(documentID);
            shouldSave = true;
        }
        
        newTagsSet.forEach { eachItem in
            shouldSave = true;
            eachItem.addDocumentID(documentID);
        }
        
        updatedTags = updatedTags.union(tagsToremove);
        updatedTags = updatedTags.union(newTagsSet);
        if(shouldSave) {
            save();
        }
        return updatedTags;
    }
    
    func syncTagsWithLocalCache(documentID: String,documentitem: FTShelfItemProtocol? = nil) {
        if let shelfItem = documentitem {
            let cacheDocument = FTCachedDocument(documentID: documentID);
            syncTagWithDocument(cacheDocument,documentItem: shelfItem);
        }
        else {
            self.syncTagsWithLocalCache(documentID: documentID);
        }
    }

    private func syncTagsWithLocalCache(documentID: String) {
        let cacheDocument = FTCachedDocument(documentID: documentID);
        FTNoteshelfDocumentProvider.shared.document(with: documentID, orRelativePath: cacheDocument.relativePath, bypassPasswordProtected: true) { shelfItem in
            if let item = shelfItem {
                self.syncTagWithDocument(cacheDocument, documentItem: item)
            }
        }
    }
    
    func saveCache() {
        self.lock.lock()
        save();
        self.lock.unlock()
    }
        
    func tagggedEntity(_ documentID: String
                       , docuemntItem: FTShelfItemProtocol
                       , pageID: String? = nil
                       , createIfNotPresent: Bool = false) -> FTTaggedEntity? {
        lock.lock();
        var key = documentID;
        if let _pageID = pageID {
            key = key.appending("_\(_pageID)");
        }
        var enity = self.taggedEntitiesInfo[key];
        if nil == enity, createIfNotPresent {
            let newEntity = FTTaggedEntity.taggedEntity(documentID, documentItem: docuemntItem, pageID: pageID);
            enity = newEntity;
            self.addTaggedEntityToCache(newEntity);
        }
        enity?.setDocumentItem(docuemntItem);
        lock.unlock();
        return enity;
    }

    
    func removeTaggedEntityFromCache(_ taggedEntity: FTTaggedEntity) {
        lock.lock();
        if taggedEntity.tags.isEmpty {
            var key = taggedEntity.documentUUID;
            if let _pageID = taggedEntity as? FTPageTaggedEntity {
                key = key.appending("_\(_pageID.pageUUID)");
            }
            self.taggedEntitiesInfo.removeValue(forKey: key)
        }
        lock.unlock();
    }
}


private extension FTTagsProvider {
    func removeAllTaggedItemsOfDocumentUUID(_ documentUUID: String) {
        lock.lock();
        var keysToRemove = [String]();
        self.taggedEntitiesInfo.forEach { eachItem in
            if eachItem.value.documentUUID == documentUUID {
                eachItem.value.tags.forEach { eachTag in
                    eachTag.removeTaggedItem(eachItem.value);
                }
                keysToRemove.append(eachItem.key);
            }
        }
        keysToRemove.forEach { eachKey in
            self.taggedEntitiesInfo.removeValue(forKey: eachKey);
        }
        
        lock.unlock();
    }
}
