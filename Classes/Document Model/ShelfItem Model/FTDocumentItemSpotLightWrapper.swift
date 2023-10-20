//
//  FTDocumentItemSpotLightWrapper.swift
//  Noteshelf
//
//  Created by Amar on 27/6/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTDocumentItemSpotLightWrapper : NSObject,FTCSIndexableItem {

    fileprivate var docItem : FTDocumentItemProtocol!;
    
    @objc convenience required init(documentItem item: Any)
    {
        self.init();
        if(!(item is FTDocumentItemProtocol)) {
            fatalError("item should be of type documentItemProtocol");
        }
        self.docItem = (item as! FTDocumentItemProtocol);
    }
    
    func canSupportCSSearchIndex() -> Bool
    {
        return true;
    }
    
    func uniqueIDForCSSearchIndex() -> String
    {
        return self.docItem.URL.relativePathWRTCollection();
    }
    
    func titleForCSSearchIndex() -> String
    {
        return self.docItem.displayTitle;
    }
    
    func contentForCSSearchIndex() -> String?
    {
        let modifiedDate = self.modifiedDateForCSSearchIndex();
        let formatter = DateFormatter.init();
        formatter.dateFormat = "dd/MM/yyyy";
        
        var content = "";
        if(nil != modifiedDate) {
            let stringFromDate = formatter.string(from: modifiedDate!);
            content = String.init(format: NSLocalizedString("ConflictDocModifiedOn", comment: "Modified on %@"), stringFromDate);
        }

        return content;
    }

    func modifiedDateForCSSearchIndex() -> Date?
    {
        var date = self.docItem.fileModificationDate;
        return date;
    }

    func thumbnailForCSSearchIndex() -> UIImage?
    {
        var imageToReturn: UIImage?;
        let sema = DispatchSemaphore(value: 0);
        DispatchQueue.global().async {
            var token: String?
            token = FTURLReadThumbnailManager.sharedInstance.thumnailForItem(self.docItem) { img, inToken in
                if token == inToken {
                    imageToReturn = img;
                }
                sema.signal();
            }
        }
        sema.wait();
        if(nil == imageToReturn) {
            imageToReturn = UIImage.init(named: "covergray");
        }
        return imageToReturn;
    }
}

class FTDocumentsSpotlightIndexManager : NSObject
{
    func prepareSpotLightIndexForItems(items : [FTShelfItemProtocol]) {
        let objects = self.prepareSpotlightIndex(items: items);
        (FTSearchIndexManager.sharedManager() as! FTSearchIndexManager).updateSearchIndex(forDocuments: objects);
    }
    
    fileprivate func prepareSpotlightIndex(items : [FTShelfItemProtocol]) -> [FTDocumentItemSpotLightWrapper]
    {
        var indexObjects = [FTDocumentItemSpotLightWrapper]();
        for eachItem in items {
            if(eachItem is FTGroupItemProtocol) {
                indexObjects.append(contentsOf: self.prepareSpotlightIndex(items: (eachItem as! FTGroupItemProtocol).childrens));
            }
            else {
                let wrapper = FTDocumentItemSpotLightWrapper.init(documentItem: eachItem as! FTDocumentItemProtocol);
                indexObjects.append(wrapper);
            }
        }
        return indexObjects;
    }
}
