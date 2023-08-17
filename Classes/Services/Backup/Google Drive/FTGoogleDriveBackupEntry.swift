//
//  FTGoogleDriveBackupEntry.swift
//  Noteshelf
//
//  Created by sreenu cheedella on 16/04/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTGoogleDriveBackupEntry: FTCloudBackup {
    var googleDriveFileId: String?
    var googleDriveParentId: String?
    var relativePath: String?

    override init(withDict dict: [String: Any]) {
        super.init(withDict: dict);
        let googleDriveInfo = dict["googleDriveInfo"] as? [String : String];
        if(nil != googleDriveInfo) {
            self.googleDriveFileId = googleDriveInfo!["googleDriveID"];
            self.googleDriveParentId = googleDriveInfo!["googleDriveParentID"];
            self.relativePath = googleDriveInfo!["relativePath"];
        }
    }
    
    override func representation() -> [String : Any] {
        var info = super.representation();
        var googleDriveInfo = [String : String]();
        if(nil != self.googleDriveFileId) {
            googleDriveInfo["googleDriveID"] = self.googleDriveFileId;
            googleDriveInfo["googleDriveParentID"] = self.googleDriveParentId;
            googleDriveInfo["relativePath"] = self.relativePath;
        }
        info["googleDriveInfo"] = googleDriveInfo;
        return info;
    }
    
    override func resetProperties() {
        super.resetProperties();
        self.googleDriveFileId = nil;
    }
}
