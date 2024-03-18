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
        let t1 = Date.timeIntervalSinceReferenceDate
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
        
        func loadTagsRecursively(_ shelfItems: [FTShelfItemProtocol]) {
            guard !tags.isEmpty else {
                var itemsToReturn = Array(items);
                itemsToReturn = (sort ? itemsToReturn.sortedTaggedEntities() : itemsToReturn);
                self.completionBlocks.forEach { eachbloack in
                    eachbloack(itemsToReturn,self);
                }
                let t2 = Date.timeIntervalSinceReferenceDate
                debugPrint("Time Takeb: \(t2-t1)")
                self.loadState = .notLoaded;
                return
            }
            let firstTag = tags.removeFirst();
            
            firstTag._taggedEntities(shelfItems, sort: false) { _taggedEntities, tag in
                let newSet = Set(_taggedEntities);
                items.formUnion(newSet);
                loadTagsRecursively(shelfItems);
            }
        }
        
        FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection.shelfItems(.none, parent: nil, searchKey: nil) { shelfItems in
            self.tagQueue.async {
                loadTagsRecursively(shelfItems);
            }
        }
    }
}
