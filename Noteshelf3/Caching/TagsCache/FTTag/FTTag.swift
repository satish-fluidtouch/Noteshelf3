//
//  FTTag.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 10/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

enum FTTagType: Int {
    case userTag,allTag;
}

enum FTDataLoadState: Int {
    case notLoaded, loading, loaded
    
    var isLoaded: Bool {
        return self == .loaded;
    }
    var isLoading: Bool {
        return self == .loaded;
    }
}

typealias FTTagCompletionHandler = ([FTTaggedEntity], FTTag)->();

class FTTag: NSObject {
    let tagQueue = DispatchQueue(label: "com.fluidtouch.tagprocess", qos: .background);
    private var lock = NSRecursiveLock();
    override func isEqual(_ object: Any?) -> Bool {
        guard let otherObj = object as? FTTag else {
            return false;
        }
        return (self.tagName.localizedCaseInsensitiveCompare(otherObj.tagName) == .orderedSame)
    }
    
    override var description: String {
        return super.description + ">>" + self.tagName;
    }
    
    override var hash: Int {
        return tagName.lowercased().hashValue;
    }
    
    private(set) var id = UUID().uuidString;
    @objc dynamic private(set) var tagName: String
    private(set) var documentIDs = Set<String>();
    private(set) var taggedEntitties = [FTTaggedEntity]();
    
    private var _loadState: FTDataLoadState = .notLoaded;
    private var loadState: FTDataLoadState {
        set {
            self.lockSelf();
            self._loadState = newValue;
            self.unlockSelf();
        }
        get {
            self.lockSelf();
            let state = _loadState;
            self.unlockSelf();
            return state;
        }
    }
    
    private var completionBlocks = [FTTagCompletionHandler]();
    
    required init(name: String) {
        tagName = name;
    }
    
    func addDocumentID(_ documentID: String) {
        self.lockSelf();
        self.documentIDs.insert(documentID);
        self.unlockSelf();
    }
    
    func removeDocumentID(_ documentID: String) {
        self.lockSelf()
        self.documentIDs.remove(documentID)
        self.taggedEntitties.removeAll { eachItem in
            if eachItem.documentUUID == documentID {
                eachItem.removeTag(self);
                return true;
            }
            return false;
        }
        self.unlockSelf()
    }

    convenience init(name: String, documentUUIDs: [String]) {
        self.init(name: name);
        self.documentIDs = Set(documentUUIDs)
    }
    
    var tagType: FTTagType {
        .userTag;
    }
    
    var tagDisplayName: String {
        self.lockSelf()
        let name = self.tagName;
        self.unlockSelf()
        return name;
    }
    
    func setTagName(_ newName: String) {
        self.lockSelf()
        self.tagName = newName;
        self.unlockSelf()
    }
    
    func documentTaggedEntity(_ documentID: String) -> FTTaggedEntity? {
        self.lockSelf()
        let item = self.taggedEntitties.first { eachItem in
            if let item = eachItem as? FTDocumentTaggedEntity, item.documentUUID == documentID {
                return true;
            }
            return false;
        }
        self.unlockSelf()
        return item;
    }

    func pageTaggedEntity(_ documentID: String,pageUUID: String) -> FTTaggedEntity? {
        self.lockSelf()
        let item = self.taggedEntitties.first { eachItem in
            if let item = eachItem as? FTPageTaggedEntity
                , item.documentUUID == documentID
                ,item.pageUUID == pageUUID {
                return true;
            }
            return false;
        }
        self.unlockSelf()
        return item;
    }

    func addTaggedItem(_ item: FTTaggedEntity) {
        self.addTaggedItemIfNeeded(item,forceAdd: false)
    }
    
    private func addTaggedItemIfNeeded(_ item: FTTaggedEntity,forceAdd: Bool) {
        self.lockSelf()
        if (self.loadState == .loaded || forceAdd)
            ,!self.taggedEntitties.contains(item) {
            self.taggedEntitties.append(item);
        }
        item.addTag(self);
        self.addDocumentID(item.documentUUID);
        self.unlockSelf()
    }
    
    func removeTaggedItem(_ item: FTTaggedEntity) {
        self.lockSelf()
        guard let index = self.taggedEntitties.firstIndex(of: item) else {
            item.removeTag(self);
            self.unlockSelf()
            return;
        }
        self.taggedEntitties.remove(at: index);
        item.removeTag(self);
        self.unlockSelf()
    }

    func markAsDeleted() {
        self.lockSelf()
        self.taggedEntitties.forEach { eachItem in
            eachItem.removeTag(self);
        }
        self.unlockSelf()
    }
    
    func getTaggedEntities(sort: Bool,_ onCompletion: FTTagCompletionHandler?) {
        if self.loadState == .loaded {
            self.lockSelf()
            let items = sort ? self.taggedEntitties.sortedTaggedEntities() : self.taggedEntitties;
            self.unlockSelf()
            onCompletion?(items,self);
            return;
        }
        
        self.lockSelf()
        if let block = onCompletion {
            self.completionBlocks.append(block);
        }
        let idsToProcess = self.documentIDs;
        let _tagName = self.tagName;
        self.unlockSelf()
        
        if self.loadState == .loading {
            return;
        }
        self.loadState = .loading;

        FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection.shelfItems(.none, parent: .none, searchKey: nil) { shelfItems in
            self.tagQueue.async {
                let validIds = self.validateDocumentItem(documentIDs: idsToProcess, shelfItems: shelfItems);
                validIds.forEach { eachDocument in
                    self.processDocument(for: _tagName, documentID: eachDocument);
                }
                self.lockSelf()
                if self.documentIDs.count != validIds.count {
                    debugLog("docID not same tag: \(self.tagName) >> \(self.documentIDs)  >> \(validIds)");
                }
                self.documentIDs = validIds;
                self.loadState = .loaded;
                let items = sort ? self.taggedEntitties.sortedTaggedEntities() : self.taggedEntitties;
                let blockToCalle = self.completionBlocks;
                self.completionBlocks.removeAll();
                self.unlockSelf()
                blockToCalle.forEach { eachBlock in
                    eachBlock(items,self);
                }
            }
        }
    }
}

private extension FTTag {
    func lockSelf() {
        lock.lock()
    }
    
    func unlockSelf() {
        lock.unlock()
    }
}

private extension FTTag {
    func validateDocumentItem(documentIDs: Set<String>, shelfItems:[FTShelfItemProtocol]) -> Set<String> {
        var validIds = Set<String>();
        var relativePaths = [String:String]()
        documentIDs.forEach { eachItem in
            let doc = FTCachedDocument(documentID: eachItem);
            if let documentName = doc.relativePath {
                relativePaths[documentName] = eachItem;
            }
        }
        
        shelfItems.forEach { eachitem in
            if let docItem = eachitem as? FTDocumentItemProtocol {
                let relativePath = docItem.URL.relativePathWRTCollection();
                if docItem.isDownloaded
                    , let docId = docItem.documentUUID
                    , documentIDs.contains(docId) {
                    validIds.insert(docId);
                }
                else if relativePaths.keys.contains(relativePath), let docID = relativePaths[relativePath] {
                    validIds.insert(docID);
                }
            }
        }
        return validIds;
    }
    
    func processDocument(for tagName: String, documentID:String) {
        let lowercasedTag = tagName.lowercased();
        
        let doc = FTCachedDocument(documentID: documentID);
        let documentName = doc.relativePath
        let docuemntTags = doc.documentTags()
        
        if docuemntTags.contains(where: {$0.lowercased() == lowercasedTag}) {
            if let taggedItem = FTTagsProvider.shared.tagggedEntity(documentID
                                                                    , documentPath: documentName
                                                                    , createIfNotPresent: true) {
                let tags = FTTagsProvider.shared.getTagsfor(docuemntTags,shouldCreate: false);
                tags.forEach { eachItem in
                    eachItem.addTaggedItemIfNeeded(taggedItem,forceAdd: eachItem == self)
                }
            }
        }
        
        let pages = doc.pages();
        pages.enumerated().forEach { eachItem in
            let eachPage = eachItem.element;
            let index = eachItem.offset;
            if let tagPage = eachPage as? FTPageTagsProtocol
                , tagPage.tags().contains(where: {$0.lowercased() == lowercasedTag}) {
                let pageProperties = FTTaggedPageProperties();
                pageProperties.pageSize = eachPage.pdfPageRect;
                pageProperties.pageIndex = index;
                
                if let pageEntity = FTTagsProvider.shared.tagggedEntity(documentID
                                                                        , documentPath: documentName
                                                                        , pageID: eachPage.uuid
                                                                        , createIfNotPresent: true) as? FTPageTaggedEntity {
                    pageEntity.updatePageProties(pageProperties);
                    let tags = FTTagsProvider.shared.getTagsfor(tagPage.tags(),shouldCreate: false);
                    tags.forEach { eachItem in
                        eachItem.addTaggedItemIfNeeded(pageEntity,forceAdd: eachItem == self)
                    }
                }
            }
        }
    }
}
