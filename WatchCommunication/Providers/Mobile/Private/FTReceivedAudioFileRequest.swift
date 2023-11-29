//
//  FTReceivedAudioFileRequest.swift
//  Noteshelf
//
//  Created by Amar on 15/03/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import WatchConnectivity
import FTCommon

class FTReceivedAudioFileRequest: NSObject,FTRequestProtocol {
    var status : FTRequestStatus = FTRequestStatus.pending;
    var error: Error?;
    var requestUUID : String = FTUtils.getUUID();
    var callback : ((Error?)->())?;

    fileprivate var audioFile : WCSessionFile!;
    
    required convenience init(file : WCSessionFile) {
        self.init();
        self.audioFile = file;
    }
    
    func startProcessing(session : WCSession,onCompletion : @escaping (Error?)->())
    {
        guard let newRecordingDict = self.audioFile.metadata?[PublishRequestKey.publishAudioToMobile.rawValue] as? Dictionary<String, Any> else {
            self.queue.async {
                self.writeLogString("no metadata");
                let error = NSError.resourceNotAvailbaleError();
                self.error = error;
                self.status = FTRequestStatus.completedWithError;
                onCompletion(error);
            }
            return;
        }
        
        let newRecording = FTWatchRecordedAudio.initWithDictionary(newRecordingDict)
        let url = URL.init(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(newRecording.GUID).appendingPathExtension(audioFileExtension);
        try? FileManager().removeItem(at: url)
        do {
            try FileManager().moveItem(at: self.audioFile.fileURL.urlByDeleteingPrivate(), to: url);
        }
            
        catch let error as NSError{
            self.queue.async {
                self.writeLogString("Handling failed: \(error)");
                self.error = error;
                self.status = FTRequestStatus.completedWithError;
                onCompletion(error);
            }
            return
        }
        newRecording.filePath = url;
        newRecording.syncStatus = .synced

        FTNoteshelfDocumentProvider.shared.addRecording(tempRecord: newRecording, onCompletion: { (newRecording, error) in
            self.queue.async {
                if(error == nil) {
                    self.status = FTRequestStatus.completed;
                    self.writeLogString("Received successfully");
                }
                else {
                    self.status = FTRequestStatus.completedWithError;
                    self.error = error;
                    self.writeLogString("Received with error: \(error!)");
                }
                onCompletion(self.error);
            }
        });
    }

}
