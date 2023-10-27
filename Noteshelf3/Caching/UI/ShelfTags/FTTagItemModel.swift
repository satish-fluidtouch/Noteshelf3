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

    private var loadingCallbacks = [(([FTShelfTagsItem]) -> Void)]();
    
    init(tag: FTTagModel, documentIds : [String] = [], shelfItems: [FTShelfTagsItem] = []) {
        self.tag = tag
        self.documentIds = documentIds
        self.shelfTagItems = shelfItems
    }

    func updateDocumentIds(docIds: [String]) {
        self.documentIds = docIds
    }

    private var isLoading = false;
    func getTaggedItems(completion: @escaping ([FTShelfTagsItem]) -> Void) {
        loadingCallbacks.append(completion);
        if isLoading {
            debugLog("loading is in progress: \(self.tag.text)");
            return;
        }
        isLoading = true;
        func callCallbacks() {
            runInMainThread {
                self.loadingCallbacks.forEach { eachCallback in
                    eachCallback(self.shelfTagItems);
                }
                self.loadingCallbacks.removeAll();
                self.isLoading = false;
            }
        }
        
        FTTagsProvider.shared.getAllTags { [weak self] allTags in
            guard let self = self else {
                callCallbacks();
                return
            }
            if allTags.count > 0 {
                if self.tag.text.isEmpty {
                    DispatchQueue.global().async {
                        let group = DispatchGroup();
                        var shelfTaggeditems = Set<FTShelfTagsItem>();
                        allTags.forEach { eachTag in
                            group.enter();
                            eachTag.getTaggedItems { items in
                                shelfTaggeditems.formUnion(Set(items));
                                group.leave();
                            }
                        }
                        group.notify(queue: DispatchQueue.main) {
                            self.shelfTagItems = Array(shelfTaggeditems);
                            callCallbacks();
                        }
                    }
                    return;
                }
                
                let shelfTagDocIds = Set(self.shelfTagItems.map({$0.documentUUID!}));
                let currentIDS = Set(self.documentIds);
                
                if self.shelfTagItems.count > 0 && currentIDS == shelfTagDocIds {
                    callCallbacks();
                } else {
                    self.taggedItemsFor(selectedTag: self.tag.text, allTags: allTags) { [weak self] shelftagItems in
                        self?.shelfTagItems = shelftagItems
                        callCallbacks();
                    }
                }
            } else {
                callCallbacks();
            }
        }

    }

    private func updateShelfTagItems(items: [FTShelfTagsItem]) {
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
        var returnItems = [FTShelfTagsItem]()

        self.getTaggedItems { [weak self] items in
            guard let self = self else {
                completion(returnItems)
                return
            }
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
                        index = taggedItems.firstIndex(where: {$0.documentUUID == documentItem.documentUUID && $0.type == .book})
                        item = FTTagsProvider.shared.shelfTagsItemForBook(documentItem: documentItem)
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
                    returnItems.append(item!)
                }
        }
            self.updateShelfTagItems(items: taggedItems)
            completion(returnItems)
        }
    }

    func updateTagForPages(documentItem: FTDocumentItemProtocol, pages: [FTThumbnailable], completion: @escaping ([FTShelfTagsItem]) -> Void) {
        var returnItems = [FTShelfTagsItem]()

        self.getTaggedItems { [weak self] items in
            guard let self = self else {
                completion(returnItems)
                return
            }
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
                returnItems.append(item)
            })
            self.updateShelfTagItems(items: taggedItems)
            completion(returnItems)
        }
    }

    func updateTagForBooks(documentItems: [FTDocumentItemProtocol], completion: @escaping ([FTShelfTagsItem]) -> Void) {
        var returnItems = [FTShelfTagsItem]()
        self.getTaggedItems { [weak self] items in
            guard let self = self else { 
                completion(returnItems)
                return
            }
            var taggedItems = items
            documentItems.forEach { documentItem in
                let item = FTTagsProvider.shared.shelfTagsItemForBook(documentItem: documentItem)
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
                returnItems.append(item)
            }

            self.updateShelfTagItems(items: taggedItems)
            completion(returnItems)
        }
    }

    func deleteTagItem() {
        for item in shelfTagItems {
            if let index = item.tags.firstIndex(where: {$0.text == self.tag.text}) {
                item.tags.remove(at: index)
            }
        }

        FTTagsProvider.shared.getAllTags { allTags in
            var _allTags = allTags
            if let existingItemIndex = allTags.firstIndex(where: {$0.tag.text == self.tag.text}) {
                _allTags.remove(at: existingItemIndex)
            }
            FTTagsProvider.shared.updateAllTagsWith(updatedTags: _allTags)
        }
    }

    func renameTagItemWith(renamedString: String) {
        self.tag.text = renamedString
    }

    private func taggedItemsFor(selectedTag: String, allTags: [FTTagItemModel], completion: @escaping ([FTShelfTagsItem]) -> Void)  {
        let dispatchGroup = DispatchGroup()
        var totalTagItems: [FTShelfTagsItem] = [FTShelfTagsItem]()
        FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection.shelfItems(FTShelfSortOrder.none, parent: nil, searchKey: nil) { allItems in
            DispatchQueue.global(qos: .background).async {
                let items: [FTDocumentItemProtocol] = allItems.compactMap({ $0 as? FTDocumentItemProtocol }).filter({ $0.isDownloaded })

                var docIds = [String]()
                if !selectedTag.isEmpty {
                    docIds = self.documentIds
                } else {
                    let returnDocids = allTags.compactMap { $0.documentIds }.joined()
                    docIds = Array(Set(returnDocids))
                }

                let filteredDocuments = items.filter { item in
                    return docIds.contains(item.documentUUID ?? "")
                }
                for case let item in filteredDocuments where item.documentUUID != nil {
                    dispatchGroup.enter()
                    guard let docUUID = item.documentUUID else { continue }
                    let tagsBook = FTTagsProvider.shared.shelfTagsItemForBook(documentItem: item)
                    tagsBook.documentItem = item
                    if !tagsBook.tags.isEmpty {
                        totalTagItems.append(tagsBook)
                    }

                    FTCacheTagsProcessor.shared.cachedDocumentPlistFor(documentUUID: docUUID) { docPlist in
                        let pages = docPlist?.pages
                        var tagsPages: [FTShelfTagsItem] = [FTShelfTagsItem]()
                        pages?.forEach { page in
                            let tags = page.tags
                            if tags.count > 0 {
                                func generateShelfTagItem() {
                                    let tagsPage = FTTagsProvider.shared.shelfTagsItemForPage(documentItem: item, pageUUID: page.uuid, tags: tags)
                                    tagsPage.documentItem = item
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

}

class FTTagsProvider {
    static let shared = FTTagsProvider()
    private var allTags = [FTTagItemModel]()

    var shelfTagsItems = Dictionary<String, FTShelfTagsItem>()

    private func getPlistTags(completion: @escaping ([FTTagItemModel]) -> Void) {
        var allTags = [FTTagItemModel]()
        FTCacheTagsProcessor.shared.tagsPlist { plistTags in
            plistTags.forEach { (key, value) in
                if let ids = value as? [String], ids.isEmpty {
                    plistTags.removeObject(forKey: key)
                } else if let tagName = key as? String, let ids = value as? [String] {
                    if let tagItem = FTTagsProvider.shared.getTagItemFor(tagName: tagName) {
                        tagItem.updateDocumentIds(docIds: ids)
                        allTags.append(tagItem)
                    } else {
                        allTags.append(FTTagItemModel(tag: FTTagModel(text: tagName), documentIds: ids))
                    }
                }
            }
            runInMainThread {
                completion(allTags)
            }
        }
    }

    func getAllTags(completion: (([FTTagItemModel]) -> Void)? = nil) {
        if allTags.isEmpty  {
            loadAllTagsFromPlist { [weak self] allTags in
                guard let self = self else {
                    completion?(allTags)
                    return
                }
                self.allTags = allTags
                completion?(allTags)
            }
        } else {
            completion?(allTags)
        }
    }

    func updateTags() {
        loadAllTagsFromPlist { _ in
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshSideMenu"), object: nil)
        }
    }

    private func loadAllTagsFromPlist(completion: (([FTTagItemModel]) -> Void)? = nil) {
        self.getPlistTags(completion: { [weak self]allTags in
            guard let self = self else {
                completion?(allTags)
                return
            }
            self.allTags = allTags
            completion?(allTags)
        })
    }

    func getAllSortedTags(completion: @escaping ([FTTagItemModel]) -> Void) {
        self.getAllTags { tags in
            let sortedArray = tags.sorted(by: { $0.tag.text.localizedCaseInsensitiveCompare($1.tag.text) == .orderedAscending })
            completion(sortedArray)
        }
    }

    func updateAllTagsWith(updatedTags: [FTTagItemModel]) {
        let sortedArray = updatedTags.sorted(by: { $0.tag.text.localizedCaseInsensitiveCompare($1.tag.text) == .orderedAscending })
        self.allTags = sortedArray
    }

    func getAllTagItemsFor(_ tagNames:[String]) -> [FTTagItemModel] {
        var tagToReturn = [FTTagItemModel]()
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
        allTags.forEach { eachItem in
            if tagNames.contains(eachItem.tag.text) {
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
        if allTags.count == 0 {
             self.getAllTags(completion: { alltagItems in
                 let index = alltagItems.firstIndex(where: {$0.tag.text == tagItem.tag.text})
                 if index == nil {
                     self.allTags.append(tagItem)
                     runInMainThread {
                         NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshSideMenu"), object: nil, userInfo: ["tag": tagItem.tag.text, "type": "add", "renamedTag": ""])
                     }
                 }
            })
        }
    }

    func removeDocumentId(docId: String) {
        allTags.forEach { tagItemModel in
            tagItemModel.removeDocumentId(docId: docId)
        }
    }

    func shelfTagsItemForBook(documentItem: FTDocumentItemProtocol) -> FTShelfTagsItem {
        if let docUUID = documentItem.documentUUID {
            if let shelfTagItem  = self.tagItem(docUUID) {
                return shelfTagItem
            } else {
                let tagsBook = FTShelfTagsItem(documentItem: documentItem, documentUUID: docUUID, type: .book)
                let tags = FTCacheTagsProcessor.shared.documentTagsFor(documentUUID: docUUID)
                tagsBook.setTags(Array(Set(tags)))
                self.setTagItem(tagsBook, for: docUUID);
                return tagsBook
            }
        }
        return FTShelfTagsItem(documentItem: documentItem, documentUUID: documentItem.documentUUID, type: .book)
    }

    private func tagItem(_ uuid: String) -> FTShelfTagsItem? {
        objc_sync_enter(self.shelfTagsItems);
        let shelfTagItem  = self.shelfTagsItems[uuid]
        objc_sync_exit(self.shelfTagsItems);
        return shelfTagItem;
    }
    
    private func setTagItem(_ item: FTShelfTagsItem, for uuid: String) {
        objc_sync_enter(self.shelfTagsItems);
        self.shelfTagsItems[uuid] = item
        objc_sync_exit(self.shelfTagsItems);
    }
    
    func shelfTagsItemForPage(documentItem: FTDocumentItemProtocol, pageUUID: String, tags: [String]) -> FTShelfTagsItem {
        if let docUUID = documentItem.documentUUID {
            if let shelfTagItem  = self.tagItem("\(docUUID)_\(pageUUID)") {
                return shelfTagItem
            } else {
                let tagsPage = FTShelfTagsItem(documentItem: documentItem, documentUUID: docUUID, type: .page)
                tagsPage.pageUUID = pageUUID
                tagsPage.documentUUID = docUUID
                tagsPage.setTags(Array(Set(tags)))
                self.setTagItem(tagsPage, for: "\(docUUID)_\(pageUUID)")
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
