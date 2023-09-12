//
//  FTGoogleDrivePublishRequest.swift
//  Noteshelf
//
//  Created by sreenu cheedella on 20/04/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST_Drive

class FTGoogleDrivePublishRequest: FTCloudMultiFormatPublishRequest {
    override func filePublishRequest(format: RKExportFormat) -> FTCloudFilePublishRequest {
        let request = FTGoogleDriveFilePublishRequest(backupEntry: self.refObject,delegate: self,sourceFile: self.sourceFileURL);
        request.exportFormat = format;
        return request;
    }
}

private class FTGoogleDriveFilePublishRequest: FTCloudFilePublishRequest {
    fileprivate var uploadPath : URL?;
    fileprivate var currentProgress : Progress?;
    fileprivate var isCancelled = false;
    
    private lazy var googleDriveAPIHelper: GoogleDriveAPI = {
        return GoogleDriveAPI(service: FTGoogleDriveClient.shared.authenticationService(),
                              callbackQueue: self.publishQueue());
    }();
    
    override func startRequest() {
        super.startRequest()
        
        self.preprocessRequest { [weak self] (error) in
            guard let weakSelf = self else {
                self?.publishFinishedWith(error: FTGoogleDriveError.cloudBackupError);
                return;
            }
            
            if (nil == error) {
                weakSelf.delegate?.publishRequest(weakSelf, uploadProgress: 0, backUpProgressType: FTBackUpProgressType.uploadingContent);
                guard let uploadFilePath = weakSelf.uploadPath else {
                    weakSelf.publishFinishedWith(error: FTGoogleDriveError.cloudBackupError);
                    return;
                }
                
                weakSelf.delegate?.publishRequest(weakSelf, uploadProgress: 0.5, backUpProgressType: FTBackUpProgressType.uploadingContent);
                var pathToUpload: String = ""   
                var name = ""
                if let relativePath = weakSelf.relativePath {
                    pathToUpload = (relativePath as NSString).deletingLastPathComponent;
                    name = (relativePath as NSString).lastPathComponent
                }
                if let driveInfo = weakSelf.fileInfo {
                    var currentRelativePath: String
                    if let path = driveInfo.relativePath {
                        currentRelativePath = path
                    } else {
                        currentRelativePath = pathToUpload
                    }
                    
                    if currentRelativePath.isEqual(pathToUpload) {
                        weakSelf.uploadFile(fileName: name
                                            , fileId: driveInfo.googleDriveFileId ?? "",
                                            folderId: driveInfo.googleDriveParentId ?? ""
                                            , relativePath: pathToUpload) { (inFile, error) in
                                                if error == nil, let file = inFile {
                                                    driveInfo.googleDriveFileId = file.identifier
                                                    driveInfo.googleDriveParentId = file.parents?.first
                                                    driveInfo.relativePath = pathToUpload
                                                    weakSelf.publishFinishedWith(error: error);
                                                } else {
                                                    weakSelf.publishFinishedWith(error: error);
                                                }
                        }
                    } else {
                        weakSelf.moveFile(fileName: name
                                          , fileId: driveInfo.googleDriveFileId ?? ""
                                          , parentId: driveInfo.googleDriveParentId ?? ""
                                          , relativePath: pathToUpload) { (file, error) in
                                            if error == nil {
                                                driveInfo.googleDriveFileId = file?.identifier
                                                driveInfo.googleDriveParentId = file?.parents?[0]
                                                driveInfo.relativePath = pathToUpload
                                                weakSelf.publishFinishedWith(error: error);
                                            } else {
                                                weakSelf.publishFinishedWith(error: error);
                                            }
                        }
                    }
                }
            } else {
                weakSelf.publishFinishedWith(error: error);
            }
        }
    }
    
    private func preprocessRequest(onCompletion : @escaping (Error?) -> Void)
    {
        self.delegate?.publishRequest(self,
                                       uploadProgress: 0,
                                       backUpProgressType: FTBackUpProgressType.preparingContent);
        self.prepareContent { [weak self] (error, path) in
            guard let weakSelf = self else {
                onCompletion(FTGoogleDriveError.cloudBackupError);
                return;
            }
            weakSelf.delegate?.publishRequest(weakSelf,
                                               uploadProgress: 0.5,
                                               backUpProgressType: FTBackUpProgressType.preparingContent);
            
            if(nil != error) {
                onCompletion(error);
            } else {
                if(weakSelf.isCancelled) {
                    onCompletion(FTGoogleDriveError.cloudBackupError);
                } else {
                    weakSelf.uploadPath = URL.init(fileURLWithPath: path!);
                    if weakSelf.refObject as? FTGoogleDriveBackupEntry != nil {
                        completionCallback(nil)
                    } else {
                        onCompletion(FTGoogleDriveError.cloudBackupError);
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
    
    override func cloudRootName() -> String {
        return FTCloudPublishRequest.backup_Folder_Name
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
    
    override func canBypassError(_ error: Error?) -> FTBackupIgnoreEntry {
        let ignoreEntry = super.canBypassError(error);
        if let nsError = error as NSError? {
            ignoreEntry.ignoreType = FTBackupIgnoreType.temporaryByPass
            ignoreEntry.ignoreReason = nsError.localizedDescription
            
            if(nsError.code == 400) {
                ignoreEntry.ignoreType = FTBackupIgnoreType.invalidInput;
            } else if(nsError.code == 401) {
                ignoreEntry.ignoreType = FTBackupIgnoreType.none;
            }
        }
        return ignoreEntry;
    }
    
    private func splitPath(relativePath: String) -> [String] {
        let strings = relativePath.split(separator: "/");
        var finalStrings = [String]()
        
        for item in strings {
            finalStrings.append(item.description)
        }
        return finalStrings
    }
    
    private func readFile(fileName: String, fileId: String, folderId: String, relativePath: String, onCompletion: @escaping (GTLRDrive_File?, Error?) -> Void){
        if fileId == "" {
            googleDriveAPIHelper.readFile(fileName: fileName, relativePath: relativePath,
                                          email: GIDSignIn.sharedInstance.currentUser?.profile?.email ?? ""){ (file, error) in
                                            onCompletion(file,error)
            }
        }else {
            googleDriveAPIHelper.readFile(fileId: fileId, parentId: folderId) { (file, error) in
                onCompletion(file,error)
            }
        }
    }
    
    private func uploadFile(fileName: String, fileId: String, folderId: String, relativePath: String, onCompletion: @escaping (GTLRDrive_File?, Error?) -> Void){
        self.readFile(fileName: fileName, fileId: fileId, folderId: folderId, relativePath: relativePath) { (file, error) in
            if error == nil {
                if file == nil {
                    self.createFile(name: fileName, documentUUID: "", relativePath: relativePath) { (file, error) in
                        onCompletion(file, error)
                    }
                } else {
                    if file?.trashed == 1{
                        self.createFile(name: fileName, documentUUID: "", relativePath: relativePath) { (file, error) in
                            onCompletion(file, error)
                        }
                    } else {
                        self.updateFile(fileName: fileName, fileId: (file?.identifier)!, folderId: folderId, relativePath: relativePath) { (file, error) in
                            onCompletion(file, error)
                        }
                    }
                }
            } else {
                self.createFile(name: fileName, documentUUID: "", relativePath: relativePath) { (file, error) in
                    onCompletion(file, error)
                }
            }
        }
    }
    
    private func moveFile(fileName: String, fileId: String, parentId: String, relativePath: String, onCompletion: @escaping (GTLRDrive_File?, Error?) -> Void){
        if (uploadPath != nil) {
            createFolder(pathArray: splitPath(relativePath: relativePath), index: 0, folderId: "") { (resultFolderId) in
                self.googleDriveAPIHelper.moveFile(name: fileName, fileId: fileId, fromFolderId: parentId, toFolderId: resultFolderId!, relativePath: relativePath, fileURL: self.uploadPath!) { (file, error) in
                    onCompletion(file, error)
                }
            }
        }
    }
    
    private func createFile(name: String, documentUUID: String, relativePath:String, onCompletion: @escaping (GTLRDrive_File?, Error?) -> Void) {
        if (uploadPath != nil) {
            createFolder(pathArray: splitPath(relativePath: relativePath), index: 0, folderId: "") { (resultFolderId) in
                self.googleDriveAPIHelper.uploadFile(name: name, folderID: resultFolderId!, relativePath: relativePath, fileURL: self.uploadPath!) { (file, error) in
                    onCompletion(file, error)
                }
            }
        }
    }
    
    private func updateFile(fileName: String, fileId: String, folderId: String, relativePath:String, onCompletion: @escaping (GTLRDrive_File?, Error?) -> Void) {
        if (uploadPath != nil) {
            googleDriveAPIHelper.updateFile(name: fileName, fileId: fileId,
                                            folderID: folderId, fileURL: self.uploadPath!) { (file, error) in
                onCompletion(file, error)
            }
        }
    }
    
    private func createFolder(pathArray: [String] ,  index: Int, folderId: String, onCompletion: @escaping (String?) -> Void) {
        if (!pathArray.isEmpty && pathArray.count > index) {
            let name = pathArray[index];
            var i = 0;
            var relativePath = ""
            
            repeat {
                if (i == index) {
                    relativePath.append(pathArray[i]);
                } else {
                    relativePath.append(pathArray[i])
                    relativePath.append("/")
                }
                i += 1 ;
            } while (i <= index);
            
            googleDriveAPIHelper.readFolder(name: name, email: GIDSignIn.sharedInstance.currentUser?.profile?.email ?? "", parentId: folderId) { (resultFolderId, error) in
                if error == nil {
                    if resultFolderId != nil {
                        self.createFolder(pathArray: pathArray, index: index + 1, folderId: resultFolderId!, onCompletion: onCompletion)
                    } else {
                        self.googleDriveAPIHelper.createFolder(name: name, parentId: folderId) { (folder, error) in
                            if error == nil {
                                self.createFolder(pathArray: pathArray, index: index + 1, folderId: (folder?.identifier)!, onCompletion: onCompletion)
                            } else {
                                self.publishFinishedWith(error: error);
                            }
                        }
                    }
                } else {
                    self.publishFinishedWith(error: error);
                }
            }
        } else {
            onCompletion(folderId)
        }
    }
    
    private func removeExtension(_ name: String) -> String {
        var finalName = name
        if (name.contains(".") && !name.contains(".nsa")) {
           finalName = name.deletingPathExtension
        }
        
        return finalName;
    }
}

private extension FTGoogleDriveFilePublishRequest {
    var fileInfo: FTGDBackupFileInfo? {
        return self.refObject.cloudFileInfo(self.exportFormat) as? FTGDBackupFileInfo
    }
}
