//
//  FTCharStrokeRender.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 27/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTCharWrapStrokeRender: FTCharToStrokeRender {
    override func convertTextToStroke(for page: FTPageProtocol, string: String,origin inOrigin: CGPoint) -> [FTAnnotation] {
        self.updatePageProperties(page);

        var origin = inOrigin;
        string.forEach { eachChar in
            if(eachChar.isNewline) {
                gotoNextParagraph(page, origin: &origin);
            }
            else if(eachChar.isWhitespace) {
                origin.x += FTTextToStrokeProperties.spaceCharWidth;
            }
            else if let strokesInfo = FTTextToStrokeDataProvider.sharedInstance.strokeInfo(for: eachChar) {
                let strokeFontInfo = strokesInfo.glyphInfo.scaledInfo(pageScale);
                let maxWidth = strokeFontInfo.width * pageScale;
                
                if((self.pageRect.width - FTTextToStrokeProperties.leftMargin) < (origin.x + maxWidth)) {
                    origin = CGPoint(x: FTTextToStrokeProperties.leftMargin, y: origin.y + self.lineHeight);
                }
                let info = self.drawStroke(strokesInfo: strokesInfo, origin: &origin);
                self.strokesToAdd.append(contentsOf: info.strokes);
            }
        }
        return self.strokesToAdd;
    }
    
    override func convertTextToStroke(for page: FTPageProtocol, content: String, origin inOrigin: CGPoint, onUpdate: @escaping FTStrokeRenderOnUpdateCallback, onComplete: @escaping FTStrokeRenderOnCompleteCallback) {
        
        self.updatePageProperties(page);
        var origin = inOrigin;
        var currentPage = page;
        
        func _createNewPageIfNeeded(_ isLastChar: Bool) {
            if let newPage = self.createNewPageIfNeeded(origin: &origin
                                                        , isLastChar: isLastChar
                                                        , currentPage: currentPage
                                                        , createPageCallBack: onUpdate) {
                currentPage = newPage;
            }
        }
        
        content.forEach { eachChar in
            if(eachChar.isNewline) {
                gotoNextParagraph(page, origin: &origin);
                _createNewPageIfNeeded(content.last == eachChar);
            }
            else if(eachChar.isWhitespace) {
                origin.x += FTTextToStrokeProperties.spaceCharWidth;
            }
            else if let strokesInfo = FTTextToStrokeDataProvider.sharedInstance.strokeInfo(for: eachChar) {
                let strokeFontInfo = strokesInfo.glyphInfo.scaledInfo(pageScale);
                let maxWidth = strokeFontInfo.width * pageScale;
                
                if((self.pageRect.width - FTTextToStrokeProperties.leftMargin) < (origin.x + maxWidth)) {
                    gotoNextLine(page, origin: &origin);
                }
                let info = self.drawStroke(strokesInfo: strokesInfo, origin: &origin);
                self.strokesToAdd.append(contentsOf: info.strokes);
                _createNewPageIfNeeded(content.last == eachChar);
            }
        }
        if !self.strokesToAdd.isEmpty {
            _ = onUpdate(self.strokesToAdd,currentPage,false);
        }
        onComplete();
    }
}

//TODO: UNUSED WILL BE REMOVED LATER
private class FTCharWrapRender: FTCharWrapStrokeRender {
    override func convertTextToStroke(for page: FTPageProtocol, string: String,origin inOrigin: CGPoint)  -> [FTAnnotation] {
        self.updatePageProperties(page);
        var origin = inOrigin;
        
        string.forEach { eachChar in
            if(eachChar.isNewline) {
                gotoNextParagraph(page, origin: &origin);
            }
            else if(eachChar.isWhitespace) {
                origin.x += FTTextToStrokeProperties.spaceCharWidth;
            }
            else if let strokesInfo = FTTextToStrokeDataProvider.sharedInstance.strokeInfo(for: eachChar) {
                let strokeFontInfo = strokesInfo.glyphInfo.scaledInfo(pageScale);
                
                let initialStrokeUnionRect = strokesInfo.strokeBoundingRect;
                let strokes = strokesInfo.strokes;
                self.strokesToAdd.append(contentsOf: strokes);
                
                let scaledUnionRect = CGRectScale(initialStrokeUnionRect, pageScale);
                if((self.pageRect.width - FTTextToStrokeProperties.leftMargin) < (origin.x + scaledUnionRect.width)) {
                    gotoNextLine(page, origin: &origin);
                }
                var dx = origin.x - initialStrokeUnionRect.origin.x;
                let offsetwidth: CGFloat = (scaledUnionRect.width - strokeFontInfo.fontWidth);
                
                let strokeOffsetX: CGFloat = strokeFontInfo.lsb;
                let originXToConsider = origin.x + strokeOffsetX - offsetwidth;
                dx = originXToConsider - initialStrokeUnionRect.origin.x;
                
                let strokeOffsetY = strokeFontInfo.y;
                let originToConsider = origin.y + (scaledUnionRect.origin.y - strokeOffsetY);
                let dy = originToConsider - initialStrokeUnionRect.origin.y;
                
                var rectOnAdd: CGRect = .null;
                strokes.forEach { eachStroke in
                    let boundingRect = eachStroke.boundingRect;
                    
                    let xOffsetfromref:CGFloat = (boundingRect.minX - initialStrokeUnionRect.minX)*(pageScale-1);
                    let yOffsetfromref:CGFloat = (boundingRect.minY - initialStrokeUnionRect.minY)*(pageScale-1);
                    eachStroke.apply(pageScale)
                    
                    let offset = CGPoint(x:dx+xOffsetfromref, y:dy+yOffsetfromref);
                    eachStroke.setOffset(offset)
                    
                    rectOnAdd = rectOnAdd.union(eachStroke.boundingRect);
                }
                origin.x += (strokeFontInfo.width + offsetwidth);
            }
        }
        return self.strokesToAdd;
    }
}
