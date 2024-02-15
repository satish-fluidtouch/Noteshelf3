//
//  FTTagUpdateTagEntities.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 07/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTTagUpdateTagEntities: FTTagOperation {
    private var addedTags: [FTTagModel];
    private var removedTags: [FTTagModel];
    private var taggedEntities: [FTTaggedEntity];
    
    required init(_ addedTags: [FTTagModel]
         , removedTags: [FTTagModel]
         , entities: [FTTaggedEntity]) {
        self.addedTags = addedTags;
        self.removedTags = removedTags;
        self.taggedEntities = entities;
    }
    
    override func perfomAction(_ onCompletion: (()->())?) -> Progress? {
        var tagGrouped = [String: [FTTaggedEntity]] ();
        var tags = Set<FTTag>();
        self.taggedEntities.forEach { eachEntity in
            var item = tagGrouped[eachEntity.documentUUID] ?? [FTTaggedEntity]();
            item.append(eachEntity);
            tagGrouped[eachEntity.documentUUID] = item;
            tags = tags.union(Set(eachEntity.tags));
        }
        let keys = tagGrouped.map({$0.key});
        
        let progress = self.enumerateDocuments(keys) { (documentID, document, token, onTaskCompletion) in
            let docPages =  document.pages()
            let taggedEntities = tagGrouped[documentID] ?? [FTTaggedEntity]();
            taggedEntities.forEach { eachItem in
                if eachItem.tagType == .book {
                    self.addedTags.forEach { eachTag in
                        document.addTag(eachTag.text)
                    }
                    document.removeTags(self.removedTags.map{$0.text})
                } else if eachItem.tagType == .page
                            , let pageUUOD = (eachItem as? FTPageTaggedEntity)?.pageUUID {
                    if let page = docPages.first(where: {$0.uuid == pageUUOD}) as? FTPageTagsProtocol {
                        self.addedTags.forEach { eachTag in
                            page.addTag(eachTag.text)
                        }
                        self.removedTags.forEach { eachTag in
                            page.removeTag(eachTag.text);
                        }
                    }
                }
            }
            FTTagsProvider.shared.syncTagWithDocument(document);
            FTNoteshelfDocumentManager.shared.saveAndClose(document: document, token: token) { _ in
                let tagsToAdd = FTTagsProvider.shared.getTagsfor(self.addedTags.map{$0.text},shouldCreate: true);
                let tagsToRemove = FTTagsProvider.shared.getTagsfor(self.removedTags.map{$0.text},shouldCreate: false);
                self.taggedEntities.forEach { eachEntity in
                    tagsToAdd.forEach { eachTag in
                        eachTag.addTaggedItem(eachEntity);
                    }
                    tagsToRemove.forEach { eachTag in
                        eachTag.removeTaggedItem(eachEntity);
                    }
                }
                FTTagsProvider.shared.saveCache();
                onTaskCompletion();
            }
        } onCompletion: {
            self.taggedEntities.forEach { eachEntity in
                tags = tags.union(eachEntity.tags);
            }
            if !tags.isEmpty {
                NotificationCenter.default.post(name: Notification.Name("DidChangePageEntities")
                                                , object: nil
                                                , userInfo: ["tags" : Array(tags)]);
            }
            onCompletion?();
        }
        progress.totalUnitCount = Int64(keys.count);
        return progress;
    }
    
}
