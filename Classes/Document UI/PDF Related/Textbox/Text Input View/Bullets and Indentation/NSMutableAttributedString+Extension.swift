//
//  NSMutableAttributedString+Extension.swift
//  Noteshelf
//
//  Created by Sameer on 15/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

extension NSMutableAttributedString {
    
    func applyScale(_ scale: CGFloat, originalScaleToApply originalScale: CGFloat) {
        self.beginEditing()
        enumerateAttributes(in: NSRange(location: 0, length: length), options: [], using: { attrs, range, _ in
            //Font
            var font = attrs[NSAttributedString.Key.font] as? UIFont
            let originalFont = attrs[NSAttributedString.Key(rawValue: "NSOriginalFont")] as? UIFont
            if let originalFont = originalFont {
                if let originalScaledFont = UIFont(name: originalFont.fontName, size: originalFont.pointSize * scale) {
                    self.addAttribute(NSAttributedString.Key("NSOriginalFont"), value: originalScaledFont, range: range)
                    font = originalFont
                }
            }
            if let font = font, let scaleFont = UIFont(name: font.fontName, size: font.pointSize * scale)  {
                self.addAttribute(.font, value: scaleFont, range: range)
            }
            
            //Pragraph style
            let paragraphStyle = attrs[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle
            if let style = paragraphStyle?.mutableCopy() as? NSMutableParagraphStyle {
                let defaultParagraphStyle = NSParagraphStyle.default

                style.maximumLineHeight *= scale
                style.minimumLineHeight *= scale
                style.firstLineHeadIndent *= scale
                style.headIndent *= scale
                if style.hasBullet() {
                    style.defaultTabInterval = 2 * indentOffset * originalScale
                      let originalTabStops = defaultParagraphStyle.tabStops
                      var tabs: [NSTextTab] = []
                      var index = 0
                      for eachTab in originalTabStops {
                          let tab = NSTextTab(textAlignment: eachTab.alignment, location: indentOffset * originalScale * CGFloat(index), options: eachTab.options)
                          index += 1
                          tabs.append(tab)
                      }
                    style.tabStops = tabs
                } else {
                    let originalTabStops = defaultParagraphStyle.tabStops
                    var tabs: [NSTextTab] = []
                    for eachTab in originalTabStops {
                        let tab = NSTextTab(textAlignment: eachTab.alignment, location: eachTab.location * originalScale, options: eachTab.options)
                        tabs.append(tab)
                    }
                    style.tabStops = tabs
                }
                addAttribute(.paragraphStyle, value: style, range: range)
            }
            //Text Attachment
            let attachment = attrs[NSAttributedString.Key.attachment] as? NSTextAttachment
            if let attachment = attachment {
                attachment.updateFileWrapperIfNeeded()
                var attachmentBounds = attachment.bounds
                attachmentBounds.size = CGSize(width: CHECKBOX_WIDTH, height: CHECKBOX_HEIGHT)
                attachmentBounds.origin.y = CGFloat(CHECK_BOX_OFFSET_Y)

                attachment.bounds = CGRectScale(attachmentBounds, originalScale)
                self.addAttribute(.attachment, value: attachment, range: range)
            }
        })
        self.endEditing()
    }
    
    func textStorageByTrimmingCharacterSet(atTheEnd characterSet: CharacterSet?) {
        if let characterSet = characterSet {
            let string = (self.string) as NSString
            var range = string.rangeOfCharacter(from: characterSet, options: .backwards)
            while range.length != 0 && NSMaxRange(range) == length {
                self.replaceCharacters(in: range, with: "")
                range = string.rangeOfCharacter(from: characterSet, options: .backwards)
            }
        }
    }
    
    func deepCopy() -> NSMutableAttributedString {
        guard let mutableString = self.mutableCopy() as? NSMutableAttributedString else {
            return self
        }
        mutableString.beginEditing()
        mutableString.enumerateAttribute(
            .attachment,
            in: NSRange(location: 0, length: self.length),
            options: [],
            using: { attachment, range, _ in
                if let attachment = attachment as? NSTextAttachment {
                    let newAttachment = NSTextAttachment(data: (attachment as AnyObject).contents, ofType: attachment.fileType)
                    newAttachment.image = attachment.image
                    newAttachment.bounds = CGRect(x: 0, y: CHECK_BOX_OFFSET_Y, width: CHECKBOX_WIDTH, height: CHECKBOX_HEIGHT)
                    attachment.updateFileWrapperIfNeeded()

                    if newAttachment.image == nil {
                        var wrapper: FileWrapper?
                        if let regularFileContents = (attachment as AnyObject).fileWrapper?.regularFileContents {
                            wrapper = FileWrapper(regularFileWithContents: regularFileContents)
                        }
                        wrapper?.preferredFilename = "Attachment.png"
                        newAttachment.fileWrapper = wrapper
                    }
                    newAttachment.updateFileWrapperIfNeeded()
                    mutableString.addAttribute(.attachment, value: newAttachment, range: range)
                }
            })
        mutableString.endEditing()
        return mutableString
    }
    
    func getFormattedAttributedStringFrom(style: FTTextStyleItem, defaultFont: CGFloat? = nil) -> NSMutableAttributedString{
        let range = NSRange(location: 0, length: self.length)
       
        var fontSize = defaultFont == nil ? CGFloat(style.fontSize) : defaultFont ?? 16
        if fontSize > 30 {
            fontSize = 30
        }
        if let font = UIFont(name: style.fontName, size: fontSize) {
            self.addAttribute(.font, value: font, range: range)
        }
       
        let color = UIColor.appColor(.black1)
        self.addAttribute(.foregroundColor, value: color, range: range)
       
        if style.isUnderLined {
            self.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        } else {
            self.addAttribute(.underlineStyle, value: 0, range: range)
        }
        
        if style.strikeThrough {
            self.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: range)
            self.addAttribute(.strikethroughColor, value: color, range: range)
        } else {
            self.addAttribute(.strikethroughStyle, value: 0, range: range)
        }
        return self
    }
}
