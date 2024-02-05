//
//  FTTagRename.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 16/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTTagRename: NSObject {
    var newTitle: String;
    var tag: FTTag;

    init(tag: FTTag,newTitle: String) {
        self.newTitle = newTitle;
        self.tag = tag;
    }
    
    func perfomAction(_ onCompletion: ((Bool) -> ())?) -> Progress? {
        let progress = Progress();
        progress.totalUnitCount = 1;

        self.tag.documents { items in
            progress.totalUnitCount += Int64(items.count);
            progress.completedUnitCount += 1
            guard !items.isEmpty else {
                FTTagsProvider.shared.renameTag(self.tag, to: self.newTitle);
                onCompletion?(false);
                return;
            }
            
            var filteredDocuments = items;
            func performRenameOperation(_ onCompletion: @escaping ()->()) {
                guard !filteredDocuments.isEmpty else {
                    onCompletion();
                    return;
                }
                let doc = filteredDocuments.removeFirst();
                let request = FTDocumentOpenRequest(url: doc.URL, purpose: .write)
                FTNoteshelfDocumentManager.shared.openDocument(request: request) { token, document, error in
                    if let document = document as? FTNoteshelfDocument {
                        document.renameTag(self.tag.tagName, with: self.newTitle)
                        FTNoteshelfDocumentManager.shared.saveAndClose(document: document, token: token) { _ in
                            progress.completedUnitCount += 1
                            performRenameOperation(onCompletion);
                        }
                    }
                    else {
                        progress.completedUnitCount += 1
                        performRenameOperation(onCompletion);
                    }
                }
            }
            FTNoteshelfDocumentProvider.shared.disableCloudUpdates();
            performRenameOperation {
                FTTagsProvider.shared.renameTag(self.tag, to: self.newTitle);
                FTNoteshelfDocumentProvider.shared.enableCloudUpdates();
                onCompletion?(true)
            };
        }
        return progress;
    }
}
