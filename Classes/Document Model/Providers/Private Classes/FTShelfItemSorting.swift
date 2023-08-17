//
//  FTShelfSorting.swift
//  Noteshelf
//
//  Created by Amar on 24/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

protocol FTShelfItemSorting
{
    func sortItems(_ items:[FTShelfItemProtocol],sortOrder : FTShelfSortOrder) -> [FTShelfItemProtocol];
}

extension FTShelfItemSorting
{
    func sortItems(_ items:[FTShelfItemProtocol],sortOrder : FTShelfSortOrder) -> [FTShelfItemProtocol]
    {
        if(sortOrder == .none) {
            return items;
        }
        
        let sortedItems = items.sorted(by: { (object1, object2) -> Bool in
            var returnVal = false;
            switch sortOrder {
            case .byModifiedDate:
                let lastUpdated1 = object1.fileModificationDate;
                let lastUpdated2 = object2.fileModificationDate;
                returnVal = (lastUpdated1.compare(lastUpdated2) == ComparisonResult.orderedDescending) ? true : false;
            case .byName:
                let title1 = object1.displayTitle.lowercased();
                let title2 = object2.displayTitle.lowercased();
                returnVal = (title1.compare(title2, options: [String.CompareOptions.caseInsensitive,String.CompareOptions.numeric], range: nil, locale: nil) == ComparisonResult.orderedAscending) ? true : false;
            case .byCreatedDate:
                let fileCreated1 = object1.fileCreationDate;
                let fileCreated2 = object2.fileCreationDate;
                returnVal = (fileCreated1.compare(fileCreated2) == ComparisonResult.orderedDescending) ? true : false;
            case .byLastOpenedDate:
                let fileCreated1 = object1.fileLastOpenedDate;
                let fileCreated2 = object2.fileLastOpenedDate;
                returnVal = (fileCreated1.compare(fileCreated2) == ComparisonResult.orderedDescending) ? true : false;
            case .manual:
                let firstIndex = object1.sortIndex()
                let secondIndex = object2.sortIndex()
                if let index1 = firstIndex, let index2 = secondIndex {
                    returnVal = (index1 < index2)
                }
                else if secondIndex != nil {
                    returnVal = true
                }
                else if firstIndex != nil {
                    returnVal = false
                }
                else {
                    let fileCreated1 = object1.fileCreationDate;
                    let fileCreated2 = object2.fileCreationDate;
                    returnVal = (fileCreated1.compare(fileCreated2) == ComparisonResult.orderedDescending) ? true : false;
                }
            default:
                break;
            }
            return returnVal;
        });
        return sortedItems;
    }    
}

private extension FTShelfItemProtocol {
    func sortIndex() -> Int?{
        var indexFolder: FTSortIndexContainerProtocol?
        if let groupItem = self.parent as? FTSortIndexContainerProtocol {
            indexFolder = groupItem
        }
        else if let shelfCategory = self.shelfCollection as? FTSortIndexContainerProtocol {
            indexFolder = shelfCategory
        }
        return indexFolder?.indexCache?.getIndex(for: self.sortIndexHash)
    }
}
