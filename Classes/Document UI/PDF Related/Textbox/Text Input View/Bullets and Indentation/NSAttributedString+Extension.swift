//
//  NSAttributedString_Extension.swift
//  Noteshelf
//
//  Created by Sameer on 15/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

extension NSAttributedString {
    
    class func attributedString(withFormat format: String, arguments args: NSAttributedString ...) -> Self {
        var attributes: [NSAttributedString] = []
        let string = format.replacingOccurrences(of: "%@", with: "")
        let count = ((format.count) - (string.count)) / "%@".count

        for index in 0..<count {
          let argument = args[index]
            attributes.append(argument)
        }

        let attributedString = NSMutableAttributedString(string: format)
        attributedString.beginEditing()

        var range = (format as NSString?)?.range(of: "%@", options: .backwards) ?? NSRange(location: 0, length: 0)
        var index = 0
        while range.location != NSNotFound {
            let attribute = attributes.last
            attributes.removeLast()

            if attribute!.isKind(of: NSAttributedString.self) {
                attributedString.replaceCharacters(in: range, with: attribute!)
            } else {
                attributedString.replaceCharacters(in: range, with: attribute!.description)
            }
            
            range = NSRange(location: 0, length: range.location )
            range = (format as NSString).range(of: "%@", options: .backwards, range: range)
        index += 1
        }
        attributedString.endEditing()
        return self.init(attributedString: attributedString)
    }
    
   func mapAttributesToMatch(withLineHeight lineHeight: CGFloat) -> NSAttributedString? {
        guard let attrStr = self.mutableCopy() as? NSMutableAttributedString else {
            return nil
        }
        attrStr.beginEditing()
        
        let storage = NSTextStorage(attributedString: self)
        storage.enumerateAttributes(
            in: NSRange(location: 0, length: length),
            options: [],
            using: { attrs, range, _ in
                //Font
                let originalFont = attrs[NSAttributedString.Key(rawValue: "NSOriginalFont")] as? UIFont
                if let originalFont = originalFont {
                    attrStr.addAttribute(.font, value: originalFont, range: range)
                }

                let fontValue = attrs[NSAttributedString.Key.font] as? UIFont
                let fontInfo = attribute(.font, at: range.location, effectiveRange: nil) as? UIFont
                if let fontInfo = fontInfo, fontInfo != fontValue {
                    attrStr.addAttribute(NSAttributedString.Key("NSOriginalFont"), value: fontInfo, range: range)
                }
                
                //Paragraph Style
                let value = attrs[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle
                if let value = value, let style = value.mutableCopy() as? NSMutableParagraphStyle {
                    let bulletsList = style.bulletLists
                    if let bulletsList = bulletsList, !bulletsList.isEmpty {
                        var bulletObject: [FTTextList] = []
                        for bullet in bulletsList {
                            let textList = FTTextList.textListWithMarkerFormat(bullet.markerFormat(), option: 0)
                            if (bullet._isOrdered != nil) {
                                textList.startingItemNumber = bullet.startingItemNumber
                            }
                            bulletObject.append(textList)
                       }
                        style.bulletLists = bulletObject
                    }
                    if lineHeight != -1 {
                        style.maximumLineHeight = lineHeight
                        style.minimumLineHeight = lineHeight
                    }
                    attrStr.addAttribute(.paragraphStyle, value: style, range: range)
                    
                }
                
                let attachment = attrs[NSAttributedString.Key.attachment] as? NSTextAttachment
                if let attachment = attachment {
                    attachment.updateFileWrapperIfNeeded()
                    var attachmentBounds = attachment.bounds
                    let some = CGSize(width: CHECKBOX_WIDTH, height: CHECKBOX_HEIGHT)
                    attachmentBounds.size = some
                    attachmentBounds.origin.y = CGFloat(CHECK_BOX_OFFSET_Y)
                    attachment.bounds = attachmentBounds
                    attrStr.addAttribute(.attachment, value: attachment, range: range)
                }
            })
        attrStr.endEditing()
        return attrStr
    }
    
   class func readRTFData(_ value: Data?) -> NSAttributedString? {
        var attributedString: NSAttributedString?
        do {
            if let value = value {
                attributedString = try NSAttributedString(
                    data: value,
                    options: [:],
                    documentAttributes: nil)
            }
        } catch {
        }
        return attributedString
    }

    func containsAttribute(_ attributeName: String?) -> Bool {
        return containsAttribute(attributeName, in: NSRange(location: 0, length: length))
    }
    
    func containsAttribute(_ attributeName: String?, in range: NSRange) -> Bool {
        var position = range.location
        let end = NSMaxRange(range)

        while position < end {
            var effectiveRange = NSRange()
            if attribute(NSAttributedString.Key(attributeName ?? ""), at: position, effectiveRange: &effectiveRange) != nil {
                return true
            }
            position = NSMaxRange(effectiveRange)
        }

        return false
    }
    

   class func attachmentString() -> String {
        var attachmentString: String?
        if attachmentString == nil {
            let c = unichar(NSTextAttachment.character)
            attachmentString = String(c)
        }
        return attachmentString ?? ""
    }
    
   func attributedStringByTrimmingCharacterSet(atTheEnd characterSet: CharacterSet?) -> NSAttributedString? {
        let attributedString = NSMutableAttributedString(attributedString: self)
        var range: NSRange?
        if let characterSet = characterSet {
            range = (attributedString.string as NSString).rangeOfCharacter(from: characterSet, options: .backwards)
        }
        if let newRange = range {
            while newRange.length != 0 && NSMaxRange(newRange) == attributedString.length {
                attributedString.replaceCharacters(
                    in: newRange,
                    with: "")
                if let characterSet = characterSet {
                    range = (attributedString.string as NSString).rangeOfCharacter(from: characterSet, options: .backwards)
                }
            }
        }
        return attributedString
    }
    
    func removeBackgroungColor() -> NSAttributedString? {
        let mutableAttributedString = NSMutableAttributedString(attributedString: self)

        mutableAttributedString.enumerateAttribute(.backgroundColor, in: NSRange(location: 0, length: length), options: .longestEffectiveRangeNotRequired, using: { value, range, stop in
            mutableAttributedString.removeAttribute(.backgroundColor, range: range)
        })

        return mutableAttributedString
    }

    func mutableDeepCopy() -> NSMutableAttributedString {
        let attributedString = NSMutableAttributedString(attributedString: self)
        return attributedString.deepCopy()
    }
    
    func components(separatedBy separator: String) -> [String] {
        var string: String?
        var range: NSRange
        var separatorRange = NSRange()
        var componentRange: NSRange
        var components: [AnyObject]?

        string = self.string
        components = []

        range = NSRange(location: 0, length: string?.count ?? 0)

        repeat {
            if let range1 = (string as NSString?)?.range(of: separator, options: [], range: range) {
                separatorRange = range1
            }
            if separatorRange.length != 0 {
                componentRange = NSRange(location: range.location, length: separatorRange.location - range.location)
                range.length -= NSMaxRange(separatorRange) - range.location
                range.location = NSMaxRange(separatorRange)
            } else {
                componentRange = range
                range.length = 0
            }
            components?.append(attributedSubstring(from: componentRange))
        } while separatorRange.length > 0

        return components as? [String] ?? []
    }
    
    func upperCaseString() -> NSAttributedString? {
        // Make a mutable copy of your input string
        let attrString = NSMutableAttributedString()

        // Make an array to save the attributes in
        var attributes = [String: Any]()

        // Add each set of attributes to the array in a dictionary containing the attributes and range
        attrString.enumerateAttributes(in: NSRange(location: 0, length: attrString.length ), options: [], using: { attrs, range, stop in
            attributes = [
                "attrs": attrs,
                "range": NSValue(range: range)
            ]
        })

        // Make a plain uppercase string
        let string = attrString.string.uppercased()

        // Replace the characters with the uppercase ones
        attrString.replaceCharacters(in: NSRange(location: 0, length: attrString.length ), with: string )
        let value = attributes["range"] as? NSValue
        if let value = value {
            attrString.setAttributes(attributes["attrs"] as? [NSAttributedString.Key : Any], range: value.rangeValue)
        }
        return attrString
    }
    
    func isEqual(toAttributedText other: NSAttributedString?) -> Bool {
        var isEqual = false
        guard let other = other else {
           return isEqual
        }
        isEqual = self.isEqual(to: other)
        if !(isEqual) {
            if length == other.length && (string == other.string) {
                isEqual = true
                enumerateAttributes(in: NSRange(location: 0, length: length), options: [], using: { attrs, range, stop in
                    var effectiveRange = NSRange()
                    let attribtues = other.attributes(at: range.location, effectiveRange: &effectiveRange)
                    if !NSEqualRanges(range, effectiveRange) || !(attrs.keys == attribtues.keys) {
                        isEqual = false
                        stop.pointee = true
                    } else if attrs.keys.contains(NSAttributedString.Key.attachment) {
                        let attachment1 = attrs[.attachment] as? NSTextAttachment
                        attachment1?.updateFileWrapperIfNeeded()
                        let attachment2 = attribtues[.attachment] as? NSTextAttachment
                        attachment2?.updateFileWrapperIfNeeded()
                        let value = attachment1?.fileWrapper?.regularFileContents
                        let otherValue = attachment2?.fileWrapper?.regularFileContents
                        var mutAttrs1 = attrs
                        var mutAttrs2 = attribtues
                        mutAttrs1.removeValue(forKey: .attachment)
                        mutAttrs2.removeValue(forKey: .attachment)
                        if (value != otherValue) || !(mutAttrs1 as NSDictionary).isEqual(mutAttrs2) {
                            isEqual = false
                            stop.pointee = true
                        }
                    } else if !(attrs as NSDictionary).isEqual(attribtues) {
                        isEqual = false
                        stop.pointee = true
                    }
                })
            }
        }
        return isEqual
    }
    
    func rangesOfOccurance(of searchString: String?) -> [AnyObject]? {
        var ranges: [AnyObject] = []
        let stringToSearch = "(\(searchString ?? ""))"

        var regex: NSRegularExpression?
        do {
            regex = try NSRegularExpression(pattern: stringToSearch, options: .caseInsensitive)
        } catch {
        }

        let range = NSRange(location: 0, length: length)

        let string = self.string
        regex?.enumerateMatches(
            in: string,
            options: [],
            range: range,
            using: { result, flags, stop in
                let subStringRange = result?.range(at: 1)
                if let subStringRange = subStringRange {
                    ranges.append(NSValue(range: subStringRange))
                }
            })
        return ranges
    }
    
    func boundsForOccurance(of searchString: String?, containerSize: CGSize, containerInset: UIEdgeInsets) -> [AnyObject]? {
        var boundsArray: [AnyObject] = []
        
        if let ranges = rangesOfOccurance(of: searchString), ranges.count > 0 {
            let storage = NSTextStorage(attributedString: self)
            var containerSizeWithInset = containerSize
            containerSizeWithInset.width = containerSizeWithInset.width - containerInset.left - containerInset.top
            containerSizeWithInset.height = containerSizeWithInset.height - containerInset.top - containerInset.bottom

            let container = NSTextContainer(size: containerSizeWithInset)
            container.lineFragmentPadding = 0
            let layoutManager = NSLayoutManager()
            layoutManager.addTextContainer(container)
            storage.addLayoutManager(layoutManager)

            for eachRange in ranges {
                guard let eachRange = eachRange as? NSValue else {
                    continue
                }
                let glyphRange = layoutManager.glyphRange(forCharacterRange: eachRange.rangeValue, actualCharacterRange: nil)
                var characterBounds = layoutManager.boundingRect(forGlyphRange: glyphRange, in: container)
                characterBounds.origin.x += containerInset.left
                characterBounds.origin.y += containerInset.top
                boundsArray.append(NSValue(cgRect: characterBounds))
            }
        }
        return boundsArray
    }
}
