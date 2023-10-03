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
}
#if DEBUG
private let cleanOnNextLaunch: Bool = false
#endif

struct FTCacheFiles {
    static let cacheFolderName: String = "com.noteshelf.cache"
    static let cacheTagsPlist: String = "cacheTags.plist"
    static let documentPlist: String = "Document.plist"
}

final class FTDocumentCache {
    static let shared = FTDocumentCache()
    let cacheFolderURL: URL

    // MARK: Private
    private let fileManager = FileManager()
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

        FTCacheTagsProcessor.shared.createCacheTagsPlistIfNeeded()

        addObservers()
    }

    func stop() {
        removeObservers()
    }

    private func createCachesDirectoryIfNeeded() {
#if DEBUG
        if cleanOnNextLaunch, fileManager.fileExists(atPath: cacheFolderURL.path) {
            do {
                try fileManager.removeItem(at: cacheFolderURL)
            } catch {
                cacheLog(.error, error)
            }
        }
#endif
        if !fileManager.fileExists(atPath: cacheFolderURL.path) {
            do {
                try fileManager.createDirectory(at: cacheFolderURL, withIntermediateDirectories: true)
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

        // Perform all the operations on the secondary thread. This should never block the user interaction
        items.forEach { item in
            if let docUUID = item.documentUUID, item.isDownloaded {
                self.cacheShelfItemFor(url: item.URL, documentUUID: docUUID)
            } else {
                cacheLog(.info, "Ignoring \(item.URL.lastPathComponent)")
            }
        }
    }
}

// Interface for cache creation

extension FTDocumentCache {
    func cachedLocation(for docUUID: String) -> URL {
        guard NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last != nil else {
            fatalError("Unable to find cache directory")
        }
        let destinationURL = cacheFolderURL.appendingPathComponent(docUUID).appendingPathExtension(FTFileExtension.ns3)
        return destinationURL
    }

    func cacheShelfItemFor(url: URL, documentUUID: String) {
        queue.async {
            do {
                try self.cacheShelfItemIfRequired(url: url, documentUUID: documentUUID)
                FTCacheTagsProcessor.shared.cacheTagsForDocument(url: url, documentUUID: documentUUID)
            } catch {
                cacheLog(.error, error.localizedDescription, url.lastPathComponent)
            }
        }
    }
}

private extension FTDocumentCache {
    func cacheShelfItemIfRequired(url: URL, documentUUID: String) throws {
        // Ignore the documents which are already open
        guard !FTNoteshelfDocumentManager.shared.isDocumentAlreadyOpen(for: url) else {
            cacheLog(.info, "Replace Ignored as already opened \(url.lastPathComponent)")
            return
        }

        let destinationURL = cachedLocation(for: documentUUID)
        if !fileManager.fileExists(atPath: destinationURL.path) {
            do {
                // Copy directly if the file doesn't exist at the cache location
                try fileManager.coordinatedCopy(fromURL: url, toURL: destinationURL, force: false)
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
                    try fileManager.coordinatedCopy(fromURL: url, toURL: destinationURL, force: true)
                    cacheLog(.success, "Replace", url.lastPathComponent)
                } catch {
                    cacheLog(.error, "Replace", error.localizedDescription, url.lastPathComponent)
                    throw error
                }
            } else {
                cacheLog(.info, "Replace Ignored as there are no modifications", url.lastPathComponent)
            }
        }
    }

    func removeCacheDocumentIfRequired(_ documents: [FTDocumentItemProtocol]) throws {
        for case let doc in documents where doc.documentUUID != nil {
            guard let docUUID = doc.documentUUID, doc.isDownloaded else { continue }

            let destinationURL = cachedLocation(for: docUUID)
            if fileManager.fileExists(atPath: destinationURL.path) {
                do {
                    FTCacheTagsProcessor.shared.removeTagsFor(documentUUID: docUUID)
                    try fileManager.removeItem(at: destinationURL)
                    cacheLog(.success, "Remove", doc.URL.lastPathComponent)
                } catch {
                    cacheLog(.error, "Remove", doc.URL.lastPathComponent)
                }
            }
        }
    }

}
