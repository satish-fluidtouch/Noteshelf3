//
//  FTOneDrivePublishRequest.swift
//  Noteshelf
//
//  Created by Amar on 20/12/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTOneDrivePublishRequest: FTCloudMultiFormatPublishRequest {
    override func filePublishRequest(format: RKExportFormat) -> FTCloudFilePublishRequest {
        let request = FTOneDriveFilePublishRequest(backupEntry: self.refObject,delegate: self,sourceFile: self.sourceFileURL);
        request.exportFormat = format;
        return request;
    }
}

private class FTOneDriveFilePublishRequest: FTCloudFilePublishRequest {
    fileprivate var currentOneDriveFileItem : FTOneDriveFileItem?;
    fileprivate var uploadPath : URL?;
    fileprivate var currentRequest : FTOneDriveUploadTask?;
    fileprivate var currentProgress : Progress?;
    fileprivate var isCancelled = false;
    
    //MARK:- Sub Class override Methods -
    override func startRequest() {
        super.startRequest();
        self.preprocessRequest { [weak self] (error) in
            guard let weakSelf = self else {
                self?.publishFinishedWith(error: FTOneDriveError.cloudBackupError);
                return;
            }
            
            if (nil == error) {
                weakSelf.delegate?.publishRequest(weakSelf,
                                                   uploadProgress: 0,
                                                   backUpProgressType: FTBackUpProgressType.uploadingContent);
                guard let uploadFilePath = weakSelf.uploadPath else {
                    weakSelf.publishFinishedWith(error: FTOneDriveError.cloudBackupError);
                    return;
                }

                weakSelf.delegate?.publishRequest(weakSelf,
                                                   uploadProgress: 0.5,
                                                   backUpProgressType: FTBackUpProgressType.uploadingContent);
                weakSelf.currentRequest = FTOneDriveClient.shared.getUploadTask()
                var pathToUpload: String = ""
                if let relativePath = weakSelf.relativePath {
                    pathToUpload = (relativePath as NSString).deletingLastPathComponent;
                }
                weakSelf.currentRequest?.uploadFile(atLocation: uploadFilePath, toParentPath: pathToUpload, onCompletion: { (item, error) in
                        if(nil == error) {
                            let onedriveItem = weakSelf.fileInfo
                            onedriveItem?.oneDriveFileID = item?.id;
                            debugLog("File ID: \(String(describing: onedriveItem?.oneDriveFileID))")
                        }
                        weakSelf.publishFinishedWith(error: error);
                })
            }
            else {
                weakSelf.publishFinishedWith(error: error);
            }
        }
    }

    deinit {
        self.removeProgress();
    }
    
    override func canelRequestIfPossible() {
        self.isCancelled = true;
        self.currentRequest?.cancel();
        if(nil != self.uploadPath) {
            try? FileManager().removeItem(at: self.uploadPath!);
        }
    }
    
    override func canBypassError(_ error: Error?) -> FTBackupIgnoreEntry {
        let ignoreEntry = super.canBypassError(error);
        if let nserror = error as NSError? {
            if(nserror.domain == "com.fluidtouch.onedrive")
            {
                ignoreEntry.ignoreType = FTBackupIgnoreType.temporaryByPass;
                ignoreEntry.ignoreReason = nserror.localizedDescription;
                //            let reason  = (nserror.userInfo["error"] as? ODError);
                //            if(nil != reason) {
                //                let message = reason!.message;
                //                if(nil != message) {
                //                    ignoreEntry.ignoreReason = message!;
                //                }
                //                else {
                //                    ignoreEntry.ignoreReason = "Unknown error";
                //                }
                //            }
                if(nserror.code == 400) {
                    ignoreEntry.ignoreType = FTBackupIgnoreType.invalidInput;
                }
                else if(nserror.code == 413) {
                    ignoreEntry.ignoreType = FTBackupIgnoreType.sizeLimit;
                    ignoreEntry.ignoreReason = "Notebook too large to backup";
                }
            }
        }
        
        return ignoreEntry;
    }
    
    override func cloudRootName() -> String {
        return FTCloudPublishRequest.backup_Folder_Name
    }
    
    //MARK:- Preprocess and finalize -
    private func preprocessRequest(onCompletion : @escaping (Error?) -> Void)
    {
        self.delegate?.publishRequest(self,
                                      uploadProgress: 0,
                                      backUpProgressType: FTBackUpProgressType.preparingContent);
        self.prepareContent { [weak self] (error, path) in
            guard let weakSelf = self else {
                onCompletion(FTOneDriveError.cloudBackupError);
                return;
            }
            weakSelf.delegate?.publishRequest(weakSelf,
                                              uploadProgress: 0.5,
                                              backUpProgressType: FTBackUpProgressType.preparingContent);
            
            if(nil != error) {
                onCompletion(error);
            }
            else {
                if(weakSelf.isCancelled) {
                    onCompletion(FTOneDriveError.cloudBackupError);
                }
                else {
                    weakSelf.uploadPath = URL.init(fileURLWithPath: path!);
                    if let oneDriveFileItem = weakSelf.fileInfo {
                        if let oneDriveFileID = oneDriveFileItem.oneDriveFileID {
                            let fileInfoTask = FTOneDriveClient.shared.getFileInfoTask()
                            fileInfoTask.getFileInfo(for: oneDriveFileID) { (item, error) in
                                if(nil == error) {
                                    weakSelf.currentOneDriveFileItem = item;
                                }
                                if let parentReference = item?.parentReference?.path?.removingPercentEncoding, let remoteFileName = item?.name?.removingPercentEncoding {
                                    let remoteRelativePath = parentReference.replacingOccurrences(of: "/drive/root:/", with: "") + "/" + remoteFileName
                                    var localRelativePath: String = ""
                                    if let relativePath = weakSelf.relativePath {
                                        localRelativePath = relativePath
                                    }
                                    if let uploadFileURL = self?.uploadPath, localRelativePath != remoteRelativePath {
                                        weakSelf.renameOrMoveIfNecessary(for: uploadFileURL.lastPathComponent, onCompletion: { (item, error) in
                                            if(nil == error) {
                                                weakSelf.currentOneDriveFileItem = item;
                                            }
                                            completionCallback(error)
                                        })
                                    }
                                    else{
                                        completionCallback(nil)
                                    }
                                }
                                else {
                                    completionCallback(nil)
                                }
                            }
                        }
                        else {
                            completionCallback(nil)
                        }
                    }
                    else {
                        onCompletion(FTOneDriveError.cloudBackupError);
                    }
                }
            }
        };
        
        func completionCallback(_ error: Error?){
            self.delegate?.publishRequest(self,
                                          uploadProgress: 1,
                                          backUpProgressType: FTBackUpProgressType.preparingContent);
            onCompletion(error)
        }
    }
    
    private func renameOrMoveIfNecessary(for fileName:String,
                                         onCompletion : @escaping (FTOneDriveFileItem? ,Error?) -> Void) {
        let moveTask = FTOneDriveClient.shared.getMoveTask()
        if let fileID = self.currentOneDriveFileItem?.id, let relativePath = self.relativePath {
            moveTask.moveItem(withID: fileID, toRelativePath: (relativePath as NSString).deletingLastPathComponent, fileName: fileName) { (item, error) in
                onCompletion(item, error)
            }
        }
        else {
            onCompletion(nil, nil)
        }
    }
    private func publishFinishedWith(error : Error?)
    {
        if(nil != self.uploadPath) {
            try? FileManager().removeItem(at: self.uploadPath!);
        }
        if(nil == error) {
            self.delegate?.didComplete(publishRequest: self, error: nil);
        }
        else {
            let ignoreEntry = self.canBypassError(error!);
            if (ignoreEntry.ignoreType == FTBackupIgnoreType.none)
            {
                self.delegate?.didComplete(publishRequest: self, error: error);
            }
            else
            {
                self.delegate?.didComplete(publishRequest: self, ignoreEntry: ignoreEntry);
            }
        }
    }
    
    fileprivate func addObserver(progress : Progress)
    {
        self.removeProgress();
        progress.addObserver(self, forKeyPath: "completedUnitCount", options: NSKeyValueObservingOptions.new, context: nil);
        self.currentProgress = progress;
    }
    
    fileprivate func removeProgress()
    {
        if(nil != self.currentProgress) {
            self.currentProgress?.removeObserver(self, forKeyPath: "completedUnitCount")
            self.currentProgress = nil;
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if(keyPath == "completedUnitCount") {
            if let del = self.delegate {
                var progress = CGFloat(self.currentProgress!.completedUnitCount)/CGFloat(self.currentProgress!.totalUnitCount);
                progress = (progress * 0.4)+0.5;
                del.publishRequest(self,
                                    uploadProgress: progress,
                                    backUpProgressType: FTBackUpProgressType.uploadingContent);
            }
        }
    }
}

private extension FTOneDriveFilePublishRequest {
    var fileInfo: FTOneDriveBackupFileInfo? {
        return self.refObject.cloudFileInfo(exportFormat) as? FTOneDriveBackupFileInfo
    }
}
