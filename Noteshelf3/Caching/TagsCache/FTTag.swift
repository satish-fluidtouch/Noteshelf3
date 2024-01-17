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

class FTTag: NSObject {
    private var lock = NSRecursiveLock();
    private var tagHash: Int = 0;
    override func isEqual(_ object: Any?) -> Bool {
        guard let otherObj = object as? FTTag else {
            return false;
        }
        return (self.tagName.localizedCaseInsensitiveCompare(otherObj.tagName) == .orderedSame)
    }
    
    override var description: String {
        return super.description + " :"+self.tagName;
    }
    
    override var hash: Int {
        return tagName.lowercased().hashValue;
    }
    
    private(set) var id = UUID().uuidString;
    @objc dynamic private(set) var tagName: String
    private(set) var documentIDs = Set<String>();
    private(set) var taggedEntitties = [FTTaggedEntity]();
    private var isLoaded = false;
    
    required init(name: String) {
        tagName = name;
    }
    
    func addDocumentID(_ documentID: String) {
        lock.lock()
        self.documentIDs.insert(documentID);
        lock.unlock()
    }
    
    func removeDocumentID(_ documentID: String) {
        lock.lock()
        self.documentIDs.remove(documentID)
        lock.unlock()
    }

    convenience init(name: String, documentUUIDs: [String]) {
        self.init(name: name);
        self.documentIDs = Set(documentUUIDs)
    }
    
    var tagType: FTTagType {
        .userTag;
    }
    
    var tagDisplayName: String {
        lock.lock()
        let name = self.tagName;
        lock.unlock()
        return name;
    }
    
    func setTagName(_ newName: String) {
        lock.lock()
        self.tagName = newName;
        lock.unlock()
    }
    
    func documentTaggedEntity(_ documentID: String) -> FTTaggedEntity? {
        lock.lock()
        let item = self.taggedEntitties.first { eachItem in
            if let item = eachItem as? FTDocumentTaggedEntity, item.documentUUID == documentID {
                return true;
            }
            return false;
        }
        lock.unlock()
        return item;
    }

    func pageTaggedEntity(_ documentID: String,pageUUID: String) -> FTTaggedEntity? {
        lock.lock()
        let item = self.taggedEntitties.first { eachItem in
            if let item = eachItem as? FTPageTaggedEntity
                , item.documentUUID == documentID
                ,item.pageUUID == pageUUID {
                return true;
            }
            return false;
        }
        lock.unlock()
        return item;
    }

    func addTaggedItem(_ item: FTTaggedEntity) {
        self.addTaggedItemIfNeeded(item,forceAdd: false)
    }
    
    private func addTaggedItemIfNeeded(_ item: FTTaggedEntity,forceAdd: Bool) {
        lock.lock()
        if (isLoaded || forceAdd)
            , nil == self.taggedEntitties.firstIndex(of: item) {
            self.taggedEntitties.append(item);
        }
        item.addTag(self);
        self.addDocumentID(item.documentUUID);
        lock.unlock()
    }
    
    func removeTaggedItem(_ item: FTTaggedEntity) {
        lock.lock()
        guard let index = self.taggedEntitties.firstIndex(of: item) else {
            item.removeTag(self);
            lock.unlock()
            return;
        }
        self.taggedEntitties.remove(at: index);
        item.removeTag(self);
        lock.unlock()
    }

    func markAsDeleted() {
        lock.lock()
        self.taggedEntitties.forEach { eachItem in
            eachItem.removeTag(self);
        }
        lock.unlock()
    }
    
    func getTaggedEntities(_ onCompletion: (([FTTaggedEntity])->())?) {
        lock.lock()
        guard !isLoaded else {
            onCompletion?(self.taggedEntitties);
            lock.unlock()
            return;
        }
        self.documentIDs.forEach { eachDocument in
            let lowercasedTag = self.tagName.lowercased();

            let doc = FTCachedDocument(documentID: eachDocument);
            let documentName = doc.documentName
            let docuemntTags = doc.docuemntTags
            
            if docuemntTags.contains(where: {$0.lowercased() == lowercasedTag}) {
                let item = FTDocumentTaggedEntity(documentUUID: eachDocument,documentName: documentName);
                let tags = FTTagsProviderV1.shared.getTagsfor(docuemntTags);
                tags.forEach { eachItem in
                    eachItem.addTaggedItemIfNeeded(item,forceAdd: true)
                }
            }

            let pages = doc.pages;
            pages.enumerated().forEach { eachItem in
                let eachPage = eachItem.element;
                let index = eachItem.offset;
                if eachPage.tags().contains(where: {$0.lowercased() == lowercasedTag}) {
                    let pageProperties = FTTaggedPageProperties();
                    pageProperties.pageSize = eachPage.pdfPageRect;
                    pageProperties.pageIndex = index;
                    let item = FTPageTaggedEntity(documentUUID: eachDocument
                                                  , documentName: documentName
                                                  , pageUUID: eachPage.uuid
                                                  , pageProperties: pageProperties);
                    let tags = FTTagsProviderV1.shared.getTagsfor(eachPage.tags());
                    tags.forEach { eachItem in
                        eachItem.addTaggedItemIfNeeded(item,forceAdd: true)
                    }
                }
            }
        }
        isLoaded = true;
        onCompletion?(self.taggedEntitties);
        lock.unlock()
    }
}
