//
//  FTTagDelete.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 16/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTTagDelete: NSObject {
    var tag: FTTag;
    init(tag: FTTag) {
        self.tag = tag;
    }

    func perfomAction(_ onCompletion: ((_ success: Bool)->())?) -> Progress? {
        let progress = Progress();
        progress.totalUnitCount = 1;
        self.tag.documents { documentItems in
            progress.totalUnitCount = Int64(documentItems.count);
            progress.completedUnitCount += 1;
            guard documentItems.isEmpty else {
                FTTagsProviderV1.shared.deleteTags([self.tag]);
                onCompletion?(false);
                return;
            }

            var filteredDocuments = documentItems;
            func performDeleteOperation(_ onCompletion: @escaping ()->()) {
                guard !filteredDocuments.isEmpty else {
                    onCompletion();
                    return;
                }
                
                let doc = filteredDocuments.removeFirst();
                let request = FTDocumentOpenRequest(url: doc.URL, purpose: .write)
                FTNoteshelfDocumentManager.shared.openDocument(request: request) { token, document, error in
                    if let document = document as? FTNoteshelfDocument {
                        document.deleteTags([self.tag.tagName])
                        FTNoteshelfDocumentManager.shared.saveAndClose(document: document, token: token) { _ in
                            progress.completedUnitCount += 1
                            performDeleteOperation(onCompletion);
                        }
                    }
                    else {
                        progress.completedUnitCount += 1
                        performDeleteOperation(onCompletion);
                    }
                }
            }

            FTNoteshelfDocumentProvider.shared.disableCloudUpdates();
            performDeleteOperation {
                FTTagsProviderV1.shared.deleteTags([self.tag]);
                FTNoteshelfDocumentProvider.shared.enableCloudUpdates();
                onCompletion?(true)
            }
        }
        return progress;
    }
}
