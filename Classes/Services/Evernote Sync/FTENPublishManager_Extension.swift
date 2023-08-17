//
//  FTENPublishManager_Extension.swift
//  Noteshelf
//
//  Created by Siva on 13/05/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTDocumentFramework
import FTCommon

extension FTENPublishManager {
    @objc func updateSyncRecord(forShelfItemAtURL url: URL,
                                withDocumentUUID uuid: String,
                                andEnSyncEnabled enSyncEnabled: Bool) {
        let dict = [
            "type": NSNumber(value: FTENSynRecordPDF.rawValue as UInt32),
            "nsGUID": uuid,
            "url": url.relativePathWRTCollection(),
            "isDirty": true,
            "lastUpdated": url.fileModificationDate.timeIntervalSinceReferenceDate,
            "syncEnabled": NSNumber(value: enSyncEnabled as Bool)
            ] as [String : Any];
        FTENPublishManager.shared.updateSyncRecordForShelf(withDict: dict);
    }
    
    func updateSyncRecord(forShelfItem shelfItem: FTShelfItemProtocol, withDocumentUUID uuid: String) {
        let dict = [
            "type": NSNumber(value: FTENSynRecordPDF.rawValue as UInt32),
            "nsGUID": uuid,
            "url": shelfItem.URL.relativePathWRTCollection(),
            "isDirty": true,
            "lastUpdated": shelfItem.fileModificationDate.timeIntervalSinceReferenceDate,
            "syncEnabled": NSNumber(value: shelfItem.enSyncEnabled as Bool)
            ] as [String : Any];
        FTENPublishManager.shared.updateSyncRecordForShelf(withDict: dict);
    }
    
    @objc func updateSyncRecord(forShelfItemAtURL url: URL, withDeleteOption shouldDeletePageRecords: Bool, andAccountType accountType: EvernoteAccountType) {
        self.executeBlock { 
            let semaphore = DispatchSemaphore(value: 0);
            
            DispatchQueue.global().async {
                func openDocument(pin: String?) {
                    let openRequest = FTDocumentOpenRequest(url: url, purpose: .read);
                    openRequest.pin = pin;
                    FTNoteshelfDocumentManager.shared.openDocument(request: openRequest) { (token, document, error) in
                        if let doc = document {
                            var pages = [[String : Any]]();
                            for page in doc.pages() {
                                var pageDictionary = [String : Any]();
                                pageDictionary["nsGUID"] = page.uuid;
                                pageDictionary["pageIndex"] = page.pageIndex();
                                pageDictionary["lastUpdated"] = page.lastUpdated;
                                pages.append(pageDictionary);
                            }
                            FTCLSLog("EN: sema signal");
                            semaphore.signal();
                            
                            self.createSyncRecords(forShelfItemWithDocumentUUID: doc.documentUUID, ofPages: pages, withDeleteOption: shouldDeletePageRecords, andAccountType: accountType);
                            FTNoteshelfDocumentManager.shared.closeDocument(document: doc,
                                                                            token: token,
                                                                            onCompletion: nil);
                        }
                        else {
                            FTCLSLog("EN: sema signal");
                            semaphore.signal();
                            runInMainThread {
                                UIAlertController.showAlert(withTitle: "", message: NSLocalizedString("FailedToOpenDocumentUnexpectedError", comment: "Failed to open the document due to unexpected error"), from: Application.keyWindow?.visibleViewController, withCompletionHandler: nil);
                            }
                        }
                    }
                }
                
                if url.isPinEnabledForDocument() {
                    let document = FTDocumentFactory.documentForItemAtURL(url) as? FTDocument;
                    document?.documentUUID(coordinatedAccess: { (uuid) in
                        if let pin = FTDocument.keychainGetPin(forKey: uuid) {
                            openDocument(pin: pin);
                        }
                        else {
                            FTLogError("EN: Failed to retrive Pin from keychain")
                            loggingPrint("Failed to retrive Pin from keychain.")
                        }
                    })
                }
                else {
                    openDocument(pin: nil);
                }
            };
            FTCLSLog("EN: sema wait");
            _ = semaphore.wait(timeout: DispatchTime.distantFuture);
        };
    }
    
    fileprivate func createSyncRecords(forShelfItemWithDocumentUUID uuid: String, ofPages pages: [[String : Any]], withDeleteOption shouldDeletePageRecords: Bool, andAccountType accountType: EvernoteAccountType) {
        self.executeBlock {
            let predicate = NSPredicate.init(format: "nsGUID==%@", uuid);
            
            var shelfItemRecord = FTENSyncUtilities.fetchTopManagedObject(withEntity: "ENSyncRecord", predicate: predicate) as? ENSyncRecord;
            if let shelfItemRecord = shelfItemRecord {
                FTENSyncUtilities.recordSyncLog("updating ENSyncRecord - \(uuid)");
                if(accountType != EvernoteAccountType.evernoteAccountUnknown)
                {
                    var previousType = EvernoteAccountType.evernoteAccountPersonal;
                    if(shelfItemRecord.isBusinessNote) {
                        previousType = EvernoteAccountType.evernoteAccountBusiness;
                    }
                    if(accountType != previousType) {
                        shelfItemRecord.enGUID = nil;
                    }
                }
            }
            else {
                FTENSyncUtilities.recordSyncLog("Creating ENSyncRecord - \(uuid)");
                shelfItemRecord = NSEntityDescription.insertNewObject(forEntityName: "ENSyncRecord", into: self.managedObjectContext()) as? ENSyncRecord;
                shelfItemRecord?.nsGUID = uuid;
                shelfItemRecord?.type = Int16(FTENSynRecordPDF.rawValue);
            }
            
            //remove from ignore list
            FTENIgnoreListManager.shared.removeNotebook(shelfItemRecord!.nsGUID);
            
            shelfItemRecord!.syncEnabled = true;
            if (accountType != EvernoteAccountType.evernoteAccountUnknown) {
                shelfItemRecord!.isBusinessNote = (accountType == EvernoteAccountType.evernoteAccountBusiness);
                if(shelfItemRecord!.isBusinessNote) {
                    FTZenDeskManager.incrementENSyncEnabledForBusinessStore();
                }
            }
            
            var pageGUIDs = Set<String>();
            
            pages.forEach({ (pageInfo) in
                if let nsGUID = pageInfo["nsGUID"] as? String {
                    let pageIndex = pageInfo["pageIndex"] as! Int;
                    let lastUpdated = pageInfo["lastUpdated"] as? NSNumber;
                    
                    pageGUIDs.insert(nsGUID);
                    
                    let predicate = NSPredicate.init(format: "nsGUID==%@ AND parentRecord.nsGUID==%@",nsGUID, uuid);
                    var pageRecord = FTENSyncUtilities.fetchTopManagedObject(withEntity: "ENSyncRecord", predicate: predicate) as? ENSyncRecord;
                    if let pageRecord = pageRecord {
                        //Check if it has been modified after it has been published. This can be checked by comparing the last updated date. If yes, mark it as dirty
                        if(pageRecord.lastUpdated.doubleValue < lastUpdated!.doubleValue || (shelfItemRecord!.enGUID == nil))
                        {
                            FTENSyncUtilities.recordSyncLog("SyncRecord modified page modified: \(nsGUID)");
                            pageRecord.isDirty = true;
                            pageRecord.isContentDirty = true;
                            pageRecord.lastUpdated = lastUpdated;
                            pageRecord.index = pageIndex as NSNumber?;                            
                        }
                        else if(pageRecord.index.intValue != pageIndex ) //Check if the page index is changed
                        {
                            FTENSyncUtilities.recordSyncLog("SyncRecord modified Page re-ordered: \(nsGUID)");
                            pageRecord.isDirty = true;
                            pageRecord.index = pageIndex as NSNumber?;
                        }
                    }
                    else {
                        FTENSyncUtilities.recordSyncLog("Creating SyncRecord new page- \(nsGUID)");
                        pageRecord = NSEntityDescription.insertNewObject(forEntityName: "ENSyncRecord", into: self.managedObjectContext()) as? ENSyncRecord;
                        pageRecord?.nsGUID=nsGUID;
                        pageRecord?.parent=shelfItemRecord;
                        if let lastUpdated = lastUpdated {
                            pageRecord?.lastUpdated = lastUpdated;
                        }
                        else {
                            pageRecord?.lastUpdated = pageRecord!.parent.lastUpdated;
                        }
                        pageRecord?.index = pageIndex as NSNumber?;
                    }
                    pageRecord?.type = shelfItemRecord!.type;
                    self.commitDataChanges();
                }
                else {
                    #if DEBUG
                    debugPrint("Page does not have nsGUID!");
                    #endif
                }
                
            });
            self.commitDataChanges();
            
            if(shouldDeletePageRecords)
            {
                //Delete any ENSyncRecord objects whose pages are deleted
                //Get child ENSyncRecord objects of shelfItemRecord
                if let pageRecords = shelfItemRecord?.childRecords as? Set<ENSyncRecord> {
                    var pageRecordGUIDs = Set<String>();
                    pageRecords.forEach({ (pageRecord) in
                        pageRecordGUIDs.insert(pageRecord.nsGUID);
                    });
                    pageRecordGUIDs = pageRecordGUIDs.subtracting(pageGUIDs);
                    
                    //Mark the records as deleted for which there is no corresponding page object
                    pageRecordGUIDs.forEach({ (pageRecordGUID) in
                        let predicate = NSPredicate.init(format: "nsGUID==%@ AND parentRecord.nsGUID==%@", pageRecordGUID, uuid);
                        if let pageRecord = FTENSyncUtilities.fetchTopManagedObject(withEntity: "ENSyncRecord", predicate: predicate) as? ENSyncRecord {
                            pageRecord.deleted = true;
                            pageRecord.isDirty = true;
                        }
                    });
                    self.commitDataChanges();
                }
            }
            self.startPublishing();
        }
    }
    
    //MARK:- SyncMap
    typealias FTSyncMapItemType = [String:Any]
    typealias FTSyncMapType = [String:FTSyncMapItemType]
    
    var mappingFileURL: URL {
        let fileURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).last!.appendingPathComponent("EnSyncMap.plist");
        return fileURL;
    }
    
    var mappingFilePath: String {
        return self.mappingFileURL.path;
    }
    
    @objc func fetchSyncMap() {
        do {
            let fileManager = FileManager.default;
            let filePath = self.mappingFilePath;
            if !fileManager.fileExists(atPath: filePath) {
                let data = try PropertyListSerialization.data(fromPropertyList: FTSyncMapType(), format: .xml, options: 0);
                fileManager.createFile(atPath: filePath, contents: data, attributes: nil);
            }
            let data = try Data(contentsOf: self.mappingFileURL);
            if let dictionary = try PropertyListSerialization.propertyList(from: data, options: PropertyListSerialization.ReadOptions.mutableContainers, format: nil) as? FTSyncMapType {
                self.syncEnabledBooks = dictionary
            }
        }
        catch {
        }
    }
    
    func saveSyncMap() {
        do {
            let fileManager = FileManager.default;
            let data = try PropertyListSerialization.data(fromPropertyList: self.syncEnabledBooks, format: .xml, options: 0);
            fileManager.createFile(atPath: self.mappingFilePath, contents: data, attributes: nil);
        }
        catch {
            #if DEBUG
            debugPrint("Problem in storing EnSyncMap");
            #endif
        }
    }
    
    @objc func updateSyncMapDocumentID(from oldID: String!, to newID: String!) {
        self.syncEnabledBooks?.removeValue(forKey: oldID);
        let syncItem = FTENSyncItemInfo(documentID: newID);
        self.syncEnabledBooks?[newID] = syncItem.dictionaryRepresentation
        self.saveSyncMap();
    }
    
    func enableSync(for documentItem: FTDocumentItemProtocol) {
        let syncItem = FTENSyncItemInfo(documentItem: documentItem);
        let documentUUID = documentItem.documentUUID!;
        self.syncEnabledBooks?[documentUUID] = syncItem.dictionaryRepresentation
        self.saveSyncMap();
        NotificationCenter.default.post(name: NSNotification.Name("ShelfItem_\(documentUUID)"), object: nil, userInfo: ["documentUUID" : documentUUID, "url" : documentItem.URL]);
    }
    
    func disableSync(for documentItem: FTDocumentItemProtocol) {
        let documentUUID = documentItem.documentUUID!;
        self.syncEnabledBooks?.removeValue(forKey: documentUUID);
        self.saveSyncMap();
        self.disableBackupForShelfItem(withUUID: documentUUID);
        NotificationCenter.default.post(name: NSNotification.Name("ShelfItem_\(documentUUID)"), object: nil, userInfo: ["documentUUID" : documentUUID, "url" : documentItem.URL]);
    }
    
    func isSyncEnabled(forDocumentItem documentItem: FTDocumentItemProtocol) -> Bool {
        return self.isSyncEnabled(forDocumentUUID: documentItem.documentUUID!);
    }
    
    @objc func isSyncEnabled(forDocumentUUID documentUUID: String) -> Bool {
        if let _ = self.syncEnabledBooks?[documentUUID] {
            return true;
        }
        return false;
    }
    
    func checkENSyncPrerequisite(from viewController: UIViewController, withCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        //Check if the evernote publish feature is purchased
        if(!FTENPublishManager.shared.evernotePublishFeaturePurchased())
        {
            FTENPublishManager.recordSyncLog("Prompting Evernote purchase option");
            
            FTENPublishManager.shared.promptPurchaseOfENPublishFeature(viewController);
            completionHandler(true);
        }
        if(!FTENPublishManager.shared.isLoggedin())
        {
            FTENPublishManager.recordSyncLog("Prompting Evernote login page");
            FTENPublishManager.shared.loginToEvernote(with: viewController, completionHandler: { (success: Bool) in
                FTENPublishManager.recordSyncLog("Login completed with success - \(success)");
                completionHandler(success);
            });
            return;
        }
        completionHandler(true);
    }
    
    //MARK:- Updating ShelfProvider
    func updateDocumentId(from oldID: String!, to newID: String!) {
        self.executeBlock { 
            if let syncRecord = FTENSyncUtilities.fetchTopManagedObject(withEntity: "ENSyncRecord", predicate: NSPredicate(format: "nsGUID==%@", oldID)) as? ENSyncRecord {
                syncRecord.nsGUID = newID;
                self.commitDataChanges();
                self.updateSyncMapDocumentID(from: oldID, to: newID);
            }
        }
    }
}
