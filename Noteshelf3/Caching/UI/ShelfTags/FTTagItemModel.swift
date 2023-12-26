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
    private var documentIds : [String]
    private let tagModelLock = NSRecursiveLock();
    
    private var shelfTagItems: [FTShelfTagsItem]
    private var loadingCallbacks = [(([FTShelfTagsItem]) -> Void)]();
    
    init(tag: FTTagModel, documentIds : [String] = [], shelfItems: [FTShelfTagsItem] = []) {
        self.tag = tag
        self.documentIds = documentIds
        self.shelfTagItems = shelfItems
    }

    func setDocumentIds(docIds: [String]) {
        tagModelLock.lock();
        self.documentIds = docIds
        tagModelLock.unlock();
    }

    func getShelfTagItems() -> [FTShelfTagsItem] {
        let items: [FTShelfTagsItem]
        tagModelLock.lock();
        let sortedShelfTagItems = self.shelfTagItems.sorted { (item1, item2) -> Bool in
            if let title1 = item1.documentItem?.displayTitle, let title2 = item2.documentItem?.displayTitle {
                if title1 != title2 {
                    return title1 < title2
                }
            }
            return item1.pageIndex < item2.pageIndex
        }

        items = sortedShelfTagItems;
        tagModelLock.unlock();
        return items;
    }
    
    func setShelfTagItems(items: [FTShelfTagsItem]) {
        tagModelLock.lock();
        self.shelfTagItems = items;
        tagModelLock.unlock();
    }
    
    func getDocumentIDS() -> [String] {
        let ids: [String]
        tagModelLock.lock();
        ids = self.documentIds;
        tagModelLock.unlock();
        return ids;
    }
    
    private func fetchAllTags(_ tags: [FTTagItemModel]
                              ,fetchedItems: Set<FTShelfTagsItem>
                              ,onCompletion: @escaping (([FTShelfTagsItem]) -> ())) {
        DispatchQueue.global().async {
            var shelfTaggeditems = fetchedItems;
            var currentTags = tags;
            if !currentTags.isEmpty {
                let tag = currentTags.removeFirst();
                tag.getTaggedItems { items in
                    shelfTaggeditems.formUnion(Set(items));
                    self.fetchAllTags(currentTags, fetchedItems: shelfTaggeditems, onCompletion: onCompletion);
                }
            }
            else {
                onCompletion(Array(shelfTaggeditems));
            }
        }
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
                    eachCallback(self.getShelfTagItems());
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
                    let shelfTaggeditems = Set<FTShelfTagsItem>();
                    self.fetchAllTags(allTags, fetchedItems: shelfTaggeditems) { items in
                        self.setShelfTagItems(items: Array(Set(items)));
                        callCallbacks();
                    }
                    return;
                }
                
                let _shelfTagItems = self.getShelfTagItems();
                let shelfTagDocIds = Set(_shelfTagItems.map({$0.documentUUID!}));
                let currentIDS = Set(self.getDocumentIDS());
                
                if _shelfTagItems.count > 0 && currentIDS == shelfTagDocIds {
                    callCallbacks();
                } else {
                    self.taggedItemsFor(selectedTag: self.tag.text, allTags: allTags) { [weak self] shelftagItems in
                        self?.setShelfTagItems(items: shelftagItems)
                        callCallbacks();
                    }
                }
            } else {
                callCallbacks();
            }
        }

    }

    private func updateShelfTagItems(items: [FTShelfTagsItem]) {
        self.setShelfTagItems(items: items);
        let docIds = items.compactMap({$0.documentUUID})
        self.setDocumentIds(docIds: Array(Set(docIds)));
    }

    func removeDocumentId(docId: String) {
        tagModelLock.lock();
        self.documentIds.removeAll(where: {$0 == docId})
        self.shelfTagItems.removeAll(where: {$0.documentUUID == docId})
        self.shelfTagItems.forEach { shelfTagItem in
            if docId == shelfTagItem.documentUUID {
                if shelfTagItem.type == .page, let pageUUID = shelfTagItem.pageUUID {
                    FTTagsProvider.shared.removeTag("\(docId)_\(pageUUID)");
                } else {
                    FTTagsProvider.shared.removeTag(docId);
                }
            }
        }
        tagModelLock.unlock();
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
        tagModelLock.lock();
        for item in shelfTagItems {
            if let index = item.tags.firstIndex(where: {$0.text == self.tag.text}) {
                item.tags.remove(at: index)
            }
        }
        tagModelLock.unlock();

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
        FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection.shelfItems(FTShelfSortOrder.none, parent: nil, searchKey: nil) { allItems in
            DispatchQueue.global(qos: .background).async {
                var totalTagItems: [FTShelfTagsItem] = [FTShelfTagsItem]()
                let items: [FTDocumentItemProtocol] = allItems.compactMap({ $0 as? FTDocumentItemProtocol }).filter({ $0.isDownloaded })

                var docIds = [String]()
                if !selectedTag.isEmpty {
                    docIds = self.getDocumentIDS()
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
    private let allTagsLock = NSRecursiveLock();
    private let shelfTagLock = NSRecursiveLock();
    private let callbackLock = NSRecursiveLock();
    private var callBacks = [(([FTTagItemModel]) -> Void)]();

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
                        debugLog("existing tag item");
                        tagItem.setDocumentIds(docIds: ids)
                        allTags.append(tagItem)
                    } else {
                        allTags.append(FTTagItemModel(tag: FTTagModel(text: tagName), documentIds: ids))
                    }
                }
            }
            completion(allTags)
        }
    }

    func getAllTags(completion: (([FTTagItemModel]) -> Void)? = nil) {
        let _allTags = self.getTags();
        if _allTags.isEmpty  {
            loadAllTagsFromPlist { allTags in
                completion?(allTags)
            }
        } else {
            completion?(_allTags)
        }
    }

    func updateTags() {
        loadAllTagsFromPlist { _ in
            runInMainThread {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshSideMenu"), object: nil)
            }
        }
    }
        
    private func loadAllTagsFromPlist(completion: (([FTTagItemModel]) -> Void)? = nil) {
        self.callbackLock.lock();
        let shouldFetch = self.callBacks.isEmpty;
        if let callback = completion {
            self.callBacks.append(callback);
        }
        self.callbackLock.unlock();
        if shouldFetch {
            self.getPlistTags(completion: { [weak self] allTags in
                self?.setAllTags(allTags);
                self?.callbackLock.lock();
                self?.callBacks.forEach({ eachCallback in
                    eachCallback(allTags);
                })
                self?.callBacks.removeAll();
                self?.callbackLock.unlock();
            })
        }
    }

    func getAllSortedTags(completion: @escaping ([FTTagItemModel]) -> Void) {
        self.getAllTags { tags in
            let sortedArray = tags.sorted(by: { $0.tag.text.localizedCaseInsensitiveCompare($1.tag.text) == .orderedAscending })
            runInMainThread {
                completion(sortedArray)
            }
        }
    }

    func updateAllTagsWith(updatedTags: [FTTagItemModel]) {
        let sortedArray = updatedTags.sorted(by: { $0.tag.text.localizedCaseInsensitiveCompare($1.tag.text) == .orderedAscending })
        self.setAllTags(sortedArray);
    }

    func getAllTagItemsFor(_ tagNames:[String]) -> [FTTagItemModel] {
        var tagToReturn = [FTTagItemModel]()
        let _allTags = getTags();
        _allTags.forEach { eachItem in
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
        let _allTags = self.getTags();
        _allTags.forEach { eachItem in
            if tagNames.contains(eachItem.tag.text) {
                tagToReturn.append(eachItem)
            }
        }
        return tagToReturn;
    }

    func addTag(tagName: String) -> FTTagItemModel {
       let tagItem = FTTagItemModel(tag: FTTagModel(text: tagName))
        tagItem.tag.isSelected = true
        self.addTagItem(tagItem);
        return tagItem
    }

    func deleteTagItem(tagItem: FTTagItemModel) {
        allTagsLock.lock();
        self.allTags.removeAll { tag in
            tag.tag.text == tagItem.tag.text
        }
        allTagsLock.unlock();
    }

    func getTagItemFor(tagName: String) -> FTTagItemModel? {
        let _allTags = getTags();
        var returnTag = _allTags.filter {$0.tag.text == tagName}.first
        if returnTag == nil {
            returnTag = FTTagItemModel(tag: FTTagModel(text: tagName))
        }
        return returnTag
    }

    func addNewTagItemIfNeeded(tagItem: FTTagItemModel) {
        let _allTags = getTags();
        if _allTags.count == 0 {
             self.getAllTags(completion: { alltagItems in
                 let index = alltagItems.firstIndex(where: {$0.tag.text == tagItem.tag.text})
                 if index == nil {
                     self.addTagItem(tagItem);
                     runInMainThread {
                         NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshSideMenu"), object: nil, userInfo: ["tag": tagItem.tag.text, "type": "add", "renamedTag": ""])
                     }
                 }
            })
        }
    }

    func removeDocumentId(docId: String) {
        allTagsLock.lock();
        allTags.forEach { tagItemModel in
            tagItemModel.removeDocumentId(docId: docId)
        }
        allTagsLock.unlock();
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

extension FTTagsProvider {
    func setAllTags(_ tags: [FTTagItemModel]) {
        self.allTagsLock.lock();
        self.allTags = tags;
        self.allTagsLock.unlock();
    }
    
    func getTags() -> [FTTagItemModel] {
        let tagsToReturn: [FTTagItemModel];
        self.allTagsLock.lock();
        tagsToReturn = self.allTags;
        self.allTagsLock.unlock();
        return tagsToReturn;
    }
    
    func addTagItem(_ item: FTTagItemModel) {
        self.allTagsLock.lock();
        self.allTags.append(item);
        self.allTagsLock.unlock();
    }
}

extension FTTagsProvider {
    fileprivate func removeTag(_ uuid: String) {
        self.shelfTagLock.lock();
        self.shelfTagsItems.removeValue(forKey: uuid)
        self.shelfTagLock.unlock();
    }
    
    private func tagItem(_ uuid: String) -> FTShelfTagsItem? {
        self.shelfTagLock.lock();
        let shelfTagItem  = self.shelfTagsItems[uuid]
        self.shelfTagLock.unlock();
        return shelfTagItem;
    }
    
    private func setTagItem(_ item: FTShelfTagsItem, for uuid: String) {
        self.shelfTagLock.lock();
        self.shelfTagsItems[uuid] = item
        self.shelfTagLock.unlock();
    }
}
