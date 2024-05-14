//
//  FTDocumentStorageOptimize.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 14/05/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTDocumentStorageOptimize: NSObject {
    func optimizeDocument(at sourceURL: URL, onCompletion: @escaping (Error?)->()) {
        guard let document = FTDocumentFactory.documentForItemAtURL(sourceURL) as? FTNoteshelfDocument else {
            let err = NSError(domain: "com.fluidtouch.optmize", code: 101, userInfo: [NSLocalizedDescriptionKey: "Failed to create document instance"]);
            onCompletion(err);
            return;
        }
        document.openDocument(purpose: .writeOptimize) { success, error in
            if let _error = error {
                onCompletion(_error);
                return;
            }
            document.pages().forEach { eachpage in
                (eachpage as? FTNoteshelfPage)?.sqliteFileItem()?.forceSave = true;
            }
            document.propertyInfoPlist()?.setObject("10.1", forKey: DOCUMENT_VERSION_KEY)
            document.saveDocument { success in
                document.closeDocument { closed in
                    if success {
                        onCompletion(nil);
                    }
                    else {
                        let err = NSError(domain: "com.fluidtouch.optmize", code: 102, userInfo: [NSLocalizedDescriptionKey: "Failed to save optimized document"]);
                        onCompletion(err);
                    }
                }
            }
        }
    }
}
