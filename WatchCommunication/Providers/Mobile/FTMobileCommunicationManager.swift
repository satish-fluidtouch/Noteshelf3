//
//  FTMobileCommunicationManager.swift
//  Noteshelf
//
//  Created by Simhachalam on 07/02/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//
import Foundation
import WatchConnectivity
import FTCommon
#if os(iOS)
    #if !targetEnvironment(macCatalyst)
#endif
    import AVFoundation
    #if !targetEnvironment(macCatalyst)
#endif
#endif

enum FTRequestStatus : Int {
    case pending
    case transfering
    case completed
    case completedWithError
}

let FTWatchRecordDidAddNewNotification = "FTWatchRecordDidAddNewNotification";
let FTWatchRecordDidDeleteNotification = "FTWatchRecordDidDeleteNotification";
let FTWatchRecordDidUpdateNotification = "FTWatchRecordDidUpdateNotification";

protocol FTRequestProtocol {
    func startProcessing(session : WCSession,onCompletion : @escaping (Error?)->());
    var status : FTRequestStatus {get set};
    var requestUUID : String {get set};
    var error : Error? {get set};
    
    var platformIdentifier : String { get }
    var queue : DispatchQueue { get }
    
    var callback : ((Error?)->())? { get set};
    
    func writeLogString(_ newlog : String);
}

extension FTRequestProtocol
{
    var queue : DispatchQueue {
        return FTMobileCommunicationManager.shared.mobileDispatchQueue;
    }
    
    var platformIdentifier : String {
        return FTMobileCommunicationManager.shared.platformIdentifier;
    }
    
    func writeLogString(_ newlog : String)
    {
        FTMobileCommunicationManager.shared.writeLogString(newlog);
    }
}

class FTMobileCommunicationManager: FTBaseCommunicationManager, WCSessionDelegate {
    
    static let shared = FTMobileCommunicationManager()
    var mobileDispatchQueue:DispatchQueue  = DispatchQueue.init(label: "com.fluidtouch.mobileCommunication", qos: DispatchQoS.background, attributes: [], autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit, target: nil)

    private var currentRequest : FTRequestProtocol?;
    
    override init() {
        super.init()
    }
    
    deinit{
    }
    
    func startWatchSession(){
        if WCSession.isSupported() {
            let session:WCSession = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?)
    {
        if(!session.outstandingFileTransfers.isEmpty
            || !session.outstandingUserInfoTransfers.isEmpty) {
            
            self.writeLogString("session outstanding file Transfers : \(session.outstandingFileTransfers.count) userInfo transfer: \(session.outstandingUserInfoTransfers.count)")
            session.outstandingUserInfoTransfers.forEach({ (userInfo) in
                userInfo.cancel()
            });
            
            session.outstandingFileTransfers.forEach({ (audioFile) in
                audioFile.cancel()
            });
        }

        if activationState == .activated {
            self.writeLogString("session activated");
            self.session = session
            NSUbiquitousKeyValueStore.default.updateStatus(watchPaired: session.isPaired,
                                                             watchAppInstalled: session.isWatchAppInstalled);
        } else {
            self.writeLogString("session not activated: \(activationState)");
            self.session = nil
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession)
    {

    }
    
    func sessionDidDeactivate(_ session: WCSession)
    {
    
    }
    
    func sessionWatchStateDidChange(_ session: WCSession)
    {
        if session.isReachable == false {
            self.writeLogString("watch not reachable");
            self.startWatchSession();
        }
        
        if session.activationState == .activated {
            NSUbiquitousKeyValueStore.default.updateStatus(watchPaired: session.isPaired,
                                                             watchAppInstalled: session.isWatchAppInstalled);
        }

    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        self.writeLogString("sessionReachabilityDidChange: \(session.isReachable)");
    }
    
    // Recieved an audio file from Apple Watch
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        if let metaDate = file.metadata, let type = metaDate["FileType"] as? String, type == "log" {
            let logger = FTLogger.init(fileName: "WatchOS-watchsynclog.txt", createIfNeeded: false);
            let path = logger.logPath();
            try? FileManager().removeItem(at: path)
            try? FileManager().moveItem(at: file.fileURL.urlByDeleteingPrivate(), to: path);
            return;
        }
        self.writeLogString("Received file : \(file.fileURL.lastPathComponent)");

        var requestID = FTUtils.getUUID();
        if let metaData = file.metadata, let idValue = metaData[FTMessageUUIDKey] as? String {
            requestID = idValue;
        }

        var audioFileGUID : String?;
        if let newRecordingDict = file.metadata?[PublishRequestKey.publishAudioToMobile.rawValue] as? Dictionary<String, Any> {
            audioFileGUID = newRecordingDict["GUID"] as? String;
        }

        if !NSUbiquitousKeyValueStore.default.isWatchAppInstalled(),
            session.activationState == .activated {
            NSUbiquitousKeyValueStore.default.updateStatus(watchPaired: session.isPaired,
                                                           watchAppInstalled: session.isWatchAppInstalled);
        }
        
        let request = FTReceivedAudioFileRequest.init(file: file);
        request.requestUUID = requestID;
        self.currentRequest = request;
        request.startProcessing(session: session) { (error) in
            if(nil != error) {
                self.currentRequest?.error = error;
                self.writeLogString("Failed: \(error!.localizedDescription)");
                UserDefaults.markAudioFileIDAsSyncedWithError(audioFileGUID!);
            }
            else {
                #if os(iOS)
                    FTCLSLog("Watch Recording : Recieved new recording")
                #endif
                UserDefaults.markAudioFileIDAsSynced(audioFileGUID!);
                self.currentRequest = nil;
                self.writeLogString("Recieved successfully");
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Notification.Name.init(FTWatchRecordDidAddNewNotification), object: nil,userInfo : ["shouldDisplay" : true]);
                }
            }
            
            #if os(iOS)
                if(nil == error) {
                    FTUserDefaults.incrementWatchAudioFileReceived();
                }
            #endif
        };
    }
}
extension UIApplication.State {
    var stringValue: String {
        switch self {
        case .active: return "active"
        case .inactive: return "inactive"
        case .background: return "background"
        }
    }
}

extension UserDefaults {
    static func markAudioFileIDAsSynced(_ fileID : String) {
        var items = UserDefaults.standard.object(forKey: "syncedItems") as? [String];
        if(nil == items) {
            items = [String]();
        }
        var mutableSet = Set(items!);
        mutableSet.insert(fileID);
        UserDefaults.standard.set(Array(mutableSet), forKey: "syncedItems");
        UserDefaults.standard.synchronize();
    }
    
    static func isAudioFileIDPresentInSynced(_ fileID : String) -> Bool {
        var present = false;
        let items = UserDefaults.standard.object(forKey: "syncedItems") as? [String];
        if((nil != items) && (items!.contains(fileID))) {
            present = true;
        }
        return present;
    }
    
    static func removeAudioFileIDFromSynced(_ fileID : String)
    {
        var items = UserDefaults.standard.object(forKey: "syncedItems") as? [String];
        if(nil != items) {
            let index = items!.index(of: fileID);
            items?.remove(at: index!);
            UserDefaults.standard.set(items, forKey: "syncedItems");
            UserDefaults.standard.synchronize();
        }
    }
    
    static func markAudioFileIDAsSyncedWithError(_ fileID : String) {
        var items = UserDefaults.standard.object(forKey: "syncedItemsFailed") as? [String];
        if(nil == items) {
            items = [String]();
        }
        var mutableSet = Set(items!);
        mutableSet.insert(fileID);
        UserDefaults.standard.set(Array(mutableSet), forKey: "syncedItemsFailed");
        UserDefaults.standard.synchronize();
    }

    static func removeAudioFileIDFromSyncedWithError(_ fileID : String)
    {
        var items = UserDefaults.standard.object(forKey: "syncedItemsFailed") as? [String];
        if(nil != items) {
            let index = items!.index(of: fileID);
            items?.remove(at: index!);
            UserDefaults.standard.set(items, forKey: "syncedItemsFailed");
            UserDefaults.standard.synchronize();
        }
    }

    static func isAudioFileIDPresentInSyncedWithError(_ fileID : String) -> Bool {
        var present = false;
        let items = UserDefaults.standard.object(forKey: "syncedItemsFailed") as? [String];
        if((nil != items) && (items!.contains(fileID))) {
            present = true;
        }
        return present;
    }

}
