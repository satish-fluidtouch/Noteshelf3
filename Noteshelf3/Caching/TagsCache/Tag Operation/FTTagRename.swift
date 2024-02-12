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
        FTNoteshelfDocumentProvider.shared.disableCloudUpdates()
        let oldName = self.tag.tagName;
        let newName = self.newTitle;
        FTTagsProvider.shared.renameTag(self.tag, to: newName);
        let progress = self.enumerateDocuments(Array(tag.documentIDs)) { (documentID, document, token, onTaskCompletion) in
            document.renameTag(oldName, with: newName)
            FTNoteshelfDocumentManager.shared.saveAndClose(document: document, token: token) { _ in
                onTaskCompletion();
            }
        } onCompletion: {
            FTNoteshelfDocumentProvider.shared.enableCloudUpdates()
            onCompletion?();
        }
        return progress;
    }
}
