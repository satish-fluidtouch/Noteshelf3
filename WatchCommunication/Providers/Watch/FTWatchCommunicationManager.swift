//
//  FTWatchCommunicationManager.swift
//  Noteshelf
//
//  Created by Simhachalam on 07/02/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import WatchConnectivity

let FTDeletedGUIDDefaultsKey = "DeletedGUIDs";

enum FTSyncStatus : Int {
    case none
    case publishing
    case fetching
}

class FTWatchCommunicationManager: FTBaseCommunicationManager, WCSessionDelegate, FTFetchRequestDelegate,FTPublishRequestDelegate {
    
    var watchDispatchQueue:DispatchQueue  = DispatchQueue.init(label: "com.fluidtouch.watchCommunication", qos: DispatchQoS.background, attributes: [], autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit, target: nil)
    static let shared = FTWatchCommunicationManager()
    var fetchRequests:[FTFetchRequestProtocol]! = []
    var failedPublishGUIDs:[String]! = []
    fileprivate var currentRunningRequest: Any?
    
    var syncStatus = FTSyncStatus.none;
    
    fileprivate var shouldSendLogFile = false;
    
    override init() {
        super.init()
        if(UserDefaults.standard.value(forKey: FTDeletedGUIDDefaultsKey) == nil){
            UserDefaults.standard.setValue([], forKey: FTDeletedGUIDDefaultsKey)
            UserDefaults.standard.synchronize()
        }
        if WCSession.isSupported() {
            let session:WCSession = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    // MARK: WCSessionDelegate
    @available(watchOSApplicationExtension 6.0, *)
    func sessionCompanionAppInstalledDidChange(_ session: WCSession) {
        if session.isCompanionAppInstalled {
            self.wakeUpAudioPublisherIfNeeded()
        }
        else{
            self.publishDidFinish()
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
        #if DEBUG
        debugPrint("session:activationDidCompleteWith: \(activationState.toDebugString)")
        #endif
        
        if(session.outstandingFileTransfers.count > 0
            || session.outstandingUserInfoTransfers.count > 0) {
            self.writeLogString("session outstanding file Transfers : \(session.outstandingFileTransfers.count) userInfo transfer: \(session.outstandingUserInfoTransfers.count)")
        
            session.outstandingFileTransfers.forEach { (audioFile) in
                audioFile.cancel()
            }
            session.outstandingUserInfoTransfers.forEach { (userInfo) in
                userInfo.cancel()
            }
        }

        #if DEBUG
        debugPrint("AFTER: sessionOutstandingFiles: \(session.outstandingFileTransfers) \nsessionOutstandingUserInfos: \(session.outstandingUserInfoTransfers)")
        #endif
        if activationState == .activated {
            self.writeLogString("session activated");
            self.session = session
            self.session?.delegate = self
            self.session?.activate()
            if #available(watchOSApplicationExtension 6.0, *) {
                if session.isCompanionAppInstalled {
                    self.startPublishing()
                }
            } else {
                self.startPublishing()
            }
        } else {
            self.writeLogString("session not activated: \(activationState)");
            self.session = nil
        }
    }
    
    /** ------------------------- Interactive Messaging ------------------------- */
    public func sessionReachabilityDidChange(_ session: WCSession) {
        self.writeLogString("sessionReachabilityDidChange: \(session.isReachable)");
        if session.isReachable {
            self.session = session;
            self.session?.delegate = self
            self.session?.activate()

            if let proto = self.currentRunningRequest as? FTRequestProtocol,proto.status == FTRequestStatus.waiting {
                let info = [FTMessageUUIDKey : proto.requestUUID,FTSesssionActionKey : "status","requestType" : proto.requestType];
                self.writeLogString("sending status: \(proto.requestUUID)");
                session.sendMessage(info,
                                    replyHandler: { (response) in
                                        self.watchDispatchQueue.async {
                                            let responseStatus = response["status"] as! String;
                                            self.writeLogString("response received: \(responseStatus)");
                                            if(responseStatus == "error") {
                                                proto.callBack?(nil,nil,NSError.notReachableError());
                                            }
                                            else if(responseStatus == "noPendingTasks") {
                                                proto.callBack?(nil,nil,NSError.notReachableError());
                                            }
                                        }
                }, errorHandler: { (error) in
                    self.writeLogString("Error received: \(error.localizedDescription)");
                });
            }
            else {
                session.sendMessage([FTSesssionActionKey : "status"], replyHandler: nil, errorHandler: nil);
            }
            
            self.startPublishing()
        }
    }

    /** -------------------------- Acknowledgement From Mobile When Audio Received ------------------------- */
    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?)
    {
        self.watchDispatchQueue.async {
            var recording: FTWatchRecording?
            if let publishRequest = self.currentRunningRequest as? FTPublishAudioRequest {
                recording = publishRequest.recording;
            }
            (self.currentRunningRequest as? FTRequestProtocol)?.callBack?(fileTransfer.file.metadata?[PublishRequestKey.publishAudioToMobile.rawValue] as? [String : Any], recording, error as NSError?);
        }
    }
    func wakeUpAudioPublisherIfNeeded(){
        self.startPublishing()
    }
    
    internal func isSessionActive() -> Bool
    {
        if let watchSession = self.session, watchSession.isReachable ,watchSession.activationState == .activated {
            return true;
        }
        return false;
    }
}

//MARK: - Fetch -
extension FTWatchCommunicationManager
{
    internal func startFetching()
    {
        self.writeLogString("Fetch began");
        if(self.fetchRequests.isEmpty) {
            self.fetchDidFinish()
        }
        else {
            self.fetchRequests.first?.startProcessingRequest()
        }
    }
    
    internal func startFetchingNextRequest() {
        if self.isSessionActive() {
            self.nextPublishRequest({ (publishRequest) in
                if(nil == publishRequest) {
                    let nextFetchrequest = self.fetchRequests.first;
                    if(nil == nextFetchrequest) {
                        self.fetchDidFinish()
                    }
                    else {
                        self.shouldSendLogFile = true;
                        self.currentRunningRequest = nextFetchrequest;
                        nextFetchrequest?.startProcessingRequest();
                    }
                }
                else {
                    self.fetchDidFinish();
                    self.startPublishing();
                }
            });
        }
        else {
            self.fetchDidFinish()
        }
    }
    
    fileprivate func fetchDidFinish()
    {
        self.writeLogString("Fetch finished");
    }
    
    //MARK:- FTFetchRequestDelegate
    func didFinishProcessingFetchRequest(_ request: FTFetchRequestProtocol, withError error: Error?) {
        watchDispatchQueue.async {
            if(nil == error) {
                self.writeLogString("did finish fetch request: \(String(describing: request.audioUUID))");
            }
            else {
                self.writeLogString("did finish fetch request: \(String(describing: request.audioUUID)) error:\(String(describing: error?.localizedDescription))");
            }
            
            let requestIndex = self.fetchRequests.index(where: { (item) -> Bool in
                if(item.audioUUID == request.audioUUID) {
                    return true;
                }
                return false;
            });
            
            self.currentRunningRequest = nil
            
            if (requestIndex != nil){
                self.fetchRequests.remove(at: requestIndex!)
            }
            self.startFetchingNextRequest();
        }
    }
}

//MARK: - Publish -
extension FTWatchCommunicationManager
{
    fileprivate func startPublishing() {
        if (self.syncStatus != .none) {
            return
        }
        
        self.shouldSendLogFile = false;
        self.syncStatus = .publishing;
        self.writeLogString("publish began");
        self.publishNextRequest()
    }
    
    fileprivate func publishNextRequest()
    {
        if(self.isSessionActive()) {
            weak var weakSelf = self
            self.nextPublishRequest({ (publishRequest) in
                self.currentRunningRequest = publishRequest;
                if(publishRequest == nil){
                    weakSelf?.publishDidFinish();
                }
                else
                {
                    self.shouldSendLogFile = true;
                    publishRequest?.startProcessingRequest()
                }
            });
        }
        else {
            self.publishDidFinish();
        }
    }
    
    fileprivate func publishDidFinish()
    {
        self.writeLogString("Publish finished");
        self.syncStatus = .none
        //self.startFetchingRequestToMobile();
    }

    fileprivate func nextPublishRequest(_ onCompletion: @escaping ((FTPublishRequestProtocol?) -> Void)){
        var publishRequest: FTPublishRequestProtocol?
        FTWatchRecordingProvider.shared.allRecordings({ (allRecordings) in
            
//            let watchDeletedAudioGUIDs:[String] = UserDefaults.standard.value(forKey: FTDeletedGUIDDefaultsKey) as! [String]
            
//            watchDeletedAudioGUIDs.forEach({ (GUID) in
//                if((self.failedPublishGUIDs.contains(GUID) == false)){
//                    let newRequest = FTPublishDeleteRequest.init(withAudioUUID: GUID, andRecording: nil)
//                    newRequest.delegate = self
//                    publishRequest = newRequest
//                    return
//                }
//            })
            
//            if (publishRequest == nil){
            let recordingItem = allRecordings.first(where: { (recording) -> Bool in
                if(recording.syncStatus == .notSynced && (self.failedPublishGUIDs.contains(recording.GUID) == false)){
                    return true;
                }
                return false;
            });
            
            if let recording = recordingItem {
                let newRequest = FTPublishAudioRequest.init(withAudioUUID : recording.GUID, andRecording: recording)
                newRequest.delegate = self
                publishRequest = newRequest
            }
//            }
            if(publishRequest == nil){
                self.failedPublishGUIDs.removeAll()
            }
            onCompletion(publishRequest)
        })
    }
    
    //MARK:- FTPublishRequestDelegate
    func didFinishProcessingPublishRequest(_ request: FTPublishRequestProtocol, withError error: Error?) {
        watchDispatchQueue.async {
            if(error != nil){
                self.writeLogString("didFinishProcessingPublishRequest \(String(describing: request.audioUUID)) error:\(String(describing: error?.localizedDescription))");
                self.failedPublishGUIDs.append(request.audioUUID)
            }
            else {
                self.writeLogString("didFinishProcessingPublishRequest \(String(describing: request.audioUUID))");
            }
            self.currentRunningRequest = nil
            self.publishNextRequest();
        }
    }
}
