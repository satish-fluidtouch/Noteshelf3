//
//  FTWatchRecordingStorageManager.swift
//  Noteshelf
//
//  Created by Simhachalam on 30/01/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

/// Base Recording. The base class for a recording.
@objc(FTWatchRecordedAudio)

public class FTWatchRecordedAudio: NSObject,FTWatchRecording {
    
    var date: Date
    var GUID: String
    var fileName: String
    var filePath: URL?
    var duration: Double
    var audioStatus:FTWatchAudioStatus = .unread
    var syncStatus:FTWatchSyncStatus = .notSynced
    var downloadStatus: FTDownloadStatus = FTDownloadStatus.notDownloaded;
    var lastModifiedDate: Date?;
    
    public init(GUID: String, date: Date, duration: Double) {
        self.date = date
        self.duration = duration
        self.audioStatus = .unread
        self.syncStatus = .notSynced
        self.fileName = GUID + ".m4a"
        self.GUID = GUID
        super.init()
    }
    
    class func initWithDictionary(_ dictionary:Dictionary<String, Any>) -> FTWatchRecordedAudio
    {
        let newRecording = FTWatchRecordedAudio.init(GUID: "", date: Date(), duration: 0.0)
        if dictionary["GUID"] != nil{
            newRecording.GUID = dictionary["GUID"]! as! String
        }
        newRecording.updateMetadata(dictionary: dictionary);
        return newRecording
    }
    
    func updateMetadata(dictionary : [String:Any])
    {
        self.fileName = dictionary["fileName"] as! String
        self.date = dictionary["date"] as! Date
        self.duration = (dictionary["duration"] as! NSNumber).doubleValue
        self.audioStatus = FTWatchAudioStatus(rawValue: Int((dictionary["audioStatus"]! as! NSString).intValue))!
        self.syncStatus = FTWatchSyncStatus(rawValue: Int(((dictionary["syncStatus"] ?? "0") as! NSString).intValue)) ?? .notSynced
    }

    public func dictionaryRepresentation()->Dictionary<String,Any>
    {
        var dictAudio:Dictionary<String,Any>=[:]
        dictAudio["GUID"]=self.GUID
        dictAudio["fileName"]=self.fileName
        dictAudio["date"]=self.date
        dictAudio["duration"]=self.duration
        dictAudio["audioStatus"]=String(describing: self.audioStatus.rawValue)
        dictAudio["syncStatus"]=String(describing: self.syncStatus.rawValue)
        return dictAudio
    }
    
    static func getGUID() -> String {
        return UUID().uuidString
    }
    static func temporaryRecordingURL(withGUID fileGUID:String) -> URL {
        let fileLocationURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileGUID).m4a")
        return fileLocationURL
    }
    
    var audioTitle : String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM YY, h:mm a";

        return formatter.string(from: self.date);
    };
}
