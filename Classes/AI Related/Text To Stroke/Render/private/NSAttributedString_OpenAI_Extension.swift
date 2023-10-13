//
//  NSAttributedString_OpenAI_Extension.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 25/09/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTAttributedStringLine {
    var attributedString: NSAttributedString;
    var range: NSRange;
    
    init(attributedString inStr: NSAttributedString, range inRange: NSRange) {
        attributedString = inStr;
        range = inRange;
    }
}

extension NSAttributedString {
    func lines() -> [FTAttributedStringLine] {
        var lines = [FTAttributedStringLine]();
        var currentIndex = 0
        self.string.enumerateLines { line, stop in
            let lineRange = NSRange(location: currentIndex, length: line.count);
            let lineAttributedString = self.attributedSubstring(from: lineRange)
            let lineRangeAttr = FTAttributedStringLine(attributedString: lineAttributedString, range: lineRange);
            lines.append(lineRangeAttr);
            currentIndex += lineRange.length + 1 // +1 to account for the newline character
        }
        return lines;
    }
    
    func words() -> [NSAttributedString] {
        var words = [NSAttributedString]();
        let text = self.string;
        
        var currentWord = "";
        var charIndex = 0;
        text.forEach { eachChar in
            if let scalevalue = eachChar.unicodeScalars.first {
                if CharacterSet.whitespacesAndNewlines.contains(scalevalue) {
                    if !currentWord.isEmpty {
                        let range = NSRange(location: charIndex, length: currentWord.count);
                        let subString = self.attributedSubstring(from: range);
                        words.append(subString);
                    }
                    charIndex += currentWord.count + 1;
                    currentWord = ""
                }
                else {
                    currentWord.append(eachChar);
                }
            }
        }
        if !currentWord.isEmpty {
            let range = NSRange(location: charIndex, length: currentWord.count);
            let subString = self.attributedSubstring(from: range);
            words.append(subString);
        }
        return words;
    }
    
    var bulletLists: [NSTextList]? {
        if self.length > 0, let attributes = self.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
            ,!attributes.textLists.isEmpty {
            return attributes.textLists;
        }
        return nil;
    }
    
    func trimmingBullets(bulletlist: [NSTextList]) -> (trimmed:NSAttributedString,bulletString:String) {
        var bulletString = bulletlist.last?.marker(forItemNumber: 0) ?? "*";
        let regexPattern = "\t.*\t"
        let attributedStringToReturn = NSMutableAttributedString(attributedString: self)
        if let regex = try? NSRegularExpression(pattern: regexPattern) {
            let inputString = self.string;
            let range = NSRange(inputString.startIndex..<inputString.endIndex, in: inputString)
            let matches = regex.matches(in: inputString, options: [.anchored], range: range);
            matches.forEach { eachMatch in
                bulletString = (inputString as NSString).substring(with: eachMatch.range).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
                bulletString = bulletString.replacingOccurrences(of: ".", with: ")");
                attributedStringToReturn.replaceCharacters(in: eachMatch.range, with: "");
            }
        }
        return (attributedStringToReturn,bulletString);
    }
}

//extension NSAttributedString {
//    func bulletString() -> String? {
//        var bulletString: String?;
//        if let paragraphStyle = self.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
//            ,let textList = paragraphStyle.textLists, let lastList = textList.last {
//            
//            if lastList.isOrdered {
//                
//            }
//            else {
//                bulletString = "*"
//                if textList.count % 2 == 1 {
//                    bulletString = "-"
//                }
//            }
//        }
//        return bulletString;
//    }
//}
