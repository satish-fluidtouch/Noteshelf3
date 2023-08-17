//
//  FTFetchAudioRequest.swift
//  Noteshelf
//
//  Created by Simhachalam on 20/02/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import WatchConnectivity

class FTFetchAudioRequest: NSObject, FTFetchRequestProtocol {
    var delegate: FTFetchRequestDelegate?
    var audioUUID: String!
    var requestUUID : String = UUID().uuidString;
    
    var recording: FTWatchRecording?
    var callBack : (([String : Any]?,FTWatchRecording?,NSError?) -> ())?;
    var status : FTRequestStatus = FTRequestStatus.executing;
    var requestType : String {
        return "FTFetchAudioRequest";
    }

    public required init(withAudioUUID audioUUID:String, andRecording recording:FTWatchRecording?){
        super.init()
        self.audioUUID = audioUUID
        self.recording = recording
    }
    
    func startProcessingRequest() {
        #if os(watchOS)
        self.writeLogString("Fetching Audio: \(String(describing: self.audioUUID))");
            
        let session = WCSession.default;
            if(session.isReachable) {
                
                self.callBack = { (response,receivedRecording,error) in
                    self.status = FTRequestStatus.completed;
                    if(error == nil && response == nil) {
                        receivedRecording!.updateMetadata(dictionary: receivedRecording!.dictionaryRepresentation());
                        FTWatchRecordingProvider.shared.addRecording(tempRecord: receivedRecording!, onCompletion: { (newRecording, error) in
                            self.delegate?.didFinishProcessingFetchRequest(self, withError: error)
                        })
                    }
                    else {
                        self.delegate?.didFinishProcessingFetchRequest(self, withError: NSError.init(domain: "AudioResourceError", code: 0, userInfo: nil))
                    }
                    self.callBack = nil;
                }
                
                self.status = FTRequestStatus.waiting;
                let infoDict:Dictionary<String, Any> = [FTMessageFromKey:FTWatchCommunicationManager.shared.platformIdentifier,
                                                        FTSesssionActionKey:FetchRequestKey.requestAudioFromMobile.rawValue,
                                                        "audioGUID": self.audioUUID,
                                                        FTMessageUUIDKey:self.requestUUID];

                session.sendMessage(infoDict, replyHandler: { (response) in
                    self.writeLogString("Recieved Reply");
                }, errorHandler: { (error) in
                    self.status = FTRequestStatus.completed;
                    self.publishQueue.async {
                        self.delegate?.didFinishProcessingFetchRequest(self, withError: error);
                        self.callBack = nil;
                    }
                })
            }
            else {
                self.status = FTRequestStatus.completed;
                self.publishQueue.async {
                    self.delegate?.didFinishProcessingFetchRequest(self, withError: NSError.notReachableError());
                    self.callBack = nil;
                }
            }
        #endif
    }
}
