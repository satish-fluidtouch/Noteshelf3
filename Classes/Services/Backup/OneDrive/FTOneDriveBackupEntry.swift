//
//  FTOneDriveBackupEntry.swift
//  Noteshelf
//
//  Created by Amar on 20/12/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTOneDriveBackupFileInfo: FTCloudBackupFileInfo {
    var oneDriveFileID : String?

    override func info() -> [String: String]? {
        if let gFileID = oneDriveFileID {
            var info = [String: String]();
            info["oneDriveID"] = gFileID;
            return info;
        }
        return nil;
    }
    
    override func updte(with info: [String:String]) {
        self.oneDriveFileID = info["oneDriveID"];
    }
    
    override func resetProperties() {
        self.oneDriveFileID = nil;
    }
}

class FTOneDriveBackupEntry: FTCloudBackup  {

    override class func fileInfo() -> FTCloudBackupFileInfo {
        return FTOneDriveBackupFileInfo();
    }
    
    override init(withDict dict: [String: Any]) {
        super.init(withDict: dict)
        let driveInfo = dict["oneDriveInfo"];
        if let singleFormatInfo = driveInfo as? [String : String] {
            self.nsFileInfo.updte(with: singleFormatInfo);
        }
        else if let multiFormatInfo = driveInfo as? [String : [String : String]] {
            if let pdfInfo = multiFormatInfo[kExportFormatPDF.cloudFileInfoKey] {
                self.pdfFileInfo.updte(with: pdfInfo);
            }
            else if let bookInfo = multiFormatInfo[kExportFormatNBK.cloudFileInfoKey] {
                self.nsFileInfo.updte(with: bookInfo);
            }
        }
    }
    
    override func representation() -> [String: Any] {
        var info = super.representation();
        var oneDriveInfo = [String : [String : String]]();
        if let pdfInfo = self.pdfFileInfo.info() {
            oneDriveInfo[kExportFormatPDF.cloudFileInfoKey] = pdfInfo;
        }
        if let bookInfo = self.nsFileInfo.info() {
            oneDriveInfo[kExportFormatNBK.cloudFileInfoKey] = bookInfo;
        }
        info["oneDriveInfo"] = oneDriveInfo;
        return info;
    }
}
