//
//  FTTagUpdateNotebook.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 07/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTTagUpdateNotebook: FTTagOperation {
    private var addedTags: [FTTagModel];
    private var removedTags: [FTTagModel];
    private var documentItems: [FTDocumentItemProtocol];
    
    required init(_ addedTags: [FTTagModel]
         , removedTags: [FTTagModel]
         , documentItems docItems: [FTDocumentItemProtocol]) {
        self.addedTags = addedTags;
        self.removedTags = removedTags;
        self.documentItems = docItems;
    }
    
    override func perfomAction(_ onCompletion: (()->())?) -> Progress? {
        var updatedTags = Set<FTTag>();
        let progress = self.enumerateDocumentItems(self.documentItems) { documentID, document, docItem, token, onTaskCompletion in
            self.addedTags.forEach { eachTag in
                document.addTag(eachTag.text);
            }
            document.removeTags(self.removedTags.map{$0.text})
            FTTagsProvider.shared.syncTagWithDocument(document, documentItem: docItem);
            FTNoteshelfDocumentManager.shared.saveAndClose(document: document, token: token) { _ in
                let tagsToAdd = FTTagsProvider.shared.getTagsfor(self.addedTags.map{$0.text},shouldCreate: true);
                let tagsToRemove = FTTagsProvider.shared.getTagsfor(self.removedTags.map{$0.text},shouldCreate: false);

                tagsToAdd.forEach { eachTag in
                    if let taggedEntity = FTTagsProvider.shared.tagggedEntity(documentID
                                                                              , docuemntItem: docItem
                                                                              , createIfNotPresent: true) {
                        eachTag.addTaggedItem(taggedEntity);
                        updatedTags = updatedTags.union(taggedEntity.tags);
                    }
                }
                tagsToRemove.forEach { eachTag in
                    if let taggedEntity = FTTagsProvider.shared.tagggedEntity(documentID
                                                                                , docuemntItem: docItem) {
                        eachTag.removeTaggedItem(taggedEntity);
                        updatedTags = updatedTags.union(taggedEntity.tags);
                    }
                }
                FTTagsProvider.shared.saveCache();
                onTaskCompletion();
            }
        } onCompletion: {
            if !updatedTags.isEmpty {
                NotificationCenter.default.post(name: Notification.Name("DidChangePageEntities")
                                                , object: nil
                                                , userInfo: ["tags" : Array(updatedTags)]);
            }
            onCompletion?();
        }
        return progress;
    }
}
