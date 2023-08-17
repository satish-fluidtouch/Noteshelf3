//
//  FTDropboxBackupEntry.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 31/08/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

@objcMembers class FTDropboxBackupEntry: FTCloudBackup {
    var rev: String?
    var dropboxPath: String?

    override init(withDict dict: [String: Any]) {
        super.init(withDict: dict);
      
        if let dropboxInfo = dict["dropbox"] as? [String : Any] {
            self.dropboxPath = dropboxInfo["dropboxPath"] as? String
            self.rev = dropboxInfo["revision"] as? String
        }
    }
    
    override func representation() -> [String : Any] {
        var dict = super.representation()
        var dropboxInfo: [String : Any] = [:]
        if let path = self.dropboxPath {
            dropboxInfo["dropBoxPath"] = path
        }
        if let revValue = self.rev {
            dropboxInfo["revision"] = revValue
        }
        dict["dropbox"] = dropboxInfo
        return dict
    }
    
    override func resetProperties() {
        super.resetProperties()
        self.rev = nil
        self.dropboxPath = nil
    }
}
