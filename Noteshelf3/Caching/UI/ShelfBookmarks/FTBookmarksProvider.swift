//
//  FTBookmarksProvider.swift
//  Noteshelf3
//
//  Created by Siva on 04/10/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTBookmarksProvider {
    static let shared = FTBookmarksProvider()
    private var bookmarkItems = [FTBookmarksItem]()

    func getBookmarkItems(completion: @escaping ([FTBookmarksItem]) -> Void) {
        if bookmarkItems.isEmpty {
            fetchBookmarks { [weak self] items in
                self?.bookmarkItems = items
                let sortedItems = items.sorted { (item1, item2) -> Bool in
                    return item1.shelfItem.displayTitle < item2.shelfItem.displayTitle
                }
                completion(sortedItems)
            }
        } else {
            let sortedItems = bookmarkItems.sorted { (item1, item2) -> Bool in
                return item1.shelfItem.displayTitle < item2.shelfItem.displayTitle
            }
            completion(sortedItems)
        }
    }

    func updateBoodmarkItemFor(pages: [FTThumbnailable], shelfItem: FTDocumentItemProtocol) {
        pages.forEach { page in
            if let index = self.bookmarkItems.firstIndex(where: {$0.pageUUID == page.uuid}) {
                if page.isBookmarked == false {
                    bookmarkItems.remove(at: index)
                } else {
                    bookmarkItems[index].isBookmarked = page.isBookmarked
                    bookmarkItems[index].bookmarkTitle = page.bookmarkTitle
                    bookmarkItems[index].bookmarkColor = page.bookmarkColor
                }
            } else if page.isBookmarked {
                let bookmarkPage = FTBookmarksItem(shelfItem: shelfItem, documentUUID: shelfItem.documentUUID!, pageUUID: page.uuid,pageIndex: page.pageIndex(), pdfKitPageRect: page.pdfPageRect, bookmarkTitle: page.bookmarkTitle, isBookmarked: page.isBookmarked, bookmarkColor: page.bookmarkColor)
                bookmarkItems.append(bookmarkPage)
            }
        }
    }

    func updateBookmarkItemsFor(cacheItems: [FTItemToCache]) {
        FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection.shelfItems(FTShelfSortOrder.none, parent: nil, searchKey: nil) { allItems in
            
            cacheItems.forEach { cacheItem in
                let documentUUID = cacheItem.documentID
                let item = (allItems as! [FTDocumentItemProtocol]).first(where: {$0.documentUUID == documentUUID})
                guard let documentItem = item  else { return }
                let matchedItems = self.bookmarkItems.filter {$0.documentUUID == documentUUID}
                self.bookmarkItems.removeAll(where: {$0.documentUUID == documentUUID})
                let cachedDocument = FTCachedDocument(documentID: documentUUID);
                cachedDocument.pages().enumerated().forEach { eachItem in
                    let page = eachItem.element;
                    let matchedItem = matchedItems.first(where: {$0.pageUUID == page.uuid})
                    if page.isBookmarked {
                        let pageIndex = eachItem.offset
                        let pdfRect = page.pdfPageRect
                        let bookmarkPage = FTBookmarksItem(shelfItem: documentItem
                                                           , documentUUID: documentUUID
                                                           , pageUUID: page.uuid
                                                           , pageIndex: pageIndex
                                                           , pdfKitPageRect: pdfRect
                                                           , bookmarkTitle: page.bookmarkTitle
                                                           , isBookmarked: page.isBookmarked
                                                           , bookmarkColor: page.bookmarkColor)
                        self.bookmarkItems.append(bookmarkPage)
                    }
                }
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshBookmarks"), object: nil)
            }
        }
    }

    func removeBookmarkFor(item: FTBookmarksItem, completion: ((Bool?) -> Void)?) {
        if let index = self.bookmarkItems.firstIndex(where: {$0.pageUUID == item.pageUUID}) {
            self.removeBookmarFor(item: item) {[weak self] _ in
                self?.bookmarkItems.remove(at: index)
                completion?(true)
            }
        } else {
            completion?(false)
        }
    }

    func removeBookmarkFor(documentId: String) {
        self.bookmarkItems.removeAll(where: {$0.documentUUID == documentId})
    }

    private func fetchBookmarks(completion: @escaping ([FTBookmarksItem]) -> Void) {
        var totalBookmarksItems: [FTBookmarksItem] = [FTBookmarksItem]()
        FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection.shelfItems(FTShelfSortOrder.none, parent: nil, searchKey: nil) { allItems in

            let items: [FTDocumentItemProtocol] = allItems.compactMap({ $0 as? FTDocumentItemProtocol }).filter({ $0.isDownloaded })

            for case let item in items where item.documentUUID != nil {
                guard let docUUID = item.documentUUID else { continue }
                
                let cachedDocument = FTCachedDocument(documentID: docUUID);
                cachedDocument.pages().enumerated().forEach { eachItem in
                    let page = eachItem.element;
                    let pageIndex = eachItem.offset;
                    if page.isBookmarked {
                        let pdfRect = page.pdfPageRect
                        let bookmarkPage = FTBookmarksItem(shelfItem: item
                                                           , documentUUID: docUUID
                                                           , pageUUID: page.uuid
                                                           , pageIndex: pageIndex
                                                           , pdfKitPageRect: pdfRect
                                                           , bookmarkTitle: page.bookmarkTitle
                                                           , isBookmarked: page.isBookmarked
                                                           , bookmarkColor: page.bookmarkColor)
                        totalBookmarksItems.append(bookmarkPage)
                    }
                }
            }
            cacheLog(.info, "Bookmarks", totalBookmarksItems.count)
            DispatchQueue.main.async {
                completion(totalBookmarksItems)
            }
        }
    }

    private func removeBookmarFor(item: FTBookmarksItem, completion: ((Bool?) -> Void)?) {
        let docUrl = item.shelfItem.URL
        let request = FTDocumentOpenRequest(url: docUrl, purpose: .write)
        FTNoteshelfDocumentManager.shared.openDocument(request: request) { token, document, error in
            if let document = document as? FTNoteshelfDocument {
                let docPages = document.pages()
                let pages = docPages.filter {$0.uuid == item.pageUUID}
                if let page = pages.first as? FTPageTagsProtocol {
                    document.removePageBookmark(page: page as! FTThumbnailable)
                    (page as? FTNoteshelfPage)?.isDirty = true
                }
                FTNoteshelfDocumentManager.shared.saveAndClose(document: document, token: token) { _ in
                    completion?(true)
                }
            } else {
                completion?(false)
            }
        }
    }

    private func thumbnailPath(documentUUID: String, pageUUID: String) -> String
    {
        let thumbnailFolderPath = URL.thumbnailFolderURL();
        let documentPath = thumbnailFolderPath.appendingPathComponent(documentUUID);
        var isDir = ObjCBool.init(false);
        if(!FileManager.default.fileExists(atPath: documentPath.path, isDirectory: &isDir) || !isDir.boolValue) {
            _ = try? FileManager.default.createDirectory(at: documentPath, withIntermediateDirectories: true, attributes: nil);
        }
        let thumbnailPath  = documentPath.appendingPathComponent(pageUUID);
        return thumbnailPath.path;
    }

    func thumbnail(documentUUID: String, pageUUID: String, onCompletion: @escaping ((UIImage?,String) -> Void)) {
        let thumbnailPath = self.thumbnailPath(documentUUID: documentUUID, pageUUID: pageUUID)
        var img: UIImage? = nil
        if nil == img && FileManager().fileExists(atPath: thumbnailPath) {
            DispatchQueue.global().async {
                img = UIImage.init(contentsOfFile: thumbnailPath)
                DispatchQueue.main.async {
                    onCompletion(img, pageUUID)
                }
            }
        } else {
            onCompletion(img, pageUUID)
        }
    }
}
