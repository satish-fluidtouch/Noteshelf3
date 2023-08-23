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
            let nbkExporter = self.contentGeneratorFor(self.exportFormat, fileURL: packageURL);
            let shelfItem = FTDocumentItem(fileURL: packageURL);
            shelfItem.isDownloaded = true;
            let itemToImport = FTItemToExport(shelfItem: shelfItem);

            nbkExporter.generateContent(forItem: itemToImport, onCompletion: {(exportItem,error,cancelled) in
                if nil != error {
                    localError = NSError(domain: "NSCloudBackUp", code: 1001, userInfo: [
                        NSLocalizedDescriptionKey: NSLocalizedString("Failedtocreatebackup", comment: "Failed to create backup file. Check remaining space on your device.")
                    ])
                    FTLogError("Archive Failed", attributes: localError?.userInfo)
                    completion(localError, nil);
                }
                else if let path = exportItem?.representedObject as? String {
                    completion(error,path);
                }
            });
        }
        else {
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
    
    private func contentGeneratorFor(_ backUpFormatType: RKExportFormat,fileURL : URL) -> FTContentGeneratorProtocol {
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
