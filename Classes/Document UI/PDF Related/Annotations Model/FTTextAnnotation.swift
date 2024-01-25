//
//  FTTextAnnotation.swift
//  Noteshelf
//
//  Created by Amar on 24/07/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

let maxTextureSize : Int = 4096;//max texture size allowed in metal is 16384;

extension NSAttributedString
{
    func attributedData() -> Data?
    {
        var data : Data?;
        do {
            data = try self.data(from: NSRange.init(location: 0, length: self.length),
                                 documentAttributes: [NSAttributedString.DocumentAttributeKey.documentType : NSAttributedString.DocumentType.rtfd]);
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
        var attrString : NSAttributedString?;
        do {
            attrString = try NSAttributedString.init(data: self,
                                                     options: [NSAttributedString.DocumentReadingOptionKey.documentType : NSAttributedString.DocumentType.rtfd],
                                                     documentAttributes: nil);
        }
        catch {
            
        }
        return attrString;
    }
}

class FTTextAnnotation: FTAnnotation,FTImageRenderingProtocol {

    @objc var attributedString : NSAttributedString? {
        willSet {
            if let newAttrStr = newValue,
                let oldAttrStr = self.attributedString,
                !newAttrStr.isEqual(toAttributedText: oldAttrStr) {
                _detectedAttributedString = nil;
                self.forceRender = true;
            }
            else if(nil == newValue && nil != self.attributedString) {
                _detectedAttributedString = nil;
                self.forceRender = true;
            }
            else if(nil != newValue && nil == self.attributedString) {
                _detectedAttributedString = nil;
                self.forceRender = true;
            }
        }
    };
    
    private var _detectedAttributedString: NSMutableAttributedString?
    var detectedAttributedString: NSAttributedString? {
        if(nil == _detectedAttributedString) {
            if let atr = self.attributedString {
                _detectedAttributedString = NSMutableAttributedString(attributedString: atr);
                _detectedAttributedString?.applyDataDetectorAttributes();
            }
        }
        return _detectedAttributedString;
    }
    
    var dataValue : Data? {
        get {
            let attributedString = self.attributedString?.mutableCopy() as? NSMutableAttributedString
            if(nil != attributedString) {
                attributedString?.enumerateAttribute(NSAttributedString.Key(rawValue: "NSOriginalFont"),
                                                     in: NSRange.init(location: 0, length: attributedString!.length),
                                                     options: NSAttributedString.EnumerationOptions.init(rawValue: 0),
                                                     using:
                    { (fontAnyType, range, _) in
                        if(nil != fontAnyType) {
                            attributedString?.addAttribute(NSAttributedString.Key.font, value: fontAnyType!, range: range);
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
    
    @objc override var annotationType : FTAnnotationType {
        return .text;
    }

    @objc var transformScale : Float = 1;
    var rotationAngle : CGFloat = 0
    
    fileprivate var _imageToRenderTexture : MTLTexture?;
    
    @objc override var boundingRect: CGRect {
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
                _imageToRenderTexture = FTMetalUtils.texture(from: image);
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
        rotationAngle = CGFloat(aDecoder.decodeFloat(forKey: "rotationAngle"));
        let data = aDecoder.decodeObject(forKey: "text") as? Data;
        if(nil != data) {
            let attr = data!.attributedString();
            self.attributedString = attr?.mapAttributesToMatch(withLineHeight: -1);
        }
    }
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder);
        aCoder.encode(self.transformScale, forKey: "transformScale")
        //For encoding and decoding we need 64 bit Float, for other cases we need CGFloat, hence the declaration is CGFlaot.
        aCoder.encode(Float(rotationAngle), forKey: "rotationAngle");
        aCoder.encode(self.attributedString?.attributedData(), forKey: "text");
    }
    
    @objc func backgroundColor() -> UIColor? {
        var backgroundColor : UIColor? = UIColor.clear;
        if let attrStr = self.attributedString,attrStr.length > 0 {
            backgroundColor = attrStr.attribute(NSAttributedString.Key.backgroundColor, at: 0, effectiveRange: nil) as? UIColor;
        }
        return backgroundColor;
    }

    override var renderingRect: CGRect {
        let transform = CGAffineTransform(rotationAngle: CGFloat(rotationAngle));
        var renderingRect = self.boundingRect.applying(transform)
        renderingRect.origin.x = self.boundingRect.midX - renderingRect.width*0.5;
        renderingRect.origin.y = self.boundingRect.midY - renderingRect.height*0.5;
        return renderingRect;
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

    override func setRotation(_ angle: CGFloat, refPoint: CGPoint) {
        if angle != 0 {
            let transform = CGAffineTransform(translationX: refPoint.x, y: refPoint.y)
                .rotated(by: angle)
                .translatedBy(x: -refPoint.x, y: -refPoint.y)

            let center = CGPoint(x: self.boundingRect.midX, y: self.boundingRect.midY)
            let newCenter = center.applying(transform)
            let newOriginX = newCenter.x - boundingRect.width/2
            let newOriginY = newCenter.y - boundingRect.height/2
            self.boundingRect.origin = CGPoint(x: newOriginX, y: newOriginY)
            self.forceRender = true
            self.rotationAngle += angle
        }
    }

    @objc override class func defaultAnnotationVersion() -> Int {
        //the text container inset
        //from version 0 - 4 :: left = 20, right = 20, top = 20, bottom = 44;
        //from 5 to now :: left = 10, right = 10, top = 10, bottom = 10;
        return Int(5);
    }
    
    override func canSelectUnderLassoSelection() -> Bool {
        return FTRackPreferenceState.allowAnnotations().contains(annotationType)
    }
    
    override func canCancelEndEditingAnnotaionWhenPopOverPresents() -> Bool {
        return true
    }

}

//MARK:- Private
private extension FTTextAnnotation
{
    private func textToImage(scale : CGFloat) -> UIImage?
    {
        var image : UIImage?;
        if let attrstr = self.detectedAttributedString {
            let screenScale = UIScreen.main.scale;

            //get the max texture size scale
            let scaleRenderingRect = CGRectScale(self.boundingRect, scale);
            let textureSize = CGSize.aspectFittedSize(scaleRenderingRect.size, max: CGSize.init(width: Int(maxTextureSize), height: Int(maxTextureSize)));
            let texScale = textureSize.width/scaleRenderingRect.width;

            let scaleTpApply = (scale/screenScale)*texScale;
            var drawingRect = CGRect.scale(self.boundingRect, scaleTpApply);
            drawingRect.origin = CGPoint.zero;
            let imageSize = drawingRect.integral.size;

            //apply scale to the attributed string to match it.
            let mutStr = NSMutableAttributedString(attributedString: attrstr);
            mutStr.beginEditing()
            mutStr.enumerateAttribute(.link, in: NSRange(location: 0, length: mutStr.length)) { (linkValue, range, stop) in
                if nil != linkValue {
                    mutStr.removeAttribute(.link, range: range)
                    mutStr.addAttributes(NSAttributedString.linkAttributes, range: range);
                }
            }
            mutStr.endEditing();
            mutStr.applyScale(scaleTpApply, originalScaleToApply: CGFloat(self.transformScale)*scaleTpApply);

            UIGraphicsBeginImageContextWithOptions(imageSize, false, 0);
            guard let context = UIGraphicsGetCurrentContext() else {
                UIGraphicsEndImageContext();
                return nil
            }
            var inset = FTTextView.textContainerInset(self.version);
            inset = UIEdgeInsetsScale(inset, CGFloat(self.transformScale)*scaleTpApply);

            let layouter = FTTextLayouter.init(attributedString: mutStr,
                                               constraints: CGSize.init(width: drawingRect.width - (inset.left + inset.right), height: CGFloat.greatestFiniteMagnitude));
            if let backColor = self.backgroundColor() {
                context.setFillColor(backColor.cgColor);
                context.fill(CGRect.init(origin: CGPoint.zero, size: imageSize));
            }
            let imageOffset = (drawingRect.width - imageSize.width)*0.5;
            context.translateBy(x: inset.left+imageOffset, y: inset.top);
            layouter.drawFlipped(in: context, bounds: CGRect(origin: CGPoint.zero, size: layouter.usedSize));

            image =  UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();

            if(self.rotationAngle != 0) {
                image = image?.imageRotatedByRadians(self.rotationAngle);
            }
        }
        return image;
    }
}

//MARK:- FTTransformColorUpdate
extension FTTextAnnotation : FTTransformColorUpdate
{
    func update(color: UIColor) -> FTUndoableInfo {
        let undoInfo = self.undoInfo()
        if let attrStr = self.attributedString {
            self.forceRender = true;
            let mutStr = NSMutableAttributedString.init(attributedString: attrStr);
            mutStr.addAttribute(NSAttributedString.Key.foregroundColor,
                                value: color,
                                range:NSRange(location: 0, length: attrStr.length));
            self.attributedString = mutStr;
        }
        return undoInfo
    }

    var currentColor: UIColor? {
        let color = self.attributedString?.attribute(NSAttributedString.Key.foregroundColor, at: 0, effectiveRange: nil) as? UIColor
        return color;
    }
}
//MARK:- FTTransformScale
extension FTTextAnnotation
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
extension FTTextAnnotation
{
    override func didRecieveMemoryWarning(_ notification: Notification) {
        self.unloadContents();
    }
}

//MARK:- FTAnnotationContainsProtocol
extension FTTextAnnotation : FTAnnotationContainsProtocol
{
    @objc func isPointInside(_ point: CGPoint) -> Bool {
        return self._isPointInside(point);
    }

    func intersectsPath(_ inSelectionPath: CGPath, withScale scale: CGFloat, withOffset selectionOffset: CGPoint) -> Bool {
        var result = false;
        
        var selectionPathBounds = inSelectionPath.boundingBox;
        selectionPathBounds.origin = CGPoint.init(x: selectionPathBounds.origin.x+selectionOffset.x,
                                                  y: selectionPathBounds.origin.y+selectionOffset.y);
        var renderingRect = self.boundingRect
        renderingRect.rotate(by: rotationAngle, refPoint: CGPoint(x: renderingRect.midX, y: renderingRect.midY))
        let boundingRect1 = CGRectScale(renderingRect, scale);
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

    fileprivate func _isPointInside(_ point: CGPoint) -> Bool {
        let frame = self.boundingRect;
        let center = CGPoint.init(x: frame.midX, y: frame.midY);

        let translateTransform = CGAffineTransform.init(translationX: center.x, y: center.y);
        let rotationTransform = CGAffineTransform(rotationAngle: self.rotationAngle);

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

}

//MARK:- FTCopying
extension FTTextAnnotation
{
    override func deepCopyAnnotation(_ toPage: FTPageProtocol, onCompletion: @escaping (FTAnnotation?) -> Void) {
        let annotation = FTTextAnnotation.init(withPage : toPage)
        annotation.boundingRect = self.boundingRect;
        annotation.isReadonly = self.isReadonly;
        annotation.version = self.version;

        annotation.rotationAngle = self.rotationAngle;
        annotation.attributedString = self.attributedString?.mutableDeepCopy();
        annotation.transformScale = self.transformScale;
        onCompletion(annotation);
    }
}

extension FTTextAnnotation : FTCGContextRendering
{
    func render(in context: CGContext!, scale: CGFloat) {

        var inset = FTTextView.textContainerInset(self.version);
        inset = UIEdgeInsetsScale(inset, CGFloat(self.transformScale));
        guard let attributedString = self.detectedAttributedString else { return }
        let textLayouter = FTTextLayouter.init(attributedString: attributedString,
                                               constraints: CGSize.init(width: self.boundingRect.size.width-(inset.left+inset.right),
                                                                        height: CGFloat.greatestFiniteMagnitude));
        context.saveGState();
        context.scaleBy(x: scale, y: scale);

        let transformTranslate = CGAffineTransform(translationX: -self.boundingRect.midX, y: -self.boundingRect.midY)
        let transformFinal = transformTranslate.concatenating(CGAffineTransform(rotationAngle: rotationAngle)).concatenating(transformTranslate.inverted())

        context.concatenate(transformFinal);
        if let bgColor = self.backgroundColor() {
            context.setFillColor(bgColor.cgColor);
            context.fill(self.boundingRect);
        }

        context.translateBy(x: inset.left, y: inset.top);
        textLayouter.drawFlipped(in: context, bounds: CGRect.init(origin: self.boundingRect.origin, size: textLayouter.usedSize));
        context.restoreGState();
    }
}

//undo info
extension FTTextAnnotation
{
    override func undoInfo() -> FTUndoableInfo {
        let info = FTTextUndoableInfo.init(withAnnotation: self);
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

private class FTTextUndoableInfo : FTUndoableInfo
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

extension FTTextAnnotation : NSSecureCoding {
    public class var supportsSecureCoding: Bool {
        return true;
    }
}

private extension NSMutableAttributedString
{
    func applyDataDetectorAttributes()
    {
        let string = self.string;
        guard !string.isEmpty else {
            return;
        }
        
        do {
            let detector = try NSDataDetector.init(types: NSTextCheckingAllSystemTypes);
            detector.enumerateMatches(in: string,
                                      options: .reportCompletion,
                                      range: NSRange(location: 0, length:string.count))
            { (result, _, _) in
                if let _result = result {
                    let range = _result.range;
                    switch(_result.resultType) {
                    case .link:
                        if let url = _result.url {
                            self.addAttribute(.customLink, value: url, range: range)
                            self.addAttributes(NSAttributedString.linkAttributes, range: range);
                        }
                    default:
                        break;
                    }
                }
            };
        }
        catch {
            
        }
    }
}

@objc extension UIColor {
    class var link: UIColor {
        return UIColor(hexString: "5779F8");
    }
}

extension NSAttributedString.Key  {
    static let customLink = NSAttributedString.Key(rawValue: "customLinkAttriuteName");
}

@objc extension NSAttributedString
{
    class var linkAttributes: [NSAttributedString.Key:Any] {
        var attributes = [NSAttributedString.Key:Any]();
        attributes[.foregroundColor] = UIColor.link;
        attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue;
        attributes[.underlineColor] = UIColor.link
        return attributes;
    }
}
