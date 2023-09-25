//
//  FTCharStrokeRender.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 27/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTCharWrapStrokeRender: FTCharToStrokeRender {
    override func convertTextToStroke(for page: FTPageProtocol, content aiContent: FTAIContent, origin inOrigin: CGPoint, onUpdate: @escaping FTStrokeRenderOnUpdateCallback, onComplete: @escaping FTStrokeRenderOnCompleteCallback) {
        
        let content = (aiContent.contentAttributedString != nil) ? (aiContent.contentAttributedString?.string ?? "") : (aiContent.contentString ?? "")

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
