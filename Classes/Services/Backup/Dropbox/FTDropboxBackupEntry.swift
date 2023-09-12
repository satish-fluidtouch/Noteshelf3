//
//  FTDropboxBackupEntry.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 31/08/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTDBBackupFileInfo: FTCloudBackupFileInfo {
    var rev: String?
    var dropboxPath: String?

    override func info() -> [String: String]? {
        if let dbPath = self.dropboxPath, let rev = self.rev {
            var info = [String: String]();
            info["dropBoxPath"] = dbPath;
            info["revision"] = rev;
            return info;
        }
        return nil;
    }
    
    override func updte(with info: [String:String]) {
        self.dropboxPath = info["dropboxPath"];
        self.rev = info["revision"];
    }
    
    override func resetProperties() {
        self.rev = nil
        self.dropboxPath = nil
    }
}

@objcMembers class FTDropboxBackupEntry: FTCloudBackup {
    override class func fileInfo() -> FTCloudBackupFileInfo {
        return FTDBBackupFileInfo();
    }
    
    override init(withDict dict: [String: Any]) {
        super.init(withDict: dict);
        
        let driveInfo = dict["dropbox"];
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
        var dict = super.representation()
        
        var dropboxInfo = [String : [String: String]]();
        if let pdfInfo = self.pdfFileInfo.info() {
            dropboxInfo[kExportFormatPDF.cloudFileInfoKey] = pdfInfo;
        }
        if let nsBookInfo = self.pdfFileInfo.info() {
            dropboxInfo[kExportFormatNBK.cloudFileInfoKey] = nsBookInfo;
        }
        dict["dropbox"] = dropboxInfo;
        return dict
    }
}
