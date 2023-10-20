//
//  FTMetadataPropertiesPlist.swift
//  Noteshelf3
//
//  Created by Akshay on 20/10/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTDocumentFramework

class FTMetadataPropertiesPlist: FTFileItemPlist {
    var isTagsModified: Bool = false
    
    override func saveContentsOfFileItem() -> Bool {
        let isSaved = super.saveContentsOfFileItem()
        self.isTagsModified = false
        return isSaved
    }
}
