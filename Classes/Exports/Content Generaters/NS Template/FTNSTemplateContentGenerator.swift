//
//  FTNSTemplateContentGenerator.swift
//  Noteshelf
//
//  Created by Amar on 29/03/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTTemplatesStore
import FTCommon

class FTNSTemplateContentGenerator: FTExportContentGenerator {
    
    fileprivate var bgtask = UIBackgroundTaskIdentifier.invalid;
    
    //MARK:- Methods

    @objc func generateTemplateContent(forItem item: FTExportItem,
                                         onCompletion completion: @escaping InternalCompletionHandler)
    {
        bgtask = startBackgroundTask();
        self.isProcessInProgress = true;
        
        self.progress.totalUnitCount = 3;
        do {
            let sourceFileURL = URL.init(fileURLWithPath: item.representedObject as! String);
            Task {
                do {
                    let url = try FTStoreCustomTemplatesHandler.shared.saveFileFrom(url: sourceFileURL, to: item.fileName)
                    let templatesFolder = url?.deletingLastPathComponent()
                    self.generateThumbImageForDocument(atURL: url!,
                                                       writeToFolder: templatesFolder!,
                                                       onCompletion:
                        { (error) in
                            if(nil != error) {
                                DispatchQueue.main.async {
                                    self.isProcessInProgress = false;
                                    endBackgroundTask(self.bgtask);
                                    completion(nil,error,false)
                                }
                            }
                            else {
                                self.progress.completedUnitCount = self.progress.completedUnitCount + 1;

                                let exportItem = FTExportItem.init();
                                exportItem.representedObject = templatesFolder;
                                exportItem.exportFileName = templatesFolder?.lastPathComponent;
                                DispatchQueue.main.async {
                                    self.isProcessInProgress = false;
                                    endBackgroundTask(self.bgtask);
                                    completion(exportItem,nil,false)
                                }
                            }
                    })
                } catch {
                    DispatchQueue.main.async {
                        self.isProcessInProgress = false;
                        endBackgroundTask(self.bgtask);
                        completion(nil,error as NSError,false)
                    }
                }
            }
        } catch let nsError as NSError {
            DispatchQueue.main.async {
                self.isProcessInProgress = false;
                endBackgroundTask(self.bgtask);
                completion(nil,nsError,false)
            }
        }
    }
    //MARK:- DownloadHelpers
    fileprivate func createTemplateHeirarchy(name : String) throws -> URL {
        
        let tempLocation = URL.init(fileURLWithPath: (FTUtils.applicationCacheDirectory() as NSString).appendingPathComponent("TempZip"));
        let folderPath = tempLocation.appendingPathComponent(name);
        
        let fileManager = FileManager();
        try? fileManager.removeItem(at: folderPath);
        try fileManager.createDirectory(at: folderPath, withIntermediateDirectories: true, attributes: nil);
        return folderPath;
    }
    
    fileprivate func generateNBKFormatForItem(item: FTItemToExport,
                                              writeToFolder folderURL : URL,
                                               onCompletion : @escaping (URL?,NSError?) -> ())
    {
        let nbkContentGenerator = FTNBKContentGenerator();
        self.progress.addChild(nbkContentGenerator.progress, withPendingUnitCount: 1);
        nbkContentGenerator.generateContent(forItem: item) { (exportItem, error, success) in
            if(nil != error) {
                onCompletion(nil,error)
            }
            else {
                do {
                    let packPath = folderURL.appendingPathComponent("template").appendingPathExtension(nsBookExtension);
                    let sourceFileURL = URL.init(fileURLWithPath: exportItem!.representedObject as! String);
                    try FileManager().moveItem(at: sourceFileURL, to: packPath);
                    onCompletion(packPath,nil)
                }
                catch let nsError as NSError {
                    onCompletion(nil,nsError)
                }
            }
        };
    }
    
    fileprivate func generateThumbImageForDocument(atURL : URL,
                                                   writeToFolder folderURL : URL,
                                                   onCompletion : @escaping (NSError?) -> ())
    {
        let saveImage : (URL,UIImage) -> NSError? = {(folderURL,image) in
            var errorToShow : NSError?;
            var thumbImageName = "thumbnail.png";
            
            let scale = Int(UIScreen.main.scale);
            if(scale > 1) {
                thumbImageName = "thumbnail@\(scale)x.png";
            }
            do {
                let thumbURL = folderURL.appendingPathComponent(thumbImageName)
                try image.pngData()?.write(to: thumbURL);
            }
            catch let fileError as NSError {
                errorToShow = fileError;
            }
            return errorToShow;
        }
        
        //unzip
        FTNSDocumentUnzipper.unzipFile(atPath: atURL.path,
                                       onUpdate: nil)
        { (path, error) in
            if nil != error {
                onCompletion(error);
                return;
            }
            let fileURL = URL(fileURLWithPath: path!);
            if(fileURL.isPinEnabledForDocument()) {
                let error = saveImage(folderURL,UIImage.init(named: "default_lock_template")!);
                onCompletion(error);
            }
            else {
                let openRequest = FTDocumentOpenRequest(url: fileURL, purpose: .read);
                FTNoteshelfDocumentManager.shared.openDocument(request: openRequest) { (token, document, error) in
                    if let doc = document {
                        if let firstPage = doc.pages().first {
                            var errorToShow : NSError?;
                            let image = FTPDFExportView.snapshot(forPage: firstPage,
                                                                 size: CGSize.init(width: 136, height: 170),
                                                                 screenScale: 0,
                                                                 shouldRenderBackground: true);
                            if(nil != image) {
                                errorToShow = saveImage(folderURL,image!);
                            }
                            FTNoteshelfDocumentManager.shared.closeDocument(document: doc,
                                                                            token: token) { (_) in
                                onCompletion(errorToShow);
                            }
                        }
                    }
                    else {
                        var docError = error as NSError?;
                        if(nil == docError) {
                            docError = NSError.init(domain: "NSExport", code: 101, userInfo: nil);
                        }
                        onCompletion(docError);
                    }
                }
            }
        }
    }
}
