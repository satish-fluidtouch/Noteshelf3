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
        FTTagsProvider.shared.syncTagsWithLocalCache(documentID: documentUUID);
    }

    func cacheTagsForDocuments(items: [FTItemToCache]) {
        items.forEach { eachItem in
            FTTagsProvider.shared.syncTagsWithLocalCache(documentID: eachItem.documentID);
        }
    }
}
