//
//  FTWatchRecordingProvider.swift
//  Noteshelf
//
//  Created by Amar on 08/02/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

@objc enum FTWatchAudioStatus:Int {
    case unread = 0
    case read
}
@objc enum FTWatchSyncStatus:Int {
    case notSynced = 0
    case synced
}

@objc enum FTWatchProviderType : Int {
    case local
    case cloud
}

let FTRecordingCollectionUpdatedNotification = "FTRecordingCollectionUpdatedNotification";

protocol FTWatchRecordingCollection {
   
    func allRecordings(_ completion : @escaping (([FTWatchRecording]) ->Void));
    
    func addRecording(tempRecord : FTWatchRecording,
                      onCompletion completion:@escaping ((FTWatchRecording?,Error?)->Void));
    
    func deleteRecording(item : FTWatchRecording,
                         onCompletion completion:@escaping ((Error?)->Void));
    
    func updateRecording(item : FTWatchRecording,
                         onCompletion completion:@escaping ((Error?)->Void));
    
    func startDownloading(item : FTWatchRecording);
    
    func rootURL() -> URL;
}

protocol FTWatchRecording : NSObjectProtocol {
    var GUID : String {get set}
    var date : Date {get set}
    var fileName : String {get set}
    var filePath : URL? {get set}
    var duration : Double {get set}
    var audioStatus : FTWatchAudioStatus {get set}
    var syncStatus : FTWatchSyncStatus {get set}
    var downloadStatus : FTDownloadStatus {get set}
    
    var lastModifiedDate : Date? {get set} //used for caching purpose
    func dictionaryRepresentation() -> [String:Any];
    func updateMetadata(dictionary : [String:Any]);
    
    var audioTitle : String { get };
}
extension FTWatchRecording{
    func prepareToCopy(){
        self.GUID = UUID().uuidString;
        self.fileName = self.GUID.appending(".\(audioFileExtension)");
    }
}
