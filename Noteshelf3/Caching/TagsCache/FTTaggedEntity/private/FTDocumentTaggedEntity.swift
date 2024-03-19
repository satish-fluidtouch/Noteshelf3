//
//  FTDocumentTaggedEntity.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 11/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTDocumentTaggedEntity: FTTaggedEntity {   
    private var image: UIImage?
    private var lastModifiedTime: TimeInterval = 0;

    override init(documentUUID: String, documentItem: FTShelfItemProtocol) {
        super.init(documentUUID: documentUUID, documentItem: documentItem);
        NotificationCenter.default.addObserver(self, selector: #selector(self.didRecieveMemoryWarning(_:)), name: UIApplication.didReceiveMemoryWarningNotification, object: nil);
    }
    
    @objc private func didRecieveMemoryWarning(_ notification: Notification) {
        self.image = nil;
        self.lastModifiedTime = 0;
    }

    override var tagType: FTTagsType {
        .book
    };
    
    override var description: String {
        return super.description+">>"+self.documentUUID
    }
    
    override func thumbnail(onCompletion: ((UIImage?,String?) -> ())?) -> String {
        if(nil != self.image) {
            onCompletion?(self.image,nil);
        }
        
        let thumbnailPath = FTDocumentCache.shared.cachedLocation(for: self.documentUUID).appending(path: "cover-shelf-image.png");
        var currentTime = Date.timeIntervalSinceReferenceDate;
        if FileManager().fileExists(atPath: thumbnailPath.path(percentEncoded: false)) {
            currentTime  = thumbnailPath.fileModificationDate.timeIntervalSinceReferenceDate;
            if currentTime > lastModifiedTime || nil == self.image {
                let img = UIImage(contentsOfFile: thumbnailPath.path(percentEncoded: false));
                self.image = img;
                self.lastModifiedTime = currentTime;
            }
        }
        onCompletion?(self.image,nil)
        return UUID().uuidString;
    }
}
