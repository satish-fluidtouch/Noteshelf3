
//
//  FTShelfItemCollectionFavorites.swift
//  Noteshelf
//
//  Created by Akshay on 09/10/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

let maximumPinLimit = 10

class FTShelfItemCollectionFavorites: FTShelfItemCollectionRecent {
    
    override var collectionType : FTShelfItemCollectionType {
        return .starred;
    };
    
    override var items : [FTDiskRecentItem] {
        return FTRecentEntries.allFavoriteEntries();
    }
    
    @discardableResult override func addShelfItemToList(_ inurl : URL) -> NSError?
    {
        var error : NSError?;
        let url = inurl.urlByDeleteingPrivate();
        if FTRecentEntries.saveEntry(url, mode: .favorites) {
                var item1 : FTShelfItemProtocol?;
                item1 = self.recentCollectionLocal?.shelfItemForURL(url);
                if(nil == item1) {
                    item1 = self.recentCollectionLocal?.addItemToCache(url, addToLocalCache: true);
                }
        }
        return error;
    }
    
    override func removeShelfItemFromList(_ urls : [URL])
    {
        for eachURL in urls {
            if(FTRecentEntries.deleteEntry(eachURL, mode: .favorites)) {
                self.recentCollectionLocal?.removeItemFromCache(eachURL);
            }
        }
    }
    
    override func updateQueryForChangeInRecentEntries()
    {
        let items = FTRecentEntries.allFavoriteEntries();
        let paths = NSURL.urlPaths(items);
        self.recentCollectionLocal?.updateQuery(searchPaths: paths);
    }

    override func addShelfItemForDocument(_ path: Foundation.URL,
                                 toTitle: String,
                                 toGroup: FTGroupItemProtocol?,
                                 onCompletion block: @escaping (NSError?, FTDocumentItemProtocol?) -> Void){
        FTNoteshelfDocumentProvider.shared.uncategorizedNotesCollection { (unfiledShelf) in
            unfiledShelf?.addShelfItemForDocument(path, toTitle: toTitle, toGroup: toGroup, onCompletion: { [weak self] error, documentItemProtocol in
                if error == nil, let shelfItemURL = documentItemProtocol?.URL {
                    self?.addShelfItemToList(shelfItemURL)
                }
                block(error,documentItemProtocol)
            })
        }
    }

}
