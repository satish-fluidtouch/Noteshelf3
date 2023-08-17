//
//  FTLogger.swift
//  Noteshelf
//
//  Created by Amar on 7/2/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

#if targetEnvironment(macCatalyst) || (!NS2_SIRI_APP && os(iOS))
#if !NOTESHELF_ACTION
import FirebaseCrashlytics
#endif
#endif

let CLS_REPORTING_ENABLED_KEY = "CLS_REPORTING_ENABLED_KEY"

private var staticLogger: FTLogger?;

class FTLogger: NSObject {
    fileprivate var fileName: String!;
    fileprivate var fileHandler: FileHandle!;
    fileprivate let loggerQueue = DispatchQueue(label: "com.fluidtouch.logger")

    @objc
    static func userFlowLogger() -> FTLogger {
        if(nil == staticLogger) {
            staticLogger = FTLogger(fileName: "UserFlow.log", createIfNeeded: true);
        }
        return staticLogger!;
    }

    convenience init(fileName: String, createIfNeeded: Bool) {
        self.init();
        self.fileName = fileName;
        if(createIfNeeded) {
            let fileURL = self.logPath();

            let filemanager = FileManager();
            if(!filemanager.fileExists(atPath: fileURL.path)) {
                filemanager.createFile(atPath: fileURL.path, contents: nil, attributes: nil);
            }
            do {
                self.fileHandler = try FileHandle(forWritingTo: self.logPath())
            } catch let error as NSError {
                #if DEBUG
                debugPrint("\(error)");
                #endif
            }
        }
    }

    deinit {
        if(self.fileHandler != nil) {
            self.fileHandler.closeFile();
        }
    }

    @objc
    func log(_ string: String) {
        if self == FTLogger.userFlowLogger() {
            loggerQueue.async {
                self.log(string, truncateIfNeeded: true, addTime: true);
            }
        } else {
            self.log(string, truncateIfNeeded: true);
        }
    }

    @objc
    func log(_ string: String, truncateIfNeeded: Bool, addTime: Bool = false) {
        if(truncateIfNeeded) {
            self.truncateIfNeeded();
        }
        self.fileHandler.seekToEndOfFile();
        var stringToLog = String(format: "%@\n", string);
        if(addTime) {
            stringToLog = String(format: "%@ : %@", NSDate(), stringToLog);
        }
        let data = stringToLog.data(using: String.Encoding.utf8);
        if(data != nil) {
            self.fileHandler.write(data!);
            self.fileHandler.synchronizeFile();
        }
    }

    func logPath() -> URL {
        #if os(iOS)
        let libraryPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.libraryDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first;
        let filePath = libraryPath?.appendingFormat("/%@", self.fileName);
        return URL(fileURLWithPath: filePath!);
        #else
            let libraryPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first;
            let filePath = libraryPath?.appendingFormat("/%@", self.fileName);
            return URL(fileURLWithPath: filePath!);
        #endif
    }

    fileprivate func truncateIfNeeded()
    {
        let attributes = try? FileManager().attributesOfItem(atPath: self.logPath().path);
        if(attributes != nil) {
            let fileSize = (attributes! as NSDictionary).fileSize();
            if(fileSize > 10_000_000) {
                let offset = UInt64(self.fileHandler.offsetInFile / 2);
                self.fileHandler.truncateFile(atOffset: offset);
                self.fileHandler.synchronizeFile();
            }
        }
    }
}

/// IMPORTATNT: This Swift function is being used only by Swift classes, there's another function in NSLogger.m with the same name and implementation in order to reduce the ObjC and Swift interference. Consider updating the ObjC file as well while modifying this.
func FTCLSLog(_ string: String) {
    #if DEBUG
    //print("CLS:", string)
    #endif
    if UserDefaults.standard.bool(forKey: CLS_REPORTING_ENABLED_KEY) {
        FTLogger.userFlowLogger().log(string)
        #if targetEnvironment(macCatalyst) || (!NS2_SIRI_APP && os(iOS))
        #if !NOTESHELF_ACTION
        Crashlytics.crashlytics().log(string);
        #endif
        #endif
    }
}

func FTLogError(_ name: String, attributes: [String: Any]? = nil) {
    let errorStr = "⚠️ Error :\(name) attributes: \(attributes?.description ?? "" )";
    FTCLSLog(errorStr)
    var params = attributes
    if let userid = UserDefaults.standard.object(forKey: "USER_ID_FOR_CRASH") {
        params?["USER_ID"] = userid
    }
    #if targetEnvironment(macCatalyst) || (!NS2_SIRI_APP && os(iOS))
    #if !NOTESHELF_ACTION
    let error = NSError(domain: name, code: 1, userInfo: params);
    Crashlytics.crashlytics().record(error: error);
    #endif
    #endif
}

func debugLog(_ log: String)
{
    #if DEBUG
    debugPrint(log)
    #endif
}
