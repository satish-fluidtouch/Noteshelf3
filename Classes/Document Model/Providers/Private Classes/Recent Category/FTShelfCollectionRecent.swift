//
//  FTShelfCollectionRecent.swift
//  Noteshelf
//
//  Created by Amar on 14/06/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTShelfCollectionRecent: NSObject,FTShelfCollection {
    let recentShelfItemCollection : FTShelfItemCollectionRecent;
    let favoritesShelfItemCollection : FTShelfItemCollectionRecent;
    var shelfCollections = [FTShelfItemCollection]();

    override init() {
        //Recent
        let urlRecent = NSURL.init(string: "Recent.shelf")! as URL;
        self.recentShelfItemCollection = FTShelfItemCollectionRecent.init(fileURL:urlRecent);
        self.shelfCollections.append(recentShelfItemCollection);
        
        //Favorites
        let urlFavorites = NSURL.init(string: "Starred.shelf")! as URL;
        self.favoritesShelfItemCollection = FTShelfItemCollectionFavorites.init(fileURL:urlFavorites);
        self.shelfCollections.append(favoritesShelfItemCollection);
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
