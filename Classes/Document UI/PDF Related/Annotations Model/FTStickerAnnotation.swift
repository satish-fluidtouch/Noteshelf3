//
//  FTStickerAnnotation.swift
//  Noteshelf3
//
//  Created by Sameer on 06/04/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit
import FTRenderKit
import FTDocumentFramework

class FTStickerAnnotation: FTImageAnnotation {
    @objc override var annotationType : FTAnnotationType {
        return .sticker;
    }

    override init() {
        super.init();
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
    }
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder);
    }

    override var allowsEditing: Bool {
        return false;
    }

    override class var supportsSecureCoding: Bool {
        return true
    }
}

//MARK:- FTCopying
extension FTStickerAnnotation
{
    override func deepCopyAnnotation(_ toPage: FTPageProtocol, onCompletion: @escaping (FTAnnotation?) -> Void) {
        let annotation = FTStickerAnnotation.init(withPage : toPage)
        annotation.groupId = self.groupId
        annotation.boundingRect = self.boundingRect;
        annotation.isReadonly = self.isReadonly;
        annotation.version = self.version;

        annotation.imageTransformMatrix = self.imageTransformMatrix;
        annotation.screenScale = self.screenScale;

        if let sourceFileItem = self.imageContentFileItem(),
           let document = toPage.parentDocument as? FTNoteshelfDocument,
           let sourceDocument = self.associatedPage?.parentDocument as? FTNoteshelfDocument,
           let resourceFolder = document.resourceFolderItem() {
            
            var contentImage: UIImage?
            if(sourceDocument.isSecured() || document.isSecured()) {
                contentImage = sourceFileItem.image()
            }

            guard let copiedFileItem = FTFileItemImageTemporary(fileName: annotation.imageContentFileName(), sourceURL: sourceFileItem.fileItemURL, content: contentImage) else {
                onCompletion(nil)
                return
            }
            copiedFileItem.securityDelegate = document;
            resourceFolder.addChildItem(copiedFileItem);
            copiedFileItem.setImage(sourceFileItem.image())
            onCompletion(annotation)
        } else {
            onCompletion(nil)
        }
    }
}


