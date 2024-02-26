//
//  FTNBKContentGenerator.swift
//  Noteshelf
//
//  Created by Siva on 23/12/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon
import ZipArchive

typealias FTZipContentProgressDidUpdate = (_ entryNumber: UInt, _ total: UInt) -> Void;

class FTNBKContentGenerator: FTExportContentGenerator, SSZipArchiveDelegate {
    fileprivate var bgtask = UIBackgroundTaskIdentifier.invalid;
    
    //MARK:- Methods
    override func generateContent(forItem item: FTItemToExport,
                                  onCompletion completion: @escaping InternalCompletionHandler) {
        self.currentItem = item;
        
        bgTask = startBackgroundTask();
        self.isProcessInProgress = true;
        let zipFileName = String.init(format: "%@.%@", self.preferedFileName, nsBookExtension);
        
        let directoryPath : NSString
        if let destinationPath = item.destinationURL {
            directoryPath = destinationPath.path as NSString
        } else {
            directoryPath = self.tempZipLoc
        }

        let destinationPath = directoryPath.appendingPathComponent(zipFileName);

        self.progress.totalUnitCount = 1;

        if let exportTarget = self.target,
            let notebook = exportTarget.notebook,
            let exportPages = exportTarget.pages,
            notebook.pages().count != exportPages.count {
            self.progress.totalUnitCount = 2;
            let tempurl = URL(fileURLWithPath: destinationPath);
            try? FileManager().removeItem(at: tempurl);
            let subProgress = notebook.createDocumentAtTemporaryURL(tempurl,
                                                                    purpose: .default,
                                                                    fromPages: exportPages,
                                                                    documentInfo: nil,
                                                                    onCompletion:
                { (_, error) in
                    if(nil == error) {
                        let documentItem = FTDocumentItem.init(fileURL:tempurl);
                        documentItem.isDownloaded = true;
                        let exportItem = FTItemToExport.init(shelfItem: documentItem);
                        exportItem.filename = item.filename;
                        self.generateNBKContent(forItem: exportItem,
                                                atDestinationPath: destinationPath,
                                                onCompletion: completion);
                    }
                    else {
// Removed below main thread, to avoid deadlock in macOS Ventura while trying to drag and drop.
//                        DispatchQueue.main.async {
                            self.isProcessInProgress = false;
                            endBackgroundTask(self.bgtask);
                            completion(nil,error,false)
//                        }
                    }
            });
            self.progress.addChild(subProgress, withPendingUnitCount: 1);
            return;
        }
        else {
            self.generateNBKContent(forItem: item,
                                         atDestinationPath: destinationPath,
                                         onCompletion: completion);
        }
    }
    
    private func generateNBKContent(forItem item: FTItemToExport,
                                         atDestinationPath destinationPath: String,
                                         onCompletion completion: @escaping InternalCompletionHandler)
    {
        // Removed below main thread, to avoid deadlock in macOS Ventura while trying to drag and drop.
//        DispatchQueue.global().async {
        FTCLSLog("NFC - NBK gen: \(item.shelfItem.URL.title)");
        let coordinator = NSFileCoordinator(filePresenter: nil);
            var accessError: NSError?;
            coordinator.coordinate(readingItemAt: item.shelfItem.URL,
                                   options: .withoutChanges,
                                   error: &accessError, byAccessor: { (newURL) in
                let filePath: NSString = newURL.path as NSString;
                var error: NSError?;
                let tempLoc: NSString = self.copyFileToTempLoc(filePath, error: &error)!;
                
                if nil != error {
                    self.isProcessInProgress = false;
                    // Removed below main thread, to avoid deadlock in macOS Ventura while trying to drag and drop.
//                    DispatchQueue.main.async(execute: {
                        completion(nil, error,false);
                        endBackgroundTask(self.bgtask);
//                    });
                    return;
                }
                
                try? FileManager().removeItem(atPath: destinationPath);
                let success = self.createZipForPackageAtPath(tempLoc as String, zipFilePath: destinationPath as NSString);
                self.progress.completedUnitCount += 1;
                self.isProcessInProgress = false;
                if success {
                    // Removed below main thread, to avoid deadlock in macOS Ventura while trying to drag and drop.
//                    DispatchQueue.main.async(execute: {
                    let destPath = destinationPath;
                        let item = FTExportItem();
                        item.fileName = self.preferedFileName;
                        let url = URL(fileURLWithPath: destPath as String);
                        item.exportFileName = (item.fileName as NSString).appendingPathExtension(url.pathExtension);
                        item.representedObject = destPath;
                        completion(item, nil,false);
                        endBackgroundTask(self.bgtask);
//                    });
                }
                else
                {
                    let error = NSError.init(domain: "FTContentGenerator", code: 1003, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("Failedtocreatebackup", comment: "Failed to create backup file. Check remaining space on your device.")])
                    // Removed below main thread, to avoid deadlock in macOS Ventura while trying to drag and drop.
//                    DispatchQueue.main.async(execute: {
                        completion(nil, error,false);
                        endBackgroundTask(self.bgtask);
//                    });
                }
            });
            
            if (nil != accessError) {
                self.isProcessInProgress = false;
                // Removed below main thread, to avoid deadlock in macOS Ventura while trying to drag and drop.
//                DispatchQueue.main.async(execute: {
                    //Incremented the progress count here, when we failed to read the document, becausse of iCloud not availability.
                    self.progress.completedUnitCount += 1;
                    completion(nil, accessError!,false);
                    endBackgroundTask(self.bgtask);
//                });
                return;
            }
            
//        }
        FTCLSLog("Notebook Generation - NBK");
    }
    
    
    func generateSupportContent(forItem item: FTItemToExport, andCompletionHandler completionHandler:@escaping InternalCompletionHandler) {
        self.generateContent(forItem: item, onCompletion: completionHandler);
    }

    //MARK:- DownloadHelpers
    fileprivate var tempZipLoc: NSString {
        let folder = (FTUtils.applicationCacheDirectory() as NSString).appendingPathComponent("TempZip");
        do {
            try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true, attributes: nil);
        }
        catch {
            
        }
        return folder as NSString;
    }
    
    fileprivate func createZipForPackageAtPath(_ filePath: String, zipFilePath:NSString) -> Bool {
        let success = SSZipArchive.createZipFile(atPath: zipFilePath as String, withContentsOfDirectory: filePath, keepParentDirectory: true);
        if !success {
            FTLogError("Content Generator Archive Failed");
        }
        do {
            try FileManager.default.removeItem(atPath: filePath);
        }
        catch {
            
        }
        return success;
    }
    
    fileprivate func copyFileToTempLoc(_ path: NSString, error: inout NSError?) -> NSString? {
        
        let fileName = self.preferedFileName;
        let fileURL = URL(fileURLWithPath: self.tempZipLoc as String)
        let fileLoc = fileURL.appendingPathComponent(fileName).appendingPathExtension(FTFileExtension.ns3)
        _ = try? FileManager.default.removeItem(at: fileLoc);
        _ = try? FileManager.default.copyItem(atPath: path as String, toPath: fileLoc.path);
        
        if FileManager.default.fileExists(atPath: fileLoc.appendingPathComponent(NOTEBOOK_RECOVERY_PLIST).path) {
            try? FileManager.default.removeItem(at: fileLoc.appendingPathComponent(NOTEBOOK_RECOVERY_PLIST))
        }
        
        return fileLoc.path as NSString;
    }
}
