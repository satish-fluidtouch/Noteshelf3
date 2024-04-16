//
//  FTFileNameUniqueProtocol.swift
//  Noteshelf
//
//  Created by Amar on 17/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

public struct FTFileExtension {
    public static let ns2 = "ns"
    public static let ns3 = "ns3"
    public static let shelf = "shelf"
    public static let group = "group"
    public static let sortIndex = "nsindex"
}

#if !os(watchOS)
public extension FileManager {
    static func uniqueFileName(_ documentName : String,
                        inFolder folderURL: URL,
                        pathExt : String? = nil) -> String {
        var count = 0
        
        let validDocName = documentName.validateFileName() as NSString;
        let fileExtension = validDocName.pathExtension;

        var fileName = validDocName.deletingPathExtension;
        if(fileName.isEmpty) {
            fileName = NSLocalizedString("Untitled", comment: "Untitled")
        }

        var newDocName = documentName;
        
        var nameExists = true;
        while (nameExists) {
            if(count == 0) {
                newDocName = "\(fileName).\(fileExtension)";
            }
            else {
                newDocName = "\(fileName) \(count).\(fileExtension)";
            }
            
            nameExists = FileManager.fileExitsWith(newDocName,inFolder:folderURL,pathExt: pathExt);
            if(nameExists == false) {
                break;
            }
            else {
                count += 1;
            }
        }
        return newDocName;
    }
    
    fileprivate static func fileExitsWith(_ name : String,
                                          inFolder folderURL : URL,
                                          pathExt : String? = nil) -> Bool {
        var url = folderURL;
        url = url.appendingPathComponent(name);
        var isDirectory = ObjCBool.init(false);
        var fileExists = false;
        let pathExtension = pathExt ?? FTFileExtension.ns3;

        if(url.pathExtension == pathExtension) {
            if(FileManager.init().fileExists(atPath: url.path)) {
                fileExists = true;
            }
        }
        else {
            if(FileManager.init().fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue) {
                fileExists = true;
            }
        }
        return fileExists;
    }
}
#endif
