//
//  FTTaggedEntity.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 11/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTTaggedEntity: NSObject, Identifiable {
    var id = UUID().uuidString;

    var documentUUID: String;
    var documentName: String?

    private var notificationObserver: NSObjectProtocol?
    var tagType: FTTagsType {
        fatalError("subclass should override")
    };
    var tags = Set<FTTag>();

    init(documentUUID: String,documentName: String?) {
        self.documentUUID = documentUUID
        self.documentName = documentName
        super.init()
        if let notificationname = self.tagUpdateNotification {
            self.notificationObserver = NotificationCenter.default.addObserver(forName: notificationname, object: nil, queue: .main) { [weak self] notification in

                guard let stringSelf = self,
                      let inObject = notification.object as? FTTaggedEntity
                        ,stringSelf.id != inObject.id else {
                    return;
                }
                let unionTag = stringSelf.tags.union(inObject.tags);
                stringSelf.tags = unionTag;
                inObject.tags = unionTag;
            }
        }
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

    var tagUpdateNotification: Notification.Name? {
        return nil;
    }
    
    deinit {
        if let observer = self.notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func addTag(_ tag: FTTag) {
        if !self.tags.contains(tag) {
            self.tags.insert(tag)
            if let tagUpdateNotification = self.tagUpdateNotification {
                NotificationCenter.default.post(name: tagUpdateNotification, object: self);
            }
        }
    }
    
    func removeTag(_ tag: FTTag) {
        if nil != self.tags.remove(tag) {
            if let tagUpdateNotification = self.tagUpdateNotification {
                NotificationCenter.default.post(name: tagUpdateNotification, object: self);
            }
        }
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
