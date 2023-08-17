//
//  FTNoteshelfDocumentProvider_FetchItem.swift
//  Noteshelf
//
//  Created by Amar on 26/11/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

typealias FTDocumentProviderFetchCallback = (FTShelfItemCollection?, FTGroupItemProtocol?, FTShelfItemProtocol?) -> Void;

extension FTNoteshelfDocumentProvider {
    func getShelfItemDetails(relativePath: String,
                             igrnoreIfNotDownloaded: Bool = false,
                             onCompletion : @escaping FTDocumentProviderFetchCallback)
    {
        var collectionName : String?;
        if let _collectionName = relativePath.collectionName() {
            collectionName = _collectionName.deletingPathExtension;
        }
        let groupPath = relativePath.relativeGroupPathFromCollection();
        var documentName:String?;
        if(relativePath.pathExtension == FTFileExtension.ns3) {
            documentName = relativePath.documentName();
        }

        if(!self.isProviderReady) {
            self.updateProviderIfRequired { [weak self] isUpdated in
                self?.getShelfItemDetails(relativePath: relativePath
                                          ,igrnoreIfNotDownloaded: igrnoreIfNotDownloaded
                                          , onCompletion: onCompletion)
            }
            return;
        }
        
        self.shelfCollection(title: collectionName) { collectionToShow in
            guard let _collectionToShow = collectionToShow else {
                onCompletion(nil, nil, nil);
                return;
            }
            _collectionToShow.shelfItems(.byName,
                                         parent: nil,
                                         searchKey: nil,
                                         onCompletion:{ _ in
                                            var groupitem: FTGroupItemProtocol?
                                            if let grpPath = groupPath {
                                                let url = _collectionToShow.URL.appendingPathComponent(grpPath);
                                                groupitem = _collectionToShow.groupItemForURL(url);
                                            }
                                            var shelfItemToOpen: FTShelfItemProtocol?;
                                            if let docName = documentName {
                                                shelfItemToOpen = _collectionToShow.documentItemWithName(title: docName, inGroup: groupitem)
                                                if let documentItem = shelfItemToOpen as? FTDocumentItemProtocol {
                                                    if(igrnoreIfNotDownloaded && !documentItem.isDownloaded) {
                                                        shelfItemToOpen = nil;
                                                    }
                                                }
                                            }
                                            onCompletion(collectionToShow, groupitem, shelfItemToOpen);
                                         });
        }
    }
    
    func shelfCollection(title : String?,
                                 pickDefault : Bool = false,
                                 onCompeltion : @escaping (FTShelfItemCollection?)->())
    {
        var collectionToShow : FTShelfItemCollection?;
        self.shelfs { (categoryCollections) in
            if pickDefault {
                if let defaultCollection = categoryCollections.first?.categories.first {
                    collectionToShow = defaultCollection;
                }
            }
            if let collectionName = title {
                for categoryCollection in categoryCollections {
                    for category in categoryCollection.categories where category.title == collectionName {
                        collectionToShow = category;
                        break;
                    }
                }
            }
            onCompeltion(collectionToShow);
        };
    }
}
