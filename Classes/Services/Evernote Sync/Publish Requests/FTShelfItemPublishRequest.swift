//
//  FTShelfItemPublishRequest.swift
//  Noteshelf
//
//  Created by Ramakrishna on 15/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

#if !targetEnvironment(macCatalyst)
class FTShelfItemPublishRequest  :FTBasePublishRequest {
    var objectID: NSManagedObjectID?
    
    override init(object refObject: NSManagedObjectID?, delegate: FTBasePublishRequestDelegate?) {
        super.init(object: refObject, delegate: delegate)
        self.objectID = refObject
        self.delegate = delegate
    }
    override func startRequest(){
        super.startRequest()
        //Check if the shelf item is already synced
        var shelfItemRecord: ENSyncRecord?
        do {
            shelfItemRecord = try self.managedObjectContext()?.existingObject(with: objectID!) as? ENSyncRecord
        } catch {
            self.delegate?.didCompletePublishRequestWithError?(error)
            return
        }
        if let shelfRecord = shelfItemRecord {
            if shelfRecord.deleted{
                deleteNote(forShelfItemRecord: shelfItemRecord)
            }else if shelfRecord.isDirty{
                //Get the shelfItem object corresponding to the record
                if shelfRecord.enGUID == nil {
                    createNote(forShelfItemRecord: shelfRecord)
                } else {
                    updateNote(forShelfItemRecord: shelfRecord)
                }
            }
        }
    }
    func deleteNote(forShelfItemRecord shelfItemRecord: ENSyncRecord?) {
        
        //For now we just delete the shelfItemRecord and not delete the notebook from server
        if let shelfItemRecord = shelfItemRecord {
            managedObjectContext()?.delete(shelfItemRecord)
        }
        commitDataChanges()
        FTENSyncUtilities.recordSyncLog("Deleted notebook record (no action taken)")
        self.delegate?.didCompletePublishRequestWithError?(nil)
        
    }
    func noteDidGetDeletedFromEvernote() {
        FTENSyncUtilities.recordSyncLog("Note got deleted from Evernote. Preparing to send all pages for this notebook")
        
        var parentRecord: ENSyncRecord?
        do {
            parentRecord = try managedObjectContext()?.existingObject(with: objectID!) as? ENSyncRecord
        } catch {
            self.delegate?.didCompletePublishRequestWithError?(error)
            return
        }
        parentRecord?.enGUID = nil
        parentRecord?.isDirty = true
        var predicate: NSPredicate?
        if let parentRecord = parentRecord {
            predicate = NSPredicate(format: "parentRecord==%@", parentRecord)
        }
        if let childRecords = FTENSyncUtilities.fetchItems(withEntity: "ENSyncRecord", predicate: predicate) as? [ENSyncRecord]{
            for record in childRecords {
                record.enGUID = nil
                record.isDirty = true
                record.isContentDirty = true
                commitDataChanges()
                self.delegate?.didCompletePublishRequestWithError?(nil)
            }
        }
    }
}
#endif
