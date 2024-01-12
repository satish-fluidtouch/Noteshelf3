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
    override func isEqual(_ object: Any?) -> Bool {
        guard let otherObj = object as? FTTag else {
            return false;
        }
        return (self.tagName.caseInsensitiveCompare(otherObj.tagName) == .orderedSame)
    }
    
    override var description: String {
        return super.description + " :"+self.tagName;
    }
    
    override var hash: Int {
        return tagName.lowercased().hashKey.hashValue;
    }
    
    var id = UUID().uuidString;
    private(set) var tagName: String;
    private(set) var documentIDs = Set<String>();
    private(set) var taggedEntitties = [FTTaggedEntity]();
    private var isLoaded = false;
    
    required init(name: String) {
        tagName = name;
    }
    
    func addDocumentID(_ documentID: String) {
        self.documentIDs.insert(documentID);
    }
    
    convenience init(name: String, documentUUIDs: [String]) {
        self.init(name: name);
        self.documentIDs = Set(documentUUIDs)
    }
    
    var tagType: FTTagType {
        .userTag;
    }
    
    var tagDisplayName: String {
        return self.tagName;
    }
    
    func setTagName(_ newName: String) {
        self.tagName = newName;
    }
    
    func documentTaggedEntity(_ documentID: String) -> FTTaggedEntity? {
        let item = self.taggedEntitties.first { eachItem in
            if let item = eachItem as? FTDocumentTaggedEntity, item.documentUUID == documentID {
                return true;
            }
            return false;
        }
        return item;
    }

    func pageTaggedEntity(_ documentID: String,pageUUID: String) -> FTTaggedEntity? {
        let item = self.taggedEntitties.first { eachItem in
            if let item = eachItem as? FTPageTaggedEntity
                , item.documentUUID == documentID
                ,item.pageUUID == pageUUID {
                return true;
            }
            return false;
        }
        return item;
    }

    func addTaggedItemIfNeeded(_ item: FTTaggedEntity) {
        if isLoaded {
            self.addTaggedItem(item)
        }
        self.documentIDs.insert(item.documentUUID)
    }
    
    private func addTaggedItem(_ item: FTTaggedEntity) {
        self.taggedEntitties.append(item);
        item.addTag(self);
        self.documentIDs.insert(item.documentUUID)
    }
    
    func removeTaggedItem(_ item: FTTaggedEntity) {
        guard let index = self.taggedEntitties.firstIndex(of: item) else {
            return;
        }
        item.removeTag(self);
        self.taggedEntitties.remove(at: index);
    }

    func markAsDeleted() {
        self.taggedEntitties.forEach { eachItem in
            eachItem.removeTag(self);
        }
    }
    
    func getTaggedEntities(_ onCompletion: (([FTTaggedEntity])->())?) {
        guard !isLoaded else {
            onCompletion?(self.taggedEntitties);
            return;
        }
        self.documentIDs.forEach { eachDocument in
            let lowercasedTag = self.tagName.lowercased();

            let doc = FTCachedDocument(documentID: eachDocument);
            let documentName = doc.documentName
            let docuemntTags = doc.docuemntTags
            
            if docuemntTags.contains(where: {$0.lowercased() == lowercasedTag}) {
                let item = FTDocumentTaggedEntity(documentUUID: eachDocument,documentName: documentName);
                self.addTaggedItem(item)
            }

            let pages = doc.pages;
            for eachPage in pages {
                if eachPage.tags().contains(where: {$0.lowercased() == lowercasedTag}) {
                    let item = FTPageTaggedEntity(documentUUID: eachDocument
                                                  , documentName: documentName
                                                  , pageUUID: eachPage.uuid
                                                  , pageIndex: 0);
                    self.addTaggedItem(item)
                }
            }
        }
        isLoaded = true;
        onCompletion?(self.taggedEntitties);
    }
}
