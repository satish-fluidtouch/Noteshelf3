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
    private let queue = DispatchQueue(label: FTCacheFiles.cacheTagsPlist, qos: .utility)
    static let shared = FTCacheTagsProcessor()
    private let fileManager = FileManager()
    let cacheFolderURL = FTDocumentCache.shared.cacheFolderURL

    private func cachedPageTagsLocation() -> URL {
        guard NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last != nil else {
            fatalError("Unable to find cache directory")
        }
        let cachedTagsPlistURL = cacheFolderURL.appendingPathComponent(FTCacheFiles.cacheTagsPlist)
        return cachedTagsPlistURL
    }

    func createCacheTagsPlistIfNeeded() {
        let cachedTagsPlistURL = self.cacheFolderURL.appendingPathComponent(FTCacheFiles.cacheTagsPlist)
        queue.async {
            if self.fileManager.fileExists(atPath: cachedTagsPlistURL.path) {
                self.readTagsInfo { [weak self] tagsPlist in
                    guard let self = self else {
                        return
                    }
                    // Plist is exists and if its corrept re creating it
                    if tagsPlist == nil {
                        self.createTagsPlist()
                        self.loadTagsFromDocuments()
                    }
                }
            } else {
                self.createTagsPlist()
                self.loadTagsFromDocuments()
            }
        }
        FTTagsProvider.shared.updateTags()
        cacheLog(.info, self.cachedPageTagsLocation())
    }

    private func loadTagsFromDocuments() {
        let dispatchGroup = DispatchGroup()
        var itemsToCahe = [FTItemToCache]()
        FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection.shelfItems(FTShelfSortOrder.none, parent: nil, searchKey: nil) { [weak self] allItems in
            guard let self = self else {return}
            self.queue.async {
                let items: [FTDocumentItemProtocol] = allItems.compactMap({ $0 as? FTDocumentItemProtocol }).filter({ $0.isDownloaded })
                for item in items {
                    dispatchGroup.enter()
                    if let docId = item.documentUUID {
                        let destinationURL = FTDocumentCache.shared.cachedLocation(for: docId)
                        itemsToCahe.append(FTItemToCache(url: destinationURL, documentID: docId))
                    }
                    dispatchGroup.leave()
                }
                dispatchGroup.notify(queue: self.queue) {
                    self.cacheTagsForDocuments(items: itemsToCahe)
                }
            }
        }
    }

    private func createTagsPlist() {
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

    private func saveTagsInfo(_ plistTags: [String:[String]]) {
        let destinationURL = self.cachedPageTagsLocation()
        do {
            let data1 = try JSONEncoder().encode(plistTags)
            if let dictionary = try JSONSerialization.jsonObject(with: data1, options: .mutableContainers) as? NSDictionary {
                dictionary.write(toFile: destinationURL.path, atomically: false)
            }
        } catch {
            cacheLog(.error, error)
        }
    }

    private func readTagsInfo(completion: @escaping (FTCacheTagsPlist?) -> Void) {
        let destinationURL = cachedPageTagsLocation()
        queue.async {
            if self.fileManager.fileExists(atPath: destinationURL.path) {
                do {
                    let data = try Data(contentsOf: destinationURL)
                    let decoder = PropertyListDecoder()
                    let cacheTagsPlist = try decoder.decode(FTCacheTagsPlist.self, from: data)
                    completion(cacheTagsPlist)
                }
                catch {
                    completion(nil)
                    cacheLog(.error, error)
                }
            } else {
                completion(nil)
            }
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
                ids.removeAll(where: { documentUUID == $0 })
                plistTags[key] = ids
            }
        }
        tags.forEach { tag in
            var docIds = Set(plistTags[tag] ?? [])
            docIds.insert(documentUUID)
            plistTags[tag] = Array(docIds)
            if let tagItem = FTTagsProvider.shared.getTagItemFor(tagName: tag) {
                tagItem.setDocumentIds(docIds: Array(docIds))
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

    func tagsPlist(completion: @escaping (NSMutableDictionary) -> Void) {
        self.readTagsInfo { cacheTagsPlist in
            if let plist = cacheTagsPlist {
                let plistTags = NSMutableDictionary(dictionary: plist.tags)
                completion(plistTags)
            } else {
                completion([:])
            }
        }
    }

    func cachedDocumentPlistFor(documentUUID: String, completion: @escaping (FTCachedDocumentPlist?) -> Void) {
        let cachedLocation = FTDocumentCache.shared.cachedLocation(for: documentUUID)
        let destinationURL = cachedLocation.appendingPathComponent(FTCacheFiles.cacheDocumentPlist)
        queue.async {
            if self.fileManager.fileExists(atPath: destinationURL.path) {
                do {
                    let data = try Data(contentsOf: destinationURL)
                    let decoder = PropertyListDecoder()
                    let documentPlist = try decoder.decode(FTCachedDocumentPlist
                        .self, from: data)
                    completion(documentPlist)
                } catch {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }

    func removeTagsFor(documentUUID: String) {
        FTTagsProvider.shared.removeDocumentId(docId: documentUUID)
        readTagsInfo {[weak self] cachedTagsPlist in
            guard let self = self else {
                return
            }
            if let cachedTagsPlist {
                var plistTags = cachedTagsPlist.tags
                for key in plistTags.keys {
                    if var ids = plistTags[key] {
                        ids.removeAll(where: { documentUUID == $0 })
                        plistTags[key] = ids
                    }
                }
                // Remove Empty tags
                plistTags.forEach { (key, value) in
                    if value.isEmpty, let index = plistTags.index(forKey: key) {
                        plistTags.remove(at: index)
                    }
                }
                self.saveTagsInfo(plistTags)
                runInMainThread {
                    FTTagsProvider.shared.updateTags()
                }
            }
        }
    }

    func cacheTagsForDocuments(items: [FTItemToCache]) {
        if !items.isEmpty {
            readTagsInfo {[weak self] cachePlist in
                guard let self = self else {
                    return
                }
                if let cachePlist {
                    var shouldRefreshSideMenu = false;
                    var shouldRefreshShelfTag = false;
                    func tagsFor(documentUUID: String, completion: @escaping ([String]) -> Void) {
                        self.cachedDocumentPlistFor(documentUUID: documentUUID) { documentPlist in
                            if documentPlist != nil, let documentPlist {
                                let docTags = self.documentTagsFor(documentUUID: documentUUID)
                                let pages = NSSet(set: Set.init((documentPlist.pages)))
                                let pagesTags = self.tagsFor(pages)
                                let tags = Array(Set.init(docTags + pagesTags))
                                let filteredTags = tags.filter { $0.count > 0 }
                                completion(filteredTags)
                            } else {
                                completion([])
                            }
                        }
                    }

                    let dispatchGroup = DispatchGroup()
                    items.forEach { eachItem in
                        dispatchGroup.enter()
                        tagsFor(documentUUID: eachItem.documentID) { tags in
                            let result = self.cacheTagsIntoPlist(tags, for: eachItem.documentID,tagsplist: cachePlist)
                            shouldRefreshSideMenu = shouldRefreshSideMenu || result.refreshSideMenu;
                            shouldRefreshShelfTag = shouldRefreshShelfTag || result.refreshShelf;
                            dispatchGroup.leave()
                        }
                    }
                    dispatchGroup.notify(queue: self.queue) {
                        // Check wheteher documentId hold in Plist for some tag and that document doesn't contain any tags remove it from Plist
                        var plistTags = cachePlist.tags
                        
                        for key in plistTags.keys {
                            if var ids = plistTags[key] {
                                for (index, docId) in ids.enumerated().reversed() {
                                    tagsFor(documentUUID: docId) { tags in
                                        if !tags.contains(key) || tags.isEmpty {
                                            ids.remove(at: index)
                                        }
                                    }
                                }
                                plistTags[key] = ids
                            }
                        }
                        cachePlist.tags = plistTags
                        self.saveTagsInfo(cachePlist.tags);
                        if shouldRefreshShelfTag || shouldRefreshSideMenu {
                            runInMainThread {
                                if shouldRefreshSideMenu {
                                    FTTagsProvider.shared.updateTags()
                                }
                                if shouldRefreshShelfTag {
                                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshShelfTags"), object: nil)
                                }
                            }
                        }
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
