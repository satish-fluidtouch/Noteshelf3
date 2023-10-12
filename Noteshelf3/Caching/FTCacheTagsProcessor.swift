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
            let dic: [String: [String]] = [String :[String]]()
            // Swift Dictionary To Data.
            do  {
                let data = try PropertyListSerialization.data(fromPropertyList: dic, format: PropertyListSerialization.PropertyListFormat.binary, options: 0)
                do {
                    try data.write(to: cachedTagsPlistURL, options: .atomic)
                    print("Successfully write")
                }catch (let error){
                    cacheLog(.error, error)
                }
            }catch (let error){
                cacheLog(.error, error)
            }
        }
        cacheLog(.info, cachedPageTagsLocation())
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
        let destinationURL = cachedPageTagsLocation()
        if fileManager.fileExists(atPath: destinationURL.path) {
            do {
                let data = try Data(contentsOf: destinationURL)
                let decoder = PropertyListDecoder()
                let cacheTagsPlist = try decoder.decode(FTCacheTagsPlist.self, from: data)
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
            } catch {
                return []
            }
        }
        return []
    }

    func cachedTags() -> [String] {
        let destinationURL = cachedPageTagsLocation()
        if fileManager.fileExists(atPath: destinationURL.path) {
            do {
                let data = try Data(contentsOf: destinationURL)
                let decoder = PropertyListDecoder()
                let cacheTagsPlist = try decoder.decode(FTCacheTagsPlist.self, from: data)
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
            } catch {
                return []
            }
        }
        return []
    }

    func cachedDocumentPlistFor(documentUUID: String, completion: @escaping (FTDocumentPlist?, Error?) -> Void) {
        let cachedLocation = FTDocumentCache.shared.cachedLocation(for: documentUUID)
        let destinationURL = cachedLocation.appendingPathComponent(FTCacheFiles.documentPlist)
        if fileManager.fileExists(atPath: destinationURL.path) {
            do {
                let data = try Data(contentsOf: destinationURL)
                let decoder = PropertyListDecoder()
                let documentPlist = try decoder.decode(FTDocumentPlist
                    .self, from: data)
                completion(documentPlist, nil)
            } catch let error {
                completion(nil, error)
            }
        } else {
            completion(nil, FTCacheError.fileNotExists)
        }
    }

    private func cachedTagsPlist() -> FTCacheTagsPlist? {
        let destinationURL = cachedPageTagsLocation()
        if fileManager.fileExists(atPath: destinationURL.path) {
            do {
                let data = try Data(contentsOf: destinationURL)
                let decoder = PropertyListDecoder()
                let cachedTagsPlist = try decoder.decode(FTCacheTagsPlist.self, from: data)
                return cachedTagsPlist
            } catch let error {
                cacheLog(.error, error.localizedDescription)
            }
        }
        return nil
    }

    private func cacheTagsIntoPlist(_ tags: [String], for documentUUID: String) {
        if let cachedTagsPlist = cachedTagsPlist() {
            let destinationURL = cachedPageTagsLocation()
            var plistTags = cachedTagsPlist.tags
            FTTagsProvider.shared.removeDocumentId(docId: documentUUID)

            var refreshTagsView = false
            if !Set(tags).isSubset(of: plistTags.keys) {
                refreshTagsView = true
            }
            tags.forEach { tag in
                var docIds = Set(plistTags[tag] ?? [])
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
            var tagRemoved = false
            plistTags.forEach { (key, value) in
                if value.isEmpty, let index = plistTags.index(forKey: key) {
                    plistTags.remove(at: index)
                    tagRemoved = true
                }
            }
            do {
                let data1 = try JSONEncoder().encode(plistTags)
                if let dictionary = try JSONSerialization.jsonObject(with: data1, options: .mutableContainers) as? NSDictionary {
                    dictionary.write(toFile: destinationURL.path, atomically: false)
                    if tagRemoved {
                        runInMainThread {
                            FTTagsProvider.shared.getAllTags(forceUpdate: true)
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshSideMenu"), object: nil)
                        }
                    }
                    if refreshTagsView {
                        runInMainThread {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshShelfTags"), object: nil)
                        }
                    }
                }
            } catch {

            }
        }
    }

    func removeTagsFor(documentUUID: String) {
        FTTagsProvider.shared.removeDocumentId(docId: documentUUID)

        if let cachedTagsPlist = cachedTagsPlist() {
            let destinationURL = cachedPageTagsLocation()
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
            do {
                let data1 = try JSONEncoder().encode(plistTags)
                if let dictionary = try JSONSerialization.jsonObject(with: data1, options: .mutableContainers) as? NSDictionary {
                    dictionary.write(toFile: destinationURL.path, atomically: false)
                        runInMainThread {
                            FTTagsProvider.shared.getAllTags(forceUpdate: true)
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshSideMenu"), object: nil)
                        }
                }
            } catch {

            }

        }
    }


    // Cache tags from Cache Document and Document pages
    func cacheTagsForDocument(url: URL, documentUUID: String) {
        self.cachedDocumentPlistFor(documentUUID: documentUUID, completion: { documentPlist, error in
            if documentPlist != nil, let documentPlist {
                let docTags = self.documentTagsFor(documentUUID: documentUUID)
                let pages = NSSet(set: Set.init((documentPlist.pages)))
                let pagesTags = self.tagsFor(pages)
                let tags = Array(Set.init(docTags + pagesTags))
                let filteredTags = tags.filter { $0.count > 0 }
                self.cacheTagsIntoPlist(filteredTags, for: documentUUID)
            }
        })
    }

    func deletTags(tags: [FTTagModel]) {
        let destinationURL = cachedPageTagsLocation()

        if let cacheTagsPlist = self.cachedTagsPlist() {
            var plistTags = cacheTagsPlist.tags
            for tag in tags {
                if let index = plistTags.index(forKey: tag.text) {
                    plistTags.remove(at: index)
                }
            }
            do {
                let data1 = try JSONEncoder().encode(plistTags)
                if let dictionary = try JSONSerialization.jsonObject(with: data1, options: .mutableContainers) as? NSDictionary {
                    dictionary.write(toFile: destinationURL.path, atomically: false)
                }
            } catch {

            }
        }
    }

    func renameTagInPlist(_ tag: String, with newTag: String) {
        let destinationURL = cachedPageTagsLocation()
        if let cacheTagsPlist = self.cachedTagsPlist() {
            do {
                var plistTags = cacheTagsPlist.tags
                if let docIds = plistTags[tag] {
                    plistTags.removeValue(forKey: tag)
                    plistTags[newTag] = docIds
                    
                    let data1 = try JSONEncoder().encode(plistTags)
                    if let dictionary = try JSONSerialization.jsonObject(with: data1, options: .mutableContainers) as? NSDictionary {
                        dictionary.write(toFile: destinationURL.path, atomically: false)
                    }
                }
            } catch {
                
            }
        }
    }
}

extension FTCacheTagsProcessor {

    func documentTagsFor(documentUUID: String?) -> [String] {
        if let docUUID = documentUUID {
            let destinationURL = FTDocumentCache.shared.cachedLocation(for: docUUID)
            let dest = destinationURL.appendingPathComponent("Metadata/Properties").appendingPathExtension("plist")
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
            if let page = pickedPage as? FTDocumentPage {
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
            if let page = pickedPage as? FTDocumentPage {
                pagesTags += page.tags
            } else if let page = pickedPage as? FTPageTagsProtocol {
                pagesTags += page.tags()
            }
        }
        let tags = Set(pagesTags)
                return Array(tags)
    }

}
