//
//  String+Extension.swift
//  Noteshelf
//
//  Created by Sameer on 13/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
extension String {

    func ends(with string: String?) -> Bool {
        if (self as NSString).range(of: string ?? "").location == count - (string?.count ?? 0) {
         return true
        } else {
         return false
        }
    }
    #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
    func addLetterSpacing(_ spacing : CGFloat) -> NSAttributedString
    {
        let attr = NSMutableAttributedString.init(string: self, attributes: [NSAttributedString.Key.kern : spacing]);
        return attr;
    }
    func escapedStringForXML() -> String {
        let mutable = NSMutableString(string:self)
        mutable.replaceOccurrences(of: "&",
                                   with: "&amp;",
                                 options: .literal,
                                 range: NSRange(location: 0, length: mutable.length))
        mutable.replaceOccurrences(of: "<",
                                   with: "&lt;",
                                    options: .literal,
                                      range: NSRange(location: 0, length: mutable.length))
        mutable.replaceOccurrences(of: ">",
                                   with: "&gt;",
                                    options: .literal,
                                      range: NSRange(location: 0, length: mutable.length))
        mutable.replaceOccurrences(of: "'",
                                   with: "&#x27;",
                                    options: .literal,
                                      range: NSRange(location: 0, length: mutable.length))
        mutable.replaceOccurrences(of: "\"",
                                   with: "&quot;",
                                    options: .literal,
                                      range: NSRange(location: 0, length: mutable.length))
        return mutable as String
    }

    func unEscapedStringForXML() -> String {
        let mutable = NSMutableString(string:self)
        mutable.replaceOccurrences(of: "&amp;",
                                   with:"&",
                                    options:.literal,
                                      range: NSRange(location: 0, length: mutable.length))
        mutable.replaceOccurrences(of: "&lt;",
                                   with:"<",
                                 options: .literal,
                                      range: NSRange(location: 0, length: mutable.length))
        mutable.replaceOccurrences(of: "&gt;",
                                   with:">",
                                    options:.literal,
                                      range: NSRange(location: 0, length: mutable.length))
        mutable.replaceOccurrences(of: "&#x27;",
                                   with:"'",
                                    options:.literal,
                                      range: NSRange(location: 0, length: mutable.length))
        mutable.replaceOccurrences(of: "&quot;",
                                   with:"\"",
                                    options:.literal,
                                      range: NSRange(location: 0, length: mutable.length))
        return mutable as String
    }


    func pngToJpgResourceExtension() -> String {
        let filenameWithoutExtension = self.deletingPathExtension
        return (filenameWithoutExtension as NSString).appendingPathExtension("jpg") ?? ""
    }


    func retinaResourceName() -> String {
        let filenameWithoutExtension = self.deletingPathExtension
        let fileExtension = self.pathExtension
        return String(format:"%@@2x.%@", filenameWithoutExtension, fileExtension)
    }

    func sizeWithFont(_ font:UIFont) -> CGSize {
        return self.size(withAttributes: [NSAttributedString.Key.font: font])
    }

    func sizeWithFont(_ font:UIFont, constrainedToSize size:CGSize) -> CGSize {
        let boundingRect = self.boundingRect(with: size, options:.usesLineFragmentOrigin, attributes:[NSAttributedString.Key.font: font], context:nil)
        return boundingRect.size
    }

    func sizeWithFont(_ font:UIFont, constrainedToSize size:CGSize, lineBreakMode:NSLineBreakMode) -> CGSize {
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = lineBreakMode
        let boundingRect = self.boundingRect(with: size, options: .usesLineFragmentOrigin, attributes:[NSAttributedString.Key.font: font,NSAttributedString.Key.paragraphStyle:style], context:nil)
        return boundingRect.size
    }

    func drawStringInRect(_ rect:CGRect, withFont font:UIFont, lineBreakMode:NSLineBreakMode, alignment:NSTextAlignment) {
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = lineBreakMode
        style.alignment = alignment
        self.draw(in: rect, withAttributes:[NSAttributedString.Key.font: font,NSAttributedString.Key.paragraphStyle:style])
    }
    #endif
}
