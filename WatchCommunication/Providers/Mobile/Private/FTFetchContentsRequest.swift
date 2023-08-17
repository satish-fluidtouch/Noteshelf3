//
//  FTFetchContentsRequest.swift
//  Noteshelf
//
//  Created by Amar on 12/03/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import WatchConnectivity
import FTCommon

class FTFetchContentsRequest: NSObject,FTRequestProtocol {

    var status: FTRequestStatus = FTRequestStatus.pending;
    var error: Error?
    var callback : ((Error?)->())?;

    fileprivate var existingIDs : [String]!;
    fileprivate var deletedIDs : [String]!;

    var requestUUID : String = FTUtils.getUUID();

    required convenience init(existingIDs : [String],deletedIDs : [String]) {
        self.init();
        self.existingIDs = existingIDs;
        self.deletedIDs = deletedIDs;
    }
    
    deinit {
        #if DEBUG
        debugPrint("FTFetchContentsRequest - deinit");
        #endif
    }

    func startProcessing(session : WCSession,onCompletion : @escaping (Error?)->Void)
    {
        self.fetchRequest(withExisting: self.existingIDs,
                          deletedGUIDs: self.deletedIDs,
                          completion: { (dictInfo) in
                            DispatchQueue.main.async {
                                let watchSession = WCSession.default
                                if(!watchSession.isReachable) {
                                    self.queue.async {
                                        self.error = NSError.notReachableError();
                                        onCompletion(self.error);
                                    }
                                    return;
                                }
                                
                                DispatchQueue.main.async {
                                    self.writeLogString("Sending contents");
                                    let userInfo = [FetchRequestKey.fetchRequestResponse.rawValue : dictInfo,
                                                    FTMessageUUIDKey : self.requestUUID] as [String : Any];
                                    
                                    self.callback = { (error) in
                                        self.error = error;
                                        onCompletion(self.error);
                                        self.callback = nil;
                                    }
                                    watchSession.transferUserInfo(userInfo)
                                }
                            }
        });
    };
    
    fileprivate func fetchRequest(withExisting watchGUIDs:[String],
                                  deletedGUIDs: [String],
                                  completion: @escaping ((Dictionary<String, [String]>) -> Void))
    {
        #if DEBUG
        debugPrint("fetchRequest(withExisting watchGUIDs...")
        #endif
        var dictFileStatus:Dictionary<String, [String]> = ["DeletedItems":[],"UpdatedItems":[]]
        
        self.queue.async {
            FTNoteshelfDocumentProvider.shared.allRecordings({ (allRecordings) in
                self.writeLogString("ecordings");

                let watchAudioGUIDSet:Set<String> = Set(watchGUIDs)
                var mobileAudioGUIDSet:Set<String> = Set((allRecordings as NSArray).value(forKeyPath: "GUID") as! [String])
                let deletedWatchAudioGUIDSet:Set<String> = Set(deletedGUIDs)
                
                mobileAudioGUIDSet.subtract(watchAudioGUIDSet)
                mobileAudioGUIDSet.subtract(deletedWatchAudioGUIDSet)
                
                dictFileStatus["UpdatedItems"]!.append(contentsOf: Array(mobileAudioGUIDSet))
                
                let mobileAudioGUIDs:[String] = (allRecordings as NSArray).value(forKeyPath: "GUID") as! [String]
                watchGUIDs.forEach({ (watchGUID) in
                    if(!mobileAudioGUIDs.contains(watchGUID)){
                        dictFileStatus["DeletedItems"]!.append(watchGUID)
                    }
                })
                self.writeLogString("FetchRequestKey.fetchRequest.rawValue");
                completion(dictFileStatus)
            })
        }
    }
}
