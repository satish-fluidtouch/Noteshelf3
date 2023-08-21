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
                    let wordInfo = FTTextToStrokeDataProvider.sharedInstance.strokeInfoForWord(currentWord);
                    self.drawWord(wordInfo, origin: &origin)
                    currentWord = "";
                }
                else {
                    currentWord.append(eachChar);
                }
            }            
            if(!currentWord.isEmpty) {
                let wordInfo = FTTextToStrokeDataProvider.sharedInstance.strokeInfoForWord(currentWord);
                self.drawWord(wordInfo, origin: &origin)
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
        
        func drawCurrentWord(_ word: String,isLastChar: Bool) {
            if isLastChar {
                debugLog("ente");
            }
            let wordInfo = FTTextToStrokeDataProvider.sharedInstance.strokeInfoForWord(word);
            if self.canFixWord(wordInfo, origin: &origin, pageScale: self.pageScale, currentPage: currentPage) {
                self.drawWord(wordInfo, origin: &origin)
            }
            else {
                _createNewPageIfNeeded(isLastChar);
                self.drawWord(wordInfo, origin: &origin)
            }
        }
        var curindex = -1;
        content.enumerateLines { line, stop in
            curindex += 1;
            var currentWord: String = "";
            line.forEach { eachChar in
                curindex += 1;
                if(eachChar.isWhitespace) {
                    drawCurrentWord(currentWord, isLastChar: (curindex == content.count));
                    currentWord = "";
                }
                else {
                    currentWord.append(eachChar);
                }
            }
            if !currentWord.isEmpty {
                drawCurrentWord(currentWord, isLastChar: (curindex == content.count));
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

    private func drawWord(_ wordInfo: FTWordStrokeInfo
                          , origin: inout CGPoint) {
        wordInfo.wordStrokesInfo.forEach { strokesInfo in
            let info = self.drawStroke(strokesInfo: strokesInfo, origin: &origin);
            strokesToAdd.append(contentsOf: info.strokes);
        }
        origin.x += FTTextToStrokeProperties.spaceCharWidth;
    }
    
    private func canFixWord(_ wordInfo: FTWordStrokeInfo
                            , origin: inout CGPoint
                            ,pageScale: CGFloat
                            ,currentPage: FTPageProtocol) -> Bool {
        let scaledGlyphWidth = wordInfo.glyphWidth * pageScale;
        let maxWordWidth = scaledGlyphWidth; //scaledWordRect.width
        
        let rightMargin = currentPage.pageRightMargin;
        
        if((self.pageRect.width - rightMargin) < (origin.x + maxWordWidth)) {
            gotoNextLine(currentPage, origin: &origin);
        }
        return !currentPage.isAtTheEndOfPage(origin)
    }
}
