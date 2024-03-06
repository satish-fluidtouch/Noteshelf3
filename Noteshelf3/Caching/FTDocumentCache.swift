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
    case pinEnabledDocument
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
    private (set) lazy var imageResourceCache: FTImageResourceCacheHandler = {
        return FTImageResourceCacheHandler();
    }();
        
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
        self.configure();
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

    func checkIfCachedDocumentIsAvailableOrNot(url: URL) -> Bool {
        let fileManager = FileManager()
        var status = false
        if fileManager.fileExists(atPath: url.path) {
            status = true
        }
        return status
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

private var useNewApproach = true;

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
        let destinationURL = cachedLocation(for: documentUUID)

        guard !url.isPinEnabledForDocument() else {
            // Cleanup the PIN enabled documents, if they have copied in earlier versions prior to v1.3.
            try? FileManager.default.removeItem(at: destinationURL)
            throw FTCacheError.pinEnabledDocument
        }

        // Ignore the documents which are already open
        guard !FTNoteshelfDocumentManager.shared.isDocumentAlreadyOpen(for: url) else {
            updateMetadataPlistWithRelativePathFor(docUrl: url, documentId: documentUUID)
            cacheLog(.info, "Replace Ignored as already opened \(url.lastPathComponent)")
            throw FTCacheError.documentIsStillOpen
        }

        if let document = FTDocumentFactory.documentForItemAtURL(url) as? FTCacheableDocument
            {
            document.generateCache(documentID: documentUUID, cacheLocation: URL.cacheLocation)
        }
        
        let _fileManager = FileManager();
        if !_fileManager.fileExists(atPath: destinationURL.path) {
            do {
                // Copy directly if the file doesn't exist at the cache location
                try FTFileCacheManager.cacheDocumentAt(url, destination: destinationURL);
//                try _fileManager.coordinatedCopy(fromURL: url, toURL: destinationURL, force: false)
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
                    try FTFileCacheManager.cacheDocumentAt(url, destination: destinationURL);
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

            self.deleteCache(docUUID, cacheLocation: URL.cacheLocation);

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

extension URL {
    static var cacheLocation: URL {
       guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
           fatalError("Pth not found");
       }
       let cacheURL = URL(filePath: path).appending(path: "Testing");
       if !FileManager().fileExists(atPath: cacheURL.path(percentEncoded: false)) {
           do {
               try FileManager().createDirectory(at: cacheURL, withIntermediateDirectories: true);
           }
           catch  {
               fatalError(error.localizedDescription)
           }
       }
       return cacheURL;
   }
}

extension FTDocumentCache {
    private func configure() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.appWillEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc private func appWillEnterForeground(_ notiifcation: Notification) {
        self.clearUnusedCacheItems();
    }
    
    private var cacheValidationExpiryTime: TimeInterval {
#if DEBUG
        return 60 * 60;
#else
        return 60 * 60 * 24;
#endif
    }
    
    private var cacheExpiryTime: TimeInterval {
#if DEBUG
        return 60 * 60 * 24;
#else
        return 60 * 60 * 24 * 30
#endif
    }
    
    private func deleteCache(_ documentID: String,cacheLocation: URL) {
        let coordinator = NSFileCoordinator()
        var error: NSError?
        let cacheDocumentURL = cacheLocation.appending(path: documentID).appendingPathExtension(FTFileExtension.ns3);

        coordinator.coordinate(writingItemAt: cacheDocumentURL, options: .forDeleting, error: &error) { writingURL in
            do {
                try FileManager().removeItem(at: writingURL);
            }
            catch {
                debugLog("cache: failed to delete: \(error.localizedDescription)")
            }
        }
    }
    
    private func clearUnusedCacheItems() {
        guard FTNoteshelfDocumentProvider.shared.isProviderReady else {
            return;
        }
        let val = UserDefaults.standard.double(forKey: "lastValidationTime")
        let currentVal = Date().timeIntervalSinceReferenceDate;
        guard currentVal - val > self.cacheValidationExpiryTime else {
            return;
        }
        UserDefaults.standard.set(currentVal, forKey: "lastValidationTime");
        
        FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection.shelfItems(.none, parent: nil, searchKey: nil) { items in
            DispatchQueue.global().async {
                let ids = items.compactMap { eachitem in
                    if let docItem = eachitem as? FTDocumentItemProtocol, docItem.isDownloaded, let docID = docItem.documentUUID {
                        return docID;
                    }
                    return nil;
                }
                
                do {
                    let paths = try FileManager().contentsOfDirectory(at: URL.cacheLocation, includingPropertiesForKeys: nil, options: .producesRelativePathURLs)
                    paths.forEach({ eachItem in
                        let item = eachItem.relativePath.deletingPathExtension;
                        if !ids.contains(item), Date().timeIntervalSinceReferenceDate - eachItem.fileModificationDate.timeIntervalSinceReferenceDate > self.cacheExpiryTime {
                            self.deleteCache(item, cacheLocation: URL.cacheLocation);
                        }
                    })
                }
                catch {
                    debugLog("Cache: Failed to verify error: \(error.localizedDescription)")
                }
            }
        }
    }
}
