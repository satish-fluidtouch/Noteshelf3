//
//  FTTagRename.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 16/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTTagRename: FTTagOperation {
    var newTitle: String;
    var tag: FTTag;

    init(tag: FTTag,newTitle: String) {
        self.newTitle = newTitle;
        self.tag = tag;
    }
    
    override func perfomAction(_ onCompletion: (()->())?) -> Progress? {
        let oldName = self.tag.tagName;
        let newName = self.newTitle;
        guard oldName.compare(newName, options: [.caseInsensitive,.numeric], range: nil, locale: nil) != .orderedSame else {
            FTTagsProvider.shared.renameTag(self.tag, to: newName);
            onCompletion?();
            return nil;
        }
        FTTagsProvider.shared.renameTag(self.tag, to: newName);
        let progress = self.enumerateDocuments(Array(tag.documentIDs)) { (documentID, document, token, onTaskCompletion) in
            document.renameTag(oldName, with: newName)
            FTTagsProvider.shared.syncTagWithDocument(document);
            FTNoteshelfDocumentManager.shared.saveAndClose(document: document, token: token) { _ in
                onTaskCompletion();
            }
        } onCompletion: {
            onCompletion?();
        }
        return progress;
    }
}
