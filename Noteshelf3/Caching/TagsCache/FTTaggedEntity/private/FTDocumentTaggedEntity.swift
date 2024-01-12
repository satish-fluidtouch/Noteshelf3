//
//  FTDocumentTaggedEntity.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 11/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTDocumentTaggedEntity: FTTaggedEntity {    
    override var tagUpdateNotification: Notification.Name? {
        return Notification.Name(rawValue: "Tag_Updated_\(documentUUID)");
    }
    
    override var description: String {
        return super.description+">>"+self.documentUUID
    }
}
