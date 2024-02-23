//
//  FTImageAnnotation.swift
//  Noteshelf
//
//  Created by Amar on 24/07/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTRenderKit
import FTDocumentFramework

class FTImageAnnotation: FTAnnotation,FTImageRenderingProtocol {
    
    override weak var associatedPage: FTPageProtocol? {
        didSet {
            if self.isReadonly == true
                && self.version <= 1 {
                self.associatedPage?.parentDocument?.hasNS1Content = true
            }
        }
    }
    
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
    
    @objc var image : UIImage? {
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
    @objc var transformedImage : UIImage? {
        get {
            if(nil == _transformedImage) {
                _transformedImage = self.transformedContentFileItem()?.image();
            }
            return _transformedImage;
        }
        set {
            if(newValue == nil && self.version >= FTImageAnnotation.v2ImageEditVersion()) {
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

    @objc var transformMatrix = CGAffineTransform.identity;
    
    var _imageTransformMatrix = CGAffineTransform.identity;
    @objc var imageTransformMatrix : CGAffineTransform {
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

    override func setRotation(_ angle: CGFloat, refPoint: CGPoint) {
        if angle != 0 {
            let rotation = CGAffineTransform(rotationAngle: angle)
            let transform = CGAffineTransform(translationX: refPoint.x, y: refPoint.y)
                .rotated(by: angle)
                .translatedBy(x: -refPoint.x, y: -refPoint.y)

            let center = CGPoint(x: self.boundingRect.midX, y: self.boundingRect.midY)
            let newCenter = center.applying(transform)
            let newOriginX = newCenter.x - boundingRect.width/2
            let newOriginY = newCenter.y - boundingRect.height/2
            self.boundingRect.origin = CGPoint(x: newOriginX, y: newOriginY)
            let finalTransform = self.imageTransformMatrix.concatenating(rotation)
            self.imageTransformMatrix = finalTransform
        }
    }

    @objc var screenScale : CGFloat = UIScreen.main.scale;
    
    @objc override var allowsEditing: Bool {
        return true;
    }
    
   @objc  override var allowsResize: Bool {
        return true;
    }

    override var allowsLocking: Bool {
        return true
    }

    @objc override var annotationType : FTAnnotationType {
        return .image;
    }
    
    override func canSelectUnderLassoSelection() -> Bool {
        return FTRackPreferenceState.allowAnnotations().contains(annotationType)
    }
    
    fileprivate var _imageToRenderTexture : MTLTexture?;
        
    func textureToRender(scale : CGFloat) -> MTLTexture? {
        objc_sync_enter(self);
        self.currentScale = scale;
        if(nil == _imageToRenderTexture || self.forceRender) {
            self.forceRender = false;
            if let image = self.imageToCreateTexture(scale:scale) {
                _imageToRenderTexture = FTMetalUtils.texture(from: image);
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
        #if !targetEnvironment(macCatalyst)
        self.boundingRect = aDecoder.decodeCGRect(forKey: "boundingRect");
        #else
        if let boundRect = aDecoder.decodeObject(forKey: "boundingRect") as? NSValue {
            self.boundingRect = boundRect.cgRectValue;
        }
        #endif

        if let img = aDecoder.decodeObject(forKey: "image") as? UIImage {
            image = img;
        }
        
        transformMatrix = aDecoder.decodeCGAffineTransform(forKey: "transformMatrix");
        imageTransformMatrix = aDecoder.decodeCGAffineTransform(forKey: "imageTransformMatrix");
        screenScale = CGFloat(aDecoder.decodeFloat(forKey: "screenScale"));
        if(screenScale == 0) {
            screenScale = UIScreen.main.scale;
        }
        if let img = aDecoder.decodeObject(forKey: "image") as? UIImage {
            self.image = img;
        }
        if let img = aDecoder.decodeObject(forKey: "transformedImage") as? UIImage {
            self.transformedImage = img;
        }
    }
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder);
        #if !targetEnvironment(macCatalyst)
        aCoder.encode(boundingRect, forKey: "boundingRect");
        #else
        aCoder.encode(NSValue(cgRect: self.boundingRect), forKey: "boundingRect");
        #endif
        if(self.copyMode) {
            aCoder.encode(self.image, forKey: "image");
            aCoder.encode(self.transformedImage, forKey: "transformedImage");
        }
        aCoder.encode(Float(screenScale), forKey: "screenScale");
        aCoder.encode(transformMatrix, forKey: "transformMatrix");
        aCoder.encode(imageTransformMatrix, forKey: "imageTransformMatrix");
    }

    override func resourceFileNames() -> [String]? {
        if(self.version >= FTImageAnnotation.v2ImageEditVersion()) {
            return [self.imageContentFileName()];
        }
        return [self.imageContentFileName(),self.transformedContentFileName()];
    }
    
    @objc override class func defaultAnnotationVersion() -> Int {
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
    
    @objc override var renderingRect: CGRect {
        if(self.version >= FTImageAnnotation.v2ImageEditVersion()) {
            let transform = self.imageTransformMatrix;
            var renderingRect = self.boundingRect.applying(transform)
            renderingRect.origin.x = self.boundingRect.midX - renderingRect.width*0.5;
            renderingRect.origin.y = self.boundingRect.midY - renderingRect.height*0.5;
            return renderingRect;
        }
        return super.renderingRect;
    }
    
    func imageContentFileName() -> String
    {
        return self.uuid.appending(".png");
    }
    
    @objc func isPointInside(_ point: CGPoint) -> Bool {
        return self._isPointInside(point);
    }
    
    override var shouldAlertForMigration : Bool {
        if(self.version < FTImageAnnotation.v2ImageEditVersion()) {
            return true;
        }
        return false;
    }
}

//MARK:- Memory Warning
extension FTImageAnnotation
{
    override func didRecieveMemoryWarning(_ notification: Notification) {
        self.unloadContents();
    }
}
//undo info
extension FTImageAnnotation
{
    override func undoInfo() -> FTUndoableInfo {
        let info = FTImageUndoableInfo.init(withAnnotation: self);
        info.image = _image
        info.imageTransform = imageTransformMatrix
        return info;
    }
    
    override func updateWithUndoInfo(_ info: FTUndoableInfo)
    {
        guard let imageInfo = info as? FTImageUndoableInfo else {
            fatalError("info should be of type FTImageAnnotation");
        }
        super.updateWithUndoInfo(imageInfo);
        self.image = imageInfo.image
        self.imageTransformMatrix = imageInfo.imageTransform
    }
}

private class FTImageUndoableInfo : FTUndoableInfo
{
    var image : UIImage?;
    var imageTransform : CGAffineTransform = CGAffineTransform.identity
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let imageInfo = object as? FTImageUndoableInfo else {
            return false;
        }
        if(
            super.isEqual(imageInfo)
                &&  imageInfo.imageTransform == self.imageTransform
                && imageInfo.image == self.image
            ) {
            return true;
        }
        return false;
    }
    
    override func canUndo(_ object : FTUndoableInfo) -> Bool {
        if(self.annotationversion != FTImageAnnotation.defaultAnnotationVersion()) {
            return false
        }
        return super.canUndo(object);
    }

}

//MARK:- Local
extension FTImageAnnotation
{
    func imageContentFileItem() -> FTFileItemImage?
    {
        if let document = self.associatedPage?.parentDocument as? FTNoteshelfDocument {
            let imageFileItem = document.resourceFolderItem()?.childFileItem(withName: self.imageContentFileName())
            return imageFileItem as? FTFileItemImage;
        }
        return nil;
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

    @objc class func v2ImageEditVersion() -> Int
    {
        return 5;
    }
}

//MARK:- FTAnnotationContainsProtocol
extension FTImageAnnotation : FTAnnotationContainsProtocol
{
    fileprivate func _isPointInside(_ point: CGPoint) -> Bool {
        let frame = self.boundingRect;
        let center = CGPoint.init(x: frame.midX, y: frame.midY);
        
        let translateTransform = CGAffineTransform.init(translationX: center.x, y: center.y);
        let rotationTransform = CGAffineTransform(rotationAngle: self.imageTransformMatrix.angle);

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
    
    func intersectsPath(_ inSelectionPath: CGPath, withScale scale: CGFloat, withOffset selectionOffset: CGPoint) -> Bool {
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

//MARK:- FTAnnotationDidAddToPageProtocol
extension FTImageAnnotation
{
    override func didMoveToPage() {
        if(nil == self.imageContentFileItem()) {
            self.image = _image;
            self.transformedImage = _transformedImage;
        }
    }
}

//MARK:- FTDeleting
extension FTImageAnnotation
{
    override func willDelete() {
        self.imageContentFileItem()?.deleteContent();
        self.transformedContentFileItem()?.deleteContent();
    }
}

//MARK:- FTCopying
extension FTImageAnnotation
{
    override func deepCopyAnnotation(_ toPage: FTPageProtocol, onCompletion: @escaping (FTAnnotation?) -> Void) {
        let imageAnnotation = FTImageAnnotation.init(withPage : toPage);
        imageAnnotation.boundingRect = self.boundingRect;
        imageAnnotation.version = self.version;
        imageAnnotation.isReadonly = self.isReadonly;
        
        imageAnnotation.imageTransformMatrix = self.imageTransformMatrix;
        imageAnnotation.transformMatrix = self.transformMatrix;
        imageAnnotation.screenScale = self.screenScale;
        
        if let sourceFileItem = self.imageContentFileItem() {
            let document = toPage.parentDocument as? FTNoteshelfDocument;
            let copiedFileItem = FTFileItemImage.init(fileName: imageAnnotation.imageContentFileName());
            copiedFileItem?.securityDelegate = document;
            document?.resourceFolderItem()?.addChildItem(copiedFileItem);
            
            var copiedTrasnformmedFileItem : FTFileItemImage?;
            var trasnformmedFileItemURL : URL?
            var copiedTrasnformmedFileItemURL : URL?
            let trasnformmedFileItem = self.transformedContentFileItem();
            if (nil != trasnformmedFileItem) {
                copiedTrasnformmedFileItem = FTFileItemImage.init(fileName: imageAnnotation.transformedContentFileName());
                copiedTrasnformmedFileItem?.securityDelegate = document;
                document?.resourceFolderItem()?.addChildItem(copiedTrasnformmedFileItem);
                
                trasnformmedFileItemURL = trasnformmedFileItem!.fileItemURL;
                copiedTrasnformmedFileItemURL = copiedTrasnformmedFileItem?.fileItemURL;
            }
            if let currentDocument =  self.associatedPage?.parentDocument as? FTNoteshelfDocument,let toDocument = document {
                if(currentDocument.isSecured() || toDocument.isSecured()) {
                    let image = sourceFileItem.image();
                    copiedFileItem?.setImage(image);
                    
                    FTCLSLog("NFC - Image deepcopy secured: \(toDocument.URL.title)");
                    let coordinator = NSFileCoordinator.init(filePresenter: toDocument);
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
                                if let fileItemURL = copiedFileItem?.fileItemURL, fileItemURL.urlByDeleteingPrivate() != fileAccessIntent.url.urlByDeleteingPrivate() {
                                    let params = ["Annotation" : "Image",
                                                  "sourceURL" : fileItemURL.path,
                                                  "intentURL" : fileAccessIntent.url.path]
                                    FTLogError("Copy URL Mismatch: Image", attributes: params);
                                }
                                copiedTrasnformmedFileItem?.saveContentsOfFileItem();
                                copiedFileItem?.saveContentsOfFileItem();
                                DispatchQueue.main.async {
                                    onCompletion(imageAnnotation);
                                }
                            }
                    })
                }
                else {
                    FTCLSLog("NFC - Image deepcopy: \(toDocument.URL.title)");
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
                                                                 onCompletion: { (_, _) in
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
extension FTImageAnnotation
{
    override func apply(_ scale: CGFloat) {
        if(scale == 1) {
            return;
        }
        
        var boundingRect = self.boundingRect;
        boundingRect.size = CGSizeScale(boundingRect.size, scale);
        self.boundingRect = boundingRect;

        if(self.version < FTImageAnnotation.v2ImageEditVersion()) {
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
            let angle = tranform.angle;
            tranform = CGAffineTransform.init(rotationAngle: -angle);

            let currentScaleX = tranform.scaleX;
            let currentScaleY = tranform.scaleY;
            
            tranform.scaledBy(x: 1/currentScaleX, y: 1/currentScaleY);
            
            let transX = tranform.translationX;
            let transY = tranform.translationY;
            tranform.translatedBy(x: (transX*scale)-transX, y: (transY*scale)-transY);
            tranform.scaledBy(x: currentScaleX, y: currentScaleY);
            tranform.rotated(by: angle);
            
            self.imageTransformMatrix = tranform;
            let transformToApply = scaleTransform.concatenating(self.imageTransformMatrix);
            
            //get the thumb image.
            var clipRect = boundingRect.integral;
            clipRect.origin = CGPoint.zero;
            let img = self.image!.resizedImage(newSize: clipRect.size,
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
private extension FTImageAnnotation
{
    func imageToCreateTexture(scale : CGFloat) -> UIImage?
    {
        var localImage = self.image;
        autoreleasepool {
            if(self.version >= FTImageAnnotation.v2ImageEditVersion()) {
                if nil != self.image {
                    if(!self.imageTransformMatrix.isIdentity) {
                        var annotationRenderRect = CGRectScale(self.renderingRect, self.screenScale*scale);
                        let textureSize = CGSize.aspectFittedSize(annotationRenderRect.size, max: CGSize.init(width: Int(maxTextureSize), height: Int(maxTextureSize)));
                        let textureScale =  textureSize.height / annotationRenderRect.height;
                        annotationRenderRect.size = textureSize;
                        
                        let boundRect = CGRectScale(self.boundingRect, self.screenScale*scale);
                        annotationRenderRect.origin = CGPoint.zero;
                        
                        var transform = CGAffineTransform.init(scaleX: boundRect.size.width/self.image!.size.width, y: boundRect.size.height/self.image!.size.height);
                        transform = transform.concatenating(CGAffineTransform.init(scaleX: textureScale, y: textureScale))
                        transform = transform.concatenating(self.imageTransformMatrix);
                        localImage = self.image?.resizedImage(newSize: annotationRenderRect.size,
                                                              transform: transform,
                                                              clippingRect: annotationRenderRect,
                                                              screenScale: 1,
                                                              includeBorder: false);
                    }
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

extension FTImageAnnotation : FTCGContextRendering
{
    func render(in context: CGContext!, scale: CGFloat) {
        if(self.version >= FTImageAnnotation.v2ImageEditVersion()) {
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

extension FTImageAnnotation : NSSecureCoding {
    public class var supportsSecureCoding: Bool {
        return true;
    }
}
