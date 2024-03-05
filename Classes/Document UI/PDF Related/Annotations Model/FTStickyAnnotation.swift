//
//  FTStickyAnnotation.swift
//  Noteshelf
//
//  Created by Amar on 24/07/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTRenderKit
import FTDocumentFramework

class FTStickyAnnotation: FTImageAnnotation {
    @objc var emojiName : String?;
    fileprivate var _imageToRenderTexture : MTLTexture?;
    
    override func textureToRender(scale : CGFloat) -> MTLTexture? {
        objc_sync_enter(self);
        self.currentScale = scale;
        if(nil == _imageToRenderTexture) {
            if let image = self.image {
                _imageToRenderTexture = FTMetalUtils.texture(from: image);
            }
        }
        objc_sync_exit(self);
        return _imageToRenderTexture;
    }
    
    @objc override var annotationType : FTAnnotationType {
        return .sticky;
    }

    override init() {
        super.init();
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        self.init();
        if let uniquesID = aDecoder.decodeObject(forKey: "uuid") as? String {
            self.uuid = uniquesID;
        }
        
        self.isReadonly = aDecoder.decodeBool(forKey: "isReadonly");
        self.version = aDecoder.decodeInteger(forKey: "version");

        #if !targetEnvironment(macCatalyst)
        self.boundingRect = aDecoder.decodeCGRect(forKey: "boundingRect");
        #else
        if let boundRect = aDecoder.decodeObject(forKey: "boundingRect") as? NSValue {
            self.boundingRect = boundRect.cgRectValue;
        }
        #endif
        self.screenScale = CGFloat(aDecoder.decodeFloat(forKey: "screenScale"));
        if let img = aDecoder.decodeObject(forKey: "image") as? UIImage {
            self.image = img
        }
        self.emojiName = aDecoder.decodeObject(forKey: "emojiName") as? String;
    }
    
    override func encode(with aCoder: NSCoder) {
        aCoder.encode(self.uuid, forKey: "uuid");
        aCoder.encode(self.isReadonly, forKey: "isReadonly");
        aCoder.encode(self.version, forKey: "version");
        #if !targetEnvironment(macCatalyst)
        aCoder.encode(self.boundingRect, forKey: "boundingRect");
        #else
        aCoder.encode(NSValue(cgRect: self.boundingRect), forKey: "boundingRect");
        #endif
        aCoder.encode(Float(self.screenScale), forKey: "screenScale");
        aCoder.encode(emojiName, forKey: "emojiName");
        if(self.copyMode) {
            aCoder.encode(self.image, forKey: "image");
        }
    }
    
    override var allowsResize: Bool {
        return false;
    }
    
    override var allowsEditing: Bool {
        return false;
    }

    override var allowsLocking: Bool {
        return false
    }
    
    override func canSelectUnderLassoSelection() -> Bool {
        return true
    }

    deinit {
        _imageToRenderTexture = nil;
    }
    
    @objc override class func defaultAnnotationVersion() -> Int
    {
        return 4;
    }
    
    @objc override var renderingRect: CGRect {
        return self.boundingRect;
    }
    
    override var transformMatrix: CGAffineTransform {
        get {
            return CGAffineTransform.identity;
        }
        set {
            super.transformMatrix = newValue;
        }
    }
    
    @objc override func isPointInside(_ point: CGPoint) -> Bool {
        return self.boundingRect.contains(point);
    }
    
    override func imageContentFileName() -> String
    {
        if let emojiName = self.emojiName {
            return emojiName.appending(".png");
        }
        else {
            return "";
        }
    }
    
    override var shouldAlertForMigration : Bool {
        return false;
    }
}

//MARK:- FTDeleting
extension FTStickyAnnotation
{
    override func willDelete() {
        
    }
}

//MARK:- FTCopying
extension FTStickyAnnotation
{
    override func deepCopyAnnotation(_ toPage: FTPageProtocol, onCompletion: @escaping (FTAnnotation?) -> Void) {
        let annotation = FTStickyAnnotation.init(withPage : toPage)
        annotation.boundingRect = self.boundingRect;
        annotation.isReadonly = self.isReadonly;
        annotation.version = self.version;

        annotation.imageTransformMatrix = self.imageTransformMatrix;
        annotation.screenScale = self.screenScale;
        annotation.emojiName = self.emojiName;
        
        if let sourceFileItem = self.imageContentFileItem(),
           let document = toPage.parentDocument as? FTNoteshelfDocument,
           let sourceDocument = self.associatedPage?.parentDocument as? FTNoteshelfDocument,
           let sourceResourceFolder = sourceDocument.resourceFolderItem(),
           let resourceFolder = document.resourceFolderItem() {

            let sourceFileItemURL = sourceResourceFolder.fileItemURL.appending(path: self.imageContentFileName(), directoryHint: .notDirectory)

            guard let copiedFileItem = FTFileItemImageTemporary(fileName: annotation.imageContentFileName(), sourceURL: sourceFileItemURL) else {
                onCompletion(nil)
                return
            }
            copiedFileItem.securityDelegate = document;
            resourceFolder.addChildItem(copiedFileItem);

            copiedFileItem.setImage(sourceFileItem.image());

            onCompletion(annotation)
        } else {
            onCompletion(nil)
        }
    }
}

//MARK:- FTTransformScale
extension FTStickyAnnotation
{
    override func apply(_ scale: CGFloat) {
        if(scale == 1) {
            return;
        }
        var boundingRect = self.boundingRect;
        boundingRect.size = CGSizeScale(boundingRect.size, scale);
        self.boundingRect = boundingRect;
    }
}

extension FTStickyAnnotation
{
    override func render(in context: CGContext!, scale: CGFloat) {
        if(!self.hidden) {
            if let localImage = self.image {
                context.saveGState();
                
                var scaledBounds = CGRectScale(self.boundingRect,scale).integral;
                context.translateBy(x: scaledBounds.origin.x, y: scaledBounds.origin.y);
                scaledBounds.origin = CGPoint.zero;
                
                context.translateBy(x: scaledBounds.midX, y: scaledBounds.midY);
                context.scaleBy(x: scale, y: scale);
 
                let imageSize = self.renderingRect.size;
                context.translateBy(x: -imageSize.width*0.5, y:  -imageSize.height*0.5);
                context.translateBy(x: 0, y: imageSize.height);
                context.scaleBy(x: 1.0, y: -1.0);
                
                // Draw view into context
                let imageRect = CGRect.init(origin: CGPoint.zero, size: imageSize);
                context.draw(localImage.cgImage!, in: imageRect);
                context.restoreGState();
            }
        }
    }
}

extension FTStickyAnnotation {
   override public class var supportsSecureCoding: Bool {
        return true;
    }
}

extension FTStickyAnnotation : FTAnnotationErase
{
    func canErase(eraseRect rects: [CGRect]) -> Bool {
        let boundingRect = self.renderingRect;
        let midPoint = CGPoint.init(x: boundingRect.midX, y: boundingRect.midY);
        var contains = false
        for rectIn1x in rects where rectIn1x.contains(midPoint) {
            contains = true
            break
        }
        return contains;
    }
    
    func supportsPartialErase() -> Bool {
        return false;
    }
}

