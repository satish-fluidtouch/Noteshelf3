//
//  FTTagItemModel.swift
//  Noteshelf3
//
//  Created by Siva on 07/09/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

class FTTagItemModel {
    var id: UUID = UUID()
    var tag: FTTagModel
    var documentIds : [String]
    var renamedTag: FTTagModel?
    private var shelfItems: [FTShelfTagsItem] 
    private var isDeleted: Bool = false

    init(tag: FTTagModel, documentIds : [String] = [], shelfItems: [FTShelfTagsItem] = []) {
        self.tag = tag
        self.documentIds = documentIds
        self.shelfItems = shelfItems
    }

    func getTaggdItems(completion: @escaping ([FTShelfTagsItem]) -> Void) {
        if shelfItems.count > 0 {
            completion(shelfItems)
        } else {
            //load tags item
            taggedItemsFor(selectedTag: self.tag.text, completion: { [weak self] shelftagItems in
                self?.shelfItems = shelftagItems
                completion(shelftagItems)
            })
        }
    }

    func updateShelfItems(items: [FTShelfTagsItem]) {
        self.shelfItems = items
        let docIds = items.compactMap({$0.documentUUID})
        self.documentIds = Array(Set(docIds))
    }

    func updateTagForPage(shelfItem: FTDocumentItemProtocol, page: FTThumbnailable, completion: @escaping (FTShelfTagsItem) -> Void) {
        self.getTaggdItems { [weak self] items in
            guard let self = self else { return }
            var taggedItems = items
            let pageTags = page.tags()
            let item = FTTagsProvider.shared.shelfTagsItemForPage(shelfItem: shelfItem, page: page, tags: pageTags)

            if tag.isSelected {
                item.tags.append(tag)
                (page as? FTNoteshelfPage)?.addTag(tag.text)
            } else {
                if let removeIndex = item.tags.firstIndex(where: {$0.text == self.tag.text}) {
                    item.tags.remove(at: removeIndex)
                    (page as? FTNoteshelfPage)?.removeTag(tag.text)
                }
            }
            if taggedItems.isEmpty {
                taggedItems.append(item)
            }
            self.updateShelfItems(items: taggedItems)
            completion(item)
        }
    }

    func updateTagForBook(shelfItem: FTDocumentItemProtocol, completion: @escaping (FTShelfTagsItem) -> Void) {
        self.getTaggdItems { [weak self] items in
            guard let self = self else { return }
            var taggedItems = items
            let existingDocTags = FTCacheTagsProcessor.shared.documentTagsFor(shelfItem: shelfItem)
            let item = FTTagsProvider.shared.shelfTagsItemForBook(shelfItem: shelfItem, tags: existingDocTags)
            if tag.isSelected {
                item.tags.append(tag)
            } else {
                if let removeIndex = item.tags.firstIndex(where: {$0.text == self.tag.text}) {
                    item.tags.remove(at: removeIndex)
                }
            }
            if taggedItems.isEmpty {
                taggedItems.append(item)
            }
            self.updateShelfItems(items: taggedItems)
            completion(item)

        }
    }

    func removeShelfItems(items: [FTShelfTagsItem]) {
        for newItem in items {
            if let existingItemIndex = shelfItems.firstIndex(where: { $0.documentUUID == newItem.documentUUID }) {
                // An item with the same ID exists, update it
                shelfItems.remove(at: existingItemIndex)
            }
        }
    }

    func deleteTagItem() {
        var allTags = FTTagsProvider.shared.getAllTags()
        if let existingItemIndex = allTags.firstIndex(where: {$0.tag.text == self.tag.text}) {
            allTags.remove(at: existingItemIndex)
        }
        FTTagsProvider.shared.updateAllTagsWith(updatedTags: allTags)
    }

    func renameTagItemWith(renamedString: String) {
        self.tag.text = renamedString
    }

    func getDocumentIdsFor(tag: String) -> [String] {
        let allTags = FTTagsProvider.shared.getAllTags()

        if !tag.isEmpty {
            return allTags
                .filter { $0.tag.text == tag }
                .first?.documentIds ?? []
        } else {
            let returnDocids = allTags.compactMap { $0.documentIds }.joined()
            let ids = Array(Set(returnDocids))
            return ids
        }
    }

    func taggedItemsFor(selectedTag: String, completion: @escaping ([FTShelfTagsItem]) -> Void)  {
        let dispatchGroup = DispatchGroup()
        var totalTagItems: [FTShelfTagsItem] = [FTShelfTagsItem]()
        FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection.shelfItems(FTShelfSortOrder.none, parent: nil, searchKey: nil) { allItems in

            let items: [FTDocumentItemProtocol] = allItems.filter({ ($0.URL.downloadStatus() == .downloaded) }).compactMap({ $0 as? FTDocumentItemProtocol })

            var docIds = [String]()
            if !selectedTag.isEmpty {
                docIds = self.documentIds
            } else {
                let returnDocids = FTTagsProvider.shared.getAllTags().compactMap { $0.documentIds }.joined()
                docIds = Array(Set(returnDocids))
            }

            let filteredDocuments = items.filter { item in
                return docIds.contains(item.documentUUID ?? "")
            }
            for case let item in filteredDocuments where item.documentUUID != nil {
                dispatchGroup.enter()
                guard let docUUID = item.documentUUID else { continue }//, item.URL.downloadStatus() == .downloaded else { continue }
                let destinationURL = FTDocumentCache.shared.cachedLocation(for: docUUID)
                let document = FTNoteshelfDocument(fileURL: destinationURL)
                document.openDocument(purpose: .read) { isOpen, error in
                    if isOpen {
                        let tags = document.documentTags()
                        if tags.count > 0 {
                            func generateShelfTagItem() {
                                let tagsBook = FTTagsProvider.shared.shelfTagsItemForBook(shelfItem: item, tags: tags)
                                tagsBook.documentUUID = document.documentUUID
                                tagsBook.document = document
                                totalTagItems.append(tagsBook)
                            }
                            if selectedTag.isEmpty {
                                generateShelfTagItem()
                            } else if tags.contains(selectedTag) {
                                generateShelfTagItem()
                            }
                        }

                        let tagsPage =  document.fetchTagsPages(shelfItem: item, selectedTag: selectedTag)
                        totalTagItems.append(contentsOf: tagsPage)
                        document.close(completionHandler: nil)
                        dispatchGroup.leave()
                    }
                }
            }
            dispatchGroup.notify(queue: .main) {
                completion(totalTagItems)
            }
            cacheLog(.success, totalTagItems.count)
        }

    }

}

class FTTagsProvider {
    static let shared = FTTagsProvider()
    private var allTags = [FTTagItemModel]()

    var shelfTagsItems = Dictionary<String, FTShelfTagsItem>()

    func getAllTags() -> [FTTagItemModel] {
        if allTags.isEmpty {
            //load
            allTags = FTCacheTagsProcessor.shared.allTags()
        }
        return allTags;
    }

    func getAllSortedTags() -> [FTTagItemModel] {
        let tags = self.getAllTags()
        let sortedArray = tags.sorted(by: { $0.tag.text.localizedCaseInsensitiveCompare($1.tag.text) == .orderedAscending })
        return sortedArray;
    }

    func updateAllTagsWith(updatedTags: [FTTagItemModel]) {
        let sortedArray = updatedTags.sorted(by: { $0.tag.text.localizedCaseInsensitiveCompare($1.tag.text) == .orderedAscending })
        self.allTags = sortedArray
    }

    func getAllTagItemsFor(_ tagNames:[String]) -> [FTTagItemModel] {
        var tagToReturn = [FTTagItemModel]()
        debugPrint(allTags)
        allTags.forEach { eachItem in
            if tagNames.contains(eachItem.tag.text) {
                eachItem.tag.isSelected = true
            } else {
                eachItem.tag.isSelected = false
            }
            tagToReturn.append(eachItem)
        }
        return tagToReturn;
    }

    func getTagItemsFor(_ tagNames:[String]) -> [FTTagItemModel] {
        var tagToReturn = [FTTagItemModel]()
        debugPrint(allTags)
        allTags.forEach { eachItem in
            if tagNames.contains(eachItem.tag.text) {
                tagToReturn.append(eachItem)
            }
        }
        return tagToReturn;
    }

    func getTagItemsWithSelectionEnableFor(_ tagNames:[String]) -> [FTTagItemModel] {
        var tagToReturn = [FTTagItemModel]()
        debugPrint(allTags)
        allTags.forEach { eachItem in
            if tagNames.contains(eachItem.tag.text) {
                eachItem.tag.isSelected = true
                tagToReturn.append(eachItem)
            }
        }
        return tagToReturn;
    }

    func getTagsForDocument(_ documentID: String) -> [FTTagItemModel] {
        var tagToReturn = [FTTagItemModel]()
        allTags.forEach { eachItem in
            let docIds = eachItem.documentIds
            if docIds.contains(documentID) {
                tagToReturn.append(eachItem)
            }
        }
        return tagToReturn;
    }

    func addTag(tagName: String) -> FTTagItemModel {
       let tagItem = FTTagItemModel(tag: FTTagModel(text: tagName))
        tagItem.tag.isSelected = true
        allTags.append(tagItem)
        return tagItem
    }

    func deleteTagItem(tagItem: FTTagItemModel) {
        self.allTags.removeAll { tag in
            tag.tag.text == tagItem.tag.text
        }
    }

    func getTagItemFor(tagName: String) -> FTTagItemModel? {
        var returnTag = allTags.filter {$0.tag.text == tagName}.first
        if returnTag == nil {
            returnTag = FTTagItemModel(tag: FTTagModel(text: tagName))
        }
        return returnTag
    }

    func updateShelfItems(items: [FTShelfTagsItem], tags: [FTTagModel]) {
        allTags.forEach { eachItem in
            if tags.contains(eachItem.tag) {
                eachItem.updateShelfItems(items: items)
            }
        }
    }

    func getTagModelFor(tagNames: [String]) -> [FTTagModel] {
        var returnList: [FTTagModel] = []
        tagNames.forEach { tag in
            let tagItem = FTTagModel(text: tag)
            tagItem.isSelected = true
            returnList.append(tagItem)
        }
        return returnList
    }

    func shelfTagsItemForBook(shelfItem: FTDocumentItemProtocol, tags: [String]) -> FTShelfTagsItem {
        if let docUUID = shelfItem.documentUUID, let shelfTagItem  = self.shelfTagsItems[docUUID] {
            return shelfTagItem
        } else if let docUUID = shelfItem.documentUUID {
            let tagsBook = FTShelfTagsItem(shelfItem: shelfItem, type: .book)
            tagsBook.documentUUID = docUUID
            tagsBook.setTags(Array(Set(tags)))
            self.shelfTagsItems[docUUID] = tagsBook
            return tagsBook
        }
        return  FTShelfTagsItem(shelfItem: shelfItem, type: .book)

    }

    func shelfTagsItemForPage(shelfItem: FTDocumentItemProtocol, page: FTThumbnailable, tags: [String]) -> FTShelfTagsItem {
        if let docUUID = shelfItem.documentUUID, let shelfTagItem  = self.shelfTagsItems["\(docUUID)_\(page.uuid)"] {
            return shelfTagItem
        } else if let docUUID = shelfItem.documentUUID {
            let tagsPage = FTShelfTagsItem(shelfItem: shelfItem, type: .page, page: page, pageIndex: page.pageIndex())
            tagsPage.pageUUID = page.uuid
            tagsPage.documentUUID = shelfItem.documentUUID
            tagsPage.setTags(Array(Set(tags)))
            self.shelfTagsItems["\(docUUID)_\(page.uuid)"] = tagsPage
            return tagsPage

        }
        return FTShelfTagsItem(shelfItem: shelfItem, type: .page)
    }

}
