//
//  FTAnnotation_UI_Factory.swift
//  Noteshelf
//
//  Created by Naidu on 10/01/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

let TEXT_ANNOTATION_OFFSET: CGFloat = 10;

let kAudioRecIconSize : CGSize = CGSize.init(width: audioRecordSize, height: audioRecordSize)

@objcMembers class FTAnnotationInfo: NSObject {
    var visibleRect: CGRect = CGRect.zero
    var scale: CGFloat = 1.0
    var atPoint: CGPoint = CGPoint.zero
    var boundingRect = CGRect.null;
    weak var localmetadataCache : FTDocumentLocalMetadataCacheProtocol?
    var enterEditMode : Bool = true
    
    func annotation() -> FTAnnotation? {
        return nil;
    }
}

@objcMembers class FTAudioAnnotationInfo : FTAnnotationInfo {
    var associatedPage : FTPageProtocol
    var audioState : AudioSessionState
    
    init(withPage page : FTPageProtocol) {
        associatedPage = page
        audioState = .stateRecording
    }
    
    override func annotation() -> FTAnnotation? {
        let annotation = FTAudioAnnotation();
        annotation.update(info: self);
        annotation.audioFileName = "Recording"
        return annotation;
    }

}

@objcMembers class FTStickyAnnotationInfo : FTImageAnnotationInfo
{
    var emojiName : String = ""
    init(image inImage : UIImage, name : String) {
        super.init(image: inImage)
        emojiName = name
        enterEditMode = false
    }
    
    override func annotation() -> FTAnnotation? {
        let annotation = FTStickyAnnotation();
        annotation.update(info: self);
        return annotation;
    }

}


@objcMembers class FTImageAnnotationInfo : FTAnnotationInfo
{
    var source : FTInsertImageSource = FTInsertImageSourcePhotos
    var center : CGPoint = CGPoint.zero

    var image : UIImage;
    init(image inImage : UIImage) {
        image = inImage
    }
    
    override func annotation() -> FTAnnotation? {
        let annotation = FTImageAnnotation();
        annotation.update(info: self);
        return annotation;
    }

}

@objcMembers class FTStickerAnnotationInfo : FTImageAnnotationInfo
{
    override init(image inImage : UIImage) {
        super.init(image: inImage)
    }
    
    override func annotation() -> FTAnnotation? {
        let annotation = FTStickerAnnotation();
        annotation.update(info: self);
        return annotation;
    }
}

@objcMembers class FTWebClipAnnotationInfo : FTImageAnnotationInfo
{
    var clipString: String = ""
    
    override func annotation() -> FTAnnotation? {
        let annotation = FTWebClipAnnotation()
        annotation.update(info: self)
        return annotation
    }

}

@objcMembers class FTShapeAnnotationInfo : FTAnnotationInfo {
    var shapeType : FTShapeType;
    init(with _shape : FTShapeType) {
        shapeType = _shape
    }
    
    override func annotation() -> FTAnnotation? {
        let annotation = FTShapeAnnotation();
        annotation.update(info: self);
        return annotation;
    }
}


@objcMembers class FTTextAnnotationInfo : FTAnnotationInfo
{
    override func annotation() -> FTAnnotation? {
        let annotation = FTTextAnnotation();
        annotation.update(info: self);
        return annotation;
    }

    var attributedString : NSAttributedString?
    var string : String?
    var fromConvertToText: Bool = false;
    // Added this to identify weburl links and convert to our linking mechanism
    var isToPaste: Bool = false

    func defaultTextTypingAttributes() -> [NSAttributedString.Key : Any]
    {
        let paragraphStyle = NSMutableParagraphStyle();
        paragraphStyle.alignment = NSTextAlignment.left;
        let defaultFont = self.localmetadataCache?.defaultBodyFont ?? UIFont.defaultTextFont();
        let defaultColor : UIColor = self.localmetadataCache?.defaultTextColor ?? UIColor(hexString: "000000");
        
        var attrs : [NSAttributedString.Key : Any] = [NSAttributedString.Key.paragraphStyle:paragraphStyle
            ,NSAttributedString.Key.font:defaultFont
            ,NSAttributedString.Key.foregroundColor:defaultColor];
        
        if let isUnderline = self.localmetadataCache?.defaultIsUnderline, isUnderline {
            attrs[NSAttributedString.Key.underlineStyle] = NSNumber.init(value: NSUnderlineStyle.single.rawValue);
        }
        
        let backgroundColorString = UserDefaults.standard.string(forKey: "text_background_color")
        if nil != backgroundColorString && (backgroundColorString != UIColor.clear.hexStringFromColor()) {
                attrs[NSAttributedString.Key.backgroundColor] = UIColor(hexString: backgroundColorString);
        }
        return attrs;
    }
}

extension FTAnnotation
{
    func update(info : FTAnnotationInfo) {
        self.currentScale = info.scale
    }
}

extension FTAudioAnnotation {
    override func update(info: FTAnnotationInfo) {
        super.update(info: info);
        guard let audioInfo = info as? FTAudioAnnotationInfo else {
            fatalError("info should be of type FTAudioAnnotationInfo");
        }
        self.associatedPage = audioInfo.associatedPage
        self.audioState = audioInfo.audioState
        if audioInfo.boundingRect.isNull {
            let visibleRect: CGRect = audioInfo.visibleRect;
            let audioRecIconSize: CGSize = CGSizeScale(kAudioRecIconSize, audioInfo.scale)
            let finalFrame : CGRect = CGRect.init(x: visibleRect.width - audioRecIconSize.width - audioRecIconSize.width/2,
                                                  y: visibleRect.origin.y ,
                                    width: audioRecIconSize.width,
                                    height: audioRecIconSize.height)
            let scaledRect = CGRect.scale(finalFrame,1/self.currentScale);
            if let page = self.associatedPage as? FTPageAnnotationFindBounds {
                self.boundingRect = page.findDefaultAudioRect(current: scaledRect)
            } else {
                self.boundingRect = scaledRect
            }
            
        } else {
            self.boundingRect = audioInfo.boundingRect
        }
    }
}

extension FTStickyAnnotation
{
    override func update(info: FTAnnotationInfo)
    {
        super.update(info: info);
        guard let stickyInfo = info as? FTStickyAnnotationInfo else {
            fatalError("info should be of type FTStickyAnnotationInfo");
        }
        
        self.emojiName = stickyInfo.emojiName
    }
}

extension FTWebClipAnnotation {
    override func update(info: FTAnnotationInfo) {
        super.update(info: info)
        guard let imageInfo = info as? FTWebClipAnnotationInfo else {
            fatalError("info should be of type FTClipAnnotationInfo");
        }
        self.clipString = imageInfo.clipString
    }
}

extension FTImageAnnotation
{
    override func update(info: FTAnnotationInfo)
    {
        super.update(info: info);
        guard let imageInfo = info as? FTImageAnnotationInfo else {
            fatalError("info should be of type FTImageAnnotationInfo");
        }
        
        self.image = imageInfo.image
        if imageInfo.boundingRect.isNull {
            let finalizedImage = imageInfo.image
            let visibleRect: CGRect = info.visibleRect;
            var finalFrame : CGRect = finalizedImage.frame(inRect: visibleRect,
                                                           capToMinIfNeeded: true,
                                                           contentScale:imageInfo.scale);
            
            if(imageInfo.center != CGPoint.zero) {
                finalFrame = CGRectSetCenter(finalFrame, imageInfo.center, visibleRect);
            }
            
            if imageInfo.source == FTInsertImageSourceClipart {
                finalFrame = CGRectScaleFromCenter(finalFrame, 0.5);
            }
            
            self.boundingRect = CGRect.scale(finalFrame,1/self.currentScale);
            
        } else {
            self.boundingRect = imageInfo.boundingRect
        }
    }
}

extension FTStickerAnnotation
{
    override func update(info: FTAnnotationInfo)
    {
        super.update(info: info);
        guard let imageInfo = info as? FTStickerAnnotationInfo else {
            fatalError("info should be of type FTStickerAnnotationInfo");
        }
        
        self.image = imageInfo.image
        if imageInfo.boundingRect.isNull {
            let finalizedImage = imageInfo.image
            let visibleRect: CGRect = info.visibleRect;
            var finalFrame : CGRect = finalizedImage.frame(inRect: visibleRect,
                                                           capToMinIfNeeded: true,
                                                           contentScale:imageInfo.scale);
            
            if(imageInfo.center != CGPoint.zero) {
                finalFrame = CGRectSetCenter(finalFrame, imageInfo.center, visibleRect);
            }
            
            if imageInfo.source == FTInsertImageSourceClipart {
                finalFrame = CGRectScaleFromCenter(finalFrame, 0.5);
            }
            
            self.boundingRect = CGRect.scale(finalFrame,1/self.currentScale);
            
        } else {
            self.boundingRect = imageInfo.boundingRect
        }
    }
}

extension FTShapeAnnotation {
    override func update(info: FTAnnotationInfo) {
        super.update(info: info)
        guard let shapeInfo = info as? FTShapeAnnotationInfo else {
            fatalError("info should be of type FTShapeAnnotationInfo");
        }
        self.shape = shapeInfo.shapeType.getDefaultShape()
        let shapeType = (shape?.type() ?? .lineStrip)
        let sides = shapeType.shapeSides()
        self.shapeData = FTShapeData(with: shapeType.rawValue, sides: sides, strokeOpacity: 1.0)
    }
}


extension FTTextAnnotation
{
    override func update(info: FTAnnotationInfo)
    {
        super.update(info: info);
        guard let textInfo = info as? FTTextAnnotationInfo else {
            fatalError("info should be of type FTTextAnnotationInfo");
        }
        
        let  attrs = textInfo.defaultTextTypingAttributes();
        if let attrStr = textInfo.attributedString {
            self.attributedString = attrStr;
        }
        else {
            if let str = textInfo.string {
                let attrString = NSMutableAttributedString.init(string: str, attributes: attrs)
                if textInfo.isToPaste {
                    attrString.applyDataDetectorAttributes()
                    attrString.enumerateAttribute(.customLink, in: NSRange(location: 0, length: attrString.length), using: { value, range, stop in
                        if let linkValue = value {
                            attrString.removeAttribute(.customLink, range: range)
                            attrString.addAttribute(.link, value: linkValue, range: range)
                        }
                    })
                }
                self.attributedString = attrString
            }
            else {
                self.attributedString = NSAttributedString.init(string: "", attributes: attrs);
            }
        }

        if textInfo.boundingRect.isNull {
            let scale = self.currentScale;
            let oneByScale = 1/scale;
            
            let inset = FTTextView.textContainerInset(FTTextAnnotation.defaultAnnotationVersion());
            let scaledInset = UIEdgeInsetsScale(inset, scale);
            
            let visibleRect: CGRect = info.visibleRect;

            info.atPoint.x -= scaledInset.left;
            
            if(info.atPoint.x < visibleRect.minX) {
                info.atPoint.x = visibleRect.minX + TEXT_ANNOTATION_OFFSET;
            }
            
            let minSize = self.minSize(info: textInfo,
                                       defaultAttrs: attrs);

            if(info.atPoint.x + minSize.width > visibleRect.maxX - TEXT_ANNOTATION_OFFSET) {
                info.atPoint.x = visibleRect.maxX - TEXT_ANNOTATION_OFFSET - minSize.width;
            }

            let availableWidth = visibleRect.maxX - info.atPoint.x - TEXT_ANNOTATION_OFFSET;
            var requiredWidth: CGSize = self.attributedString?.requiredAttributedStringSize(maxWidth: availableWidth*oneByScale,
                                                                                            containerInset: inset) ?? CGSize.zero;
            requiredWidth = CGSizeScale(requiredWidth, scale);
            requiredWidth.width = max(requiredWidth.width,minSize.width);
            requiredWidth.height = max(requiredWidth.height,minSize.height);
            let width =  requiredWidth.width;
            let height = requiredWidth.height;
            
            let flexTextViewFrame: CGRect = CGRect(x: info.atPoint.x,
                                                   y: info.atPoint.y - scaledInset.top,
                                                   width: width,
                                                   height: height);
            let boundRect = CGRect.scale(flexTextViewFrame,oneByScale);
            self.boundingRect = boundRect;
        }
        else {
            self.boundingRect = textInfo.boundingRect;
        }
    }
    
    private func minSize(info: FTTextAnnotationInfo,
                         defaultAttrs : [NSAttributedString.Key:Any]) -> CGSize {
        
        let inset = FTTextView.textContainerInset(FTTextAnnotation.defaultAnnotationVersion());
        let scaledInset = UIEdgeInsetsScale(inset, info.scale);
        
        
        var minSizeRequired = NSAttributedString.minSizeToFit(defaultAttrs[.font] as? UIFont,
                                                              scale: info.scale,
                                                              containerInset: scaledInset)
        guard let attrString = self.attributedString else {
            return minSizeRequired;
        }
        
        if(attrString.length > 0 || nil != defaultAttrs[.backgroundColor]) {
            minSizeRequired.width = 240;
            minSizeRequired.height = 120;
            minSizeRequired = CGSize.scale(minSizeRequired, info.scale);
        }
        return minSizeRequired;
    }
}
