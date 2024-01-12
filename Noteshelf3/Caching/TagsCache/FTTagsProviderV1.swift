//
//  FTTagsProviderV1.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 10/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTTagsProviderV1: NSObject {
    static let shared = FTTagsProviderV1();
    
    private lazy var alTag: FTAllTag = {
        return FTAllTag(name: "AllTags");
    }();
    
    private lazy var userTags: [String:FTTag] = {
        let items = load();
        return items;
    }()
    
    func renameTag(_ tag: FTTag,to newName: String) {
        if var currentTag = userTags.removeValue(forKey: tag.tagName.lowercased()) {
            currentTag.setTagName(newName);
            userTags[newName.lowercased()] = currentTag;
            //save()
        }
    }
    
    func deleteTag(_ tag: FTTag) {
        if let tag = userTags.removeValue(forKey: tag.tagName.lowercased()) {
            tag.markAsDeleted();
            //save()
        }
    }
    
    func getTags(_ includeAllTags: Bool = false,sort:Bool = false) -> [FTTag] {
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
        return userCreatedTags;
    }
    
    func getTagsfor(_ names:[String]) -> [FTTag] {
        var tagItems = [FTTag]();
        names.forEach { eachName in
            if eachName.lowercased() == self.alTag.tagName.lowercased() {
                tagItems.append(self.alTag)
            }
            else if let tag = self.userTags[eachName.lowercased()] {
                tagItems.append(tag)
            }
            else {
                let tag =  FTTag(name: eachName);
                self.userTags[eachName.lowercased()] = tag;
                tagItems.append(tag)
            }
        }
        return tagItems;
    }
    
    func syncTagsWithLocalCache(documentID: String) {
        let cacheDocument = FTCachedDocument(documentID: documentID);
        let documentName = cacheDocument.documentName;
        
        self.syncNotebookTagsWithLocalCache(documentID: documentID, documentName: documentName, tagNames: cacheDocument.docuemntTags);
        let pages = cacheDocument.pages;
        pages.forEach { eachpage in
            self.syncPageTagsWithLocalCache(documentID: documentID
                                            , documentName: documentName
                                            , pageID: eachpage.uuid
                                            , tagNames: eachpage.tags());
        }
    }
    
    func syncNotebookTagsWithLocalCache(documentID: String
                                        ,documentName: String?
                                        , tagNames: [String])
    {
        var currentTags = Set<FTTag>();
        self.userTags.forEach { eachTag in
            let tag = eachTag.value;
            if nil != tag.documentTaggedEntity(documentID) {
                currentTags.insert(tag);
            }
        }
        let newTags = Set(self.getTagsfor(tagNames));

        let tagsToremove = currentTags.subtracting(newTags);
        tagsToremove.forEach { eachTag in
            if let docEntity = eachTag.documentTaggedEntity(documentID) {
                eachTag.removeTaggedItem(docEntity)
            }
        }

        let tagsToAdd = newTags.subtracting(currentTags);
        tagsToAdd.forEach { eachTag in
            let item = FTDocumentTaggedEntity(documentUUID: documentID,documentName:documentName)
            eachTag.addTaggedItemIfNeeded(item);
        }
    }
    
    func syncPageTagsWithLocalCache(documentID: String
                                    ,documentName: String?
                                    , pageID: String
                                    , tagNames: [String])
    {
        var currentTags = Set<FTTag>();
        self.userTags.forEach { eachTag in
            let tag = eachTag.value;
            if nil != tag.pageTaggedEntity(documentID, pageUUID: pageID) {
                currentTags.insert(tag);
            }
        }
        let newTags = Set(self.getTagsfor(tagNames));

        let tagsToremove = currentTags.subtracting(newTags);
        tagsToremove.forEach { eachTag in
            if let docEntity = eachTag.pageTaggedEntity(documentID, pageUUID: pageID) {
                eachTag.removeTaggedItem(docEntity)
            }
        }
        
        let tagsToAdd = newTags.subtracting(currentTags);
        tagsToAdd.forEach { eachTag in
            let item = FTPageTaggedEntity(documentUUID: documentID
                                          ,documentName:documentName
                                          ,pageUUID: pageID
                                          ,pageIndex: 0)
            eachTag.addTaggedItemIfNeeded(item);
        }
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
                        allTags[eachItem.key.lowercased()] = tag;
                    }
                }
            }
            catch {
                
            }
        }
        return allTags;
    }
    
    func save() {
        var infoToStore = [String: [String]]();
        self.userTags.values.forEach { eachItem in
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
