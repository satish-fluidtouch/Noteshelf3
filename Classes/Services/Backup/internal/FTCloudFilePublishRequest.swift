//
//  FTCloudFilePublishRequest.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 22/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

@objcMembers class FTCloudFilePublishRequest: FTCloudPublishRequest {
    var exportFormat: RKExportFormat = kExportFormatNBK;
    
    var relativePath: String? {
        if let rootName = cloudRootName() {
            var relativePath = (rootName as NSString).appendingPathComponent(refObject.filePath)
            let componenets = (relativePath as NSString).pathComponents
            var componentsWithNoExtension: [String] = []
            for eachComp in componenets {
                componentsWithNoExtension.append((eachComp as NSString).deletingPathExtension.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
            }
            relativePath = componentsWithNoExtension.joined(separator: "/")
            if let finalPath = (relativePath as NSString).appendingPathExtension(exportFormat.filePathExtension()) {
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
    
    func prepareContent(forUpload completion: @escaping (_ inError: Error?, _ packagePath: String?) -> Void) {
        FTCloudBackupPublisher.recordSyncLog("preparing Content")
        
        var localError: NSError?;

        let packageURL = self.sourceFileURL;
        if FileManager().fileExists(atPath: self.sourceFileURL.path) {
            if self.exportFormat == kExportFormatPDF,packageURL.isPinEnabledForDocument() {
                localError = FTCloudBackupErrorCode.passwordEnabled.error;
                FTCloudBackupPublisher.recordSyncLog(localError?.localizedDescription ?? "")
                FTLogError("File not backedup as PDF", attributes: localError?.userInfo)
                completion(localError,nil);
                return;
            }
            guard !self.refObject.hasCrashedPreviouslyWhileUploading() else {
                localError = FTCloudBackupErrorCode.contentPrepareFailedPresviously.error;
                FTCloudBackupPublisher.recordSyncLog(localError?.localizedDescription ?? "")
                FTLogError("File not backedup as PDF", attributes: localError?.userInfo)
                completion(localError,nil);
                return;
            }
            self.refObject.markAsPreparingContent();
            let shelfItem = FTDocumentItem(fileURL: packageURL);
            shelfItem.isDownloaded = true;
            let itemToImport = FTItemToExport(shelfItem: shelfItem);
            let nbkExporter = self.contentGeneratorFor(self.exportFormat, fileURL: packageURL);
            nbkExporter.generateContent(forItem: itemToImport, onCompletion: {[weak self] (exportItem,error,cancelled) in
                self?.refObject.resetPrepareContent();
                if nil != error {
                    if error?.domain == "FTContentGenerator", error?.code == 1003 {
                        localError = FTCloudBackupErrorCode.storageFull.error;
                    }
                    else {
                        localError = error;
                    }
                    FTLogError("Archive Failed", attributes: localError?.userInfo)
                    completion(localError, nil);
                }
                else if let path = exportItem?.representedObject as? String {
                    completion(error,path);
                }
            });
        }
        else {
            localError = FTCloudBackupErrorCode.fileNotAvailable.error
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

        if let nserror = error as? NSError {
            if nserror.domain == NSCocoaErrorDomain, nserror.code == NSFileReadNoSuchFileError {
                ignoreEntry.ignoreType = .fileNotAvailable
                ignoreEntry.hideFromUser = true
            } else if nserror.isError(.fileNotAvailable) {
                ignoreEntry.ignoreType = .fileNotAvailable
                ignoreEntry.hideFromUser = true
            } else if nserror.isError(.packageNeedsUpgrade) {
                ignoreEntry.ignoreType = .packageNeedsUpgrade
            }
            else if nserror.isError(.passwordEnabled) {
                ignoreEntry.ignoreType = .passwordEnabled
                ignoreEntry.ignoreReason = nserror.localizedDescription;
            }
            else if nserror.isError(.contentPrepareFailedPresviously) {
                ignoreEntry.ignoreType = .temporaryByPass;
                ignoreEntry.ignoreReason = nserror.localizedDescription;
                ignoreEntry.hideFromUser = true;
            }
            else if nserror.isError(.invalidInput) {
                ignoreEntry.ignoreType = .invalidInput
                ignoreEntry.ignoreReason = "\(ignoreEntry.title ?? "") - Path not valid or operaion cancelled"
                ignoreEntry.hideFromUser = true
            }
        }
        return ignoreEntry
    }
}

private extension FTCloudFilePublishRequest {
    func contentGeneratorFor(_ backUpFormatType: RKExportFormat,fileURL : URL) -> FTContentGeneratorProtocol {
        if backUpFormatType == kExportFormatPDF {
            let target = FTExportTarget();
            target.properties.exportFormat = backUpFormatType;
            let nbkExporter = FTPDFDocumentPDFContentGenerator();
            nbkExporter.target = target;
            return nbkExporter;
        }
        else {
            return FTNBKContentGenerator();
        }
    }
}

fileprivate extension String {
    static let counterKey = "counter";
    static let lastTime = "lastTime";
}

fileprivate extension FTCloudBackup {
    var contentPrepareKey: String {
        let key = "cloud_content_prepare_\(self.uuid)";
        return key;
    }
    
    private var prepareContentInfo: [String:NSNumber] {
        let info = UserDefaults.standard.object(forKey: contentPrepareKey) as? [String:NSNumber] ?? [String:NSNumber]();
        return info;
    }
    
    func markAsPreparingContent() {
        var info = prepareContentInfo;
        info[String.counterKey] = NSNumber(value:(info[String.counterKey]?.intValue ?? 0) + 1);
        info[String.lastTime] = NSNumber(value: Date.timeIntervalSinceReferenceDate);
        UserDefaults.standard.setValue(info, forKey: contentPrepareKey)
    }
        
    private func resetIfNeeded() {
        let info = prepareContentInfo;
        let lastTime = info[String.lastTime]?.doubleValue ?? 0;
        let currentTime = Date.timeIntervalSinceReferenceDate;
        if(currentTime - lastTime >= 24*60*60) {
            self.resetPrepareContent();
        }
    }
    
    func resetPrepareContent() {
        UserDefaults.standard.removeObject(forKey: contentPrepareKey);
    }
    
    func hasCrashedPreviouslyWhileUploading() -> Bool {
        self.resetIfNeeded();
        let info = self.prepareContentInfo;
        let counter = info[String.counterKey]?.intValue ?? 0;
        if counter >= 2 {
            return true;
        }
        return false;
    }
}
