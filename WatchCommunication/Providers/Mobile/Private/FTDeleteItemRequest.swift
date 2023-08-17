//
//  FTDeleteItemRequest.swift
//  Noteshelf
//
//  Created by Amar on 12/03/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import WatchConnectivity
import FTCommon

class FTDeleteItemRequest: NSObject,FTRequestProtocol {

    var requestUUID : String = FTUtils.getUUID();
    var status: FTRequestStatus = FTRequestStatus.pending;
    var error: Error?
    var callback : ((Error?)->())?;

    fileprivate var audioUUID : String!;

    required convenience init(withAudioGUID uuid : String) {
        self.init();
        self.audioUUID = uuid;
    }

    deinit {
        #if DEBUG
        debugPrint("FTDeleteItemRequest - deinit");
        #endif
    }

    func startProcessing(session : WCSession,
                         onCompletion: @escaping (Error?) -> Void)
    {
        self.writeLogString("Deleting \(self.audioUUID ?? "-")");
        guard FTNoteshelfDocumentProvider.shared.isProviderReady else {
            self.error = NSError.notReachableError();
            self.status = FTRequestStatus.completedWithError;
            onCompletion(error);
            return
        }
        
        let audioToDelete = FTWatchRecordedAudio.init(GUID: self.audioUUID, date: Date(), duration: 0)
        let audioURL = FTNoteshelfDocumentProvider.shared.rootAudioRecordingsURL().appendingPathComponent(self.audioUUID).appendingPathExtension(audioFileExtension);
        audioToDelete.filePath = audioURL
        FTNoteshelfDocumentProvider.shared.deleteRecording(item: audioToDelete, onCompletion: { (error) in
            self.queue.async {
                self.error = NSError.resourceNotAvailbaleError();
                if(nil == error) {
                    self.status = FTRequestStatus.completedWithError;
                }
                else {
                    self.status = FTRequestStatus.completed;
                }
                self.error = error;
                onCompletion(error);
            }
        });
    }
}
