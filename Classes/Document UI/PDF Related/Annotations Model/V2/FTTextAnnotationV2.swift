//
//  FTTextAnnotationV2.swift
//  Noteshelf
//
//  Created by Amar on 24/07/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import NSMetalRender

let maxTextureSize : Int = 4096;//max texture size allowed in metal is 16384;

extension NSAttributedString
{
    func attributedData() -> Data?
    {
        var data : Data? = nil ;
        do {
            data = try self.data(from: NSRange.init(location: 0, length: self.length),
                                 documentAttributes: [NSDocumentTypeDocumentAttribute : NSRTFDTextDocumentType]);
        }
        catch {
            
        }
        return data;
    }
}

extension Data
{
    func attributedString() -> NSAttributedString?
    {
        var attrString : NSAttributedString? = nil;
        do {
            attrString = try NSAttributedString.init(data: self,
                                                     options: [NSDocumentTypeDocumentAttribute : NSRTFDTextDocumentType],
                                                     documentAttributes: nil);
        }
        catch {
            
        }
        return attrString;
    }
}

class FTTextAnnotationV2: FTAnnotationV2,FTImageRenderingProtocol {

    var attributedString : NSAttributedString? {
        willSet {
            if let newAttrStr = newValue,
                let oldAttrStr = self.attributedString,
                !newAttrStr.isEqual(toAttributedText: oldAttrStr) {
                self.forceRender = true;
            }
            else if(nil == newValue && nil != self.attributedString) {
                self.forceRender = true;
            }
            else if(nil != newValue && nil == self.attributedString) {
                self.forceRender = true;
            }
        }
    };
    
    var dataValue : Data? {
        get {
            let attributedString = self.attributedString?.mutableCopy() as? NSMutableAttributedString
            if(nil != attributedString) {
                attributedString?.enumerateAttribute("NSOriginalFont",
                                                     in: NSRange.init(location: 0, length: attributedString!.length),
                                                     options: NSAttributedString.EnumerationOptions.init(rawValue: 0),
                                                     using:
                    { (fontAnyType, range, stop) in
                        if(nil != fontAnyType) {
                            attributedString?.addAttribute(NSFontAttributeName, value: fontAnyType!, range: range);
                        }
                })
            }
            return attributedString?.attributedData();
        }
        set {
            if let attrStr = newValue?.attributedString() {
                let mappedAttr = attrStr.mapAttributesToMatch(withLineHeight: -1);
                let mutAttrStr = NSMutableAttributedString.init(attributedString: mappedAttr!);
                mutAttrStr.applyScale(1, originalScaleToApply: CGFloat(self.transformScale));
                self.attributedString = mutAttrStr;
            }
        }
    }
    
    override var annotationType : FTAnnotationType {
        return .text;
    }

    var transformScale : Float = 1;
    
    fileprivate var _imageToRenderTexture : MTLTexture?;
    
    override var boundingRect: CGRect {
        willSet{
            if(newValue != self.boundingRect) {
                self.forceRender = true;
            }
        }
    }
    
    func textureToRender(scale : CGFloat) -> MTLTexture? {
        objc_sync_enter(self);
        if(nil == _imageToRenderTexture || self.forceRender || self.currentScale != scale) {
            self.forceRender = false;
            self.currentScale = scale;
            if let image = self.textToImage(scale: CGFloat(scale)) {
                _imageToRenderTexture = FTMetalUtils.texture(from: image, device: mtlDevice!);
            }
        }
        objc_sync_exit(self);
        return _imageToRenderTexture;
    }

    override init() {
        super.init();
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        self.transformScale = aDecoder.decodeFloat(forKey: "transformScale");
        let data = aDecoder.decodeObject(forKey: "text") as? Data;
        if(nil != data) {
            let attr = data!.attributedString();
            self.attributedString = attr?.mapAttributesToMatch(withLineHeight: -1);
        }
    }
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder);
        aCoder.encode(self.transformScale, forKey: "transformScale")
        aCoder.encode(self.attributedString?.attributedData(), forKey: "text");
    }
    
    func backgroundColor() -> UIColor? {
        var backgroundColor : UIColor? = UIColor.clear;
        if let attrStr = self.attributedString,attrStr.length > 0 {
            backgroundColor = attrStr.attribute(NSBackgroundColorAttributeName, at: 0, effectiveRange: nil) as? UIColor;
        }
        return backgroundColor;
    }
    
    override func unloadContents() {
        _imageToRenderTexture = nil;
    }
    
    override func setOffset(_ offset: CGPoint) {
        if(offset != CGPoint.zero) {
            var boundingRect = self.boundingRect;
            boundingRect.origin = CGPointTranslate(boundingRect.origin, offset.x, offset.y);
            self.boundingRect = boundingRect;
            self.associatedPage?.isDirty = true;
        }
    }
    
    override class func defaultAnnotationVersion() -> Int {
        //the text container inset
        //from version 0 - 4 :: left = 20, right = 20, top = 20, bottom = 44;
        //from 5 to now :: left = 10, right = 10, top = 10, bottom = 10;
        return Int(5);
    }

}

//MARK:- Private
extension FTTextAnnotationV2
{
    fileprivate func textToImage(scale : CGFloat) -> UIImage?
    {
        var image : UIImage? = nil;
        if let attrstr = self.attributedString {
            autoreleasepool {
                var scaledboundingRect = CGRectScale(self.boundingRect, scale);
                scaledboundingRect.origin = CGPoint.zero;
                
                let textureSize = CGSize.aspectFittedSize(scaledboundingRect.size, max: CGSize.init(width: Int(maxTextureSize), height: Int(maxTextureSize)));
                let texScale = textureSize.width/scaledboundingRect.width;
                
                let width = Int(textureSize.width);
                let height = Int(textureSize.height);
                
                let colorSpace = CGColorSpaceCreateDeviceRGB();
                let context = CGContext.init(data: nil,
                                             width: width,
                                             height: height,
                                             bitsPerComponent: 8,
                                             bytesPerRow: width * 4,
                                             space: colorSpace,
                                             bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue);
                var inset = FTTextView.textContainerInset(self.version);
                inset = UIEdgeInsetsScale(inset, CGFloat(self.transformScale));
                
                let layouter = FTTextLayouter.init(attributedString: attrstr,
                                                   constraints: CGSize.init(width: self.renderingRect.width - (inset.left + inset.right), height: CGFloat.greatestFiniteMagnitude));
                
                context?.translateBy(x: 0, y: CGFloat(height));
                context?.scaleBy(x: 1, y: -1);
                
                context?.scaleBy(x: texScale*scale, y: texScale*scale);
                if let backColor = self.backgroundColor() {
                    context?.setFillColor(backColor.cgColor);
                    context?.fill(CGRect.init(origin: CGPoint.zero, size: self.renderingRect.size));
                }
                context?.translateBy(x: inset.left, y: inset.top);
                
                layouter?.drawFlipped(in: context, bounds: CGRect.init(origin: CGPoint.zero, size: layouter!.usedSize));
                
                let imageRef = context?.makeImage();
                if(nil != imageRef) {
                    image = UIImage.init(cgImage: imageRef!);
                }
            }
            
        }
        return image;
    }
}

//MARK:- FTTransformColorUpdate
extension FTTextAnnotationV2 : FTTransformColorUpdate
{
    func upodateColor(_ color: UIColor!) {
        if let attrStr = self.attributedString {
            self.forceRender = true;
            let mutStr = NSMutableAttributedString.init(attributedString: attrStr);
            mutStr.addAttribute(NSForegroundColorAttributeName, value: color, range: NSMakeRange(0, attrStr.length));
            self.attributedString = mutStr;
        }
    }
    
    func currentColor() -> UIColor! {
        let color = self.attributedString?.attribute(NSForegroundColorAttributeName, at: 0, effectiveRange: nil) as? UIColor
        return color ?? UIColor.clear;
    }
}

//MARK:- FTTransformScale
extension FTTextAnnotationV2
{
    override func apply(_ scale: CGFloat) {
        if(scale == 1) {
            return;
        }
        
        self.transformScale *= Float(scale);
        var boundingRect = self.boundingRect;
        boundingRect.size = CGSizeScale(boundingRect.size, scale);
        self.boundingRect = boundingRect;
        
        if let attrStr = self.attributedString {
            let mutStr = NSMutableAttributedString.init(attributedString: attrStr);
            mutStr.applyScale(scale, originalScaleToApply: CGFloat(self.transformScale));
            self.attributedString = mutStr;
        }
    }
}

//MARK:- Memory Warning
extension FTTextAnnotationV2
{
    override func didRecieveMemoryWarning(_ notification: Notification) {
        self.unloadContents();
    }
}

//MARK:- FTAnnotationContainsProtocol
extension FTTextAnnotationV2
{
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

//MARK:- FTCopying
extension FTTextAnnotationV2
{
    override func deepCopyAnnotation(_ toPage: FTPageProtocol, onCompletion: @escaping (FTAnnotationV2?) -> Void) {
        let annotation = FTTextAnnotationV2.init(withPage : toPage)
        annotation.boundingRect = self.boundingRect;
        annotation.isReadonly = self.isReadonly;
        annotation.version = self.version;

        annotation.attributedString = self.attributedString?.mutableDeepCopy();
        annotation.transformScale = self.transformScale;
        onCompletion(annotation);
    }
}

extension FTTextAnnotationV2 : FTCGContextRendering
{
    func render(in context: CGContext!, scale: CGFloat) {
        if(!self.hidden) {

            var inset = FTTextView.textContainerInset(self.version);
            inset = UIEdgeInsetsScale(inset, CGFloat(self.transformScale));
            
            let textLayouter = FTTextLayouter.init(attributedString: self.attributedString,
                                                   constraints: CGSize.init(width: self.boundingRect.size.width-(inset.left+inset.right),
                                                                            height: CGFloat.greatestFiniteMagnitude));
            context.saveGState();
            context.scaleBy(x: scale, y: scale);
            if let bgColor = self.backgroundColor() {
                context.setFillColor(bgColor.cgColor);
                context.fill(self.boundingRect);
            }
            
            context.translateBy(x: inset.left, y: inset.top);
            textLayouter?.drawFlipped(in: context, bounds: CGRect.init(origin: self.boundingRect.origin, size: textLayouter!.usedSize));
            context.restoreGState();
        }
    }
}

//undo info
extension FTTextAnnotationV2
{
    override func undoInfo() -> FTUndoableInfo {
        let info = FTTextUndoableInfo();
        info.boundingRect = self.boundingRect;
        info.attrString = self.attributedString ?? NSAttributedString();
        return info;
    }
    
    override func updateWithUndoInfo(_ info: FTUndoableInfo)
    {
        guard let textInfo = info as? FTTextUndoableInfo else {
            fatalError("info should be of type FTTextUndoableInfo");
        }
        super.updateWithUndoInfo(textInfo);
        self.attributedString = textInfo.attrString;
    }
}

fileprivate class FTTextUndoableInfo : FTUndoableInfo
{
    var attrString : NSAttributedString = NSAttributedString();
    override func isEqual(_ object: Any?) -> Bool {
        guard let textInfo = object as? FTTextUndoableInfo else {
            return false;
        }
        if(
            super.isEqual(textInfo)
        &&  self.attrString.isEqual(toAttributedText: textInfo.attrString)
            ) {
            return true;
        }
        return false;
    }
}

#if TARGET_OS_SIMULATOR
extension FTTextAnnotation
{
    override func undoInfo() -> FTUndoableInfo {
        let info = FTTextUndoableInfo();
        info.boundingRect = self.boundingRect;
        info.attrString = self.attributedString ?? NSAttributedString();
        return info;
    }
    
    override func updateWithUndoInfo(_ info: FTUndoableInfo)
    {
        guard let textInfo = info as? FTTextUndoableInfo else {
            fatalError("info should be of type FTTextUndoableInfo");
        }
        super.updateWithUndoInfo(textInfo);
        self.attributedString = textInfo.attrString;
    }
}
#endif
