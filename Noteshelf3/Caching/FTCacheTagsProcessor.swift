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
                        allTags.append(FTTagItemModel(tag: FTTagModel(text: tagName), documentIds: ids))
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
            do {
                let data1 = try JSONEncoder().encode(plistTags)
                if let dictionary = try JSONSerialization.jsonObject(with: data1, options: .mutableContainers) as? NSDictionary {
                    dictionary.write(toFile: destinationURL.path, atomically: false)
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
                self.cacheTagsIntoPlist(tags, for: documentUUID)
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

    func renameTagInPlist(_ tag: FTTagModel, with newTag: FTTagModel) {
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
            } catch {
                
            }
        }
    }

    func renameTag(_ tag: FTTagModel, with newTag: FTTagModel, for document: FTNoteshelfDocument) {
       let doc = document
       var isOpen = false
           isOpen =  doc.documentState == .normal
           if !isOpen {
                doc.openDocument(purpose: FTDocumentOpenPurpose.write, completionHandler: { success, error in
                    if success {
                        doc.renameTag(tag.text, with: newTag.text)
                        doc.saveAndCloseWithCompletionHandler { _ in
                            FTDocumentCache.shared.cacheShelfItemFor(url: doc.URL, documentUUID: doc.documentUUID)
                        }
                    }
               })
           } else {
                doc.renameTag(tag.text, with: newTag.text)
               doc.save { _ in
                   FTDocumentCache.shared.cacheShelfItemFor(url: doc.URL, documentUUID: doc.documentUUID)
               }
           }
   }

    func deleteTags(tags: [FTTagModel], for document: FTNoteshelfDocument) {
        let doc = document
        var isOpen = false
        isOpen =  doc.documentState == .normal
        if !isOpen {
            doc.openDocument(purpose: FTDocumentOpenPurpose.write) { success, error in
                if success {
                    doc.deleteTags(tags.map {$0.text})
                    doc.saveAndCloseWithCompletionHandler { _ in
                        FTDocumentCache.shared.cacheShelfItemFor(url: doc.URL, documentUUID: doc.documentUUID)
                    }
                }
            }
        } else {
            doc.deleteTags(tags.map {$0.text})
            doc.save { _ in
                FTDocumentCache.shared.cacheShelfItemFor(url: doc.URL, documentUUID: doc.documentUUID)
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
