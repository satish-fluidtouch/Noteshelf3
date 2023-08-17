//
//  FTWebdavManager.swift
//  Noteshelf
//
//  Created by Ramakrishna on 28/01/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import Webdav
import FTCommon

enum KeychainError: Error {
    case noPassword
    case unexpectedPasswordData
    case unhandledError(status: OSStatus)
}
struct FTWebdavAuthProperties {
    let serverAddress :URL
    let serverCredentials : URLCredential?
}
struct FTWebdavFileProperties {
    let href: String
    let displayName : String
    let isCollection : Bool
}
typealias FTWebdavAuthenticateCallback = (Bool, Bool,NSError?) -> Void
class FTWebdavManager : NSObject {
    private var authenticationCallBack: FTWebdavAuthenticateCallback?
    static let shared = FTWebdavManager()
    private var serverAddress : String?
    private var userCredentials : URLCredential?
    var loadingIndicatorViewController : FTLoadingIndicatorViewController?
    func authenticateToWebdav(from controller: UIViewController,
                               onCompletion completionHandler: @escaping (Bool, Bool,NSError?) -> Void) {
        self.showLoginPrompt(onViewController: controller)
        authenticationCallBack = completionHandler
    }
    func isLoggedIn() -> Bool{
        if self.fetchSavedWebdavAuthenticationProperties()?.serverAddress != nil{
            return true
        }
        return false
    }
    private func showLoginPrompt(onViewController viewController:UIViewController){
        let alertController = UIAlertController.init(title: NSLocalizedString("ConnectToWebdav", comment: "Connect to WebDAV"), message: "", preferredStyle: UIAlertController.Style.alert);
        
        let cancelAction = UIAlertAction.init(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertAction.Style.cancel, handler: { _ in
            self.authenticationCallBack?(false,true,nil)
        });
        alertController.addAction(cancelAction);
        
        let linkAction = UIAlertAction.init(title: NSLocalizedString("Connect", comment: "Connect"), style: UIAlertAction.Style.default, handler: { [weak self] _ in
            
            guard let strongSelf = self else{
                self?.authenticationCallBack?(false,true,FTWebdavError.cloudBackupError)
                return
            }
            if let address = alertController.textFields?[0].text, let userName = alertController.textFields?[1].text, let password = alertController.textFields?[2].text {
                guard address.isValidURLString() else {
                    strongSelf.authenticationCallBack?(false,true,FTWebdavError.unsupportedURLError)
                    return
                }
                
                strongSelf.serverAddress = address
                strongSelf.userCredentials = URLCredential(user: userName, password: password, persistence: URLCredential.Persistence.permanent)
                if let credentials = strongSelf.userCredentials{
                    runInMainThread {
                        strongSelf.loadingIndicatorViewController  = FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: viewController, withText: NSLocalizedString("Connecting", comment: "Connecting..."));
                    }
                    strongSelf.connectToWebDavServerWith(address: address, credentials: credentials)
                }
            }
        });
        alertController.addAction(linkAction);
        
        alertController.addTextField { (textField) in
            textField.placeholder = "https://www.example.com/WebDAV/"
        }
        alertController.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("Username", comment: "Username")
        }
        alertController.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("Password", comment: "Password")
            textField.isSecureTextEntry = true
        }
        viewController.present(alertController, animated: true, completion: nil)
    }
    private func connectToWebDavServerWith(address : String,credentials:URLCredential){
        
        guard let rootURL = URL(string: address)else{
            return
        }
        let request = FTWebdavRequest(withURL: rootURL, credentials: credentials)
        
        request.readFileWith(relativePath: "") { (success, error,response)  in
            if success && error == nil{
                if !self.getDavItemsFromServerResponse(response).isEmpty{
                    if self.authenticationCallBack != nil {
                        self.saveWebdavAuthenticationProperties()
                    }
                }else{
                    self.showWebdavAuthenticationFailureWith(error: FTWebdavError.serverConnectionError) // Fails at this level when connected to non webdav server
                }
            }else{
                    let nsError = FTWebdavError.error(withError: error)
                    self.showWebdavAuthenticationFailureWith(error: nsError)
                }
            }
    }
    private func showWebdavAuthenticationFailureWith(error:NSError){
        DispatchQueue.main.async {
            if self.loadingIndicatorViewController != nil {
                self.loadingIndicatorViewController?.hide()
            }
            _ = self.removeWebdavAuthProperties()
            self.authenticationCallBack?(false,false,error)
        }
    }
    private func getDavItemsFromServerResponse(_ response : Any?) -> [DAVResponseItem]{
        var davItems = [DAVResponseItem]()
            if let responseItems = response as? NSArray{
                for item in responseItems where ((item as? DAVResponseItem) != nil){
                    if let davItem = item as? DAVResponseItem{
                        davItems.append(davItem)
                    }
                }
        }
        return davItems
    }
    func uploadFileWith(relativepath:String,sourceFilePath filePath:String,completion: @escaping (_ error:Error?) -> Void ){
        if let webdavRequest = self.getWebdavRequest(){
            webdavRequest.uploadFileWith(relativeFolderPath: relativepath, sourceFilePath: filePath) { (_, error, _) in
                completion(error)
            }
        }
    }
    func renameFileWith(currentRelativePath currentPath : String,oldFileName:String, newFileName:String,completion: @escaping (_ error:Error?) -> Void) {
        let currentRelativePath = currentPath + "/" + "\(oldFileName)"
        let newRelativePath = currentPath + "/" + "\(newFileName)"
        if let webdavRequest = self.getWebdavRequest(){
            webdavRequest.moveFileWith(currentRelativePath: currentRelativePath, newRelativepath: newRelativePath) { (_, error, _) in
                completion(error)
            }
        }
    }
    func moveFileWith(currentRelativePath currentPath: String, newRelativePath : String, filename:String,completion: @escaping (_ error:Error?) -> Void){
        let currentRelativePath = currentPath + "/" + "\(filename)"
        let newRelativePath = newRelativePath + "/" + "\(filename)"
        if let webdavRequest = self.getWebdavRequest(){
            webdavRequest.moveFileWith(currentRelativePath: currentRelativePath, newRelativepath: newRelativePath) { (_, error, _) in
                completion(error)
            }
        }
    }
    func readFileWith(relativePath:String,completion: @escaping (_ error:Error?) -> Void){
        if let webdavRequest = self.getWebdavRequest(){
            webdavRequest.readFileWith(relativePath: relativePath){ (_, error, _) in
                completion(error)
            }
        }
    }
    func getFileHierarchyAt(relativePath:String,completion:@escaping (_ fileItems :[FTWebdavFileProperties]) -> Void){
        var fileItems : [FTWebdavFileProperties] = []
//        var relativePath = relativePath
//        if FTWebdavManager.getWebdavBackupLocation() == nil {
//            if let serverRelativePath = FTWebdavManager.shared.fetchSavedWebdavAuthenticationProperties()?.serverAddress.relativePath , serverRelativePath !={
//                relativePath = relativePath.replacingOccurrences(of: serverRelativePath, with: "");
//                relativePath = relativePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"));
//            }
//        }
        if let webdavRequest = self.getWebdavRequest(){
            webdavRequest.listServerFilesWith(relativePath: relativePath){ (_, _, response) in
                if let davItems = response as? NSArray{
                    for item in davItems{
                        if let davItem = item as? DAVResponseItem{
                            let fileName = FTWebdavManager.getDisplayNameForWebdavFile(withHref :davItem.href)
                            if let href = davItem.href, href != relativePath{
                                fileItems.append(FTWebdavFileProperties(href: davItem.href, displayName: fileName, isCollection: davItem.isCollection))
                            }
                        }
                    }
                    completion(fileItems)
                }
                completion(fileItems)
            }
            completion(fileItems)
        }
        completion(fileItems)
    }
    class func getDisplayNameForWebdavFile(withHref path:String) -> String{
        let strings = path.split(separator: "/");
        var finalStrings = [String]()
        
        for item in strings {
            finalStrings.append(item.description)
        }
        return finalStrings.last ?? ""
    }
    func createFolderWith(relativePath:String,completion:@escaping (_ success :Bool, _ error:Error?) -> Void){
        if let webdavRequest = self.getWebdavRequest(){
            if !relativePath.isEmpty {
                let folderURL = URL(fileURLWithPath: relativePath, isDirectory: true)
                webdavRequest.createFolderWith(relativePath: folderURL.relativePath) { (success, error,_) in
                    completion(success,error)
                }
            }
        }
    }
    private func getWebdavRequest() -> FTWebdavRequest? {
        if self.isLoggedIn(),let serverAuthProperties = self.fetchSavedWebdavAuthenticationProperties(){
            let request = FTWebdavRequest(withURL: serverAuthProperties.serverAddress, credentials: serverAuthProperties.serverCredentials)
            return request
        }
        return nil
    }
    private func saveWebdavAuthenticationProperties(){
        if let serverPathString = self.serverAddress, let serverURL = URL(string: serverPathString), let userName = userCredentials?.user, let password = userCredentials?.password {
            let password = password.data(using: String.Encoding.utf8)!
            let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                        kSecAttrAccount as String: userName,
                                        kSecAttrServer as String: serverURL.absoluteString,
                                        kSecValueData as String: password]
            _ = removeWebdavAuthProperties()
            let status = SecItemAdd(query as CFDictionary, nil)
            if status == errSecSuccess {
                DispatchQueue.main.async {
                    if self.loadingIndicatorViewController != nil {
                        self.loadingIndicatorViewController?.hide()
                    }
                    FTWebdavManager.setWebdavServerHostAddress(serverPathString)
                    track("Shelf_Settings_Cloud_Backup_WebDAV_Connected", params: [:], screenName: FTScreenNames.shelfSettings)
                    self.authenticationCallBack?(true,false,nil)
                }
            }
            else{
                DispatchQueue.main.async {
                    if self.loadingIndicatorViewController != nil {
                        self.loadingIndicatorViewController?.hide()
                    }
                    self.authenticationCallBack?(false,false,FTWebdavError.unableToAuthenticateError)
                }
                FTLogError("WebDAV_Error", attributes: ["WebDAV_Auth_Details_Keychain_Saving_Error" : status])
                track("WebDAV_Error", params: ["WebDAV_Auth_Details_Keychain_Saving_Error":status], screenName: FTScreenNames.shelfSettings)
            }
        }
        
    }
    func fetchSavedWebdavAuthenticationProperties() -> FTWebdavAuthProperties?{
        let query: [String: Any] = [
                                    kSecClass as String: kSecClassInternetPassword,
                                    kSecReturnAttributes as String: true,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecReturnData as String: true]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status != errSecItemNotFound else { return nil }
        guard status == errSecSuccess else { return nil }
        guard let existingItem = item as? [String : Any],
            let passwordData = existingItem[kSecValueData as String] as? Data,
            let password = String(data: passwordData, encoding: String.Encoding.utf8),
            let account = existingItem[kSecAttrAccount as String] as? String,
            let serverAddress = existingItem[kSecAttrServer as String] as? String
        else {
            return nil
        }
        let credentials = URLCredential(user: account, password: password, persistence: URLCredential.Persistence.none)
        guard let serverURL = URL(string: serverAddress) else {
            print("Failed to get server url")
            return nil
        }
        return FTWebdavAuthProperties(serverAddress: serverURL, serverCredentials: credentials)
    }
    func removeWebdavAuthProperties() -> Bool{
        var removedAuthProperties : Bool = false
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword]
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound {
            removedAuthProperties = true
        }else { removedAuthProperties = false}
        return removedAuthProperties
    }
}

struct FTWebdavError {
    private static let errorDomain = "com.fluidtouch.webdav"
    
    static func error(withError error: Error?) -> NSError {
        switch (error as NSError?)?.code {
        case -1012:
            return userCredentialsError
        case -1004:
            return serverConnectionError
        case -1009:
            return noInternetConnectinoError
        case 404:
            return fileNotFoundError
        case 403:
            return serverConnectionError
        case 405:
            return rejectedRequest
        case 409:
            return noAccessPermission
        case 502:
            return serverConnectionError
        default:
            return defaultError((error as NSError?))
        }
    }
    static var noInternetConnectinoError : NSError{
        return NSError.init(domain: FTWebdavError.errorDomain, code: 182, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("NoInternetConnection", comment: "No Internet Connection")])
    }
    static var serverConnectionError : NSError{
        return NSError.init(domain: FTWebdavError.errorDomain, code: 181, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("UnableToConnectToTheWebDAVServer", comment: "Unable to connect to the server")])
    }
    static var userCredentialsError : NSError{
        return NSError.init(domain: FTWebdavError.errorDomain, code: 180, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("IncorrectCredentials", comment: "Incorrect Credentials")])
    }
    static var cloudBackupError: NSError {
        return NSError.init(domain: FTWebdavError.errorDomain, code: 178, userInfo: [NSLocalizedDescriptionKey: "Cloud backup error"])
    }
    static var unsupportedURLError : NSError {
        return NSError(domain: FTWebdavError.errorDomain, code: 179, userInfo: [NSLocalizedDescriptionKey:NSLocalizedString("UnableToLocateTheServer", comment: "Unable To Locate The Server")])
    }
    static var unableToAuthenticateError : NSError {
        return NSError(domain: FTWebdavError.errorDomain, code: 183, userInfo: [NSLocalizedDescriptionKey: "Noteshelf is unable to authenticate to webdav server"])
    }
    private static var fileNotFoundError: NSError {
        return NSError.init(domain: self.errorDomain, code: 404, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("Webdav404Error", comment: "Webdav file not found error")])
    }
    private static var noAccessPermission: NSError {
        return NSError.init(domain: self.errorDomain, code: 183, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("Webdav409Error", comment: "The host server has denied your request. Please check that your account has permissions to make changes to the folder and try again.")])
    }
    private static var rejectedRequest: NSError {
        return NSError.init(domain: self.errorDomain, code: 183, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("Webdav405Error", comment: "Webdav server has rejected the request")])
    }
    private static func defaultError(_ withError: NSError?) -> NSError {
        return NSError.init(domain: self.errorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : withError?.localizedDescription ?? "webdav error occured"])
    }
}
extension String {
    func isValidURLString() -> Bool {
        guard let url = URL(string: self)
            else { return false }

        if !UIApplication.shared.canOpenURL(url) { return false }
        return true
    }
}
extension FTWebdavManager {
    class func setWebdavBackupLocation(withPath path : String){
        var relativePath = path;
        if let server = FTWebdavManager.shared.fetchSavedWebdavAuthenticationProperties()?.serverAddress.relativePath {
            relativePath = relativePath.replacingOccurrences(of: server, with: "");
            relativePath = relativePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"));
        }
        UserDefaults.standard.setValue(relativePath, forKey: "webdav_backup_location")
        UserDefaults.standard.synchronize()
    }
    class func getWebdavBackupLocation() -> String? {
        if let backupLocation =  UserDefaults.standard.string(forKey: "webdav_backup_location") {
            return backupLocation
        }
        return nil
    }
    class func removeWebdavBackupLocation(){
        UserDefaults.standard.removeObject(forKey: "webdav_backup_location")
        UserDefaults.standard.synchronize()
    }
    class func setStatusForWebdavServerPathSelectionScreenDismiss(_ status : Bool){
        UserDefaults.standard.setValue(status, forKey: "webdav_server_path_selection_sceen_dismiss_key")
        UserDefaults.standard.synchronize()
    }
    class func shouldShowWebdavServerPathSelectionScreenAndDismiss() -> Bool{
        UserDefaults.standard.bool(forKey: "webdav_server_path_selection_sceen_dismiss_key")
    }
    class func setWebdavServerHostAddress(_ address:String){
        UserDefaults.standard.setValue(address, forKey: "webdav_server_host_address")
        UserDefaults.standard.synchronize()
    }
}
