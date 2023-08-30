//
//  FTCloudBackupPublisher.swift
//  FTAutoBackupSwift
//
//  Created by Simhachalam Naidu on 14/08/20.
//  Copyright © 2020 Simhachalam Naidu. All rights reserved.
//

import UIKit
import Reachability
import MessageUI

typealias FTGenericCompletionBlockWithStatus = ((Bool) -> Void)

@objc enum FTBackUpProgressType: Int {
    case preparingContent
    case uploadingContent
}

@objc protocol FTCloudPublishRequestDelegate: NSObjectProtocol {
    @objc func willBeginPublishRequest(_ request: FTCloudPublishRequest)
    @objc func didComplete(publishRequest request: FTCloudPublishRequest,
                                      error: Error?)
    @objc func didComplete(publishRequest request: FTCloudPublishRequest,
                                      ignoreEntry: FTBackupIgnoreEntry)
    @objc func publishRequest(_ request: FTCloudPublishRequest,
                                       uploadProgress progress: CGFloat,
                                       backUpProgressType type: FTBackUpProgressType)
}

class FTCloudBackupPublisher: NSObject {
    lazy var errorUIHelper: FTCloudBackupENPublishError = {
        return FTCloudBackupENPublishError(type: .cloudBackup);
    }()
    
    var backupEntryDictionary = [String: Any]()
    var ignoreList = FTCloudBackupIgnoreList()
    var backUpFilePath: String {
        let libraryPath = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        let backUpEntryPath = libraryPath.appendingPathComponent("BackUpEntry.plist").path
        return backUpEntryPath
    }
    var currentPublishRequest: FTCloudPublishRequest?

    var publishInProgress: Bool = false
    var shouldCancelPublishing: Bool = false
    weak var delegate: FTBaseCloudManagerDelegate?
        
    let publishQueue = DispatchQueue.init(label: "com.fluidtouch.noteshelf.publish",
                                                        qos: .background,
                                                        attributes: [],
                                                        autoreleaseFrequency: .inherit,
                                                        target: nil);

    convenience init(withDelegate delegate: FTBaseCloudManagerDelegate) {
        self.init()
        backupEntryDictionary = [String : Any]()
        self.delegate = delegate
        loadData()
    }

    func login(with viewController: UIViewController, completionHandler block: @escaping FTGenericCompletionBlockWithStatus) {
        //subclass should override
        block(false)
    }
    
    func publishRequest(forItem inItem: FTCloudBackup,itemURL: URL) -> FTCloudPublishRequest? {
        let request = FTCloudPublishRequest(backupEntry: inItem, delegate: self,sourceFile:itemURL)
        return request
    }

    func backUpItem(forInfo inDict: [String : Any]) -> FTCloudBackup? {
        return FTCloudBackup.init(withDict: inDict)
    }

    func isLoggedIn() -> Bool {
       return false
    }

    func cloudBackUpType() -> FTCloudBackUpType {
        return .none
    }

    @objc func cloudBackUpName() -> String {
        return "None"
    }
    // MARK:- Publish Public
    func startPublish() {
        if self.publishInProgress {
            return
        }

        if canProceedPublishing() {
            UserDefaults.standard.removeObject(forKey: BACKUP_ERROR)
            UserDefaults.standard.synchronize()
            self.publishInProgress = true
            self.publishQueue.async(execute: {
                FTCloudBackupPublisher.recordSyncLog("Publish began")
                self.publishNextRequest()
            })
        }
    }

    func cancelPublish() {
        if self.publishInProgress {
            self.shouldCancelPublishing = true
            currentPublishRequest?.canelRequestIfPossible()
        }
    }

    //MARK:- Publish Private
    func canProceedPublishing() -> Bool {
        if !isLoggedIn() {
            return false
        }

        if UserDefaults.standard.bool(forKey: "safe_mode_Identifier") {
            return false
        }

        var shouldProceed = true
        let publishOverWifiOnly = FTCloudBackUpManager.shared.isCloudBackupOverWifiOnly()

        let reachability = Reachability.forInternetConnection()
        if let status = reachability?.currentReachabilityStatus() {
            if status == .NotReachable {
                shouldProceed = false
            } else if publishOverWifiOnly {
                //Check if we are have a valid Wi-Fi network
                if status != .ReachableViaWiFi {
                    shouldProceed = false
                }
            }
        }
        return shouldProceed
    }
    
    func publishNextRequest() {
        if shouldCancelPublishing {
            publishDidCancel()
            return
        }
        getNextPublishRequest { request in
            self.currentPublishRequest = request;
            if let currentRequest = self.currentPublishRequest {
                FTCloudBackupPublisher.recordSyncLog("Publish Start:\(currentRequest.refObject.filePath.lastPathComponent)")

                currentRequest.refObject.isDirty = false
                currentRequest.refObject.errorDescription = nil
                currentRequest.startRequest()
            }
            else {
                //No more changes to publish. We are done here.
                self.publishDidFinish()
            }
        }
    }
    
    func getNextPublishRequest(onCompletion: @escaping (FTCloudPublishRequest?) -> ()) {
        FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection.shelfItems(.none, parent: nil, searchKey: nil) { shelfItems in
            self.publishQueue.async {
                var request: FTCloudPublishRequest?
                let ignoreList = self.ignoreList.ignoreListIds();
                for eachItem in shelfItems {
                    if eachItem.URL.downloadStatus() == .downloaded,
                       let docItem = eachItem as? FTDocumentItemProtocol
                        ,let docId = docItem.documentUUID {
                        
                        let autobackupItem = FTAutoBackupItem(URL: eachItem.URL, documentUUID: docId);
                        
                        if let refObject = self.backupItem(docId) {
                            let lastBackupDate = (refObject.lastBackupDate?.doubleValue ?? 0);
                            let lastUpdatedDate = (autobackupItem.lastUpdated?.doubleValue ?? 0);
                            let refObjectLastUpdated = (refObject.lastUpdated?.doubleValue ?? 0)
                            let currentTime = Date.timeIntervalSinceReferenceDate;
                            var isIgnored = false;
                            
                            if(ignoreList.contains(docId) && lastUpdatedDate <= refObjectLastUpdated) {
                                isIgnored = true;
                            }
                            if !isIgnored,
                                (lastBackupDate < lastUpdatedDate && currentTime - lastUpdatedDate > 60)
                                || refObject.filePath != eachItem.URL.relativePathWRTCollection() {
                                self.ignoreList.remove(fromIgnoreList: docId);
                                refObject.filePath = eachItem.URL.relativePathWRTCollection();
                                refObject.lastUpdated = autobackupItem.lastUpdated;
                                request = self.publishRequest(forItem: refObject,itemURL: eachItem.URL);
                                break;
                            }
                        }
                        else {
                            self.shelfItemDidGetUpdated(autobackupItem, isSameQueue: true);
                            if let refObject = self.backupItem(docId) {
                                self.ignoreList.remove(fromIgnoreList: docId);
                                refObject.lastUpdated = autobackupItem.lastUpdated;
                                request = self.publishRequest(forItem: refObject,itemURL: eachItem.URL);
                                break;
                            }
                        }
                    }
                }
                onCompletion(request);
            }
        }
    }
    
    private func backupItem(_ documentUUID:String) -> FTCloudBackup? {
        var refObject: FTCloudBackup?
        //        let ignoredItems = ignoreList.ignoreListIds()
        for (_, value) in backupEntryDictionary {
            if let obj = value as? FTCloudBackup
                ,obj.uuid == documentUUID
            //                ,!ignoredItems.contains(obj.uuid)
            {
                refObject = obj
                break
            }
        }
        return refObject;
    }
    
    func publishDidFinish() {
        FTCloudBackupPublisher.recordSyncLog("Publish did finish")
        UserDefaults.standard.set(
            Date.timeIntervalSinceReferenceDate,
            forKey: "LAST_SUCCESS_BACK_UP_TIME")

        publishInProgress = false
        shouldCancelPublishing = false
        currentPublishRequest = nil

        delegate?.cloudBackUpManager(self, didCompleteWithError: nil)
    }

    func publishDidFail(_ error: NSError?) {
        FTCloudBackupPublisher.recordSyncLog("Publish did fail \(error?.localizedDescription ?? "")")

        if error != nil {
            if shouldShowError(error) {
                UserDefaults.standard.set(error?.dropboxFriendlyMessageErrorDescription(), forKey: BACKUP_ERROR)
                UserDefaults.standard.synchronize()
            }

            if let uudid = currentPublishRequest?.refObject.uuid {
                DispatchQueue.main.async(execute: {
                    let notificationKey = String(format: FTBackUpDidCompletePublishWithErrorNotificationFormat, uudid)
                    var userInfo: [String : Error?]?
                    if let error = error {
                        userInfo = [
                            "NSError": error
                        ]
                    }
                    NotificationCenter.default.post(name: NSNotification.Name(notificationKey), object: nil, userInfo: userInfo)
                })
            }
        }

        publishInProgress = false
        shouldCancelPublishing = false

        currentPublishRequest = nil

        logPublishError(error)

        delegate?.cloudBackUpManager(self, didCompleteWithError: error)
    }
    
    func logPublishError(_ error: NSError?)
    {
        //subclass should override
    }


    func publishDidCancel() {
        FTCloudBackupPublisher.recordSyncLog("Publish did cancel")

        publishInProgress = false
        shouldCancelPublishing = false

        currentPublishRequest = nil

        delegate?.didCancelCloudBackUpManager(self)
    }
    func isPublishPending() -> Bool {
        var hasSomethingToPublish = false
        for (_, value) in backupEntryDictionary {
            if let obj = value as? FTCloudBackup, obj.isDirty {
              if (obj.isDirty) {
                  hasSomethingToPublish = true
                  break
              }
            }
        }
        return hasSomethingToPublish
    }

    // MARK:- Data Entry
    
    func loadData() {
        if let dictionary = NSDictionary(contentsOfFile: backUpFilePath) as Dictionary? {
            for (keyString, value) in dictionary {
                if let dict = value as? [String: Any],
                    let key = keyString as? String,
                    let entry = self.backUpItem(forInfo: dict) {
                    self.backupEntryDictionary[key] = entry
                }
            }
        }
    }
    
    func saveData() {
        var saveInfo: [AnyHashable : Any] = [:]
        for (key, value) in backupEntryDictionary {
            if let obj = value as? FTCloudBackup {
                let rep = obj.representation()
                saveInfo[key] = rep
                obj.backupInfo = rep
            }
        }
        (saveInfo as NSDictionary).write(toFile: backUpFilePath, atomically: true)
    }
    
    func shelfItemDidGetDeleted(_ shelfItem: FTAutoBackupItem) {
        
        if let guid = shelfItem.documentUUID {
            ignoreList.remove(fromIgnoreList: guid)
            NotificationCenter.default.post(name: NSNotification.Name(String(format: FTBackUpDidCancelledPublishNotificationFormat, guid)), object: nil)
            publishQueue.async(execute: {
                if let entry = self.backupEntryDictionary[guid] as? FTCloudBackup {
                    entry.isDirty = false
                    self.backupEntryDictionary.removeValue(forKey: guid)
                    self.saveData()
                }
            })
        }
    }
    
    func shelfItemDidGetUpdated(_ shelfItem: FTAutoBackupItem,isSameQueue: Bool = false) {
        
        if let guid = shelfItem.documentUUID {
            ignoreList.remove(fromIgnoreList: guid)
            var dict: [String: Any] = [:]
            dict[FTBackUpGUIDKey] = guid
            dict[FTBackUpIsDirtyKey] = NSNumber(value: true)
            if shelfItem.lastUpdated != nil {
                dict[FTBackUpLastUpdatedKey] = shelfItem.lastUpdated
            }
            dict[FTBackUpPackagePathKey] = shelfItem.relativePath
            if(isSameQueue) {
                self.updateSyncRecordForShelf(withDict: dict)
            }
            else {
                publishQueue.async(execute: {
                    self.updateSyncRecordForShelf(withDict: dict)
                })
            }
        }
    }
    func shelfItemDidGetMovedFromCloud(toLocal oldShelfItem: FTAutoBackupItem,
                                       to newShelfItem: FTAutoBackupItem) {
        if let guid = oldShelfItem.documentUUID {
            ignoreList.remove(fromIgnoreList: guid)
            publishQueue.async(execute: {
                if let guid = oldShelfItem.documentUUID, let entry = self.backupEntryDictionary[guid] as? FTCloudBackup {
                    entry.filePath = newShelfItem.relativePath
                    self.backupEntryDictionary[newShelfItem.documentUUID] = entry
                    self.backupEntryDictionary.removeValue(forKey: guid)
                }
                self.saveData()
            })
        }
    }
    // MARK:- Sync Log -
    @objc class func recordSyncLog(_ syncLog: String) {
        FTCLSLog(syncLog);
    }

    func sendLog(_ onViewController: UIViewController?) {
        if !MFMailComposeViewController.canSendMail() {
            let alertController = UIAlertController(title: "", message: "EmailNotSetup".localized, preferredStyle: .alert)

            let action = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: nil)
            alertController.addAction(action)
            onViewController?.present(alertController, animated: true)
            return
        }
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = self
        let data = NSData(contentsOfFile: backUpFilePath) as Data?

        controller.setSubject("Dropbox Backup Log")
        if data != nil {
            if let data = data {
                controller.addAttachmentData(data, mimeType: "application/xml", fileName: "BackUP.plist")
            }
        }
        controller.modalPresentationStyle = .formSheet
        onViewController?.present(controller, animated: true)
    }
    
    func shouldShowError(_ error: Error?) -> Bool {
        var shouldShowError = true
        if (error as NSError?)?.domain == NSURLErrorDomain {
            switch (error as NSError?)?.code {
                case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost, NSURLErrorTimedOut, NSURLErrorCancelled:
                    shouldShowError = false
                default:
                    break
            }
        }
        return shouldShowError
    }
}

extension FTCloudBackupPublisher: FTCloudPublishRequestDelegate {
    @objc func willBeginPublishRequest(_ request: FTCloudPublishRequest) {
        DispatchQueue.main.async(execute: {
            NotificationCenter.default.post(name: NSNotification.Name(String(format: FTBackUpWillBeginPublishNotificationFormat, request.refObject.uuid)),
                                            object: nil,
                                            userInfo: nil)
        })
    }

    @objc func didComplete(publishRequest request: FTCloudPublishRequest,
                           error: Error?) {
        if let inError = error as NSError? {
            request.refObject.errorDescription = inError.localizedDescription;
            request.refObject.isDirty = true;
            self.publishDidFail(inError);
            return;
        }
        request.refObject.errorDescription = nil
        request.refObject.lastBackupDate = request.refObject.lastUpdated ?? NSNumber(value: Date.timeIntervalSinceReferenceDate);
        
        let notificationKey = String(format: FTBackUpDidCompletePublishNotificationFormat, request.refObject.uuid)
        var userInfo: [String: NSNumber] = [:]
        if let backupDate = request.refObject.lastBackupDate {
            userInfo[FTBackUpLastBackedUpDateKey] = backupDate
        }
        
        DispatchQueue.main.async(execute: {
            NotificationCenter.default.post(
                name: NSNotification.Name(notificationKey),
                object: nil,
                userInfo: userInfo)
        })
        publishQueue.async(execute: {
            self.saveData()
            self.publishNextRequest()
        })
    }
    
    @objc func didComplete(publishRequest request: FTCloudPublishRequest,
                           ignoreEntry: FTBackupIgnoreEntry) {
        ignoreList.addToIgnoreList(ignoreEntry)
        if ignoreEntry.ignoreType == .packageNotAvailable {
            request.refObject.resetProperties()
        } else {
            request.refObject.errorDescription = ignoreEntry.ignoreReason
            request.refObject.isDirty = true
        }
        
        let notificationKey = String(format: FTBackUpDidCompletePublishNotificationFormat, request.refObject.uuid)
        var lastBackupDate = request.refObject.lastBackupDate
        if nil == lastBackupDate {
            lastBackupDate = request.refObject.lastUpdated
        }
        var userInfo: [AnyHashable : Any]?
        if lastBackupDate != nil, let lastBackupDate = request.refObject.lastBackupDate {
            userInfo = [
                FTBackUpLastBackedUpDateKey: lastBackupDate
            ]
        }
        DispatchQueue.main.async(execute: {
            NotificationCenter.default.post(
                name: NSNotification.Name(notificationKey),
                object: nil,
                userInfo: userInfo)
        })
        self.publishQueue.async(execute: {
            self.saveData()
            self.publishNextRequest()
        })
    }
    
    @objc func publishRequest(_ request: FTCloudPublishRequest,
                                       uploadProgress progress: CGFloat,
                                       backUpProgressType type: FTBackUpProgressType) {
        DispatchQueue.main.async {
            var uploadProgress: CGFloat = progress
            if (type == .preparingContent)
            {
                uploadProgress *= 0.5;
            }
            else if(type == .uploadingContent)
            {
                uploadProgress = 0.5 + (uploadProgress * 0.5)
            }
            NotificationCenter.default.post(
                name: NSNotification.Name(String(format: FTBackUpPublishProgressNotificationFormat, request.refObject.uuid)),
                object: nil,
                userInfo: ["progress": NSNumber.init(value: Float(uploadProgress))])
        }
    }
    
    func updateSyncRecordForShelf(withDict inDict: [String : Any]) {
        if let guid = inDict[FTBackUpGUIDKey] as? String {
            var entry = backupEntryDictionary[guid] as? FTCloudBackup
            if entry == nil {
                entry = backUpItem(forInfo: inDict)
                if nil != entry {
                    self.backupEntryDictionary[guid] = entry
                }
            }
            entry?.updateWithDict(inDict)
            saveData()
        }
    }
}
extension FTCloudBackupPublisher: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
