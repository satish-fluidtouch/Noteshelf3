//
//  NSURL_Application_Specific_Paths.swift
//  Noteshelf
//
//  Created by Amar on 30/6/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTDocumentFramework

extension URL {
    static func thumbnailFolderURL() -> URL
    {
        let libraryPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.libraryDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first;
        let thumbnailFolderPath = URL(fileURLWithPath: libraryPath!).appendingPathComponent("Thumbnails");
        
        var isDir = ObjCBool.init(false);
        if(!FileManager.default.fileExists(atPath: thumbnailFolderPath.path, isDirectory: &isDir) || !isDir.boolValue) {
            _ = try? FileManager.default.createDirectory(at: thumbnailFolderPath, withIntermediateDirectories: true, attributes: nil);
        }
        return thumbnailFolderPath;
    }
    
    func urlByDeleteingPrivate() -> URL
    {
        return FTDocumentUtils.resolvedURL(self);
    }
    
    func isPinEnabledForDocument() -> Bool {
        var valueToReturn = false
        #if !NOTESHELF_ACTION
        if self.downloadStatus() == .downloaded {
          let securityPath = self.appendingPathComponent("secure.plist");
          if(FileManager().fileExists(atPath: securityPath.path)) {
              valueToReturn = true;
          }
        }
        return valueToReturn
        #else
        return valueToReturn
        #endif
      }
}

extension FTShelfItemProtocol {
    func isPinEnabledForDocument() -> Bool {
        let valueToReturn: Bool
        if let document = self as? FTDocumentItemProtocol, document.isDownloaded {
            let securityPath = self.URL.appendingPathComponent("secure.plist");
            if(FileManager().fileExists(atPath: securityPath.path)) {
                valueToReturn = true
            } else {
                valueToReturn = false
            }
        } else {
            valueToReturn = false
        }
        return valueToReturn
    }
}
