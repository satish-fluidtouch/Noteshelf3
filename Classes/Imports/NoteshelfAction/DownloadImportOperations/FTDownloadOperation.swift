//
//  FTDownloadOperation.swift
//  Whink
//
//  Created by Simhachalam on 01/08/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTDownloadOperation: Operation {
    private var currentAction:FTSharedAction
    private var downloadTask: URLSessionDownloadTask?

    private var taskExecuting = true {
        willSet{
            self.willChangeValue(forKey: "isFinished");
        }
        didSet {
            self.didChangeValue(forKey: "isFinished");
        }
    }
    
    required init(importAction : FTSharedAction)
    {
        currentAction = importAction
        super.init()
        
        let absoluteURL = importAction.sourceURL;
        if var newUrl = URL(string: absoluteURL) {
            if absoluteURL.contains("www.dropbox.com"){
                newUrl = URL(string: absoluteURL.appending("&raw=1"))!
            }
            
            let sessionConfiguration = URLSessionConfiguration.default
            let downloadSession = URLSession(configuration: sessionConfiguration,
                                             delegate: self,
                                             delegateQueue: nil)
            downloadTask = downloadSession.downloadTask(with: newUrl)
        }
    }

    override var isFinished: Bool {
        return !self.taskExecuting;
    }
    
    
    override func main() {
        if let task = self.downloadTask {
            task.resume()
            self.markDownloadState(.downloading);
        }
        else {
            self.markDownloadState(.downloadFailed)
            self.taskExecuting=false
        }
    }
    
    func pauseDownloading() {
        self.downloadTask?.suspend();
    }
    
    func resumeDownloading() {
        self.downloadTask?.resume();
    }
    
    func cancelDownloding() {
        self.downloadTask?.cancel();
    }
}

private extension FTDownloadOperation
{
    func markDownloadState(_ status : FTImportStatus)
    {
        self.currentAction.importStatus = status;
        if(status == .downloadFailed) {
            #if DEBUG
            debugPrint("IMPORTACTION: The task failed:",self.currentAction.sourceURL);
            #endif
            self.currentAction.fileURL = ""
            NotificationCenter.default.post(name: NSNotification.Name.actionDownloadDidFail, object: self.currentAction)
        }
        else if(status == .readyToImport) {
            #if DEBUG
            debugPrint("IMPORTACTION: The task finished transferring data successfully",self.currentAction.sourceURL);
            #endif
            NotificationCenter.default.post(name: NSNotification.Name.actionDownloadDidFinish, object: self.currentAction)
        }
        else if(status == .downloading) {
            #if DEBUG
            debugPrint("IMPORTACTION: Download Started:",self.currentAction.sourceURL)
            #endif
        }
        FTImportStorageManager.updateImportAction(self.currentAction)
        NotificationCenter.default.post(name: NSNotification.Name.actionImportStatusDidUpdate, object: self.currentAction)
    }
}

extension FTDownloadOperation : URLSessionDownloadDelegate
{
    //MARK: URLSession Delegate
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL){
        
        let storageDirectoryPath = FTImportStorageManager.storageDirectoryURL()
        let uniqueName = FileManager.uniqueFileName(self.currentAction.fileName,
                                                    inFolder: storageDirectoryPath,
                                                    pathExt: (self.currentAction.fileName as NSString).pathExtension);
        
        let destinationURLForFile = storageDirectoryPath.appendingPathComponent(uniqueName)
        #if DEBUG
        debugPrint("IMPORTACTION: Downloaded:",destinationURLForFile,self.currentAction.sourceURL)
        #endif
        
        let fileManager = FileManager()
        if !fileManager.fileExists(atPath: destinationURLForFile.path) {
            do {
                try fileManager.moveItem(at: location, to: destinationURLForFile)
                self.currentAction.fileURL = destinationURLForFile.path
            }
            catch {
                #if DEBUG
                debugPrint("IMPORTACTION: ERROR:: An error occurred while moving file to destination url")
                #endif
                self.markDownloadState(.downloadFailed);
            }
        }
        else {
            //cannot proceed;
            #if DEBUG
            debugPrint("IMPORTACTION: cannot proceed")
            #endif
        }
    }
    
    // 2
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64){
        #if DEBUG
        debugPrint("IMPORTACTION: Progress:",Float(totalBytesWritten)/Float(totalBytesExpectedToWrite))
        #endif
    }
    
    //MARK: URLSessionTaskDelegate
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?){
        downloadTask = nil
        if let err = error {
            self.markDownloadState(.downloadFailed)
            #if DEBUG
            debugPrint("IMPORTACTION: \(err.localizedDescription)");
            #endif
        }
        else {
            self.markDownloadState(.readyToImport)
        }
        self.taskExecuting=false
    }
}
