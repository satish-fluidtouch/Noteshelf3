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
    
    override func getTaggedEntities(_ onCompletion: (([FTTaggedEntity]) -> ())?) {
        let tags = FTTagsProviderV1.shared.getTags();
        var items = Set<FTTaggedEntity>();
        tags.forEach { eachtag in
            eachtag.getTaggedEntities { eachEntity in
                let newSet = Set(eachEntity);
                items.formUnion(newSet);
            }
        }
        onCompletion?(Array(items));
    }
}
