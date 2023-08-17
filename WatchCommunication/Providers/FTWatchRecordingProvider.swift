//
//  FTWatchRecordingProvider.swift
//  Noteshelf
//
//  Created by Akshay on 17/01/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTWatchRecordingProvider {
    static let shared = FTWatchRecordingProvider()
    
    fileprivate let watchRecordingsCollection = FTWatchRecordingCollection_Local();

}
extension FTWatchRecordingProvider: FTWatchRecordingCollection {
    
    func allRecordings(_ completion : @escaping (([FTWatchRecording]) ->Void)) {
        watchRecordingsCollection.allRecordings(completion)
    }
    
    func addRecording(tempRecord : FTWatchRecording,
                      onCompletion completion:@escaping ((FTWatchRecording?,Error?)->Void)) {
        watchRecordingsCollection.addRecording(tempRecord: tempRecord, onCompletion: completion)
    }
    
    func deleteRecording(item : FTWatchRecording,
                         onCompletion completion:@escaping ((Error?)->Void)) {
        watchRecordingsCollection.deleteRecording(item: item, onCompletion: completion)
    }
    
    func updateRecording(item : FTWatchRecording,
                         onCompletion completion:@escaping ((Error?)->Void)) {
        watchRecordingsCollection.updateRecording(item: item, onCompletion: completion)

    }
    
    func startDownloading(item : FTWatchRecording) {
        watchRecordingsCollection.startDownloading(item: item)
    }
    
    func rootURL() -> URL {
        return watchRecordingsCollection.rootURL()
    }
}
