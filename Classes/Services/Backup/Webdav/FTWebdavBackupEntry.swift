//
//  FTWebdavBackupEntry.swift
//  Noteshelf
//
//  Created by Ramakrishna on 08/02/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTWebdavBackupEntry : FTCloudBackup {
    var webdavPath: String?
    var backupFileName: String?
    
    override init(withDict dict: [String: Any]) {
        super.init(withDict: dict);
      
        if let webdavInfo = dict["webdav"] as? [String : Any] {
            self.webdavPath = webdavInfo["webdavPath"] as? String
            self.backupFileName = webdavInfo["backupFileName"] as?  String
        }
    }
    
    override func representation() -> [String : Any] {
        var dict = super.representation()
        var webdavInfo: [String : Any] = [:]
        if let path = self.webdavPath {
            webdavInfo["webdavPath"] = path
        }
        if let fileName = self.backupFileName {
            webdavInfo["backupFileName"] = fileName
        }
        dict["webdav"] = webdavInfo
        return dict
    }
    
    override func resetProperties() {
        super.resetProperties()
        self.webdavPath = nil
        self.backupFileName = nil
    }
}
