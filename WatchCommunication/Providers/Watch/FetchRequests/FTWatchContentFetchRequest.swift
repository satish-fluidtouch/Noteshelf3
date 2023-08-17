//
//  FTWatchContentFetchRequest.swift
//  Noteshelf
//
//  Created by Amar on 14/03/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import WatchConnectivity

class FTWatchContentFetchRequest: NSObject , FTFetchRequestProtocol {
    weak var delegate : FTFetchRequestDelegate?
    var audioUUID : String!
    var recording : FTWatchRecording?
    var requestType : String {
        return "FTWatchContentFetchRequest";
    }

    var requestUUID : String = UUID().uuidString;
    var status : FTRequestStatus = FTRequestStatus.executing;
    var callBack: (([String : Any]?, FTWatchRecording?, NSError?) -> ())?;
    
    required init(withAudioUUID audioUUID:String, andRecording recording:FTWatchRecording?)
    {
        super.init()
        self.audioUUID = audioUUID;
    }
    
    func startProcessingRequest()
    {
        self.writeLogString("fetching content started")
            FTWatchRecordingProvider.shared.allRecordings({ (allRecordings) in
                let syncedAudios = allRecordings.filter { audioRecord in
                    return audioRecord.syncStatus == FTWatchSyncStatus.synced
                }
                
                let watchExistingAudioGUIDs:[String] = (syncedAudios as NSArray).value(forKeyPath: "GUID") as! [String]
                let watchDeletedAudioGUIDs:[String] = UserDefaults.standard.value(forKey: FTDeletedGUIDDefaultsKey) as! [String]
                
                DispatchQueue.main.async {
                    let session = WCSession.default
                    if(!session.isReachable) {
                        self.writeLogString("1: Session not reachable");
                        self.status = FTRequestStatus.completed;
                        self.publishQueue.async {
                            self.delegate?.didFinishProcessingFetchRequest(self, withError: NSError.notReachableError());
                        }
                        return
                    }
                    
                    self.callBack = { (response,recording,error) in
                        self.status = FTRequestStatus.completed;
                        self.delegate?.didFinishProcessingFetchRequest(self, withError: error);
                        self.callBack = nil;
                    }

                    let info = [FTMessageUUIDKey : self.requestUUID,
                                FTMessageFromKey:self.platformIdentifier,
                                FTSesssionActionKey:FetchRequestKey.fetchRequest.rawValue,
                                "Existing": watchExistingAudioGUIDs,
                                "Deleted": watchDeletedAudioGUIDs] as [String : Any];
                    
                    self.status = FTRequestStatus.waiting;
                    self.writeLogString("Sending Message");
                    session.sendMessage(info,
                                        replyHandler: { (response) in
                                            self.writeLogString("Received reply");
                    }, errorHandler: { (error) in
                        self.status = FTRequestStatus.completed;
                        self.publishQueue.async {
                            self.delegate?.didFinishProcessingFetchRequest(self, withError: error);
                            self.callBack = nil;
                        }
                    })
                }
            })
    }
}
