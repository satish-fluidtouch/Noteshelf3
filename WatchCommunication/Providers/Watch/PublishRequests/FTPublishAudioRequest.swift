//
//  FTPublishAudioRequest.swift
//  Noteshelf
//
//  Created by Simhachalam on 20/02/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import WatchConnectivity

class FTPublishAudioRequest: NSObject, FTPublishRequestProtocol {
    var delegate: FTPublishRequestDelegate?
    
    var requestType : String {
        return "FTPublishAudioRequest";
    }

    var audioUUID: String!
    var recording: FTWatchRecording?
    
    var callBack: (([String : Any]?, FTWatchRecording?, NSError?) -> ())?;
    var requestUUID: String = UUID().uuidString;
    var status : FTRequestStatus = FTRequestStatus.executing;

    fileprivate var counter : Int = 0;
    
    public required init(withAudioUUID audioUUID:String, andRecording recording:FTWatchRecording?){
        super.init()
        self.audioUUID = audioUUID
        self.recording = recording
    }
    
    func startProcessingRequest() {
        #if os(watchOS)
        self.writeLogString("Publish audio \(String(describing: self.audioUUID))");
            
        let session = WCSession.default;
            if (!session.isReachable) {
                self.status = FTRequestStatus.completed;
                self.writeLogString("Session not reachable");
                self.delegate?.didFinishProcessingPublishRequest(self, withError: NSError.notReachableError())
                return;
            }
            
            
            let data = self.recording!.dictionaryRepresentation()
            let metadata = [PublishRequestKey.publishAudioToMobile.rawValue: data,
                            FTMessageUUIDKey : self.requestUUID] as [String : Any]
            
            DispatchQueue.main.async {
                let session = WCSession.default;
                if (!session.isReachable) {
                    self.status = FTRequestStatus.completed;
                    self.writeLogString("Session not reachable");
                    self.delegate?.didFinishProcessingPublishRequest(self, withError: NSError.notReachableError())
                    return;
                }
                
                self.callBack = { (response,recording,error) in
                    if(response != nil && error == nil) {
                        self.status = FTRequestStatus.completed;
                        if let GUID = response!["GUID"] as? String, GUID == self.recording!.GUID {
                            self.recording!.syncStatus = .synced
                            FTWatchRecordingProvider.shared.updateRecording(item: self.recording!, onCompletion: { (error) in
                                self.delegate?.didFinishProcessingPublishRequest(self, withError: error)
                            })
                        }
                        else
                        {
                            self.writeLogString("Publish Did Finish :: GUID Mismatch");
                        }
                    }
                    else {
                        self.delegate?.didFinishProcessingPublishRequest(self, withError: error)
                        self.callBack = nil;
                    }
                }
                
                if(FileManager().fileExists(atPath: self.recording!.filePath!.path)) {
                    self.writeLogString("Sending file");
                    self.status = FTRequestStatus.waiting;
                    session.transferFile(self.recording!.filePath!, metadata: metadata)
                }
                else {
                    self.status = FTRequestStatus.completed;
                    self.publishQueue.async {
                        self.writeLogString("Resource not available");
                        self.delegate?.didFinishProcessingPublishRequest(self, withError: NSError.resourceNotAvailbaleError())
                        self.callBack = nil;
                    }
                }
            }
        #endif
    }
}
