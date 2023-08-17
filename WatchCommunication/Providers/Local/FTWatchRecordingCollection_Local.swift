//
//  FTWatchRecordingProvider_Local.swift
//  Noteshelf
//
//  Created by Amar on 08/02/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTWatchRecordingCollection_Local: FTWatchRecordingCollection,FTWatchRecordingSort,FTWatchRecordingCache {
    
    
    private var lastReadContents : [String]?;
    private var rootFolderModifiedDate : Date?;
    
    internal var watchRecordings = FTHashTable();
    internal var watchRecordingsNoFile = FTHashTable();

    private var observeTimer : Timer?;
    private var isProcessing = false;
    
    private var finishedGathering = false;
    
    var providerType: FTWatchProviderType {
        return .local;
    }
    
    deinit {
        #if DEBUG
        debugPrint("deinit FTWatchRecordingCollection_Local");
        #endif
    }
    
    func allRecordings(_ completion: @escaping (([FTWatchRecording]) -> Void)) {
        if(!finishedGathering) {
            DispatchQueue.global().async {
                self.createRootIfNeeded();
                do {
                    let plists = try self.plistFiles();
                    self.rootFolderModifiedDate = self.rootURL().fileModificationDate;
                    self.lastReadContents = plists;
                    plists.forEach({ (fileName) in
                        let url = self.rootURL().appendingPathComponent(fileName);
                        let item = self.createRecord(fromURL: url);
                        if(nil != item) {
                            self.addRecordToAppropriateCache(item: item!, key: url)
                        }
                    });
                    self.startObserving();
                }
                catch {
                    
                }
                self.finishedGathering = true;
                objc_sync_enter(self);
                let items = self.sortItems(Array(self.watchRecordings.allItems()) as! [FTWatchRecording]);
                objc_sync_exit(self);
                DispatchQueue.main.async {
                    completion(items);
                }
            }
        }
        else {
            objc_sync_enter(self);
            let items = self.sortItems(Array(self.watchRecordings.allItems()) as! [FTWatchRecording]);
            objc_sync_exit(self);
            DispatchQueue.main.async {
                completion(items);
            }
        }
    }
    
    func addRecording(tempRecord : FTWatchRecording,
                      onCompletion completion: @escaping ((FTWatchRecording?, Error?) -> Void))
    {
        DispatchQueue.global().async {
           
            self.createRootIfNeeded();

            var errorThrown : Error?
            var record : FTWatchRecording?
            
            do {
                var metaDataPlistURL = self.rootURL().appendingPathComponent(tempRecord.GUID).appendingPathExtension(audioMetadataFileExtension);
                if((FileManager().fileExists(atPath: metaDataPlistURL.path))) {
                    tempRecord.prepareToCopy()
                    metaDataPlistURL = self.rootURL().appendingPathComponent(tempRecord.GUID).appendingPathExtension(audioMetadataFileExtension);
                }
                let info = tempRecord.dictionaryRepresentation();
                try (info as NSDictionary).write(to: metaDataPlistURL);
                
                let audioURL = self.rootURL().appendingPathComponent(tempRecord.GUID).appendingPathExtension(audioFileExtension);
                if(!(FileManager().fileExists(atPath: audioURL.path))) {
                    try FileManager().moveItem(at: tempRecord.filePath!, to: audioURL)
                    record = self.createRecord(info: info);
                    self.addRecordToAppropriateCache(item: record!, key: metaDataPlistURL);
                }
            }
            catch
            {
                errorThrown = error;
            }
            DispatchQueue.main.async {
                completion(record,errorThrown);
            }
        }
    }
    
    func deleteRecording(item: FTWatchRecording, onCompletion completion: @escaping ((Error?) -> Void)) {
        DispatchQueue.global().async {
            var errorThrown : Error?
            
            if let pathURL = item.filePath {
                do {
                    let plistURL = self.rootURL().appendingPathComponent(item.GUID).appendingPathExtension(audioMetadataFileExtension);
                    let fileManager = FileManager();
                    if(fileManager.fileExists(atPath: pathURL.path)) {
                        try fileManager.removeItem(at: pathURL);
                    }
                    if(fileManager.fileExists(atPath: plistURL.path)) {
                        try fileManager.removeItem(at: plistURL);
                    }
                    self.removeRecordFromAllCache(url: plistURL);
                }
                catch
                {
                    errorThrown = error;
                }
            }
            else {
                errorThrown = NSError.init(domain: "FTWatchRecording", code: 101, userInfo: nil);
            }
            
            DispatchQueue.main.async {
                completion(errorThrown);
            }
        }
    }
    
    func updateRecording(item: FTWatchRecording, onCompletion completion: @escaping ((Error?) -> Void)) {
        DispatchQueue.global().async {
            var errorThrown : Error?
            
            do {
                let info = item.dictionaryRepresentation();
                let metaDataPlistURL = self.rootURL().appendingPathComponent(item.GUID).appendingPathExtension(audioMetadataFileExtension);
                try (info as NSDictionary).write(to: metaDataPlistURL);
                let storedItem = self.recordFromAllCache(key: metaDataPlistURL);
                _ = self.updateRecord(record: storedItem, fromFile: metaDataPlistURL.lastPathComponent)
            }
            catch
            {
                errorThrown = error;
            }
            DispatchQueue.main.async {
                completion(errorThrown);
            }
        }
    }
    
    func startDownloading(item : FTWatchRecording) {
        
    }
    //MARK:- Private -
    private func plistFiles() throws -> [String]
    {
        let contents = try FileManager().contentsOfDirectory(atPath: self.rootURL().path);
        let plists = contents.filter({ (eachEntry) -> Bool in
            if(URL.init(fileURLWithPath: eachEntry).isAudioMetadataFile()) {
                return true;
            }
            return false;
        });
        return plists;
    }
    
    func rootURL() -> URL
    {
        #if os(iOS)
            var folderPath = FTUtils.noteshelfDocumentsDirectory();
            folderPath.appendPathComponent("Audio Recording");
            return folderPath;
        #else
            let urls = FileManager().urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask);
            var folderPath = urls.first!;
            folderPath.appendPathComponent("Audio Recording");
            return folderPath;
        #endif
    }
    
    internal func createRootIfNeeded() {
        var isDir = ObjCBool.init(false);
        let exists = FileManager().fileExists(atPath: self.rootURL().path, isDirectory: &isDir);
        if(!exists || !isDir.boolValue) {
            try? FileManager().createDirectory(at: self.rootURL(), withIntermediateDirectories: true, attributes: nil);
        }
    }
    
    //MARK:- Cache -
    private func updateRecord(record: FTWatchRecording?,fromFile filename: String) -> Bool
    {
        if(nil == record) {
            return false;
        }
        
        let url = self.rootURL().appendingPathComponent(filename);
        let modifiedDate = url.fileModificationDate;
        if((record!.lastModifiedDate != nil)
            && (record!.lastModifiedDate?.compare(modifiedDate) == ComparisonResult.orderedAscending))
        {
            let contents = NSDictionary.init(contentsOf: url);
            if(nil != contents) {
                record?.fileName = contents!["fileName"] as! String
                record?.date = contents!["date"] as! Date
                record?.duration = (contents!["duration"] as! NSNumber).doubleValue
                record?.audioStatus = FTWatchAudioStatus(rawValue: Int((contents!["audioStatus"]! as! NSString).intValue))!
                record?.syncStatus = FTWatchSyncStatus(rawValue: Int(((contents!["syncStatus"] ?? "0") as! NSString).intValue))!
                record?.lastModifiedDate = modifiedDate
                return true;
            }
        }
        
        return false;
    }
    
    private func createRecord(fromURL url: URL) -> FTWatchRecording?
    {
        let contents = NSDictionary.init(contentsOf: url);
        var item : FTWatchRecording?
        if(nil != contents) {
            item = FTWatchRecordedAudio.initWithDictionary(contents as! Dictionary<String, Any>);
            item?.downloadStatus = FTDownloadStatus.downloaded;
            item?.filePath = self.rootURL().appendingPathComponent(item!.fileName);
            item?.lastModifiedDate = url.fileModificationDate
        }
        
        return item;
    }

    private func createRecord(info : [String:Any]) -> FTWatchRecording
    {
        let item = FTWatchRecordedAudio.initWithDictionary(info);
        item.downloadStatus = FTDownloadStatus.downloaded;
        item.filePath = self.rootURL().appendingPathComponent(item.fileName);
        return item;
    }
    
    private func recordFileExists(item : FTWatchRecording) -> Bool
    {
        var hasFile = false;
        let url = self.rootURL().appendingPathComponent(item.fileName);
        if(FileManager().fileExists(atPath: url.path)) {
            item.filePath = url;
            hasFile = true;
        }
        return hasFile;
    }

    //MARK:- Observer -
    private func stopObserving()
    {
        self.observeTimer?.invalidate();
        self.observeTimer = nil;
    }
    
    private func startObserving()
    {
        DispatchQueue.main.async {
            self.observeTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true, block: { [weak self] (timer) in
                DispatchQueue.global().async {
                    guard let strongSelf = self else {
                        return;
                    }
                    var modifiedDate : Date?;
                    let newModifiedDate = strongSelf.rootURL().fileModificationDate;
                    if let prevModifidDate = strongSelf.rootFolderModifiedDate {
                        if(newModifiedDate.compare(prevModifidDate) != ComparisonResult.orderedDescending) {
                            return;
                        }
                        modifiedDate = newModifiedDate;
                    }

                    strongSelf.stopObserving();
                    do {
                        let plists = try strongSelf.plistFiles();
                        let currentSet = Set(strongSelf.lastReadContents!);
                        let newSet = Set(plists);
                        
                        let deletedSet = currentSet.subtracting(newSet);
                        let addedSet = newSet.subtracting(currentSet);
                        let commonSet = currentSet.intersection(newSet);
                        
                        var itemsAdded = [FTWatchRecording]();
                        var itemsDeleted = [FTWatchRecording]();
                        var itemsUpdated = [FTWatchRecording]();
                        
                        deletedSet.forEach({ (eachFileName) in
                            let path = strongSelf.rootURL().appendingPathComponent(eachFileName);
                            let deletedItem = strongSelf.recordFromCache(key: path);
                            strongSelf.removeRecordFromAllCache(url: path);
                            if(nil != deletedItem) {
                                itemsDeleted.append(deletedItem!);
                            }
                        });
                        
                        addedSet.forEach({ (eachFileName) in
                            let path = strongSelf.rootURL().appendingPathComponent(eachFileName);
                            let item = strongSelf.createRecord(fromURL: path);
                            strongSelf.addRecordToAppropriateCache(item: item!, key: path);
                            if(nil != item) {
                                itemsAdded.append(item!);
                            }
                        });
                        
                        commonSet.forEach({ (eachFileName) in
                            let path = strongSelf.rootURL().appendingPathComponent(eachFileName);
                            let itemToUpdate = strongSelf.recordFromAllCache(key: path);
                            let success = strongSelf.updateRecord(record: itemToUpdate, fromFile: eachFileName);
                            
                            let sourceItem = strongSelf.recordFromCache(key: path);
                            if(success && (nil != sourceItem)) {
                                itemsUpdated.append(sourceItem!);
                            }
                        });
                        
                        objc_sync_enter(strongSelf);
                        let recordings = strongSelf.watchRecordingsNoFile.allItems();
                        recordings.forEach({ (item) in
                            let recordingItem = item as! FTWatchRecording;
                            if(strongSelf.recordFileExists(item: recordingItem)) {
                                let path = strongSelf.rootURL().appendingPathComponent(recordingItem.GUID).appendingPathExtension(audioMetadataFileExtension);
                                strongSelf.removeRecordFromNoFileCache(url: path);
                                strongSelf.addRecordToCache(item: recordingItem, key: path);
                                itemsAdded.append(recordingItem);
                            }
                        });
                        
                        strongSelf.lastReadContents = plists;
                        if(nil != modifiedDate) {
                            strongSelf.rootFolderModifiedDate = modifiedDate;
                        }
                        objc_sync_exit(strongSelf);
                        
                        DispatchQueue.main.async {
                            self?.startObserving();
                            NotificationCenter.default.post(name: NSNotification.Name(FTRecordingCollectionUpdatedNotification), object: nil)
                        }
                    }
                    catch {
                        self?.startObserving();
                    }
                    
                }
            });
        }
    }
}
