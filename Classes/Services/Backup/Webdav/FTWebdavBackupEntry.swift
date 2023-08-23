//
//  FTWebdavBackupEntry.swift
//  Noteshelf
//
//  Created by Ramakrishna on 08/02/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTWebDavBackupFileInfo: FTCloudBackupFileInfo {
    var webdavPath: String?
    var backupFileName: String?

    override func info() -> [String: String]? {
        if let path = webdavPath, let fileName = backupFileName {
            var info = [String: String]();
            info["webdavPath"] = path;
            info["backupFileName"] = fileName;
            return info;
        }
        return nil;
    }
    
    override func updte(with info: [String:String]) {
        if let path = info["webdavPath"] {
            self.webdavPath = path;
        }
        if let fileName = info["backupFileName"] {
            self.backupFileName = fileName;
        }
    }
    
    override func resetProperties() {
        self.webdavPath = nil
        self.backupFileName = nil
    }
}

class FTWebdavBackupEntry : FTCloudBackup {
    override init(withDict dict: [String: Any]) {
        super.init(withDict: dict);
        if let webdavInfo = dict["webdav"] {
            if let singleFormatInfo = webdavInfo as? [String:String] {
                self.nsFileInfo.updte(with: singleFormatInfo)
            }
            else if let multiFormatInfo = webdavInfo as? [String: [String:String]] {
                if let pdfInfo = multiFormatInfo[kExportFormatPDF.cloudFileInfoKey] {
                    self.pdfFileInfo.updte(with: pdfInfo)
                }
                if let bookInfo = multiFormatInfo[kExportFormatNBK.cloudFileInfoKey] {
                    self.nsFileInfo.updte(with: bookInfo);
                }
            }
        }
    }
    
    override func representation() -> [String : Any] {
        var dict = super.representation()
        var webdavInfo: [String : Any] = [:]
        if let pdfInfo = self.pdfFileInfo.info() {
            webdavInfo[kExportFormatPDF.cloudFileInfoKey] = pdfInfo;
        }
        if let bookInfo = self.nsFileInfo.info() {
            webdavInfo[kExportFormatNBK.cloudFileInfoKey] = bookInfo;
        }
        dict["webdav"] = webdavInfo
        return dict
    }
    
    override func resetProperties() {
        super.resetProperties()
    }
}
