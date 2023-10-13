//
//  NSURL_Application_Specific_Paths.swift
//  Noteshelf
//
//  Created by Amar on 30/6/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

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
        var fileItemURL = self.standardizedFileURL;
        let filePath = fileItemURL.path;
        let searchString = "/private";
        if(filePath.hasPrefix(searchString)) {
            let range = filePath.startIndex..<filePath.endIndex;

            fileItemURL = URL.init(fileURLWithPath: filePath.replacingOccurrences(of: searchString, with: "", options: String.CompareOptions.anchored, range: range));
        }
        return fileItemURL;
    }
    
    func isPinEnabledForDocument() -> Bool {
        if let attri = getExtendedAttribute(for: .documentIsSecure), let isSecure = attri.stringValue?.lowercased().stringToBool {
            return isSecure
        }
        let securityPath = self.appendingPathComponent("secure.plist");
        let isEnabled: Bool
        if(FileManager().fileExists(atPath: securityPath.path)) {
            isEnabled = true;
        } else {
            isEnabled = false
        }
        let isSecureAttribute = FileAttributeKey.ExtendedAttribute(key: .documentIsSecure, string: isEnabled.boolToString.lowercased())
        try? self.setExtendedAttributes(attributes: [isSecureAttribute])
        return isEnabled;
    }
}
