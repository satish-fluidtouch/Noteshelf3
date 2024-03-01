//
//  FTClipAnnotation.swift
//  Noteshelf
//
//  Created by Mahesh on 03/10/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTWebClipAnnotation: FTImageAnnotation {
    var clipString: String = ""

    @objc override var annotationType : FTAnnotationType {
        return .webclip;
    }

    override init() {
        super.init();
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
    }

    override class var supportsSecureCoding: Bool {
        return super.supportsSecureCoding
    }

    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder);
    }
}

//MARK:- FTCopying
extension FTWebClipAnnotation
{
    override func deepCopyAnnotation(_ toPage: FTPageProtocol, onCompletion: @escaping (FTAnnotation?) -> Void) {
        let annotation = FTWebClipAnnotation.init(withPage : toPage)
        annotation.boundingRect = self.boundingRect;
        annotation.isReadonly = self.isReadonly;
        annotation.version = self.version;

        annotation.imageTransformMatrix = self.imageTransformMatrix;
        annotation.screenScale = self.screenScale;
        
        guard let document = toPage.parentDocument as? FTNoteshelfDocument,
              let sourceFileItem = self.imageContentFileItem(),
              let sourceResourceFolder = (self.associatedPage?.parentDocument as? FTNoteshelfDocument)?.resourceFolderItem(),
              let resourceFolder = document.resourceFolderItem()
        else {
            onCompletion(nil)
            return
        }

        let sourceFileItemURL = sourceResourceFolder.fileItemURL.appending(path: self.imageContentFileName(), directoryHint: .notDirectory)

        let destinationFileItemURL = resourceFolder.fileItemURL.appending(path: annotation.imageContentFileName(), directoryHint: .notDirectory)

        guard let copiedFileItem = FTFileItemImageTemporary(url: destinationFileItemURL, sourceURL: sourceFileItemURL) else {
            onCompletion(nil)
            return
        }
        copiedFileItem.securityDelegate = document;
        resourceFolder.addChildItem(copiedFileItem);

        copiedFileItem.setImage(sourceFileItem.image())

        onCompletion(annotation);
    }
}



