//
//  FTShelfCollectionLocalRoot.swift
//  Noteshelf
//
//  Created by Akshay on 30/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTShelfCollectionLocalRoot: NSObject {
    let ns3Collection: FTShelfCollectionLocal

    override init() {
        //TODO: (AK) Think about a refactor for passing the Boolean or always compare the URL
        // Passing the boolean is a bit effective as we are injecting from the initializer
        self.ns3Collection = FTShelfCollectionLocal(rootURL: Self.userFolderURL())
        super.init()
    }
}

extension FTShelfCollectionLocalRoot {
    private static func userFolderURL() -> URL
    {
        let noteshelfURL = FTUtils.noteshelfDocumentsDirectory();
        let systemURL = noteshelfURL.appendingPathComponent("User Documents");
        let fileManger = FileManager();
        var isDir = ObjCBool.init(false);
        if(!fileManger.fileExists(atPath: systemURL.path, isDirectory: &isDir) || !isDir.boolValue) {
            try? fileManger.createDirectory(at: systemURL, withIntermediateDirectories: true, attributes: nil);
        }
        return systemURL;
    }

    private static func ns2UserFolderURL() -> URL
    {
        let noteshelfURL = FTUtils.ns2DocumentsDirectory();
        let systemURL = noteshelfURL.appendingPathComponent("User Documents");
        let fileManger = FileManager();
        var isDir = ObjCBool.init(false);
        if(!fileManger.fileExists(atPath: systemURL.path, isDirectory: &isDir) || !isDir.boolValue) {
            try? fileManger.createDirectory(at: systemURL, withIntermediateDirectories: true, attributes: nil);
        }
        return systemURL;
    }
}
