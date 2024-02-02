//
//  FTTaggedEntity.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 11/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

enum FTTagsType {
    case page, book
}

class FTTaggedEntity: NSObject, Identifiable {
    
    static func taggedEntity(_ documentID: String
                             , documentName: String?
                             , pageID: String? = nil) -> FTTaggedEntity {
        let item: FTTaggedEntity
        if let _pageID = pageID {
            item = FTPageTaggedEntity(documentUUID: documentID
                                      , documentName: documentName
                                      , pageUUID: _pageID);
        }
        else {
            item = FTDocumentTaggedEntity(documentUUID: documentID, documentName: documentName);
        }
        return item;
    }

    var id = UUID().uuidString;

    private(set) var documentUUID: String
    var documentName: String
    var relativePath: String?

    var tagType: FTTagsType {
        fatalError("subclass should override")
    };
    private(set) var tags = Set<FTTag>();

    init(documentUUID: String,documentName: String?) {
        self.documentUUID = documentUUID;
        self.documentName = documentName ?? "";
        super.init()
    }
    
    func thumbnail(onCompletion: ((UIImage?,String)->())?) -> String {
        fatalError("Subclass should override")
    }
    
    var thumbnailURL: URL {
        let thumbnailFolderPath = URL.thumbnailFolderURL();
        let documentPath = thumbnailFolderPath.appendingPathComponent(self.documentUUID);
        var isDir = ObjCBool.init(false);
        if(!FileManager.default.fileExists(atPath: documentPath.path(percentEncoded: false)
                                           , isDirectory: &isDir) || !isDir.boolValue) {
            _ = try? FileManager.default.createDirectory(at: documentPath, withIntermediateDirectories: true, attributes: nil);
        }
        return documentPath;
    }
    
    override var hash: Int {
        return self.documentUUID.hashKey.hash;
    }

    func addTag(_ tag: FTTag) {
        if !self.tags.contains(tag) {
            self.tags.insert(tag)
        }
    }
    
    func removeTag(_ tag: FTTag) {
        self.tags.remove(tag)
    }
    
    override func isEqual(_ object: Any?) -> Bool
    {
        guard let other = object as? FTTaggedEntity else {
            return false;
        }
        return self.hash == other.hash
    }
    
    override var description: String {
        return "Tag - \(self.tags.map{$0.tagName})";
    }
}
