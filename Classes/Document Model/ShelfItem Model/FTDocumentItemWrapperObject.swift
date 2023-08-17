//
//  FTDocumentItemWrapperObject.swift
//  Noteshelf
//
//  Created by Amar on 22/4/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

/******************************
This class is used temporarily for encapsulating the swift protocl items to make use in objective c class
 Will be deprecated in near future.
******************************/

import Foundation
import FTCommon

@objcMembers class FTDocumentItemWrapperObject : NSObject
{
    fileprivate var _documentItem : FTDocumentItemProtocol!;
    
    //item should be of FTDocumentItemProtocol
    convenience init(documentItem item : AnyObject)
    {
        self.init();
        self._documentItem = (item as! FTDocumentItemProtocol);
    }
    
    func setTempFileModificationDate(_ date: Date) {
        (self._documentItem as? FTDocumentItemTempAttributes)?.tempFileModificationDate = date;
    }
    
    var title : String! {
        return self._documentItem.displayTitle;
    };
    
    var URL : Foundation.URL {
        return self._documentItem.URL as URL;
    };
    
    var uuid : String! {
        return self._documentItem.uuid;
    };
    
    var type : RKShelfItemType! {
        return self._documentItem.type;
    };
    
    var fileModificationDate : Date {
        return self._documentItem.fileModificationDate as Date;
    };
    
    var fileCreationDate : Date {
        return self._documentItem.fileCreationDate as Date;
    };
    
    var fileLastOpenedDate: Date {
        return self._documentItem.fileLastOpenedDate as Date;
    }

    var parent : FTGroupItemProtocol? {
        return self._documentItem.parent;
    };
    
    var shelfCollection : FTShelfItemCollection! {
        return self._documentItem.shelfCollection;
    };
    
    var parentUUID : String? {
        return self._documentItem.parent?.uuid;
    }
    
    var documentItem : AnyObject
    {
        return self._documentItem as AnyObject;
    }
    
    var documentUUID : String
    {
        if(nil != self._documentItem.documentUUID) {
            return self._documentItem.documentUUID!;
        }
        else {
            FTLogError("Document UUID Not found");
            return FTUtils.getUUID();
        }
    }

    var documentItemProtocol : FTDocumentItemProtocol
    {
        return self._documentItem;
    }
    
    var shelfItemProtocol : FTShelfItemProtocol
    {
        return (self._documentItem as FTShelfItemProtocol);
    }
    
    var enSyncEnabled : Bool
    {
        return (self._documentItem as FTShelfItemProtocol).enSyncEnabled;
    }

}
