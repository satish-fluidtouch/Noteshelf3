//
//  FTOpenAiResponse.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 04/10/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

private let htmResponseStyle = "<style>body{ font-family: 'Helvetica Neue', sans-serif} h1{ color: #D07459; font-size: 26px; font-weight: 700;} h2{ color: #52A7A7; font-size: 22px; font-weight: 700;} h3{ color: #EBAE24; font-size: 22px; font-weight: 700;} h4{ color: #8D59C1; font-size: 20px; font-weight: 500;} h5{ color: #000000; font-size: 18px; font-weight: 700;} h6{ color: #000000; font-size: 18px; font-weight: 500;} p{ font-size: 18px; font-weight: 400;} ol{ padding-top: 50px; margin: 0px;} li{padding:-40px; margin: 0px; font-size: 18px;} ol li{ list-style-type: decimal;} ol ol li{ list-style-type: lower-alpha;} ol ol ol li{ list-style-type: decimal;} ol ol ol ol li{ list-style-type: lower-alpha;} ol ol ol ol ol li{ list-style-type: decimal;} ol ol ol ol ol ol ol li{ list-style-type: lower-alpha;} ol ol ol ol ol ol ol ol li{ list-style-type: decimal;} ol ol ol ol ol ol ol ol ol li{ list-style-type: lower-alpha;} ol ol ol ol ol ol ol ol ol ol li{ list-style-type: decimal;} ol ol ol ol ol ol ol ol ol ol ol li{ list-style-type: lower-alpha;}</style>";

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
            attrString.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: attrString.length)) { color, effectedRange, stop in
                if let fgColor = color as? UIColor, fgColor.hexString == self.blackHexColor {
                    attrString.addAttribute(.foregroundColor, value: UIColor.label, range: effectedRange);
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
}
