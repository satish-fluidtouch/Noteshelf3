//
//  FTPageTaggedEntity.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 11/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTTaggedPageProperties: NSObject {
    var pageIndex: Int = 0 {
        didSet{
            debugLog("enter");
        }
    };
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
                  , documentPath: String?
                  , pageUUID: String
                  , pageProperties: FTTaggedPageProperties = FTTaggedPageProperties()) {
        self.pageUUID = pageUUID
        self.pageProperties = pageProperties
        super.init(documentUUID: documentUUID,documentPath: documentPath);
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
