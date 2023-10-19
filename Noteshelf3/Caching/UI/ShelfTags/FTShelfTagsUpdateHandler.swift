//
//  FTShelfTagsUpdateHandler.swift
//  Noteshelf
//
//  Created by Siva on 23/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

enum FTTagsType {
    case page, book
}

class FTShelfTagsUpdateHandler: NSObject {
    static let shared = FTShelfTagsUpdateHandler()

    func updateTagsFor(items: [FTShelfTagsItem], completion: ((Bool?) -> Void)?) {
        let dispatchGroup = DispatchGroup()

        var itemsGrouped = [String: [FTShelfTagsItem]]()

        items.forEach { eachItem in
            if let documentId = eachItem.documentUUID {
                var items = itemsGrouped[documentId] ?? [FTShelfTagsItem]()
                items.append(eachItem)
                itemsGrouped[documentId] = items
            }
        }

        guard  !itemsGrouped.isEmpty else {
            completion?(true)
            return
        }

        var itesmToCache = [FTItemToCache]()
        FTNoteshelfDocumentProvider.shared.disableCloudUpdates()
        FTDocumentCache.shared.disableCacheUpdates()
        itemsGrouped.forEach { eachItem in
            if let firstItem = eachItem.value.first?.documentItem {
                let url = firstItem.URL
                let isDocAlreadyOpened = FTNoteshelfDocumentManager.shared.isDocumentAlreadyOpen(for: url)
                dispatchGroup.enter()
                let items = eachItem.value
                let request = FTDocumentOpenRequest(url: url, purpose: .write)
                FTNoteshelfDocumentManager.shared.openDocument(request: request) { token, document, error in
                    if let document = document as? FTNoteshelfDocument {
                        let docPages =  document.pages()
                        items.forEach { eachItem in
                            if eachItem.type == .book {
                                document.addTags(tags: eachItem.tags.map{$0.text})
                            } else if eachItem.type == .page {
                                if let page = docPages.first(where: {$0.uuid == eachItem.pageUUID}) {
                                    (page as? FTPageTagsProtocol)?.addTags(tags: eachItem.tags.map({$0.text}))
                                    page.isDirty = true
                                }
                            }
                        }
                        FTNoteshelfDocumentManager.shared.saveAndClose(document: document, token: token) { _ in
                            if !isDocAlreadyOpened {
                                itesmToCache.append(FTItemToCache(url: document.URL, documentID: document.documentUUID))
                            }
                            dispatchGroup.leave()
                        }
                    }
                    else {
                        dispatchGroup.leave()
                    }
                }
            }
        }
        dispatchGroup.notify(queue: .main) {
            FTDocumentCache.shared.enableCacheUpdates();
            FTDocumentCache.shared.cacheShelfItems(items: itesmToCache);
            FTNoteshelfDocumentProvider.shared.enableCloudUpdates()
            completion?(true)
        }
    }

    func deleteTag(tag: FTTagModel, completion: ((Bool?) -> Void)?) {
        let dispatchGroup = DispatchGroup()
        FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection.shelfItems(FTShelfSortOrder.none, parent: nil, searchKey: nil) { allItems in
            let items: [FTDocumentItemProtocol] = allItems.filter({ ($0.URL.downloadStatus() == .downloaded) }).compactMap({ $0 as? FTDocumentItemProtocol })

            let tagItem = FTTagsProvider.shared.getTagItemFor(tagName: tag.text)

            guard let docIdsForTag = tagItem?.documentIds else {
                completion?(false)
                return
            }

            let filteredDocuments = items.filter { item in
                return docIdsForTag.contains(item.documentUUID ?? "")
            }
            var itesmToCache = [FTItemToCache]()

            if !filteredDocuments.isEmpty, let topViewController =  UIApplication.shared.topViewController() {
                let loadingIndicatorViewController =  FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: topViewController, withText: "")
                FTNoteshelfDocumentProvider.shared.disableCloudUpdates();
                FTDocumentCache.shared.disableCacheUpdates();
                for case let doc in filteredDocuments where doc.documentUUID != nil {
                    dispatchGroup.enter()
                    let request = FTDocumentOpenRequest(url: doc.URL, purpose: .write)
                    FTNoteshelfDocumentManager.shared.openDocument(request: request) { token, document, error in
                        if let document = document as? FTNoteshelfDocument {
                            document.deleteTags([tag.text])
                            FTNoteshelfDocumentManager.shared.saveAndClose(document: document, token: token) { _ in
                                itesmToCache.append(FTItemToCache(url: document.URL, documentID: document.documentUUID))
                                dispatchGroup.leave()
                            }
                        } else {
                            dispatchGroup.leave()
                        }
                    }
                }
                dispatchGroup.notify(queue: .main) {
                    loadingIndicatorViewController.hide()
                    FTDocumentCache.shared.enableCacheUpdates();
                    FTDocumentCache.shared.cacheShelfItems(items: itesmToCache);
                    FTNoteshelfDocumentProvider.shared.enableCloudUpdates()
                    completion?(true)
                }
            } else {
                completion?(false)
            }
        }
    }

    func renameTag(tag: String, with newTag: String, completion: ((Bool?) -> Void)?) {
        let dispatchGroup = DispatchGroup()

        FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection.shelfItems(FTShelfSortOrder.none, parent: nil, searchKey: nil) { allItems in
            let items: [FTDocumentItemProtocol] = allItems.filter({ ($0.URL.downloadStatus() == .downloaded) }).compactMap({ $0 as? FTDocumentItemProtocol })

            let tagItem = FTTagsProvider.shared.getTagItemFor(tagName: newTag)
            guard let docIdsForTag = tagItem?.documentIds else {
                completion?(false)
                return
            }

            let filteredDocuments = items.filter { item in
                return docIdsForTag.contains(item.documentUUID ?? "")
            }
            var itesmToCache = [FTItemToCache]()
            if !filteredDocuments.isEmpty, let topViewController =  UIApplication.shared.topViewController() {
                let loadingIndicatorViewController =  FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: topViewController, withText: "")
                FTNoteshelfDocumentProvider.shared.disableCloudUpdates();
                FTDocumentCache.shared.disableCacheUpdates();
                for case let doc in filteredDocuments where doc.documentUUID != nil {
                    dispatchGroup.enter()
                    let request = FTDocumentOpenRequest(url: doc.URL, purpose: .write)
                    FTNoteshelfDocumentManager.shared.openDocument(request: request) { token, document, error in
                        if let document = document as? FTNoteshelfDocument {
                            document.renameTag(tag, with: newTag)
                            FTNoteshelfDocumentManager.shared.saveAndClose(document: document, token: token) { _ in
                                itesmToCache.append(FTItemToCache(url: document.URL, documentID: document.documentUUID))
                                dispatchGroup.leave()
                            }
                        } else {
                            dispatchGroup.leave()
                        }
                    }
                }
                dispatchGroup.notify(queue: .main) {
                    FTDocumentCache.shared.enableCacheUpdates();
                    FTDocumentCache.shared.cacheShelfItems(items: itesmToCache);
                    FTNoteshelfDocumentProvider.shared.enableCloudUpdates();
                    loadingIndicatorViewController.hide()
                    completion?(true)
                }
            } else {
                completion?(false)
            }
        }
    }

}
