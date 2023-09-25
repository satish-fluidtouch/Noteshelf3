//
//  FTWordStrokeRender.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 27/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTWordWrapStrokeRender: FTCharToStrokeRender {
    private var xMargin: CGFloat = 0;
    override func convertTextToStroke(for page: FTPageProtocol
                                      ,content aicontent: FTAIContent
                                      , origin inOrigin: CGPoint
                                      , onUpdate: @escaping FTStrokeRenderOnUpdateCallback
                                      , onComplete: @escaping FTStrokeRenderOnCompleteCallback) {
        self.updatePageProperties(page);
        var origin = inOrigin;
        let content = (aicontent.contentAttributedString != nil) ? (aicontent.contentAttributedString?.string ?? "") : (aicontent.contentString ?? "")

        var currentPage = page;
        func _createNewPageIfNeeded(_ isLastChar: Bool) {
            if let newPage = self.createNewPageIfNeeded(origin: &origin
                                                        , isLastChar: isLastChar
                                                        , currentPage: currentPage
                                                        , createPageCallBack: onUpdate) {
                if self.xMargin != 0 {
                    origin.x = self.xMargin;
                }
                currentPage = newPage;
            }
        }
        
        func drawCurrentWord(_ word: NSAttributedString,isLastChar: Bool) {
            let wordInfo = FTTextToStrokeDataProvider.sharedInstance.strokeInfoForWord(word.string);
            if self.canFitWord(wordInfo, origin: &origin, pageScale: self.pageScale, currentPage: currentPage) {
                self.drawWord(wordInfo, content: word, origin: &origin)
            }
            else {
                _createNewPageIfNeeded(isLastChar);
                self.drawWord(wordInfo, content: word, origin: &origin)
            }
        }
        
        var currentLineCounter = 0;
        if let lines = aicontent.contentAttributedString?.lines() {
            lines.forEach({ eachLineRange in
                let eachLine = eachLineRange.attributedString;
                currentLineCounter += 1;
                self.xMargin = 0;
                var currentLine = eachLine;
                if let bulletList = eachLine.bulletLists,let bullet = bulletList.last {
                    let trimmedEntries = eachLine.trimmingBullets(bulletlist: bulletList);
                    currentLine = trimmedEntries.trimmed;
                    var bulletString = trimmedEntries.bulletString;
                    if !bullet.isOrdered {
                        if bulletList.count % 2 == 0 {
                            bulletString = "-";
                        }
                    }
                    drawCurrentWord(NSAttributedString(string: bulletString), isLastChar: false);
                    self.xMargin = origin.x;
                }
                let words = currentLine.words()
                let isLastLine = currentLineCounter == lines.count;
                var isLastWord = false;
                var currentWordCounter = 0;

                words.forEach { eachWord in
                    currentWordCounter += 1;
                    isLastWord = currentWordCounter == words.count;
                    drawCurrentWord(eachWord, isLastChar: (isLastLine && isLastWord));
                }
                
                self.gotoNextParagraph(currentPage, origin: &origin);
                _createNewPageIfNeeded((isLastLine && isLastWord));
            });
        }
        if !self.strokesToAdd.isEmpty {
            _ = onUpdate(self.strokesToAdd,currentPage,false);
        }
        
        onComplete();
    }

    override var lineSpacing: CGFloat {
        return 2;
    }
}

private extension FTWordWrapStrokeRender {
    func drawWord(_ wordInfo: FTWordStrokeInfo
                          , content: NSAttributedString
                          , origin: inout CGPoint) {
        wordInfo.wordStrokesInfo.forEach { strokesInfo in
            let info = self.drawStroke(strokesInfo: strokesInfo, word: content,origin: &origin);
            strokesToAdd.append(contentsOf: info.strokes);
        }
        if !wordInfo.wordStrokesInfo.isEmpty {
            origin.x += FTTextToStrokeProperties.spaceCharWidth;
        }
    }
    
    func canFitWord(_ wordInfo: FTWordStrokeInfo
                            , origin: inout CGPoint
                            ,pageScale: CGFloat
                            ,currentPage: FTPageProtocol) -> Bool {
        let scaledGlyphWidth = wordInfo.glyphWidth * pageScale;
        let maxWordWidth = scaledGlyphWidth; //scaledWordRect.width
        
        let rightMargin = currentPage.pageRightMargin;
        
        if((self.pageRect.width - rightMargin) < (origin.x + maxWordWidth)) {
            gotoNextLine(currentPage, origin: &origin);
            if self.xMargin != 0 {
                origin.x = self.xMargin;
            }
        }
        return !currentPage.isAtTheEndOfPage(origin)
    }
}

/*
var effectiveRange: NSRange = NSRange(location: NSNotFound, length: 0);
eachLineRange.attributedString.attribute(.paragraphStyle, at: eachLineRange.range.location, effectiveRange: &effectiveRange);
*/
