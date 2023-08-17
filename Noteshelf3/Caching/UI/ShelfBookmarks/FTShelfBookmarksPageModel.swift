//
//  FTShelfBookmarksPageModel.swift
//  Noteshelf3
//
//  Created by Siva on 20/01/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Combine
import Foundation
import UIKit

enum FTbookmarksPageLoadState {
    case loading
    case loaded
    case empty
    case none
}

enum FTBookmarkItemType {
    case page, none
}

struct FTBookmarksResult: Identifiable {
    var id: UUID = UUID()
    var bookmarkItems: [FTBookmarksItem] = [FTBookmarksItem]()

    init(bookmarkItems: [FTBookmarksItem]) {
        self.bookmarkItems = bookmarkItems
    }
}

struct FTBookmarksItem: Identifiable {
    var id: UUID = UUID()
    let pageIndex: Int?
    let page: FTThumbnailable?
    var shelfItem: FTDocumentItemProtocol?
    var type: FTBookmarkItemType = .none
    var color: String?

    init(shelfItem: FTDocumentItemProtocol?, type: FTBookmarkItemType, page: FTThumbnailable? = nil, pageIndex: Int? = 0, color: String?) {
        self.page = page
        self.pageIndex = pageIndex
        self.shelfItem = shelfItem
        self.type = type
        self.color = color
    }
}
final class FTShelfBookmarksPageModel: ObservableObject {
    @Published private(set) var bookmarksResult: FTBookmarksResult? = nil
    @Published private(set) var state: FTbookmarksPageLoadState = .loading
    var selectedTag: String = ""

    func buildCache() async {
        do {
            await startLoading()
            let bookmarksPage = try await fetchBookmarksPages()
            await setBookmarksPage(bookmarksPage)
        } catch {
            cacheLog(.error, error)
        }
    }

    @MainActor
    private func startLoading() {
        state = .loading
    }

    @MainActor
    private func setBookmarksPage(_ bookmarksResult: FTBookmarksResult?) {
        if bookmarksResult == nil {
            state = .empty
        } else {
            state = .loaded
        }
        self.bookmarksResult = bookmarksResult
    }
}

private extension FTShelfBookmarksPageModel {
    func fetchBookmarksPages() async throws -> FTBookmarksResult {
        let allItems = await FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection.shelfItems(FTShelfSortOrder.byName, parent: nil, searchKey: nil)
        var totalBookmarksItems: [FTBookmarksItem] = [FTBookmarksItem]()

        let items: [FTDocumentItemProtocol] = allItems.filter({ ($0.URL.downloadStatus() == .downloaded) }).compactMap({ $0 as? FTDocumentItemProtocol })

        for case let item in items where item.documentUUID != nil {
            guard let docUUID = item.documentUUID else { continue }//, item.URL.downloadStatus() == .downloaded else { continue }
            let destinationURL = FTDocumentCache.shared.cachedLocation(for: docUUID)
            // move to post processing phace
            do {
                let document = await FTNoteshelfDocument(fileURL: destinationURL)
                let isOpen = try await document.openDocument(purpose: FTDocumentOpenPurpose.read)
                if isOpen {
                    let bookmarkPage = await document.fetchBookmarksPages(shelfItem: item)
                    totalBookmarksItems.append(contentsOf: bookmarkPage)
                }
                _ = await document.close(completionHandler: nil)
            } catch {
                cacheLog(.error, error, destinationURL.lastPathComponent)
            }
        }
        cacheLog(.success, totalBookmarksItems.count)
        let result = FTBookmarksResult(bookmarkItems: totalBookmarksItems)
        return result
    }
}
