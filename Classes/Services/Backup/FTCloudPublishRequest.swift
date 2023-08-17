//
//  FTCloudPublishRequest.swift
//  FTAutoBackupSwift
//
//  Created by Naidu on 26/08/20.
//  Copyright © 2020 Simhachalam Naidu. All rights reserved.
//

import UIKit
import ZipArchive
import FTCommon

@objcMembers class FTCloudPublishRequest: NSObject {
    static let backup_Folder_Name = "Noteshelf3 Backup";
    weak var delegate: FTCloudPublishRequestDelegate?
    var refObject: FTCloudBackup!

    init(backupEntry refObject: FTCloudBackup, delegate: FTCloudPublishRequestDelegate?) {
        super.init()
        self.refObject = refObject
        self.delegate = delegate
        NotificationCenter.default.addObserver(self, selector: #selector(didCancelOperation(fromBackup:)), name: NSNotification.Name(String(format: FTBackUpDidCancelledPublishNotificationFormat, self.refObject.uuid)), object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func startRequest() {
        delegate?.willBeginPublishRequest(self)        
    }

    func canelRequestIfPossible() {
        //subclass should override to stop operation
    }

    func publishQueue() -> DispatchQueue? {
        return FTCloudBackUpManager.shared.activeCloudBackUpManager?.publishQueue
    }

    func cloudRootName() -> String? {
        return nil
    }
    
    var relativePath: String? {
        if nil == refObject {
            return ""
        }
        if let rootName = cloudRootName() {
            var relativePath = (rootName as NSString).appendingPathComponent(refObject.filePath)
            let componenets = (relativePath as NSString).pathComponents
            var componentsWithNoExtension: [String] = []
            for eachComp in componenets {
                componentsWithNoExtension.append((eachComp as NSString).deletingPathExtension.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
            }
            relativePath = componentsWithNoExtension.joined(separator: "/")
            if let finalPath = (relativePath as NSString).appendingPathExtension(nsBookExtension) {
                relativePath = finalPath
            }
            return relativePath
        }
        return ""
    }
    
    
    func zipArchiveProgressEvent(_ loaded: UInt64, total: UInt64) {
        let progress = CGFloat(loaded) / CGFloat(total)
        delegate?.publishRequest(
            self,
            uploadProgress: progress,
            backUpProgressType: .preparingContent)
    }

    func didCancelOperation(fromBackup notification: Notification?) {
        canelRequestIfPossible()
    }
    
    func  prepareContent(forUpload completion: @escaping (_ inError: Error?, _ packagePath: String?) -> Void) {
        FTCloudBackupPublisher.recordSyncLog("preparing Content")
        
        var localError: NSError?;
        if nil == refObject {
            localError = NSError(domain: "NSCloudBackUp", code: 1002, userInfo: [
                NSLocalizedDescriptionKey: "Package Not present"
            ])
            completion(localError, nil)
            return
        }
        guard let rootURL = FTCloudBackUpManager.shared.rootDocumentsURL else {
            localError = NSError(domain: "NSCloudBackUp", code: 1002, userInfo: [
                NSLocalizedDescriptionKey: "Package Not present"
            ])
            completion(localError, nil)
            return
        }
        let packageURL = rootURL.appendingPathComponent(refObject.filePath)
        if FileManager().fileExists(atPath: packageURL.path) {
            var cloudError: NSError?;
            let coordinator = NSFileCoordinator(filePresenter: nil)
            coordinator.coordinate(readingItemAt: packageURL,
                                   options: .withoutChanges,
                                   error: &cloudError,
                byAccessor: { newURL in
                        let sourceFilePath = newURL.path
                        let fileName = newURL.lastPathComponent
                        let toPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)
                        
                        var zipPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName).deletingPathExtension
                        if let finalPath = (zipPath as NSString).appendingPathExtension(nsBookExtension) {
                            zipPath = finalPath
                        }                        
                        let fileManager = FileManager()
                        try? fileManager.removeItem(atPath: toPath)
                        try? fileManager.removeItem(atPath: zipPath)
                        
                        FTCloudBackupPublisher.recordSyncLog("Moving to temp loc")
                        var success = false
                        do {
                            try fileManager.copyItem(atPath: sourceFilePath, toPath: toPath)
                            success = true
                        } catch {
                            
                        }
                        FTCloudBackupPublisher.recordSyncLog("Zipping content")
                        
                        success = SSZipArchive.createZipFile(atPath: zipPath, withContentsOfDirectory: toPath, keepParentDirectory: true, withPassword: nil, andProgressHandler: {[weak self] entryNumber, total in
                            if let `self` = self {
                                let progress = CGFloat(entryNumber) / CGFloat(total)
                                self.delegate?.publishRequest(self, uploadProgress: progress, backUpProgressType: .preparingContent)
                            }
                        })
                        try? fileManager.removeItem(atPath: toPath)
                        var nsError: NSError?
                        if !success {
                            nsError = NSError(domain: "NSCloudBackUp", code: 1001, userInfo: [
                                NSLocalizedDescriptionKey: NSLocalizedString("Failedtocreatebackup", comment: "Failed to create backup file. Check remaining space on your device.")
                            ])
                            FTLogError("Archive Failed", attributes: (nsError as NSError?)?.userInfo)
                            try? fileManager.removeItem(atPath: zipPath)
                        }
                        completion(nsError, zipPath);
            })
            
            if cloudError != nil {
                completion(cloudError,nil);
            }
        }else{
            localError = NSError(domain: "NSCloudBackUp", code: 1002, userInfo: [
                NSLocalizedDescriptionKey: "Package Not present"
            ])
            FTCloudBackupPublisher.recordSyncLog("File not found while preparing upload content.")
            FTLogError("File not found while preparing upload content.", attributes: localError?.userInfo)
            completion(localError, nil)
        }
    }
    
    func canBypassError(_ error: Error?) -> FTBackupIgnoreEntry {
        let ignoreEntry = FTBackupIgnoreEntry()
        ignoreEntry.title = URL(fileURLWithPath: refObject.filePath.lastPathComponent).deletingPathExtension().path
        ignoreEntry.uuid = refObject.uuid
        ignoreEntry.ignoreType = .none

        if ((error as NSError?)?.domain == NSCocoaErrorDomain) && (error as NSError?)?.code == NSFileReadNoSuchFileError {
            ignoreEntry.ignoreType = .fileNotAvailable
            ignoreEntry.hideFromUser = true
        } else if ((error as NSError?)?.domain == "NSCloudBackUp") && (error as NSError?)?.code == 1002 {
            ignoreEntry.ignoreType = .fileNotAvailable
            ignoreEntry.hideFromUser = true
        } else if ((error as NSError?)?.domain == "NSCloudBackUp") && (error as NSError?)?.code == 1003 {
            ignoreEntry.ignoreType = .packageNeedsUpgrade
        }
        else if ((error as NSError?)?.domain == "NSCloudBackUp") && (error as NSError?)?.code == 102 {
            ignoreEntry.ignoreType = .invalidInput
            ignoreEntry.ignoreReason = "\(ignoreEntry.title ?? "") - Path not valid or operaion cancelled"
            ignoreEntry.hideFromUser = true
        }
        return ignoreEntry
    }
}
