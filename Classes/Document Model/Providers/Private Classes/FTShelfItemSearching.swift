//
//  FTShelfItemSearching.swift
//  Noteshelf
//
//  Created by Amar on 24/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

protocol FTShelfItemSearching {
    func searchShelfItems(_ items : [FTShelfItemProtocol],
                          skipGroupItems : Bool,
                          searchKey : String!) -> [FTShelfItemProtocol];
}

extension FTShelfItemSearching
{
    func searchShelfItems(_ items : [FTShelfItemProtocol],
                          skipGroupItems : Bool,
                          searchKey : String!) -> [FTShelfItemProtocol]
    {
        var searchItems = [FTShelfItemProtocol]();
        
        for item in items {
            if((item.displayTitle.lowercased().contains(searchKey!.lowercased())) == true) {
                if(item.type == RKShelfItemType.pdfDocument) {
                    searchItems.append(item);
                }
                else if(item.type == RKShelfItemType.group) {
                    searchItems.append(item);
                }
            }
            
            if(item.type == RKShelfItemType.group && !skipGroupItems) {
                if let group = item as? FTGroupItemProtocol {
                    let searchedItems = self.searchShelfItems(group.childrens,
                                                              skipGroupItems: false,
                                                              searchKey: searchKey);
                    searchItems.append(contentsOf: searchedItems);
                }
            }
        }

        return searchItems;
    }
}
