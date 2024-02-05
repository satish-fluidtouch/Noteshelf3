//
//  FTCachedDocument.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 12/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTCachedDocument: NSObject {
    private lazy var propertyPlist: FTFileItemPlist = {
        let url = self.fileURL.appending(path: METADATA_FOLDER_NAME).appending(path: PROPERTIES_PLIST);
        return FTFileItemPlist(url: url, isDirectory: false)
    }()
    
    private lazy var documentPlist: FTNSDocumentInfoPlistItem = {
        let url = self.fileURL.appending(path: DOCUMENT_INFO_FILE_NAME);
        return FTNSDocumentInfoPlistItem(url: url, isDirectory: false)
    }();
    
    private(set)  var documentID: String
    private(set) var fileURL: URL;
    
    required init(documentID: String) {
        self.documentID = documentID;
        self.fileURL = FTDocumentCache.shared.cachedLocation(for: documentID);
    }
    
    var pages: [FTNoteshelfPage] {
        return self.documentPlist.pages as! [FTNoteshelfPage];
    }
    
    var docuemntTags: [String] {
        let tags = self.propertyPlist.contentDictionary["tags"] as? [String]
        return tags ?? [String]();
    }
    
    var relativePath: String? {
        if let relativePath = self.propertyPlist.contentDictionary["relativePath"] as? String {
            return relativePath;
        }
        return nil
    }

    var documentName: String {
        if let relativePath = self.relativePath {
            return relativePath.deletingPathExtension.lastPathComponent;
        }
        else {
            return "Missing";
        }
    }
}
