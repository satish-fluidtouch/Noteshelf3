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

struct FTShelfTagsResult: Identifiable {
    var id: UUID = UUID()
    var tagsItems: [FTShelfTagsItem] = [FTShelfTagsItem]()

    init(tagsItems: [FTShelfTagsItem]) {
        self.tagsItems = tagsItems
    }
}

struct FTShelfTagsItem: Identifiable {
    var id: UUID = UUID()
    let pageIndex: Int?
    let page: FTThumbnailable?
    var shelfItem: FTDocumentItemProtocol?
    var document: FTNoteshelfDocument?
    var type: FTShelfTagsItemType = .none
    private(set) var tags: [FTTagModel] = [FTTagModel]()
    
    mutating func setTags(_ tagNames: [String]) {
        tagNames.forEach { eachTag in
            self.tags.append(FTTagModel(text: eachTag));
        }
    }
    mutating func removeAllTags() {
            self.tags.removeAll()
    }

    
    init(shelfItem: FTDocumentItemProtocol?, type: FTShelfTagsItemType, page: FTThumbnailable? = nil, pageIndex: Int? = 0) {
        self.page = page
        self.pageIndex = pageIndex
        self.shelfItem = shelfItem
        self.type = type
        self.document = (page as? FTNoteshelfPage)?.parentDocument as? FTNoteshelfDocument
    }
}

final class FTShelfTagsPageModel: ObservableObject {
    @Published private(set) var tagsResult: FTShelfTagsResult? = nil
    @Published private(set) var state: FTShelfTagsPageLoadState = .loading
    var selectedTag: String = ""

    func buildCache() async {
        do {
            await startLoading()
            let tagsPage = try await fetchTagsPages(selectedTag:  self.selectedTag)
            await setTagsPage(tagsPage)
        } catch {
            cacheLog(.error, error)
        }
    }

    @MainActor
    private func startLoading() {
        state = .loading
    }

    @MainActor
    private func setTagsPage(_ tagsResult: FTShelfTagsResult?) {
        if tagsResult == nil {
            state = .empty
        } else {
            state = .loaded
        }
        self.tagsResult = tagsResult
    }
}

 extension FTShelfTagsPageModel {
    func fetchTagsPages(selectedTag: String) async throws -> FTShelfTagsResult {
        measureTime(name: "<<<<All Notes") {
        }
        let allItems = await FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection.shelfItems(FTShelfSortOrder.byName, parent: nil, searchKey: nil)
        var totalTagItems: [FTShelfTagsItem] = [FTShelfTagsItem]()

        let items: [FTDocumentItemProtocol] = allItems.filter({ ($0.URL.downloadStatus() == .downloaded) }).compactMap({ $0 as? FTDocumentItemProtocol })

        let docIds = FTCacheTagsProcessor.shared.documentIdsForTag(tag: FTTagModel(text: selectedTag))
       let filteredDocuments = items.filter { item in
           return docIds.contains(item.documentUUID ?? "")
       }

        for case let item in filteredDocuments where item.documentUUID != nil {

            guard let docUUID = item.documentUUID else { continue }//, item.URL.downloadStatus() == .downloaded else { continue }
            let destinationURL = FTDocumentCache.shared.cachedLocation(for: docUUID)
            // move to post processing phace
            do {
                let document = await FTNoteshelfDocument(fileURL: destinationURL)
                let isOpen = try await document.openDocument(purpose: FTDocumentOpenPurpose.read)
                if isOpen {
                    var tags = await document.documentTags()
                    // Check if the selected tag is All Tags or Individual
                    // If the received selectedtag is Empty, treate it as "All Tags"
                    if !selectedTag.isEmpty {
                        let filteredTags = tags.filter {$0 == selectedTag}
                        if !filteredTags.isEmpty {
                            tags = filteredTags
                        } else {
                            tags = []
                        }
                    }
                    if tags.count > 0 {
                        var tagsBook = FTShelfTagsItem(shelfItem: item, type: .book)
                        tagsBook.setTags(tags);
                        tagsBook.document = document
                        totalTagItems.append(tagsBook)
                    }

                    let tagsPage = await document.fetchTagsPages(shelfItem: item, selectedTag: selectedTag)
                    totalTagItems.append(contentsOf: tagsPage)
                    _ = await document.close(completionHandler: nil)
                }
            } catch {
                cacheLog(.error, error, destinationURL.lastPathComponent)
            }
        }
        cacheLog(.success, totalTagItems.count)
        let result = FTShelfTagsResult(tagsItems: totalTagItems)
        return result
    }

     func fetchOnlyTaggedNotebooks(selectedTags: [String], shelfItems: [FTShelfItemProtocol], progress: Progress) async throws -> FTShelfTagsResult {
         if selectedTags.isEmpty {
             debugLog("Programmer error")
             return FTShelfTagsResult(tagsItems: [])
         } else {
             let result = try await self.processTags(reqItems: shelfItems, selectedTags: selectedTags, progress: progress)
             return result
         }
     }

     private func processTags(reqItems: [FTShelfItemProtocol], selectedTags: [String], progress: Progress) async throws -> FTShelfTagsResult {
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
                         var tagsBook = FTShelfTagsItem(shelfItem: item, type: .book)
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
         let result = FTShelfTagsResult(tagsItems: totalTagItems)
         return result
     }
}
