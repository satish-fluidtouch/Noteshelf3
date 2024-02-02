//
//  FTAllTag.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 10/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTAllTag: FTTag {
    override var tagType: FTTagType  {
        .allTag;
    }

    override var tagDisplayName: String {
        return "sidebar.allTags".localized;
    }
    
    override func getTaggedEntities(sort: Bool,_ onCompletion: (([FTTaggedEntity])->())?) {
        let tags = FTTagsProviderV1.shared.getTags();
        var items = Set<FTTaggedEntity>();
        tags.forEach { eachtag in
            eachtag.getTaggedEntities(sort: false, { taggedEntities in
                let newSet = Set(taggedEntities);
                items.formUnion(newSet);
            })
        }
        let itemsToReturn = Array(items);
        onCompletion?(sort ? itemsToReturn.sortedTaggedEntities() : itemsToReturn);
    }
}
