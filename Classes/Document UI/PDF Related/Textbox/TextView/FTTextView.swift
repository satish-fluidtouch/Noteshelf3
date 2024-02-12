//
//  FTTextView.swift
//  Noteshelf
//
//  Created by Sameer on 21/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import MobileCoreServices

let FTTextPasteBoardType = "com.noteshelf2.textPasteboard"

class FTTextView: UITextView, UIGestureRecognizerDelegate, NSTextStorageDelegate {
    private var _scale: CGFloat = 1.0
    private var _isMoving: Bool = false
    var scale: CGFloat {
        get {
            return _scale
        }
        
        set {
            if _scale != newValue {
                if selectedRange.length == 0 {
                    var font = typingAttributes[NSAttributedString.Key.font] as? UIFont
                    font = UIFont(name: font?.fontName ?? "", size: (font?.pointSize ?? 0.0) * (newValue / _scale))
                    setValueFor(font, forAttribute: NSAttributedString.Key.font.rawValue, in: selectedRange)
                }
                textStorage.applyScale(newValue / _scale, originalScaleToApply: newValue * transformScale)
                _scale = newValue
                var inset = FTTextView.textContainerInset(annotationVersion)
                inset = UIEdgeInsetsScale(inset, transformScale)
                textContainerInset = UIEdgeInsets(top: inset.top * _scale, left: inset.left * _scale, bottom: inset.bottom * _scale, right: inset.right * _scale)
            }
        }
    }
    var isMoving : Bool {
        get {
            return _isMoving
        }
        
        set {
            #if targetEnvironment(macCatalyst)
            if _isMoving != newValue {
                _isMoving = newValue
                setEnableLoupeGestureRecognizer(!newValue)
            }
            #endif
        }
    }
    private var annotationVersion = 0
    var transformScale: CGFloat = 0.0
    private var isPointOnSelection = false
    func UIFontIsDynamicType(_ font: UIFont?) -> Bool {
        return font?.fontName.hasPrefix(".") ?? false
    }
    override var inputAccessoryViewController: UIInputViewController? {
        return nil
    }
    weak var annotationViewController: FTTextAnnotationViewController?
    weak var touchHandler: FTTouchEventProtocol?

    convenience init( frame: CGRect, annotationVersion version: Int, transformScale: CGFloat, annotationViewController: FTTextAnnotationViewController) {
        self.init()
        self.annotationViewController = annotationViewController
        // Initialization code
        typingAttributes = defaultAttributes
        backgroundColor = UIColor.clear
        annotationVersion = version
        self.transformScale = transformScale
        autocorrectionType = .no

        var inset = FTTextView.textContainerInset(annotationVersion)
        inset = UIEdgeInsetsScale(inset, self.transformScale)
        textContainerInset = inset

        contentInset = .zero
        isScrollEnabled = true
        delaysContentTouches = false
        textContainer.lineFragmentPadding = 0
        textStorage.delegate = self
        autoresizingMask = [.flexibleHeight, .flexibleWidth]
        scale = 1.0

        let gesture = FTTextAttachmentTapGesture(target: self, action: #selector(didTap(onView:)))
        gesture.supportedActionType = FTActionSupport.textAttachment
        addGestureRecognizer(gesture)
          #if targetEnvironment(macCatalyst)
          allowsEditingTextAttributes = true
          let color = UIColor(red: 0, green: 0.48, blue: 1.0, alpha: 1.0)
          if let val = self.value(forKey: "textInputTraits")  {
            (val as AnyObject).setValue(color, forKey: "insertionPointColor");
          }
          #else
          allowsEditingTextAttributes = false
          #endif

        self.linkTextAttributes = NSAttributedString.linkAttributes;
    }
    
    var defaultAttributes: [NSAttributedString.Key : Any] {
        let style = (NSParagraphStyle.default).mutableCopy()
        let pStyle = style as? NSMutableParagraphStyle
        pStyle?.alignment = .left
        let defaultBodyFont = UIFont.defaultTextFont()
          let defaultTextColor = UIColor(hexString: "000000")
          var dictionary: [NSAttributedString.Key : Any]?
          if let pStyle = pStyle {
              dictionary = [
                  NSAttributedString.Key.paragraphStyle: pStyle,
                  NSAttributedString.Key.font: defaultBodyFont,
                  NSAttributedString.Key.foregroundColor: defaultTextColor,
                  NSAttributedString.Key.underlineStyle: NSNumber(value: 0)
              ]
          }
          return dictionary ?? [:]
    }
    
    #if !targetEnvironment(macCatalyst)
    override func becomeFirstResponder() -> Bool {
        let responder = super.becomeFirstResponder()
        if(responder) {
            self.updateMenuItems()
        }
        return responder
    }
    #endif

#if targetEnvironment(macCatalyst)
    override func editMenu(for textRange: UITextRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
        var actions = suggestedActions
        let menu = self.getMenuForMac()
        actions.append(menu)
        return UIMenu(children: actions)
    }

    func getMenuForMac() -> UIMenu {
        var menuItems = [UIMenuElement]()
        if self.checkIfToShowEditLinkOptions() {
            let editLinkMenuItem = UIAction(title: "textLink_editLink".localized) { [weak self] _ in
                self?.editLinkMenuItemAction(nil)
            }
            menuItems.append(editLinkMenuItem)

            let removeLinkMenuItem = UIAction(title: "textLink_removeLink".localized) { [weak self] _ in
                self?.removeLinkMenuItemAction(nil)
            }
            menuItems.append(removeLinkMenuItem)
        } else {
            let linkToMenuItem = UIAction(title: "textLink_linkTo".localized) { [weak self] _ in
                self?.linkMenuItemAction(nil)
            }
            menuItems.append(linkToMenuItem)
        }
        let menu = UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: menuItems);
        return menu;
    }
#endif

    func setValueFor(_ value: Any?, forAttribute attr: String, in range: NSRange) {
        if range.length == 0 {
            var attributes = typingAttributes
            if let value = value {
                attributes[NSAttributedString.Key(rawValue: attr)] = value
            } else {
                attributes.removeValue(forKey: NSAttributedString.Key(rawValue: attr))
            }
            typingAttributes = attributes
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
        delegate?.textViewDidChange?(self)
    }
    
    func attribute(_ attr: String, in range: NSRange) -> NSObjectProtocol? {
        var value: Any?
        if range.length == 0 {
            value = typingAttributes[NSAttributedString.Key(attr)]
        } else {
            // Might be a scaling text storage.
            value = attributedText?.attribute(NSAttributedString.Key(attr), at: range.location, effectiveRange: nil)
        }
        return value as? NSObjectProtocol
    }

    //MARK: Cursor position/ text size
    func boundsOf(_ range: UITextRange?) -> CGRect {
        var range = range
        var rectToReturn = CGRect.zero

        if range == nil {
            let start = beginningOfDocument
            range = textRange(from: start, to: start)
        }

        if range?.isEmpty ?? false {
            if let start1 = range?.start {
                rectToReturn = caretRect(for: start1)
            }
        } else {
            var unionRect = CGRect.null
            if let range = range {
                for selectionRect in selectionRects(for: range) {
                    if unionRect.isNull {
                        unionRect = selectionRect.rect
                    } else {
                        unionRect = unionRect.union(selectionRect.rect)
                    }
                }
            }
            rectToReturn = unionRect
        }
        return rectToReturn.insetBy(dx: -10, dy: -10)
    }

    func textUsedSize() -> CGSize {
        var str = attributedText
        if attributedText?.length == 0 {
            str = NSAttributedString(string: "W", attributes: typingAttributes)
        }
        let size = str?.requiredAttributedStringSize(
            maxWidth: bounds.size.width,
            containerInset: textContainerInset)
        return size ?? CGSize.zero
    }
    
    override func copy(_ sender: Any?) {
        let range = selectedRange
        if range.length == 0 {
            return
        }

        var representations: [String : Any] = [:]
        let textStorage = self.textStorage
        let containsAttachments = textStorage.containsAttribute(NSAttributedString.Key.attachment.rawValue, in: range)
        // Add a rich text type if the delegate didn't already.
        if representations[FTTextPasteBoardType] == nil {
            // TODO: We might want to add RTF even if we also added RTFD if the system doesn't auto-convert for us.
            var documentType: String?
            var dataType: String?
            do {
                documentType = NSAttributedString.DocumentType.rtfd.rawValue
                dataType = FTTextPasteBoardType
            }

            guard  let selectedAttributedString = textStorage.attributedSubstring(from: range).mutableCopy() as? NSMutableAttributedString else {
                return
            }
            let newRange = NSRange(location: 0, length: selectedAttributedString.length )

            let oneByScale = 1 / scale

            selectedAttributedString.enumerateAttributes(in: newRange, options: [], using: { attrs, range, _ in
                let font = attrs[NSAttributedString.Key.font] as? UIFont
                let scaleFont = UIFont(name: font?.fontName ?? "", size: (font?.pointSize ?? 0.0) * CGFloat(oneByScale))
                if let scaleFont = scaleFont {
                    selectedAttributedString.addAttribute(.font, value: scaleFont, range: range)
                }

                let paragraphStyle = attrs[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle
                let newParagraphStyle = paragraphStyle?.mutableCopy() as? NSMutableParagraphStyle
                newParagraphStyle?.minimumLineHeight *= CGFloat(oneByScale)
                newParagraphStyle?.maximumLineHeight *= CGFloat(oneByScale)

                newParagraphStyle?.firstLineHeadIndent *= CGFloat(oneByScale)
                newParagraphStyle?.headIndent *= CGFloat(oneByScale)
                if let newParagraphStyle = newParagraphStyle, newParagraphStyle.hasBullet() {
                    newParagraphStyle.defaultTabInterval *= oneByScale

                    let originalTabStops = newParagraphStyle.tabStops
                    var tabStops: [AnyHashable] = []
                    for eachTab in originalTabStops ?? [] {
                        let tab = NSTextTab(textAlignment: eachTab.alignment, location: eachTab.location * oneByScale, options: eachTab.options)

                        tabStops.append(tab)
                    }
                    newParagraphStyle.tabStops = tabStops as? [NSTextTab]
                }
                if let newParagraphStyle = newParagraphStyle {
                    selectedAttributedString.addAttribute(.paragraphStyle, value: newParagraphStyle, range: range)
                }
            })
            
            var data: Data?
            do {
                data = try selectedAttributedString.data(from: NSRange(location: 0, length: selectedAttributedString.length), documentAttributes: [
                  NSAttributedString.DocumentAttributeKey.documentType: documentType ?? ""
                ])
            } catch {
            }
            
            if data == nil {
              debugLog("Error archiving as \(String(describing: documentType))")
            } else {
               var archivedData: Data?
               if let data = data {
                 archivedData = try? NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: false)
               }
               if let dataType = dataType {
                 representations[dataType] = archivedData
               }
            }
        }

        if representations[kUTTypeUTF8PlainText as String] == nil {
            var string = ((textStorage.string) as NSString).substring(with: range)
            if containsAttachments {
                // Strip the attachment characters in this range. Could maybe get more fancy by collapsing spaces into a single space, but not going to mess with that for now.
                string = string.replacingOccurrences(of: NSAttributedString.attachmentString(), with: "")
            }
            let data = string.data(using: .utf8)
            representations[kUTTypeUTF8PlainText as String] = data
        }
                 
        let items = [representations]
        let pasteboard = UIPasteboard.general
        pasteboard.items = items
    }
              
    override func cut(_ sender: Any?) {
        let range = selectedRange
        if range.length == 0 {
            return
        }

        copy(sender)

        let replacement = NSAttributedString(string: "", attributes: nil)
        replaceAttributedString(in: selectedRange, with: replacement)
    }

    override func delete(_ sender: Any?) {
        if selectedTextRange != nil && !(selectedTextRange?.isEmpty ?? false) {
            if let selectedTextRange = selectedTextRange {
                replace(selectedTextRange, withText: "")
            }
        }
    }
    
    override func paste(_ sender: Any?) {
        let pasteboard = UIPasteboard.general
        // Handle our default readable types.
        let scaleToApply = scale
        let result = NSMutableAttributedString()
        enumerateBestDataForTypes(
            pasteboard,
            readableTypes(),
            { [self] data, dataType in
                    var data = data
                    var attributedString: NSAttributedString?
                    if (dataType == FTTextPasteBoardType) {

                        if let unarchievedData = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSObject.self], from: data) as? Data ?? Data() {
                            data = unarchievedData
                        }
                    } else if dataType == kUTTypeURL as String {
                        if let urlData = pasteboard.url?.dataRepresentation {
                            data = urlData
                        }
                    }
                    if nil == attributedString {
                        attributedString = NSAttributedString.readRTFData(data)
                    }

                    if attributedString != nil {
                        attributedString = attributedString?.mapAttributesToMatch(withLineHeight: -1)

                        var str: NSMutableAttributedString?
                        if let attributedString = attributedString {
                            str = NSMutableAttributedString(attributedString: attributedString)
                        }
                        str?.removeAttribute(.link, range: NSRange(location: 0, length: str?.length ?? 0))
                        str?.applyScale(scaleToApply, originalScaleToApply: scaleToApply)
                        attributedString = str

                        let currentParagraphStyle = typingAttributes[.paragraphStyle] as? NSParagraphStyle
                        if let currentParagraphStyle = currentParagraphStyle, let bulletLists = currentParagraphStyle.bulletLists, !bulletLists.isEmpty {
                            attributedString = removeBulletsIfPresent(attributedString, scale: scaleToApply)
                        }

                        if let attributedString = attributedString {
                            result.append(attributedString)
                            if dataType == FTTextPasteBoardType {
                                result.enumerateAttribute(
                                    .paragraphStyle,
                                    in: NSRange(location: 0, length: result.length),
                                    options: [],
                                    using: { paragraphStyle, range, _ in
                                        if let bulletLists = currentParagraphStyle?.bulletLists, !bulletLists.isEmpty {
                                            let newParagraphStyle = currentParagraphStyle?.mutableCopy()
                                            if let newParagraphStyle = newParagraphStyle as? NSMutableParagraphStyle {
                                                result.addAttribute(.paragraphStyle, value: newParagraphStyle, range: range)
                                            }
                                        }
                                    })
                            } else {
                               _  = delegate?.textView?(self, shouldChangeTextIn: selectedRange, replacementText: result.string)
                                result.addAttributes(typingAttributes, range: NSRange(location: 0, length: result.length))
                            }
                        }
                    }
                })
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length), options: [], using: { font, range, _ in
            // Text pasted from Notes will have dynamic type fonts, but we want to control our sizes in our document-based apps. Might need a setting on OUITextView for clients that *do* want dynamic type.
            if UIFontIsDynamicType(font as? UIFont) {
                result.removeAttribute(.font, range: range)
            }
        })

        let backgroundColor = typingAttributes[.backgroundColor] as? UIColor
        if let backgroundColor = backgroundColor {
            result.addAttribute(.backgroundColor, value: backgroundColor, range: NSRange(location: 0, length: result.length))
        } else {
            result.removeAttribute(.backgroundColor, range: NSRange(location: 0, length: result.length))
        }

        if result.length > 0 {
            replaceAttributedString(in: selectedRange, with: result)
           }
    }
    
    func replaceAttributedString(in range: NSRange, with attributedString: NSAttributedString?) {
        let textStorage = self.textStorage
        let typingAttributes = self.typingAttributes
        //match the bullets on pasting
        let style = typingAttributes[.paragraphStyle] as? NSParagraphStyle

        let lineRange = (self.textStorage.string as NSString).paragraphRange(for: range)

        var afterEditRange = NSRange(location: range.location, length: attributedString?.length ?? 0)

        let selectedRange = self.selectedRange
        afterEditRange = NSRange(location: NSMaxRange(afterEditRange), length: 0)

        if NSMaxRange(afterEditRange) < NSMaxRange(selectedRange) {
            // Shrinking; do the selection change before the edit
            self.selectedRange = afterEditRange
        }

        textStorage.beginEditing()
        if let attributedString = attributedString {
            textStorage.replaceCharacters(in: range, with: attributedString)
        }
        textStorage.endEditing()

        if NSMaxRange(afterEditRange) > NSMaxRange(selectedRange) {
            // Growing; do the selection change after the edit
            self.selectedRange = afterEditRange
        }

        if let style = style, let bulletList = style.bulletLists, !bulletList.isEmpty {
            if attributedString?.string == "" {
                if lineRange.location == range.location {
                    let p = style.mutableCopy() as? NSMutableParagraphStyle
                    p?.resetBulletIndentations()
                    setValue(p, forAttribute: NSAttributedString.Key.paragraphStyle.rawValue, in: afterEditRange)
                }
            } else {
                replaceBullets(
                    withTextLists: style.bulletLists as? [FTTextList],
                    for: NSRange(location: selectedRange.location, length: attributedString?.length ?? 0),
                    scale: scale)
            }
        } else {
            let startLoc = selectedRange.location
            attributedString?.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: attributedString?.length ?? 0), options: .reverse, using: { value, rangeOfText, _ in
                if let value = value as? NSParagraphStyle, let bulletLists = value.bulletLists, !bulletLists.isEmpty{
                    replaceBullets(
                        withTextLists: value.bulletLists as? [FTTextList],
                     for: NSRange(location: startLoc + rangeOfText.location, length: rangeOfText.length),
                     scale: scale)
                }
            })
        }
        
        if let delegate = delegate, delegate.responds(to: #selector(UITextViewDelegate.textViewDidChange(_:))) {
            delegate.textViewDidChange?(self)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event);
        let point = touches.first?.location(in: self)
        let bounds = boundsOf(selectedTextRange)
        isPointOnSelection = bounds.contains(point ?? CGPoint.zero)
        if !isPointOnSelection {
            touchHandler?.processTouchesBegan(touches, with: event)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event);
        if !isPointOnSelection {
            touchHandler?.processTouchesMoved(touches, with: event)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event);
        if !isPointOnSelection {
            touchHandler?.processTouchesEnded(touches, with: event)
        }
    }
    
    override func text(in range: UITextRange) -> String? {
        if range.isEmpty {
            return ""
        }

        let st = offset(from: beginningOfDocument, to: range.start)
        let en = offset(from: beginningOfDocument, to: range.end)
        let length = en - st

        var result: String?
        if en <= st {
            result = ""
        } else if (attributedText?.length ?? 0) < st + length {
            result = ""
        } else {
            if let attributedText = attributedText {
                result = (attributedText.string as NSString).substring(with: NSRange(location: st, length: length))
            }
        }

        return result
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        var shouldReturn = super.gestureRecognizerShouldBegin(gestureRecognizer)
        if isMoving && gestureRecognizer.view == self && (gestureRecognizer is UILongPressGestureRecognizer) {
            shouldReturn = false
        } else if panGestureRecognizer == gestureRecognizer {
            shouldReturn = false
        }
        return shouldReturn
    }
    
    class func textContainerInset(_ textAnnotationVersion: Int) -> UIEdgeInsets {
        if textAnnotationVersion <= 4 {
            return UIEdgeInsets(top: 20, left: 20, bottom: 44, right: 20)
        }
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }

    @objc func didTap(onView gesture: FTTextAttachmentTapGesture?) {
        if let attachement = gesture?.actionAttribute as? NSTextAttachment,
           let range = gesture?.range {
            _ = self.delegate?.textView?(self,
                                         shouldInteractWith: attachement,
                                         in: range,
                                         interaction: .invokeDefaultAction);
        }
    }
    
    func loupeGestureRecognizer() -> UIGestureRecognizer? {
        if #available(iOS 14.0, *) {
            return nil;
        }
        var loupeGesture: UIGestureRecognizer?
        let gestures = gestureRecognizers
        if let gestures = gestures {
            for eachGesture in gestures {
                if (eachGesture is UILongPressGestureRecognizer) && (eachGesture.view == self) {
                    loupeGesture = eachGesture
                    break
                }
            }
        }
        return loupeGesture
    }
    
    #if targetEnvironment(macCatalyst)
    func setEnableLoupeGestureRecognizer(_ enable: Bool) {
        var loupeGesture: UIGestureRecognizer?
        if let gestures = self.gestureRecognizers {
            for eachGesture in gestures {
                if let classname = NSClassFromString("UITextLoupePanGestureRecognizer"),
                   eachGesture.isKind(of: classname),
                   eachGesture.view == self {
                    loupeGesture = eachGesture
                    break
                }
            }
            if nil == loupeGesture {
                for eachGesture in gestures {
                    if (eachGesture is UILongPressGestureRecognizer) && (eachGesture.view == self) {
                        loupeGesture = eachGesture
                        break
                    }
                }
            }
        }
        loupeGesture?.isEnabled = enable
    }
    #endif
}

    private func readableTypes() -> [AnyHashable]? {
        return [
            FTTextPasteBoardType,
            kUTTypeRTF,
            kUTTypePlainText,
            kUTTypeURL
        ]
    }

    private func enumerateBestDataForTypes(_ pasteboard: UIPasteboard?, _ types: [AnyHashable]?, _ completion: (Data,String)->Void ) {
        var itemSet: NSIndexSet?
        if let types = types as? [String] {
            itemSet = pasteboard?.itemSet(withPasteboardTypes: types) as NSIndexSet?
        }
        itemSet?.enumerate({ itemIndex, _ in
            for type in types ?? [] {
                guard let type = type as? String else {
                    continue
                }
                let datas = pasteboard?.data(forPasteboardType: type, inItemSet: NSIndexSet(index: itemIndex) as IndexSet)
                let data = datas?.last
                if let data = data {
                    completion(data, type)
                    break
                }
            }
        })
    }

extension FTTextView {

    @objc func linkMenuItemAction(_ sender: Any?) {
        if let controller = self.annotationViewController {
            controller.performLinkAction(sender)
            if controller.isEditMode {
                FTTextLinkEventTracker.trackEvent(with: TextLinkEvents.selectedTextLinkToTap)
            } else {
                FTTextLinkEventTracker.trackEvent(with: TextLinkEvents.linkToTap)
            }
        }
    }
    
    @objc func editLinkMenuItemAction(_ sender: Any?) {
        if let controller = self.annotationViewController {
            controller.performLinkAction(sender)
            if controller.isEditMode {
                FTTextLinkEventTracker.trackEvent(with: TextLinkEvents.selectedTextEditLinkTap)
            } else {
                FTTextLinkEventTracker.trackEvent(with: TextLinkEvents.editLinkTap)
            }
        }
    }

    @objc func removeLinkMenuItemAction(_ sender: Any?) {
        if let controller = self.annotationViewController {
            controller.removeLinkAction(sender)
            if controller.isEditMode {
                FTTextLinkEventTracker.trackEvent(with: TextLinkEvents.selectedTextRemoveLinkTap)
            } else {
                FTTextLinkEventTracker.trackEvent(with: TextLinkEvents.removeLinkTap)
            }
        }
    }

    @objc func lookUpMenuItemAction(_ sender: Any?) {
        if let controller = self.annotationViewController {
            controller.performLookUpMenu(sender)
        }
    }
    
    @objc func shareMenuItemAction(_ sender: Any?) {
        if let controller = self.annotationViewController {
            controller.performShareMenu(sender)
        }
    }

    @objc func colorMenuItemAction(_ sender: Any?) {
        if let controller = self.annotationViewController {
            controller.performColorMenu(sender)
        }
    }

    func getSelectedText() -> String? {
        if let selectedTextRange: UITextRange = self.selectedTextRange,!selectedTextRange.isEmpty {
            return self.text(in: selectedTextRange);
        }
        return nil
    }
    
    func isTextHighLighted() -> Bool {
        return !(self.selectedTextRange?.isEmpty ?? true);
    }
    
    func checkIfToShowEditLinkOptions() -> Bool {
        var shouldShowEditLinkOptions = false
        if isTextHighLighted(),self.selectedRange.length > 0 {
            let startingLocation = self.selectedRange.location
            let endingLocation = startingLocation + self.selectedRange.length
            shouldShowEditLinkOptions = checkLinkConsistencyInRange(startingLocation..<endingLocation)
        } else if self.attributedText.length > 0 {
            if let textAnnotVc = self.annotationViewController, !textAnnotVc.isEditMode {
                let trimmedRange = self.trimWhitespaceAndNewlines(from: 0..<self.attributedText.length, in: self.attributedText)
                shouldShowEditLinkOptions = checkLinkConsistencyInRange(trimmedRange)
            }
        }
        return shouldShowEditLinkOptions
    }

    private func trimWhitespaceAndNewlines(from range: Range<Int>, in attributedText: NSAttributedString) -> Range<Int> {
        var trimmedRange = range
        // Trim leading whitespaces, newlines, and tabs
        while trimmedRange.count > 0 {
            let nsRange = NSRange(location: trimmedRange.lowerBound, length: 1)
            let substring = attributedText.attributedSubstring(from: nsRange).string
            if let firstScalar = substring.unicodeScalars.first, CharacterSet.whitespacesAndNewlines.contains(firstScalar) || substring == "\t" {
                trimmedRange = trimmedRange.dropFirst()
            } else {
                break
            }
        }
        // Trim trailing whitespaces, newlines, and tabs
        while trimmedRange.count > 0 {
            let nsRange = NSRange(location: trimmedRange.upperBound - 1, length: 1)
            let substring = attributedText.attributedSubstring(from: nsRange).string
            if let firstScalar = substring.unicodeScalars.first, CharacterSet.whitespacesAndNewlines.contains(firstScalar) || substring == "\t" {
                trimmedRange = trimmedRange.dropLast()
            } else {
                break
            }
        }
        return trimmedRange
    }

    private func checkLinkConsistencyInRange(_ range: Range<Int>) -> Bool {
        var firstSchemeUrl: URL?
        for location in range {
            let charAttrs = self.attributedText.attributes(at: location, effectiveRange: nil)
            if let charSchemeUrl = charAttrs[.link] as? URL {
                if firstSchemeUrl == nil {
                    firstSchemeUrl = charSchemeUrl
                } else if charSchemeUrl != firstSchemeUrl {
                    return false
                }
            } else {
                return false
            }
        }
        return firstSchemeUrl != nil
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any!) -> Bool {
        
        if let controller = self.annotationViewController,  controller.isEditMode {
            if [#selector(self.copy(_:)),
                #selector(self.cut(_:)),
                #selector(self.paste(_:)),
                #selector(self.select(_:)),
                #selector(self.selectAll(_:))
            ].contains(action) {
                return super.canPerformAction(action, withSender: sender);
            }
            
            if action == #selector(self.colorMenuItemAction(_:)) {
                return true;
            }
            
            if self.isTextHighLighted() {
                if [#selector(self.lookUpMenuItemAction(_:)), #selector(self.shareMenuItemAction(_:)),
                    #selector(self.delete(_:))].contains(action) {
                    return true
                } else if self.checkIfToShowEditLinkOptions() {
                    if [#selector(self.editLinkMenuItemAction(_:)), #selector(self.removeLinkMenuItemAction(_:))].contains(action) {
                        return true
                    }
                } else if [#selector(self.linkMenuItemAction(_:))].contains(action) {
                    return true
                }
            }
        }
        
        if action == Selector(("replace:")) {
            return true
        }
        return false
    }

}

#if !targetEnvironment(macCatalyst)
private extension FTTextView {
    func updateMenuItems() {
        let colorMenuItem: UIMenuItem = UIMenuItem(title: NSLocalizedString("Color", comment: "Color"), action: #selector(FTTextView.colorMenuItemAction(_:)))
        let lookUpMenuItem: UIMenuItem = UIMenuItem(title: NSLocalizedString("LookUp", comment: "Look Up"), action: #selector(FTTextView.lookUpMenuItemAction(_:)))
        let shareMenuItem: UIMenuItem = UIMenuItem(title: NSLocalizedString("Share", comment: "Share"), action: #selector(FTTextView.shareMenuItemAction(_:)))
        
        let linkMenuItem = UIMenuItem(title: "textLink_linkTo".localized, action: #selector(FTTextView.linkMenuItemAction(_:)))
        let editLinkITem = UIMenuItem(title: "textLink_editLink".localized, action: #selector(FTTextView.editLinkMenuItemAction(_:)))
        let removeLinkItem = UIMenuItem(title: "textLink_removeLink".localized, action: #selector(FTTextView.removeLinkMenuItemAction(_:)))

        let menuItems: [UIMenuItem] = [colorMenuItem, lookUpMenuItem, shareMenuItem, linkMenuItem, editLinkITem, removeLinkItem]
        let menuController = UIMenuController.shared
        menuController.menuItems = menuItems
    }
}
#endif
