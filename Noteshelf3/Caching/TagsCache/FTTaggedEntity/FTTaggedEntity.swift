//
//  FTTaggedEntity.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 11/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTTaggedEntity: NSObject {
    var documentUUID: String;

    var documentName: String?
    private var objectID = UUID().uuidString
    private var notificationObserver: NSObjectProtocol?

    var tags = Set<FTTag>();

    init(documentUUID: String,documentName: String?) {
        self.documentUUID = documentUUID
        self.documentName = documentName
        super.init()
        if let notificationname = self.tagUpdateNotification {
            self.notificationObserver = NotificationCenter.default.addObserver(forName: notificationname, object: nil, queue: .main) { [weak self] notification in
                guard let stringSelf = self,
                      let inObject = notification.object as? FTPageTaggedEntity
                        ,stringSelf.objectID != inObject.objectID else {
                    return;
                }
                let unionTag = stringSelf.tags.union(inObject.tags);
                stringSelf.tags = unionTag;
                inObject.tags = unionTag;
            }
        }
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
        self.tags.insert(tag)
        if let tagUpdateNotification = self.tagUpdateNotification {
            NotificationCenter.default.post(name: tagUpdateNotification, object: self);
        }
    }
    
    func removeTag(_ tag: FTTag) {
        self.tags.remove(tag)
        if let tagUpdateNotification = self.tagUpdateNotification {
            NotificationCenter.default.post(name: tagUpdateNotification, object: self);
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
