//
//  UITextViewBulletsAndIndentation+Extension.swift
//  Noteshelf
//
//  Created by Sameer on 15/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

extension UITextView {
// MARK: Typing Attributes
    func setValue(_ value: Any?, forAttribute attr: String, in range: NSRange) {
        if range.length == 0 {
            updateTypingAttributes(withValue: value, forAttribute: attr)
            return
        }
        // Might be a scaling text storage.
        textStorage.beginEditing()
        if let value = value {
            textStorage.addAttribute(NSAttributedString.Key(attr), value: value, range: range)
        } else {
            textStorage.removeAttribute(NSAttributedString.Key(attr), range: range)
        }

        textStorage.endEditing()
    }
    
    func updateTypingAttributes(withValue value: Any?, forAttribute attr: String) {
        var attributes = typingAttributes
        if let value = value {
            attributes[NSAttributedString.Key(rawValue: attr)] = value
        } else {
            attributes.removeValue(forKey: NSAttributedString.Key(rawValue: attr))
        }
        typingAttributes = attributes
    }

    func currentTypingAttributes(atLocation location: Int, stringLine: String) -> [AnyHashable : Any]? {
        var typingAttributes = self.typingAttributes
        if location < (textStorage.length ) {
            if (stringLine.count) != 0 {
                typingAttributes = textStorage.attributes(at: location, effectiveRange: nil)
            }
        }
        let originalFont = typingAttributes[NSAttributedString.Key("NSOriginalFont")] as? UIFont
        if let originalFont = originalFont {
            typingAttributes[.font] = originalFont
        }
        return typingAttributes
    }
    
    // MARK: Helpers
    func paragraphStyle(atLocation location: Int) -> NSParagraphStyle? {
        var style = typingAttributes[.paragraphStyle] as? NSParagraphStyle
        if (textStorage.length) > location {
            style = textStorage.attribute(.paragraphStyle, at: location, effectiveRange: nil) as? NSParagraphStyle
        }
        return style
    }

    func paragraphRange(for editingRange: NSRange) -> NSRange {
        let range = (textStorage.string as NSString?)?.paragraphRange(for: editingRange)
        return range!
    }

    func paragraphStyle(for editingRange: NSRange) -> NSParagraphStyle? {
        let range = paragraphRange(for: editingRange)
        let style = paragraphStyle(atLocation: range.location)
        return style
    }
    
    func linesOfString(in range: NSRange) -> [String]? {
        let lines = (textStorage.string as NSString?)?.substring(with: range)
        let numberOflines = lines?.components(separatedBy: CharacterSet.newlines)
        return numberOflines
    }

    func linesOfString(in range: NSRange,effectiveRange: NSRangePointer) -> [String]? {
        var paragraphRange = self.paragraphRange(for: range)
        var string = (textStorage.string as NSString).substring(with: paragraphRange)
        if let trimmedString = string.trimmingTrailingCharacters(in: CharacterSet.newlines) {
            string = trimmedString
        }

        let paragraphLength = string.count
        paragraphRange.length = paragraphLength

        let numberOflines = linesOfString(in: paragraphRange)
        effectiveRange.pointee.location = paragraphRange.location
        effectiveRange.pointee.length = paragraphRange.length
        return numberOflines
    }
    
  //MARK: Bullet Check
    func hasBullets(in range: NSRange, scale: CGFloat) -> Bool {
        if !SUPPORTS_BULLETS {
            return false
        } else {
            var hasBullets = false
            let paragraphRange = self.paragraphRange(for: range)
            let style = paragraphStyle(atLocation: paragraphRange.location)

            let string = (textStorage.string as NSString).substring(with: paragraphRange)
            let bulletString = self.bulletString(in: string, location: paragraphRange.location, scale: scale)

            let bulletFormatLengthLocal = (bulletString).count

            if let style = style, style.isOrderedTextList(withScale: scale) {
                if bulletString.isEmpty {
                    return false
                }
            }
            if (style?.hasBullet) != nil && NSLocationInRange(range.location, NSRange(location: paragraphRange.location, length: bulletFormatLengthLocal + 1)) {
                hasBullets = true
            }
            return hasBullets
        }
    }
    
    func hasBulletsInLineParagraph(for range: NSRange) -> Bool {
        if !SUPPORTS_BULLETS {
            return false
        } else {
            var hasBullets = false
            var paragraphRange = self.paragraphRange(for: range)
            let paragraphLength = paragraphRange.length
            if isNewLineAtTheEnd(for: paragraphRange) {
                paragraphRange.length = Int(max(paragraphLength - 1, 0))
            }

            var style: NSParagraphStyle?
            if (textStorage.length ) > paragraphRange.location {
                style = textStorage.attribute(.paragraphStyle, at: paragraphRange.location, effectiveRange: nil) as? NSParagraphStyle
            }
            if let style = style, style.hasBullet() {
                hasBullets = true
            }
            return hasBullets
        }
    }
    
    func bulletString(in string: String?, location loc: Int, scale: CGFloat) -> String {
        let currentParagraphStyle = paragraphStyle(atLocation: loc)
        return currentParagraphStyle?.bulletChar(in: string, contentScale: scale) ?? ""
    }
    
    func isLineOf(_ string: String?, hasOnlyBulletsOf paragraphStyle: NSParagraphStyle?, scale: CGFloat) -> Bool {
        let currentTextList = paragraphStyle?.currentTextList(withScale: scale)
        let value = currentTextList?.markerItemNumber(inLineString: string ?? "") ?? 0

        let bulletAttrString = currentTextList?.attributedMarker(forItemNumber: value, scale: CGFloat(scale))
        let secondChar = bulletAttrString?.string

        let trimmedSTring = string?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) ?? ""

        //decrement the indentation if the user just taps the
        if ((trimmedSTring.count) == 0) || (trimmedSTring == secondChar) {
            return true
        }
        return false
    }
    
    func isBulletInsertedInBetween( for range: NSRange,paragraphStyle style: NSParagraphStyle?,scale: CGFloat) -> Bool {
        var insertedInBetween = false
        let nextMatchRange = nextRange(
            matching: style,
            range: range,
            scale: scale)
        if (range.location + nextMatchRange.length) > range.location {
            insertedInBetween = true
        }
        return insertedInBetween
    }
    
    //MARK: Public methods
    
    func setTextAlignment(_ textAlignment: NSTextAlignment, forEditing editingRange: NSRange) {
        let paragraphRange = self.paragraphRange(for: editingRange)

        let style = typingAttributes[.paragraphStyle] as? NSParagraphStyle
        let paragraph = style?.mutableCopy() as? NSMutableParagraphStyle
        paragraph?.alignment = textAlignment
        updateTypingAttributes(withValue: paragraph, forAttribute: NSAttributedString.Key.paragraphStyle.rawValue)

        textStorage.enumerateAttribute(
            .paragraphStyle,
            in: paragraphRange,
            options: [],
            using: { value, range, stop in
                let pStyle = value as? NSParagraphStyle
                let style = pStyle?.mutableCopy() as? NSMutableParagraphStyle
                style?.alignment = textAlignment
                self.setValue(style, forAttribute: NSAttributedString.Key.paragraphStyle.rawValue, in: range)
            })
    }

    func setAutoLineSpace(status: Bool, forEditing editingRange: NSRange) {
        self.setValue(NSNumber.init(value: status), forAttribute: FTFontStorage.isLineSpaceEnabledKey, in: editingRange)
    }

    func setLineSpacing(lineSpace: CGFloat, forEditing editingRange: NSRange) {
        let paragraphRange = self.paragraphRange(for: editingRange)

        let style = typingAttributes[.paragraphStyle] as? NSParagraphStyle
        let paragraph = style?.mutableCopy() as? NSMutableParagraphStyle
        paragraph?.lineSpacing = lineSpace
        updateTypingAttributes(withValue: paragraph, forAttribute: NSAttributedString.Key.paragraphStyle.rawValue)
        self.setValue(paragraph, forAttribute: NSAttributedString.Key.paragraphStyle.rawValue, in: paragraphRange)
    }
    
    func increaseIndentationForcibly( _ forcibly: Bool, editing editingRange: NSRange, scale: CGFloat) -> Bool {
        var valueToReturn = true

        if forcibly || hasBullets(in: editingRange, scale: scale) {
            let paragraphStyle = self.paragraphStyle(for: selectedRange)?.mutableCopy()
            if let style = paragraphStyle as? NSMutableParagraphStyle {
                style.increaseIndentation(withScale: scale)
                valueToReturn = adjustIndentation(
                    for:style,
                    indentationType: FTBulletIndentationType.increase,
                    editing: editingRange,
                    scale: scale)
            }
           
        }
        return valueToReturn
    }
    
    func decreaseIndentationForcibly(_ forcibly: Bool, editing editingRange: NSRange, scale: CGFloat) -> Bool {
        var valueToReturn = true

        if forcibly || hasBullets(in: editingRange, scale: scale) {
            let paragraphStyle = self.paragraphStyle(for: selectedRange)?.mutableCopy()
             if let style = paragraphStyle as? NSMutableParagraphStyle {
                style.decreaseIndentation(withScale: scale)
                valueToReturn = adjustIndentation(
                    for: paragraphStyle as? NSParagraphStyle,
                    indentationType: FTBulletIndentationType.decrease,
                    editing: editingRange,
                    scale: scale)
            }
        }
        return valueToReturn
    }
    
    func adjustBulletIndentLevel(for indentationType: FTBulletIndentationType, editing range: NSRange, forcibly: Bool, scale: CGFloat) -> Bool {
        if !SUPPORTS_BULLETS {
            return true
        } else {
            if !hasBulletsInLineParagraph(for: range) {
                return true
            }

            let paraRange = paragraphRange(for: range)
            let style = self.paragraphStyle(atLocation: paraRange.location)

            var effectiveRange = NSRange()
            let linesOfString = self.linesOfString(in: range, effectiveRange: &effectiveRange)
            var valueToReturn = false

            var startLoc = effectiveRange.location
            
            if let linesOfString = linesOfString {
                for (index, element) in linesOfString.enumerated() {
                     var actionSuccess = false
                    let style = self.paragraphStyle(atLocation: startLoc)?.mutableCopy()
                    var paragraphStyle = style as? NSMutableParagraphStyle

                    let bulletString = self.bulletString(in: element, location: startLoc, scale: scale)
                    let bulletStringlength = bulletString.count
                    var increasedLength = 0
                    if forcibly || NSLocationInRange(range.location, NSRange(location: startLoc, length: bulletStringlength)) {
                        self.updateBulletIndentation(for: &paragraphStyle, indentationType: indentationType, scale: scale)
                        if let paragraphStyle = paragraphStyle, !paragraphStyle.hasBullet() {
                            paragraphStyle.bulletLists = nil
                            increasedLength = -bulletString.count
                        }
                        actionSuccess = self.replaceBullet(
                            forStringLine: element,
                                  startLocation: startLoc,
                                  paragraphStyle: paragraphStyle,
                                  newlyAdding: false,
                                  lineNumber: index,
                                  scale: scale)
                        if actionSuccess {
                            startLoc += increasedLength
                        }
                    }
                    startLoc += (element.count + 1)
                     if !valueToReturn {
                         valueToReturn = actionSuccess
                     }
                }
            }
            if (style?.isOrderedTextList(withScale: scale))! {
                let typingAttributes = self.typingAttributes
                replaceNumberBulletsOnAutoComplete(
                    for: paraRange,
                    oldStyle: style,
                    scale: scale)
                self.typingAttributes = typingAttributes
            }
            return !valueToReturn
        }
    }
    
    func replaceBullets( withTextLists textLists: [FTTextList]?, for selectedRange: NSRange, scale: CGFloat) {
        if !SUPPORTS_BULLETS {
            return
        } else {
            var effectiveRange = NSRange()
            let numberOflines = linesOfString(
                in: selectedRange,
                effectiveRange: &effectiveRange)

            var startLoc = NSMaxRange(effectiveRange)
            
            numberOflines?.enumerated().reversed().forEach({ (index, element) in
                startLoc -= element.count
                var bulletsShouldAdd = false
                let style = self.paragraphStyle(atLocation: startLoc)?.mutableCopy()
                let paragraphStyle = style as? NSMutableParagraphStyle
                if let textLists = textLists, textLists.isEmpty {
                    paragraphStyle?.firstLineHeadIndent = 0
                    paragraphStyle?.resetBulletIndentations()
                } else if !self.hasBulletsInLineParagraph(for: NSRange(location: startLoc, length: element.count)) {
                    if let delegate = self.delegate, delegate.responds(to: #selector(UITextViewDelegate.textView(_:shouldChangeTextIn:replacementText:))) {
                       _ = delegate.textView?(self, shouldChangeTextIn: self.selectedRange, replacementText: " ")
                    }
                    bulletsShouldAdd = true
                    paragraphStyle?.resetBulletIndentations()
                    paragraphStyle?.increaseBulletIndentation(withScale: scale)
                }
                paragraphStyle?.bulletLists = textLists
                _ = self.replaceBullet(forStringLine: element, startLocation: startLoc, paragraphStyle: paragraphStyle, newlyAdding: bulletsShouldAdd, lineNumber: index, scale: scale)
                  startLoc -= 1
            })

            let style = paragraphStyle(atLocation: self.selectedRange.location)
            if let style = style, style.isOrderedTextList(withScale: scale){
                replaceNumberBulletsOnAutoComplete(
                    for: selectedRange,
                    oldStyle: style,
                    scale: scale)
            }
        }
    }
    
    func autoContinueBullets(forEditing range: NSRange, scale: CGFloat) -> Bool {
        if !SUPPORTS_BULLETS {
            return true
        } else {
            if !hasBulletsInLineParagraph(for: range) {
                return true
            }

            let style = self.paragraphStyle(atLocation: range.location)
            var insertedInBetween = false
            if let style = style, style.isOrderedTextList(withScale: scale) {
                insertedInBetween = isBulletInsertedInBetween(for: range, paragraphStyle: style, scale: scale)
            }

            var insertedBullets = false

            var effectiveRange = NSRange()
            let numberOflines = linesOfString(
                in: range,
                effectiveRange: &effectiveRange)

            var startLoc = effectiveRange.location
           for (_, element) in numberOflines!.enumerated() {
               let paragraphStyle = self.paragraphStyle(atLocation: startLoc)
               if let paragraphStyle = paragraphStyle, paragraphStyle.hasBullet() {
                   if self.isLineOf(element, hasOnlyBulletsOf: paragraphStyle, scale: scale) {
                    _ =  self.decreaseIndentationForcibly(
                           true,
                           editing: NSRange(location: startLoc, length: 0),
                           scale: scale)
                       insertedBullets = true
                   } else {
                      let currentTextList = paragraphStyle.currentTextList(withScale: scale)
                      self.updateTypingAttributes(withValue: paragraphStyle, forAttribute: NSAttributedString.Key.paragraphStyle.rawValue)
                      if let currentTextList = currentTextList {
                       let value = currentTextList.markerItemNumber(inLineString: element)
                       let bulletAttrString = currentTextList.attributedMarker(forItemNumber: value + 1, scale: CGFloat(scale))
                        if let bulletAttrString = bulletAttrString, let stringToReplace = NSAttributedString.attributedString(withFormat: AUTO_COMPLETE_BULLET_FORMAT, arguments: bulletAttrString).mutableCopy() as? NSMutableAttributedString {
                               stringToReplace.addAttributes(typingAttributes, range: NSRange(location: 0, length: stringToReplace.length))
                                textStorage.insert(stringToReplace, at: selectedRange.location)
                                selectedRange = NSRange(location: selectedRange.location + stringToReplace.length, length: 0)
                                insertedBullets = true
                                startLoc += stringToReplace.length
                           }
                       }
                   }
               }
                startLoc += element.count
                startLoc += 1
           }
            if insertedInBetween {
                replaceNumberBulletsOnAutoComplete(
                    for: range,
                    oldStyle: style,
                    scale: scale)
            }
        if (delegate?.responds(to: #selector(UITextViewDelegate.textViewDidChange(_:))))! {
            delegate?.textViewDidChange!(self)
            }
        return !insertedBullets
        }
    }
    
    //MARK: Indentation Helper
    
    func adjustIndentation( for paragraphStyle: NSParagraphStyle?, indentationType: FTBulletIndentationType, editing editingRange: NSRange,scale: CGFloat) -> Bool {
        let range = paragraphRange(for: editingRange)
        setValue(paragraphStyle, forAttribute: NSAttributedString.Key.paragraphStyle.rawValue, in: range)
        updateTypingAttributes(withValue: paragraphStyle, forAttribute: NSAttributedString.Key.paragraphStyle.rawValue)

        let valueToReturn = adjustBulletIndentLevel(
            for: indentationType,
            editing: editingRange,
            forcibly: true,
            scale: scale)

        //to refresh the cursor
        setNeedsLayout()
        return valueToReturn
    }
    
    //MARK: Bullets Indentation Helper
    func updateBulletIndentation( for style: inout NSMutableParagraphStyle?, indentationType indentationtype: FTBulletIndentationType, scale: CGFloat
    ) {
        switch indentationtype {
        case .increase:
                style?.increaseBulletIndentation(withScale: scale)
        case .decrease:
                style?.decreaseBulletIndentation(withScale: scale)
        }
    }
    
    //MARK:  Bullet Replace Helper
    
    func replaceBullet( forStringLine string: String?, startLocation: Int, paragraphStyle style: NSParagraphStyle?, newlyAdding: Bool, lineNumber: Int,
        scale: CGFloat
    ) -> Bool {
        var updateSelection = false
        var replacedSuccessfully = false
        let hasTextLists = ((style?.bulletLists?.count ?? 0) > 0) ? true : false
        guard let paragraphStyle = self.paragraphStyle(atLocation: startLocation) else {
            return replacedSuccessfully
        }

        let linerange = paragraphRange(for: selectedRange)
        if NSLocationInRange(startLocation, linerange) || startLocation <= linerange.location {
            updateSelection = true
        }
         if paragraphStyle.hasBullet() || newlyAdding {
            var stringLength = string?.count ?? 0
            var currentSelectedLocation = selectedRange.location

            var typingAttributes = currentTypingAttributes(
                atLocation: startLocation,
                stringLine: string ?? "")
            typingAttributes?[NSAttributedString.Key.paragraphStyle] = style
            
            let length = bulletString(in: string, location: startLocation, scale: scale).count
            let newRange = NSRange(location: startLocation, length: length )

            var stringToReplace = NSMutableAttributedString()

            if !hasTextLists {
                stringToReplace = NSMutableAttributedString(string: "")
                stringLength -= length
            }

            textStorage.beginEditing()

            if hasTextLists {
                let currentTextList = style?.currentTextList(withScale: scale)
                if nil != currentTextList {
                    let bulletAttrString = currentTextList?.attributedMarker(forItemNumber: lineNumber, scale: CGFloat(scale))
                    if let bulletAttrString = bulletAttrString, let strToReplace = NSAttributedString.attributedString(withFormat: BULLET_FORMAT, arguments: bulletAttrString).mutableCopy() as? NSMutableAttributedString {
                        stringToReplace = strToReplace
                    }

                    if let typingAttributes = typingAttributes as? [NSAttributedString.Key : Any] {
                        stringToReplace.addAttributes(typingAttributes, range: NSRange(location: 0, length: stringToReplace.length ))
                        stringLength -= (length - stringToReplace.length)
                    }
                }
            }
    
            if NSMaxRange(newRange) > (textStorage.length) {
                let msg = String(format: "range mismatch: range:%@,string lenght: %lu", NSStringFromRange(newRange), UInt(textStorage.length ))
                    FTCLSLog(msg)
                }
            textStorage.replaceCharacters(in: newRange, with: stringToReplace)
                
            currentSelectedLocation -= (length - stringToReplace.length);

            if isNewLineAtTheEnd(for: NSRange(location: newRange.location, length: stringLength)) {
                stringLength += 1
            }
            if (textStorage.length) < newRange.location + stringLength + 1 {
                    stringLength = max(stringLength, 0)
                }

                let updateAttributeForRange = NSRange(location: newRange.location, length: stringLength)
            if NSMaxRange(updateAttributeForRange) <= (textStorage.length ) {
                textStorage.addAttribute(.paragraphStyle, value: style as Any, range: updateAttributeForRange)
                }
            textStorage.endEditing()

                if updateSelection && (currentSelectedLocation >= 0) {
                    if currentSelectedLocation > 0 {
                        selectedRange = NSRange(location: currentSelectedLocation - 1, length: 0)
                    }
                    selectedRange = NSRange(location: currentSelectedLocation, length: 0)
                }
                if let typingAttributes = typingAttributes as? [NSAttributedString.Key : Any], stringLength <= 1 {
                    self.typingAttributes = typingAttributes
                }

                replacedSuccessfully = true
            }
        return replacedSuccessfully
    }
    
    //MARK: OrdererList Helpers
    
    func replaceNumberBulletsOnAutoComplete( for range: NSRange, oldStyle: NSParagraphStyle?, scale: CGFloat) {
        #if false
            let t1 = Date.timeIntervalSinceReferenceDate
        #endif
        var lineNum = 0
        var range = range
        range.length = 0
        var effectiveRange = NSRange()
        guard let numberOflines = linesOfStringMatchingParagraphStyle(
            in: range,
            effectiveRange: &effectiveRange,
            startNumber: &lineNum,
            oldStyle: oldStyle,
            scale: scale) else {
                return
        }
        var startLoc = effectiveRange.location

        let style = self.paragraphStyle(atLocation: startLoc)

        var levelInfos: [AnyHashable : Any] = [:]
        let keyNumber = roundOffTo3Digits(style?.headIndent ?? 0)
        levelInfos[NSNumber(value: Float(keyNumber))] = NSNumber(value: lineNum)
        var previousHeadIndent: CGFloat = 0
    
        for element in numberOflines {
            let trimmedString = element.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

            guard let paragraphStyle = self.paragraphStyle(atLocation: startLoc) else {
                return
            }
            if (trimmedString.count) > 0 {
                var replacedSuccessfully = false
                if paragraphStyle.hasBullet() {
                    let currentBulletString = bulletString(in: element, location: startLoc, scale: scale)
                    if hasBullets(in: NSRange(location: startLoc, length: element.count), scale: scale) && paragraphStyle.isOrderedTextList(withScale: scale) {
                        replacedSuccessfully = true
                        if previousHeadIndent != paragraphStyle.headIndent {
                            let keyNumber = roundOffTo3Digits(paragraphStyle.headIndent)
                            if previousHeadIndent > CGFloat(keyNumber) {
                                levelInfos.removeValue(forKey: NSNumber(value: Float(previousHeadIndent)))
                            } else {
                                levelInfos[NSNumber(value: Float(previousHeadIndent))] = NSNumber(value: lineNum)
                            }
                            lineNum = (levelInfos[NSNumber(value: keyNumber)] as? NSNumber)?.intValue ?? 0
                            previousHeadIndent = CGFloat(keyNumber)
                        }
                       _ = replaceBullet(
                               forStringLine: element,
                               startLocation: startLoc,
                               paragraphStyle: paragraphStyle,
                               newlyAdding: false,
                               lineNumber: lineNum,
                               scale: scale)

                           let currentTextList = paragraphStyle.currentTextList(withScale: scale)
                           var newIndexString: String?
                           if let marker = currentTextList?.marker(forItemNumber: lineNum) {
                               newIndexString = String(format: BULLET_FORMAT, marker)
                           }
                        if let newIndexString = newIndexString {
                            startLoc += (newIndexString.count - currentBulletString.count)
                        }
                    }
                    if (replacedSuccessfully) {
                        lineNum += 1;
                    }
                }
            } else {
                levelInfos.removeValue(forKey: NSNumber(value: Float(paragraphStyle.headIndent)))
                previousHeadIndent = 0
            }
            startLoc += element.count;
            startLoc += 1;
        }
        #if false
            let t2 = Date.timeIntervalSinceReferenceDate
            print(String(format: "timetaken = %lf", t2 - t1))
        #endif
    }
    
    func markerIndexForString(in previousEffectiveRange: NSRange, scale: CGFloat) -> Int {
        var range = NSRange(location: previousEffectiveRange.location, length: 0)
        range = paragraphRange(for: range)
        let lineString = (textStorage.string as NSString?)?.substring(with: range) ?? ""

        let style = paragraphStyle(atLocation: range.location)

        let currentTextList = style?.currentTextList(withScale: scale)
        let startLineNumber = currentTextList?.markerItemNumber(inLineString: lineString) ?? 0
        return startLineNumber
    }
    
    func linesOfStringMatchingParagraphStyle(
        in range: NSRange,
        effectiveRange: NSRangePointer,
        startNumber: UnsafeMutablePointer<Int>?,
        oldStyle: NSParagraphStyle?,
        scale: CGFloat
    ) -> [String]? {
        let startNumber = startNumber
        var paragraphfallsInThisRange = false
        var matchedRange = NSRange(location: 0, length: 0)

        let lineRange = self.paragraphRange(for: range)
        let currentStyle = paragraphStyle(atLocation: range.location)

        if let currentStyle = currentStyle, currentStyle.isOrderedTextList(withScale: scale) {
            paragraphfallsInThisRange = true
            matchedRange = lineRange
            matchedRange.length = 0
        }

        var styleToMatch = currentStyle
        if (currentStyle?.headIndent ?? 0.0) > (oldStyle?.headIndent ?? 0.0) {
            styleToMatch = oldStyle
        }
        let prevRange = previousRange(
            matching: styleToMatch,
            range: matchedRange,
            scale: scale)
        if prevRange.location != NSNotFound {
            matchedRange = prevRange
            let newNumber = markerIndexForString(in: prevRange, scale: scale)
            startNumber?.pointee = newNumber
        }
        let rangeReturned = nextRange(
            matching: styleToMatch,
            range: matchedRange,
            scale: scale)
        matchedRange.length += rangeReturned.length
        var paragraphRange = self.paragraphRange(for: range)
        if paragraphfallsInThisRange {
           paragraphRange = self.paragraphRange(for: matchedRange)
        }
        let numberOflines = linesOfString(in: paragraphRange)

        effectiveRange.pointee.location = paragraphRange.location
        effectiveRange.pointee.length = paragraphRange.length

        return numberOflines
    }
    
    func previousParagraphStyle( for range: NSRange, effectiveRange: NSRangePointer) -> NSParagraphStyle? {
        var previousRange = paragraphRange(for: range)
        var loc = range.location
        loc -= 1
        if loc < 0 {
            return nil
        }
        previousRange.location = loc
        previousRange.length = 0

        let prevStyle = textStorage.attribute(.paragraphStyle, at: previousRange.location, effectiveRange: effectiveRange) as? NSParagraphStyle
        return prevStyle
    }
    
    func nextParagraphStyle( for range: NSRange, effectiveRange: NSRangePointer?) -> NSParagraphStyle? {
        var nextRange = paragraphRange(for: range)
        let loc = range.location + range.length + 1
        if loc >= (textStorage.length ) {
            return nil
        }
        nextRange.location = loc
        nextRange.length = 0

        let nextStyle = textStorage.attribute(.paragraphStyle, at: nextRange.location, effectiveRange: effectiveRange) as? NSParagraphStyle
        return nextStyle
    }
    
    func previousRange(matching currentStyle: NSParagraphStyle?,range: NSRange,scale: CGFloat) -> NSRange {
        var previousEffectiveRange = NSRange()
        var prevStyle = previousParagraphStyle(for: range, effectiveRange: &previousEffectiveRange)

        var rangeToReturn = NSRange(location: NSNotFound, length: 0)
        //    CGFloat indentToCheck = MIN(oldStyle.headIndent, currentStyle.headIndent);
        let indentToCheck = currentStyle?.headIndent ?? 0.0

        var roundOffPrevStyle = roundOffTo3Digits(prevStyle?.headIndent ?? 0)
        let roundOffCurStyle = roundOffTo3Digits(indentToCheck)

        while prevStyle != nil && (roundOffPrevStyle >= roundOffCurStyle) {
            rangeToReturn.length += previousEffectiveRange.length
            rangeToReturn.location = previousEffectiveRange.location

            if roundOffPrevStyle == roundOffCurStyle {
                break
            }
            prevStyle = previousParagraphStyle(for: previousEffectiveRange, effectiveRange: &previousEffectiveRange)
            roundOffPrevStyle = roundOffTo3Digits(prevStyle?.headIndent ?? 0)
        }
        return rangeToReturn;
    }
    
    func nextRange(
        matching currentStyle: NSParagraphStyle?,
        range: NSRange,
        scale: CGFloat
    ) -> NSRange {
        var rangeToReturn = NSRange(location: 0, length: 0)
        rangeToReturn.location = range.location

        var nextEffectiveRange = NSRange()
        var newStyle = nextParagraphStyle(for: range, effectiveRange: &nextEffectiveRange)
        let headIndent = currentStyle?.headIndent ?? 0.0

        var roundOffNewStyle = roundOffTo3Digits(newStyle?.headIndent ?? 0)
        let roundOffHeadIndent = roundOffTo3Digits(headIndent)

        while newStyle != nil && (roundOffNewStyle >= roundOffHeadIndent) {
            let newStyleArray = newStyle?.bulletLists
            let currentStyleArray = currentStyle?.bulletLists
            var isEqual = true
            if let newStyleArray = newStyleArray, let currentStyleArray = currentStyleArray {
                let dict1 = newStyleArray as NSArray
                let dict2 = currentStyleArray as NSArray
                isEqual = (dict1 == dict2)
            }

            if roundOffNewStyle == roundOffHeadIndent && !isEqual {
                break
            }
            rangeToReturn.length += nextEffectiveRange.length
            rangeToReturn.location = nextEffectiveRange.location
            
            newStyle = nextParagraphStyle(for: nextEffectiveRange, effectiveRange: &nextEffectiveRange)
            roundOffNewStyle = roundOffTo3Digits(newStyle?.headIndent ?? 0)
        }
         return rangeToReturn
    }
    
    func isNewLineAtTheEnd(for range: NSRange) -> Bool {
        let paragraphRange = self.paragraphRange(for: range)
        if NSMaxRange(paragraphRange) > 0 {
            let subString = (textStorage.string as NSString?)?.substring(with: NSRange(location: NSMaxRange(paragraphRange) - 1, length: 1))
            if subString == "\n" {
                return true
            }
        }
        return false
    }
    
    //MARK: Copy/Paste remove Bullet
    func removeBulletsIfPresent(_ attributedString: NSAttributedString?, scale: CGFloat) -> NSAttributedString? {
        if !SUPPORTS_BULLETS {
            return attributedString
        } else {
            let numberofLines = attributedString?.string.components(separatedBy: "\n")
            var attrString: NSMutableAttributedString?
            if let attributedString = attributedString {
                attrString = NSMutableAttributedString(attributedString: attributedString)
            }
            var startLoc = 0
            
            for element in numberofLines! {
                var bulletString: String?
                if !element.isEmpty {
                     let style = attrString?.attribute(.paragraphStyle, at: startLoc, effectiveRange: nil) as? NSParagraphStyle
                     bulletString = style?.bulletChar(in: element, contentScale: scale)
                     if (bulletString?.count ?? 0) != 0 {
                         attrString?.replaceCharacters(in: NSRange(location: startLoc, length: bulletString?.count ?? 0), with: "")
                     }
                 }
                 if let bulletString = bulletString {
                     startLoc += (element.count - bulletString.count)
                     startLoc += 1
                 }
            }
            return attrString;
        }
    }
    
    func shouldConsiderForDecrementIndentation(onDeleting range: NSRange, scale contentScale: CGFloat) -> Bool {
        let hasBullet = hasBullets(in: range, scale: contentScale)
        return hasBullet
    }
}

 func roundOffTo3Digits(_ value: CGFloat) -> Int {
     let keyNumber = Int(roundf(Float(value * 1000)) / 1000)
     return keyNumber
 }
