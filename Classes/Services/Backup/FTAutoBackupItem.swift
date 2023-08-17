//
//  FTAutoBackupItem.swift
//  Noteshelf
//
//  Created by Amar on 3/5/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

@objcMembers class FTAutoBackupItem: NSObject {
    var URL : Foundation.URL!;
    var relativePath : String! {
        return self.URL.relativePathWRTCollection();
    };

    var lastUpdated : NSNumber? {
        var modificationDate : AnyObject?;
        let nsURL = (self.URL as NSURL);
        _ = try? nsURL.getPromisedItemResourceValue(&modificationDate, forKey: URLResourceKey.contentModificationDateKey);
        if(nil == modificationDate) {
            _ = try? nsURL.getPromisedItemResourceValue(&modificationDate, forKey: URLResourceKey.creationDateKey);
        }
        if(nil != modificationDate) {
            return NSNumber.init(value: (modificationDate as! Date).timeIntervalSinceReferenceDate as Double);
        }
        else {
            return nil;
        }
    }
    
    var title : String!{
        get {
            return self.URL.deletingPathExtension().lastPathComponent;
        }
    };
    
    var documentUUID : String!;
    
    required convenience init(URL : Foundation.URL,documentUUID : String) {
        self.init();
        self.URL = URL;
        self.documentUUID = documentUUID;
    }
}
