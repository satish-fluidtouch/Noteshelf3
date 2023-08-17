//
//  FTWatchRecordingCache.swift
//  Noteshelf
//
//  Created by Amar on 12/02/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTWatchRecordingCache {
    var watchRecordings : FTHashTable {get set};
    var watchRecordingsNoFile : FTHashTable {get set};

    var providerType : FTWatchProviderType {get};

    func addRecordToAppropriateCache(item : FTWatchRecording,key : URL);
    func addRecordToNoFileCache(item : FTWatchRecording,key : URL);
    func addRecordToCache(item : FTWatchRecording,key : URL) ;
    func recordFromAllCache(key : URL) -> FTWatchRecording?;
    func recordFromNoFileCache(key : URL) -> FTWatchRecording?;
    func recordFromCache(key : URL) -> FTWatchRecording?;
    func removeRecordFromAllCache(url : URL);
    func removeRecordFromNoFileCache(url : URL);
    func removeRecordFromCache(url : URL);
}

extension FTWatchRecordingCache
{
    func addRecordToAppropriateCache(item : FTWatchRecording,key : URL) {
        objc_sync_enter(self);
        var fileExists = false;
        if(self.providerType == .cloud) {
            fileExists = item.filePath?.isUbiquitousFileExists() ?? false;
        }
        else {
            fileExists = FileManager().fileExists(atPath: item.filePath!.path);
        }
        
        if(fileExists) {
            self.addRecordToCache(item: item, key: key);
        }
        else {
            self.addRecordToNoFileCache(item: item, key: key);
        }
        objc_sync_exit(self);
    }
    
    func addRecordToNoFileCache(item : FTWatchRecording,key : URL) {
        objc_sync_enter(self);
        self.removeRecordFromNoFileCache(url: key);
        self.watchRecordingsNoFile.addItemToHashTable(item, forKey: key);
        objc_sync_exit(self);
    }
    
    func addRecordToCache(item : FTWatchRecording,key : URL) {
        objc_sync_enter(self);
        self.watchRecordings.addItemToHashTable(item, forKey: key);
        objc_sync_exit(self);
    }
    
    func recordFromAllCache(key : URL) -> FTWatchRecording?
    {
        objc_sync_enter(self);
        var item = self.recordFromCache(key: key);
        if(nil == item) {
            item = self.recordFromNoFileCache(key: key);
        }
        objc_sync_exit(self);
        return item;
    }
    
    func recordFromNoFileCache(key : URL) -> FTWatchRecording?
    {
        objc_sync_enter(self);
        let item = self.watchRecordingsNoFile.itemFromHashTable(key) as? FTWatchRecording;
        objc_sync_exit(self);
        return item;
    }
    
    func recordFromCache(key : URL) -> FTWatchRecording?
    {
        objc_sync_enter(self);
        let item = self.watchRecordings.itemFromHashTable(key) as? FTWatchRecording;
        objc_sync_exit(self);
        return item;
    }
    
    func removeRecordFromAllCache(url : URL)
    {
        objc_sync_enter(self);
        self.removeRecordFromNoFileCache(url: url);
        self.removeRecordFromCache(url: url);
        objc_sync_exit(self);
    }
    
    func removeRecordFromNoFileCache(url : URL)
    {
        objc_sync_enter(self);
        self.watchRecordingsNoFile.removeItemFromHashTable(url);
        objc_sync_exit(self);
    }
    
    func removeRecordFromCache(url : URL)
    {
        objc_sync_enter(self);
        self.watchRecordings.removeItemFromHashTable(url);
        objc_sync_exit(self);
    }
}

protocol FTWatchRecordingSort {
    
}

extension FTWatchRecordingSort {
    func sortItems(_ items:[FTWatchRecording]) -> [FTWatchRecording]
    {
        let sortedItems = items.sorted(by: { (object1, object2) -> Bool in
            var returnVal = false;
            let lastUpdated1 = object1.date;
            let lastUpdated2 = object2.date;
            returnVal = (lastUpdated1.compare(lastUpdated2) == ComparisonResult.orderedDescending) ? true : false;
            return returnVal;
        });
        return sortedItems;
    }
}
