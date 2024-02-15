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
        let progress = self.enumerateDocuments(Array(self.tag.documentIDs)) { (documentID, document, token, onTaskCompletion) in
            document.deleteTags([self.tag.tagName])
            FTTagsProvider.shared.syncTagWithDocument(document);
            FTNoteshelfDocumentManager.shared.saveAndClose(document: document, token: token) { _ in
                self.tag.removeDocumentID(documentID);
                onTaskCompletion();
            }
        } onCompletion: {
            FTTagsProvider.shared.deleteTags([self.tag]);
            onCompletion?()
        }
        return progress;
    }
}
