//
//  FTENSyncItemInfo.swift
//  Noteshelf
//
//  Created by Siva on 17/06/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

struct FTENSyncItemInfo {
    var id: String!
    
    var dictionaryRepresentation: [String: Any] {
        return [
            "id" : id,
        ];
    }
    
    init(documentItem: FTDocumentItemProtocol) {
        self.id = documentItem.documentUUID!;
    }
    
    init(documentID: String!) {
        self.id = documentID;
    }
}
