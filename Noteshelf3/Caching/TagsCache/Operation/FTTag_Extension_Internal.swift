//
//  FTTag_Extension_Internal.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 16/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

internal extension FTTag {
    func documents(_ onCompletion: @escaping (([FTDocumentItemProtocol])->())) {
        FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection.shelfItems(FTShelfSortOrder.none
                                                                                  , parent: nil
                                                                                  , searchKey: nil) { allItems in
            let items: [FTDocumentItemProtocol] = allItems.compactMap({ $0 as? FTDocumentItemProtocol }).filter({ $0.isDownloaded && !$0.isPinEnabledForDocument()})
            
            let filteredDocuments = items.filter { item in
                if let docId = item.documentUUID {
                    return self.documentIDs.contains(docId);
                }
                return false;
            }
            onCompletion(filteredDocuments);
        }
    }
}

extension FTNoteshelfDocumentProvider {
    func document(with docID: String
                  , orRelativePath: String? = nil
                  , bypassPasswordProtected : Bool = true
                  , onCompletion: @escaping ((FTDocumentItemProtocol?)->())) {
        self.allNotesShelfItemCollection.shelfItems(.none
                                                    , parent: nil
                                                    , searchKey: nil) { items in
            var itemToreturn: FTDocumentItemProtocol?
            for eachItem in items {
                if let docItem = eachItem as? FTDocumentItemProtocol {
                    if docItem.isDownloaded, docItem.documentUUID == docID {
                        itemToreturn = docItem;
                        break;
                    }
                    else if docItem.URL.relativePathWRTCollection() == orRelativePath {
                        itemToreturn = docItem;
                    }
                }
            }
            if let docItem = itemToreturn, docItem.isPinEnabledForDocument(), !bypassPasswordProtected {
                itemToreturn = nil;
            }
            onCompletion(itemToreturn);
        }
    }
}
