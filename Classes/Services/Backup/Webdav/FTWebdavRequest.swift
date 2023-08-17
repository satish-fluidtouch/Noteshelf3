//
//  RequestWebdaVAccess.swift
//  Webdav
//
//  Created by Ramakrishna on 05/01/21.
//

import Foundation
import UIKit
import Webdav

protocol FTWebdavRequestDelegate : AnyObject{
    func didCompleteRequest()
    func didFailRequest(withError : Error)
}
typealias FTWebdavRequestCallback = (_ success:Bool,_ error:Error?,_ response: Any?) -> Void
class FTWebdavRequest : NSObject {
    var requestURL : URL
    var userCredentials : URLCredential?
    var requestCallback : FTWebdavRequestCallback?
    var davSession : DAVSession?
    weak var webdavRequestDelegate :FTWebdavRequestDelegate?
    
    init(withURL url : URL, credentials:URLCredential? = nil) {
        requestURL = url
        if let pathComponent = FTWebdavManager.getWebdavBackupLocation() {
            requestURL.appendPathComponent(pathComponent);
        }
        userCredentials = credentials
    }
    
    func uploadFileWith(relativeFolderPath folderPath: String,sourceFilePath filePath:String,completion: @escaping (_ success:Bool,_ error:Error?, _ response:Any?) -> Void){
        requestCallback = completion
        var request = URLRequest(url: requestURL)
        do {
            let fileURL = URL(fileURLWithPath: filePath)
            let data = try Data(contentsOf: fileURL)
            request.httpBody = data
            request.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")
            let MIMEType = DAVPutRequest.mimeType(forExtension: fileURL.pathExtension);
            request.setValue(MIMEType, forHTTPHeaderField: "Content-Type");
            var destinationPath : String = ""
            #if targetEnvironment(macCatalyst)
                destinationPath = folderPath.appendingFormat("/%@",fileURL.lastPathComponent)
            #else
                destinationPath = URL(fileURLWithPath: folderPath, isDirectory: true).appendingPathComponent(fileURL.lastPathComponent).path
            #endif
            let pathToUpload = requestURL.appendingPathComponent(destinationPath).path;
            let uploadRequest = DAVPutRequest(path: pathToUpload, originalRequest: request, session: getDavSession(), delegate: self)
            uploadRequest?.start()
        } catch  {
            self.requestCallback?(false,error, nil)
            FTLogError("WebDAV_Error", attributes: ["Upload_Error" : error.localizedDescription])
            track("WebDAV_Error", params: ["error":error.localizedDescription], screenName: FTScreenNames.shelfSettings)
        }
    }
    func deleteFileWith(relativePath :String,completion: @escaping (_ success:Bool,_ error:Error?,_ response: Any?) -> Void ){
        requestCallback = completion
        let deleteRequest = DAVDeleteRequest(path: relativePath, session: getDavSession(), delegate: self)
        deleteRequest?.start()
    }
    func moveFileWith(currentRelativePath currentPath: String,newRelativepath: String, completion: @escaping (_ success:Bool,_ error:Error?,_ response: Any?) -> Void ){
        requestCallback = completion
        let currentPathWRTBackupPath = requestURL.appendingPathComponent(currentPath).path
        let moveRequest = DAVMoveRequest(path: URL(fileURLWithPath: currentPathWRTBackupPath).path,   session: getDavSession(), delegate: self)
        let newPathWRTBackupPath = requestURL.appendingPathComponent(newRelativepath).path
        moveRequest?.destinationPath = newPathWRTBackupPath
        moveRequest?.overwrite = true
        moveRequest?.start()
    }
    func listServerFilesWith(relativePath:String,completion: @escaping (_ success:Bool,_ error:Error?,_ response: Any?) -> Void){
        if let serverURL = FTWebdavManager.shared.fetchSavedWebdavAuthenticationProperties()?.serverAddress,relativePath.isEmpty{
            requestURL = serverURL
        }
        requestCallback = completion
        let listingRequest = DAVListingRequest(path: relativePath, session: getDavSession(), delegate: self)
        listingRequest?.start()
    }
    func readFileWith(relativePath:String,completion: @escaping (_ success:Bool,_ error:Error?,_ response: Any?) -> Void){
        requestCallback = completion
        let path = requestURL.appendingPathComponent(relativePath).path
        let listingRequest = DAVListingRequest(path: path, session: getDavSession(), delegate: self)
        listingRequest?.start()
    }
    func createFolderWith(relativePath:String,completion:@escaping (_ success:Bool,_ error:Error?,_ response: Any?) -> Void){
        requestCallback = completion
        let relativePathWRTUploadPath = requestURL.appendingPathComponent(relativePath).path
        let directoryRequest = DAVMakeCollectionRequest(path: relativePathWRTUploadPath, session: getDavSession(), delegate: self)
        directoryRequest?.start()
    }
    func getFile(withURL url:URL,completion: @escaping (_ success:Bool,_ error:Error?,_ response: Any?) -> Void){
        requestCallback = completion
        let getRequest = DAVGetRequest(path: url.path, session: getDavSession(), delegate: self)
        getRequest?.start()
    }
    func getDavSession() -> DAVSession? {
        if nil == davSession{
            davSession = DAVSession(rootURL: requestURL, delegate: self)
            return davSession
        }
        return davSession
    }
    private func getDavRequest() -> DAVRequest {
        
        return DAVRequest(path: requestURL.path, session:getDavSession() , delegate: self)
    }
    
}
extension FTWebdavRequest : DAVSessionDelegate {
    func webDAVSession(_ session: DAVSession!, didReceive challenge: URLAuthenticationChallenge!, completionHandler: ((Int, URLCredential?) -> Void)!) {
        FTCloudBackupPublisher.recordSyncLog("Webdav auth challenge received: \(challenge.protectionSpace.authenticationMethod)")
        let failureCount = challenge.previousFailureCount
        if failureCount > 0 {
            challenge.sender?.cancel(challenge)
            completionHandler(4,nil)
        }else{
            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic{
                completionHandler(0, userCredentials)
            }else if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust{
                completionHandler(2, URLCredential(trust: challenge.protectionSpace.serverTrust!));
            }
            else if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPDigest{
                completionHandler(3,userCredentials)
            }
            else{
                completionHandler(1, nil) 
            }
        }
    }
    func webDAVSession(_ session: DAVSession!, appendStringToTranscript string: String!, sent: Bool) {
        print("Transcript",string ?? "")
    }
}
extension FTWebdavRequest : DAVRequestDelegate {
    func request(_ aRequest: DAVRequest!, didFailWithError error: Error!) {
        var erroDescription = error.localizedDescription
        if let errorCode = (error as NSError?)?.code{
            erroDescription += ". "
            erroDescription += "status code:\(errorCode)"
            FTLogError("WebDAV_Error" + "_\(errorCode)", attributes: ["WebDAV_Request_Error" : erroDescription])
            track("WebDAV_Error" + "_\(errorCode)", params: ["WebDAV_Request_Error":erroDescription], screenName: FTScreenNames.shelfSettings)
        }
        self.requestCallback?(false,error,nil)
    }
    
    func request(_ aRequest: DAVRequest!, didSucceedWithResult result: Any!) {
        self.requestCallback?(true,nil,result)
    }
}
