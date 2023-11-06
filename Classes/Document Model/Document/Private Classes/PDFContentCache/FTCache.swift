//
//  FTCache.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 25/10/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTCache: NSObject {
    private var _contents: NSMutableDictionary?;
    private var identifier = UUID().uuidString;
    
    init(identifier _iden: String) {
        identifier = _iden
    }
    
    private func cacheURL() -> URL {
        let cacheFolder = NSSearchPathForDirectoriesInDomains(.cachesDirectory,
                                                              .userDomainMask,
                                                              true).last;
        let cacheFolderURL = Foundation.URL(fileURLWithPath: cacheFolder!);
        let fileName = self.identifier.appending(".plist");
        return cacheFolderURL.appendingPathComponent(fileName);
    }
    
    private var contents: NSMutableDictionary? {
        objc_sync_enter(self);
        if nil == _contents {
            _contents = NSMutableDictionary(contentsOf: self.cacheURL());
        }
        objc_sync_exit(self);
        return _contents
    }
    
    func setObject(_ object:Any,forKey key: String) {
        objc_sync_enter(self);
        self.contents?.setObject(object, forKey: key as NSCopying);
        self.contents?.write(to: self.cacheURL(), atomically: true);
        objc_sync_exit(self);
    }
    
    func removeObject(forKey key: String) {
        objc_sync_enter(self);
        self.contents?.removeObject(forKey: key);
        self.contents?.write(to: self.cacheURL(), atomically: true);
        objc_sync_exit(self);
    }
    
    func object(forKey key: String) -> Any? {
        objc_sync_enter(self);
        let value = self.contents?.object(forKey: key);
        objc_sync_exit(self);
        return value;
    }
}
