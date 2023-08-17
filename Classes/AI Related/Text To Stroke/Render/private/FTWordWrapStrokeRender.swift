//
//  FTWordStrokeRender.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 27/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTWordWrapStrokeRender: FTCharToStrokeRender {
    override func convertTextToStroke(for page: FTPageProtocol
                                      , string: String
                                      ,origin inOrigin: CGPoint) -> [FTAnnotation] {
        self.updatePageProperties(page);
        var origin = inOrigin;

        string.enumerateLines { line, stop in
            var currentWord: String = "";
            line.forEach { eachChar in
                if(eachChar.isWhitespace) {
                    self.drawWord(currentWord, origin: &origin, pageScale: self.pageScale,currentPage: page);
                    currentWord = "";
                }
                else {
                    currentWord.append(eachChar);
                }
            }            
            if(!currentWord.isEmpty) {
                self.drawWord(currentWord, origin: &origin, pageScale: self.pageScale,currentPage: page);
                currentWord = ""
            }
            self.gotoNextParagraph(page, origin: &origin);
        }
        return strokesToAdd;
    }
    
    override func convertTextToStroke(for page: FTPageProtocol
                                      ,content: String
                                      , origin inOrigin: CGPoint
                                      , onUpdate: @escaping FTStrokeRenderOnUpdateCallback
                                      , onComplete: @escaping FTStrokeRenderOnCompleteCallback) {
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
        
        content.enumerateLines { line, stop in
            var currentWord: String = "";
            line.forEach { eachChar in
                if(eachChar.isWhitespace) {
                    self.drawWord(currentWord, origin: &origin, pageScale: self.pageScale,currentPage: currentPage);
                    currentWord = "";
                    _createNewPageIfNeeded(eachChar == content.last);
                }
                else {
                    currentWord.append(eachChar);
                }
            }
            if(!currentWord.isEmpty) {
                self.drawWord(currentWord, origin: &origin, pageScale: self.pageScale,currentPage: currentPage);
                currentWord = ""
            }
            self.gotoNextParagraph(currentPage, origin: &origin);
            _createNewPageIfNeeded(content.last == currentWord.last);
        }
        
        if !self.strokesToAdd.isEmpty {
            _ = onUpdate(self.strokesToAdd,currentPage,false);
        }
        
        onComplete();
    }

    private func drawWord(_ word: String
                          , origin: inout CGPoint
                          ,pageScale: CGFloat
                          ,currentPage: FTPageProtocol) {
        let wordInfo = FTTextToStrokeDataProvider.sharedInstance.strokeInfoForWord(word);
        let scaledGlyphWidth = wordInfo.glyphWidth * pageScale;
        let maxWordWidth = scaledGlyphWidth; //scaledWordRect.width
        
        let leftmargin = currentPage.pageLeftMargin;
        let rightMargin = currentPage.pageRightMargin;
        
        if((self.pageRect.width - rightMargin) < (origin.x + maxWordWidth)) {
            gotoNextLine(currentPage, origin: &origin);
        }
        wordInfo.wordStrokesInfo.forEach { strokesInfo in
            let info = self.drawStroke(strokesInfo: strokesInfo, origin: &origin);
            strokesToAdd.append(contentsOf: info.strokes);
        }
        origin.x += FTTextToStrokeProperties.spaceCharWidth;
    }
}
