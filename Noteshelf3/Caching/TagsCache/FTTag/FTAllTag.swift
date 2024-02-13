//
//  FTAllTag.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 10/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTAllTag: FTTag {
    private var loadState: FTDataLoadState = .notLoaded;
    private var completionBlocks = [FTTagCompletionHandler]();
    
    override var tagType: FTTagType  {
        .allTag;
    }

    override var tagDisplayName: String {
        return "sidebar.allTags".localized;
    }
    
    override func getTaggedEntities(sort: Bool,_ onCompletion: FTTagCompletionHandler?) {
        guard !loadState.isLoaded else {
            return;
        }
        if let block = onCompletion {
            completionBlocks.append(block);
        }
        guard !loadState.isLoading else {
            return;
        }
        loadState = .loading;
        var tags = FTTagsProvider.shared.getTags();
        var items = Set<FTTaggedEntity>();
        
        func loadTagsRecursively() {
            guard !tags.isEmpty else {
                var itemsToReturn = Array(items);
                itemsToReturn = (sort ? itemsToReturn.sortedTaggedEntities() : itemsToReturn);
                self.completionBlocks.forEach { eachbloack in
                    eachbloack(itemsToReturn,self);
                }
                self.loadState = .notLoaded;
                return
            }
            let firstTag = tags.removeFirst();
            firstTag.getTaggedEntities(sort: false) { (taggedEntities,tag) in
                let newSet = Set(taggedEntities);
                items.formUnion(newSet);
                loadTagsRecursively();
            }
        }
        
        loadTagsRecursively();
    }
}
