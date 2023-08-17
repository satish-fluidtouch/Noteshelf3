//
//  FTSharedAction.swift
//  Noteshelf
//
//  Created by Matra on 10/09/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTSharedAction: NSObject {

    var importGUID:String = UUID().uuidString
    var fileName:String = ""
    var fileURL:String = ""
    var collectionName: String?
    var groupName: String?
    var sourceURL:String = ""
    var documentUrlHash:String = ""
    var importStatus:FTImportStatus = .notStarted;
    
    convenience init(dictionary : [String : String])
    {
        self.init();
        if dictionary["importGUID"] != nil{
            self.importGUID=dictionary["importGUID"]!
        }
        
        self.fileName = dictionary["fileName"] ?? ""
        self.fileURL = dictionary["fileURL"] ?? ""
        self.sourceURL = dictionary["sourceURL"] ?? ""
        self.documentUrlHash = dictionary["documentUrlHash"] ?? ""
        self.collectionName = dictionary["collectionName"] ?? ""
        self.groupName = dictionary["groupName"] ?? ""
        if let status = dictionary["importStatus"] as NSString? {
            self.importStatus = FTImportStatus(rawValue: status.integerValue) ?? FTImportStatus.notStarted;
        }
    }
    
    func dictionaryRepresentation() -> [String : String]
    {
        var dictAction = [String:String]()
        dictAction["importGUID"] = self.importGUID
        dictAction["fileName"] = self.fileName
        dictAction["fileURL"] = self.fileURL
        dictAction["sourceURL"] = self.sourceURL
        dictAction["documentUrlHash"] = self.documentUrlHash
        dictAction["collectionName"] = self.collectionName
        dictAction["groupName"] = self.groupName
        dictAction["importStatus"] = "\(self.importStatus.rawValue)"
        return dictAction
    }
    
    override var debugDescription: String {
        return self.dictionaryRepresentation().description;
    }
}
