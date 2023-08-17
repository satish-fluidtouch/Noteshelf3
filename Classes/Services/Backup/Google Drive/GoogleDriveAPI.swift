//
//  GoogleDriveAPI.swift
//  Noteshelf
//
//  Created by sreenu cheedella on 20/04/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import GoogleAPIClientForREST_Drive

class GoogleDriveAPI: NSObject {
    private let service: GTLRDriveService
    private let RELATIVE_PATH_KEY = "RelativePath"
    
    init(service: GTLRDriveService,callbackQueue: DispatchQueue?) {
        self.service = service
        if let quueue = callbackQueue {
            self.service.callbackQueue = quueue;
        }
    }
    
    func readFile(fileName: String, relativePath: String, email: String, onCompletion: @escaping (GTLRDrive_File?, Error?) -> Void) {
        let query = GTLRDriveQuery_FilesList.query()
        query.spaces = "drive"
        
        let withName = "name = '\(fileName)'" // Case insensitive!
        query.q = "\(withName)"
        query.fields = "files(id, name, parents, trashed, appProperties)"
        
        service.executeQuery(query) { (_ , file, error) in
            if let files = (file as? GTLRDrive_FileList)?.files {
                for item in files {
                    if let value = item.appProperties?.additionalProperties().first?.value, value as? String == relativePath {
                        onCompletion(item, error)
                        return
                    }
                }
            }
            onCompletion(nil,error)
        }
    }
    
    func readFile(fileId: String, parentId: String, onCompletion: @escaping (GTLRDrive_File?, Error?) -> Void) {
        let query = GTLRDriveQuery_FilesGet.query(withFileId: fileId)
        query.fields = "id, name, parents, trashed"
        
        service.executeQuery(query) { (_ , file, error) in
            onCompletion((file as? GTLRDrive_File), error)
        }
    }
    
    func readFolder(name: String, email: String, parentId: String, completion: @escaping (String?, Error?) -> Void) {
        let query = GTLRDriveQuery_FilesList.query()
        
        // Comma-separated list of areas the search applies to. E.g., appDataFolder, photos, drive.
        query.spaces = "drive"
        
        // Comma-separated list of access levels to search in. Some possible values are "user,allTeamDrives" or "user"
        query.corpora = "user"
        
        let withName = "name = '\(name)'" // Case insensitive!
        let foldersOnly = "mimeType = 'application/vnd.google-apps.folder'"
        let ownedByUser = "'\(email)' in owners"
        let withParent = "'\(parentId)' in parents"
        query.q = "\(withName) and \(foldersOnly) and \(ownedByUser)"
        
        if !parentId.isEqual("") {
            query.q?.append(" and \(withParent)")
        }
        
        service.executeQuery(query) { (_, result, error) in
            completion((result as? GTLRDrive_FileList)?.files?.first?.identifier, error)
        }
    }
    
    func createFolder(name: String, parentId: String, completion: @escaping (GTLRDrive_File?,Error?) -> Void) {
        let folder = GTLRDrive_File()
        folder.mimeType = "application/vnd.google-apps.folder"
        folder.name = name
        
        if !parentId.isEqual("") {
            folder.parents = [parentId]
        }
        
        let query = GTLRDriveQuery_FilesCreate.query(withObject: folder, uploadParameters: nil)
        
        self.service.executeQuery(query) { (_, file, error) in
            completion(file as? GTLRDrive_File, error)
        }
    }
    
    func uploadFile(name: String, folderID: String, relativePath: String, fileURL: URL, onCompletion: @escaping (GTLRDrive_File?, Error?) -> Void) {
        let file = GTLRDrive_File()
        file.name = name
        file.parents = [folderID]
        let properties = GTLRDrive_File_AppProperties.init()
        properties.setAdditionalProperty(relativePath, forName: self.RELATIVE_PATH_KEY)
        file.appProperties = properties
        
        let mimeType = "application/ns2"
        
        // Optionally, GTLRUploadParameters can also be created with a Data object.
        let uploadParameters = GTLRUploadParameters(fileURL: fileURL, mimeType: mimeType)
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: uploadParameters)
        query.fields = "id, name, parents"
        
        //        service.uploadProgressBlock = { _, totalBytesUploaded, totalBytesExpectedToUpload in
        //            // This block is called multiple times during upload and can
        //            // be used to update a progress indicator visible to the user.
        //        }
        
        self.service.executeQuery(query) { (_, result, error) in
            onCompletion((result as? GTLRDrive_File), error)
        }
    }
    
    func updateFile(name: String, fileId: String, folderID: String, fileURL: URL, onCompletion: @escaping (GTLRDrive_File?, Error?) -> Void) {
        let file = GTLRDrive_File()
        file.name = name
        
        let mimeType = "application/ns2"
        
        // Optionally, GTLRUploadParameters can also be created with a Data object.
        let uploadParameters = GTLRUploadParameters(fileURL: fileURL, mimeType: mimeType)
        let query = GTLRDriveQuery_FilesUpdate.query(withObject: file, fileId: fileId, uploadParameters: uploadParameters)
        query.fields = "id, name, parents"
        self.service.executeQuery(query) { (_, result, error) in
            onCompletion((result as? GTLRDrive_File), error)
        }
    }
    
    func moveFile(name: String, fileId: String, fromFolderId: String, toFolderId: String, relativePath: String, fileURL: URL, onCompletion: @escaping (GTLRDrive_File?, Error?) -> Void){
        let file = GTLRDrive_File()
        file.name = name
        let properties = GTLRDrive_File_AppProperties.init()
        properties.setAdditionalProperty(relativePath, forName: self.RELATIVE_PATH_KEY)
        file.appProperties = properties
        
        let mimeType = "application/ns2"
        
        // Optionally, GTLRUploadParameters can also be created with a Data object.
        let uploadParameters = GTLRUploadParameters(fileURL: fileURL, mimeType: mimeType)
        let query = GTLRDriveQuery_FilesUpdate.query(withObject: file, fileId: fileId, uploadParameters: uploadParameters)
        query.fields = "id, name, parents"
        query.addParents = toFolderId
        query.removeParents = fromFolderId
        self.service.executeQuery(query) { (_, result, error) in
            onCompletion((result as? GTLRDrive_File), error)
        }
    }
    
    public func search(_ name: String, folderId: String, onCompleted: @escaping (GTLRDrive_File?, Error?) -> ()) {
        let query = GTLRDriveQuery_FilesList.query()
        query.pageSize = 1
        
        let withName = "name contains '\(name)'"
        let withParentId = "'\(folderId)' in parents"
        query.q = "\(withName) and \(withParentId)"
        
        self.service.executeQuery(query) { (_ , results, error) in
            onCompleted((results as? GTLRDrive_FileList)?.files?.first, error)
        }
    }
    
    public func listFiles(_ folderID: String, onCompleted: @escaping (GTLRDrive_FileList?, Error?) -> ()) {
        let query = GTLRDriveQuery_FilesList.query()
        query.pageSize = 100
        query.q = "'\(folderID)' in parents and mimeType != 'application/vnd.google-apps.folder'"
        self.service.executeQuery(query) { (_ , result, error) in
            onCompleted(result as? GTLRDrive_FileList, error)
        }
    }
    
    public func download(_ fileItem: GTLRDrive_File, onCompleted: @escaping (Data?, Error?) -> ()) {
        guard let fileID = fileItem.identifier else {
            return onCompleted(nil, nil)
        }
        
        self.service.executeQuery(GTLRDriveQuery_FilesGet.queryForMedia(withFileId: fileID)) { (ticket, file, error) in
            guard let data = (file as? GTLRDataObject)?.data else {
                return onCompleted(nil, nil)
            }
            
            onCompleted(data, nil)
        }
    }
    
    public func delete(_ fileItem: GTLRDrive_File, onCompleted: @escaping ((Error?) -> ())) {
        guard let fileID = fileItem.identifier else {
            return onCompleted(nil)
        }
        
        self.service.executeQuery(GTLRDriveQuery_FilesDelete.query(withFileId: fileID)) { (ticket, nilFile, error) in
            onCompleted(error)
        }
    }
    
    public func about(onCompletion: @escaping (GTLRDrive_About?, Error?) -> Void) {
        let query = GTLRDriveQuery_AboutGet.query()
        query.fields = "user(displayName,emailAddress),storageQuota(limit,usage)";
        service.executeQuery(query) { (_ , result, error) in
            onCompletion(result as? GTLRDrive_About, error)
        }
    }
}
