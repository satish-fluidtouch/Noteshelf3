//
//  FTWatchRecordingProviderManager.swift
//  Noteshelf
//
//  Created by Amar on 08/02/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

let audioFileExtension : String = "m4a";
let audioMetadataFileExtension : String = "plist";

@objc class FTWatchRecordingProviderManager: NSObject {
    fileprivate static let supportsCloudContentMoving = true;
    
    var currentProvider : FTWatchRecordingProvider?;
    
    #if os(iOS)
    static func provider(onCompletion : @escaping (FTWatchRecordingProviderManager)->Void)
    {
        let watchProvider = FTWatchRecordingProviderManager();
        var provider : FTWatchRecordingProvider = FTWatchRecordingProvider_Local();
        if(FTiCloudManager.shared().iCloudOn()) {
            DispatchQueue.global().async {
                let cloudURL = FileManager().url(forUbiquityContainerIdentifier: nil);
                if(nil != cloudURL) {
                    let cloudProvider = FTWatchRecordingProvider_Cloud();
                    cloudProvider.cloudURL = cloudURL;
                    provider = cloudProvider;
                }
                watchProvider.currentProvider = provider;
                DispatchQueue.main.async {
                    onCompletion(watchProvider);
                }
            }
        }
        else {
            watchProvider.currentProvider = provider;
            DispatchQueue.main.async {
                onCompletion(watchProvider);
            }
        }
    }
    
    deinit {
        #if DEBUG
        debugPrint("deinit \(self.classForCoder)");
        #endif
    }
    
    static func numberOfUnreadItems(onCompletion : @escaping (String,Int) -> ()) -> String
    {
        let token = FTUtils.getUUID();
        onCompletion(token,0);
        return token;
//        FTWatchRecordingProviderManager.provider { (provider) in
//            DispatchQueue.global().async {
//                let providerToConsider = provider.currentProvider;
//                if (nil != providerToConsider) {
//                    providerToConsider!.allRecordings({(recordings) in
//                        let filteredItems = recordings.filter({ (eachRecording) -> Bool in
//                            if(eachRecording.audioStatus == FTWatchAudioStatus.unread) {
//                                return true;
//                            }
//                            return false;
//                        });
////                        _ = provider.currentProvider;
//                        let count = filteredItems.count;
//                        DispatchQueue.main.async {
//                            onCompletion(token,count);
//                        }
//                    });
//                }
//                else {
//                    DispatchQueue.main.async {
//                        onCompletion(token,0);
//                    }
//                }
//            }
//        };
//        return token;
    }
    
    //ENable below methods when needed
    static func moveContentsFromLocalToiCloud(onCompletion : @escaping ((Error?) -> Void)) {
        if(!FTWatchRecordingProviderManager.supportsCloudContentMoving) {
            onCompletion(nil);
            return;
        }
        
        DispatchQueue.global().async {
            let localProvider = FTWatchRecordingProvider_Local();
            localProvider.allRecordings { (items) in
                let cloudProvider = FTWatchRecordingProvider_Cloud();
                cloudProvider.cloudURL = FTiCloudManager.shared().iCloudRootURL();

                cloudProvider.allRecordings({ (cloudItems) in
                    let cloudURL = cloudProvider.rootURL();
                    if(FileManager().isUbiquitousItem(at: cloudURL)) {
                        self.moveItems(items: items,
                                       fromLocalURL: localProvider.rootURL(),
                                       toCloud: cloudURL,
                                       onCompletion: onCompletion);
                    }
                    else {
                        do {
                            try FileManager().setUbiquitous(true, itemAt: localProvider.rootURL(), destinationURL: cloudURL);
                            onCompletion(nil);
                        }
                        catch {
                            DispatchQueue.main.async {
                                onCompletion(error);
                            }
                        }
                    }
                });
            }
        }    }
    
    //ENable below methods when needed
    static func moveContentsFromiCloudToLocal(onCompletion : @escaping ((Error?) -> Void)) {
        if(!FTWatchRecordingProviderManager.supportsCloudContentMoving) {
            onCompletion(nil);
            return;
        }
        DispatchQueue.global().async {
            let localProvider = FTWatchRecordingProvider_Local();
            localProvider.allRecordings { (items) in
                localProvider.createRootIfNeeded();
                
                let cloudProvider = FTWatchRecordingProvider_Cloud();
                cloudProvider.cloudURL = FTiCloudManager.shared().iCloudRootURL();

                cloudProvider.allRecordings({ (cloudItems) in
                    let cloudRootURL = cloudProvider.rootURL();
                    let localRootURL = localProvider.rootURL();
                    self.copyItems(items: cloudItems,
                                   fromCloud: cloudRootURL,
                                   toLocalURL: localRootURL,
                                   onCompletion: onCompletion);
                });
            }
        }
    }
    
    private static func copyItems(items : [FTWatchRecording],
                           fromCloud cloudURL : URL,
                           toLocalURL localURL : URL,
                           onCompletion : @escaping ((Error?)->Void))
    {
        var itemsMutable = items;
        let eachItem = itemsMutable.first;
        if(nil == eachItem) {
            DispatchQueue.main.async {
                onCompletion(nil);
            }
            return;
        }
        itemsMutable.removeFirst();
        let audioCloudURL = eachItem!.filePath!
        let plistCloudURL = audioCloudURL.deletingPathExtension().appendingPathExtension(audioMetadataFileExtension);
        
        let plistLocalURL = localURL.appendingPathComponent(plistCloudURL.lastPathComponent);
        
        let plistInfo = eachItem?.dictionaryRepresentation();
        do {
            try (plistInfo! as NSDictionary).write(to: plistLocalURL);
            let audioLocalURL = plistLocalURL.deletingPathExtension().appendingPathExtension(audioFileExtension);

            try? FileManager().removeItem(at: audioLocalURL);
            
            FileManager.copyCoordinatedItemAtURL(audioCloudURL,
                                                 toNonCoordinatedURL: audioLocalURL,
                                                 onCompletion: { (success, error) in
                if(nil == error) {
                    DispatchQueue.global().async {
                        self.copyItems(items: itemsMutable,
                                       fromCloud: cloudURL,
                                       toLocalURL: localURL,
                                       onCompletion: onCompletion);
                    }
                }
                else {
                    DispatchQueue.main.async {
                        onCompletion(error);
                    }
                }
            });
        }
        catch let fileError {
            DispatchQueue.main.async {
                onCompletion(fileError);
            }
        }
    }
    
    private static func moveItems(items : [FTWatchRecording],
                               fromLocalURL localURL : URL,
                               toCloud cloudURL : URL,
                               onCompletion : @escaping ((Error?)->Void))
    {
        var itemsMutable = items;
        let eachItem = itemsMutable.first;
        if(nil == eachItem) {
            DispatchQueue.main.async {
                onCompletion(nil);
            }
            return;
        }
        itemsMutable.removeFirst();
        let audioPath = eachItem!.filePath!
        let sourcePlist = audioPath.deletingPathExtension().appendingPathExtension(audioMetadataFileExtension);
        
        let destPlist = cloudURL.appendingPathComponent(sourcePlist.lastPathComponent);
        let destAudioURL = destPlist.deletingPathExtension().appendingPathExtension(audioFileExtension);
        
        FileManager.replaceCoordinatedItem(atURL: destPlist, fromLocalURL: sourcePlist) { (error) in
            if(nil == error) {
                FileManager.replaceCoordinatedItem(atURL: destAudioURL,
                                                   fromLocalURL: audioPath,
                                                   onCompletion: { (inError) in
                                                    if(nil == inError) {
                                                        try? FileManager().removeItem(at: sourcePlist);
                                                        try? FileManager().removeItem(at: audioPath);
                                                        
                                                        self.moveItems(items: itemsMutable,
                                                                       fromLocalURL: localURL,
                                                                       toCloud: cloudURL,
                                                                       onCompletion: onCompletion);
                                                    }
                                                    else {
                                                        DispatchQueue.main.async {
                                                            onCompletion(inError);
                                                        }
                                                    }
                });
            }
            else {
                DispatchQueue.main.async {
                    onCompletion(error);
                }
            }
        }
    }
    
    
    fileprivate static func replaceItem(atURL : URL,
                                        toURL : URL,
                                        onCompletion : @escaping (Error?)->()) {
        if(FileManager().isUbiquitousItem(at: toURL)) {
            let sourceModificationDate = atURL.fileModificationDate;
            let destModificationDate = toURL.fileModificationDate;
            
            if(destModificationDate!.compare(sourceModificationDate!) != .orderedDescending) {
                let plistFileIntent = NSFileAccessIntent.writingIntent(with: toURL, options: NSFileCoordinator.WritingOptions.forReplacing);
                let cooridinator = NSFileCoordinator.init();
                cooridinator.coordinate(with: [plistFileIntent], queue: OperationQueue.init(), byAccessor: { (error) in
                    if(nil != error) {
                        onCompletion(error);
                }
                    else {
                        do {
                            _ = try FileManager().replaceItemAt(plistFileIntent.url, withItemAt: atURL);
                            onCompletion(nil);
                        }
                        catch let fileError {
                            onCompletion(fileError);
                        }
                    }
                })
            }
            else {
                onCompletion(nil);
            }
        }
        else {
            do {
                try FileManager().setUbiquitous(true, itemAt: atURL, destinationURL: toURL);
                onCompletion(nil);
            }
            catch let fileError {
                onCompletion(fileError);
            }
        }
    }
    
    #else
    static func provider(onCompletion : @escaping (FTWatchRecordingProviderManager)->Void)
    {
        let watchProvider = FTWatchRecordingProviderManager();
        let provider : FTWatchRecordingProvider = FTWatchRecordingProvider_Local();
        watchProvider.currentProvider = provider;
        onCompletion(watchProvider);
    }
    #endif
}
