//
//  FTCloudBackup.swift
//  FTAutoBackupSwift
//
//  Created by Simhachalam Naidu on 13/08/20.
//  Copyright © 2020 Simhachalam Naidu. All rights reserved.
//

import UIKit

@objc open class FTCloudBackup: NSObject {
    var backupInfo: [String: Any]?
    var uuid: String = UUID().uuidString
    var filePath: String = ""
    var lastUpdated: NSNumber?
    var lastBackupDate: NSNumber?
    var isDirty: Bool = false
    var errorDescription: String?
    
    @objc init(withDict dict: [String: Any]) {
        super.init()
        self.backupInfo = dict;
        self.updateWithDict(dict)
        if(nil == self.lastBackupDate) {
            self.lastBackupDate = self.lastUpdated
        }
    }
    
    func updateWithDict(_ dict: [String: Any]) {
        if let UUID = dict[FTBackUpGUIDKey] as? String {
            self.uuid = UUID
        }
        if let path = dict[FTBackUpPackagePathKey] as? String {
            self.filePath = path
        }
        if let updated = dict[FTBackUpLastUpdatedKey] as? NSNumber {
            self.lastUpdated = updated
        }
        if let backupDate = dict[FTBackUpLastBackedUpDateKey] as? NSNumber {
            self.lastBackupDate = backupDate
        }
        self.isDirty = dict[FTBackUpIsDirtyKey] as? Bool ?? false
        self.errorDescription = dict[FTBackUpErrorDescriptionKey] as? String
    }
    
    func representation() -> [String: Any] {
        var dictInfo = [String: Any]()
        dictInfo[FTBackUpGUIDKey] = self.uuid
        dictInfo[FTBackUpIsDirtyKey] = self.isDirty
        dictInfo[FTBackUpPackagePathKey] = filePath
        
        if(nil != self.lastUpdated) {
            dictInfo[FTBackUpLastUpdatedKey] = self.lastUpdated
        }
        if self.lastBackupDate != nil {
            dictInfo[FTBackUpLastBackedUpDateKey] = self.lastBackupDate
        }
        if(nil != self.errorDescription) {
            dictInfo[FTBackUpErrorDescriptionKey] = self.errorDescription
        }
        return dictInfo
    }
    
    func resetProperties() {
        self.isDirty = false
    }
}
