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
                    return item1.bookmarkColor < item2.bookmarkColor
                }
                completion(sortedItems)
            }
        } else {
            let sortedItems = bookmarkItems.sorted { (item1, item2) -> Bool in
                return item1.bookmarkColor < item2.bookmarkColor
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

    private func fetchBookmarks(completion: @escaping ([FTBookmarksItem]) -> Void) {
        let dispatchGroup = DispatchGroup()

        var totalBookmarksItems: [FTBookmarksItem] = [FTBookmarksItem]()
        FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection.shelfItems(FTShelfSortOrder.none, parent: nil, searchKey: nil) { allItems in

        let items: [FTDocumentItemProtocol] = allItems.filter({ ($0.URL.downloadStatus() == .downloaded) }).compactMap({ $0 as? FTDocumentItemProtocol })

            for case let item in items where item.documentUUID != nil {
                dispatchGroup.enter()
                guard let docUUID = item.documentUUID else { continue }

                FTCacheTagsProcessor.shared.cachedDocumentPlistFor(documentUUID: docUUID) { docPlist, error in
                    let pages = docPlist?.pages
                    var tagsPages: [FTBookmarksItem] = [FTBookmarksItem]()
                    pages?.forEach { page in
                        if page.isBookmarked {
                            var pageIndex = 0
                            if let index = pages?.firstIndex(where: { $0.uuid == page.uuid }) {
                                pageIndex = index
                            }
                            let pdfRect = page.pageRect
                            let bookmarkPage = FTBookmarksItem(shelfItem: item, documentUUID: docUUID, pageUUID: page.uuid,pageIndex: pageIndex, pdfKitPageRect: pdfRect, bookmarkTitle: page.bookmarkTitle, isBookmarked: page.isBookmarked, bookmarkColor: page.bookmarkColor)
                            tagsPages.append(bookmarkPage)
                        }
                    }
                    totalBookmarksItems.append(contentsOf: tagsPages)
                    dispatchGroup.leave()
                }
            }
            cacheLog(.info, "Bookmarks", totalBookmarksItems.count)
            dispatchGroup.notify(queue: .main) {
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
