//
//  FTPageTaggedEntity.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 11/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTTaggedPageProperties: NSObject {
    var pageIndex: Int = 0;
    var pageSize: CGRect = CGRect.zero;
    
    func isSame(_ other: FTTaggedPageProperties) -> Bool {
        return (
            other.pageSize == self.pageSize
            && other.pageIndex == self.pageIndex
        );
    }
}

class FTPageTaggedEntity: FTTaggedEntity {
    override var tagType: FTTagsType {
        .page
    };

    var pageUUID: String;
    private(set) var pageProperties: FTTaggedPageProperties
    
    required init(documentUUID: String
                  , documentName: String?
                  , pageUUID: String
                  , pageProperties: FTTaggedPageProperties) {
        self.pageUUID = pageUUID
        self.pageProperties = pageProperties
        super.init(documentUUID: documentUUID,documentName: documentName);
        NotificationCenter.default.addObserver(self, selector: #selector(self.didUpdatePageProperties(_:)), name: Notification.Name("TagUpdatedPageProperties"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("TagUpdatedPageProperties"), object: nil);
    }
    
    func updatePageProties(_ pageProperties: FTTaggedPageProperties) {
        if !self.pageProperties.isSame(pageProperties) {
            self.pageProperties = pageProperties;
            NotificationCenter.default.post(name: Notification.Name("TagUpdatedPageProperties"), object: self);
        }
    }
    
    override var hash: Int {
        return self.documentUUID.appending(self.pageUUID).hashKey.hash;
    }
    
    override var description: String {
        return super.description+">>"+self.documentUUID+"_"+self.pageUUID;
    }
    
    override func thumbnail(onCompletion: ((UIImage?,String) -> ())?) -> String {
        let thumbnailPath = self.thumbnailURL.appending(path: self.pageUUID);
        let token = UUID().uuidString;
        DispatchQueue.global().async {
            let img = UIImage(contentsOfFile: thumbnailPath.path(percentEncoded: false));
            DispatchQueue.main.async {
                onCompletion?(img, token)
            }
        }
        return token;
    }
}

private extension FTPageTaggedEntity {
    @objc func didUpdatePageProperties(_ notifcation: Notification) {
        if let notObj = notifcation.object as? FTPageTaggedEntity
            ,notObj.id != self.id {
            self.pageProperties = notObj.pageProperties;
        }
    }
}
