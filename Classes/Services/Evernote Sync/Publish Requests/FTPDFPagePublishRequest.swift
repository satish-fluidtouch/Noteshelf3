//
//  FTPDFPagePublishRequest.swift
//  Noteshelf
//
//  Created by Siva on 30/03/17.
//
//

import UIKit
import CoreData

#if !targetEnvironment(macCatalyst)
// import EvernoteSDK
#endif
import FTDocumentFramework

class FTPDFPagePublishRequest: FTBasePublishRequest {
    
    var pdfDocument: FTDocumentProtocol!
    var objectID : NSManagedObjectID?
    private var docToken = FTDocumentOpenToken();
    
    override init(object refObject: NSManagedObjectID?, delegate: FTBasePublishRequestDelegate?) {
        self.objectID = refObject
        super.init(object: refObject, delegate: delegate)
        self.delegate = delegate
    }
    
    override func startRequest() {
        //Check if a page needs to be created or updated in EN
        do {
            let pageRecord = try self.managedObjectContext()?.existingObject(with: self.objectID!) as? ENSyncRecord;
            if(nil == pageRecord) {
                self.delegate?.didCompletePublishRequestWithError!(request: self,error:nil);
            }
            else {
                if(pageRecord!.isDeleted()) {
                    self.deleteResourceForPage(pageRecord);
                }
                else {
                    #if !targetEnvironment(macCatalyst)
                    self.updateResourceForPage(pageRecord);
                    #endif
                }
            }
        }
        catch let error as NSError {
            self.delegate?.didCompletePublishRequestWithError?(request: self,error:error);
        }
    }
    
    fileprivate func deleteResourceForPage(_ pageRecord: ENSyncRecord!) {
        FTENPublishManager.recordSyncLog("Deleting Page-began");
        #if !targetEnvironment(macCatalyst)
        guard let session = EvernoteSession.shared(), session.isAuthenticated  else {
            let error = FTENPublishError.authError;
            FTENSyncUtilities.recordSyncLog(String(format: "Failed with Error:%@",error as CVarArg));
            self.delegate?.didCompletePublishRequestWithError?(request: self,error:error);
            return;
        }
        guard let parentGUID = pageRecord.parent.enGUID else {
            self.delegate?.didCompletePublishRequestWithError?(request: self,error:FTENPublishError.unexpectedError);
            return;
        }
        EvernoteNoteStore(session: session).getNoteWithGuid(parentGUID, withContent: true, withResourcesData: true, withResourcesRecognition: false, withResourcesAlternateData: false) { note in
            self.executeBlock {
                if let note,!note.active {
                    self.noteDidGetDeletedFromEvernote();
                    return;
                }

                do {
                    if let pageRecord = try self.managedObjectContext()?.existingObject(with: self.objectID!) as? ENSyncRecord {
                        if let note,
                           let orderedResources = note.resources,
                           orderedResources.contains(where: {nil != pageRecord.enGUID && ($0 as AnyObject).guid == pageRecord.enGUID}) {
                            let pageContents = FTENSyncUtilities.fetchItems(withEntity: "ENSyncRecord", predicate: NSPredicate(format: "enGUID == %@", pageRecord.enGUID)) as? [ENSyncRecord];

                            if pageContents?.count == 1 {
                                note.resources = NSMutableArray(array: orderedResources.filter({($0 as AnyObject).guid != pageRecord.enGUID}))
                            }

                            let predicateForResourcedPages = NSPredicate(format: "parentRecord.nsGUID==%@ AND enGUID != nil AND nsGUID!=%@", pageRecord.parent.nsGUID, pageRecord.nsGUID);
                            let sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)];

                            let pagesForENContent = FTENSyncUtilities.fetchItems(withEntity: "ENSyncRecord", predicate: predicateForResourcedPages, sortDescriptors: sortDescriptors) as? [ENSyncRecord];

                            let enml = FTENSyncUtilities.enmlRepresentation(withResources: note.resources as? [EDAMResource], syncRecords: pagesForENContent);
                            note.content = String.init(format: EVERNOTE_NOTE_TEMPLATE, enml!);

                            var lastUpdated = pageRecord.lastUpdated.doubleValue;

                            let filePath = pageRecord.parent.fullURLPath;
                            if ((nil != filePath) && (FileManager.default.fileExists(atPath: filePath!))) {
                                let url = URL(fileURLWithPath: filePath!);
                                lastUpdated = url.fileModificationDate.timeIntervalSinceReferenceDate
                            }

                            note.updated = EDAMTimestamp(lastUpdated)
                            guard EvernoteSession.shared().isAuthenticated else {
                                let error = FTENPublishError.authError;
                                FTENSyncUtilities.recordSyncLog(String(format: "Failed with Error:%@",error as CVarArg));
                                self.delegate?.didCompletePublishRequestWithError?(request: self,error:error);
                                return;
                            }
                            EvernoteNoteStore(session: session).update(note) { updatedNote in
                                self.executeBlock {
                                    do {
                                        if let pageRecord = try self.managedObjectContext()?.existingObject(with: self.objectID!) as? ENSyncRecord {
                                            self.managedObjectContext()?.delete(pageRecord);
                                            self.commitDataChanges();
                                            FTENSyncUtilities.recordSyncLog(String(format: "Deleting Page-completed for notebook: %@", (updatedNote?.title)!));

                                            self.delegate?.didCompletePublishRequestWithError?(request: self,error:nil);
                                        }
                                        else {
                                            self.delegate?.didCompletePublishRequestWithError?(request: self,error:nil);//Dont return error as we want to proceed in this case. (Should never come here though!)
                                            return;
                                        }
                                    }
                                    catch {
                                        self.delegate?.didCompletePublishRequestWithError?(request: self,error:FTENPublishError.unexpectedError);
                                        return;
                                    }

                                }
                            } failure: { error in
                                self.executeBlock {
                                    FTENSyncUtilities.recordSyncLog("Failed with Error:\(error)");
                                    self.delegate?.didCompletePublishRequestWithError?(request: self,error:error);
                                }
                            };
                        }
                        else {
                            //If page does not exist on Evernote, no point in updating it again. Just delete the sync record.
                            self.managedObjectContext()?.delete(pageRecord);
                            self.commitDataChanges();

                            FTENSyncUtilities.recordSyncLog("Deleting Page-completed for notebook: \(note?.title)");
                            self.delegate?.didCompletePublishRequestWithError?(request: self,error:nil);
                            return;
                        }
                    }
                    else {
                        self.delegate?.didCompletePublishRequestWithError?(request: self,error:FTENPublishError.unexpectedError);
                        return;
                    }
                }
                catch {
                    self.delegate?.didCompletePublishRequestWithError?(request: self,error:FTENPublishError.unexpectedError);
                    return;
                }
            }
        } failure: { error in
            self.executeBlock {
                if let nsError = error as? NSError, nsError.code == Int(EDAMErrorCode_UNKNOWN.rawValue) {
                    self.noteDidGetDeletedFromEvernote();
                }
                else {
                    FTENSyncUtilities.recordSyncLog("Failed with error: \(error)");
                    self.delegate?.didCompletePublishRequestWithError?(request: self,error:error);
                }
                if let error {
                }
            }
        }
        return
        #endif
    }
    #if !targetEnvironment(macCatalyst)
    func orderedListOfResourcesFromNote(_ note: EDAMNote, parentGUID: NSString) -> [EDAMResource] {
        var listOfRecords = [ENSyncRecord]();
        note.resources?.forEach { (resource) in
            let fileName: NSString = "" //resource.attributes.fileName as NSString;
            let predicate = NSPredicate.init(format: "nsGUID==%@ AND parentRecord.nsGUID==%@", fileName.deletingPathExtension, parentGUID);
            if let syncRecord = FTENSyncUtilities.fetchTopManagedObject(withEntity: "ENSyncRecord", predicate: predicate) as? ENSyncRecord {
                listOfRecords.append(syncRecord);
            }
        };
        let sortedRecords = listOfRecords.sorted { $0.index.intValue < $1.index.intValue };
        
        var orderedList = [EDAMResource]();
        
//        sortedRecords.forEach { (syncRecord) in
//            let nsGUID: NSString = syncRecord.nsGUID as NSString;
//            let resourcesForCurrentSyncRecord = note.resources.filter({ (resource) -> Bool in
//                if (resource.attributes.fileName == nsGUID as String || resource.attributes.fileName == nsGUID.appendingPathExtension("jpg")!) {
//                    return true;
//                }
//                return false;
//            });
//            if resourcesForCurrentSyncRecord.count > 0 {
//                orderedList.append(resourcesForCurrentSyncRecord[0] );
//            }
//        };
        return orderedList;
    }
    
    fileprivate func updateResourceForPage(_ pageRecord: ENSyncRecord!) {
        FTENPublishManager.recordSyncLog("Updating Page-began");
        
        guard let session = EvernoteSession.shared(), session.isAuthenticated else {
            let error = FTENPublishError.authError;
            FTENSyncUtilities.recordSyncLog(String(format: "Failed with Error:%@",error as CVarArg));
            self.delegate?.didCompletePublishRequestWithError?(request: self,error:error);
            return;
        }
        guard let parentGUID = pageRecord.parent.enGUID else {
            self.delegate?.didCompletePublishRequestWithError?(request: self,error:FTENPublishError.unexpectedError);
            return;
        }
        if FTENPublishManager.shared.ftENNotebook?.edamNote == nil {
            EvernoteNoteStore(session: session).getNoteWithGuid(parentGUID, withContent: true, withResourcesData: true, withResourcesRecognition: true, withResourcesAlternateData: false) { note in
                self.executeBlock {
                    FTENPublishManager.shared.ftENNotebook?.edamNote = note
                    if let resources = note?.resources as? [EDAMResource] {
                        FTENPublishManager.shared.ftENNotebook?.edamResources = resources
                    }
                    updateNote()
                }
            } failure: { error in
                self.executeBlock(onPublishQueue: {
                    if let nserror = error as? NSError, (nserror.code == Int(EDAMErrorCode_UNKNOWN.rawValue)) {
                        self.noteDidGetDeletedFromEvernote();
                    }
                    else {
                        FTENSyncUtilities.recordSyncLog("Failed with error: \(error)");
                        self.delegate?.didCompletePublishRequestWithError?(request: self,error:error);
                    }
                });
            }
        }
        else {
            updateNote()
        }
        func updateNote()  {
            self.executeBlock {
                guard let note = FTENPublishManager.shared.ftENNotebook?.edamNote,note.active else {
                    self.noteDidGetDeletedFromEvernote();
                    return;
                }

                do {
                    if let pageRecord = try self.managedObjectContext()?.existingObject(with: self.objectID!) as? ENSyncRecord {

                        if FTNoteshelfDocumentManager.shared.isDocumentOpen(for: pageRecord.parent.nsGUID) {
                            FTENPublishManager.recordSyncLog(String(format: "Evernote Publish Skip - Document is in open state"));
                            let notebookOpenError = NSError(domain: "Noteshelf.EN.UpdatePage", code: 800, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("evernote.openNotebook.SyncSkip", comment: "Sync failed with reason - A notebook is in open state.")])
                            self.delegate?.didCompletePublishRequestWithError?(request: self,error:notebookOpenError);
                            return;
                        }

                        self.getPage(fromPageRecord: pageRecord, onCompletion: { (pdfPage) in
                            if let pdfPage = pdfPage {
                                //let orderedResources = note?.resources ?? [EDAMResource]();
                                var contentSizeForFlurry: Int32 = 0;

                                var resourcesMappedForAllPages = [EDAMResource]();
                                var orderedResources = [EDAMResource]()
                                if let resources = FTENPublishManager.shared.ftENNotebook?.edamResources {
                                    resourcesMappedForAllPages.append(contentsOf: resources);
                                    orderedResources = resources
                                }

                                var resource: EDAMResource?
                                if orderedResources.contains(where: {nil != pageRecord.enGUID && ($0 as AnyObject).guid == pageRecord.enGUID}) {
                                    if pageRecord.isContentDirty {
                                        let items = FTENSyncUtilities.fetchItems(withEntity: "ENSyncRecord", predicate: NSPredicate(format: "enGUID == %@",pageRecord.enGUID));
                                        if((items?.count)! > 1) {
                                            //if there is only one GUID usage the update the same or else create new one
                                        }
                                        else {
                                            let index = orderedResources.firstIndex(where: { (resource) -> Bool in
                                                let pageResource = resource ;
                                                if(pageResource.guid == pageRecord.enGUID) {
                                                    return true;
                                                }
                                                return false;
                                            });
                                            resourcesMappedForAllPages.remove(at: index!)
                                        }
                                        resource = (pdfPage as! FTPageEvernoteSyncProtocol).edamResource;
                                        if let resource = resource {
                                            resourcesMappedForAllPages.append(resource);
                                            contentSizeForFlurry = resource.data.size;
                                        }
                                        else {
                                            self.closeDocumentIfNeeded();
                                            self.snapshotFailedAction();
                                            return;
                                        }
                                    }
                                }
                                else {
                                    resource = (pdfPage as! FTPageEvernoteSyncProtocol).edamResource;
                                    if let resource = resource {
                                        resourcesMappedForAllPages.append(resource);
                                    }
                                    else {
                                        self.closeDocumentIfNeeded();
                                        self.snapshotFailedAction();
                                        return;
                                    }
                                }

                                if resourcesMappedForAllPages.contains(where: {nil == $0.data.bodyHash}) {
                                    FTLogError("Evernote Publish Error", attributes: ["Reason": "bodyHash nil"])
// commented below Code for diagnostics
//                                    self.closeDocumentIfNeeded();
//                                    self.snapshotFailedAction();
//                                    return;
                                }

                                let predicateForResourcedPages = NSPredicate(format: "parentRecord.nsGUID==%@ AND (enGUID != nil OR nsGUID==%@)",pageRecord.parent.nsGUID, pageRecord.nsGUID);
                                let sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)];

                                let pagesForENContent = FTENSyncUtilities.fetchItems(withEntity: "ENSyncRecord", predicate: predicateForResourcedPages, sortDescriptors: sortDescriptors) as? [ENSyncRecord];

                                if let enml = FTENSyncUtilities.enmlRepresentation(withResources: resourcesMappedForAllPages, syncRecords: pagesForENContent) {
                                    note.content = String.init(format: EVERNOTE_NOTE_TEMPLATE, enml);
                                }

                                note.resources = NSMutableArray(array:  resourcesMappedForAllPages);

                                if(pageRecord.isContentDirty)
                                {
                                    FTENSyncUtilities.recordSyncLog(String(format: "Updating content of page (%ld of %ld) of notebook: %@", pdfPage.pageIndex()+1, self.pdfDocument.pages().count, (note.title)!));

                                    note.updated = NSDate(timeIntervalSinceReferenceDate: pdfPage.lastUpdated.doubleValue).enedamTimestamp()
                                }
                                else
                                {
                                    FTENSyncUtilities.recordSyncLog(String(format: "Updating content of page (Content not modified) (%ld of %ld) of notebook: %@", pdfPage.pageIndex()+1, self.pdfDocument.pages().count, (note.title)!));
                                }
                                //Before updating the note, we set the isDirty flag to NO. if the update fails we reset it back to YES.
                                pageRecord.isDirty = false;
                                let pageContentWasDirty = pageRecord.isContentDirty;
                                pageRecord.isContentDirty = false;

                                self.commitDataChanges();

                                ////////////////////////////////////////
                                //Publish tags to Evernote
                                ////////////////////////////////////////

                                let tags = NSMutableSet();
                                if nil == note.tagNames {
                                    note.tagNames = NSMutableArray();
                                }
                                if(pdfPage is FTPageTagsProtocol) {
                                    (pdfPage as! FTPageTagsProtocol).tags().forEach{note.tagNames.add($0 as String)};
                                }
                                note.tagNames?.forEach{tags.add($0 )};
                                note.tagNames = NSMutableArray(array: tags.allObjects)
                                self.closeDocumentIfNeeded();

                                guard EvernoteSession.shared().isAuthenticated else {
                                    let error = FTENPublishError.authError;
                                    FTENSyncUtilities.recordSyncLog(String(format: "Failed with Error:%@",error as CVarArg));
                                    self.delegate?.didCompletePublishRequestWithError?(request: self,error:error);
                                    return;
                                }
                                EvernoteNoteStore(session: session).update(note) { updatedNote in
                                    self.executeBlock {
                                        do {
                                            if let updatedNote, let pageRecord = try self.managedObjectContext()?.existingObject(with: self.objectID!) as? ENSyncRecord {
                                                if(pageContentWasDirty) {
                                                    FTENSyncUtilities.recordSyncLog("Updating page-completed");
                                                }

                                                FTENPublishManager.shared.ftENNotebook?.edamNote = updatedNote
                                                if let _ = resource {
                                                    if let edamResources = updatedNote.resources as? [EDAMResource] {

                                                        FTENPublishManager.shared.ftENNotebook?.edamResources = edamResources
                                                        edamResources.filter({ (edamResource) -> Bool in
                                                            var fileName: NSString = edamResource.attributes.fileName as NSString;
                                                            fileName = fileName.deletingPathExtension as NSString;
                                                            return pageRecord.nsGUID == fileName as String;
                                                        }).forEach {
                                                            pageRecord.enGUID = $0.guid
                                                            self.commitDataChanges();
                                                        };
                                                    }
                                                    //                                                    self.updateResourceGUIDsOfNote(updatedNote);
                                                    //                                                    self.commitDataChanges();
                                                }
                                                self.delegate?.didCompletePublishRequestWithError?(request: self,error:nil);
                                            }
                                            else {
                                                self.delegate?.didCompletePublishRequestWithError?(request: self,error:nil);//Dont return error as we want to proceed in this case. (Should never come here though!)
                                                return;
                                            }
                                        }
                                        catch {
                                            self.delegate?.didCompletePublishRequestWithError?(request: self,error:FTENPublishError.unexpectedError);
                                            return;
                                        }
                                    }
                                } failure: { error in
                                    self.executeBlock(onPublishQueue: {
                                        FTENSyncUtilities.recordSyncLog("Failed to update page with error: \(error)");
                                        do {
                                            if let pageRecord = try self.managedObjectContext()?.existingObject(with: self.objectID!) as? ENSyncRecord {
                                                pageRecord.isDirty = true;
                                                if pageContentWasDirty {
                                                    pageRecord.isContentDirty = pageContentWasDirty;
                                                }
                                                self.commitDataChanges();
                                            }
                                        }
                                        catch {

                                        }

                                        if let nserror = error as? NSError, (nserror.code == Int(EDAMErrorCode_LIMIT_REACHED.rawValue))
                                        {
                                            let parentURL = pageRecord.parent.url as NSString;
                                            let title = parentURL.lastPathComponent.deletingPathExtension;
                                            let entry = FTENIgnoreEntry(title:title , ignoreType: FTENIgnoreReasonType.dataLimitReached, notebookID: pageRecord.parent.nsGUID)
                                            self.delegate?.didCompletePublishRequest?(request: self, withIgnore: entry);
                                        }
                                        else {
                                            self.delegate?.didCompletePublishRequestWithError?(request: self,error:error);
                                        }
                                    });
                                };
                            }
                            else {
                                self.closeDocumentIfNeeded();

                                FTENPublishManager.recordSyncLog(String(format: "Page not found"));

                                pageRecord.isDirty = false;
                                pageRecord.isContentDirty = false;
                                self.commitDataChanges();
                                self.delegate?.didCompletePublishRequestWithError?(request: self,error:nil);
                            }
                        });
                    }
                    else {
                        FTENPublishManager.recordSyncLog("ENSyncRecord is unavailable");
                        self.delegate?.didCompletePublishRequestWithError?(request: self,error:FTENPublishError.unexpectedError);
                        return;
                    }
                }
                catch let error as NSError {
                    FTENPublishManager.recordSyncLog(String(format: "Failed to update page with error:%@", error as CVarArg));

                    self.delegate?.didCompletePublishRequestWithError?(request: self,error:FTENPublishError.unexpectedError);
                    return;
                }

            }
        }
    }
    #endif
    
    fileprivate func closeDocumentIfNeeded()
    {
        if let doc = self.pdfDocument {
            FTNoteshelfDocumentManager.shared.closeDocument(document: doc, token: docToken, onCompletion: nil);
        }
        self.pdfDocument = nil;
    }
    
    //MARK:- Private
    fileprivate func getPage(fromPageRecord pageRecord: ENSyncRecord!, onCompletion completionHandler: @escaping ((FTPageProtocol?) -> Void)) {
        
        func openDocument(url: URL,pin: String?) {
            FTCLSLog("Doc Open - EN Page publish : \(url.title)")
            let openrequest = FTDocumentOpenRequest(url: url, purpose: .read);
            openrequest.pin = pin;
            FTNoteshelfDocumentManager.shared.openDocument(request: openrequest) { (token, document, error) in
                self.executeBlock(onPublishQueue: {
                    if let doc = document {
                        self.pdfDocument = doc;
                        self.docToken = token;
                        let matchingPages = self.pdfDocument.pages().filter({$0.uuid == pageRecord.nsGUID});
                        if let matchingPage = matchingPages.first {
                            completionHandler(matchingPage);
                        }
                        else {
                            completionHandler(nil);
                        }
                    }
                    else {
                        completionHandler(nil);
                    }
                });
            }
        }
        
        let filePath = pageRecord.parent.fullURLPath;
        if let path = filePath,
           FileManager().fileExists(atPath: path) {
            let url = URL(fileURLWithPath: path);
            if url.downloadStatus() == .downloaded {
                if(url.isPinEnabledForDocument()) {
                    let doc = FTDocumentFactory.documentForItemAtURL(url);
                    (doc as? FTDocument)?.documentUUID(coordinatedAccess: { (uuid) in
                        if let pin = FTDocument.keychainGetPin(forKey: uuid) {
                            openDocument(url: url, pin: pin);
                        }
                        else {
                            loggingPrint("Failed to retrive Pin from keychain.")
                            completionHandler(nil);
                        }
                    })
                }
                else {
                    openDocument(url: url, pin: nil);
                }
            }
            else {
                completionHandler(nil);
            }
        }
        else {
            completionHandler(nil);
        }
    }
    
    fileprivate func noteDidGetDeletedFromEvernote()
    {
        #if !targetEnvironment(macCatalyst)
        FTENSyncUtilities.recordSyncLog("Note got deleted from Evernote. Preparing to send all pages for this notebook");
        do {
            let pageRecord = try self.managedObjectContext()?.existingObject(with: self.objectID!) as! ENSyncRecord;
            let parentRecord = pageRecord.parent;
            parentRecord?.enGUID = nil;
            parentRecord?.isDirty = true;
            let predicate = NSPredicate.init(format: "parentRecord==%@", parentRecord!);
            let childRecords = FTENSyncUtilities.fetchItems(withEntity: "ENSyncRecord", predicate: predicate);
            childRecords?.enumerated().forEach({ (index,item) in
                let childRecord = item as! ENSyncRecord;
                childRecord.enGUID = nil;
                childRecord.isDirty = true;
                childRecord.isContentDirty = true;
            });
            self.commitDataChanges();
            self.delegate?.didCompletePublishRequestWithError?(request: self,error:nil);
        }
        catch let error as NSError{
            self.delegate?.didCompletePublishRequestWithError?(request: self,error:error);
        }
        #endif
    }
    
    fileprivate func sizeRangeStringForContentSize(_ pageSize : Int32) -> String?
    {
        var sizeRangeString : String?;
        if(pageSize > 0 && pageSize <= 200*1024) {
            sizeRangeString = "0-200KB";
        }
        else if(pageSize > 200*1024 && pageSize <= 400*1024) {
            sizeRangeString = "200-400KB";
        }
        else if(pageSize > 400*1024 && pageSize <= 600*1024) {
            sizeRangeString = "400-600KB";
        }
        else if(pageSize > 600*1024 && pageSize <= 800*1024) {
            sizeRangeString = "600-800KB";
        }
        else if(pageSize > 800*1024 && pageSize <= 1000*1024) {
            sizeRangeString = "800KB-1MB";
        }
        else if(pageSize > 1000*1024 && pageSize <= 1200*1024) {
            sizeRangeString = "1MB-1.2MB";
        }
        else if(pageSize > 1200*1024 && pageSize <= 1400*1024) {
            sizeRangeString = "1.2MB-1.4MB";
        }
        else if(pageSize > 1400*1024 && pageSize <= 1600*1024) {
            sizeRangeString = "1.4MB-1.6MB";
        }
        else if(pageSize > 1600*1024 && pageSize <= 1800*1024) {
            sizeRangeString = "1.6MB-1.8MB";
        }
        else if(pageSize > 1800*1024 && pageSize <= 2000*1024) {
            sizeRangeString = "1.8MB-2MB";
        }
        else if(pageSize > 2000*1024) {
            sizeRangeString = ">2MB";
        }
        return sizeRangeString;
    }
    
    private func snapshotFailedAction() {
        #if !targetEnvironment(macCatalyst)
        FTENSyncUtilities.recordSyncLog("Page Snapshot failed.");
        
        self.delegate?.didCompletePublishRequestWithError?(request: self,error:FTENPublishError.pageSnapshotError);
        #endif
    }
}
