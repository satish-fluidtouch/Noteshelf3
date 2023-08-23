//
//  FTWebdavPublishRequest.swift
//  Noteshelf
//
//  Created by Ramakrishna on 05/02/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

typealias FTWebdavPreprocessCompletionHandler = (Error?) -> Void
class FTWebdavPublishRequest: FTCloudMultiFormatPublishRequest {
    override func filePublishRequest(format: RKExportFormat) -> FTCloudFilePublishRequest {
        let request = FTWebdavFilePublishRequest(backupEntry: self.refObject, delegate: self);
        request.exportFormat = format;
        return request;
    }
}

private class FTWebdavFilePublishRequest : FTCloudFilePublishRequest {
    private var preprocessCompletionBlock: FTWebdavPreprocessCompletionHandler?
    fileprivate var uploadPath : String?;
    fileprivate var currentProgress : Progress?;
    fileprivate var isCancelled = false;
    
    override func cloudRootName() -> String? {
        return FTCloudPublishRequest.backup_Folder_Name;
    }
    
    override func startRequest() {
        super.startRequest()
        self.preprocessRequest { [weak self] (error) in
            FTCloudBackupPublisher.recordSyncLog("Webdav publish request start")
            guard let weakSelf = self else {
                self?.publishFinishedWith(error: FTWebdavError.cloudBackupError);
                return
            }
            if error == nil{
                weakSelf.delegate?.publishRequest(weakSelf, uploadProgress: 0, backUpProgressType: FTBackUpProgressType.uploadingContent);
                
                weakSelf.delegate?.publishRequest(weakSelf, uploadProgress: 0.5, backUpProgressType: FTBackUpProgressType.uploadingContent);
                var pathToUpload: String = ""
                var name = ""
                if let relativePath = weakSelf.relativePath {
                    pathToUpload = (relativePath as NSString).deletingLastPathComponent;
                    name = (relativePath as NSString).lastPathComponent
                }
                if var webdavBackUpEntry = weakSelf.fileInfo {
                    
                    var currentRelativePath: String
                    var backedFilename : String
                    if let path = webdavBackUpEntry.webdavPath {
                        currentRelativePath = path
                    } else {
                        currentRelativePath = pathToUpload
                    }
                    if let fileName = webdavBackUpEntry.backupFileName {
                        backedFilename = fileName
                    }
                    else{
                        backedFilename = name
                    }
                    
                    if currentRelativePath == pathToUpload && backedFilename == name {
                        FTCloudBackupPublisher.recordSyncLog("Webdav publish: started uploading notebook")
                        weakSelf.uploadFileWith(relativePath: pathToUpload) { (error) in
                            weakSelf.saveWebdavPathAndFinishPublish(withPath: pathToUpload, webdavBackUpEntry: &webdavBackUpEntry, fileName: name, error: error)
                        }
                    }
                    else {
                        if currentRelativePath != pathToUpload {
                            if backedFilename == name {
                                FTCloudBackupPublisher.recordSyncLog("Webdav publish: started moving notebook")
                                weakSelf.moveFileFrom(currentRelativePath: currentRelativePath, newRelativePath: pathToUpload, fileName: name) { (error) in
                                    weakSelf.saveWebdavPathAndFinishPublish(withPath: pathToUpload, webdavBackUpEntry: &webdavBackUpEntry, fileName: name, error: error)
                                }
                            }else{
                                FTCloudBackupPublisher.recordSyncLog("Webdav publish: started rename and move notebook")
                                weakSelf.renameAndMoveFile(currentRelativePath: currentRelativePath, newRelativePath: pathToUpload, oldFileName: backedFilename, newFileName: name) { (error) in
                                    weakSelf.saveWebdavPathAndFinishPublish(withPath: pathToUpload, webdavBackUpEntry: &webdavBackUpEntry, fileName: name, error: error)
                                }
                            }
                            
                        }else{
                            FTCloudBackupPublisher.recordSyncLog("Webdav publish: started renaming notebook")
                            weakSelf.renameFileWith(currentRelativePath: currentRelativePath, oldFileName: backedFilename, newFileName: name) { (error) in
                                weakSelf.saveWebdavPathAndFinishPublish(withPath: currentRelativePath, webdavBackUpEntry: &webdavBackUpEntry, fileName: name, error: error)
                            }
                        }
                    }
                }
            }else{
                self?.publishFinishedWith(error: error)
            }
        }
    }
    
    func preprocessRequest(onCompletion completionBlock: @escaping FTWebdavPreprocessCompletionHandler) {
        FTCloudBackupPublisher.recordSyncLog("preprocess Request")
        preprocessCompletionBlock = completionBlock
        
        self.delegate?.publishRequest(self,
                                      uploadProgress: 0.0,
                                      backUpProgressType: .preparingContent)
        self.prepareContent { [weak self](error, path) in
            guard let weakSelf = self else {
                completionBlock(FTWebdavError.cloudBackupError);
                return;
            }
            weakSelf.delegate?.publishRequest(weakSelf,
                                              uploadProgress: 0.5,
                                              backUpProgressType: FTBackUpProgressType.preparingContent);
            if(nil != error) {
                completionBlock(error);
            } else {
                if(weakSelf.isCancelled) {
                    completionBlock(FTWebdavError.cloudBackupError);
                } else {
                    weakSelf.uploadPath = path;
                    if weakSelf.refObject as? FTWebdavBackupEntry != nil {
                        completionCallback(nil)
                    } else {
                        completionBlock(FTWebdavError.cloudBackupError)
                    }
                }
            }
        }
        
        func completionCallback(_ error: Error?){
            self.delegate?.publishRequest(self,
                                          uploadProgress: 1,
                                          backUpProgressType: FTBackUpProgressType.preparingContent);
            completionBlock(error)
        }
    }
    
    private func saveWebdavPathAndFinishPublish(withPath path:String
                                                ,webdavBackUpEntry :inout FTWebDavBackupFileInfo
                                                ,fileName name :String
                                                ,error:Error?){
        if error == nil{
            webdavBackUpEntry.webdavPath = path
            webdavBackUpEntry.backupFileName = name
            self.publishFinishedWith(error: error);
        }else{
            self.publishFinishedWith(error: error);
        }
    }
    
    private func readFileWith(relativePath:String, onCompletion:@escaping (_ error: Error?) -> Void){
        FTCloudBackupPublisher.recordSyncLog("Webdav publish: get file with relative path,\(relativePath)")
        FTWebdavManager.shared.readFileWith(relativePath: relativePath) { (error) in
            onCompletion(error)
        }
    }
    
    private func renameAndMoveFile(currentRelativePath:String,newRelativePath:String,oldFileName:String,newFileName:String,onCompletion:@escaping(Error?) -> Void) {
        self.renameFileWith(currentRelativePath: currentRelativePath, oldFileName: oldFileName, newFileName: newFileName) { (error) in
            if error == nil{
                self.moveFileFrom(currentRelativePath: currentRelativePath, newRelativePath: newRelativePath, fileName: newFileName) { (error) in
                    if error == nil{
                        onCompletion(error)
                    }else{
                        self.publishFinishedWith(error: error)
                    }
                }
            }else{
                self.publishFinishedWith(error: error)
            }
        }
    }
    
    private func renameFileWith(currentRelativePath:String,
                                oldFileName:String,
                                newFileName:String,
                                onCompletion:@escaping(Error?) -> Void) {
        self.readFileWith(relativePath: currentRelativePath) { (error) in
            if error == nil{
                FTCloudBackupPublisher.recordSyncLog("Webdav publish: renaming notebook")
                FTWebdavManager.shared.renameFileWith(currentRelativePath: currentRelativePath, oldFileName: oldFileName, newFileName: newFileName) { (error) in
                    onCompletion(error)
                }
            }else{
                self.createFileFor(newRelativePath: currentRelativePath, withRefToCurrenRelativePath: currentRelativePath, fileName: newFileName) { (error) in
                    if error == nil{
                        onCompletion(error)
                    }else{
                        self.publishFinishedWith(error: error)
                    }
                }
            }
        }
    }
    
    private func moveFileFrom(currentRelativePath:String, newRelativePath:String,fileName:String, onCompletion: @escaping (Error?) -> Void) {
        self.readFileWith(relativePath: newRelativePath) { (error) in
            if error == nil{
                FTCloudBackupPublisher.recordSyncLog("Webdav publish: moving notebook")
                FTWebdavManager.shared.moveFileWith(currentRelativePath: currentRelativePath, newRelativePath: newRelativePath, filename: fileName) { (error) in
                    onCompletion(error)
                }
            }else{
                self.createFileFor(newRelativePath: newRelativePath, withRefToCurrenRelativePath: currentRelativePath, fileName: fileName) { (error) in
                    if error == nil{
                        onCompletion(error)
                    }else{
                        self.publishFinishedWith(error: error)
                    }
                }
            }
        }
    }
    
    private func createFileFor(newRelativePath newPath:String,withRefToCurrenRelativePath oldPath:String, fileName:String, onCompletion: @escaping (Error?) -> Void) {
            createFolder(pathArray: splitPath(relativePath: newPath), index: 0) { (error) in
                if error == nil{
                    FTCloudBackupPublisher.recordSyncLog("Webdav publish: moving notebook")
                    FTWebdavManager.shared.moveFileWith(currentRelativePath: oldPath, newRelativePath: newPath, filename: fileName) { (error) in
                        onCompletion(error)
                    }
                }else{
                    onCompletion(error)
                }
            }
    }
    
    private func createFileWith(relativePath:String, onCompletion: @escaping (Error?) -> Void) {
        if (uploadPath != nil) {
            createFolder(pathArray: splitPath(relativePath: relativePath), index: 0) { (error) in
                if error == nil{
                    FTCloudBackupPublisher.recordSyncLog("Webdav publish: uploading notebook")
                    FTWebdavManager.shared.uploadFileWith(relativepath: relativePath, sourceFilePath: self.uploadPath!) { (error) in
                        onCompletion(error)
                    }
                }else{
                    onCompletion(error)
                }
            }
        }
    }
    
    private func createFolder(pathArray: [String] ,  index: Int, onCompletion: @escaping (Error?) -> Void) {
        if (!pathArray.isEmpty && pathArray.count > index) {
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
            
            self.readFileWith(relativePath: relativePath) { (error) in
                if error == nil{
                    self.createFolder(pathArray: pathArray, index: index + 1, onCompletion: onCompletion)
                }else{
                    FTCloudBackupPublisher.recordSyncLog("Webdav publish: creating folder")
                    FTWebdavManager.shared.createFolderWith(relativePath: relativePath) { (_, error) in
                        if error == nil{
                            self.createFolder(pathArray: pathArray, index: index + 1, onCompletion: onCompletion)
                        }else{
                            self.publishFinishedWith(error: error)
                        }
                    }
                }
            }
        }
        else {
            onCompletion(nil)
        }
    }
    
    private func publishFinishedWith(error : Error?)
    {
        if(nil != self.uploadPath) {
            try? FileManager().removeItem(at: URL(fileURLWithPath: self.uploadPath!));
        }
        if(nil == error) {
            self.delegate?.didComplete(publishRequest: self, error: nil);
        }
        else {
            FTCloudBackupPublisher.recordSyncLog("Webdav publish: error occured, \(String(describing: error?.localizedDescription))")
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
            ignoreEntry.ignoreReason = FTWebdavError.error(withError: error).localizedDescription
            if (nsError.code == 404){
                ignoreEntry.ignoreType = .fileNotAvailable
                ignoreEntry.hideFromUser = true
            }
            else if(nsError.code == 400) {
                ignoreEntry.ignoreType = FTBackupIgnoreType.invalidInput;
            } else if(nsError.code == 401) {
                ignoreEntry.ignoreType = FTBackupIgnoreType.none;
            }
        }
        return ignoreEntry;
    }
    
    private func uploadFileWith(relativePath:String,completion: @escaping (Error?) -> Void){
        
            self.readFileWith(relativePath: relativePath) { (error) in
                if error == nil{
                    FTCloudBackupPublisher.recordSyncLog("Webdav publish: uploading notebook")
                    FTWebdavManager.shared.uploadFileWith(relativepath: relativePath, sourceFilePath: self.uploadPath!) { (error) in
                        completion(error)
                    }
                }else{
                    self.createFileWith(relativePath: relativePath) { (error) in
                        if error == nil{
                            completion(error)
                        }else{
                            self.publishFinishedWith(error: error)
                        }
                    }
                }
            }
    }
    
    private func splitPath(relativePath: String) -> [String] {
        let strings = relativePath.split(separator: "/");
        var finalStrings = [String]()
        
        for item in strings {
            finalStrings.append(item.description)
        }
        return finalStrings
    }
}

private extension FTWebdavFilePublishRequest {
    var fileInfo: FTWebDavBackupFileInfo? {
        return self.refObject.cloudFileInfo(exportFormat) as? FTWebDavBackupFileInfo
    }
}
