//
//  FTBaseCommunicationManager.swift
//  Noteshelf
//
//  Created by Simhachalam on 07/02/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import WatchConnectivity
#if os(iOS)
    import AVFoundation
#endif

enum FTAudioFileSyncStatus : String {
    case complete = "complete"
    case error = "error"
    case notYet = "notYet"
}

let FTMessageUUIDKey = "messageUUID";
let FTSesssionActionKey = "sessionAction";
let FTMessageFromKey = "messageFrom";
let FTDeviceKey = "device";
let FTMessageKey = "message";

let FTAudioFileSyncStatusKey = "status";
let FTAudioFileReceivedMessageKey = "AudioFileRecieved";

enum RecordingStoreCommunicationKey: String {
    
    case deleteRecordingInWatch = "delete-recording-in-watch"
    case didDeleteRecordingInWatch = "did-delete-recording-in-watch"
}
enum FetchRequestKey: String {
    case fetchRequest = "fetch-request"
    case fetchRequestResponse = "fetch-request-response"
    case requestAudioFromMobile = "request-audio-from-mobile"
    case noAudioResourceAvailable = "no-audio-resource-available"

    case wakeUp = "wakeup"
    case IAmReadyToReceive = "ready-to-receive"
    case notReachableError = "notReachableError"
    
}
enum PublishRequestKey: String {
    case publishAudioToMobile = "publish-audio-to-mobile"
    case didPublishAudioToMobile = "did-publish-audio-to-mobile"
    case didFailToPublishAudioToMobile = "did-fail-to-publish-audio-to-mobile"
    case deleteAudio = "delete-audio"
}

extension NSError
{
    static func notReachableError() -> NSError
    {
        return NSError.init(domain: "FTWatchSyncError", code: 201, userInfo: [NSLocalizedDescriptionKey : "Device not reachable"]);
    }
    
    static func resourceNotAvailbaleError() -> NSError
    {
        return NSError.init(domain: "FTWatchSyncError", code: 202, userInfo: [NSLocalizedDescriptionKey : "Audio Resource not available"]);
    }
    
    static func providerNotReadyError() -> NSError
    {
        return NSError.init(domain: "FTWatchSyncError", code: 203, userInfo: [NSLocalizedDescriptionKey : "Provider not yet ready"]);
    }
}

public class FTBaseCommunicationManager: NSObject {
    var session: WCSession?
    var fileHandler : FTLogger!
    let platformIdentifier: String = {
        #if os(watchOS)
            return "WatchOS"
        #else
            return "iOS"
        #endif
    }()
    
    fileprivate let logFileName : String = {
        #if os(watchOS)
            return "WatchOS-watchsynclog.txt"
        #else
            return "iOS-watchsynclog.txt"
        #endif
    }();
    
    func writeLogString(_ newLog:String)
    {
        if(nil == self.fileHandler) {
            self.fileHandler = FTLogger.init(fileName: self.logFileName, createIfNeeded: true);
        }
        self.fileHandler.log(newLog, truncateIfNeeded: true, addTime: true);
        #if DEBUG
        debugPrint("\(self.platformIdentifier) \(newLog)");
        #endif
    }
}

extension WCSessionActivationState {
    var toDebugString: String {
        switch self {
        case .activated: return "activated"
        case .inactive: return "inactive"
        case .notActivated: return "not activated"
        default:
            return "UNKNOWN"
        }
    }
}

extension Date
{
    func nsAudioFormatTitle() -> String {
        return DateFormatter.localizedString(from: self, dateStyle: .medium, timeStyle: .short);
    }
    
    func shelfShortStyleFormat() -> String {
        return DateFormatter.localizedString(from: self, dateStyle: .short, timeStyle: .short);
    }
    func shelfItemCreatedDateFormat() -> String {
        return DateFormatter.localizedString(from: self, dateStyle: .short, timeStyle: .none) + " at " +  DateFormatter.localizedString(from: self, dateStyle: .none, timeStyle: .short)
    }
}

extension TimeInterval {
    //https://github.com/apple/swift-corelibs-foundation/blob/master/Foundation/DateComponentsFormatter.swift

    func formatSecondsToString() -> String {
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute, .second ]
        formatter.zeroFormattingBehavior = [ .dropLeading ]
        let formattedDuration = formatter.string(from: self);
        return formattedDuration ?? "00:00:00";
    }
    
    func stringFromTimeInterval() -> String {
        let time = NSInteger(self)
        let ms = Int((self.truncatingRemainder(dividingBy: 1)) * 1000)
        let seconds = time % 60
        let minutes = (time / 60) % 60
        let hours = (time / 3600)
        return String(format: "%0.2d:%0.2d:%0.2d.%0.3d",hours,minutes,seconds,ms)
    }

}
