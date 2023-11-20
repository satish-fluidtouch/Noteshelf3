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

struct FTBookmarksItem: Identifiable {
    var id: UUID = UUID()
    var shelfItem: FTDocumentItemProtocol
    var documentUUID: String
    var pageUUID: String
    var pageIndex: Int
    var pdfKitPageRect: CGRect
    var bookmarkTitle: String
    var isBookmarked: Bool
    var bookmarkColor: String

    init(shelfItem: FTDocumentItemProtocol,documentUUID: String, pageUUID: String, pageIndex: Int, pdfKitPageRect: CGRect, bookmarkTitle: String,isBookmarked: Bool,bookmarkColor: String) {
        self.shelfItem = shelfItem
        self.documentUUID = documentUUID
        self.pageUUID = pageUUID
        self.pageIndex = pageIndex
        self.pdfKitPageRect = pdfKitPageRect
        self.bookmarkTitle = bookmarkTitle
        self.isBookmarked = isBookmarked
        self.bookmarkColor = bookmarkColor
    }
}

final class FTShelfBookmarksPageModel: ObservableObject {
    var selectedTag: String = ""

    func buildCache(completion: @escaping ([FTBookmarksItem]) -> Void) {
            FTBookmarksProvider.shared.getBookmarkItems { items in
                completion(items)
            }
    }

}
