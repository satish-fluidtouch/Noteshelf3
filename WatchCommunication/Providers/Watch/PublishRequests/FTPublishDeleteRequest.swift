//
//  FTPublishDeleteRequest.swift
//  Noteshelf
//
//  Created by Simhachalam on 20/02/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import WatchConnectivity

class FTPublishDeleteRequest: NSObject, FTPublishRequestProtocol {
    weak var delegate: FTPublishRequestDelegate?
    var requestType : String {
        return "FTPublishDeleteRequest";
    }

    var audioUUID: String!
    var recording: FTWatchRecording?
    
    var callBack: (([String : Any]?, FTWatchRecording?, NSError?) -> ())?;
    var requestUUID: String = UUID().uuidString;
    var status : FTRequestStatus = FTRequestStatus.executing;

    public required init(withAudioUUID audioUUID:String, andRecording recording:FTWatchRecording?){
        super.init()
        self.audioUUID = audioUUID
        self.recording = recording
    }

    func startProcessingRequest() {
        #if os(watchOS)
        self.writeLogString("Publish Delete file : \(String(describing: self.audioUUID))");
            let session = WCSession.default;
            if(!session.isReachable) {
                self.status = FTRequestStatus.completed;
                self.delegate?.didFinishProcessingPublishRequest(self, withError: NSError.notReachableError())
                return;
            }
            
            self.callBack = { (response,audio,error) in
                self.status = FTRequestStatus.completed;
                self.delegate?.didFinishProcessingPublishRequest(self, withError: error);
                self.callBack = nil;
            }
            
            self.status = FTRequestStatus.waiting;
            let infoDict:Dictionary<String, Any> = [FTMessageFromKey:FTWatchCommunicationManager.shared.platformIdentifier,
                                                    FTSesssionActionKey:PublishRequestKey.deleteAudio.rawValue,
                                                    "audioGUID": self.audioUUID,
                                                    FTMessageUUIDKey : self.requestUUID];
            self.writeLogString("Sending Message");
            session.sendMessage(infoDict,
                                replyHandler: { (response) in
                                    self.writeLogString("Received reply");
                                    self.publishQueue.async {
                                        var deletedGUIDs:[String] = UserDefaults.standard.value(forKey: FTDeletedGUIDDefaultsKey) as! [String]
                                        let requestIndex = deletedGUIDs.index(where: { (item) -> Bool in
                                            if(item == self.audioUUID) {
                                                return true;
                                            }
                                            return false;
                                        });
                                        
                                        if (requestIndex != nil){
                                            deletedGUIDs.remove(at: requestIndex!)
                                        }
                                        UserDefaults.standard.setValue(deletedGUIDs, forKey: FTDeletedGUIDDefaultsKey)
                                        UserDefaults.standard.synchronize()
                                        
                                        self.status = FTRequestStatus.completed;
                                        self.delegate?.didFinishProcessingPublishRequest(self, withError: nil);
                                        self.callBack = nil;
                                    }
            }, errorHandler: { (errpr) in
                self.status = FTRequestStatus.completed;
                self.publishQueue.async {
                    self.delegate?.didFinishProcessingPublishRequest(self, withError: errpr);
                    self.callBack = nil;
                }
            });
        #endif
    }
    
    func didFinishProcessing() {
        
    }
}
