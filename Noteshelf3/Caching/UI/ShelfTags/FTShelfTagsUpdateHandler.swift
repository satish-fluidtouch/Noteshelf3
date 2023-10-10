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
            func saveTags(document: FTNoteshelfDocument) {
                let docPages =  document.pages()
                if item.type == .book {
                    document.addTags(tags: item.tags.map{$0.text})
                } else if item.type == .page {
                    if let page = docPages.first(where: {$0.uuid == item.pageUUID}) {
                        (page as? FTPageTagsProtocol)?.addTags(tags: item.tags.map({$0.text}))
                        page.isDirty = true
                    }
                }
            }
            if let document = item.document {
                saveTags(document: document)
                item.document = nil
                dispatchGroup.leave()
            }
            else {
                let request = FTDocumentOpenRequest(url: item.shelfItem!.URL, purpose: .write)
                FTNoteshelfDocumentManager.shared.openDocument(request: request) { token, document, error in
                    if let document = document as? FTNoteshelfDocument {
                        saveTags(document: document)
                        FTNoteshelfDocumentManager.shared.saveAndClose(document: document, token: token) { _ in
                            dispatchGroup.leave()
                        }
                    }
                }
            }
        }
        dispatchGroup.notify(queue: .main) {
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
            FTCacheTagsProcessor.shared.deletTags(tags: [tag])

            if let topViewController =  UIApplication.shared.topViewController() {
                let loadingIndicatorViewController = FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: topViewController, withText: "")
                for case let doc in filteredDocuments where doc.documentUUID != nil {
                    dispatchGroup.enter()
                    let request = FTDocumentOpenRequest(url: doc.URL, purpose: .write)
                    FTNoteshelfDocumentManager.shared.openDocument(request: request) { token, document, error in
                        if let document = document as? FTNoteshelfDocument {
                            document.deleteTags([tag.text])
                            FTNoteshelfDocumentManager.shared.saveAndClose(document: document, token: token) { _ in
                                dispatchGroup.leave()
                            }
                        } else {
                            dispatchGroup.leave()
                        }
                    }
                }
                dispatchGroup.notify(queue: .main) {
                    loadingIndicatorViewController.hide()
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
            if let topViewController =  UIApplication.shared.topViewController() {
                let loadingIndicatorViewController =  FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: topViewController, withText: "")
                for case let doc in filteredDocuments where doc.documentUUID != nil {
                    dispatchGroup.enter()

                    let request = FTDocumentOpenRequest(url: doc.URL, purpose: .write)
                    FTNoteshelfDocumentManager.shared.openDocument(request: request) { token, document, error in
                        if let document = document as? FTNoteshelfDocument {
                            document.renameTag(tag, with: newTag)
                            FTNoteshelfDocumentManager.shared.saveAndClose(document: document, token: token) { _ in
                                dispatchGroup.leave()
                            }
                        } else {
                            dispatchGroup.leave()
                        }
                    }
                }
                dispatchGroup.notify(queue: .main) {
                    loadingIndicatorViewController.hide()
                    completion?(true)
                }
            } else {
                completion?(false)
            }
        }
    }

}
