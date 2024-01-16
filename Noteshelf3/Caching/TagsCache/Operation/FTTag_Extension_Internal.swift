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

