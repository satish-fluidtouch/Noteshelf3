//
//  FTDocumentItemSpotLightWrapper.swift
//  Noteshelf
//
//  Created by Amar on 27/6/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTDocumentItemSpotLightWrapper : NSObject,FTCSIndexableItem {

    override func isEqual(_ object: Any?) -> Bool {
        guard let otherObject = object as? FTDocumentItemSpotLightWrapper else {
            return false;
        }
        return self.uniqueIDForCSSearchIndex() == otherObject.uniqueIDForCSSearchIndex();
    }
    
    override var hash: Int {
        return self.uniqueIDForCSSearchIndex().hash;
    }
    
    fileprivate var docItem : FTDocumentItemProtocol!;
    private var thuumbImage: UIImage? = UIImage(named: "covergray");
    private var isReady = false;
    
    @objc convenience required init(documentItem item: Any) {
        self.init();
        if(!(item is FTDocumentItemProtocol)) {
            fatalError("item should be of type documentItemProtocol");
        }
        self.docItem = (item as! FTDocumentItemProtocol);
    }
    
    func prepare(_ queue: DispatchQueue?, onCompletion block: (() -> Void)?) {
        var token: String?
        token = FTURLReadThumbnailManager.sharedInstance.thumnailForItem(self.docItem) { img, inToken in
            if token == inToken, let _img = img {
                self.thuumbImage = img;
            }
            self.isReady = true;
            if let _queue = queue {
                _queue.async {
                    block?();
                }
            }
            else {
                block?();
            }
        }
    }
    
    func canSupportCSSearchIndex() -> Bool {
        return true;
    }
    
    func uniqueIDForCSSearchIndex() -> String {
        return self.docItem.URL.relativePathWRTCollection();
    }
    
    func titleForCSSearchIndex() -> String {
        guard isReady else {
            fatalError("call prepare method first");
        }
        return self.docItem.displayTitle;
    }
    
    func contentForCSSearchIndex() -> String?
    {
        guard isReady else {
            fatalError("call prepare method first");
        }
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
        guard isReady else {
            fatalError("call prepare method first");
        }
        return thuumbImage;
    }
}

class FTDocumentsSpotlightIndexManager : NSObject
{
    func prepareSpotLightIndexForItems(items : [FTShelfItemProtocol]) {
        let objects = self.prepareSpotlightIndex(items: items);
        FTSearchIndexManager.shared().updateSearchIndex(forDocuments: objects);
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
