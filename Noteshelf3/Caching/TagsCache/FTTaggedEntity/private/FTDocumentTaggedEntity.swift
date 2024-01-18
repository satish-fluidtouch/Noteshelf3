//
//  FTDocumentTaggedEntity.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 11/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTDocumentTaggedEntity: FTTaggedEntity {    
    override var tagType: FTTagsType {
        .book
    };
    
    override var description: String {
        return super.description+">>"+self.documentUUID
    }
    
    override func thumbnail(onCompletion: ((UIImage?,String) -> ())?) -> String {
        let thumbnailPath = FTDocumentCache.shared.cachedLocation(for: self.documentUUID).appending(path: "cover-shelf-image.png");
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
