//
//  FTENPublishManager.swift
//  Noteshelf
//
//  Created by Ramakrishna on 08/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Reachability
import FTCommon
// import EvernoteSDK
import CoreData

typealias GenericCompletionBlockWithStatus = (Bool) -> Void
@objc enum EvernoteAccountType : Int {
    case evernoteAccountPersonal
    case evernoteAccountBusiness
    case evernoteAccountUnknown
}

class FTENNotebook: NSObject {
    var edamNote: EDAMNote?
    var edamResources = [EDAMResource]();
}

@objcMembers class FTENPublishManager: NSObject, FTBasePublishRequestDelegate {
    var shouldCancelPublishing = false
    private var currentlyPublingNotebookId: String?
    private var publishInProgress = false
    private var taskId: UIBackgroundTaskIdentifier!
    
    private(set) var ftENNotebook: FTENNotebook?;
    
    //TODO: FLURRY
    /*
     Event Name: Evernote Sync Enabled {Parameter: New or Existing, From: Shelf/ Notebook}
     Event Name: Evernote Sync Disable {From: Shelf/ Notebook}
     Shelf item Published
     
     Event Name: Page published {Size: < 500KB,500KB - 1MB,1MB-2MB,>2MB} //200 Increnebts upto 2 MB
     Event Name: Unexpected Error
     
     Sync On WIFI Only
     
     CLS_LOG in sync log
     */
    var noteshelfNotebookGuid: String?
    /*Represents the GUID of the Noteshelf notebook in Evernote */
    var noteshelfBusinessNotebookGuid: String?
    /*Represents the GUID of the Noteshelf notebook in Evernote Business */
    private var _managedObjectContext: NSManagedObjectContext?
    /*Managed object context created for accessing Master database (ENSyncRecord) in background thread */    //SyncMap
    var syncEnabledBooks: [String : [String:Any]]?
    private var _rootDocumentsURL: URL?;
      var rootDocumentsURL: URL? {
        get {
              var url: URL?;
              objc_sync_enter(self);
              url = _rootDocumentsURL;
              objc_sync_exit(self);
        return url;
            }
        set {
          objc_sync_enter(self);
          if(_rootDocumentsURL != newValue) {
            _rootDocumentsURL = newValue;
            self.startPublishing()
          }
          objc_sync_exit(self);
        }
      }
    var currentOpenedDocumentUUID: String?
    static var publishQueue: DispatchQueue?
    // MARK: Public interface
    
    static let shared : FTENPublishManager = {
        let instance = FTENPublishManager()
        instance.fetchSyncMap()
        if publishQueue == nil {
            let dispacthQOS = DispatchQoS(qosClass: DispatchQoS.QoSClass.background, relativePriority: 0)
            publishQueue = DispatchQueue.init(label: "com.fluidtouch.noteshelf.evernotePublish", qos: dispacthQOS)
        }
        instance.addAppStateNotificationObservers()
        instance.addMemoryWarningNotificationObserver()
        return instance
    }()
    func evernotePublishFeaturePurchased() -> Bool {
        return true
    }
    
    func isLoggedin() -> Bool {
        #if !targetEnvironment(macCatalyst)
        return EvernoteSession.shared().isAuthenticated
        #else
        return false
        #endif
    }
    func promptPurchaseOfENPublishFeature(_ rootviewController: UIViewController?) {
    }
    func startPublishing() {
        if(!evernotePublishFeaturePurchased()){
            return //Safety check
        }
        if(self.publishInProgress){
            return
        }
        //Check if logged in to Evernote
        #if !targetEnvironment(macCatalyst)
        if EvernoteSession.shared().isAuthenticated && shouldProceedWithPublishing() {
            publishInProgress = true
            executeBlock(onPublishQueue: { [self] in
                if self.isPublishPending(){
                    _ = self.managedObjectContext()
                    FTENSyncUtilities.recordSyncLog("Publish began")
                    FTENSyncUtilities.truncateSyncLogUpperLimitIfReachedUpperLimit()
                    self.publishNextRequest()
                } else {
                    self.publishInProgress = false
                }
            })
        }else{
            if UserDefaults.standard.value(forKey: "EVERNOTE_LAST_LOGIN_ALERT_TIME") != nil {
                let currentTimeInterval = Date.timeIntervalSinceReferenceDate
                let lastAlertTimeInterval = TimeInterval(UserDefaults.standard.double(forKey: "EVERNOTE_LAST_LOGIN_ALERT_TIME"))
                if (currentTimeInterval - lastAlertTimeInterval) > 60 {
                    showAlertForRelogin(onError: NSError(domain: "EDAMErrorDomain", code: Int(EDAMErrorCode_AUTH_EXPIRED.rawValue)))
                }
            }
        }
        #endif
    } //Triggers publishing of any pending changes to Evernote
    
    func cancelPublishing() {
        if publishInProgress {
            shouldCancelPublishing = true
        }
    }
    class func recordSyncLog(_ syncLog: String?) {
        #if !targetEnvironment(macCatalyst)
        FTENPublishManager.shared.executeBlock(onPublishQueue: {
            FTENSyncUtilities.recordSyncLog(syncLog)
        })
        #endif
    }
    func shouldProceedWithPublishing() -> Bool {
        if FTUserDefaults.isInSafeMode() {
            return false
        }
        var shouldProceed = true
        let publishOverWifiOnly = UserDefaults.standard.bool(forKey: EVERNOTE_PUBLISH_ON_WIFI_ONLY)
        let reachability = Reachability(hostName: "www.evernote.com")
        let status = reachability?.currentReachabilityStatus()
        
        if publishOverWifiOnly {
            //Check if we are have a valid Wi-Fi network
            if status != NetworkStatus.ReachableViaWiFi {
                shouldProceed = false
            }
        }
        //Added below code to avoid publishing if the root document folder is not set yet
        if nil == rootDocumentsURL {
            shouldProceed = false
        }
        return shouldProceed
    }
    func loginToEvernote(with viewController: UIViewController,  completionHandler :@escaping GenericCompletionBlockWithStatus) {
        #if !targetEnvironment(macCatalyst)
        guard let session = EvernoteSession.shared() else {
            completionHandler(false)
            return
        }
        session.authenticate(with: viewController, completionHandler: { error in
            if error != nil || !session.isAuthenticated {
                let alertController = UIAlertController(title: "", message: NSLocalizedString("EvernoteAuthenticationFailed", comment: "Unable to authenticate with Evernote"), preferredStyle: .alert)

                let action = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .cancel, handler: nil)
                alertController.addAction(action)
                viewController.present(alertController, animated: true)
                completionHandler(false)
            } else {
                UserDefaults.standard.removeObject(forKey: "EVERNOTE_LAST_LOGIN_ALERT_TIME")
                completionHandler(true)
            }
        })
        #endif
    }
    // MARK:- Core Data related
    
    func executeBlock(onPublishQueue block: @escaping () -> Void) {
        FTENPublishManager.publishQueue?.async(execute: { [self] in
            self.managedObjectContext().perform(block)
        })
    }
    func managedObjectContext() -> NSManagedObjectContext {
        
        if _managedObjectContext == nil{
            let coordinator = FTENCoreDataStack.shared.persistentStoreCoordinator
            if let coordinator = coordinator {
                _managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                _managedObjectContext?.persistentStoreCoordinator = coordinator
            }
            _managedObjectContext?.undoManager = nil
        }
        return _managedObjectContext!
    }
    func commitDataChanges() {
        do {
            try self.managedObjectContext().save()
        } catch {
            // Update to handle the error appropriately.
            debugLog("Unresolved error \(error),\(String(describing: (error as NSError?)?.userInfo))")
            exit(-1) // Fail
        }
    }
    // MARK: Publish request pipelining
    #if !targetEnvironment(macCatalyst)
    func publishNextRequest() {
        if shouldCancelPublishing {
            publishDidCancel()
            return
        }
        if let request = getNextPublishRequest(0) {
            taskId = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
            request.startRequest()
        } else {
            //No more changes to publish. We are done here.
            publishDidFinish()
        }
    }
    #endif
    //To prevent a crash in some rare scenario, where this method recursively getting called for some users.
    #if !targetEnvironment(macCatalyst)
    func getNextPublishRequest(_ attempt: Int) -> FTBasePublishRequest? {
        
        var attempt = attempt
        var nextRequest: FTBasePublishRequest?
        
        if FTENIgnoreListManager.shared.ignoredNotebooksID().contains(currentlyPublingNotebookId ?? "") {
            currentlyPublingNotebookId = nil
            ftENNotebook = nil;
        }
        
        if currentlyPublingNotebookId == currentOpenedDocumentUUID {
            currentlyPublingNotebookId = nil
            ftENNotebook = nil;
        }
        if (currentlyPublingNotebookId == nil) {
            chooseNotebookToPublish()
            if(currentlyPublingNotebookId != nil) {
                ftENNotebook = FTENNotebook();
            }
        }
        
        if (currentlyPublingNotebookId != nil) {
            var predicate = NSPredicate(format: "nsGUID==%@", currentlyPublingNotebookId!)
            let parentRecord = FTENSyncUtilities.fetchTopManagedObject(withEntity: "ENSyncRecord", predicate: predicate) as? ENSyncRecord
            
            if let parentRecord = parentRecord,(parentRecord.enGUID == nil || parentRecord.isDirty || parentRecord.deleted) {
                if parentRecord.isBusinessNote && (noteshelfBusinessNotebookGuid == nil) {
                    nextRequest = FTNoteshelfBusinessNotebookPublishRequest(object: nil, delegate: self)
                    return nextRequest
                } else if !(parentRecord.isBusinessNote) && (noteshelfNotebookGuid == nil) {
                    nextRequest = FTNoteshelfNotebookPublishRequest(object: nil, delegate: self)
                    return nextRequest
                }
                //Publish shelfitem.
                nextRequest = FTShelfItemPublishRequest(object: parentRecord.objectID, delegate: self)
            } else{
                if parentRecord?.syncEnabled ?? false {
                    //Here we need to create a request for publishing the dirty page for this notebook
                    //Get the dirty page in this notebook
                    predicate = NSPredicate(format: "parentRecord==%@ AND isDirty==YES", parentRecord!)
                    let sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
                    
                    let pageRecord = FTENSyncUtilities.fetchTopManagedObject(withEntity: "ENSyncRecord", predicate: predicate, sortDescriptors: sortDescriptors) as? ENSyncRecord
                    if let pageRecord = pageRecord {
                        pageRecord.isBusinessNote = parentRecord?.isBusinessNote ?? false
                        nextRequest = FTPDFPagePublishRequest(object: pageRecord.objectID, delegate: self)
                    } else {
                        if attempt >= 3 {
                            let url = parentRecord?.url
                            if nil == url {
                                FTLogError("EN-ShelfItem: Parent URL nil");
                            }
                            let title = url?.lastPathComponent.deletingPathExtension
                            markThisNotebook(asProblematic: currentlyPublingNotebookId, title: title)
                            attempt = 0
                        }else {
                            attempt += 1
                        }
                        self.currentlyPublingNotebookId = nil
                        nextRequest = self.getNextPublishRequest(attempt)
                    }
                }else {
                    self.currentlyPublingNotebookId = nil;
                    nextRequest = self.getNextPublishRequest(0)
                }
            }
        }
        return nextRequest
    }
    #endif
    
    func publishDidCancel() {
        currentlyPublingNotebookId = nil
        noteshelfNotebookGuid = nil
        publishInProgress = false
        shouldCancelPublishing = false
        _managedObjectContext = nil
        #if !targetEnvironment(macCatalyst)
        FTENSyncUtilities.recordSyncLog("Publish did cancel")
        #endif
    }
    
    func publishDidFinish() {
        currentlyPublingNotebookId = nil
        noteshelfNotebookGuid = nil
        publishInProgress = false
        shouldCancelPublishing = false
        _managedObjectContext = nil
        
        
        UserDefaults.standard.set(
            Date.timeIntervalSinceReferenceDate,
            forKey: EVERNOTE_LAST_PUBLISH_TIME)
        #if !targetEnvironment(macCatalyst)
        FTENSyncUtilities.recordSyncLog("Publish did finish")
        #endif
        
    }
    
    func publishDidFail() {
        currentlyPublingNotebookId = nil
        noteshelfNotebookGuid = nil
        publishInProgress = false
        shouldCancelPublishing = false
        _managedObjectContext = nil
    }
    func logPublishError(_ error: NSError) {
        var continuePublish = false
        
        var logFlurry = false
        var showSupportAction = false
        
        var failureReason = "Unknown"
        let reachability = Reachability(hostName: "www.evernote.com")
        let status = reachability?.currentReachabilityStatus()
        if status == NetworkStatus.NotReachable {
            failureReason = "Not Reachable"
        } else {
            logFlurry = true
            self.showAlertForRelogin(onError: error)
            #if !targetEnvironment(macCatalyst)
            let enErrorCode = UInt32(abs(error.code))
            switch  enErrorCode {
            case EDAMErrorCode_UNKNOWN.rawValue:
                logFlurry = true;
                showSupportAction = true;
                failureReason = "Unknown";
            case EDAMErrorCode_AUTH_EXPIRED.rawValue:
                logFlurry = true;
                failureReason = "Auth Expired. Please login Again"
            case EDAMErrorCode_BAD_DATA_FORMAT.rawValue,
                EDAMErrorCode_DATA_REQUIRED.rawValue,
                EDAMErrorCode_LEN_TOO_LONG.rawValue,
                EDAMErrorCode_LEN_TOO_SHORT.rawValue,
                EDAMErrorCode_TOO_FEW.rawValue,
                EDAMErrorCode_TOO_MANY.rawValue :
                logFlurry = true;
                showSupportAction = true;
                let errorCode = ((error as NSError).userInfo["EDAMErrorCode"] as? NSNumber)?.intValue ?? 0
                failureReason = String(format: "Invalid Data - %ld", errorCode)
            case EDAMErrorCode_SHARD_UNAVAILABLE.rawValue:
                logFlurry = true;
                failureReason = "Data not found"
            case EDAMErrorCode_PERMISSION_DENIED.rawValue,EDAMErrorCode_INVALID_AUTH.rawValue:
                /*
                 EDAMErrorCode_INVALID_AUTH
                 EDAMErrorCode_PERMISSION_DENIED
                 */
                logFlurry = true;
                showSupportAction = true;
                let errorCode = ((error as NSError).userInfo["EDAMErrorCode"] as? NSNumber)?.intValue ?? 0
                failureReason = String(format: "Permission Denied - %ld", errorCode)
            case EDAMErrorCode_LIMIT_REACHED.rawValue:
                continuePublish = true;
                failureReason = "Limit Reached"

            case EDAMErrorCode_QUOTA_REACHED.rawValue:
                failureReason = "Quota Reached"
                logFlurry = false

            case EDAMErrorCode_DATA_CONFLICT.rawValue:
                logFlurry = true;
                showSupportAction = true;
                failureReason = "Data conflict"
            case EDAMErrorCode_ENML_VALIDATION.rawValue:
                logFlurry = true;
                showSupportAction = true;
                failureReason = "Permission Denied"
            case EDAMErrorCode_RATE_LIMIT_REACHED.rawValue:
                failureReason = "Rate limit reached"
                logFlurry = false
                
            default:
                    // EN error codes are only (1-19) hence We would like to show a neat error so going into the userinfo dict of the Evernote error and getting the details of NSURL error.
                if failureReason == "Unknown" {
                    let errorInfoDict = error.userInfo
                    if let urlError = errorInfoDict["error"] as? NSError, urlError.responds(to: #selector(getter: error.localizedDescription)){
                        failureReason = urlError.localizedDescription
                    }
                    else if FTENPublishError.isAuthError(error) {
                        failureReason = error.localizedDescription;
                    }
                }
            }
            #endif
            UserDefaults.standard.set(failureReason, forKey: EVERNOTE_PUBLISH_ERROR)
            UserDefaults.standard.set(showSupportAction, forKey: EN_PUBLISH_ERR_SHOW_SUPPORT)
            UserDefaults.standard.synchronize()
        }
        FTENSyncUtilities.recordSyncLog("Publish failed with reason: \(failureReason). Error: \(error)")
        if (logFlurry) {
            FTLogError("Evernote Publish Error", attributes: ["Reason": failureReason])
        }
    }
    
    func chooseNotebookToPublish() {
        var ignoreIDs = FTENIgnoreListManager.shared.ignoredNotebooksID()
        if let currentDocumentID = currentOpenedDocumentUUID {
            var mutIgnoreIds = ignoreIDs
            mutIgnoreIds.append(currentDocumentID)
            ignoreIDs = mutIgnoreIds
        }
        //Create a publish request for any dirty shelfItem that is enabled for EN sync
        let predicate = NSPredicate(format: "parentRecord==nil AND isDirty==YES AND syncEnabled==YES AND deleted==NO AND (NOT (nsGUID IN %@))", ignoreIDs)
        
        let syncRecord = FTENSyncUtilities.fetchTopManagedObject(withEntity: "ENSyncRecord", predicate: predicate) as? ENSyncRecord
        if let syncRecord = syncRecord, !FTNoteshelfDocumentManager.shared.isDocumentOpen(for: syncRecord.nsGUID) {
            currentlyPublingNotebookId = syncRecord.nsGUID
        } else {
            //Choose any ENSyncRecord that corresponds a page and is dirty and its parentrecord is enabled for sync
            let predicate = NSPredicate(format: "parentRecord!=nil AND parentRecord.syncEnabled==YES AND isDirty==YES AND (NOT (parentRecord.nsGUID IN %@))", ignoreIDs)
            
            let record = FTENSyncUtilities.fetchTopManagedObject(withEntity: "ENSyncRecord", predicate: predicate) as? ENSyncRecord
            if let record = record,!FTNoteshelfDocumentManager.shared.isDocumentOpen(for: record.parent.nsGUID) {
                currentlyPublingNotebookId = record.parent.nsGUID
            }
        }
    }
    func isPublishPending() -> Bool {
        let predicate = NSPredicate(format: "isDirty==YES")
        let parentRecord = FTENSyncUtilities.fetchTopManagedObject(withEntity: "ENSyncRecord", predicate: predicate) as? ENSyncRecord
        return parentRecord != nil ? true : false
        
    }
    // MARK: Publish Request delegate
    func didCompletePublishRequestWithError(_ error: Error?) {
        UIApplication.shared.endBackgroundTask(taskId)
        UserDefaults.standard.removeObject(forKey: EVERNOTE_PUBLISH_ERROR)
        UserDefaults.standard.removeObject(forKey: EN_PUBLISH_ERR_SHOW_SUPPORT)
        UserDefaults.standard.removeObject(forKey: "EVERNOTE_LAST_LOGIN_ALERT_TIME")
        
        if let error = error as NSError?{
            logPublishError(error)
            publishDidFail()
        } else {
            executeBlock(onPublishQueue: { [self] in
                 #if !targetEnvironment(macCatalyst)
                self.publishNextRequest()
                #endif
            })
        }
    }
    func didCompletePublishRequest(withIgnore ignoreEntry: FTENIgnoreEntry) {
        if let title = ignoreEntry.title {
            FTENPublishManager.recordSyncLog("Ignored sync for the Notebook with title - \(title)")
        }
        FTENIgnoreListManager.shared.add(ignoreEntry)
        self.didCompletePublishRequestWithError(nil)
    }
    
    func markThisNotebook(asProblematic notebookId: String?, title: String?) {
        FTENPublishManager.recordSyncLog("Ignored sync for the Problematic Notebook - \(title ?? "")")
        let ignoreEntry = FTENIgnoreEntry(title: title ?? "", ignoreType: FTENIgnoreReasonType.fileNotFound, notebookID: notebookId ?? "", shouldDisplay: false)
        FTENIgnoreListManager.shared.add(ignoreEntry)
    }
    // MARK: Sync Record related
    func updateSyncRecordForShelf(withDict inDict: [String : Any]) {
        executeBlock(onPublishQueue: {
            
            let nsGUID = inDict["nsGUID"] as? String
            if let nsGUID = nsGUID {
                let predicate = NSPredicate(format: "nsGUID==%@", nsGUID)
                var shelfRecord = FTENSyncUtilities.fetchTopManagedObject(withEntity: "ENSyncRecord", predicate: predicate) as? ENSyncRecord
                if shelfRecord == nil {
                    //We need not insert a new record if the deleted flag is set.
                    let isDeleted = inDict["deleted"] as? NSNumber
                    if isDeleted?.boolValue ?? false {
                        return
                    }
                    shelfRecord = NSEntityDescription.insertNewObject(forEntityName: "ENSyncRecord", into: self.managedObjectContext()) as? ENSyncRecord
                    
                    UserDefaults.standard.set(true, forKey: "EvernotePubUsed")
                    UserDefaults.standard.synchronize()
                }
                shelfRecord?.nsGUID = nsGUID
                let enGUID = inDict["enGUID"] as? String
                if let enGUID = enGUID {
                    shelfRecord?.enGUID = enGUID
                }
                let url = inDict["url"] as? String
                if let url = url {
                    shelfRecord?.url = url
                }
                let isDirty = inDict["isDirty"] as? NSNumber
                if let isDirty = isDirty {
                    shelfRecord?.isDirty = isDirty.boolValue
                }
                let isDeleted = inDict["deleted"] as? NSNumber
                if let isDeleted = isDeleted {
                    shelfRecord?.deleted = isDeleted.boolValue
                }
                let type = inDict["type"] as? NSNumber
                if let type = type {
                    shelfRecord?.type = type.int16Value
                }
                let syncEnabled = inDict["syncEnabled"] as? NSNumber
                if let syncEnabled = syncEnabled {
                    shelfRecord?.syncEnabled = syncEnabled.boolValue
                }
                let lastUpdated = inDict["lastUpdated"] as? NSNumber
                if let lastUpdated = lastUpdated {
                    shelfRecord?.lastUpdated = lastUpdated
                }
                self.commitDataChanges()
                //If the sync gets disabled for this shelfItem, we need to stop the publish process for this notebook.
                if shelfRecord?.nsGUID == self.currentlyPublingNotebookId {
                    if shelfRecord?.syncEnabled == false || shelfRecord?.deleted == true {
                        self.currentlyPublingNotebookId = nil
                    }
                }
                //remove from ignore list
                FTENIgnoreListManager.shared.removeNotebook(shelfRecord?.nsGUID)
            }
        })
    }
    // MARK: Sync Logs
    
    func nsENLogPath() -> String? {
        var path = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).map(\.path).last
        path = URL(fileURLWithPath: path ?? "").appendingPathComponent("ns-en.log").path
        return path
    }
    func generateSyncLog() {
        let t = DispatchSemaphore(value: 0)
        executeBlock(onPublishQueue: { [self] in
            let request = NSFetchRequest<NSFetchRequestResult>()
            let entity = NSEntityDescription.entity(forEntityName: "SyncLog", in: self.managedObjectContext())
            request.entity = entity
            let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
            request.sortDescriptors = [sortDescriptor]
            let logs = FTENSyncUtilities.fetchData(request)
            
            if let logPath = self.nsENLogPath(){
                let fileURL = URL(fileURLWithPath: logPath);
                do {
                    let filemanager = FileManager();
                    if(!filemanager.fileExists(atPath: fileURL.path)) {
                        filemanager.createFile(atPath: fileURL.path, contents: nil, attributes: nil);
                    }
                    let fileHandle : FileHandle = try FileHandle(forWritingTo: fileURL)
                    fileHandle.seekToEndOfFile();
                    
                    if let syncLogs = logs as? [SyncLog]{
                        for log in syncLogs {
                            var syncLog  = DateFormatter.localizedString(from: NSDate.init(timeIntervalSinceReferenceDate: TimeInterval(log.date.int64Value)) as Date, dateStyle: DateFormatter.Style.short, timeStyle: DateFormatter.Style.long)
                            syncLog += " "
                            syncLog += log.log
                            syncLog += "\n"
                            
                            let data = syncLog.data(using: String.Encoding.utf8);
                            if(data != nil) {
                                fileHandle.write(data!);
                                fileHandle.synchronizeFile();
                            }
                        }
                        fileHandle.closeFile()
                    }
                }catch let error as NSError {
                    #if DEBUG
                    debugPrint("\(error)");
                    #endif
                }
            }
            FTCLSLog("EN: sema signal")
            t.signal()
        })
        FTCLSLog("EN: sema wait")
        t.wait(timeout: DispatchTime.distantFuture)
    }

    func publishOnlyOnWifi() -> Bool {
        return UserDefaults.standard.bool(forKey: EVERNOTE_PUBLISH_ON_WIFI_ONLY)
    }
    func showAlertForRelogin(onError error: Error?) {
        #if !targetEnvironment(macCatalyst)
        guard let nserror = error as? NSError else {
            return;
        }
        if (nserror.code == EDAMErrorCode_AUTH_EXPIRED.rawValue || FTENPublishError.isAuthError(nserror)) {
            let alertViewController = UIAlertController(title: NSLocalizedString("EvernoteAuthTokenExpiredTitle", comment: "Evernote Token Expired"), message: nil, preferredStyle: .alert)
            
            let action = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: { _ in
                alertViewController.dismiss(animated: true)
            })
            alertViewController.addAction(action)
            let controller = UIApplication.shared.keyWindow?.visibleViewController
            let login = UIAlertAction(title: NSLocalizedString("Login", comment: "Login"), style: .default, handler: { [self] _ in
                
                if let controller = UIApplication.shared.keyWindow?.visibleViewController {
                    self.loginToEvernote(with: controller) {  [weak self] success in
                        if success {
                            self?.startPublishing()
                        }
                    }
                }
                alertViewController.dismiss(animated: true)
            })
            alertViewController.addAction(login)
            DispatchQueue.main.async(execute: {
                controller?.present(alertViewController, animated: true)
                UserDefaults.standard.set(Date.timeIntervalSinceReferenceDate, forKey: "EVERNOTE_LAST_LOGIN_ALERT_TIME")
                UserDefaults.standard.synchronize()
            })
        }
        #endif
    }
    // MARK: - ENBusinessSupport
    func showAccountChooser(_ fromViewController: UIViewController?, withCompletionHandler completionHandler: @escaping (_ evernoteAccountType: EvernoteAccountType) -> Void) {
        #if !targetEnvironment(macCatalyst)
        if (EvernoteSession.shared().businessUser == nil) {
            completionHandler(EvernoteAccountType.evernoteAccountPersonal)
            return
        }
        #endif
        let alertController = UIAlertController(title: NSLocalizedString("ChooseAccount", comment: "ChooseAccount"), message: nil, preferredStyle: .alert)
        
        let alertActionPersonal = UIAlertAction(title: NSLocalizedString("Personal", comment: "Personal"), style: .default, handler: { _ in
            FTENPublishManager.recordSyncLog("User is opting for personal account to sync")
            
            completionHandler(EvernoteAccountType.evernoteAccountPersonal)
        })
        alertController.addAction(alertActionPersonal)
        let alertActionBusiness = UIAlertAction(title: NSLocalizedString("Business", comment: "Business"), style: .default, handler: { _ in
            FTENPublishManager.recordSyncLog("User is opting for business account to sync")
            completionHandler(EvernoteAccountType.evernoteAccountBusiness)
        })
        alertController.addAction(alertActionBusiness)
        let alertActionCancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: { _ in
            FTENPublishManager.recordSyncLog("User is cancelling account option")
            completionHandler(EvernoteAccountType.evernoteAccountUnknown)
        })
        alertController.addAction(alertActionCancel)
        fromViewController?.present(alertController, animated: true, completion: nil)
    }
    func showBusinessSupportHelpIfNeeded(_ onViewController: UIViewController?) {
        let kEvernoteBusinessSupportHelp = "EvernoteBusinessSupportHelp"
        let kEvernoteBusinessSupportHelpDisplayed = "Displayed"
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
            let standardUserDefaults = UserDefaults.standard
            if let evernoteBusinessSupportHelpValue = standardUserDefaults.value(forKey: kEvernoteBusinessSupportHelp) as? String, !(evernoteBusinessSupportHelpValue == kEvernoteBusinessSupportHelpDisplayed) {
                #if !targetEnvironment(macCatalyst)
                if EvernoteSession.shared().businessUser != nil {
                    FTLogError("EN Business Alert Shown", attributes: nil)
                    FTCLSLog("EN Business Alert Shown")
                    let alertController = UIAlertController(title: "Good news!", message: "Noteshelf now supports auto-publish to Evernote Business notebooks. You can choose between Business and Personal when you enable Evernote Sync on a specific notebook.", preferredStyle: .alert)
                    
                    let alertAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: { _ in
                        standardUserDefaults.setValue(kEvernoteBusinessSupportHelpDisplayed, forKey: kEvernoteBusinessSupportHelp)
                        standardUserDefaults.synchronize()
                    })
                    alertController.addAction(alertAction)
                    onViewController?.present(alertController, animated: true)
                } else {
                    UserDefaults.standard.setValue(kEvernoteBusinessSupportHelpDisplayed, forKey: kEvernoteBusinessSupportHelp)
                    UserDefaults.standard.synchronize()
                }
                #endif
            }
        })
    }
    // MARK: - NS2
    func disableBackupForShelfItem(withUUID uuid: String?) {
        executeBlock(onPublishQueue: { [weak self] in
            let predicate = NSPredicate(format: "nsGUID==%@", uuid ?? "")
            let parentRecord = FTENSyncUtilities.fetchTopManagedObject(withEntity: "ENSyncRecord", predicate: predicate) as? ENSyncRecord
            parentRecord?.syncEnabled = false
            self?.commitDataChanges()
        })
    }
    private func addMemoryWarningNotificationObserver(){
    #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
        NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: nil) { [weak self] (_) in
            guard let self = self else {
                return;
            }
            self.executeBlock {
                self.ftENNotebook = nil
            }
        };
    #endif
    }
    // MARK:- App State Notification-
    func addAppStateNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterbackground(_:)),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(UIApplicationDelegate.applicationDidBecomeActive(_:)),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
    }
    
    @objc func applicationDidEnterbackground(_ notificaiton: Notification?) {
        cancelPublishing()
    }
    
    @objc func applicationDidBecomeActive(_ notificaiton: Notification) {
        startPublishing()
    }
}

extension FTENPublishManager{
    static func applyDefaultBackupPreferences(forItem documentItem:FTDocumentItemProtocol?, documentUUID: String){
        if let item = documentItem {
            item.documentUUID = documentUUID
            if FTENPublishManager.shared.isLoggedin() {
                DispatchQueue.main.async(execute:  {
                    let evernotePublishManager = FTENPublishManager.shared;
                    evernotePublishManager.enableSync(for: item);
                    evernotePublishManager.updateSyncRecord(forShelfItem: item, withDocumentUUID: documentUUID);
                    #if !targetEnvironment(macCatalyst)
                    evernotePublishManager.updateSyncRecord(forShelfItemAtURL: item.URL, withDeleteOption: true, andAccountType: (EvernoteSession.shared().businessUser != nil ? EvernoteAccountType.evernoteAccountBusiness : EvernoteAccountType.evernoteAccountPersonal))
                    #endif
                });
            }
        }
    }
}

