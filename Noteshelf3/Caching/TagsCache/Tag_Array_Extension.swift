//
//  Tag_Array_Extension.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 02/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

extension Array<FTTag>
{
    func sortedTags() -> Array<FTTag> {
        let sortedItems = self.sorted { tag1, tage2 in
            let compare = tag1.tagName.compare(tage2.tagName, options:[.caseInsensitive,.numeric], range: nil, locale: nil)
            return compare == .orderedAscending
        }
        return sortedItems;
    }
}

extension Array<FTTagModel>
{
    mutating func sortTags() {
        self.sort { tag1, tage2 in
            let compare = tag1.text.compare(tage2.text, options:[.caseInsensitive,.numeric], range: nil, locale: nil)
            return compare == .orderedAscending
        }
    }
    
    func sortedTags() -> Array<FTTagModel> {
        let sortedItems = self.sorted { tag1, tage2 in
            let compare = tag1.text.compare(tage2.text, options:[.caseInsensitive,.numeric], range: nil, locale: nil)
            return compare == .orderedAscending
        }
        return sortedItems;
    }
}


extension Array<FTTaggedEntity> {
    func sortedTaggedEntities() -> Array<FTTaggedEntity> {
        let items = self.sorted { item1, item2 in
            if let docEntity1 = item1 as? FTDocumentTaggedEntity
                , let docEntity2 = item2 as? FTDocumentTaggedEntity {
                return docEntity1.documentName.compare(docEntity2.documentName, options: [.caseInsensitive,.numeric], range: nil, locale: nil) == .orderedAscending;
            }
            else if let pageEntity1 = item1 as? FTPageTaggedEntity
                ,let pageEntity2 = item2 as? FTPageTaggedEntity {
                let result = pageEntity1.documentName.compare(pageEntity2.documentName, options: [.caseInsensitive,.numeric], range: nil, locale: nil);
                if result == .orderedSame {
                    return pageEntity1.pageProperties.pageIndex < pageEntity2.pageProperties.pageIndex;
                }
                return result == .orderedAscending;
            }
            else if item1 is FTPageTaggedEntity
                        , item2 is FTDocumentTaggedEntity {
                return false;
            }
            return true;
        }
        return items;
    }
}
