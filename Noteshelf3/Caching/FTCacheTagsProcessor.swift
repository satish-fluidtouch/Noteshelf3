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

     func cachedDocumentPlistFor(documentUUID: String) throws -> FTDocumentPlist? {
        let cachedLocation = FTDocumentCache.shared.cachedLocation(for: documentUUID)
        let destinationURL = cachedLocation.appendingPathComponent(FTCacheFiles.documentPlist)
        if fileManager.fileExists(atPath: destinationURL.path) {
            do {
                let data = try Data(contentsOf: destinationURL)
                let decoder = PropertyListDecoder()
                let documentPlist = try decoder.decode(FTDocumentPlist
                    .self, from: data)
                return documentPlist
            } catch let error {
                throw error
            }
        }
        return nil
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

    private func cacheTagsIntoPlist(_ tags: [String], for documentUUID: String) throws {
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

            tags.forEach { tag in
                var docIds: [String] = [String]()
                docIds = plistTags[tag] ?? []
                docIds.append(documentUUID)
                let set = Set(docIds)
                docIds = Array(set)
                plistTags[tag] = docIds
            }
            // Remove Empty tags
            plistTags.forEach { (key, value) in
                if value.isEmpty, let index = plistTags.index(forKey: key) {
                    plistTags.remove(at: index)
                }
            }
            let data1 = try JSONEncoder().encode(plistTags)
            if let dictionary = try JSONSerialization.jsonObject(with: data1, options: .mutableContainers) as? NSDictionary {
                dictionary.write(toFile: destinationURL.path, atomically: false)
            }
        }
    }

    // Remove All tags from Plist When App Launch

    func removeAllTagsFromPlist() throws {
        if let cachedTagsPlist = cachedTagsPlist() {
            let destinationURL = cachedPageTagsLocation()
            var plistTags = cachedTagsPlist.tags
            plistTags.removeAll()
            do {
                let data1 = try JSONEncoder().encode(plistTags)
                if let dictionary = try JSONSerialization.jsonObject(with: data1, options: .mutableContainers) as? NSDictionary {
                    dictionary.write(toFile: destinationURL.path, atomically: false)
                }
            }
        }
    }

    // Cache tags from Cache Document and Document pages
    func cacheTagsForDocument(url: URL, documentUUID: String) throws {
        if let documentPlist = try self.cachedDocumentPlistFor(documentUUID: documentUUID) {
            let docTags = self.tagsForShelfItem(url: url)
            let pages = NSSet(set: Set.init((documentPlist.pages)))
            let pagesTags = self.tagsFor(pages)
            let tags = Array(Set.init(docTags + pagesTags))
            try self.cacheTagsIntoPlist(tags, for: documentUUID)
        } else {
            throw FTTagsCacheError.documentPlistNotAvailable
        }
    }

    func deletTags(tags: [FTTagModel]) async throws {
        if let cacheTagsPlist = self.cachedTagsPlist() {
            do {
                var docIdsList = Set<String>();
                for tag in tags {
                    let plistTags = cacheTagsPlist.tags
                    if let docIDs = plistTags[tag.text] {
                        docIdsList = docIdsList.union(Set(docIDs));
                    }
                }
            }
        }
    }

    func documentIdsForTag(tag: FTTagModel) -> [String] {
        if let cacheTagsPlist = self.cachedTagsPlist() {
            let plistTags = cacheTagsPlist.tags
            if tag.text.count > 0, let docIds = plistTags[tag.text] {
                return docIds
            } else {
                var docIds = [String]()
                plistTags.forEach { (key, value) in
                    docIds += value
                }
                let ids = Array(Set.init(docIds))
                return ids
            }
        }
        return []
    }

    func deletetag(tag: String, for documentUUID: String){
        if let cacheTagsPlist = self.cachedTagsPlist() {
            let plistTags = cacheTagsPlist.tags
            if var values = plistTags[tag] {
                for (index, _) in values.enumerated().reversed() {
                    if values.contains(documentUUID) {
                        values.remove(at: index)
                    }
                }
            }

        }
    }

    func tagsFor(shelfItem: FTShelfTagsItem) throws -> [String] {
        do {
            if let documentUUID = shelfItem.document?.documentUUID, let documentPlist = try self.cachedDocumentPlistFor(documentUUID: documentUUID) {
                let cacheUrl =  FTDocumentCache.shared.cachedLocation(for: documentUUID)
                let docTags = self.tagsForShelfItem(url: cacheUrl)
                if shelfItem.type == .book {
                    return docTags
                }
                let pages = NSSet(set: Set.init((documentPlist.pages)))
                if let pagesArray = pages.allObjects as? [FTDocumentPage], !pagesArray.isEmpty, let pageUUID = shelfItem.page?.uuid {
                    if let page = pagesArray.first(where: {$0.uuid == pageUUID}) {
                        let pageTags = self.tagsFor([page])
                        let tags = Array(Set.init(pageTags))
                        return tags
                    }
                }
                return []
            } else {
                throw FTTagsCacheError.documentPlistNotAvailable
            }
        }
    }


    func renameTagInPlist(_ tag: FTTagModel, with newTag: FTTagModel) async throws {
        let destinationURL = cachedPageTagsLocation()
        if let cacheTagsPlist = self.cachedTagsPlist() {
            do {
                var plistTags = cacheTagsPlist.tags
                if let docIds = plistTags[tag.text] {
                    plistTags.removeValue(forKey: tag.text)
                    plistTags[newTag.text] = docIds
                    
                    let data1 = try JSONEncoder().encode(plistTags)
                    if let dictionary = try JSONSerialization.jsonObject(with: data1, options: .mutableContainers) as? NSDictionary {
                        dictionary.write(toFile: destinationURL.path, atomically: false)
                    }
                }
            }
        }
    }

     func renameTag(_ tag: FTTagModel, with newTag: FTTagModel, for document: FTNoteshelfDocument) async throws {
        let doc = document
        var isOpen = false
        let destinationURL = await doc.URL
        do {
            isOpen = await doc.documentState == .normal
            if !isOpen {
                isOpen = try await doc.openDocument(purpose: FTDocumentOpenPurpose.write)
                await doc.renameTag(tag.text, with: newTag.text)
                _ = await doc.saveAndClose()
            } else {
                await doc.renameTag(tag.text, with: newTag.text)
                _ = await doc.save(completionHandler: nil)
            }
            try await FTDocumentCache.shared.cacheShelfItemFor(url: doc.URL, documentUUID: doc.documentUUID)
        } catch {
            cacheLog(.error, error, destinationURL.lastPathComponent)
        }
    }

    func deleteTags(tags: [FTTagModel], for document: FTNoteshelfDocument) async throws {
       let doc = document
       var isOpen = false
       let destinationURL = await doc.URL
       do {
           isOpen = await doc.documentState == .normal
           if !isOpen {
               isOpen = try await doc.openDocument(purpose: FTDocumentOpenPurpose.write)
               await doc.deleteTags(tags.map {$0.text})
               _ = await doc.saveAndClose()
           } else {
               await doc.deleteTags(tags.map {$0.text})
               _ = await doc.save(completionHandler: nil)
           }
           try await FTDocumentCache.shared.cacheShelfItemFor(url: doc.URL, documentUUID: doc.documentUUID)
       } catch {
           cacheLog(.error, error, destinationURL.lastPathComponent)
       }
   }
}

extension FTCacheTagsProcessor {

    func tagsForShelfItem(url: URL) -> [String] {
        var tagsList: [String] = []
        var docTags = [String]()
            let dest = url.appendingPathComponent("Metadata/Properties").appendingPathExtension("plist")
            let propertiList = FTFileItemPlist(url: dest, isDirectory: false)
            if let tags = propertiList?.object(forKey: "tags") as? [String] {
                docTags += tags
            }
        tagsList = Array(Set.init(docTags))
        let sortedArray = tagsList.sorted()//(by: { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending })
        return sortedArray
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
