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
}
#if DEBUG
private let cleanOnNextLaunch: Bool = true
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
        try? FTCacheTagsProcessor.shared.removeAllTagsFromPlist()

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
        cacheLog(.info, "shelfItemDidRemove", notification.userInfo, notification.object)
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

        // Perform all the operations on the secondary thread. This should never block the user interaction
        queue.async {
            do {
                try self.removeCacheDocumentIfRequired(items)
            } catch {

            }
            if !items.isEmpty {
                runInMainThread {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshSideMenu"), object: nil)
                }
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

        cacheLog(.info, "shelfitemDidUpdate", notification.userInfo, shelfItemCollection.URL)
        guard let items = notification.userInfo?["items"] as? [FTDocumentItemProtocol] else { return }

        // Perform all the operations on the secondary thread. This should never block the user interaction
        queue.async {
            items.forEach { item in
                if let docUUID = item.documentUUID {
                    do {
                        try self.cacheShelfItemFor(url: item.URL, documentUUID: docUUID)
                    } catch {
                        cacheLog(.error, item.URL)
                    }
                } else {
                    cacheLog(.info, "Ignoring \(item.URL.lastPathComponent)")
                }
            }
            if !items.isEmpty {
                runInMainThread {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshSideMenu"), object: nil)
                }
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

    func cacheShelfItemFor(url: URL, documentUUID: String, forceUpdate: Bool = false) throws {
        var catchError: Error?
         cacheShelfItemIfRequired(url: url, documentUUID: documentUUID, onCompletion: { error in
             catchError = error
            if error == nil {
                do {
                    try FTCacheTagsProcessor.shared.cacheTagsForDocument(url: url, documentUUID: documentUUID)
                } catch {
                    catchError = error
                }
            }
        })
        if let catchError = catchError {
            throw catchError
        }
    }
}

private extension FTDocumentCache {
    func cacheShelfItemIfRequired(url: URL, documentUUID: String, forceUpdate: Bool = false) throws {
        let destinationURL = cachedLocation(for: documentUUID)
        if fileManager.fileExists(atPath: destinationURL.path) {
            let isReplaced = try fileManager.coordinatedCopy(fromURL: url, toURL: destinationURL, force: true)
            cacheLog(.success, "Replace", isReplaced, destinationURL.lastPathComponent)
        } else {
            let isCopied = try fileManager.coordinatedCopy(fromURL: url, toURL: destinationURL)
            cacheLog(.success, "Copy", isCopied, destinationURL.lastPathComponent)
        }
    }

    func cacheShelfItemIfRequired(url: URL, documentUUID: String, forceUpdate: Bool = false, onCompletion: ((Error?) ->())?) {
        var forceUpdate = forceUpdate
        let destinationURL = cachedLocation(for: documentUUID)
        var fileAction = "Copy"
        if fileManager.fileExists(atPath: destinationURL.path) {
            fileAction = "Replace"
            forceUpdate = true
        }
        fileManager.coordinatedCopy(fromURL: url, toURL: destinationURL, force: forceUpdate) { error in
            cacheLog( (error == nil) ? .success : .error, fileAction, (error == nil), destinationURL.lastPathComponent)
            onCompletion?(error);
        }
    }

    // TODO: (AK) Try using Async Sequences
    func removeCacheDocumentIfRequired(_ documents: [FTDocumentItemProtocol]) throws {
        for case let doc in documents where doc.documentUUID != nil {
            guard let docUUID = doc.documentUUID else { continue }

            let destinationURL = cachedLocation(for: docUUID)
            if fileManager.fileExists(atPath: destinationURL.path) {
                do {
                    try FTCacheTagsProcessor.shared.cacheTagsForDocument(url: doc.URL, documentUUID: docUUID)
                    try fileManager.removeItem(at: destinationURL)
                    cacheLog(.success, "Remove", destinationURL.lastPathComponent)
                } catch {
                    cacheLog(.error, "Remove", destinationURL.lastPathComponent)
                }
            }
        }
    }

}
