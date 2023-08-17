//
//  FTNotebookRecognitionHelper.swift
//  Noteshelf
//
//  Created by Naidu on 12/06/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

let minimumTimeDifference: TimeInterval = 5
enum FTNotebookRecognitionStatus
{
    case none,waiting,inProgress,finished;
}

class FTNotebookRecognitionHelper: NSObject {
    var documentUUID = UUID().uuidString;
    weak var currentDocument: FTNoteshelfDocument?
    private var recognitionInProgressInfo = FTRecognitionInProgressPlist()
    
    private let handwriteRecogQueue = DispatchQueue.init(label: "com.fluitouch.handwriteRecog",
                                                         qos: .background,
                                                         attributes: [],
                                                         autoreleaseFrequency: .inherit,
                                                         target: nil);
    
    private var hasPendingRecognitionPages: Bool = true
    private var isRecognitionInProgress: Bool = false
    var recognitionIndexingInfo: [AnyHashable : Any]? {
        didSet {
            var notification:Notification = Notification.init(name: Notification.Name(rawValue: FTRecognitionInfoDidUpdateNotification))
            if(self.recognitionIndexingInfo == nil){
                notification.userInfo = ["status": FTNotebookRecognitionStatus.none]
            }
            else {
                notification.userInfo = self.recognitionIndexingInfo
            }
            NotificationCenter.default.post(notification)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        #if DEBUG
        debugPrint("\(type(of: self)) is deallocated");
        #endif
    }
    
    @objc static var shouldProceedRecognition : Bool {
        if(
            (FTLanguageResourceManager.shared.currentLanguageCode != nil)
                && (FTLanguageResourceManager.shared.currentLanguageCode != languageCodeNone)
        ) {
            return true;
        }
        return false;
    }
    
    convenience init(withDocument document:FTNoteshelfDocument) {
        self.init()
        self.documentUUID = document.documentUUID;
        
        NotificationCenter.default.addObserver(self, selector: #selector(FTNotebookRecognitionHelper.handleLanguageChange(_:)), name: NSNotification.Name(rawValue: FTRecognitionLanguageDidChange), object: nil)
        self.currentDocument = document
        
        NotificationCenter.default.addObserver(forName: FTNotebookRecognitionHelper.myScriptActivatedNotification,
                                               object: nil,
                                               queue: nil) { [weak self] (_) in
            self?.wakeUpRecognitionHelperIfNeeded();
        }
    }
    
    @objc fileprivate func handleLanguageChange(_ sender: Any){
        FTLanguageResourceManager.shared.writeLogString("Recognition Language Changed To:" + FTLanguageResourceManager.shared.currentLanguageDisplayName, currentDocument: self.currentDocument)
        if let selectedLanguage = FTLanguageResourceManager.shared.currentLanguageCode{
            self.currentDocument?.recognitionCache?.updateLanguage(to: selectedLanguage)
        }
        if FTNotebookRecognitionHelper.shouldProceedRecognition {
            self.wakeUpRecognitionHelperIfNeeded()
        }
    }
    
    func startPendingRecognition() {
        if (
            self.hasPendingRecognitionPages == false
            || self.isRecognitionInProgress == true
            ||  FTNotebookRecognitionHelper.shouldProceedRecognition == false
            || !FTNotebookRecognitionHelper.myScriptActivated
            || !supportsHWRecognition
        ){
            return
        }
        
        self.hasPendingRecognitionPages = false
        self.isRecognitionInProgress = true
        
        self.handwriteRecogQueue.async {[weak self] in
            var pickedPage : FTPageProtocol?;
            var engineWaitingTime: TimeInterval = 0.0
            if let allPages = self?.currentDocument?.pages(), !allPages.isEmpty {
                for iCount in 0...allPages.count-1 {
                    let eachPage = allPages[iCount]
                    //****************Recognition Crash Tracking Begin
                    let isCrashedForPage: Bool = self?.recognitionInProgressInfo.isCrashed(forPage: eachPage) ?? false
                    //****************Recognition Crash Tracking End
                    
                    if !isCrashedForPage, (eachPage as! FTNoteshelfPage).canRecognizeHandwriting {
                        var timeDifference = minimumTimeDifference
                        if let recogInfo = eachPage.recognitionInfo{
                            timeDifference = Date.timeIntervalSinceReferenceDate - recogInfo.lastUpdated.doubleValue
                        }
                        if timeDifference >= minimumTimeDifference || timeDifference < 0 {
                            pickedPage = eachPage;
                            #if DEBUG
                            //debugPrint("Page: \(eachPage.pageIndex() + 1)");
                            #endif
                            self?.hasPendingRecognitionPages = true
                            break;
                        }
                        else {
                            engineWaitingTime = minimumTimeDifference - timeDifference
                        }
                    }
                }
            }
            if let pageToProcess = pickedPage {
                self?.recognitionInProgressInfo.addCurrectRecognitionPage(pageToProcess)
                
                self?.cancelSchelduledRecogntion();
                let bgTask = startBackgroundTask();
                let lastUpdatedDate = pageToProcess.lastUpdated;
                
                let task: FTRecognitionTask = FTRecognitionTask(language: FTLanguageResourceManager.shared.currentLanguageCode ?? "en_US"
                                                                , annotations: pageToProcess.annotations()
                                                                , canvasSize: pageToProcess.pdfPageRect.size)
                task.currentDocument = self?.currentDocument
                //********Updates the indexing status to show in the finder searching********
                task.onStatusChange = { (status) in
                    switch(status) {
                    case .waiting:
                        self?.recognitionIndexingInfo = ["page": pageToProcess, "status": FTNotebookRecognitionStatus.waiting]
                    case .inProgress:
                        self?.recognitionIndexingInfo = ["page": pageToProcess, "status": FTNotebookRecognitionStatus.inProgress]
                    default:
                        break;
                    }
                }
                //********When recognition finished********
                task.onCompletion = {[weak self] (info, error) -> (Void) in
                    self?.recognitionInProgressInfo.removeRecognitionPage(pageToProcess)
                    
                    self?.isRecognitionInProgress = false
                    endBackgroundTask(bgTask);
                    if let weakSelf = self, weakSelf.currentDocument != nil {
                        if error != nil{
                            self?.recognitionIndexingInfo = ["status": FTNotebookRecognitionStatus.finished]
                            return
                        }
                        
                        if(FTLanguageResourceManager.shared.currentLanguageCode != info?.languageCode){
                            weakSelf.startPendingRecognition()
                            return
                        }
                        
                        if(nil != lastUpdatedDate) {
                            info?.lastUpdated = lastUpdatedDate;
                        }
                        #if DEBUG
                        //debugPrint("FTNotebookRecognitionHelper \(info?.recognisedString ?? "NULL")")
                        #endif
                        if info == nil{ //If engine error
                            FTLanguageResourceManager.shared.writeLogString("Engine Error:: \(pageToProcess.pageIndex() + 1)", currentDocument: self?.currentDocument)
                            return;
                        }
                        else{
                            pageToProcess.recognitionInfo = info
                        }
                        weakSelf.startPendingRecognition()
                    }
                }
                //********                
                FTRecognitionTaskManager.shared.addBackgroundTask(task)
            }
            else if(engineWaitingTime > 0) {
                runInMainThread {
                    self?.isRecognitionInProgress = false;
                    self?.scheduleRecogntion(afterDelay: engineWaitingTime);
                }
            }
            else {
                self?.isRecognitionInProgress = false;
                if self?.currentDocument != nil{
                    self?.recognitionIndexingInfo = ["status": FTNotebookRecognitionStatus.finished]
                }
            }
        }
    }
    
    @objc func wakeUpRecognitionHelperIfNeeded(){
        if self.isRecognitionInProgress == false {
            self.hasPendingRecognitionPages = true
            self.startPendingRecognition()
        }
    }
    
    private func cancelSchelduledRecogntion()
    {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(FTNotebookRecognitionHelper.wakeUpRecognitionHelperIfNeeded), object: nil)
    }
    
    private func scheduleRecogntion(afterDelay time : TimeInterval)
    {
        self.cancelSchelduledRecogntion();
        self.perform(#selector(FTNotebookRecognitionHelper.wakeUpRecognitionHelperIfNeeded), with: nil, afterDelay: time)
    }
}

private class FTRecognitionInProgressPlist: NSObject {
    
    var plistPath: String? {
        return NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.libraryDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).last?.appending("/RecognitionInProgress.plist")
    }
    
    private func uniqueKeyForPage(_ page: FTPageProtocol) -> String? {
        if let documentUUID = page.parentDocument?.documentUUID {
            let pageUUID = page.uuid
            return "\(documentUUID)_\(pageUUID)"
        }
        return nil
    }
    
    private func contents() -> NSMutableDictionary {
        var dict: NSMutableDictionary
        if let filePath = self.plistPath {
            dict = NSMutableDictionary.init(contentsOfFile: filePath) ?? NSMutableDictionary()
        }
        else {
            dict = NSMutableDictionary()
        }
        return dict
    }
    
    func addCurrectRecognitionPage(_ page: FTPageProtocol) {
        if let uniquePageUUID = self.uniqueKeyForPage(page) {
            let updatedContents = self.contents()
            updatedContents.setObject(NSNumber.init(value: Date.timeIntervalSinceReferenceDate as Double), forKey: uniquePageUUID as NSCopying)
            self.save(updatedContents)
        }
    }
    
    func removeRecognitionPage(_ page: FTPageProtocol) {
        if let uniquePageUUID = self.uniqueKeyForPage(page) {
            let updatedContents = self.contents()
            updatedContents.removeObject(forKey: uniquePageUUID)
            self.save(updatedContents)
        }
    }
    
    private func save(_ dict: NSMutableDictionary) {
        if let filePath = self.plistPath {
            dict.write(toFile: filePath, atomically: true)
        }
    }
    
    var resetTimeInterval : Double {
        let value : Double;
        #if DEBUG
            value = 180;
        #else
            value = 24 * 60 * 60 //FTAppConfigHelper.sharedAppConfig().myScriptRecognitionResetDuration()
        #endif
        return value;
    }

    func isCrashed(forPage page: FTPageProtocol) -> Bool {
        var isCrashed: Bool = false
        if let uniquePageID = self.uniqueKeyForPage(page) {
            if let number = self.contents().object(forKey: uniquePageID) as? NSNumber {
                let previousTimeStamp = number.doubleValue
                let currentTimeStamp = Date.timeIntervalSinceReferenceDate
                if currentTimeStamp - previousTimeStamp >= TimeInterval(self.resetTimeInterval) {
                    isCrashed = false
                }
                else {
                    isCrashed = true
                }
            }
        }
        return isCrashed
    }
}

extension FTNotebookRecognitionHelper {
    private static let myScriptActivatedNotification = Notification.Name("myScriptActivatedNotification");
    private static let MyScriptActivationKey = "MYScript_Activated";
    
    @objc class func updateMyScriptActivation(freshInstall: Bool) {
        let obj = FTTMyScriptDefault.object(identifier: MyScriptActivationKey);
        if nil == obj {
            if(freshInstall) {
                self.myScriptActivated = false;
            }
            else {
                self.activateMyScript("Already_Activated");
            }
        }
    }
        
    static func activateMyScript(_ screenName: String) {
        self.myScriptActivated = true;
        track(MyScriptActivationKey, params: nil, screenName: screenName, shouldLog: true);
    }
    
    private(set) static var myScriptActivated:Bool {
        get {
            return FTTMyScriptDefault.bool(identifier: MyScriptActivationKey);
        }
        set {
            let oldValue = self.myScriptActivated;
            FTTMyScriptDefault.setBool(newValue, identifier: MyScriptActivationKey);
            if oldValue != newValue {
                NotificationCenter.default.post(name: FTNotebookRecognitionHelper.myScriptActivatedNotification,
                                                object: nil);
            }
        }
    }
    static func resetMyScriptActivatiom() {
        FTTMyScriptDefault.reset(identifier: MyScriptActivationKey);
    }
}

private extension KeychainItemWrapper {
    static func setBool(_ boolVal: Bool,identifier: String) {
        let wrapper = KeychainItemWrapper(identifier: identifier, accessGroup: nil);
        let data = NSNumber(value: boolVal).stringValue.data(using: .utf8);
        wrapper?.setObject(data, forKey: kSecValueData);
    }
    
    static func object(identifier: String) -> Data? {
        let wrapper = KeychainItemWrapper(identifier: identifier, accessGroup: nil);
        let value = wrapper?.object(forKey: kSecValueData) as? Data;
        return value;
    }
    
    static func bool(identifier : String) -> Bool {
        if let value = KeychainItemWrapper.object(identifier: identifier),
           let str = String(data: value, encoding: .utf8) {
            return (str as NSString).boolValue;
        }
        return false;
    }
    
    static func reset(identifier : String) {
        let wrapper = KeychainItemWrapper(identifier: identifier, accessGroup: nil);
        wrapper?.resetKeychainItem();
    }
}

private class FTTMyScriptDefault: NSObject {
    static func reset(identifier : String) {
        UserDefaults.standard.removeObject(forKey: identifier);
        KeychainItemWrapper.reset(identifier: identifier);
    }
    
    static func bool(identifier : String) -> Bool {
        guard let value = FTTMyScriptDefault.object(identifier: identifier) else {
            return false;
        }
        if let nsValue = value as? NSNumber {
            return nsValue.boolValue;
        }
        if let strValue = value as? String {
            return (strValue as NSString).boolValue;
        }
        return false;
    }
    
    static func object(identifier: String) -> Any? {
        if let obj = KeychainItemWrapper.object(identifier: identifier),
           let str = String(data: obj, encoding: .utf8) {
            return str;
        }
        if let value = UserDefaults.standard.object(forKey: identifier) as? NSNumber {
            return value;
        }
        return nil;
    }
    
    static func setBool(_ boolVal: Bool,identifier: String) {
        UserDefaults.standard.setValue(boolVal, forKey: identifier);
        KeychainItemWrapper.setBool(boolVal, identifier: identifier);
    }
}
