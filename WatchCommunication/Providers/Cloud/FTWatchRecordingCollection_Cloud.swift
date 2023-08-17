//
//  FTWatchRecordingCollection_Cloud.swift
//  Noteshelf
//
//  Created by Amar on 08/02/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTWatchRecordingCollection_Cloud: FTWatchRecordingCollection, FTWatchRecordingSort, FTWatchRecordingCache {

    weak var listenerDelegate: FTQueryListenerProtocol?

    internal var watchRecordings = FTHashTable();
    internal var watchRecordingsNoFile = FTHashTable();

    fileprivate var cloudURL: URL!;

    init(cloudURL: URL) {
        self.cloudURL = cloudURL
    }

    var providerType: FTWatchProviderType {
        return .cloud;
    }

    deinit {
        #if DEBUG
        debugPrint("deinit FTWatchRecordingCollection_Cloud");
        #endif
    }

    func allRecordings(_ completion: @escaping (([FTWatchRecording]) -> Void)) {
        objc_sync_enter(self);
        let items = self.sortItems(self.watchRecordings.allItems() as! [FTWatchRecording]);
        objc_sync_exit(self);

        DispatchQueue.main.async {
            completion(items);
        }
    }

    func addRecording(tempRecord: FTWatchRecording,
                      onCompletion completion: @escaping ((FTWatchRecording?, Error?) -> Void)) {
        DispatchQueue.global().async {

            self.createRootIfNeeded();

            var errorThrown: Error?
            var record: FTWatchRecording?

            do {
                let tempURL = URL(fileURLWithPath: NSTemporaryDirectory());
                var metaDataPlistURL = tempURL.appendingPathComponent(tempRecord.GUID).appendingPathExtension(audioMetadataFileExtension);

                if((FileManager().fileExists(atPath: metaDataPlistURL.path))) {
                    tempRecord.prepareToCopy()
                    metaDataPlistURL = tempURL.appendingPathComponent(tempRecord.GUID).appendingPathExtension(audioMetadataFileExtension);
                }
                let info = tempRecord.dictionaryRepresentation();
                try (info as NSDictionary).write(to: metaDataPlistURL);                
                let destPath = self.rootURL().appendingPathComponent(metaDataPlistURL.lastPathComponent);
                try FileManager().setUbiquitous(true, itemAt: metaDataPlistURL, destinationURL: destPath);

                let audoURL = self.rootURL().appendingPathComponent(tempRecord.GUID).appendingPathExtension(audioFileExtension);
                if(!(FileManager().fileExists(atPath: audoURL.path))) {
                    try FileManager().setUbiquitous(true, itemAt: tempRecord.filePath!, destinationURL: audoURL);
                    record = self.createRecord(destPath);
                    self.addRecordToAppropriateCache(item: record!, key: destPath);
                }
            } catch {
                errorThrown = error;
            }
            DispatchQueue.main.async {
                completion(record, errorThrown);
            }
        }

    }

    func deleteRecording(item: FTWatchRecording,
                         onCompletion completion: @escaping ((Error?) -> Void)) {
        DispatchQueue.global().async {
            let cooridinator = NSFileCoordinator(filePresenter: nil);
            let audioURL = item.filePath!;
            let metadataPlistURL = audioURL.deletingPathExtension().appendingPathExtension(audioMetadataFileExtension);

            var intents = [NSFileAccessIntent]();
            let fileManager = FileManager();
            var plistIntent: NSFileAccessIntent?

            if(fileManager.fileExists(atPath: metadataPlistURL.path)) {
                plistIntent = NSFileAccessIntent.writingIntent(with: metadataPlistURL, options: NSFileCoordinator.WritingOptions.forDeleting);
                intents.append(plistIntent!);
            }
            var audioIntent: NSFileAccessIntent?
            if(fileManager.fileExists(atPath: audioURL.path)) {
                audioIntent = NSFileAccessIntent.writingIntent(with: audioURL, options: NSFileCoordinator.WritingOptions.forDeleting);
                intents.append(audioIntent!);
            }
            if(intents.count > 0) {
                let operationQueue = OperationQueue();
                cooridinator.coordinate(with: intents, queue: operationQueue, byAccessor: { error in
                    var errorToThrow = error;
                    if(nil == error) {
                        do {
                            if(nil != audioIntent) {
                                try fileManager.removeItem(at: audioIntent!.url);
                            }
                            if(nil != plistIntent) {
                                try fileManager.removeItem(at: plistIntent!.url);
                            }
                            self.removeRecordFromCache(url: metadataPlistURL);
                        } catch let fileError {
                            errorToThrow = fileError;
                        }
                    }
                    DispatchQueue.main.async {
                        completion(errorToThrow);
                    }
                })
            } else {
                DispatchQueue.main.async {
                    completion(nil);
                }
            }
        }
    }

    func updateRecording(item: FTWatchRecording,
                         onCompletion completion: @escaping ((Error?) -> Void)) {
        DispatchQueue.global().async {
            let cooridinator = NSFileCoordinator(filePresenter: nil);
            let audioURL = item.filePath!;
            let metadataPlistURL = audioURL.deletingPathExtension().appendingPathExtension(audioMetadataFileExtension);
            let plistIntent = NSFileAccessIntent.writingIntent(with: metadataPlistURL, options: NSFileCoordinator.WritingOptions.forReplacing);

            let operationQueue = OperationQueue();
            cooridinator.coordinate(with: [plistIntent], queue: operationQueue, byAccessor: { error in
                var errorToThrow = error;
                if(nil == error) {
                    do {
                        let info = item.dictionaryRepresentation() as NSDictionary;
                        try info.write(to: plistIntent.url);
                    } catch let fileError {
                        errorToThrow = fileError;
                    }
                }
                DispatchQueue.main.async {
                    completion(errorToThrow);
                }
            });
        }
    }

    func startDownloading(item: FTWatchRecording) {
        do {
            if(item.downloadStatus == FTDownloadStatus.notDownloaded) {
                try FileManager().startDownloadingUbiquitousItem(at: item.filePath!);
                item.downloadStatus = FTDownloadStatus.downloading;
            }
        } catch {

        }
    }

    private func createRootIfNeeded() {
        var isDir = ObjCBool(false);
        let exists = FileManager().fileExists(atPath: self.rootURL().path, isDirectory: &isDir);
        if(!exists || !isDir.boolValue) {
            let tempPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(self.rootURL().lastPathComponent);
            try? FileManager().removeItem(at: tempPath);
            try? FileManager().createDirectory(at: tempPath, withIntermediateDirectories: true, attributes: nil);
            try? FileManager().setUbiquitous(true, itemAt: tempPath, destinationURL: self.rootURL());
        }
    }
}

// MARK: - FTMetadataCachingProtocol
extension FTWatchRecordingCollection_Cloud: FTMetadataCachingProtocol {

    func willBeginFetchingInitialData() {

    }

    func didEndFetchingInitialData() {

    }

    var canHandleAudio: Bool {
        return true
    }

    func addMetadataItemsToCache(_ metadataItems: [NSMetadataItem], isBuildingCache: Bool) {
        var addedItems = [FTWatchRecording]();

        for eachItem in metadataItems {
            let fileURL = eachItem.URL();
            if(fileURL.isAudioMetadataFile()) {
                if(eachItem.downloadStatus() == NSMetadataUbiquitousItemDownloadingStatusNotDownloaded) {
                    try? FileManager().startDownloadingUbiquitousItem(at: fileURL);
                }
                //Check if the document reference is present in documentMetadataItemHashTable.If the reference is found, its already added to cache. We just need to update the document with this metadataItem
                if let watchrecording = self.recordFromAllCache(key: fileURL) {
                    addedItems.append(watchrecording);
                } else {
                    if(eachItem.isItemDownloaded()) {
                        if let watchrecording = self.createRecord(fileURL) {
                            self.addRecordToAppropriateCache(item: watchrecording, key: fileURL);
                        }
                    }
                }
            } else if(fileURL.isAudioFile()) {
                let url = fileURL.deletingPathExtension().appendingPathExtension(audioMetadataFileExtension);
                if let watchrecording = self.recordFromAllCache(key: url) {
                    let noFileItem = self.recordFromNoFileCache(key: url);
                    self.update(item: watchrecording, withURL: url, audioMetadaItem: eachItem);
                    let afterUpdate = self.recordFromNoFileCache(key: url);
                    if((nil != noFileItem) && (nil == afterUpdate)) {
                        addedItems.append(watchrecording);
                    }
                }
            }
        }
        if(addedItems.count > 0) {
            runInMainThread({
                NotificationCenter.default.post(name: NSNotification.Name(FTRecordingCollectionUpdatedNotification), object: nil)
            });
        }
    }

    func removeMetadataItemsFromCache(_ metadataItems: [NSMetadataItem]) {
        var itemsRemoved = [FTWatchRecording]();

        for eachItem in metadataItems {
            let fileURL = eachItem.URL();
            if(fileURL.isAudioMetadataFile()) {
                let item = self.recordFromAllCache(key: fileURL);
                if(nil != item) {
                    self.removeRecordFromAllCache(url: fileURL);
                    itemsRemoved.append(item!);
                }
            } else {
                let metadataPathURL = fileURL.deletingPathExtension().appendingPathExtension(audioMetadataFileExtension);
                let item = self.recordFromAllCache(key: metadataPathURL);
                if(nil != item) {
                    self.removeRecordFromCache(url: metadataPathURL);
                    self.addRecordToNoFileCache(item: item!, key: metadataPathURL);
                    itemsRemoved.append(item!);
                }
            }
        }
        if(itemsRemoved.count > 0) {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name(FTRecordingCollectionUpdatedNotification), object: nil)
            }
        }
    }

    func updateMetadataItemsInCache(_ metadataItems: [NSMetadataItem]) {
        var updatedItems = Set<FTWatchRecordedAudio>();
        var itemsToAdd = [NSMetadataItem]();

        for eachItem in metadataItems {
            let fileURL = eachItem.URL();
            if(fileURL.isAudioMetadataFile()) {
                if let watchrecording = self.recordFromAllCache(key: fileURL) {
                    self.update(item: watchrecording, withURL: fileURL, audioMetadaItem: nil);
                    updatedItems.insert(watchrecording as! FTWatchRecordedAudio);
                } else {
                    itemsToAdd.append(eachItem);
                }
            } else if(fileURL.isAudioFile()) {
                let url = fileURL.deletingPathExtension().appendingPathExtension(audioMetadataFileExtension);
                if let watchrecording = self.recordFromCache(key: url) {
                    self.update(item: watchrecording, withURL: url, audioMetadaItem: eachItem);
                    updatedItems.insert(watchrecording as! FTWatchRecordedAudio);
                } else {
                    itemsToAdd.append(eachItem);
                }
            }
        }
        if(itemsToAdd.count > 0) {
            self.addMetadataItemsToCache(itemsToAdd, isBuildingCache: false);
        }
        if(updatedItems.count > 0) {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name(FTRecordingCollectionUpdatedNotification), object: nil)
            }
        }
    }
}

extension FTWatchRecordingCollection_Cloud {
    internal func createRecord(_ forURL: URL) -> FTWatchRecording? {
        let sema = DispatchSemaphore(value: 0);
        var item: FTWatchRecording?;

        DispatchQueue.global().async {
            var error: NSError?;
            let coordinator = NSFileCoordinator(filePresenter: nil);
            coordinator.coordinate(readingItemAt: forURL,
                                   options: NSFileCoordinator.ReadingOptions.withoutChanges,
                                   error: &error) { readingURL in
                                    let info = NSDictionary(contentsOf: readingURL);
                                    if(nil == info) {
//                                        FTCLSLog("WRC_create sema signal");
                                        sema.signal();
                                        return;
                                    }

                                    item = FTWatchRecordedAudio.initWithDictionary(info as! Dictionary<String, Any>);
                                    item!.filePath = self.rootURL().appendingPathComponent(item!.fileName);
                                    item!.downloadStatus = item!.filePath!.downloadStatus();
                                    item!.lastModifiedDate = readingURL.fileModificationDate;
//                                    FTCLSLog("WRC_create sema signal");
                                    sema.signal();
            };
            if(nil != error) {
//                FTCLSLog("WRC_create sema signal");
                sema.signal();
            }
        }
//        FTCLSLog("WRC_create sema wait");
        sema.wait();
        return item;
    }

    internal func update(item: FTWatchRecording, withURL url: URL, audioMetadaItem metadata: NSMetadataItem?) {
        let noFileItem = self.recordFromNoFileCache(key: url);

        let modifiedDate = url.fileModificationDate;
        if((item.lastModifiedDate != nil)
            && (item.lastModifiedDate!.compare(modifiedDate) == ComparisonResult.orderedAscending)) {
            let sema = DispatchSemaphore(value: 0);
            DispatchQueue.global().async {
                var error: NSError?;
                let coordinator = NSFileCoordinator(filePresenter: nil);
                coordinator.coordinate(readingItemAt: url,
                                       options: NSFileCoordinator.ReadingOptions.withoutChanges,
                                       error: &error) { readingURL in
                                        let contents = NSDictionary(contentsOf: readingURL);
                                        if(nil == contents) {
                                            FTCLSLog("WRC_update sema signal");
                                            sema.signal();
                                            return;
                                        }
                                        item.fileName = contents!["fileName"] as! String
                                        item.date = contents!["date"] as! Date
                                        item.duration = (contents!["duration"] as! NSNumber).doubleValue
                                        item.audioStatus = FTWatchAudioStatus(rawValue: Int((contents!["audioStatus"]! as! NSString).intValue))!
                                        item.syncStatus = FTWatchSyncStatus(rawValue: Int(((contents!["syncStatus"] ?? "0") as! NSString).intValue))!
                                        item.lastModifiedDate = modifiedDate
                                        FTCLSLog("WRC_update sema signal");
                                        sema.signal();
                };
                if(nil != error) {
                    FTCLSLog("WRC_update sema signal");
                    sema.signal();
                }
            }
            FTCLSLog("WRC_update sema wait");
            sema.wait();
        }

        if(nil != metadata) {
            var status = FTDownloadStatus.notDownloaded;
            if(metadata!.isItemDownloaded()) {
                status = .downloaded
            } else if let isDownloading = metadata!.isDownloading(), isDownloading.boolValue {
                status = .downloading;
            }
            item.downloadStatus = status;
        }

        if ((nil != noFileItem) && FileManager().fileExists(atPath: item.filePath!.path)) {
            self.removeRecordFromNoFileCache(url: url);
            self.addRecordToCache(item: item, key: url);
        }
    }
}

extension FTWatchRecordingCollection_Cloud {
    func rootURL() -> URL {
        return self.cloudURL!.appendingPathComponent("Documents").appendingPathComponent("Audio Recordings");
    }

    internal func createFolderIfNeeded() -> Error? {
        let manager = FileManager();
        var isDir = ObjCBool(false);
        let exits = manager.fileExists(atPath: self.rootURL().path, isDirectory: &isDir);
        if(!exits || !isDir.boolValue) {
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Recordings");
            try? manager.removeItem(at: tempURL);
            do {
                try manager.createDirectory(at: tempURL, withIntermediateDirectories: true, attributes: nil);
                try manager.setUbiquitous(true, itemAt: tempURL, destinationURL: self.rootURL());
            } catch let error {
                return error;
            }
        }
        return nil;
    }
}
