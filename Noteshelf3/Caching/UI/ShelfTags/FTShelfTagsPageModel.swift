//
//  FTShelfTagsPageModel.swift
//  Noteshelf3
//
//  Created by Siva on 08/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Combine
import Foundation
import UIKit
import FTCommon

enum FTShelfTagsPageLoadState {
    case loading
    case loaded
    case empty
}

enum FTShelfTagsItemType {
    case page, book, none
}

 class FTShelfTagsItem: NSObject,Identifiable {

    var id: UUID = UUID()
    var pageIndex: Int?
    var page: FTThumbnailable?
    var documentUUID: String?
    var pageUUID: String?
    var shelfItem: FTDocumentItemProtocol?
    var document: FTNoteshelfDocument?
    var type: FTShelfTagsItemType = .none
    var tags: [FTTagModel] = [FTTagModel]() {
        didSet {
            self.tags = Array(Set(tags))
        }
    }

     func setTags(_ tagNames: [String]) {
        tagNames.forEach { eachTag in
            if let tagItem = FTTagsProvider.shared.getTagItemFor(tagName: eachTag) {
                self.tags.append(tagItem.tag)
            } else {
                self.tags.append(FTTagModel(text: eachTag))
            }
        }
    }

     func removeAllTags() {
            self.tags.removeAll()
    }

    private var observerProtocol: AnyObject?;
    
    init(shelfItem: FTDocumentItemProtocol?, type: FTShelfTagsItemType, page: FTThumbnailable? = nil, pageIndex: Int? = 0) {
        super.init()
        self.page = page
        self.pageIndex = pageIndex
        self.shelfItem = shelfItem
        self.type = type
        self.document = (page as? FTNoteshelfPage)?.parentDocument as? FTNoteshelfDocument

        observerProtocol = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "tagsUpdate")
                                               , object: nil
                                               , queue: nil) { [weak self] notification in
            guard let self = self else { return }

            let userInfo = notification.userInfo
            print("Page Id = ", self.pageUUID)
            if let item = userInfo?.values.first as? FTShelfTagsItem
                ,self != item
                , self.type == item.type {
                if self.type == .book, self.documentUUID == item.documentUUID {
                    tags.removeAll();
                    self.tags.append(contentsOf: item.tags);
                }
                else if self.type == .page, self.documentUUID == item.documentUUID, self.pageUUID == item.pageUUID {
                    self.tags.removeAll();
                    self.tags.append(contentsOf: item.tags);
                }
            }
        }
    }

//    deinit {
//        NotificationCenter.default.removeObserver(self.observerProtocol, name: NSNotification.Name(rawValue: "tagsUpdate"), object: nil);
//    }
}

final class FTShelfTagsPageModel: ObservableObject {
    @Published private(set) var tagsResult = [FTShelfTagsItem]()
    @Published private(set) var state: FTShelfTagsPageLoadState = .loading
    var selectedTag: String = ""

    func buildCache(completion: @escaping ([FTShelfTagsItem]) -> Void)  {
             startLoading()
            let selectedTagItem = FTTagsProvider.shared.getTagItemFor(tagName: selectedTag)
            selectedTagItem?.getTaggdItems(completion: { [weak self] tagsPage in
                var tagItems = tagsPage
                tagItems.removeAll(where: {$0.tags.isEmpty})
                if self?.selectedTag.count ?? 0 > 0 {
                    tagItems = tagItems.filter { item in
                        // Check if the item's tags do not contain the selectedTag's text
                        return item.tags.map { $0.text }.contains(self?.selectedTag)
                    }
                }
                self?.setTagsPage(tagItems)
                completion(self?.tagsResult ?? [])
            })
    }

    private func startLoading() {
        state = .loading
    }

    private func setTagsPage(_ tagsResult: [FTShelfTagsItem]) {
        if tagsResult.isEmpty {
            state = .empty
        } else {
            state = .loaded
        }
        self.tagsResult = tagsResult
    }
}

 extension FTShelfTagsPageModel {

     func fetchOnlyTaggedNotebooks(selectedTags: [String], shelfItems: [FTShelfItemProtocol], progress: Progress) async throws -> [FTShelfTagsItem] {
         if selectedTags.isEmpty {
             debugLog("Programmer error")
             return []
         } else {
             let result = try await self.processTags(reqItems: shelfItems, selectedTags: selectedTags, progress: progress)
             return result
         }
     }

     private func processTags(reqItems: [FTShelfItemProtocol], selectedTags: [String], progress: Progress) async throws -> [FTShelfTagsItem] {
         let items: [FTDocumentItemProtocol] = reqItems.filter({ ($0.URL.downloadStatus() == .downloaded) }).compactMap({ $0 as? FTDocumentItemProtocol })

         var totalTagItems: [FTShelfTagsItem] = [FTShelfTagsItem]()

         for case let item in items where item.documentUUID != nil {
             guard let docUUID = item.documentUUID else { continue }//, item.URL.downloadStatus() == .downloaded else { continue }
             let destinationURL = FTDocumentCache.shared.cachedLocation(for: docUUID)
             print(destinationURL.path)
             // move to post processing phace
             do {
                 let document = await FTNoteshelfDocument(fileURL: destinationURL)
                 let isOpen = try await document.openDocument(purpose: FTDocumentOpenPurpose.read)
                 if isOpen {
                     let tags = await document.documentTags()
                     let considerForResult = selectedTags.allSatisfy(tags.contains(_:))
                     if considerForResult && !tags.isEmpty {
                         let tagsBook = FTShelfTagsItem(shelfItem: item, type: .book)
                         tagsBook.setTags(tags)
                         totalTagItems.append(tagsBook)
                     }
                 }

                 let tagsPage = await document.fetchSearchTagsPages(shelfItem: item, selectedTags: selectedTags)
                 totalTagItems.append(contentsOf: tagsPage)
                 _ = await document.saveAndClose()
                 progress.completedUnitCount += 1
             } catch {
                 cacheLog(.error, error, destinationURL.lastPathComponent)
             }
         }
         cacheLog(.success, totalTagItems.count)
         return totalTagItems
     }
}
