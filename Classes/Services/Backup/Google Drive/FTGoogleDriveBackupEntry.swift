//
//  FTGoogleDriveBackupEntry.swift
//  Noteshelf
//
//  Created by sreenu cheedella on 16/04/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTGDBackupFileInfo: FTCloudBackupFileInfo {
    var googleDriveFileId: String?
    var googleDriveParentId: String?
    var relativePath: String?
    
    override func info() -> [String: String]? {
        if let gFileID = googleDriveFileId {
            var info = [String: String]();
            info["googleDriveID"] = gFileID;
            info["googleDriveParentID"] = self.googleDriveParentId ?? "";
            info["relativePath"] = self.relativePath ?? "";
            return info;
        }
        return nil;
    }
    
    override func updte(with info: [String:String]) {
        self.googleDriveFileId = info["googleDriveID"];
        self.googleDriveParentId = info["googleDriveParentID"];
        self.relativePath = info["relativePath"];
    }
    
    override func resetProperties() {
        self.googleDriveFileId = nil;
    }
}

class FTGoogleDriveBackupEntry: FTCloudBackup {
    override class func fileInfo() -> FTCloudBackupFileInfo {
        return FTGDBackupFileInfo();
    }
    
    override init(withDict dict: [String: Any]) {
        super.init(withDict: dict);
        let driveInfo = dict["googleDriveInfo"];
        if let singleFormatInfo = driveInfo as? [String: String] {
            self.nsFileInfo.updte(with: singleFormatInfo);
        }
        else if let multiFormatInfo = driveInfo as? [String : [String: String]] {
            if let pdfInfo = multiFormatInfo[kExportFormatPDF.cloudFileInfoKey] {
                self.pdfFileInfo.updte(with: pdfInfo);
            }
            if let bookInfo = multiFormatInfo[kExportFormatNBK.cloudFileInfoKey] {
                self.nsFileInfo.updte(with: bookInfo);
            }
        }
    }
    
    override func representation() -> [String : Any] {
        var info = super.representation();
        var googleDriveInfo = [String : [String: String]]();
        if let pdfInfo = self.pdfFileInfo.info() {
            googleDriveInfo[kExportFormatPDF.cloudFileInfoKey] = pdfInfo;
        }
        if let nsBookInfo = self.pdfFileInfo.info() {
            googleDriveInfo[kExportFormatNBK.cloudFileInfoKey] = nsBookInfo;
        }
        info["googleDriveInfo"] = googleDriveInfo;
        return info;
    }
}
