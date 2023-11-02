//
//  FTDocumentCache.swift
//  Noteshelf
//
//  Created by Akshay on 19/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

/* Steps:
 These tasks should be on low priority and should not interrupt the user at any point.
 1. Build the Cache for the documents.
 2. Pre-Process the images and store the low resolution images which are suitable for thumbnails.
 3. Copy the Audio recordings and link them with the root document.
 4. Invalidate the cache and rebuild on the save of the document.
 */

enum FTCacheError: Error {
    case invalidPath
    case corruptedDocument
    case documentNotDownloaded
    case fileNotExists
    case cachingNotRequired
    case documentIsStillOpen
}
#if DEBUG
private let cleanOnNextLaunch: Bool = false
#endif

struct FTCacheFiles {
    static let cacheFolderName: String = "com.noteshelf.cache"
    static let cacheTagsPlist: String = "cacheTags.plist"
    static let cacheDocumentPlist: String = "Document.plist"
    static let cachePropertyPlist: String = "Metadata/Properties.plist"
}

 class FTItemToCache {
    var fileUrl: URL;
    var documentID : String;
    init(url: URL, documentID docID: String) {
        fileUrl = url;
        documentID = docID;
    }
}

final class FTDocumentCache {
    private let lock = NSRecursiveLock();
    
    static let shared = FTDocumentCache()
    let cacheFolderURL: URL

    private var itemsToCache = [FTItemToCache]();
    private var cacheDisabled = false;

    // MARK: Private
    private let queue = DispatchQueue(label: FTCacheFiles.cacheFolderName, qos: .utility)
    private init() {
        guard let cacheFolder = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last else {
            fatalError("Unable to find cache directory")
        }
        cacheFolderURL = Foundation.URL(fileURLWithPath: cacheFolder).appendingPathComponent(FTCacheFiles.cacheFolderName)
    }

    func start() {
        createCachesDirectoryIfNeeded()
        cacheLog(.info, cacheFolderURL)

        addObservers()
    }

    func stop() {
        removeObservers()
    }

    private func createCachesDirectoryIfNeeded() {
        let _fileManager = FileManager()
#if DEBUG
        if cleanOnNextLaunch, _fileManager.fileExists(atPath: cacheFolderURL.path) {
            do {
                try _fileManager.removeItem(at: cacheFolderURL)
            } catch {
                cacheLog(.error, error)
            }
        }
#endif
        if !_fileManager.fileExists(atPath: cacheFolderURL.path) {
            do {
                try _fileManager.createDirectory(at: cacheFolderURL, withIntermediateDirectories: true)
            } catch {
                cacheLog(.error, error)
            }
        }
    }

    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(shelfitemDidUpdate(_:)), name: .shelfItemAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shelfItemDidRemove(_:)), name: .shelfItemRemoved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shelfitemDidUpdate(_:)), name: .shelfItemUpdated, object: nil)
    }

    private func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .shelfItemAdded, object: nil)
        NotificationCenter.default.removeObserver(self, name: .shelfItemUpdated, object: nil)
        NotificationCenter.default.removeObserver(self, name: .shelfItemRemoved, object: nil)
    }

    @objc func shelfItemDidRemove(_ notification: Notification) {
        guard let shelfItemCollection = notification.object as? FTShelfItemCollection else {
            return
        }

        // Ignore the items which are updated in Trash
        if shelfItemCollection is FTShelfItemCollectionSystem {
            return
        }

        guard !shelfItemCollection.isNS2Collection() else {
            return
        }

        guard let items = notification.userInfo?["items"] as? [FTDocumentItemProtocol] else { return }
        cacheLog(.info, "shelfItemDidRemove", items.count)

        // Perform all the operations on the secondary thread. This should never block the user interaction
        queue.async {
            do {
                try self.removeCacheDocumentIfRequired(items)
            } catch {
            }
        }
    }

    @objc func shelfitemDidUpdate(_ notification: Notification) {
        guard let shelfItemCollection = notification.object as? FTShelfItemCollection else {
            return
        }

        // Ignore the items which are updated in Trash
        if shelfItemCollection is FTShelfItemCollectionSystem {
            return
        }

        guard !shelfItemCollection.isNS2Collection() else {
            return
        }

        guard let items = notification.userInfo?["items"] as? [FTDocumentItemProtocol] else { return }
        cacheLog(.info, "shelfitemDidUpdate", items.count)
        var cacheItems = [FTItemToCache]()
        items.forEach { item in
            if let docId = item.documentUUID {
                cacheItems.append(FTItemToCache(url: item.URL, documentID: docId))
            }
        }

        self.cacheShelfItems(items: cacheItems)
    }
}

// Interface for cache creation
extension FTDocumentCache {
    func disableCacheUpdates() {
        self.cacheDisabled = true;
    }

    func enableCacheUpdates() {
        self.cacheDisabled = false;
        runInMainThread(0.1) {
            self.lock.lock()
            self.itemsToCache.forEach { eachItem in
                self.cacheShelfItemFor(url: eachItem.fileUrl, documentUUID: eachItem.documentID);
            }
            self.itemsToCache.removeAll();
            self.lock.unlock()
        }
    }

    func cachedLocation(for docUUID: String) -> URL {
        guard NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last != nil else {
            fatalError("Unable to find cache directory")
        }
        let destinationURL = cacheFolderURL.appendingPathComponent(docUUID).appendingPathExtension(FTFileExtension.ns3)
        return destinationURL
    }

    func cacheShelfItems(items: [FTItemToCache]) {

        if self.cacheDisabled {
            self.lock.lock()
            items.forEach { eachItem in
                self.itemsToCache.append(FTItemToCache(url: eachItem.fileUrl, documentID: eachItem.documentID))
            }
            self.lock.unlock()
            return;
        }

        let dispatchGroup = DispatchGroup()
        queue.async {
            var itemsCached = [FTItemToCache]();
            items.forEach { eachItem in
                dispatchGroup.enter()
                    do {
                        try self.cacheShelfItemIfRequired(url: eachItem.fileUrl, documentUUID: eachItem.documentID )
                        itemsCached.append(eachItem)
                        dispatchGroup.leave()
                    } catch {
                        cacheLog(.error, error.localizedDescription, eachItem.fileUrl.lastPathComponent)
                        dispatchGroup.leave()
                    }
            }
            dispatchGroup.notify(queue: self.queue) {
                if itemsCached.count > 0 {
                    FTCacheTagsProcessor.shared.cacheTagsForDocuments(items: itemsCached)
                    FTBookmarksProvider.shared.updateBookmarkItemsFor(cacheItems: itemsCached)
                }
            }
        }
    }

    func cacheShelfItemFor(url: URL, documentUUID: String) {
        if self.cacheDisabled {
            self.lock.lock()
            self.itemsToCache.append(FTItemToCache(url: url, documentID: documentUUID))
            self.lock.unlock()
            return;
        }

        queue.async {
            do {
                try self.cacheShelfItemIfRequired(url: url, documentUUID: documentUUID)
                let itemToCache = FTItemToCache(url: url, documentID: documentUUID)
                FTCacheTagsProcessor.shared.cacheTagsForDocuments(items: [itemToCache])
                FTBookmarksProvider.shared.updateBookmarkItemsFor(cacheItems: [itemToCache])
            } catch {
                cacheLog(.error, error.localizedDescription, url.lastPathComponent)
            }
        }
    }

    private func relativePathWRTCollectionFor(documentId: String) -> String? {
        let destinationURL = cachedLocation(for: documentId)
        let dest = destinationURL.appendingPathComponent(FTCacheFiles.cachePropertyPlist)
        if let propertiList = FTFileItemPlist(url: dest, isDirectory: false), let relativePath = propertiList.object(forKey: "relativePath") as? String {
            return relativePath
        }
        return nil
    }
}

private extension FTDocumentCache {
    func cacheShelfItemIfRequired(url: URL, documentUUID: String) throws {

        func updateMetadataPlistWithRelativePathFor(docUrl: URL, documentId: String) {
            let destinationURL = cachedLocation(for: documentId)
            let dest = destinationURL.appendingPathComponent(FTCacheFiles.cachePropertyPlist)
            if let propertiList = FTFileItemPlist(url: dest, isDirectory: false) {
                let relativePath = docUrl.relativePathWRTCollection()
                propertiList.setObject(relativePath, forKey: "relativePath")
                try? propertiList.writeUpdates(to: dest)
            }
        }

        // Ignore the documents which are already open
        guard !FTNoteshelfDocumentManager.shared.isDocumentAlreadyOpen(for: url) else {
            updateMetadataPlistWithRelativePathFor(docUrl: url, documentId: documentUUID)
            cacheLog(.info, "Replace Ignored as already opened \(url.lastPathComponent)")
            throw FTCacheError.documentIsStillOpen
        }

        let destinationURL = cachedLocation(for: documentUUID)
        let _fileManager = FileManager();
        if !_fileManager.fileExists(atPath: destinationURL.path) {
            do {
                // Copy directly if the file doesn't exist at the cache location
                try _fileManager.coordinatedCopy(fromURL: url, toURL: destinationURL, force: false)
                updateMetadataPlistWithRelativePathFor(docUrl: url, documentId: documentUUID)
                cacheLog(.success, "Copy", url.lastPathComponent)
            } catch {
                cacheLog(.error, "Copy", error.localizedDescription, url.lastPathComponent)
                throw error
            }
        } else {
            // Check for the latet modification dates at the cache location
            let existingmodified = destinationURL.fileModificationDate
            let newModified = url.fileModificationDate

            // Can be improved by checking for .orderedAscending/orderedDescending, for now we're just replacing the existing cache if the modification dates mismatches.
            let isLatestModified = existingmodified.compare(newModified) == .orderedAscending
            cacheLog(.info, " \(isLatestModified) existing: \(existingmodified) new: \(newModified)", url)

            if isLatestModified {
                do {
                    try _fileManager.coordinatedCopy(fromURL: url, toURL: destinationURL, force: true)
                    updateMetadataPlistWithRelativePathFor(docUrl: url, documentId: documentUUID)
                    cacheLog(.success, "Replace", url.lastPathComponent)
                } catch {
                    cacheLog(.error, "Replace", error.localizedDescription, url.lastPathComponent)
                    throw error
                }
            } else {
                updateMetadataPlistWithRelativePathFor(docUrl: url, documentId: documentUUID)
                cacheLog(.info, "Replace Ignored as there are no modifications", url.lastPathComponent)
                throw FTCacheError.cachingNotRequired
            }
        }
    }

    func removeCacheDocumentIfRequired(_ documents: [FTDocumentItemProtocol]) throws {
        for case let doc in documents where doc.documentUUID != nil {
            guard let docUUID = doc.documentUUID, doc.isDownloaded else { continue }

            let destinationURL = cachedLocation(for: docUUID)
            let relativePath = self.relativePathWRTCollectionFor(documentId: docUUID)
            let _fileManger = FileManager();
            if _fileManger.fileExists(atPath: destinationURL.path) && (doc.URL.relativePathWRTCollection() == relativePath || relativePath == nil){
                do {
                    FTCacheTagsProcessor.shared.removeTagsFor(documentUUID: docUUID)
                    FTBookmarksProvider.shared.removeBookmarkFor(documentId: docUUID)
                    try _fileManger.removeItem(at: destinationURL)
                    cacheLog(.success, "Remove", doc.URL.lastPathComponent)
                } catch {
                    cacheLog(.error, "Remove", doc.URL.lastPathComponent)
                }
            }
        }
    }

}
