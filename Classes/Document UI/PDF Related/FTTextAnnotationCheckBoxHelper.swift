//
//  FTTextAnnotationCheckBoxHelper.swift
//  Noteshelf
//
//  Created by Amar on 19/6/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

private class FTAttributesInfo: NSObject
{
    var attributes: [NSAttributedString.Key : Any]?;
    var boundingRect = CGRect.null;
}

private class FTTextAnnotationLayoutHelper: NSObject
{
    static let shared = FTTextAnnotationLayoutHelper();
    
    fileprivate var layoutManager = NSLayoutManager();
    fileprivate var textContainer = NSTextContainer(size: CGSize.init(width: CGFloat(Float.greatestFiniteMagnitude), height: CGFloat(Float.greatestFiniteMagnitude)));
    fileprivate var textStorage = NSTextStorage(string: "");
    fileprivate var trasnformScale : CGFloat = 1;
    fileprivate var annotationVersion : Int = 0;
    
    override init() {
        super.init();
        self.textContainer.lineFragmentPadding = 0
        self.layoutManager.addTextContainer(self.textContainer);
        self.textStorage.addLayoutManager(self.layoutManager);
    }
    
    func cleanUpMemory()
    {
        self.textStorage.setAttributedString(NSAttributedString.init());
        self.layoutManager.ensureLayout(for: self.textContainer);
    }
    
    func updateWith(textAnnotation: FTTextAnnotation,attrString : NSAttributedString)
    {
        self.trasnformScale = CGFloat(textAnnotation.transformScale);
        
        var inset = FTTextView.textContainerInset(textAnnotation.version);
        inset = UIEdgeInsetsScale(inset, self.trasnformScale);
        var size = textAnnotation.boundingRect.size;
        size.width -= (inset.left+inset.right);
        size.height -= (inset.top+inset.bottom);
        self.textContainer.size = size;

        self.textStorage.setAttributedString(attrString);
        self.layoutManager.ensureLayout(for: self.textContainer);
        self.annotationVersion = textAnnotation.version;
    }
    
    func attributes(atPoint point : CGPoint) -> FTAttributesInfo
    {
        let attributesInfo = FTAttributesInfo();
        var convertedPoint = point;
        var inset = FTTextView.textContainerInset(self.annotationVersion);
        inset = UIEdgeInsetsScale(inset, self.trasnformScale);
        
        convertedPoint.x -= inset.left;
        convertedPoint.y -= inset.top;
        
        let characterIndex = self.layoutManager.characterIndex(for: convertedPoint,
                                                               in: self.textContainer,
                                                               fractionOfDistanceBetweenInsertionPoints: nil);
        if (characterIndex >= self.textStorage.length) {
            return attributesInfo;
        }
        
        let charRange : NSRange = NSRange.init(location: characterIndex, length: 1);
        let glyphRange = self.layoutManager.glyphRange(forCharacterRange: charRange, actualCharacterRange: nil);
        let boundRect = self.layoutManager.boundingRect(forGlyphRange: glyphRange, in: self.textContainer);
        if(boundRect.contains(convertedPoint)) {
            var range : NSRange = NSRange.init(location: NSNotFound, length: 0);
            attributesInfo.attributes = self.textStorage.attributes(at: characterIndex, effectiveRange:
                &range);
            attributesInfo.boundingRect = self.boundingRect(range: range);
        }
        return attributesInfo;
    }
    
    private func boundingRect(range: NSRange) -> CGRect
    {
        let attrsGlyphRange = self.layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil);
        var rect = self.layoutManager.boundingRect(forGlyphRange: attrsGlyphRange, in: self.textContainer);
        
        var inset = FTTextView.textContainerInset(self.annotationVersion);
        inset = UIEdgeInsetsScale(inset, self.trasnformScale);
        rect.origin.x += inset.left;
        rect.origin.y += inset.top;
        return rect;
    }
}

class FTTextAnnotationLinkHelper: NSObject
{
    func linkInfo(at point : CGPoint,forAnnotation annotation : FTAnnotation) -> FTAnnotationAction?
    {
        var action: FTAnnotationAction?;
        if let textAnnotation = annotation as? FTTextAnnotation,
            let attrString = textAnnotation.attributedString {
            FTTextAnnotationLayoutHelper.shared.updateWith(textAnnotation: textAnnotation,
                                                           attrString: attrString);

            let attributesInfo = FTTextAnnotationLayoutHelper.shared.attributes(atPoint: point);
            if let actionURL = attributesInfo.attributes?[.link] as? URL {
                action = FTAnnotationAction()
                action?.URL = actionURL
                action?.rect = attributesInfo.boundingRect
                action?.annotation = annotation
            }
        }
        return action;
    }

    func cleanUpMemory()
    {
        FTTextAnnotationLayoutHelper.shared.cleanUpMemory();
    }
}

class FTTextAnnotationCheckBoxHelper : NSObject {
    
    func checkIfCheckboxExists(atPoint point : CGPoint,
                               forAnnotation annotation : FTAnnotation) -> Bool
    {
        if let textAnnotation = annotation as? FTTextAnnotation,
            let attrString = textAnnotation.attributedString {
            FTTextAnnotationLayoutHelper.shared.updateWith(textAnnotation: textAnnotation,
                                                           attrString: attrString);
            let attributesInfo = FTTextAnnotationLayoutHelper.shared.attributes(atPoint: point);
            if nil != attributesInfo.attributes?[.attachment] {
                return true;
            }
        }
        return false;
    }

    func toggleCheckBox(atPoint point : CGPoint,annotation : FTAnnotation)
    {
        let helper = FTTextAnnotationLayoutHelper.shared;
        var convertedPoint = point;
        var inset = FTTextView.textContainerInset(helper.annotationVersion);
        inset = UIEdgeInsetsScale(inset, helper.trasnformScale);
        
        convertedPoint.x -= inset.left;
        convertedPoint.y -= inset.top;
        
        let characterIndex = helper.layoutManager.characterIndex(for: convertedPoint,
                                                                 in: helper.textContainer,
                                                                 fractionOfDistanceBetweenInsertionPoints: nil);
        if (characterIndex < helper.textStorage.length) {
            var range : NSRange = NSRange.init(location: 0, length: 0);
            if let textAttachment = helper.textStorage.attribute(NSAttributedString.Key.attachment,
                                                               at: characterIndex,
                                                               effectiveRange: &range) {
                let checkBoxOffAttachment = NSTextAttachment.init();
                checkBoxOffAttachment.image = UIImage.init(named: "check-off-2x.png");
                checkBoxOffAttachment.updateFileWrapperIfNeeded();
                checkBoxOffAttachment.bounds = CGRect.init(x: CGFloat(0), y: CGFloat(CHECK_BOX_OFFSET_Y), width: CGFloat(CHECKBOX_WIDTH), height: CGFloat(CHECKBOX_HEIGHT));
                
                let checkBoxonAttachment = NSTextAttachment.init();
                checkBoxonAttachment.image = UIImage.init(named: "check-on-2x.png");
                checkBoxonAttachment.updateFileWrapperIfNeeded();
                checkBoxonAttachment.bounds = CGRect.init(x: CGFloat(0), y: CGFloat(CHECK_BOX_OFFSET_Y), width: CGFloat(CHECKBOX_WIDTH), height: CGFloat(CHECKBOX_HEIGHT));
                
                let contents = (textAttachment as! NSTextAttachment).fileWrapper?.regularFileContents;
                
                guard let checkBoxOffContents = checkBoxOffAttachment.fileWrapper?.regularFileContents,
                    let checkBoxOnContents = checkBoxonAttachment.fileWrapper?.regularFileContents
                    else {
                        return;
                }
                
                var isSameAsCheckOff = (contents == checkBoxOffContents);
                var isSameAsCheckOn = (contents == checkBoxOnContents);
                
                if ((contents != nil) && !isSameAsCheckOff && !isSameAsCheckOn)
                {
                    //isEqualToData is not working always, if isEqualToData fails checking UIImagePNGRepresentation
                    let contentInfo = UIImage.init(data: contents!)!.pngData();
                    let checkOnContentInfo = UIImage.init(data: checkBoxOnContents)!.pngData();
                    let checkOffContentInfo = UIImage.init(data: checkBoxOffContents)!.pngData();
                    
                    isSameAsCheckOff = (contentInfo == checkOffContentInfo);
                    isSameAsCheckOn = (contentInfo == checkOnContentInfo);
                }
                
                //since in iOS12 there was an issue where the textattachment was not stored properly and the file wrapper for new textattachment creation was not having file wrapper as a work around we are depending on the data size to determine the type of check box.
                if ((contents != nil) && !isSameAsCheckOff && !isSameAsCheckOn)
                {
                    let contentLength = contents!.count;
                    if(contentLength <= checkBoxOffContents.count) {
                        isSameAsCheckOff = true;
                    }
                    else if(contentLength > checkBoxOffContents.count && contentLength <= (checkBoxOnContents.count + 10)) {
                        isSameAsCheckOn = true;
                    }
                }
                if(isSameAsCheckOff) {
                    let str = NSAttributedString.init(attachment: checkBoxonAttachment);
                    var attrs = helper.textStorage.attributes(at: range.location, effectiveRange: nil);
                    attrs.removeValue(forKey: NSAttributedString.Key.attachment);
                    
                    helper.textStorage.beginEditing();
                    helper.textStorage.replaceCharacters(in: range, with: str);
                    helper.textStorage.addAttributes(attrs, range: range);
                    helper.textStorage.endEditing();
                }
                else if(isSameAsCheckOn) {
                    let str = NSAttributedString.init(attachment: checkBoxOffAttachment);
                    var attrs = helper.textStorage.attributes(at: range.location, effectiveRange: nil);
                    attrs.removeValue(forKey: NSAttributedString.Key.attachment);
                    
                    helper.textStorage.beginEditing();
                    helper.textStorage.replaceCharacters(in: range, with: str);
                    helper.textStorage.addAttributes(attrs, range: range);
                    helper.textStorage.endEditing();
                }
                (annotation as? FTTextAnnotation)?.attributedString = helper.textStorage.deepCopy();
            }
        }
    }
    
    func cleanUpMemory()
    {
        FTTextAnnotationLayoutHelper.shared.cleanUpMemory();
    }
}
