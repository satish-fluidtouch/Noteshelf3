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
    private var documentIDs: [String];
    
    required init(_ addedTags: [FTTagModel]
         , removedTags: [FTTagModel]
         , docIDs: [String]) {
        self.addedTags = addedTags;
        self.removedTags = removedTags;
        self.documentIDs = docIDs;
    }
    
    override func perfomAction(_ onCompletion: (()->())?) -> Progress? {
        var updatedTags = Set<FTTag>();
        let progress = self.enumerateDocuments(self.documentIDs) { documentID, document, token, onTaskCompletion in
            self.addedTags.forEach { eachTag in
                document.addTag(eachTag.text);
            }
            document.removeTags(self.removedTags.map{$0.text})
            FTTagsProvider.shared.syncTagWithDocument(document);
            FTNoteshelfDocumentManager.shared.saveAndClose(document: document, token: token) { _ in
                let tagsToAdd = FTTagsProvider.shared.getTagsfor(self.addedTags.map{$0.text},shouldCreate: true);
                let tagsToRemove = FTTagsProvider.shared.getTagsfor(self.removedTags.map{$0.text},shouldCreate: false);

                let docName = document.URL.relativePathWRTCollection()
                tagsToAdd.forEach { eachTag in
                    if let taggedEntity = FTTagsProvider.shared.tagggedEntity(documentID
                                                                              , documentPath: docName
                                                                              , createIfNotPresent: true) {
                        eachTag.addTaggedItem(taggedEntity);
                        updatedTags = updatedTags.union(taggedEntity.tags);
                    }
                }
                tagsToRemove.forEach { eachTag in
                    if let taggedEntity = FTTagsProvider.shared.tagggedEntity(documentID
                                                                                , documentPath: docName) {
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
