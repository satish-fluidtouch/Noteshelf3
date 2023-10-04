//
//  FTPDFExportView_Extension.swift
//  Noteshelf
//
//  Created by Amar on 17/08/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

extension FTPDFExportView {
    @objc static func snapshot(forPage page: FTPageProtocol?,
                         size : CGSize,
                         screenScale : CGFloat,
                         shouldRenderBackground : Bool) -> UIImage?
    {
        var imageToReturn : UIImage?
        if let pageTorender = page {
            self.snapshot(forPage: pageTorender,
                          size: size,
                          screenScale: screenScale,
                          renderBackground: shouldRenderBackground,
                          offscreenRenderer: nil,
                          asynchronous: false,
                          purpose:FTSnapshotPurposeDefault,
                          windowHash: nil) { (image, _) in
                            imageToReturn = image;
            };
        }
        return imageToReturn;
    }

    static func snapshot(forPage page : FTPageProtocol?,
                               size : CGSize,
                               screenScale : CGFloat,
                               shouldRenderBackground : Bool,
                               offscreenRenderer: FTOffScreenRenderer? = nil,
                               with purpose:FTSnapshotPurpose) -> UIImage?
    {
        var imageToReturn : UIImage?
        if let pageTorender = page {
            let annotations = pageTorender.annotations();
            self.snapshot(forPage: pageTorender,
                          size: size,
                          screenScale: screenScale,
                          renderBackground: shouldRenderBackground,
                          offscreenRenderer: offscreenRenderer,
                          asynchronous: false,
                          annotations: annotations,
                          purpose:purpose,
                          windowHash: nil){ (image, _) in
                            imageToReturn = image;
            }
        }
        return imageToReturn;
    }

    static func snapshot(forPage page : FTPageProtocol?,
                         size : CGSize,
                         screenScale : CGFloat,
                         offscreenRenderer : FTOffScreenRenderer?,
                         purpose:FTSnapshotPurpose,
                         windowHash: Int?,
                         onCompletion : @escaping (UIImage?,FTPageProtocol?)->())
    {
        if let pageTorender = page {
            self.snapshot(forPage: pageTorender,
                          size: size,
                          screenScale: screenScale,
                          renderBackground: true,
                          offscreenRenderer: offscreenRenderer,
                          asynchronous : true,
                          purpose:purpose,
                          windowHash: windowHash,
                          onCompletion: onCompletion);
        }
        else {
            onCompletion(nil,page);
        }
    }
    
    @objc static func snapshot(forPage page: FTPageProtocol?,
                         screenScale : CGFloat,
                         withAnnotations : [FTAnnotation]) -> UIImage?
    {
        return self.snapshot(forPage: page,
                             screenScale: screenScale,
                             withAnnotations: withAnnotations,
                             shouldRenderBackground: false);
    }

    @objc static func snapshot(forPage page: FTPageProtocol?,
                         screenScale : CGFloat,
                         withAnnotations : [FTAnnotation],
                         shouldRenderBackground : Bool) -> UIImage?
    {
        var imageToReturn : UIImage?
        if let pageTorender = page {
            self.snapshot(forPage: pageTorender,
                          size: pageTorender.pdfPageRect.size,
                          screenScale: screenScale,
                          renderBackground: shouldRenderBackground,
                          offscreenRenderer: nil,
                          asynchronous: false,
                          annotations: withAnnotations,
                          purpose:FTSnapshotPurposeDefault,
                          windowHash: nil) { (image, _) in
                            imageToReturn = image;
            }
        }
        return imageToReturn;
    }
    @objc static func snapshot(forPage page: FTPageProtocol?,
                         size : CGSize,
                         screenScale : CGFloat,
                         onCompletion : @escaping (UIImage?,FTPageProtocol?)->())
    {
        if let pageTorender = page {
            self.snapshot(forPage: pageTorender,
                          size: size,
                          screenScale: screenScale,
                          renderBackground: true,
                          offscreenRenderer: nil,
                          asynchronous: true,
                          purpose:FTSnapshotPurposeDefault,
                          windowHash: nil,
                          onCompletion: onCompletion);
        }
        else {
            onCompletion(nil,page);
        }
    }

    fileprivate static func snapshot(forPage page : FTPageProtocol?,
                                     size : CGSize,
                                     screenScale : CGFloat,
                                     renderBackground : Bool,
                                     offscreenRenderer : FTOffScreenRenderer?,
                                     asynchronous : Bool,
                                     purpose:FTSnapshotPurpose,
                                     windowHash: Int?,
                                     onCompletion : @escaping (UIImage?,FTPageProtocol?)->())
    {
        if let pageTorender = page {
            self.snapshot(forPage: pageTorender,
                          size: size,
                          screenScale: screenScale,
                          renderBackground: renderBackground,
                          offscreenRenderer: offscreenRenderer,
                          asynchronous: asynchronous,
                          annotations: nil,
                          purpose:purpose,
                          windowHash: windowHash,
                          onCompletion: onCompletion);
        }
        else {
            onCompletion(nil,page);
        }
    }
    
    //@annotations : passing nil will rendering all annotations
    fileprivate static func snapshot(forPage page : FTPageProtocol,
                                     size : CGSize,
                                     screenScale : CGFloat,
                                     renderBackground : Bool,
                                     offscreenRenderer : FTOffScreenRenderer?,
                                     asynchronous : Bool,
                                     annotations : [FTAnnotation]?,
                                     purpose:FTSnapshotPurpose,
                                     windowHash: Int?,
                                     onCompletion : @escaping (UIImage?,FTPageProtocol?)->())
    {
        if(asynchronous) {
            DispatchQueue.global().async {
                self.snapshot(forPage: page,
                              size: size,
                              screenScale: screenScale,
                              renderBackground: renderBackground,
                              offscreenRenderer: offscreenRenderer,
                              asynchronous: false,
                              annotations: annotations,
                              purpose:purpose,
                              windowHash: windowHash,
                              onCompletion: onCompletion);
            }
            return;
        };

        var offscreenRenderToUse = offscreenRenderer;
        //Create an offscreen render view with specified size.
        //calculate the size that fits the current page's aspect ratio
        let pageRect = page.pdfPageRect;
        if(pageRect.isNull) {
            onCompletion(nil,page);
            return;
        }
        /*
         Steps involved in finding the rect so that the annotation properties should not go below the min value.
         1. Find the rect maintaining the aspect ratio for the specified size
         2. Check if the aspect rect size or width less than minimum size needed for the page to display the annotation properties without falling below minimum value. If the rect size is less than minimum size then set the rect size to minimum size required
         3. Find scale of the rect wrt to normal size of the page.
         4: Generate background if needed
         5. Create Offscreen render view with the aspect rect frame.
         */
        
        //Step 1
        let finalRectSize = CGSize.aspectFittedSize(pageRect.size, max: size);
        var finalRect = CGRect.init(origin: CGPoint.zero, size: finalRectSize);
        
        //Step 2
        let referenceViewSize = page.pageReferenceViewSize();
        if(purpose == FTSnapshotPurposeThumbnail) {
            finalRect.size = CGSize.aspectFittedSize(pageRect.size, max: CGSize.init(width: 500, height: 500));
        }
        else {
            // Reverting this logic in 8.8.7 in favor of tiling logic implemented for the background rendering.
            /*
            if(finalRect.size.width < referenceViewSize.width || finalRect.size.height < referenceViewSize.height) {
                finalRect.size = referenceViewSize;
            }
            */
            if(Int(finalRect.size.width) > maxTextureSize || Int(finalRect.size.height) > maxTextureSize) {
                finalRect.size = CGSize.aspectFittedSize(finalRect.size, max: CGSize.init(width: maxTextureSize, height: maxTextureSize));
            }
        }
        
        //Step 3
        let scaleWrtNorm = finalRect.size.width/referenceViewSize.width;

        //Step 5
        var shouldReleaseOnCompletion = false;
        if(offscreenRenderToUse == nil) {
            offscreenRenderToUse = FTRendererProvider.shared.dequeOffscreenRenderer()
            shouldReleaseOnCompletion = true;
        }
        
        var annotaionsToRender = annotations ?? page.annotations();
        if(purpose == FTSnapshotPurposeEvernoteSync) {
            annotaionsToRender =  annotaionsToRender.filter { (eachAnnotation) -> Bool in
                return eachAnnotation.supportsENSync;
            }
        }
        
        let semaphore = DispatchSemaphore.init(value:0);
        var imageToReturn : UIImage?;


        func generateImage(bgTexture : MTLTexture?, backgroundTextureTileContent: FTBackgroundTextureTileContent?)
        {
            var bgColor: UIColor = .white;
            if (nil != bgTexture || nil != backgroundTextureTileContent), let _bgColor = (page as? FTPageBackgroundColorProtocol)?.pageBackgroundColor {
                bgColor = _bgColor;
            }
            
            let request = FTOffScreenPageImageRequest(with: windowHash);
            request.label = "PAGE_SNAPSHOT"
            request.backgroundColor = bgColor
            request.annotations = annotaionsToRender;
            request.screenScale = screenScale;
            request.imageSize = finalRect.size;
            if FTRenderConstants.USE_BG_TILING {
                request.backgroundTextureTileContent = backgroundTextureTileContent;
            } else {
                request.backgroundTexture = bgTexture;
            }
            request.scale = scaleWrtNorm;
            request.contentSize = finalRect.size;

            request.completionBlock = { image in
                var newImage = image;
                if(nil != newImage) {
                    autoreleasepool{
                        let downSizeScale = min(finalRectSize.width/pageRect.width, finalRectSize.height/pageRect.height);
                        if(downSizeScale != scaleWrtNorm) {
                            newImage = self.resizeImage(image: newImage, toSize: finalRectSize, screenScale: screenScale);
                        }
                    }
                }
                imageToReturn = newImage;
                semaphore.signal();
            }
            offscreenRenderToUse?.imageFor(request: request);
        }

        if(renderBackground) {
            if FTRenderConstants.USE_BG_TILING {
                let content = page.backgroundTextureTiles(scale: scaleWrtNorm, targetRect: finalRect, visibleRect: finalRect)
                if let _content = content {
                    generateImage(bgTexture: nil, backgroundTextureTileContent: _content)
                }
                else {
                    semaphore.signal();
                }
            } else {
                page.backgroundTexture(toFitIn: finalRect) { (_texture) in
                    if let texture = _texture {
                        generateImage(bgTexture: texture, backgroundTextureTileContent: nil)
                    }
                    else {
                        semaphore.signal();
                    }
                }
            }
        }
        else {
            generateImage(bgTexture: nil, backgroundTextureTileContent: nil);
        }

        semaphore.wait();
        if(shouldReleaseOnCompletion) {
            FTRendererProvider.shared.enqueOffscreenRenderer(offscreenRenderToUse);
        }

        onCompletion(imageToReturn, page);
    }
    
    fileprivate static func resizeImage(image : UIImage?, toSize size : CGSize,screenScale : CGFloat) -> UIImage?
    {
        UIGraphicsBeginImageContextWithOptions(size, false, screenScale);
        let context = UIGraphicsGetCurrentContext();
        context?.interpolationQuality = CGInterpolationQuality.high;
        
        let flipVertical = CGAffineTransform.init(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height);
        context?.concatenate(flipVertical);
        
        context?.draw(image!.cgImage!, in: CGRect.init(origin: CGPoint.zero, size: size));
        let newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return newImage;
    }
}

@objc extension FTPDFExportView {
    
    ///Note: We've moved rendering hidden text from Objective-C to Swift, as we faced an issue where emojis are treated as 2 character length, when we try to get the character at index. The logic is now changed to interating through the array of Swift string characters
    func renderRecognizedText(_ context:CGContext) {
        guard let recognisedString = self.pdfPage.recognitionInfo?.recognisedString, let charRects = self.pdfPage.recognitionInfo?.characterRects else {
            return
        }
            #if DEBUG
                //print("Recognized String\n", recognisedString,"\n------------")
            #endif
            
            context.saveGState()
            context.translateBy(x: 0.0, y: self.bounds.size.height)
            context.scaleBy(x: 1.0, y: -1.0)
            var tempChars = [String]();
            var tempRects = [CGRect]();
            
            var words = [String]();
            var rects = [CGRect]();
            
            let charsWithRects = zip(recognisedString, charRects)
            
            for (character, rect) in charsWithRects {
                if rect == charRects.last {
                    tempChars.append(String(character))
                    if rect != .zero && rect != .null {
                        tempRects.append(rect)
                    }
                }
                
                if character == " " || character == "\n" || rect == charRects.last {
                    var finalRect = CGRect.null
                    tempRects.forEach({ rect in
                        finalRect = rect.union(finalRect)
                    })
                    let word = tempChars.joined()
                    words.append(word)
                    rects.append(finalRect)

                    tempRects.removeAll()
                    tempChars.removeAll()
                } else {
                    tempChars.append(String(character))
                    if rect != .zero && rect != .null {
                        tempRects.append(rect)
                    }
                }
            }
            
            let wordsWithRects = zip(words, rects)
            
            for (word,rect) in wordsWithRects {
                var font = UIFont.systemFont(ofSize: 2)
                let textColor = UIColor.init(white: 1.0, alpha: 0.0)
                let attributes = [NSAttributedString.Key.font:font,NSAttributedString.Key.foregroundColor:textColor]
                let attrWord = NSMutableAttributedString(string: word, attributes: attributes)
                for fontSize in 2..<999 {
                    font = UIFont.systemFont(ofSize: CGFloat(fontSize))
                    attrWord.addAttribute(NSAttributedString.Key.font, value: font, range: NSMakeRange(0, word.count))
                    let expectedSize = attrWord.requiredSizeForAttributedStringConStraint(to:CGSize(width: rect.size.width, height: CGFloat(Float.greatestFiniteMagnitude)))
                    
                    if expectedSize.height >= rect.size.height - 5 {
                        font = UIFont.systemFont(ofSize: CGFloat(fontSize-1))
                        attrWord.addAttribute(NSAttributedString.Key.font, value: font, range: NSMakeRange(0, word.count))
                        
                        //Adjust the Kern attribute, to adjust spacing between the characters
                        if word.count > 1 {
                            let currentSize = attrWord.size()
                            var kern = 0
                            while currentSize.width <= rect.size.width {
                                attrWord.addAttribute(NSAttributedString.Key.kern, value: NSNumber(value: kern), range: NSMakeRange(0, word.count))
                                if(attrWord.size().width >= rect.size.width) {
                                    attrWord.addAttribute(NSAttributedString.Key.kern, value: NSNumber(value: kern-1), range: NSMakeRange(0, word.count))
                                    break;
                                }
                                kern += 1
                            }
                        }
                        break
                    }
                }
                #if DEBUG
                    //print(word, rect)
                #endif
                FTPDFExportView.render(attributedString: attrWord, rect: rect, context: context, scale: self.scale)
            }
            context.restoreGState()
    }

    static func renderFooterInfo(image: UIImage, screenScale: CGFloat, title: String, currentPage: Int, totalPages: Int, textColor: UIColor = .black) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(image.size, false, screenScale)
        if let context = UIGraphicsGetCurrentContext() {
            context.interpolationQuality = CGInterpolationQuality.high;
            image.draw(in: CGRect(origin:.zero, size: image.size))
            renderFooterInfo(context: context,
                             isFlipped: false,
                             scale: 1,
                             pageSize: image.size,
                             title: title,
                             currentPage: currentPage,
                             totalPages: totalPages, textColor: textColor)
        }
        let imageToReturn = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext()
        return imageToReturn
    }

    static func renderFooterInfo(context:CGContext,
                                 isFlipped: Bool,
                                 scale: CGFloat,
                                 pageSize: CGSize,
                                 title: String,
                                 currentPage: Int,
                                 totalPages: Int, textColor: UIColor = .black) {

        context.saveGState();
        if isFlipped {
            context.translateBy(x: 0, y: pageSize.height);
            context.scaleBy(x: 1, y: -1);
        }
        let font = UIFont.appFont(for: .regular, with: 12.0)
        let color = textColor.withAlphaComponent(0.5)
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.lineBreakMode = NSLineBreakMode.byTruncatingTail
        let attributes : [NSAttributedString.Key:Any] = [.font : font,
                                                         .foregroundColor: color,
                                                         .paragraphStyle: paraStyle ]
        let titleAttri = NSAttributedString(string: title, attributes: attributes)
        let size = titleAttri.size()
        let y : CGFloat =  pageSize.height - 10 - size.height;
        let width = min(size.width, pageSize.width/2)
        let titleRect = CGRect(x: 10.0, y: y, width: width, height: size.height)
        render(attributedString: titleAttri, rect: titleRect, context: context, scale: scale)

        let pageNum = String(format: NSLocalizedString("NofNAlt", comment: "%d of %d"), currentPage, totalPages);
        let pageNumAttri = NSAttributedString(string: pageNum, attributes: attributes)
        let pageNumSize = pageNumAttri.size()
        let xPageNum = pageSize.width - pageNumSize.width - 10
        let widthPageNum = min(pageNumSize.width, pageSize.width/2)
        let pageNumRect = CGRect(x: xPageNum, y: y, width: widthPageNum, height: pageNumSize.height)
        render(attributedString: pageNumAttri, rect: pageNumRect, context: context, scale: scale)

        context.restoreGState();
    }

    fileprivate static func render(attributedString: NSAttributedString, rect: CGRect, context: CGContext, scale: CGFloat) {

        let textLayouter = FTTextLayouter.init(attributedString: attributedString,
                                               constraints: rect.size);
        context.saveGState();
        context.scaleBy(x: scale, y: scale);

        let drawRect = CGRect.init(origin: rect.origin, size: textLayouter.usedSize)
        textLayouter.drawFlipped(in: context, bounds: drawRect)

        context.restoreGState();

    }
}
