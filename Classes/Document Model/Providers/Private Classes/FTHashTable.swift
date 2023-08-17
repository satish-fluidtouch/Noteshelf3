//
//  FTHashTable.swift
//  Noteshelf
//
//  Created by Amar on 17/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTHashTable : NSObject
{
    fileprivate var hashTable = [String:Any](); //medataItem hash as key
    deinit {
        #if DEBUG
            print("deinit Hashtable")
        #endif
    }
    fileprivate func keyForItem(_ item : Any) -> String
    {
        var hashKey : String!;
        if let value = item as? URL {
            let fileItemURL = value.urlByDeleteingPrivate().path;
            hashKey = fileItemURL.hashKey
        }
        else if let value = item as? NSMetadataItem {
            hashKey = "\(value.hash)";
        }
        return hashKey;
    }
    //currently key accepted are NSURL and NSMetadataItem
    func addItemToHashTable(_ shelfItem : Any,forKey key : Any)
    {
        objc_sync_enter(self);
        let hashKey = self.keyForItem(key);
        self.hashTable[hashKey] = shelfItem;
        objc_sync_exit(self);
    }
    
    func itemFromHashTable(_ key : Any) -> Any?
    {
        objc_sync_enter(self);
        let hashKey = self.keyForItem(key);
        let value = self.hashTable[hashKey];
        objc_sync_exit(self);
        return value;
    }
    
    func removeItemFromHashTable(_ key : Any)
    {
        objc_sync_enter(self);
        let hashKey = self.keyForItem(key);
        self.hashTable.removeValue(forKey: hashKey);
        objc_sync_exit(self);
    }
    
    func removeAll()
    {
        objc_sync_enter(self);
        self.hashTable.removeAll();
        objc_sync_exit(self);
    }
    
    func allItems() -> [Any]
    {
        objc_sync_enter(self);
        let itemsToReturn = Array(hashTable.values)
        objc_sync_exit(self);
        return itemsToReturn;
    }
}

extension String {
    var hashKey: String {
        var key: String = ""
        var hasher = Hasher();
        hasher.combine(self);
        let hash = hasher.finalize()
        key = "\(hash)";
        return key
    }
}

extension URL {
    var hashKey: String {
        return self.path.hashKey;
    }
}
