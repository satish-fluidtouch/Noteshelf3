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

enum FTTagsUpdateType {
    case add, remove, removeAll
}

class FTShelfTagsUpdateHandler: NSObject {
    static let shared = FTShelfTagsUpdateHandler()
    
    func updateTag(_ tag: FTTagModel?, for items: [FTShelfTagsItem], updateType type: FTTagsUpdateType) async throws {
        for case var item in items where (item.shelfItem?.documentUUID != nil) {
            do {
                var document: FTNoteshelfDocument!
                var isOpen = false
                if let itemDocument = item.document {
                    document = itemDocument
                    isOpen = await document.documentState == .normal
                    if !isOpen {
                        document = await FTNoteshelfDocument(fileURL: item.shelfItem!.URL)
                        isOpen = try await document.openDocument(purpose: FTDocumentOpenPurpose.write)
                    }
                } else {
                    document = await FTNoteshelfDocument(fileURL: item.shelfItem!.URL)
                    isOpen = try await document.openDocument(purpose: FTDocumentOpenPurpose.write)
                }
                if isOpen {
                    let docPages = await document.pages()
                    if item.type == .book {
                        if type == .add, let text = tag?.text {
                            await document.addTag(text)
                        } else if type == .remove, let text = tag?.text {
                            await document.removeTags([text])
                        } else if type == .removeAll {
                            await document.removeAllTags()
                        }
                    } else if item.type == .page {
                        let pages = docPages.filter {$0.pageIndex() == item.pageIndex}
                        if let page = pages.first as? FTPageTagsProtocol {
                            if type == .add, let text = tag?.text {
                                page.addTag(text)
                            } else if type == .remove, let text = tag?.text {
                                page.removeTag(text)
                            } else if type == .removeAll {
                                page.removeAllTags()
                            }
                        }
                    }
                }
                if item.document == nil {
                    _ = await document.saveAndClose()
                } else {
                    _ = await document.save(completionHandler: nil)
                }
                if let doc = item.shelfItem, let docUUID = doc.documentUUID {
                    try FTDocumentCache.shared.cacheShelfItemFor(url: doc.URL, documentUUID: docUUID)
                }
            } catch {
                cacheLog(.error, error, item.shelfItem!.URL.lastPathComponent)
            }
        }

    }

    func deleteTag(tag: FTTagModel, for document: FTNoteshelfDocument? = nil) async throws {
        let allItems = await FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection.shelfItems(FTShelfSortOrder.byName, parent: nil, searchKey: nil)
        let items: [FTDocumentItemProtocol] = allItems.filter({ ($0.URL.downloadStatus() == .downloaded) }).compactMap({ $0 as? FTDocumentItemProtocol })

        try await FTCacheTagsProcessor.shared.deletTags(tags: [tag])
        let docIdsForTag = FTCacheTagsProcessor.shared.documentIdsForTag(tag: tag)
       let filteredDocuments = items.filter { item in
           return docIdsForTag.contains(item.documentUUID ?? "")
       }

       for case let doc in filteredDocuments where doc.documentUUID != nil {
           guard let documentUUID = doc.documentUUID else { continue }
           if let currentDoc = document, await documentUUID == currentDoc.documentUUID {
               try await FTCacheTagsProcessor.shared.deleteTags(tags: [tag], for: currentDoc)
           } else {
               let doc = await FTNoteshelfDocument(fileURL: doc.URL)
               try await FTCacheTagsProcessor.shared.deleteTags(tags: [tag], for: doc)
           }
       }

    }

    func renameTag(tag: FTTagModel, with newTag: FTTagModel, for document: FTNoteshelfDocument? = nil) async throws {

        let allItems = await FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection.shelfItems(FTShelfSortOrder.byName, parent: nil, searchKey: nil)
        let items: [FTDocumentItemProtocol] = allItems.filter({ ($0.URL.downloadStatus() == .downloaded) }).compactMap({ $0 as? FTDocumentItemProtocol })

        try await FTCacheTagsProcessor.shared.renameTagInPlist(tag, with: newTag)

         let docIdsForTag = FTCacheTagsProcessor.shared.documentIdsForTag(tag: newTag)
        let filteredDocuments = items.filter { item in
            return docIdsForTag.contains(item.documentUUID ?? "")
        }

        for case let doc in filteredDocuments where doc.documentUUID != nil {
            guard let documentUUID = doc.documentUUID else { continue }
            if let currentDoc = document, await documentUUID == currentDoc.documentUUID {
            try await FTCacheTagsProcessor.shared.renameTag(tag, with: newTag, for: currentDoc)
            } else {
                let noteDoc = await FTNoteshelfDocument(fileURL: doc.URL)
                try await FTCacheTagsProcessor.shared.renameTag(tag, with: newTag, for: noteDoc)
            }
        }
    }

}
