//
//  FTTagsProviderV1.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 10/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension Notification.Name {
    static let didUpdateTags = Notification.Name(rawValue:"didupdateTagsNotification");
}

class FTTagsProviderV1: NSObject {
    static let shared = FTTagsProviderV1();
    private var lock = NSRecursiveLock();
    
    private lazy var alTag: FTAllTag = {
        return FTAllTag(name: "AllTags");
    }();
    
    private lazy var userTags: [String:FTTag] = {
        lock.lock()
        let items = load();
        lock.unlock()
        return items;
    }()
    
    private func addTags(_ tags: [FTTag]) {
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
    
    func renameTag(_ tag: FTTag,to newName: String) {
        lock.lock();
        if let currentTag = userTags.removeValue(forKey: tag.tagKey) {
            currentTag.setTagName(newName);
            userTags[tag.tagKey] = currentTag;
            save()
            self.postTagUpdateNotification(["operation" : "add", "tags" : [currentTag]])
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
    
    private func postTagUpdateNotification(_ userInfo: [AnyHashable:Any]) {
        if !Thread.current.isMainThread {
            runInMainThread {
                self.postTagUpdateNotification(userInfo)
            }
            return;
        }
        NotificationCenter.default.post(name: .didUpdateTags, object: nil, userInfo: userInfo)
    }
    
    func getTags(_ includeAllTags: Bool = false,sort:Bool = false) -> [FTTag] {
        lock.lock();
        var userCreatedTags = Array(self.userTags.values);
        if sort {
            userCreatedTags.sort { tag1, tage2 in
                let compare = tag1.tagName.compare(tage2.tagName, options:[.caseInsensitive,.numeric], range: nil, locale: nil)
                return compare == .orderedAscending
            }
        }
        if includeAllTags {
            userCreatedTags.insert(self.alTag, at: 0);
        }
        lock.unlock();
        return userCreatedTags;
    }
    
    func getTagsfor(_ names:[String]) -> [FTTag] {
        lock.lock();
        var tagItems = [FTTag]();
        var tagsToAdd = [FTTag]();
        names.forEach { eachName in
            if eachName.caseInsensitiveCompare(self.alTag.tagName) == .orderedSame {
                tagItems.append(self.alTag)
            }
            else if let tag = self.userTags[eachName.lowercased()] {
                tagItems.append(tag)
            }
            else {
                let tag =  FTTag(name: eachName);
                tagsToAdd.append(tag);
                tagItems.append(tag)
            }
        }
        self.addTags(tagsToAdd);
        lock.unlock();
        return tagItems;
    }
    
    func syncTagsWithLocalCache(documentID: String) {
        lock.lock();
        let cacheDocument = FTCachedDocument(documentID: documentID);
        let documentName = cacheDocument.documentName;
        
        let currentTags = Set(self.userTags.values.filter{$0.documentIDs.contains(documentID)});
        var newTagsSet = Set(self.getTagsfor(cacheDocument.docuemntTags))
        
        self.syncNotebookTagsWithLocalCache(documentID: documentID
                                            , documentName: documentName
                                            , tagNames: newTagsSet);
        let pages = cacheDocument.pages;
        pages.enumerated().forEach { eachItem in
            let eachpage = eachItem.element;
            let index = eachItem.offset;
            let pageSet = Set(self.getTagsfor(eachpage.tags()))
            
            let pageProperties = FTTaggedPageProperties();
            pageProperties.pageSize = eachpage.pdfPageRect;
            pageProperties.pageIndex = index;
            
            self.syncPageTagsWithLocalCache(documentID: documentID
                                            , documentName: documentName
                                            , pageID: eachpage.uuid
                                            , tagNames: pageSet
                                            , pageProperties: pageProperties);
            newTagsSet.formUnion(pageSet);
        }
        
        let tagsToremove = currentTags.subtracting(newTagsSet);
        tagsToremove.forEach { eachItem in
            eachItem.removeDocumentID(documentID);
        }
        
        newTagsSet.forEach { eachItem in
            eachItem.addDocumentID(documentID);
        }
        lock.unlock();
    }
}

private extension FTTagsProviderV1 {
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

private extension FTTagsProviderV1 {
    func syncNotebookTagsWithLocalCache(documentID: String
                                        ,documentName: String?
                                        , tagNames: Set<FTTag>) {
        var currentTags = Set(self.userTags.values.filter{nil != $0.documentTaggedEntity(documentID)});
        
        let tagsToRemove = currentTags.subtracting(tagNames);
        tagsToRemove.forEach { eachTag in
            if let docEntity = eachTag.documentTaggedEntity(documentID) {
                eachTag.removeTaggedItem(docEntity)
            }
        }
        
        let tagsToAdd = tagNames.subtracting(currentTags);
        tagsToAdd.forEach { eachTag in
            let item = FTDocumentTaggedEntity(documentUUID: documentID,documentName:documentName)
            eachTag.addTaggedItemIfNeeded(item);
        }
    }
    
    func syncPageTagsWithLocalCache(documentID: String
                                    , documentName: String?
                                    , pageID: String
                                    , tagNames: Set<FTTag>
                                    , pageProperties: FTTaggedPageProperties) {
        let currentTags = Set(self.userTags.values.filter{nil != $0.pageTaggedEntity(documentID,pageUUID: pageID)});
        let tagsToRemove = currentTags.subtracting(tagNames);
        tagsToRemove.forEach { eachTag in
            if let docEntity = eachTag.pageTaggedEntity(documentID, pageUUID: pageID) {
                eachTag.removeTaggedItem(docEntity)
            }
        }
        
        let tagsToAdd = tagNames.subtracting(currentTags);
        tagsToAdd.forEach { eachTag in
            let item = FTPageTaggedEntity(documentUUID: documentID
                                          ,documentName:documentName
                                          ,pageUUID: pageID
                                          ,pageProperties: pageProperties)
            eachTag.addTaggedItemIfNeeded(item);
        }
        let oldOnces = tagNames.subtracting(tagsToAdd)
        oldOnces.forEach { eachTag in
            if let docEntity = eachTag.pageTaggedEntity(documentID, pageUUID: pageID) as? FTPageTaggedEntity {
                docEntity.updatePageProties(pageProperties);
            }
        }
    }
}

private extension FTTagsProviderV1 {
    var cacheLocation: URL {
        guard NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last != nil else {
            fatalError("Unable to find cache directory")
        }
        let cacheFolderURL = FTDocumentCache.shared.cacheFolderURL
        let cachedTagsPlistURL = cacheFolderURL.appendingPathComponent(FTCacheFiles.cacheTagsPlist)
        return cachedTagsPlistURL
    }
}

private extension FTTag {
    var tagKey: String {
        return self.tagName.lowercased();
    }
}
