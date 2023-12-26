//
//  FTRecognitionLanguageResouerce.swift
//  Noteshelf
//
//  Created by Naidu on 29/06/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import ZipArchive
import FTCommon

enum FTBundleResourceStatus {
    case none
    case downloading
    case downloaded
}
let FTRecognitionLanguageDidChange = "FTRecognitionLanguageDidChange"

private let MY_SCRIPT_APP_SUPPORT_VERSION = "2.3";
private let myScriptPath = "myscript/v\(MY_SCRIPT_APP_SUPPORT_VERSION)/";
private let offlineLangauges = ["en_US", "zh_CN"]

class FTRecognitionLangResource: NSObject{
    private var taskID : UIBackgroundTaskIdentifier?;
    
    var resourceRequest: NSBundleResourceRequest?
    fileprivate var resourceURL:URL {
        if(self.languageCode == "zh_TW"
            || self.languageCode == "zh_HK"
            || isInChinaRegion()) {
            return FTServerConfig.chinaRegionURL.appendingPathComponent(myScriptPath);
        }
        return FTServerConfig.awsResourceURL.appendingPathComponent(myScriptPath);
    }
    fileprivate var downloadTask : URLSessionDownloadTask!;
    fileprivate var session : URLSession!;
    internal var downloadCompletionCallback : (()->())?;
    var activateWhenDownloaded: Bool = false
    
    var displayName: String!
    var nativeDisplayName: String {
        return self.languageCode.nativeDisplayName
    }
    
    var languageEventName: String!
    
    var languageCode: String!
    var resourceStatus: FTBundleResourceStatus = FTBundleResourceStatus.none{
        didSet{
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: FTResourceDownloadStatusDidChange), object: nil)
            if(self.resourceStatus == .downloaded){
                if (self.activateWhenDownloaded && (FTLanguageResourceManager.shared.lastSelectedLangCode == self.languageCode)) {
                    self.activateWhenDownloaded = false
                    FTLanguageResourceManager.shared.currentLanguageCode = self.languageCode
                    FTLanguageResourceManager.shared.isPreferredLanguageChosen = true //Assuming this is automatic resource request, so setting isPreferredLanguageChosen to true
                }
                self.downloadCompletionCallback?()
            }
        }
    }
    
    convenience init(with displayNameKey:String, languageCode: String, eventLanguageName:String){
        self.init()
        self.displayName = FTLanguageLocalizedString(displayNameKey, comment: "")
        self.languageEventName = eventLanguageName
        self.languageCode = languageCode
        if(offlineLangauges.contains(languageCode)){
            self.resourceStatus = FTBundleResourceStatus.downloaded
        }
        else{
            if(languageCode != languageCodeNone) {
                let languagePathURL = URL.recognitionResourcesFolderURL().appendingPathComponent("recognition-assets-" + self.languageCode)
                var isDir = ObjCBool.init(true);
                if FileManager.default.fileExists(atPath: languagePathURL.path, isDirectory: &isDir){
                    self.resourceStatus = FTBundleResourceStatus.downloaded
                }
            }
            else {
                self.resourceStatus = FTBundleResourceStatus.downloaded;
            }
        }
    }
    
    deinit {
        #if DEBUG
        debugPrint("\(type(of: self)) is deallocated");
        #endif
    }
    func downloadResourceOnDemand(){
        if(self.resourceStatus != .none){
            return
        }
        self.resourceStatus = .downloading
        self.downloadResource(forLanuguage: self.languageCode)
    }
}
//================================
extension FTRecognitionLangResource: URLSessionDownloadDelegate {
    
    private func endBackgroundTask() {
        runInMainThread {
            if let task = self.taskID {
                UIApplication.shared.endBackgroundTask(task)
                self.taskID = nil;
            }
        }
    }
    
    func downloadResource(forLanuguage languageCode: String)
    {
        self.taskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.downloadTask.cancel();
        }
        let assetURL = self.resourceURL.appendingPathComponent("recognition-assets-\(languageCode).zip")
        let request = URLRequest(url: assetURL);
        self.session = URLSession.init(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil);
        self.downloadTask = self.session.downloadTask(with: request);
        self.downloadTask.resume();
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
    {
        var processFailed = false;
        do {
            let moveURL = location.deletingLastPathComponent().appendingPathComponent("recognition-assets-" + languageCode);
            try? FileManager().removeItem(at: moveURL);
            try FileManager().moveItem(at: location, to: moveURL);
            let unzipPath = URL.recognitionResourcesFolderURL()
            
            let success = SSZipArchive.unzipFile(atPath: moveURL.path, toDestination: unzipPath.path);
            try? FileManager().removeItem(at: moveURL);
            if(!success) {
                processFailed = true;
            }
        }
        catch {
            processFailed = true;
        }
        
        if(processFailed) {
            self.handleDownloadFailure(withError: nil)
        }
        else {
            runInMainThread {
                self.resourceStatus = FTBundleResourceStatus.downloaded
            }
        }
        self.endBackgroundTask();
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if(nil != error) {
            self.handleDownloadFailure(withError: error)
        }
        self.endBackgroundTask();
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    {
        #if DEBUG
        DispatchQueue.main.async {
            let progress = Int((Float(totalBytesWritten)/Float(totalBytesExpectedToWrite))*100);
            debugPrint("Recognition progress: \(progress)")
        };
        #endif
    }
    
    private func handleDownloadFailure(withError resourceError:Error?)
    {

        if FTLanguageResourceManager.shared.currentLanguageCode == nil{ //Assuming this is automatic resource request, so setting en_US as current language on failure
            FTLanguageResourceManager.shared.currentLanguageCode = "en_US"
        }
        else
        {
            if FTLanguageResourceManager.shared.lastSelectedLangCode == self.languageCode {
                FTLanguageResourceManager.shared.lastSelectedLangCode = ""
                FTLanguageResourceManager.shared.currentLanguageCode = FTLanguageResourceManager.shared.currentLanguageCode //To fire notification
            }
        }
        self.resourceStatus = FTBundleResourceStatus.none
    }
}

//================================
extension URL{
    static func recognitionResourcesFolderURL() -> URL
    {
        let libraryPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.libraryDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first;
        let recognitionFolderPath = URL(fileURLWithPath: libraryPath!).appendingPathComponent("RecognitionResources");
        
        var isDir = ObjCBool.init(false);
        if(!FileManager.default.fileExists(atPath: recognitionFolderPath.path, isDirectory: &isDir) || !isDir.boolValue) {
            _ = try? FileManager.default.createDirectory(at: recognitionFolderPath, withIntermediateDirectories: true, attributes: nil);
        }
        return recognitionFolderPath;
    }
}
//================================
extension Bundle {
    static func languageConfigurationPath(forLanguage langCode: String) -> String?{
        if offlineLangauges.contains(langCode) {
            return Bundle.main.path(forResource: "recognition-assets-\(langCode)/conf", ofType: "")
        }
        let configurationPathURL = URL.recognitionResourcesFolderURL().appendingPathComponent("recognition-assets-" + langCode + "/conf")
        if FileManager.default.fileExists(atPath: configurationPathURL.path)
        {
            return configurationPathURL.path
        }
        return nil
    }
}
//================================
