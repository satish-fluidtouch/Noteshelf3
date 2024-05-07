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

    func createCacheTagsPlistIfNeeded(_ onCompletion: (()->())?) {
        queue.async {
            self.loadTagsFromDocuments(onCompletion)
        }
        cacheLog(.info, "preparing tags cache")
    }

    private func loadTagsFromDocuments(_ onCompletion: (()->())?) {
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
                        let itemToCache = FTItemToCache(url: destinationURL, documentID: docId);
                        itemToCache.shelfItem = item;
                        itemsToCahe.append(itemToCache)
                    }
                    dispatchGroup.leave()
                }
                dispatchGroup.notify(queue: self.queue) {
                    self.cacheTagsForDocuments(items: itemsToCahe)
                    onCompletion?()
                }
            }
        }
    }

    private func cacheTagsForDocuments(items: [FTItemToCache]) {
        items.forEach { eachItem in
            FTTagsProvider.shared.syncTagsWithLocalCache(documentID: eachItem.documentID,documentitem: eachItem.shelfItem);
        }
    }
}
