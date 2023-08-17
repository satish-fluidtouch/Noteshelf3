//
//  FTImageAnnotationV2.swift
//  Noteshelf
//
//  Created by Amar on 24/07/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import NSMetalRender

class FTImageAnnotationV2: FTAnnotationV2,FTImageRenderingProtocol {
    
    fileprivate var _image : UIImage?;
    
    override var boundingRect: CGRect {
        willSet {
            if(self.boundingRect != newValue) {
                self.forceRender = true;
            }
        }
        didSet {
            if(self.boundingRect.origin.x.isInfinite || self.boundingRect.origin.x.isNaN) {
                self.boundingRect.origin.x = 0;
            }
            if(self.boundingRect.origin.y.isInfinite || self.boundingRect.origin.y.isNaN) {
                self.boundingRect.origin.y = 0;
            }
        }
    }
    
    var image : UIImage? {
        get {
            if(nil == _image) {
                _image = self.imageContentFileItem()?.image();
            }
            return _image;
        }
        set {
            _image = newValue;
            var fileItem = self.imageContentFileItem();
            if(nil == fileItem) {
                if let page = self.associatedPage,let document = page.parentDocument as? FTNoteshelfDocument {
                    fileItem = FTFileItemImage.init(fileName: self.imageContentFileName());
                    fileItem?.securityDelegate = document
                    document.resourceFolderItem()?.addChildItem(fileItem);
                }
            }
            fileItem?.setImage(newValue);
            self.forceRender = true;
        }
    };

    fileprivate var _transformedImage : UIImage?;
    var transformedImage : UIImage? {
        get {
            if(nil == _transformedImage) {
                _transformedImage = self.transformedContentFileItem()?.image();
            }
            return _transformedImage;
        }
        set {
            if(newValue == nil && self.version >= FTImageAnnotationV2.v2ImageEditVersion()) {
                _transformedImage = newValue;
                self.transformedContentFileItem()?.deleteContent();
                return;
            }
            
            if let txImage = newValue,let cgImage = txImage.cgImage {
                _transformedImage = UIImage.init(cgImage: cgImage, scale: 1, orientation: txImage.imageOrientation);
            }
            else {
                _transformedImage = newValue;
            }
            
            var fileItem = self.transformedContentFileItem();
            if(nil == fileItem) {
                if let page = self.associatedPage,let document = page.parentDocument as? FTNoteshelfDocument {
                    fileItem = FTFileItemImage.init(fileName: self.imageContentFileName());
                    fileItem?.securityDelegate = document
                    document.resourceFolderItem()?.addChildItem(fileItem);
                }
            }
            fileItem?.setImage(newValue);
            self.forceRender = true;
        }
    };

    var transformMatrix = CGAffineTransform.identity;
    
    var _imageTransformMatrix = CGAffineTransform.identity;
    var imageTransformMatrix : CGAffineTransform {
        get {
            return _imageTransformMatrix
        }
        set {
            if(newValue != _imageTransformMatrix) {
                _imageTransformMatrix = newValue;
                self.forceRender = true;
            }
        }
    };
    
    override func setOffset(_ offset: CGPoint) {
        if(offset != CGPoint.zero) {
            var boundRect = self.boundingRect;
            boundRect.origin = CGPointTranslate(boundRect.origin, offset.x, offset.y);
            self.boundingRect = boundRect;
        }
    }

    var screenScale : CGFloat = UIScreen.main.scale;
    
    override var allowsEditing: Bool {
        return true;
    }
    
    override var allowsResize: Bool {
        return true;
    }
    
    override var annotationType : FTAnnotationType {
        return .image;
    }
    
    fileprivate var _imageToRenderTexture : MTLTexture?;
    
    func textureToRender(scale : CGFloat) -> MTLTexture? {
        objc_sync_enter(self);
        self.currentScale = scale;
        if(nil == _imageToRenderTexture || self.forceRender) {
            self.forceRender = false;
            if let metalDevice = mtlDevice, let image = self.imageToCreateTexture() {
                _imageToRenderTexture = FTMetalUtils.texture(from: image, device: metalDevice);
            }
        }
        objc_sync_exit(self);
        return _imageToRenderTexture;
    }

    deinit {
        _imageToRenderTexture = nil;
        _image = nil;
    }
    
    override init() {
        super.init();
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        boundingRect = aDecoder.decodeCGRect(forKey: "boundingRect");
        
        if let img = aDecoder.decodeObject(forKey: "image") as? UIImage {
            image = img;
        }
        
        transformMatrix = aDecoder.decodeCGAffineTransform(forKey: "transformMatrix");
        imageTransformMatrix = aDecoder.decodeCGAffineTransform(forKey: "imageTransformMatrix");
        screenScale = CGFloat(aDecoder.decodeFloat(forKey: "screenScale"));
        if(screenScale == 0)
        {
            screenScale = UIScreen.main.scale;
        }
    }
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder);
        aCoder.encode(boundingRect, forKey: "boundingRect");
        if(self.copyMode) {
            aCoder.encode(self.image, forKey: "image");
            aCoder.encode(self.transformedImage, forKey: "transformedImage");
        }
        aCoder.encode(Float(screenScale), forKey: "screenScale");
        aCoder.encode(transformMatrix, forKey: "transformMatrix");
        aCoder.encode(imageTransformMatrix, forKey: "imageTransformMatrix");
    }

    override func resourceFileNames() -> [String]? {
        if(self.version >= FTImageAnnotationV2.v2ImageEditVersion()) {
            return [self.imageContentFileName()];
        }
        return [self.imageContentFileName(),self.transformedContentFileName()];
    }
    
    override class func defaultAnnotationVersion() -> Int {
        //version 1: images from NS1
        //version 2-4: 1st version of NS2
        //version 5: new edit feature
        return 5;
    }
    
    override func unloadContents() {
        objc_sync_enter(self);
        _image = nil;
        _transformedImage = nil;
        self.imageContentFileItem()?.unloadContentsOfFileItem();
        self.transformedContentFileItem()?.unloadContentsOfFileItem();
        _imageToRenderTexture = nil;
        objc_sync_exit(self);
    }
    
    override func loadContents() {
        
    }
    
    override var renderingRect: CGRect {
        if(self.version >= FTImageAnnotationV2.v2ImageEditVersion()) {
            let transform = self.imageTransformMatrix;
            var renderingRect = self.boundingRect.applying(transform)
            renderingRect.origin.x = self.boundingRect.midX - renderingRect.width*0.5;
            renderingRect.origin.y = self.boundingRect.midY - renderingRect.height*0.5;
            return renderingRect;
        }
        return super.renderingRect;
    }
}

//MARK:- Memory Warning
extension FTImageAnnotationV2
{
    override func didRecieveMemoryWarning(_ notification: Notification) {
        self.unloadContents();
    }
}
//MARK:- Local
extension FTImageAnnotationV2
{
    func imageContentFileItem() -> FTFileItemImage?
    {
        if let document = self.associatedPage?.parentDocument as? FTNoteshelfDocument {
            let imageFileItem = document.resourceFolderItem()?.childFileItem(withName: self.imageContentFileName())
            return imageFileItem as? FTFileItemImage;
        }
        return nil;
    }
    
    internal func imageContentFileName() -> String
    {
        return self.uuid.appending(".png");
    }
    
    fileprivate func transformedContentFileItem() -> FTFileItemImage?
    {
        if let document = self.associatedPage?.parentDocument as? FTNoteshelfDocument {
            let imageFileItem = document.resourceFolderItem()?.childFileItem(withName: self.transformedContentFileName())
            return imageFileItem as? FTFileItemImage;
        }
        return nil;
    }

    fileprivate func transformedContentFileName() -> String
    {
        return self.uuid.appending("_tx.png");
    }

    class func v2ImageEditVersion() -> Int
    {
        return 5;
    }
}

//MARK:- FTAnnotationContainsProtocol
extension FTImageAnnotationV2
{
    override func isPointInside(_ point: CGPoint) -> Bool {
        let frame = self.boundingRect;
        let center = CGPoint.init(x: frame.midX, y: frame.midY);
        
        let translateTransform = CGAffineTransform.init(translationX: center.x, y: center.y);
        let rotationTransform = self.imageTransformMatrix;

        let invertedTransform = translateTransform.inverted();
        let transform1 = invertedTransform.concatenating(rotationTransform);
        let customRotation = transform1.concatenating(translateTransform);
        
        var point1 = CGPoint.init(x: frame.minX, y: frame.minY);
        point1 = point1.applying(customRotation);
        
        var point2 = CGPoint.init(x: frame.minX, y: frame.maxY);
        point2 = point2.applying(customRotation);
        
        var point3 = CGPoint.init(x: frame.maxX, y: frame.maxY);
        point3 = point3.applying(customRotation);
        
        var point4 = CGPoint.init(x: frame.maxX, y: frame.minY);
        point4 = point4.applying(customRotation);
        
        let path = UIBezierPath();
        path.move(to: point1);
        path.addLine(to: point2);
        path.addLine(to: point3);
        path.addLine(to: point4);
        path.close();
        return path.contains(point);
    }
    
    override func intersectsPath(_ inSelectionPath: CGPath, withScale scale: CGFloat, withOffset selectionOffset: CGPoint) -> Bool {
        var result = false;

        var selectionPathBounds = inSelectionPath.boundingBox;
        selectionPathBounds.origin = CGPoint.init(x: selectionPathBounds.origin.x+selectionOffset.x,
                                                  y: selectionPathBounds.origin.y+selectionOffset.y);
        let boundingRect1 = CGRectScale(self.renderingRect, scale);
        if(boundingRect1.intersects(selectionPathBounds)) {
            let intersectionRect = boundingRect1.intersection(selectionPathBounds).integral;
            let width = Int(intersectionRect.width);
            let height = Int(intersectionRect.height);

            let bits = UnsafeMutablePointer<UInt8>.allocate(capacity: width*height);

            if let context = CGContext.init(data: bits,
                                         width: width,
                                         height: height,
                                         bitsPerComponent: MemoryLayout<UInt8>.stride * 8,
                                         bytesPerRow: width,
                                         space: CGColorSpaceCreateDeviceGray(),
                                         bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue) {
                let rect = CGRect(x: 0, y: 0, width: width, height: height)
                context.clear(rect)
                
                context.translateBy(x: 0, y: CGFloat(height));
                context.scaleBy(x: 1, y: -1);
                context.setShouldAntialias(false);
                
                //We want the portion of the image to be drawn in that intersection rect. So translate, such that portion gets drawn
                context.translateBy(x: -intersectionRect.origin.x, y: -intersectionRect.origin.y);
                context.saveGState();
                
                //Since our selection path is from lasso view which is in different coordinate system,this transaltion is necessary
                context.translateBy(x: selectionOffset.x, y: selectionOffset.y);
                context.addPath(inSelectionPath);
                context.restoreGState();
                context.clip();
                self.render(in: context, scale: scale);
                
                for x in 0..<width {
                    for y in 0..<height {
                        let val = UInt8(bits[y * width + x]);
                        if(val != 0) {
                            result = true;
                            break;
                        }
                    }
                    if(result) {
                        break;
                    }
                }
            }
            bits.deallocate();
        }
        return result;
    }
}

//MARK:- FTDeleting
extension FTImageAnnotationV2
{
    override func willDelete() {
        self.imageContentFileItem()?.deleteContent();
        self.transformedContentFileItem()?.deleteContent();
    }
}

//MARK:- FTCopying
extension FTImageAnnotationV2
{
    override func deepCopyAnnotation(_ toPage: FTPageProtocol, onCompletion: @escaping (FTAnnotationV2?) -> Void) {
        let imageAnnotation = FTImageAnnotationV2.init(withPage : toPage);
        imageAnnotation.boundingRect = self.boundingRect;
        imageAnnotation.version = self.version;
        imageAnnotation.isReadonly = self.isReadonly;
        
        imageAnnotation.imageTransformMatrix = self.imageTransformMatrix;
        imageAnnotation.transformMatrix = self.transformMatrix;
        imageAnnotation.screenScale = self.screenScale;
        
        if let sourceFileItem = self.imageContentFileItem() {
            let document = toPage.parentDocument as? FTDocumentFileItems;
            let copiedFileItem = FTFileItemImage.init(fileName: imageAnnotation.imageContentFileName());
            copiedFileItem?.securityDelegate = document as? FTFileItemSecurity;
            document?.resourceFolderItem()?.addChildItem(copiedFileItem);
            
            var copiedTrasnformmedFileItem : FTFileItemImage?;
            var trasnformmedFileItemURL : URL?
            var copiedTrasnformmedFileItemURL : URL?
            let trasnformmedFileItem = self.transformedContentFileItem();
            if (nil != trasnformmedFileItem) {
                copiedTrasnformmedFileItem = FTFileItemImage.init(fileName: imageAnnotation.transformedContentFileName());
                copiedTrasnformmedFileItem?.securityDelegate = document as? FTFileItemSecurity;
                document?.resourceFolderItem()?.addChildItem(copiedTrasnformmedFileItem);
                
                trasnformmedFileItemURL = trasnformmedFileItem!.fileItemURL;
                copiedTrasnformmedFileItemURL = copiedTrasnformmedFileItem?.fileItemURL;
            }
            if let currentDocument =  self.associatedPage?.parentDocument as? FTNoteshelfDocument,let toDocument = document as? FTNoteshelfDocument {
                if(currentDocument.isSecured() || toDocument.isSecured()) {
                    let image = sourceFileItem.image();
                    copiedFileItem?.setImage(image);
                    
                    let coordinator = NSFileCoordinator.init(filePresenter: document as? NSFilePresenter);
                    var fileAccessIntents = [NSFileAccessIntent]();
                    let fileAccessIntent = NSFileAccessIntent.writingIntent(with: copiedFileItem!.fileItemURL,
                                                                            options: NSFileCoordinator.WritingOptions.forReplacing);
                    fileAccessIntents.append(fileAccessIntent);
                    if(nil != trasnformmedFileItem) {
                        copiedTrasnformmedFileItem?.setImage(trasnformmedFileItem!.image());
                        let fileAccessIntent = NSFileAccessIntent.writingIntent(with: copiedTrasnformmedFileItem!.fileItemURL,
                                                                                options: NSFileCoordinator.WritingOptions.forReplacing);
                        fileAccessIntents.append(fileAccessIntent);
                    }
                    
                    let operationQueue = OperationQueue.init();
                    coordinator.coordinate(with: fileAccessIntents,
                                           queue: operationQueue,
                                           byAccessor:
                        { (error) in
                            if(nil != error) {
                                onCompletion(nil);
                            }
                            else {
                                copiedTrasnformmedFileItem?.saveContentsOfFileItem();
                                copiedFileItem?.saveContentsOfFileItem();
                                DispatchQueue.main.async {
                                    onCompletion(imageAnnotation);
                                }
                            }
                    })
                }
                else {
                    FileManager.coordinatedCopyAtURL(sourceFileItem.fileItemURL,
                                                     toURL: copiedFileItem!.fileItemURL)
                    { (success, error) in
                        if(nil != error) {
                            onCompletion(nil);
                        }
                        else {
                            if(nil != trasnformmedFileItemURL && nil != copiedTrasnformmedFileItemURL) {
                                FileManager.coordinatedCopyAtURL(trasnformmedFileItemURL!,
                                                                 toURL: copiedTrasnformmedFileItemURL!,
                                                                 onCompletion: { (success, error) in
                                                                    onCompletion(imageAnnotation);
                                });
                            }
                            else {
                                onCompletion(imageAnnotation);
                            }
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
}

//MARK:- FTTransformScale
extension FTImageAnnotationV2
{
    override func apply(_ scale: CGFloat) {
        if(scale == 1) {
            return;
        }
        
        var boundingRect = self.boundingRect;
        boundingRect.size = CGSizeScale(boundingRect.size, scale);
        self.boundingRect = boundingRect;

        if(self.version < FTImageAnnotationV2.v2ImageEditVersion()) {
            //modify the transform change due to change in scale.

            var  currentScaleTransform = CGAffineTransform.identity;
            var scaleTransform = self.transformMatrix;
            if(self.version == 1) {
                let imageSize = CGSizeScale(self.image!.size,1/self.screenScale);
                currentScaleTransform = CGAffineTransform.init(scaleX: boundingRect.size.width/imageSize.width,
                                                               y: boundingRect.size.height/imageSize.height);
                scaleTransform = currentScaleTransform;
            }
            else {
                currentScaleTransform = CGAffineTransform.init(scaleX: scale, y: scale);
                scaleTransform = currentScaleTransform.concatenating(self.transformMatrix);
            }
            
            //modify the image transform change due to change in scale.
            var tranform = self.imageTransformMatrix;
            let angle = CGAffineTransformGetRotation(tranform);
            tranform = CGAffineTransform.init(rotationAngle: -angle);

            let currentScaleX = CGAffineTransformGetScaleX(tranform);
            let currentScaleY = CGAffineTransformGetScaleY(tranform);
            
            tranform.scaledBy(x: 1/currentScaleX, y: 1/currentScaleY);
            
            let transX = CGAffineTransformGetTranslateX(tranform);
            let transY = CGAffineTransformGetTranslateY(tranform);
            tranform.translatedBy(x: (transX*scale)-transX, y: (transY*scale)-transY);
            tranform.scaledBy(x: currentScaleX, y: currentScaleY);
            tranform.rotated(by: angle);
            
            self.imageTransformMatrix = tranform;
            let transformToApply = scaleTransform.concatenating(self.imageTransformMatrix);
            
            //get the thumb image.
            var clipRect = boundingRect.integral;
            clipRect.origin = CGPoint.zero;
            let img = self.image!.resizedImage(clipRect.size,
                                                 transform: transformToApply,
                                                 clippingRect: clipRect,
                                                 screenScale: self.screenScale,
                                                 includeBorder: false);

            self.transformedImage = img;
            self.transformMatrix = scaleTransform;
        }
    }
}

//MARK:- Image Gen
extension FTImageAnnotationV2
{
    func imageToCreateTexture() -> UIImage?
    {
        var localImage = self.image;
        autoreleasepool {
            if(self.version >= FTImageAnnotationV2.v2ImageEditVersion()) {
                if nil != self.image {
                    var annotationRenderRect = CGRectScale(self.renderingRect, self.screenScale);
                    let textureSize = CGSize.aspectFittedSize(annotationRenderRect.size, max: CGSize.init(width: Int(maxTextureSize), height: Int(maxTextureSize)));
                    let textureScale =  textureSize.height / annotationRenderRect.height;
                    annotationRenderRect.size = textureSize;
                    
                    let boundRect = CGRectScale(self.boundingRect, self.screenScale);
                    annotationRenderRect.origin = CGPoint.zero;
                    
                    
                    var transform = CGAffineTransform.init(scaleX: boundRect.size.width/self.image!.size.width, y: boundRect.size.height/self.image!.size.height);
                    transform = transform.concatenating(CGAffineTransform.init(scaleX: textureScale, y: textureScale))
                    transform = transform.concatenating(self.imageTransformMatrix);
                    localImage = self.image?.resizedImage(annotationRenderRect.size,
                                                          transform: transform,
                                                          clippingRect: annotationRenderRect,
                                                          screenScale: 1,
                                                          includeBorder: false);
                }
            }
            else {
                localImage = self.transformedImage;
                if(nil == localImage) {
                    localImage = self.image;
                }
                if(nil != localImage) {
                    UIGraphicsBeginImageContextWithOptions((localImage!.size), false, UIScreen.main.scale);
                    localImage!.draw(in: CGRect.init(origin: CGPoint.zero, size: localImage!.size));
                    localImage = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                }
            }
            if(nil == localImage) {
                localImage = self.image;
            }
        }
        return localImage;
    }
}

extension FTImageAnnotationV2 : FTCGContextRendering
{
    func render(in context: CGContext!, scale: CGFloat) {
        if(self.version >= FTImageAnnotationV2.v2ImageEditVersion()) {
            self.renderV5(in: context, scale: scale);
        }
        else {
            self.renderV1to4(in: context, scale: scale);
        }
    }
    
    private func renderV1to4(in context: CGContext!, scale: CGFloat)
    {
        if(!self.hidden) {
            context.saveGState();
            var scaledBounds = CGRectScale(self.boundingRect, scale).integral;

            context.translateBy(x: scaledBounds.origin.x, y: scaledBounds.origin.y);
            scaledBounds.origin = CGPoint.zero;

            var localImage = self.transformedImage;
            var transformToApply = CGAffineTransform.identity;
            if(nil == localImage) {
                localImage = self.image;
                transformToApply = self.transformMatrix;
            }
            if let inImage = localImage, let cgImage = localImage?.cgImage {
                let dummy = CGAffineTransform.init(a: 0, b: 0, c: 0, d: 0, tx: 0, ty: 0);
                if(transformToApply != CGAffineTransform.identity && dummy != transformToApply) {
                    let imageSize = CGSizeScale(inImage.size,inImage.scale/self.screenScale);
                    
                    // Transform the image (as the image view has been transformed)
                    context.translateBy(x: scaledBounds.midX, y: scaledBounds.midY);
                    context.scaleBy(x: scale, y: scale)
                    
                    context.concatenate(transformToApply);
                    
                    context.translateBy(x: -imageSize.width*0.5, y: -imageSize.height*0.5);
                    context.translateBy(x: 0.0, y: imageSize.height);
                    context.scaleBy(x: 1, y: -1);
                    
                    // Draw view into context
                    let imageRect = CGRect.init(origin: CGPoint.zero, size: imageSize);
                    context.draw(cgImage, in: imageRect);
                }
                else {
                    context.translateBy(x: scaledBounds.minX, y: scaledBounds.maxY);
                    context.scaleBy(x: 1, y: -1);
                    // Draw view into context
                    context.draw(cgImage, in: CGRect.init(origin: CGPoint.zero, size: scaledBounds.size));
                    
                }
            }
            context.restoreGState();
        }
    }

    private func renderV5(in context: CGContext!, scale: CGFloat)
    {
        if(!self.hidden) {
            if let imageTorender = self.image?.cgImage {
                context.saveGState();
                var scaledBounds = CGRectScale(self.boundingRect, scale).integral;
                
                context.translateBy(x: scaledBounds.origin.x, y: scaledBounds.origin.y);
                scaledBounds.origin = CGPoint.zero;
                
                context.translateBy(x: scaledBounds.midX, y: scaledBounds.midY);
                context.concatenate(self.imageTransformMatrix);
                
                context.translateBy(x: -scaledBounds.midX, y: -scaledBounds.midY);
                
                context.translateBy(x: 0, y: scaledBounds.height);
                context.scaleBy(x: 1, y: -1);
                
                
                // Draw view into context
                context.draw(imageTorender, in: CGRect.init(origin: CGPoint.zero, size: scaledBounds.size));
                
                context.restoreGState();
            }
        }
    }
}
