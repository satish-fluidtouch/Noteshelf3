//
//  FTShelfItemCollection+Async.swift
//  Noteshelf
//
//  Created by Akshay on 19/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

extension FTShelfItemCollectionAll {
    func shelfItems(_ sortOrder: FTShelfSortOrder, parent: FTGroupItemProtocol?, searchKey: String?) async -> [FTShelfItemProtocol] {
        return await withCheckedContinuation { continuation in
            shelfItems(sortOrder, parent: parent, searchKey: searchKey) { result in
                continuation.resume(returning: result)
            }
        }
    }
}

extension FTDocumentProtocolInternal {
    func openDocument(purpose: FTDocumentOpenPurpose) async throws -> Bool {
        return try await withCheckedThrowingContinuation({ continuation in
            self.openDocument(purpose: purpose, completionHandler: { isSuccess, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: isSuccess)
                }
            })
        })
    }

    func saveAndClose() async -> Bool {
        return await withCheckedContinuation({ continuation in
            self.saveAndCloseWithCompletionHandler { isSuccess in
                continuation.resume(returning: isSuccess)
            }
        })
    }
}

// MARK: TagsPages
extension FTNoteshelfDocument {
  
    func fetchTagsPages(shelfItem: FTDocumentItemProtocol, selectedTag: String) -> [FTShelfTagsItem] {
        var tagsPages: [FTShelfTagsItem] = [FTShelfTagsItem]()
        self.pages().forEach { page in
            if let tagPage = page as? FTThumbnailable {
                var tags = tagPage.tags()
                if tags.count > 0 {
                    func generateShelfTagItem() {
                        let tagsPage = FTTagsProvider.shared.shelfTagsItemForPage(shelfItem: shelfItem, page: tagPage, tags: tags)
//                        let tagsPage = FTShelfTagsItem(shelfItem: shelfItem, type: .page, page: tagPage, pageIndex: page.pageIndex())
//                        tagsPage.pageUUID = page.uuid
//                        tagsPage.documentUUID = shelfItem.documentUUID
//                        tagsPage.setTags(tags)
                        tagsPage.document = self
                        tagsPages.append(tagsPage)
                    }
                    if selectedTag.isEmpty {
                        generateShelfTagItem()
                    } else if tags.contains(selectedTag) {
                        generateShelfTagItem()
                    }
                }
            }
        }
        return tagsPages
    }

    func fetchSearchTagsPages(shelfItem: FTDocumentItemProtocol, selectedTags: [String]) -> [FTShelfTagsItem] {
        var tagsPages: [FTShelfTagsItem] = [FTShelfTagsItem]()
        self.pages().forEach { page in
            if let tagPage = page as? FTThumbnailable {
                let tags = tagPage.tags()
                let considerForResult = selectedTags.allSatisfy(tags.contains(_:))
                if considerForResult && !tags.isEmpty {
                    var tagsPage = FTShelfTagsItem(shelfItem: shelfItem, type: .page, page: tagPage, pageIndex: page.pageIndex())
                    tagsPage.setTags(tags)
                    tagsPages.append(tagsPage)
                }
            }
        }
        return tagsPages
    }

    func addPageTag(tag: String) {
        self.pages().forEach { page in
            (page as? FTNoteshelfPage)?.addTag(tag)
        }
    }

    func removePageTag(tag: String) {
        self.pages().forEach { page in
            (page as? FTNoteshelfPage)?.removeTag(tag)
        }
    }


    func removePageTags(tags: [String]) {
        self.pages().forEach { page in
            tags.forEach { tag in
                (page as? FTNoteshelfPage)?.removeTag(tag)
            }
        }
    }

    func renamePageTag(_ tag: String, with newTag: String) {
        self.pages().forEach { page in
            (page as? FTNoteshelfPage)?.rename(tag: tag, with: newTag)
        }
    }

}

extension FTNoteshelfDocument {

    func fetchBookmarksPages(shelfItem: FTDocumentItemProtocol) -> [FTBookmarksItem] {
        var bookmarksPages: [FTBookmarksItem] = [FTBookmarksItem]()
        self.pages().forEach { page in
            if let _page = page as? FTThumbnailable {
                if _page.isBookmarked {
                    let bookmarkPage = FTBookmarksItem(shelfItem: shelfItem, type: .page, page: _page, pageIndex: _page.pageIndex(), color: _page.bookmarkColor)
                    bookmarksPages.append(bookmarkPage)
                }
            }
        }
        return bookmarksPages
    }

    func removePageBookmark(page: FTThumbnailable) {
        let isBookmarked = !page.isBookmarked
        page.isBookmarked = isBookmarked
        if(isBookmarked == false){
            page.bookmarkTitle = ""
            page.bookmarkColor = ""
        }
        else{
            page.bookmarkTitle = ""
            page.bookmarkColor = "ED0D6B"
        }
    }
}
