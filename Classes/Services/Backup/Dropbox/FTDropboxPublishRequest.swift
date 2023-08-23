//
//  FTDropboxPublishRequest.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 31/08/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import SwiftyDropbox

let FTDidUnlinkAllDropboxClient: String = "FTDidUnlinkAllDropboxClient"
typealias FTDropBoxPreprocessCompletionHandler = (Error?) -> Void

class FTDropboxPublishRequest: FTCloudMultiFormatPublishRequest {
    override func filePublishRequest(format: RKExportFormat) -> FTCloudFilePublishRequest {
        let request = FTDropboxFilePublishRequest(backupEntry: self.refObject,delegate: self);
        request.exportFormat = format;
        return request;
    }
}

private class FTDropboxFilePublishRequest: FTCloudFilePublishRequest {
    private var currentRev: String?
    private var preprocessCompletionBlock: FTDropBoxPreprocessCompletionHandler?
    private var dropboxEntry: FTDropboxBackupEntry? {
        return self.refObject as? FTDropboxBackupEntry
    }
    private var uploadTask: BatchUploadTask?
    private var uploadFilePath: String?
    private var queue: DispatchQueue?
    private var isCancelled = false

    override init(backupEntry refObject: FTCloudBackup, delegate: FTCloudPublishRequestDelegate?) {
        super.init(backupEntry: refObject, delegate: delegate)
        NotificationCenter.default.addObserver(self, selector: #selector(dropboxClientUnlinked(_:)), name: NSNotification.Name(rawValue: FTDidUnlinkAllDropboxClient), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func startRequest() {
        self.queue = self.publishQueue()
        super.startRequest()
        self.preprocessRequest { (error) in
            if error != nil {
                self.publishFailedWithError(error)
            }else {
                self.delegate?.publishRequest(self,
                                              uploadProgress: 0.0,
                                              backUpProgressType: .uploadingContent)
            }
            guard let relativePath = self.relativePath, let uploadPath = self.uploadFilePath else {
                self.publishFailedWithError(NSError(domain: "NSCloudBackup", code: 102, userInfo: nil))
                return
            }
            let parentPath = URL(fileURLWithPath: relativePath).deletingLastPathComponent().path
            if let fileInfo = self.fileInfo
               , let dropboxPath = fileInfo.dropboxPath {
                if self.currentRev == nil, (!(relativePath.lowercased() == dropboxPath.lowercased()) || !(URL(fileURLWithPath: dropboxPath).pathExtension == URL(fileURLWithPath: uploadPath).pathExtension)) {
                    FTCloudBackupPublisher.recordSyncLog(String.init(format: "DB File Move from: %@ to: %@", dropboxPath, relativePath))
                    self.moveFile(fromPath: dropboxPath, toPath: relativePath) { (error, file) in
                        if nil != file {
                            let parentPath = URL(fileURLWithPath: relativePath).deletingLastPathComponent().path
                            self.uploadFile(uploadPath.lastPathComponent,
                                            toPath: parentPath,
                                            withParentRev: file?.rev,
                                            fromPath: uploadPath)
                        } else {
                            if let nsError = error, nsError.isDropboxError(), nsError.code == 404 {
                                self.uploadFile(uploadPath.lastPathComponent,
                                                toPath: parentPath,
                                                withParentRev: self.currentRev,
                                                fromPath: uploadPath)
                            } else {
                                self.publishFailedWithError(error)
                            }
                        }
                    }
                }
            }
            else {
                FTCloudBackupPublisher.recordSyncLog("Uploading File")
                self.uploadFile(uploadPath.lastPathComponent,
                                toPath: parentPath,
                                withParentRev: self.currentRev,
                                fromPath: uploadPath)
            }
        }
    }
    
    func uploadFile(_ filename: String,
                      toPath path: String,
                      withParentRev parentRev: String?,
                      fromPath sourcePath: String) {

        guard let uploadPath = self.uploadFilePath else {
            return
        }
        
        let fileRoute = DropboxClientsManager.authorizedClient?.files
        var updateMode: Files.WriteMode = Files.WriteMode.add
        var autoRename: Bool = true

        if let rev = parentRev {
            updateMode = Files.WriteMode.update(rev)
            autoRename = false
        }
        let sourceFileURL = URL(fileURLWithPath: sourcePath)
        let info = Files.CommitInfo(path: URL(fileURLWithPath: path).appendingPathComponent(filename).path,
                                     mode: updateMode,
                                     autorename: autoRename,
                                     clientModified: nil,
                                     mute: false,
                                     propertyGroups: nil,
                                     strictConflict: false)
        let uploadInfo = [
            sourceFileURL: info
        ]
        let progressBlock: ProgressBlock = { progress in
            self.delegate?.publishRequest(self,
                                          uploadProgress: progress.fractionCompleted,
                                          backUpProgressType: .uploadingContent)
        }
        let responseBlock: BatchUploadResponseBlock = { (fileUrlsToBatchResultEntries, finishBatchRouteError, fileUrlsToRequestErrors) in
            var writeError: Files.WriteError?
            var uploadSuccess = false

            if let entry = fileUrlsToBatchResultEntries?[sourceFileURL] {
                switch entry {
                case .success(let fileMetadata):
                    uploadSuccess = true
                    let fileManger = FileManager()
                    try? fileManger.removeItem(atPath: uploadPath)
                    if let info = self.fileInfo {
                        info.dropboxPath = fileMetadata.pathLower;
                        info.rev = fileMetadata.rev;
                    }
                    self.delegate?.didComplete(publishRequest: self, error: nil)
                case .failure(let failure):
                    switch failure {
                    case .path(let pathError):
                        writeError = pathError
                    default:
                        writeError = Files.WriteError.other
                    }
                }
            }
            
            if !uploadSuccess {
                var error: Error?
                if nil != writeError {
                    error = writeError?.nserrorMapped()
                }
                if nil == error {
                    if let requestError = fileUrlsToRequestErrors[sourceFileURL] {
                        switch requestError {
                        case .routeError(let pollError, _, _, _):
                            error = pollError.unboxed.nserrorMapped()

                        default:
                            error = NSError(domain: "dropbox.com", code: 105, userInfo: [NSLocalizedDescriptionKey : requestError.description])
                        }
                    }
                }
                //Lastest SDK this is not being posted
//                if nil == error {
//                    error = finishBatchRequestError?.nserrorMapped()
//                }

                let fileManger = FileManager()
                try? fileManger.removeItem(atPath: uploadPath)
                self.publishFailedWithError(error)
            }
        }
        self.uploadTask = fileRoute?.batchUploadFiles(fileUrlsToCommitInfo: uploadInfo,
                                                      queue: queue,
                                                      progressBlock: progressBlock,
                                                      responseBlock: responseBlock)
    }
            
    override func canelRequestIfPossible() {
        FTCloudBackupPublisher.recordSyncLog("Request Cancelled")
        isCancelled = true
        uploadTask?.cancel()
        if preprocessCompletionBlock != nil {
            preprocessCompletionBlock = nil
        }
        let fileManger = FileManager()
        if let uploadPath = uploadFilePath {
            try? fileManger.removeItem(atPath: uploadPath)
        }
        self.delegate?.didComplete(publishRequest: self, error: nil)
    }

    func preprocessRequest(onCompletion completionBlock: @escaping FTDropBoxPreprocessCompletionHandler) {
        FTCloudBackupPublisher.recordSyncLog("preprocess Request")
        preprocessCompletionBlock = completionBlock

        self.delegate?.publishRequest(self,
                                      uploadProgress: 0.0,
                                      backUpProgressType: .preparingContent)
        if let relativePath = self.relativePath {
            loadMetadateForFile(atPath: relativePath)
        }
        else {
            completionBlock(NSError(domain: "NSCloudBackup", code: 102, userInfo: nil))
        }
    }
    
    func moveFile(fromPath from: String,
                  toPath to: String,
                  onCompletion completionhandler: @escaping (_ error: NSError?, _ file: Files.FileMetadata?) -> Void) {
        DropboxClientsManager.authorizedClient?.files?.moveV2(fromPath: from, toPath: to).response(completionHandler: { result, relocationError in
            if let fileMetadata = result?.metadata as? Files.FileMetadata {
                completionhandler(nil, fileMetadata)
            } else if let relocationError = relocationError {
                var error: Error? = nil
                
                switch relocationError {
                case .routeError(let rError, _, _, _):
                    error = rError.unboxed.nserrorMapped()
                    
                default:
                    error = NSError(domain: "dropbox.com", code: 105, userInfo: [NSLocalizedDescriptionKey : relocationError.description])
                }

                if ((error as NSError?)?.domain == "dropbox.com") && (error as NSError?)?.code == 103 {
                    DropboxClientsManager.authorizedClient?.files?.getMetadata(path: to).response(queue: self.queue, completionHandler: { result, metadataError in
                        if let fileMetadata = result as? Files.FileMetadata {
                            completionhandler(nil, fileMetadata)
                        } else if let metadataError = metadataError {
                            var error: NSError? = nil
                            switch metadataError {
                            case .routeError(let mError, _, _, _):
                                error = mError.unboxed.nserrorMapped()

                            default:
                                error = NSError(domain: "dropbox.com", code: 105, userInfo: [NSLocalizedDescriptionKey : relocationError.description])
                            }

                            completionhandler(error, nil)
                        }
                    })
                }
            }
        })
    }
    func loadedMetaData(_ result: Files.Metadata?) {
        if !isCancelled {
            if result is Files.DeletedMetadata {
                currentRev = nil
            } else {
                let fileMetadata = result as? Files.FileMetadata
                currentRev = fileMetadata?.rev
            }
            prepareContent(forUpload: { error, packagePath in
                self.uploadFilePath = packagePath
                if self.preprocessCompletionBlock != nil {
                    self.preprocessCompletionBlock?(error)
                    self.preprocessCompletionBlock = nil
                }
            })
        }
    }
    
    func loadMetadateForFile(atPath path: String?) {
        DropboxClientsManager.authorizedClient?.files?.getMetadata(path: path!).response(queue: self.queue, completionHandler: { [weak self] (result, metaDataError) in
            if result != nil {
                self?.loadedMetaData(result)
            }
            else
            {
                var error: NSError?
                if let metaDataError = metaDataError {
                    switch metaDataError {
                    case .routeError(let box, _, _, _):
                        error = box.unboxed.nserrorMapped()
                    default:
                        error = NSError(domain: "dropbox.com", code: 105, userInfo: [NSLocalizedDescriptionKey : metaDataError.description])
                    }
                }

                if let nsError = error, nsError.isDropboxError(), nsError.code == 404 {
                    self?.loadedMetaData(result)
                } else {
                    if self?.preprocessCompletionBlock != nil {
                        self?.preprocessCompletionBlock?(error)
                        self?.preprocessCompletionBlock = nil
                    }
                }
            }
        })
    }
    
    func dropboxClientUnlinked(_ notification: Notification?) {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func cloudRootName() -> String? {
        return "/Apps/\(FTCloudPublishRequest.backup_Folder_Name)"
    }

    func publishFailedWithError(_ error: Error?) {
        if let nsError = error as NSError?, nsError.code == -999 {
            self.delegate?.didComplete(publishRequest: self, error: error)
        } else {
            let ignoreEntry = canBypassError(error)
            if ignoreEntry.ignoreType != .none {
                self.delegate?.didComplete(publishRequest: self, ignoreEntry: ignoreEntry)
            } else {
                self.delegate?.didComplete(publishRequest: self, error: error)
            }
        }
    }
    
    override func canBypassError(_ error: Error?) -> FTBackupIgnoreEntry {
        let ignoreEntry = super.canBypassError(error)
        if let nsError = error as NSError?, nsError.domain == "dropbox.com", nsError.code != 507 {
            ignoreEntry.ignoreType = .invalidInput
            ignoreEntry.ignoreReason = nsError.dropboxFriendlyMessageErrorDescription()
//            //log flurry
//            var message = "Unexpected"
//            if !ignoreEntry.ignoreReason.isEmpty {
//                message = ignoreEntry.ignoreReason
//            }
        }
        return ignoreEntry
    }
}

private extension FTDropboxFilePublishRequest {
    var fileInfo: FTDBBackupFileInfo? {
        return self.dropboxEntry?.cloudFileInfo(exportFormat) as? FTDBBackupFileInfo
    }
}
