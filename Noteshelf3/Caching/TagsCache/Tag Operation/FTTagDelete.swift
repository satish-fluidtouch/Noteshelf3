//
//  FTTagDelete.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 16/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTTagDelete: FTTagOperation {
    var tag: FTTag;
    init(tag: FTTag) {
        self.tag = tag;
    }

    override func perfomAction(_ onCompletion: (()->())?) -> Progress? {
        var updatedTags : Set<FTTag>?;
        let progress = self.enumerateDocuments(Array(self.tag.documentIDs)) { (documentID, document, docItem, token, onTaskCompletion) in
            document.deleteTags([self.tag.tagName])
            updatedTags = FTTagsProvider.shared.syncTagWithDocument(document,documentItem: docItem);
            FTNoteshelfDocumentManager.shared.saveAndClose(document: document, token: token) { _ in
                self.tag.removeDocumentID(documentID);
                onTaskCompletion();
            }
        } onCompletion: {
            FTTagsProvider.shared.deleteTags([self.tag]);
            if let tag = updatedTags, !tag.isEmpty {
                NotificationCenter.default.post(name: Notification.Name("DidChangePageEntities")
                                                , object: nil
                                                , userInfo: ["tags" : Array(tag)]);
            }
            onCompletion?()
        }
        return progress;
    }
}
