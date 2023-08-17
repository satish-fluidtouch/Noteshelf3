//
//  FTOneDriveBackupEntry.swift
//  Noteshelf
//
//  Created by Amar on 20/12/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTOneDriveBackupEntry: FTCloudBackup  {

    var oneDriveFileID : String?
    
    override init(withDict dict: [String: Any]) {
        super.init(withDict: dict)
        let oneDriveInfo = dict["oneDriveInfo"] as? [String : String];
        if(nil != oneDriveInfo) {
            self.oneDriveFileID = oneDriveInfo!["oneDriveID"];
        }
    }
    
    override func representation() -> [String: Any] {
        var info = super.representation();
        var oneDriveInfo = [String : String]();
        if(nil != self.oneDriveFileID) {
            oneDriveInfo["oneDriveID"] = self.oneDriveFileID;
        }
        info["oneDriveInfo"] = oneDriveInfo;
        return info;
    }
    
    override func resetProperties() {
        super.resetProperties();
        self.oneDriveFileID = nil;
    }
    
}
