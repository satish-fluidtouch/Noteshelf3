//
//  FTPageTaggedEntity.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 11/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTPageTaggedEntity: FTTaggedEntity {
    var pageUUID: String;
    var pageIndex: Int;
    
    required init(documentUUID: String
                  , documentName: String?
                  , pageUUID: String
                  , pageIndex: Int) {
        self.pageUUID = pageUUID
        self.pageIndex = pageIndex
        super.init(documentUUID: documentUUID,documentName: documentName);
    }
    
    override var tagUpdateNotification: Notification.Name? {
        return Notification.Name(rawValue: "Tag_Updated_\(documentUUID)_\(pageUUID)");
    }
    
    override var hash: Int {
        return self.documentUUID.appending(self.pageUUID).hashKey.hash;
    }
    
    override var description: String {
        return super.description+">>"+self.documentUUID+"_"+self.pageUUID;
    }
}
