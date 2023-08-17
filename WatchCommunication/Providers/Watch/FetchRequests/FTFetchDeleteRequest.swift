//
//  FTFetchDeleteRequest.swift
//  Noteshelf
//
//  Created by Simhachalam on 20/02/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTFetchDeleteRequest: NSObject, FTFetchRequestProtocol {
    var delegate: FTFetchRequestDelegate?
    
    var audioUUID: String!
    var recording: FTWatchRecording?
    var requestUUID : String = UUID().uuidString;
    var callBack: (([String : Any]?, FTWatchRecording?, NSError?) -> ())?;
    var status : FTRequestStatus = FTRequestStatus.executing;

    var requestType : String {
        return "FTFetchDeleteRequest";
    }

    public required init(withAudioUUID audioUUID:String,
                         andRecording recording:FTWatchRecording?)
    {
        super.init()
        self.audioUUID = audioUUID
        self.recording = recording
    }
    
    func startProcessingRequest() {
        #if os(watchOS)
        self.writeLogString("Deleting Audio: \(String(describing: self.audioUUID))");
            let audioToDelete = FTWatchRecordedAudio.init(GUID: self.audioUUID, date: Date(), duration: 0)
            let audioURL = FTWatchRecordingProvider.shared.rootURL().appendingPathComponent(self.audioUUID).appendingPathExtension(audioFileExtension);
            audioToDelete.filePath = audioURL
            
            FTWatchRecordingProvider.shared.deleteRecording(item: audioToDelete, onCompletion: { (error) in
                self.status = FTRequestStatus.completed;
                self.publishQueue.async {
                    self.delegate?.didFinishProcessingFetchRequest(self, withError: error)
                }
            })
        #endif
    }
}
