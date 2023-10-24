//
//  FTENSyncUtilities.swift
//  Noteshelf
//
//  Created by Ramakrishna on 26/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

let SYNC_LOG_CLEAR_IN_DAYS = 10
let SYNC_LOG_MAX_RECORDS = 10000
let SYNC_LOG_TRUNCATE_RECORDS = 4000


@objcMembers class FTENSyncUtilities : NSObject {
    #if !targetEnvironment(macCatalyst)
    class func resource(forKey key: String, inResources resources: [NSArray], matching matchingvalue: String) -> EDAMResource? {
        var resourceToReturn: EDAMResource?
        (resources as NSArray?)?.enumerateObjects({ (resource : Any, _ : Int, stop :UnsafeMutablePointer<ObjCBool>) in
            if let edamResource = resource as? EDAMResource, let value = edamResource.value(forKey: key) as? String, value == matchingvalue{
                resourceToReturn = edamResource
                stop.pointee = true
            }
        })
        return resourceToReturn
    }
    #endif
    #if !targetEnvironment(macCatalyst)
    class func enmlRepresentation(withResources resources: [EDAMResource]?,syncRecords: [ENSyncRecord]?) -> String? {
        guard let resources = resources, let syncRecords = syncRecords else{
            return nil
        }
        let myWriter = ENMLWriter()
        myWriter.startDocument()
        //Attachment data should go here
        for (index,record) in syncRecords.enumerated() {
            var resourceToReturn: EDAMResource?
            if record.enGUID != nil{
                for resource in resources where resource.guid == record.enGUID {
                   // if resource.guid == record.enGUID{
                        resourceToReturn = resource
                        break
                    //}
                }
            }
            if nil == resourceToReturn {
                let fileName = (record.nsGUID ?? "") + ".jpg"
                for resource in resources where resource.attributes.fileName == fileName{
                    //if resource.attributes.fileName == fileName{
                        resourceToReturn = resource
                        break
                    //}
                }
            }
            if nil == resourceToReturn {
                if nil != record.enGUID {
                    FTLogError("EN: Failed to find resource", attributes: [
                        "enGUID": record.enGUID ?? ""
                    ])
                } else {
                    FTLogError("EN: Failed to find resource", attributes: [
                        "enGUID": "Not fouund"
                    ])
                }
                FTENSyncUtilities.recordSyncLog("Failed to find resource")
            }else{
                myWriter.startElement("div",withAttributes: [
                    "style": "padding: 0px 0px 0px 0px;margin-bottom:15px;"
            ])
                myWriter.startElement("div",withAttributes:[
                    "style": String(format: "max-width:%dpx;margin:0px auto 0px auto;padding:0px 0px 0px 0px;display:block;background-color:white;background-color:#ffffff;-webkit-box-shadow:1px 1px 3px rgba(0,0,0,.25);border-radius:7px;", resourceToReturn?.width ?? 0)] )
                if let resourceData = resourceToReturn?.data {
                    myWriter.writeResource(
                        withDataHash: resourceData.bodyHash,
                        mime: resourceToReturn?.mime,
                        attributes: [
                            "style": "margin: 0px; padding:0px; border-radius:7px;"
                        ])
                }
                myWriter.endElement()
                #if DEBUG
                myWriter.startElement("div",withAttributes: [
                    "style": "color: rgb(128, 128, 128);margin-top:5px;text-align:center;"])
                myWriter.write(String.localizedStringWithFormat(NSLocalizedString("PageNofN", comment: "Page N of N"), index + 1, syncRecords.count as CVarArg ))
                myWriter.endElement()
                #endif
                myWriter.endElement()
            }
        }

        //Footer : Start
        let htmlString = "<a href=\"https://www.itunes.apple.com/us/app/noteshelf-2/id1271086060?mt=8\" >Noteshelf</a>"
        let publishByString = String.localizedStringWithFormat(NSLocalizedString("PublishedByNoteshelf", comment: "Published By Noteshelf"), htmlString)
        myWriter.startElement("div",withAttributes: [
            "style": "color: #808080;text-align: center;padding:10px 10px;"
        ])
        myWriter.write(publishByString)
        myWriter.endElement()
        //Footer : end
        myWriter.endDocument()
        let contents = myWriter.contents?.replacingOccurrences(of: "<en-note", with: "<en-note style=\"padding: 15px 15px 1px 15px;text-align:center;background-color:#eef2f3;\"")
        let xmlVersionAndDocType: String = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">"
        
        if let contents {
            return xmlVersionAndDocType + contents
        } else {
            return nil
        }
    }
    #endif
    
    #if !targetEnvironment(macCatalyst)
    class func enmlRepresentation(withResources resources: [EDAMResource]?) -> String? {
        guard let resources = resources else{
            return nil
        }
        let myWriter = ENMLWriter()
        myWriter.startDocument()

        for (index,resource) in resources.enumerated() {
            myWriter.startElement(
                "div",
                withAttributes: [
                    "style": "padding: 0px 0px 0px 0px;margin-bottom:15px;"
            ])
            myWriter.startElement("div",
                withAttributes: [
                    "style": String(format: "max-width:%dpx;margin:0px auto 0px auto;padding:0px 0px 0px 0px;display:block;background-color:white;background-color:#ffffff;-webkit-box-shadow:1px 1px 3px rgba(0,0,0,.25);border-radius:7px;", Int(resource.width))
            ])
            if let edamData = resource.data {
                myWriter.writeResource(
                    withDataHash: edamData.bodyHash,
                    mime: resource.mime,
                    attributes: [
                        "style": "margin: 0px; padding:0px; border-radius:7px;"
                ])
            }
            myWriter.endElement()
            #if DEBUG
            myWriter.startElement("div",
                withAttributes: [
                    "style": "color: rgb(128, 128, 128);margin-top:5px;text-align:center;"
            ])
            myWriter.write(String.localizedStringWithFormat(NSLocalizedString("PageNofN", comment: "Page N of N"), index + 1, resources.count as CVarArg))
            myWriter.endElement()
            #endif

            myWriter.endElement()
        }
        myWriter.endDocument()
        let contents = myWriter.contents?.replacingOccurrences(of: "<en-note", with: "<en-note style=\"padding: 15px 15px 1px 15px;text-align:center;background-color:#eef2f3;\"")
        let xmlVersionAndDocType: String = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">"

        if let contents {
            return xmlVersionAndDocType + contents
        } else {
            return nil
        }
    }
    #endif
    //MARK:- Fetch From DB
    class func fetchData(_ fetchRequest: NSFetchRequest<NSFetchRequestResult>) -> [Any]? {
        do {
            let fetchResults: [Any] = try FTENPublishManager.shared.managedObjectContext().fetch(fetchRequest)
            return fetchResults
        }catch {
            // Handle the error.
            debugLog("Unresolved error \(error),\(String(describing: (error as NSError?)?.userInfo))")
            exit(-1);  // Fail
        }
    }
    
    class func fetchItems(withEntity entityName: String, predicate: NSPredicate?) -> [Any]? {
        let request = NSFetchRequest<NSFetchRequestResult>()
        let entity = NSEntityDescription.entity(forEntityName: entityName , in: FTENPublishManager.shared.managedObjectContext())
        request.entity = entity
        if let reqPredicate = predicate {
            request.predicate = reqPredicate
        }
        let tags = FTENSyncUtilities.fetchData(request)
        return tags
    }
    class func fetchItems(withEntity entityName: String, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) -> [Any]? {
        let request = NSFetchRequest<NSFetchRequestResult>()
        let entity = NSEntityDescription.entity(forEntityName: entityName , in: FTENPublishManager.shared.managedObjectContext())
        request.entity = entity
        if let reqPredicate = predicate {
            request.predicate = reqPredicate
        }
        if let reqSortDescriptors = sortDescriptors {
            request.sortDescriptors = reqSortDescriptors
        }
        let tags = FTENSyncUtilities.fetchData(request)
        return tags
    }
    class func fetchTopManagedObjectID(withEntity entityName: String, predicate: NSPredicate?) -> NSManagedObjectID? {
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.fetchLimit = 1
        request.resultType = .managedObjectIDResultType
        
        let entity = NSEntityDescription.entity(forEntityName: entityName, in: FTENPublishManager.shared.managedObjectContext())
        request.entity = entity
        if let reqPredicate = predicate {
            request.predicate = reqPredicate
        }
        if let tags = FTENSyncUtilities.fetchData(request), !tags.isEmpty, let managedObjectID = tags.first as? NSManagedObjectID{
            return managedObjectID
        }
        return nil
    }
    class func fetchTopManagedObject(withEntity entityName: String, predicate: NSPredicate?) -> NSManagedObject? {
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.fetchLimit = 1
        let entity = NSEntityDescription.entity(forEntityName: entityName, in: FTENPublishManager.shared.managedObjectContext())
        request.entity = entity
        if let reqPredicate = predicate {
            request.predicate = reqPredicate
        }
        if let tags = FTENSyncUtilities.fetchData(request), !tags.isEmpty, let managedObject = tags.first as? NSManagedObject{
            return managedObject
        }
        return nil
    }
    class func fetchTopManagedObject(withEntity entityName: String, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) -> NSManagedObject? {
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.fetchLimit = 1
        let entity = NSEntityDescription.entity(forEntityName: entityName, in: FTENPublishManager.shared.managedObjectContext())
        request.entity = entity
        if let reqPredicate = predicate {
            request.predicate = reqPredicate
        }
        if let reqSortDescriptors = sortDescriptors {
            request.sortDescriptors = reqSortDescriptors
        }
        if let tags = FTENSyncUtilities.fetchData(request), !tags.isEmpty, let managedObject = tags.first as? NSManagedObject{
            return managedObject
        }
        return nil
    }
    class func recordSyncLog(_ log: String?) {
        if let log = log {
            FTCLSLog("EN: \(log)")
            if let syncLog = NSEntityDescription.insertNewObject(forEntityName: "SyncLog", into: FTENPublishManager.shared.managedObjectContext()) as? SyncLog{
                syncLog.date = NSNumber(value: Date().timeIntervalSinceReferenceDate)
                syncLog.log = log
                FTENPublishManager.shared.commitDataChanges()
            }
        }
    }
    class func truncateSyncLogUpperLimitIfReachedUpperLimit() {
        let count = FTENSyncUtilities.fetchCount(withEntity: "SyncLog", predicate: nil)
        
        if count > SYNC_LOG_MAX_RECORDS {
            
            NSLog("Truncating began")
            let request = NSFetchRequest<NSFetchRequestResult>()
            request.fetchLimit = SYNC_LOG_TRUNCATE_RECORDS
            
            let entity = NSEntityDescription.entity(forEntityName: "SyncLog", in: FTENPublishManager.shared.managedObjectContext())
            request.entity = entity
            
            let sortDescripter = NSSortDescriptor(key: "date", ascending: true)
            request.sortDescriptors = [sortDescripter]
            
            if let logsToDelete = FTENSyncUtilities.fetchData(request) as? [SyncLog]{
                
                for log in logsToDelete {
                    FTENPublishManager.shared.managedObjectContext().delete(log)
                }
            }
            FTENPublishManager.shared.commitDataChanges()
            FTENSyncUtilities.recordSyncLog("Synclog truncated: max records")
        }
        FTENSyncUtilities.clearSyncLogsCreated(beforeDays: Float(SYNC_LOG_CLEAR_IN_DAYS))
    }
    class func clearSyncLogsCreated(beforeDays days: Float) {
        let currentTimeInterval = Date().timeIntervalSinceReferenceDate
        let timeIntervalForClearLog = TimeInterval(Float(currentTimeInterval) - days * 24 * 60 * 60)
        
        if let syncLogs = FTENSyncUtilities.fetchItems(withEntity: "SyncLog", predicate: NSPredicate(format: "date<%f", timeIntervalForClearLog)) as? [SyncLog]{
            
            for log in syncLogs{
                FTENPublishManager.shared.managedObjectContext().delete(log)
            }
            FTENPublishManager.shared.commitDataChanges()
            if !syncLogs.isEmpty {
                FTENSyncUtilities.recordSyncLog("Synclog truncated: 10 days")
            }
        }
    }
    class func fetchCount(withEntity entityName: String, predicate: NSPredicate?) -> Int {
        let request = NSFetchRequest<NSFetchRequestResult>()
        
        let entity = NSEntityDescription.entity(forEntityName: entityName, in: FTENPublishManager.shared.managedObjectContext())
        request.entity = entity
        if let predicate = predicate {
            request.predicate = predicate
        }
        var count: Int?
        do {
            count = try FTENPublishManager.shared.managedObjectContext().count(for: request)
        } catch {
            // Handle the error.
            debugLog("Unresolved error \(error),\(String(describing: (error as NSError?)?.userInfo))")
            exit(-1) // Fail
        }
        return count ?? 0
    }
}
extension String {
    func validatingForEvernoteNoteName() -> String {
        //Note name cannot have control charecters
        var noteName = components(separatedBy: CharacterSet.controlCharacters).joined(separator: " ")
        
        //Note name cannot be greater than 255 charecters
        if noteName.count > 255 {
            noteName = (noteName as NSString).substring(to: 255)
        }
        
        //Note name cannot have leading or trailing whitespaces
        noteName = noteName.trimmingCharacters(in: CharacterSet.whitespaces)
        
        if noteName == "" {
            return NSLocalizedString("Untitled", comment: "Untitled")
        } else {
            return noteName
        }
    }
}
