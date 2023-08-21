//
//  FTShelfCollectionRecent.swift
//  Noteshelf
//
//  Created by Amar on 14/06/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTShelfCollectionRecent: NSObject,FTShelfCollection {
    func ns2Shelfs(_ onCompletion: @escaping (([FTShelfItemCollection]) -> Void)) {
        onCompletion([])
    }

    var recentShelfItemCollection : FTShelfItemCollectionRecent?;
    var favoritesShelfItemCollection : FTShelfItemCollectionRecent?;
    fileprivate(set) var shelfCollections = [FTShelfItemCollection]();

    static func shelfCollection(_ onCompletion : @escaping ((FTShelfCollection) -> Void))
    {
        let collection = FTShelfCollectionRecent();
        
        //Recent
        let urlRecent = NSURL.init(string: "Recent.shelf")! as URL;
        collection.recentShelfItemCollection = FTShelfItemCollectionRecent.init(fileURL:urlRecent);
        collection.shelfCollections.append(collection.recentShelfItemCollection!);
        
        //Favorites
        let urlFavorites = NSURL.init(string: "Starred.shelf")! as URL;
        collection.favoritesShelfItemCollection = FTShelfItemCollectionFavorites.init(fileURL:urlFavorites);
        collection.shelfCollections.append(collection.favoritesShelfItemCollection!);
        
        onCompletion(collection);
    }
    
    func shelfs(_ onCompletion : @escaping (([FTShelfItemCollection])->Void))
    {
        onCompletion(self.shelfCollections);
    }
    
    func collection(withTitle title: String) -> FTShelfItemCollection? {
        for eachItem in self.shelfCollections {
            if(eachItem.title == title) {
                return eachItem;
            }
        }
        return nil;
    }
}
