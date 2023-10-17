//
//  FTCacheTagsProcessor.swift
//  Noteshelf3
//
//  Created by Siva on 30/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

enum FTTagsCacheError: Error {
    case invalidPath
    case corruptedDocument
    case documentNotDownloaded
    case documentPlistNotAvailable
    case tagsPlistNotAvailable
}

final class FTCacheTagsProcessor {

    static let shared = FTCacheTagsProcessor()
    private let fileManager = FileManager()
    let cacheFolderURL = FTDocumentCache.shared.cacheFolderURL

    func createCacheTagsPlistIfNeeded() {
        let cachedTagsPlistURL = cacheFolderURL.appendingPathComponent(FTCacheFiles.cacheTagsPlist)
        if !fileManager.fileExists(atPath: cachedTagsPlistURL.path) {
            writeMainPlist()
        } else {
            let tagsPlist = self.readTagsInfo()
            if tagsPlist == nil {
                writeMainPlist()
            }
        }
        cacheLog(.info, cachedPageTagsLocation())
    }

    private func writeMainPlist() {
        let cachedTagsPlistURL = cacheFolderURL.appendingPathComponent(FTCacheFiles.cacheTagsPlist)
        let dic: [String: [String]] = [String :[String]]()
        // Swift Dictionary To Data.
        do  {
            let data = try PropertyListSerialization.data(fromPropertyList: dic, format: PropertyListSerialization.PropertyListFormat.binary, options: 0)
            do {
                try data.write(to: cachedTagsPlistURL, options: .atomic)
            } catch (let error){
                cacheLog(.error, error)
            }
        }catch (let error){
            cacheLog(.error, error)
        }

    }

    private func cachedPageTagsLocation() -> URL {
        guard NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last != nil else {
            fatalError("Unable to find cache directory")
        }
        let cachedTagsPlistURL = cacheFolderURL.appendingPathComponent(FTCacheFiles.cacheTagsPlist)
        return cachedTagsPlistURL
    }

    func allTags() -> [FTTagItemModel] {
        var allTags = [FTTagItemModel]()
        if let cacheTagsPlist = self.readTagsInfo() {
            let plistTags = NSMutableDictionary(dictionary: cacheTagsPlist.tags)
            plistTags.forEach { (key, value) in
                if let ids = value as? [String], ids.isEmpty {
                    plistTags.removeObject(forKey: key)
                } else if let tagName = key as? String, let ids = value as? [String] {
                    if let tagItem = FTTagsProvider.shared.getTagItemFor(tagName: tagName) {
                        tagItem.updateDocumentIds(docIds: ids)
                        allTags.append(tagItem)
                    } else {
                        allTags.append(FTTagItemModel(tag: FTTagModel(text: tagName), documentIds: ids))
                    }
                }
            }
            return allTags
        }
        return []
    }

    func cachedTags() -> [String] {
        if let cacheTagsPlist = self.readTagsInfo() {
            let plistTags = NSMutableDictionary(dictionary: cacheTagsPlist.tags)
            plistTags.forEach { (key, value) in
                if let ids = value as? [String], ids.isEmpty {
                    plistTags.removeObject(forKey: key)
                }
            }
            let keys = plistTags.allKeys as? [String]
            if let sortedArray = keys?.sorted() {
                return sortedArray
            }
        }
        return []
    }

    func cachedDocumentPlistFor(documentUUID: String, completion: @escaping (FTCachedDocumentPlist?, Error?) -> Void) {
        let cachedLocation = FTDocumentCache.shared.cachedLocation(for: documentUUID)
        let destinationURL = cachedLocation.appendingPathComponent(FTCacheFiles.cacheDocumentPlist)
        if fileManager.fileExists(atPath: destinationURL.path) {
            do {
                let data = try Data(contentsOf: destinationURL)
                let decoder = PropertyListDecoder()
                let documentPlist = try decoder.decode(FTCachedDocumentPlist
                    .self, from: data)
                completion(documentPlist, nil)
            } catch let error {
                completion(nil, error)
            }
        } else {
            completion(nil, FTCacheError.fileNotExists)
        }
    }

    private func cacheTagsIntoPlist(_ tags: [String]
                                     , for documentUUID: String
                                     , tagsplist cachedTagsPlist: FTCacheTagsPlist) -> (refreshSideMenu: Bool,refreshShelf: Bool) {
        let plist = cachedTagsPlist
        var plistTags = plist.tags
        
        FTTagsProvider.shared.removeDocumentId(docId: documentUUID)
        
        var refreshTagsView = false
        if !Set(tags).isSubset(of: plistTags.keys) {
            refreshTagsView = true
        }
        tags.forEach { tag in
            let docIds = Set(plistTags[tag] ?? [])
            if !docIds.contains(documentUUID) {
                refreshTagsView = true
            }
        }
        for key in plistTags.keys {
            if var ids = plistTags[key] {
                for (index, docId) in ids.enumerated() {
                    if documentUUID == docId {
                        ids.remove(at: index)
                    }
                }
                plistTags[key] = ids
            }
        }
        tags.forEach { tag in
            var docIds = Set(plistTags[tag] ?? [])
            docIds.insert(documentUUID)
            plistTags[tag] = Array(docIds)
            if let tagItem = FTTagsProvider.shared.getTagItemFor(tagName: tag) {
                tagItem.updateDocumentIds(docIds: Array(docIds))
                FTTagsProvider.shared.addNewTagItemIfNeeded(tagItem: tagItem)
            }
        }
        // Remove Empty tags
        plistTags.forEach { (key, value) in
            if value.isEmpty, let index = plistTags.index(forKey: key) {
                plistTags.remove(at: index)
            }
        }
        plist.tags = plistTags;
        return (true,refreshTagsView);
    }
    
    private var lock = NSRecursiveLock();
    private func saveTagsInfo(_ plistTags: [String:[String]]) {
        self.lock.lock();
        defer {
            self.lock.unlock();
        }
        let destinationURL = cachedPageTagsLocation()
        do {
            let data1 = try JSONEncoder().encode(plistTags)
            if let dictionary = try JSONSerialization.jsonObject(with: data1, options: .mutableContainers) as? NSDictionary {
                dictionary.write(toFile: destinationURL.path, atomically: false)
            }
        } catch {
            cacheLog(.error, error)
        }
    }
    
    private func readTagsInfo() -> FTCacheTagsPlist? {
        self.lock.lock();
        defer {
            self.lock.unlock();
        }
        let destinationURL = cachedPageTagsLocation()
        if fileManager.fileExists(atPath: destinationURL.path) {
            do {
                let data = try Data(contentsOf: destinationURL)
                let decoder = PropertyListDecoder()
                let cacheTagsPlist = try decoder.decode(FTCacheTagsPlist.self, from: data)
                return cacheTagsPlist
            }
            catch {
                cacheLog(.error, error)
            }
        }
        return nil;
    }
    
    func removeTagsFor(documentUUID: String) {
        FTTagsProvider.shared.removeDocumentId(docId: documentUUID)

        if let cachedTagsPlist = readTagsInfo() {
            var plistTags = cachedTagsPlist.tags
            for key in plistTags.keys {
                if var ids = plistTags[key] {
                    for (index, docId) in ids.enumerated() {
                        if documentUUID == docId {
                            ids.remove(at: index)
                        }
                    }
                    plistTags[key] = ids
                }
            }
            // Remove Empty tags
            plistTags.forEach { (key, value) in
                if value.isEmpty, let index = plistTags.index(forKey: key) {
                    plistTags.remove(at: index)
                }
            }
            saveTagsInfo(plistTags)
            runInMainThread {
                FTTagsProvider.shared.getAllTags(forceUpdate: true)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshSideMenu"), object: nil)
            }
        }
    }

    func cacheTagsForDocument(items: [FTItemToCache]) {
        if !items.isEmpty,let cachePlist = self.readTagsInfo() {
            var shouldRefreshSideMenu = false;
            var shouldRefreshShelfTag = false;
            
            items.forEach { eachItem in
                    self.cachedDocumentPlistFor(documentUUID: eachItem.documentID) { documentPlist, error in
                        if documentPlist != nil, let documentPlist {
                            let docTags = self.documentTagsFor(documentUUID: eachItem.documentID)
                            let pages = NSSet(set: Set.init((documentPlist.pages)))
                            let pagesTags = self.tagsFor(pages)
                            let tags = Array(Set.init(docTags + pagesTags))
                            let filteredTags = tags.filter { $0.count > 0 }
                            let result = self.cacheTagsIntoPlist(filteredTags, for: eachItem.documentID,tagsplist: cachePlist)
                            shouldRefreshSideMenu = shouldRefreshSideMenu || result.refreshSideMenu;
                            shouldRefreshShelfTag = shouldRefreshShelfTag || result.refreshShelf;
                        }
                    }
            }
            
            self.saveTagsInfo(cachePlist.tags);
                if shouldRefreshShelfTag || shouldRefreshSideMenu {
                    runInMainThread {
                        if shouldRefreshSideMenu {
                            FTTagsProvider.shared.getAllTags(forceUpdate: true)
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshSideMenu"), object: nil)
                        }
                        if shouldRefreshShelfTag {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshShelfTags"), object: nil)
                        }
                    }
                }
        }
    }

}

extension FTCacheTagsProcessor {

    func documentTagsFor(documentUUID: String?) -> [String] {
        if let docUUID = documentUUID {
            let destinationURL = FTDocumentCache.shared.cachedLocation(for: docUUID)
            let dest = destinationURL.appendingPathComponent(FTCacheFiles.cachePropertyPlist)
            let propertiList = FTFileItemPlist(url: dest, isDirectory: false)
            if let docTags = propertiList?.object(forKey: "tags") as? [String] {
                return Array(Set.init(docTags))
            }
        }
        return []
    }

    func tagsFor(_ pages: NSSet) -> [String] {
        var pageTags: [String] = [String]()
        if (!pages.allObjects.isEmpty) {
            pageTags = self.insersectedPagesTags(pages: pages)
        }
        let sortedArray = pageTags.sorted(by: { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending })
        return sortedArray
    }

    func commonTagsFor(pages: NSSet) -> [String] {
        var commonTags: Set<String> = []
        for (index, pickedPage) in pages.enumerated() {
            if let page = pickedPage as? FTCachedDocumentPage {
                commonTags = index == 0 ? Set.init(page.tags.map{$0}) : commonTags.intersection(Set.init(page.tags.map{$0}))
            } else if let page = pickedPage as? FTPageTagsProtocol {
                commonTags = index == 0 ? Set.init(page.tags().map{$0}) : commonTags.intersection(Set.init(page.tags().map{$0}))
            }
        }
        return Array(commonTags)
    }


    func tagsModelForTags(tags: [String]) -> [FTTagModel] {
        var selectedTagsList: [FTTagModel] = []
        let allTags = cachedTags()
        allTags.forEach { tag in
            let tagItem = FTTagModel(text: tag)
            tagItem.isSelected = tags.contains(tag);
            selectedTagsList.append(tagItem)
        }
        let sortedArray = selectedTagsList.sorted(by: { $0.text.localizedCaseInsensitiveCompare($1.text) == .orderedAscending })
        return sortedArray
    }

    private func insersectedPagesTags(pages: NSSet) -> [String] {
        var pagesTags: [String] = []
        pages.forEach { pickedPage in
            if let page = pickedPage as? FTCachedDocumentPage {
                pagesTags += page.tags
            } else if let page = pickedPage as? FTPageTagsProtocol {
                pagesTags += page.tags()
            }
        }
        let tags = Set(pagesTags)
        return Array(tags)
    }

}
