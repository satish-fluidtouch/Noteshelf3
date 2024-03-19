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
    
    private var image: UIImage?
    private var lastModifiedTime: TimeInterval = 0;
    
    override var tagType: FTTagsType {
        .page
    };

    var pageUUID: String;
    private(set) var pageProperties: FTTaggedPageProperties
    
    required init(documentUUID: String
                  , documentItem: FTShelfItemProtocol
                  , pageUUID: String
                  , pageProperties: FTTaggedPageProperties = FTTaggedPageProperties()) {
        self.pageUUID = pageUUID
        self.pageProperties = pageProperties
        super.init(documentUUID: documentUUID, documentItem: documentItem)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didRecieveMemoryWarning(_:)), name: UIApplication.didReceiveMemoryWarningNotification, object: nil);
    }
        
    @objc private func didRecieveMemoryWarning(_ notification: Notification) {
        self.image = nil;
        self.lastModifiedTime = 0;
    }
    
    func updatePageProties(_ pageProperties: FTTaggedPageProperties) {
        if !self.pageProperties.isSame(pageProperties) {
            self.pageProperties = pageProperties;
        }
    }
    
    override var hash: Int {
        return self.documentUUID.appending(self.pageUUID).hashKey.hash;
    }
    
    override var description: String {
        return super.description+">>"+self.documentUUID+"_"+self.pageUUID;
    }
    
    override func thumbnail(onCompletion: ((UIImage?,String?) -> ())?) -> String {
        if(nil != self.image) {
            onCompletion?(self.image,nil);
        }
        let token = UUID().uuidString;
        let thumbnailPath = self.thumbnailURL.appending(path: self.pageUUID);
        var currentTime = Date.timeIntervalSinceReferenceDate;
        if FileManager().fileExists(atPath: thumbnailPath.path(percentEncoded: false)) {
            currentTime  = thumbnailPath.fileModificationDate.timeIntervalSinceReferenceDate;
            if currentTime > lastModifiedTime || nil == self.image {
                DispatchQueue.global().async {
                    let img = UIImage(contentsOfFile: thumbnailPath.path(percentEncoded: false));
                    DispatchQueue.main.async {
                        self.image = img;
                        self.lastModifiedTime = currentTime;
                        onCompletion?(img, token)
                    }
                }
            }
        }

        return token;
    }
}
