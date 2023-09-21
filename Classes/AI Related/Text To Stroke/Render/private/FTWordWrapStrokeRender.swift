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
                                      , content: FTAIContent
                                      ,origin inOrigin: CGPoint) -> [FTAnnotation] {
        self.updatePageProperties(page);
        var origin = inOrigin;
        let string = (content.contentAttributedString != nil) ? (content.contentAttributedString?.string ?? "") : (content.contentString ?? "")

        string.enumerateLines { line, stop in
            var currentWord: String = "";
            line.forEach { eachChar in
                if(eachChar.isWhitespace) {
                    let wordInfo = FTTextToStrokeDataProvider.sharedInstance.strokeInfoForWord(currentWord);
                    self.drawWord(wordInfo, content: NSAttributedString(string: currentWord),origin: &origin)
                    currentWord = "";
                }
                else {
                    currentWord.append(eachChar);
                }
            }            
            if(!currentWord.isEmpty) {
                let wordInfo = FTTextToStrokeDataProvider.sharedInstance.strokeInfoForWord(currentWord);
                self.drawWord(wordInfo, content: NSAttributedString(string: currentWord), origin: &origin)
                currentWord = ""
            }
            self.gotoNextParagraph(page, origin: &origin);
        }
        return strokesToAdd;
    }
    
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
                currentPage = newPage;
            }
        }
        
        func drawCurrentWord(_ word: NSAttributedString,isLastChar: Bool) {
            if isLastChar {
                debugLog("ente");
            }
            let wordInfo = FTTextToStrokeDataProvider.sharedInstance.strokeInfoForWord(word.string);
            if self.canFixWord(wordInfo, origin: &origin, pageScale: self.pageScale, currentPage: currentPage) {
                self.drawWord(wordInfo, content: word, origin: &origin)
            }
            else {
                _createNewPageIfNeeded(isLastChar);
                self.drawWord(wordInfo, content: word, origin: &origin)
            }
        }
        
        var curindex = -1;
        let lines = aicontent.contentAttributedString?.lines();
        lines?.forEach({ eachLine in
            curindex += 1;
            let words = eachLine.words()
            words.forEach { eachWord in
                curindex = eachWord.length + 1;
                drawCurrentWord(eachWord, isLastChar: (curindex == content.count));
            }
            self.gotoNextParagraph(currentPage, origin: &origin);
            _createNewPageIfNeeded(curindex == content.count);
        });
        if !self.strokesToAdd.isEmpty {
            _ = onUpdate(self.strokesToAdd,currentPage,false);
        }
        
        onComplete();
    }

    private func drawWord(_ wordInfo: FTWordStrokeInfo
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

extension NSAttributedString {
    func lines() -> [NSAttributedString] {
        var lines = [NSAttributedString]();
        var currentIndex = 0
        self.string.enumerateLines { line, stop in
            let lineRange = NSRange(location: currentIndex, length: line.count);
            let lineAttributedString = self.attributedSubstring(from: lineRange)
            lines.append(lineAttributedString);
            currentIndex += lineRange.length + 1 // +1 to account for the newline character
        }
        return lines;
    }
    
    func words() -> [NSAttributedString] {
        var words = [NSAttributedString]();
        let text = self.string;

        let range = text.startIndex ..< text.endIndex
        
        text.enumerateSubstrings(in: range
                                 , options: .byWords) { substring, substringRange, enclosingRange, stop in
            if let _substring = substring {
                debugPrint("tokenRange: \(substringRange) _substring: \(_substring)")
                let sub = self.attributedSubstring(from: NSRange(substringRange, in: text));
                debugPrint("word: \(sub)");
                if sub.length > 0 {
                    words.append(sub)
                }
            }
        }
        return words;
    }
}
