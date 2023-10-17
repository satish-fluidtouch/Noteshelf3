//
//  FTOpenAiResponse.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 04/10/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

private let htmResponseStyle = """
<style> 
body{ font-family: 'Helvetica Neue', sans-serif}
h1{ color: #D07459; font-size: 26px; font-weight: 700;}
h2{ color: #52A7A7; font-size: 22px; font-weight: 700;} 
h3{ color: #EBAE24; font-size: 22px; font-weight: 700;}
h4{ color: #8D59C1; font-size: 20px; font-weight: 500;}
h5{ color: #000000; font-size: 18px; font-weight: 700;}
h6{ color: #000000; font-size: 18px; font-weight: 500;}
p{ font-size: 18px; font-weight: 400;}
ol{ padding-top: 50px; margin: 0px;}
li{padding:-40px; margin: 0px; font-size: 18px;}
ol li{ list-style-type: decimal;}
ol ol li{ list-style-type: upper-alpha;}
ol ol ol li{ list-style-type: decimal;}
ol ol ol ol li{ list-style-type: upper-alpha;}
ol ol ol ol ol li{ list-style-type: decimal;}
ol ol ol ol ol ol ol li{ list-style-type: upper-alpha;}
ol ol ol ol ol ol ol ol li{ list-style-type: decimal;}
ol ol ol ol ol ol ol ol ol li{ list-style-type: upper-alpha;}
ol ol ol ol ol ol ol ol ol ol li{ list-style-type: decimal;}
ol ol ol ol ol ol ol ol ol ol ol li{ list-style-type: upper-alpha;}
</style>
""";

class FTOpenAIResponse: NSObject {
    private(set) var attributedString = NSAttributedString();
    private var htmlFormat = "";
    private var stringResponse = "";
    private var blackHexColor = UIColor.black.hexString;
    
    func appendHtmlResponse(_ htmlDelta: String) {
        self.htmlFormat.append(htmlDelta);    
        self.updateAttributedString();
    }
    
    func appendStringRessponse(_ response: String) {
        stringResponse.append(response);
        self.attributedString = NSMutableAttributedString(string: stringResponse, attributes: [.font: UIFont.systemFont(ofSize: 18),.foregroundColor : UIColor.label])
    }
    
    private func updateAttributedString() {
        let htmlContent = htmResponseStyle.appending(self.htmlFormat);
        if let data = htmlContent.data(using: .unicode)
            , let attrString = try? NSMutableAttributedString(data: data, options: [.documentType : NSAttributedString.DocumentType.html], documentAttributes: nil) {
            attrString.beginEditing();
            attrString.enumerateAttributes(in: NSRange(location: 0, length: attrString.length)) { attribues, effectedRange, stop in
                if let fgColor = attribues[.foregroundColor] as? UIColor,fgColor.hexString == self.blackHexColor {
                    attrString.addAttribute(.foregroundColor, value: UIColor.label, range: effectedRange);
                }
                if nil == attribues[.font] as? UIFont {
                    attrString.addAttribute(.font, value: UIFont.systemFont(ofSize: 18), range: effectedRange);
                }
                if let font = attribues[.font] as? UIFont, font.pointSize < 18 {
                    let newFont = font.withSize(18);
                    attrString.addAttribute(.font, value: newFont, range: effectedRange);
                }
                if let paragraphStyle = attribues[.paragraphStyle] as? NSParagraphStyle
                    ,paragraphStyle.hasBullet()
                    , let lastBullet = paragraphStyle.bulletLists?.last as? NSTextList {
                    let mutParagraph = self.mappedParagraphStyleForBullets(paragraphStyle);
                    attrString.addAttribute(.paragraphStyle, value: mutParagraph, range: effectedRange);
                    if !lastBullet.isOrdered
                        ,let newLastBullet = mutParagraph.bulletLists?.last as? NSTextList
                        , lastBullet.markerFormat != newLastBullet.markerFormat {
                        let oldBulletString = lastBullet.marker(forItemNumber: lastBullet.startingItemNumber);
                        let newBulletString = newLastBullet.marker(forItemNumber: newLastBullet.startingItemNumber);
                        
                        let subString = attrString.attributedSubstring(from: effectedRange);
                        if let ranges = subString.rangesOfOccurance(of: "\t\(oldBulletString)\t") as? [NSValue] {
                            ranges.forEach { eachrange in
                                var range = eachrange.rangeValue;
                                range.location += effectedRange.location;
                                attrString.replaceCharacters(in: range, with: "\t\(newBulletString)\t")
                            }
                        }
                    }
                }
            }
            attrString.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: attrString.length), options: .reverse) { value, effRange, stop in
                if let paragraphStyle = value as? NSParagraphStyle, !(paragraphStyle.bulletLists?.isEmpty ?? true) {
                    let maxRange = NSMaxRange(effRange);
                    if attrString.length > maxRange {
                        if let attribute = attrString.attribute(.paragraphStyle, at: maxRange, effectiveRange: nil) as? NSParagraphStyle, (attribute.bulletLists?.isEmpty ?? true) {
                            let string = attrString.attributedSubstring(from: NSRange(location: maxRange, length: 1));
                            if string.string != "\n" {
                                let attributes = attrString.attributes(at: maxRange, longestEffectiveRange: nil, in: NSRange(location: 0, length: attrString.length));
                                attrString.insert(NSAttributedString(string: "\n", attributes: attributes), at: maxRange);
                            }
                        }
                    }
                }
            }
            attrString.endEditing();
            self.attributedString = attrString;
        }
    }
    
    private func mappedParagraphStyleForBullets(_ paragraphStyle: NSParagraphStyle) -> NSParagraphStyle {
        if let bulletList = paragraphStyle.bulletLists as? [NSTextList]
            , let mutParagraph = paragraphStyle.mutableCopy() as? NSMutableParagraphStyle {
            var newBulletList = [NSTextList]();
            bulletList.enumerated().forEach { eachItem in
                let textList = eachItem.element;
                let index = eachItem.offset;
                
                if !textList.isOrdered {
                    let newTab: NSTextList
                    if index % 2 == 0 {
                        newTab = NSTextList(markerFormat: .disc, startingItemNumber: textList.startingItemNumber);
                    }
                    else {
                        newTab = NSTextList(markerFormat: .hyphen, startingItemNumber: textList.startingItemNumber);
                    }
                    newBulletList.append(newTab)
                }
                else {
                    newBulletList.append(textList)
                }
            }
            mutParagraph.textLists = newBulletList;
            mutParagraph.headIndent = indentOffset * bulletList.count.toCGFloat()
            mutParagraph.firstLineHeadIndent = indentOffset * (bulletList.count.toCGFloat()-1);
            return mutParagraph;
        }
        return paragraphStyle;
    }
}
