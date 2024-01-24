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
        annotation.boundingRect = self.boundingRect;
        annotation.isReadonly = self.isReadonly;
        annotation.version = self.version;

        annotation.imageTransformMatrix = self.imageTransformMatrix;
        annotation.screenScale = self.screenScale;
        
        let document = toPage.parentDocument as? FTNoteshelfDocument
        var copiedFileItem = annotation.imageContentFileItem();
        if(nil == copiedFileItem) {
            if let sourceFileItem = self.imageContentFileItem() {
                copiedFileItem = FTFileItemImage.init(fileName: annotation.imageContentFileName(),document: document);
                copiedFileItem?.securityDelegate = document;
                document?.resourceFolderItem()?.addChildItem(copiedFileItem);

                if let currentDocument =  self.associatedPage?.parentDocument as? FTNoteshelfDocument,let toDocument = document  {
                    if(currentDocument.isSecured() || toDocument.isSecured()) {
                        let image = sourceFileItem.image();
                        copiedFileItem?.setImage(image);
                        
                        let coordinator = NSFileCoordinator.init(filePresenter: document);
                        let fileAccessIntent = NSFileAccessIntent.writingIntent(with: copiedFileItem!.fileItemURL,
                                                                                options: NSFileCoordinator.WritingOptions.forReplacing);
                        let operationQueue = OperationQueue.init();
                        coordinator.coordinate(with: [fileAccessIntent],
                                               queue: operationQueue,
                                               byAccessor:
                            { (error) in
                                if(nil != error) {
                                    onCompletion(nil);
                                }
                                else {
                                    if let fileItemURL = copiedFileItem?.fileItemURL, fileItemURL.urlByDeleteingPrivate() != fileAccessIntent.url.urlByDeleteingPrivate() {
                                        let params = ["Annotation" : "Sticky",
                                                      "sourceURL" : fileItemURL.path,
                                                      "intentURL" : fileAccessIntent.url.path]
                                        FTLogError("Copy URL Mismatch: Sticky",attributes: params);
                                    }
                                    copiedFileItem?.saveContentsOfFileItem();
                                    DispatchQueue.main.async {
                                        onCompletion(annotation);
                                    }
                                }
                        })
                    }
                    else {
                        FileManager.coordinatedCopyAtURL(sourceFileItem.fileItemURL,
                                                         toURL: copiedFileItem!.fileItemURL)
                        { (success, error) in
                            if(nil == error) {
                                onCompletion(annotation);
                            }
                            else {
                                onCompletion(nil);
                            }
                        }
                    }
                }
                else {
                    onCompletion(nil);
                }
            }
            else {
                onCompletion(nil);
            }
        }
        else {
            onCompletion(annotation);
        }
    }
}


