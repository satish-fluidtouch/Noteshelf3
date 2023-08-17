//
//  FTSendAudioFileRequest.swift
//  Noteshelf
//
//  Created by Amar on 12/03/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import WatchConnectivity
import FTCommon

class FTSendAudioFileRequest: NSObject,FTRequestProtocol {

    var status : FTRequestStatus = FTRequestStatus.pending;
    var error: Error?;
    var requestUUID : String = FTUtils.getUUID();
    var callback : ((Error?)->())?;

    fileprivate var audioUUID : String!;
    
    required convenience init(withAudioGUID uuid : String) {
        self.init();
        self.audioUUID = uuid;
    }

    deinit {
        #if DEBUG
        debugPrint("FTSendAudioFileRequest - deinit");
        #endif
    }

    func startProcessing(session : WCSession,onCompletion : @escaping (Error?)->())
    {
        self.writeLogString("Sending File: \(self.audioUUID ?? "-")");
        self.preprocessRequest(onCompletion: { (resultRecording) in
            if(resultRecording == nil
                || resultRecording!.downloadStatus != .downloaded
                || !FileManager().fileExists(atPath: resultRecording!.filePath!.path))
            {
                if let audioRecording = resultRecording, audioRecording.downloadStatus == .notDownloaded {
                    FTNoteshelfDocumentProvider.shared.startDownloading(item: resultRecording!)
                }
                
                DispatchQueue.main.async {
                    let session = WCSession.default;
                    if(!session.isReachable) {
                        self.status = FTRequestStatus.completedWithError;
                        self.queue.async {
                            self.error = NSError.notReachableError();
                            onCompletion(self.error);
                        }
                        return;
                    }
                    
                    let contentInfo =  [FTMessageFromKey:self.platformIdentifier, FTSesssionActionKey: FetchRequestKey.noAudioResourceAvailable.rawValue, "audioGUID": self.audioUUID];
                    let info = [FetchRequestKey.noAudioResourceAvailable.rawValue : contentInfo,
                                FTMessageUUIDKey : self.requestUUID] as [String : Any];
                    
                    self.status = FTRequestStatus.completedWithError;
                    session.transferUserInfo(info);
                    self.queue.async {
                        self.error = NSError.resourceNotAvailbaleError();
                        onCompletion(self.error);
                    }
                }
                return;
            }
            
            let tempURL = URL.init(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(resultRecording!.GUID).appendingPathExtension(audioFileExtension);
            try? FileManager().removeItem(at: tempURL)
            
            let data = resultRecording!.dictionaryRepresentation()
            let metadata = [FetchRequestKey.requestAudioFromMobile.rawValue: data,
                            FTMessageUUIDKey : self.requestUUID] as [String : Any];
            
            FileManager.copyCoordinatedItemAtURL(resultRecording!.filePath!, toNonCoordinatedURL: tempURL, onCompletion: { (success, error) in
                let session = WCSession.default;
                if(!session.isReachable) {
                    self.status = FTRequestStatus.completedWithError;
                    self.queue.async {
                        self.error = NSError.notReachableError();
                        onCompletion(self.error);
                    }
                    return;
                }
                
                DispatchQueue.main.async {
                    if(nil != error) {
                        let contentInfo = [FTMessageFromKey:self.platformIdentifier, FTSesssionActionKey: FetchRequestKey.noAudioResourceAvailable.rawValue, "audioGUID": self.audioUUID];
                        let userInfo = [FetchRequestKey.noAudioResourceAvailable.rawValue : contentInfo,
                                        FTMessageUUIDKey : self.requestUUID] as [String : Any];
                        session.transferUserInfo(userInfo)
                        self.status = FTRequestStatus.completedWithError;
                        self.queue.async {
                            self.error = error;
                            onCompletion(self.error);
                        }
                    }
                    else {
                        self.callback = { (error) in
                            self.error = error;
                            onCompletion(self.error);
                            self.callback = nil;
                        }

                        session.transferFile(tempURL, metadata: metadata)
                    }
                }
            });
        });
    }
    
    fileprivate func preprocessRequest(onCompletion completion: @escaping ((FTWatchRecording?) -> Void))
    {        
        FTNoteshelfDocumentProvider.shared.allRecordings({ (allRecordings) in
            self.queue.async {
                let resultAudios = allRecordings.filter { audioRecord in
                    return (audioRecord.GUID == self.audioUUID)
                }
                
                if(resultAudios.count > 0) {
                    completion(resultAudios.first)
                }
                else {
                    completion(nil)
                }
            }
        })
    }
}
