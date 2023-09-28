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

        for case let item in items where (item.shelfItem?.documentUUID != nil) {
            dispatchGroup.enter()
            var document: FTNoteshelfDocument!
            var isOpen = false
            func saveTags() {
                if isOpen {
                    let docPages =  document.pages()
                    if item.type == .book {
                        document.addTags(tags: item.tags.map{$0.text})
                    } else if item.type == .page {
                        let pages = docPages.filter {$0.uuid == item.pageUUID}
                        if let page = pages.first as? FTPageTagsProtocol {
                            page.addTags(tags: item.tags.map({$0.text}))
                        }
                    }
                    if item.document == nil {
                        document.saveAndCloseWithCompletionHandler { _ in
                            if let doc = item.shelfItem, let docUUID = doc.documentUUID {
                                FTDocumentCache.shared.cacheShelfItemFor(url: doc.URL, documentUUID: docUUID)
                                dispatchGroup.leave()
                            }
                        }
                    } else {
                        document.save { _ in
                            if let doc = item.shelfItem, let docUUID = doc.documentUUID {
                                FTDocumentCache.shared.cacheShelfItemFor(url: doc.URL, documentUUID: docUUID)
                                dispatchGroup.leave()
                            }
                        }
                    }
                }

            }
            if let itemDocument = item.document {
                document = itemDocument
                isOpen = document.documentState == .normal
                document =  FTNoteshelfDocument(fileURL: item.shelfItem!.URL)
                document.openDocument(purpose: FTDocumentOpenPurpose.write) { success, error in
                    isOpen = success
                    saveTags()
                }
            }
            else {
                document =  FTNoteshelfDocument(fileURL: item.shelfItem!.URL)
                document.openDocument(purpose: FTDocumentOpenPurpose.write) { success, error in
                    isOpen = success
                    saveTags()
                }
            }
        }
        dispatchGroup.notify(queue: .main) {
            completion?(true)
        }
    }

    func deleteTag(tag: FTTagModel, for document: FTNoteshelfDocument? = nil, completion: ((Bool?) -> Void)?) {
        let dispatchGroup = DispatchGroup()
        FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection.shelfItems(FTShelfSortOrder.byName, parent: nil, searchKey: nil) { allItems in
            let items: [FTDocumentItemProtocol] = allItems.filter({ ($0.URL.downloadStatus() == .downloaded) }).compactMap({ $0 as? FTDocumentItemProtocol })

            FTCacheTagsProcessor.shared.deletTags(tags: [tag])
            let tagItem = FTTagsProvider.shared.getTagItemFor(tagName: tag.text)
            guard let docIdsForTag = tagItem?.documentIds else {return}
           let filteredDocuments = items.filter { item in
               return docIdsForTag.contains(item.documentUUID ?? "")
           }
            if let topViewController =  UIApplication.shared.topViewController() {
                let loadingIndicatorViewController = FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: topViewController, withText: "")
                for case let doc in filteredDocuments where doc.documentUUID != nil {
                    dispatchGroup.enter()
                    guard let documentUUID = doc.documentUUID else { continue }
                    if let currentDoc = document,  documentUUID == currentDoc.documentUUID {
                        FTCacheTagsProcessor.shared.deleteTags(tags: [tag], for: currentDoc)
                    } else {
                        let doc =  FTNoteshelfDocument(fileURL: doc.URL)
                         FTCacheTagsProcessor.shared.deleteTags(tags: [tag], for: doc)
                    }
                    dispatchGroup.leave()
                }
                 loadingIndicatorViewController.hide()
                dispatchGroup.notify(queue: .main) {
                    completion?(true)
                }
            }

        }
        completion?(false)
    }

    func renameTag(tag: FTTagModel, with newTag: FTTagModel, for document: FTNoteshelfDocument? = nil) {
        let dispatchGroup = DispatchGroup()

        FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection.shelfItems(FTShelfSortOrder.byName, parent: nil, searchKey: nil) { allItems in
            let items: [FTDocumentItemProtocol] = allItems.filter({ ($0.URL.downloadStatus() == .downloaded) }).compactMap({ $0 as? FTDocumentItemProtocol })

             FTCacheTagsProcessor.shared.renameTagInPlist(tag, with: newTag)
            let tagItem = FTTagsProvider.shared.getTagItemFor(tagName: newTag.text)
            guard let docIdsForTag = tagItem?.documentIds else {return}
            let filteredDocuments = items.filter { item in
                return docIdsForTag.contains(item.documentUUID ?? "")
            }
            if let topViewController =  UIApplication.shared.topViewController() {
                let loadingIndicatorViewController =  FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: topViewController, withText: "")
                for case let doc in filteredDocuments where doc.documentUUID != nil {
                    dispatchGroup.enter()
                    guard let documentUUID = doc.documentUUID else { continue }
                    if let currentDoc = document,  documentUUID == currentDoc.documentUUID {
                         FTCacheTagsProcessor.shared.renameTag(tag, with: newTag, for: currentDoc)
                    } else {
                        let noteDoc =  FTNoteshelfDocument(fileURL: doc.URL)
                         FTCacheTagsProcessor.shared.renameTag(tag, with: newTag, for: noteDoc)
                    }
                    dispatchGroup.leave()
                }
                 loadingIndicatorViewController.hide()
            }
        }
    }

}
