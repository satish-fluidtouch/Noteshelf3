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
    let id: UUID = UUID()
    let tag: FTTagModel
    var documentIds : [String]
    private var shelfTagItems: [FTShelfTagsItem]

    init(tag: FTTagModel, documentIds : [String] = [], shelfItems: [FTShelfTagsItem] = []) {
        self.tag = tag
        self.documentIds = documentIds
        self.shelfTagItems = shelfItems
    }

    func updateDocumentIds(docIds: [String]) {
        self.documentIds = docIds
    }

    func getTaggedItems(completion: @escaping ([FTShelfTagsItem]) -> Void) {
        if FTTagsProvider.shared.getAllTags().count > 0 {
            let shelfTagDocIds = shelfTagItems.map({$0.documentUUID!})
            if shelfTagItems.count > 0 && self.documentIds.allSatisfy(shelfTagDocIds.contains(_:)) {
                completion(shelfTagItems)
            } else {
                taggedItemsFor(selectedTag: self.tag.text) { [weak self] shelftagItems in
                    self?.shelfTagItems = shelftagItems
                    completion(shelftagItems)
                }
            }
        } else {
            completion(shelfTagItems)
        }
    }

    func updateShelfTagItems(items: [FTShelfTagsItem]) {
        self.shelfTagItems = items
        let docIds = items.compactMap({$0.documentUUID})
        self.documentIds = Array(Set(docIds))
    }

    func removeDocumentId(docId: String) {
        self.documentIds.removeAll(where: {$0 == docId})
        self.shelfTagItems.removeAll(where: {$0.documentUUID == docId})
        self.shelfTagItems.forEach { shelfTagItem in
            if docId == shelfTagItem.documentUUID {
                if shelfTagItem.type == .page, let pageUUID = shelfTagItem.pageUUID {
                    FTTagsProvider.shared.shelfTagsItems.removeValue(forKey: "\(docId)_\(pageUUID)")
                } else {
                    FTTagsProvider.shared.shelfTagsItems.removeValue(forKey: docId)
                }
            }
        }
    }

    func updateTagForShelfTagItem(shelfTagItems: [FTShelfTagsItem], completion: @escaping ([FTShelfTagsItem]) -> Void) {
        self.getTaggedItems { [weak self] items in
            guard let self = self else { return }
            var taggedItems = items

            shelfTagItems.forEach { shelfTagItem in
                if let documentItem = shelfTagItem.documentItem {
                    var index: Int? = nil
                    var item: FTShelfTagsItem? = nil
                    if shelfTagItem.type == .page {
                         index = items.firstIndex(where: {$0.pageUUID == shelfTagItem.pageUUID && $0.type == .page})
                         item = FTTagsProvider.shared.shelfTagsItemForPage(documentItem: documentItem, pageUUID: shelfTagItem.pageUUID!, tags: shelfTagItem.tags.map({$0.text}))
                        item?.pdfKitPageRect = shelfTagItem.pdfKitPageRect
                        item?.pageIndex = shelfTagItem.pageIndex
                    } else {
                        let existingDocTags = FTCacheTagsProcessor.shared.documentTagsFor(documentUUID: documentItem.documentUUID)
                        index = taggedItems.firstIndex(where: {$0.documentUUID == documentItem.documentUUID && $0.type == .book})
                        item = FTTagsProvider.shared.shelfTagsItemForBook(documentItem: documentItem, tags: existingDocTags)
                    }
                    if self.tag.isSelected {
                        item?.tags.append(self.tag)
                    } else {
                        if let removeIndex = item?.tags.firstIndex(where: {$0.text == self.tag.text}) {
                            item?.tags.remove(at: removeIndex)
                        }
                    }
                    if let _itemIndex = index, let item {
                        taggedItems[_itemIndex] = item
                    } else if let item {
                        taggedItems.append(item)
                    }
                }
        }
            self.updateShelfTagItems(items: taggedItems)
            completion(taggedItems)
        }
    }

    func updateTagForPages(documentItem: FTDocumentItemProtocol, pages: [FTThumbnailable], completion: @escaping ([FTShelfTagsItem]) -> Void) {
        self.getTaggedItems { [weak self] items in
            guard let self = self else { return }
            var taggedItems = items
            pages.forEach({ page in
                let index = items.firstIndex(where: {$0.pageUUID == page.uuid && $0.type == .page})
                let item = FTTagsProvider.shared.shelfTagsItemForPage(documentItem: documentItem, pageUUID: page.uuid, tags: page.tags())
                item.pdfKitPageRect = page.pdfPageRect
                item.pageIndex = page.pageIndex()
                if self.tag.isSelected {
                    item.tags.append(self.tag)
                } else {
                    if let removeIndex = item.tags.firstIndex(where: {$0.text == self.tag.text}) {
                        item.tags.remove(at: removeIndex)
                    }
                }
                if let _itemIndex = index {
                    taggedItems[_itemIndex] = item
                } else {
                    taggedItems.append(item)
                }
            })
            self.updateShelfTagItems(items: taggedItems)
            completion(taggedItems)
        }
    }

    func updateTagForBooks(documentItems: [FTDocumentItemProtocol], completion: @escaping ([FTShelfTagsItem]) -> Void) {
        self.getTaggedItems { [weak self] items in
            guard let self = self else { return }
            var taggedItems = items
            documentItems.forEach { documentItem in
                let existingDocTags = FTCacheTagsProcessor.shared.documentTagsFor(documentUUID: documentItem.documentUUID)
                let item = FTTagsProvider.shared.shelfTagsItemForBook(documentItem: documentItem, tags: existingDocTags)
                let itemIndex = taggedItems.firstIndex(where: {$0.documentUUID == documentItem.documentUUID && $0.type == .book})

                if self.tag.isSelected {
                    item.tags.append(self.tag)
                } else {
                    if let removeIndex = item.tags.firstIndex(where: {$0.text == self.tag.text}) {
                        item.tags.remove(at: removeIndex)
                    }
                }
                if let _itemIndex = itemIndex  {
                        taggedItems[_itemIndex].tags = item.tags
                } else {
                    taggedItems.append(item)
                }
            }

            self.updateShelfTagItems(items: taggedItems)
            completion(taggedItems)
        }
    }

    func deleteTagItem() {
        for item in shelfTagItems {
            if let index = item.tags.firstIndex(where: {$0.text == self.tag.text}) {
                item.tags.remove(at: index)
            }
        }

        var allTags = FTTagsProvider.shared.getAllTags()
        if let existingItemIndex = allTags.firstIndex(where: {$0.tag.text == self.tag.text}) {
            allTags.remove(at: existingItemIndex)
        }
        FTTagsProvider.shared.updateAllTagsWith(updatedTags: allTags)
    }

    func renameTagItemWith(renamedString: String) {
        self.tag.text = renamedString
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
                guard let docUUID = item.documentUUID else { continue }
                let tags = FTCacheTagsProcessor.shared.documentTagsFor(documentUUID: docUUID)
                if tags.count > 0 {
                    func generateShelfTagItem() {
                        let tagsBook = FTTagsProvider.shared.shelfTagsItemForBook(documentItem: item, tags: tags)
                        totalTagItems.append(tagsBook)
                    }
                    if selectedTag.isEmpty {
                        generateShelfTagItem()
                    } else if tags.contains(selectedTag) {
                        generateShelfTagItem()
                    }
                }
                FTCacheTagsProcessor.shared.cachedDocumentPlistFor(documentUUID: docUUID) { docPlist, error in
                    let pages = docPlist?.pages
                    var tagsPages: [FTShelfTagsItem] = [FTShelfTagsItem]()
                    pages?.forEach { page in
                        let tags = page.tags
                        if tags.count > 0 {
                            func generateShelfTagItem() {
                                let tagsPage = FTTagsProvider.shared.shelfTagsItemForPage(documentItem: item, pageUUID: page.uuid, tags: tags)
                                tagsPage.pdfKitPageRect = page.pageRect
                                if let index = pages?.firstIndex(where: {$0.uuid == page.uuid}) {
                                    tagsPage.pageIndex = index
                                }
                                tagsPages.append(tagsPage)
                            }
                            if selectedTag.isEmpty {
                                generateShelfTagItem()
                            } else if tags.contains(selectedTag) {
                                generateShelfTagItem()
                            }
                        }
                    }
                    totalTagItems.append(contentsOf: tagsPages)
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.notify(queue: .main) {
                completion(totalTagItems)
            }
            cacheLog(.info, "totalTagItems", totalTagItems.count)
        }

    }

}

class FTTagsProvider {
    static let shared = FTTagsProvider()
    private var allTags = [FTTagItemModel]()

    var shelfTagsItems = Dictionary<String, FTShelfTagsItem>()

    @discardableResult
    func getAllTags(forceUpdate: Bool = false) -> [FTTagItemModel] {
        if allTags.isEmpty || forceUpdate {
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

    func addNewTagItemIfNeeded(tagItem: FTTagItemModel) {
        var alltagItems = allTags
        if alltagItems.count == 0 {
            alltagItems = self.getAllTags()
        }
        let index = alltagItems.firstIndex(where: {$0.tag.text == tagItem.tag.text})
        if index == nil {
            allTags.append(tagItem)
            runInMainThread {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshSideMenu"), object: nil, userInfo: ["tag": tagItem.tag.text, "type": "add", "renamedTag": ""])
            }
        }
    }

    func removeDocumentId(docId: String) {
        allTags.forEach { tagItemModel in
            tagItemModel.removeDocumentId(docId: docId)
        }
    }

    func shelfTagsItemForBook(documentItem: FTDocumentItemProtocol, tags: [String]) -> FTShelfTagsItem {
        if let docUUID = documentItem.documentUUID {
            if let shelfTagItem  = self.shelfTagsItems[docUUID] {
                return shelfTagItem
            } else {
                let tagsBook = FTShelfTagsItem(documentItem: documentItem, documentUUID: docUUID, type: .book)
                tagsBook.setTags(Array(Set(tags)))
                self.shelfTagsItems[docUUID] = tagsBook
                return tagsBook
            }
        }
        return  FTShelfTagsItem(documentItem: documentItem, documentUUID: documentItem.documentUUID, type: .book)
    }

    func shelfTagsItemForPage(documentItem: FTDocumentItemProtocol, pageUUID: String, tags: [String]) -> FTShelfTagsItem {
        if let docUUID = documentItem.documentUUID {
            if let shelfTagItem  = self.shelfTagsItems["\(docUUID)_\(pageUUID)"] {
                return shelfTagItem
            } else {
                let tagsPage = FTShelfTagsItem(documentItem: documentItem, documentUUID: docUUID, type: .page)
                tagsPage.pageUUID = pageUUID
                tagsPage.documentUUID = docUUID
                tagsPage.setTags(Array(Set(tags)))
                self.shelfTagsItems["\(docUUID)_\(pageUUID)"] = tagsPage
                return tagsPage

            }
        }
        return FTShelfTagsItem(documentItem: documentItem, documentUUID: documentItem.documentUUID, type: .page)
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
