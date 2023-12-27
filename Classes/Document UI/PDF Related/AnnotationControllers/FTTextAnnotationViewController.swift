//
//  FTTextAnnotationViewController.swift
//  Noteshelf
//
//  Created by Naidu on 07/01/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

let TEXT_AREA_BORDER_SIZE  =  10
private let TEXT_KNOB_SIZE  =  8
private let TEXT_KNOB_OFFSET: CGFloat = 4;
private let Text_Offset: CGFloat = 10;
private let TEXT_TOP_KNOB_WIDTH = 24
private let TEXT_TOP_KNOB_HEIGHT = 8
private let TEXT_TOP_KNOB_TAG = 101

let ftDidTextAnnotationResignNotifier = Notification.Name("FTDidTextboxResignResponder")

enum FTKnobPosition : Int{
    case FTKnobPositionNone = -1
    case FTKnobPositionLeft = 100
    case FTKnobPositionRight
}

private enum FTKnobResizeDirection : Int{
    case topLeft,topRight,bottomLeft,bottomRight;
}

private enum FTTextBoxResizeMode: Int {
    case none
    case dynamic
    case fixed
}

protocol FTTextAnnotationDelegate: NSObjectProtocol {
    func didChangeSelectionAttributes(_ attributes: [NSAttributedString.Key : Any]?, scale: CGFloat)
}

class FTTextAnnotationViewController: UIViewController {
    
    private var touchDownTime: TimeInterval = Date().timeIntervalSince1970;
    weak var delegate: FTAnnotationEditControllerDelegate?
    fileprivate var annotationMode: FTAnnotationMode = FTAnnotationMode.create
    fileprivate var _annotation: FTAnnotation?
    private var transitionInProgress: Bool = false
    private var contentHolderview : UIView?;
    let customTransitioningDelegate = FTSlideInPresentationManager(mode: .topToBottom)

    private var resizeMode: FTTextBoxResizeMode = .none;
    private var resizeDirection = FTKnobResizeDirection.bottomRight;
    private var knobHandlerImage: UIImageView!

    // Don't make below viewmodel weak as this is needed for eyedropper delegate to be implemented here(since we are dismissing color edit controller)
    internal var penShortcutViewModel: FTPenShortcutViewModel?

#if targetEnvironment(macCatalyst)
    private var forceEndEditing: Bool = false
#endif

    private weak var referenceLibraryController: FTReferenceLibraryViewController?;
    var linkSelectedRange: NSRange?
    
    var annotation: FTAnnotation {
        return _annotation!;
    }
    var supportOrientationChanges: Bool {
        return true
    }
    
    private var checkBoxGesture : FTTextAttachmentTapGesture?;
    
    fileprivate var isEmpty: Bool {
        if !textInputView.attributedText.string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
            return false
        }
        return true
    }
    
    fileprivate var autocorrectionType : UITextAutocorrectionType {
        get {
            return self.textInputView.autocorrectionType
        }
        set {
            self.textInputView.autocorrectionType = newValue
        }
    }
    
    private var textFrame: CGRect {
        get {
            let transform = self.view.transform;
            self.view.transform = CGAffineTransform.identity;
            var frame = self.view.frame;
            frame = frame.insetBy(dx: Text_Offset, dy: Text_Offset);
            self.view.transform = transform;
            return frame;
        }
        set {
            let transform = self.view.transform;
            self.view.transform = CGAffineTransform.identity;
            self.view.frame = newValue.insetBy(dx: -Text_Offset, dy: -Text_Offset);
            var newFrame = newValue;
            newFrame.origin = CGPoint(x:Text_Offset,y:Text_Offset);
            self.contentHolderview?.frame = newFrame;
            self.view.transform = transform;
        }
    }
    
    internal var isEditMode: Bool {
        return self.editMode
    }
    
    private var editMode : Bool {
        get {
            return textInputView.isUserInteractionEnabled
        }
        set {
            if newValue == textInputView.isUserInteractionEnabled { return }
            if newValue {
                textInputView.isEditable = true;
                textInputView.isUserInteractionEnabled = true
                self.checkBoxGesture?.isEnabled = false;
                self.autocorrectionType = UITextAutocorrectionType.yes
                UIMenuController.shared.hideMenu()
                _ = self.becomeFirstResponder()
                textInputView.layoutManager.invalidateDisplay(forCharacterRange: NSRange(location: 0, length: textInputView.textStorage.length));
            }
            else {
                textInputView.isEditable = false;
                self.checkBoxGesture?.isEnabled = true;
                textInputView.isUserInteractionEnabled = false
                self.autocorrectionType = UITextAutocorrectionType.no
                #if !targetEnvironment(macCatalyst)
                    _ = self.resignFirstResponder()
                NotificationCenter.default.post(name: ftDidTextAnnotationResignNotifier, object: nil)
                #endif
            }
        }
    }
    
    fileprivate var zoomScale : CGFloat {
        let contentScale = self.delegate?.contentScale() ?? 1;
        return contentScale
    }
    
    internal var textInputView : FTTextView!
    
    fileprivate var attributedString : NSAttributedString {
        get {
            let attributes: NSMutableAttributedString? = textInputView.attributedText.mutableDeepCopy()
            attributes?.applyScale(1 / textInputView.scale, originalScaleToApply: 1 * textInputView.transformScale)
//            if let length = attributes?.length,length > 0 {
//                attributes?.removeAttribute(.link, range: NSRange(location: 0, length: length));
//            }
            return attributes!
        }
        set {
            let str = newValue.mapAttributesToMatch(withLineHeight: -1)?.mutableDeepCopy()
            str?.applyScale(textInputView.scale, originalScaleToApply: textInputView.scale * textInputView.transformScale)
            textInputView.attributedText = str
            textInputView.backgroundColor = textInputView.attribute(NSAttributedString.Key.backgroundColor.rawValue, in: NSRange(location: 0, length: str?.length ?? 0)) as? UIColor
            if newValue.length > 0 && textInputView.selectedRange.location == newValue.length {
                let font = str?.attribute(NSAttributedString.Key.font, at: newValue.length - 1, effectiveRange: nil) as? UIFont
                if nil != font {
                    textInputView.setValue(font, forAttribute:NSAttributedString.Key.font.rawValue, in: textInputView.selectedRange)
                }
            }
        }
    }
    
    fileprivate var isMoving : Bool = false
    fileprivate var isScaling : Bool = false
    fileprivate var counter = 0
    fileprivate var resizeKnobImageView : UIImageView!
    
    weak var textSelectionDelegate: FTTextAnnotationDelegate?
    
    required init(withAnnotation annotation: FTAnnotation,
                  delegate: FTAnnotationEditControllerDelegate?,
                  mode: FTAnnotationMode)
    {
        super.init(nibName: nil, bundle: nil);
        self._annotation = annotation
        self.delegate = delegate
        self.annotationMode = mode
        let contentScale = delegate?.contentScale() ?? CGFloat(1);
        
        self.view.autoresizingMask = [UIView.AutoresizingMask.init(rawValue: 0)];

        self.view.isExclusiveTouch = true
        self.textFrame = CGRectScale(annotation.boundingRect, contentScale)
        self.loadInputTextView(annotation.associatedPage)
        self.textInputView.touchHandler = self;
        if let annotation = annotation as? FTTextAnnotation{
            self.view.transform = CGAffineTransform(rotationAngle: annotation.rotationAngle)

            if let attrStr = annotation.attributedString {
                if attrStr.length > 0 {
                    self.attributedString = annotation.attributedString!
                    self.setTextBackgroundColor(annotation.backgroundColor())
                }
            }
            self.checkBoxGesture = FTTextAttachmentTapGesture.init(target: self, action: #selector(didTapOnView(_:)))
            self.checkBoxGesture?.supportedActionType = FTActionSupport.all;
            self.checkBoxGesture?.textView = self.textInputView
            if self.checkBoxGesture != nil {
                self.contentHolderview?.addGestureRecognizer(self.checkBoxGesture!);
            }
            self.checkBoxGesture?.isEnabled = false;
        }
        self.textInputView.scale = contentScale;
        self.checkBoxGesture?.isEnabled = false
        
        self.updateResizeMode();
        
        NotificationCenter.default.addObserver(forName: Notification.Name.didUpdateAnnotationNotification,
                                               object: annotation,
                                               queue: nil) { [weak self] (notification) in
            self?.refreshView();
        }
       
        #if targetEnvironment(macCatalyst)
        NotificationCenter.default.addObserver(forName: Notification.Name.shouldResignTextfieldNotification,
                                               object: nil,
                                               queue: nil) { [weak self] (notification) in
            self?.forceEndEditing = true
        }
        
        let contextMenu = UIContextMenuInteraction.init(delegate: self)
        self.view.addInteraction(contextMenu)
        #endif
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = FTAnnotationBaseView.init(frame: UIScreen.main.bounds, touchEventHandler: self, menuHandler: self)
        self.view = view
    }

    override func viewDidLoad() {
        super.viewDidLoad();
        let frame = self.view.bounds.insetBy(dx: Text_Offset, dy: Text_Offset);
        let contentView = UIView(frame: frame);
        contentView.autoresizingMask = [.flexibleWidth,.flexibleHeight];
        self.view.addSubview(contentView);
        self.contentHolderview = contentView;
        }

    private func loadInputTextView(_ page : FTPageProtocol?) {
        let version = self.annotation.version
        var transformScale: Float = 0.0
        if let ann = self.annotation as? FTTextAnnotation {
            transformScale  = ann.transformScale
        }
        let textView = FTTextView(frame: self.contentHolderview?.bounds ?? CGRect.zero,
                                  annotationVersion: version,
                                  transformScale: CGFloat(transformScale), annotationViewController: self)
        textView.delegate = self
        textView.attributedText = NSAttributedString.init(string: "")
        textView.isUserInteractionEnabled = false
        self.textInputView = textView
        self.contentHolderview?.addSubview(self.textInputView)
        
        self.resizeKnobImageView = UIImageView.init(frame: CGRect(x: 0,
                                                                  y: 0,
                                                                  width: TEXT_KNOB_SIZE,
                                                                  height: TEXT_KNOB_SIZE))
        self.resizeKnobImageView.image = UIImage(named: "text_resize_indicator")
        self.resizeKnobImageView.isUserInteractionEnabled = true
        self.resizeKnobImageView.tag = FTKnobPosition.FTKnobPositionLeft.rawValue
        self.resizeKnobImageView.backgroundColor = .clear
        self.resizeKnobImageView.isHidden = false
        self.contentHolderview?.addSubview(self.resizeKnobImageView)
        
        self.knobHandlerImage = UIImageView.init(frame: CGRect(x: 0,
                                                                  y: 0,
                                                                  width: TEXT_TOP_KNOB_WIDTH,
                                                                  height: TEXT_TOP_KNOB_HEIGHT))
        self.knobHandlerImage.image = UIImage(named: "text_knob_handler")
        //self.knobHandlerImage.isUserInteractionEnabled = true
        self.knobHandlerImage.tag = TEXT_TOP_KNOB_TAG
        self.knobHandlerImage.backgroundColor = .clear
        self.knobHandlerImage.isHidden = false
        self.view.addSubview(self.knobHandlerImage)
        self.view.bringSubviewToFront(self.knobHandlerImage)
        
        let backgroundColorString = UserDefaults.standard.string(forKey: "text_background_color")
        if let bgColorStr = backgroundColorString, bgColorStr != UIColor.clear.hexStringFromColor() {
            self.setTextBackgroundColor(UIColor(hexString: backgroundColorString))
            track("textmode_page_tapped", params: ["postit_color" : bgColorStr], screenName: FTScreenNames.textbox)
        }
        else {
            self.setTextBackgroundColor(UIColor.clear)
            track("textmode_page_tapped", params: ["postit_color" : "clear"], screenName: FTScreenNames.textbox)
        }
        
        //update default properties
        if let defaultFont = page?.parentDocument?.localMetadataCache?.defaultBodyFont {
            textInputView.setValue(defaultFont,
                                   forAttribute: NSAttributedString.Key.font.rawValue,
                                   in: NSRange(location: 0, length: 0))
        }
        if let defaultColor = page?.parentDocument?.localMetadataCache?.defaultTextColor {
            textInputView.setValue(defaultColor,
                                   forAttribute: NSAttributedString.Key.foregroundColor.rawValue,
                                   in: NSRange(location: 0, length: 0))
        }
        if let underlineValue = page?.parentDocument?.localMetadataCache?.defaultIsUnderline {
            textInputView.setValue(NSNumber.init(value: underlineValue),
                                   forAttribute: NSAttributedString.Key.underlineStyle.rawValue,
                                   in: NSRange(location: 0, length: 0))
        }
        if let strikeThrough = page?.parentDocument?.localMetadataCache?.defaultIsStrikeThrough {
            textInputView.setValue(NSNumber.init(value: strikeThrough),
                                   forAttribute: NSAttributedString.Key.strikethroughStyle.rawValue,
                                   in: NSRange(location: 0, length: 0))
        }
        if let alignment = page?.parentDocument?.localMetadataCache?.defaultTextAlignment, let lineSpace = page?.parentDocument?.localMetadataCache?.defaultAutoLineSpace  {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = CGFloat(lineSpace)
            paragraphStyle.alignment = NSTextAlignment(rawValue: alignment) ?? .left
            textInputView.setValueFor(paragraphStyle, forAttribute: NSAttributedString.Key.paragraphStyle.rawValue, in: NSRange(location: 0, length: 0))
        }

        if let isAutoLineSpaceEnabled = page?.parentDocument?.localMetadataCache?.defaultIsLineSpaceEnabled {
            textInputView.setValueFor(NSNumber.init(value: isAutoLineSpaceEnabled), forAttribute: FTFontStorage.isLineSpaceEnabledKey, in: NSRange(location: 0, length: 0))
        }
        textView.scale = self.zoomScale

        #if targetEnvironment(macCatalyst)
            self.delegate?.annotationControllerWillBeginEditing?(self)
        #endif
        self.delegate?.annotationControllerDidAdded(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let contentView = self.contentHolderview else {
            return;
        }
        if textInputView != nil {
            textInputView.frame = contentView.bounds.integral
        }
        if resizeKnobImageView != nil {
            var frame = resizeKnobImageView.frame
            let completeframe = contentView.bounds
            frame.origin.x = completeframe.width - frame.size.width - TEXT_KNOB_OFFSET
            frame.origin.y = completeframe.height - frame.size.height - TEXT_KNOB_OFFSET;
            resizeKnobImageView.frame = frame
        }
        
        if knobHandlerImage != nil {
            var frame = knobHandlerImage.frame
            let completeframe = contentView.bounds
            frame.origin.x = completeframe.width/2 //- CGFloat(TEXT_TOP_KNOB_WIDTH/2)
            frame.origin.y = 6
            knobHandlerImage.frame = frame
        }
    }
   
    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator);
        transitionInProgress = true
        
        coordinator.animate(alongsideTransition: { (_) in
        }) { [weak self] (_) in
            self?.transitionInProgress = false
            self?.scheduleScrolling(delay: 0.3);
        }
    }
    
    // MARK: Gesture
    @objc func didTapOnView(_ gesture: FTTextAttachmentTapGesture?) {
        if let textAttachment = gesture?.actionAttribute as? NSTextAttachment,
            let range = gesture?.range {
            _ = self.textInputView.delegate?.textView?(self.textInputView,
                                                       shouldInteractWith: textAttachment,
                                                       in: range,
                                                       interaction: .invokeDefaultAction);
        }
        else if let urlAction = gesture?.actionAttribute as? URL,
            let range = gesture?.range {
            _ = self.textInputView.delegate?.textView?(self.textInputView,
                                                       shouldInteractWith: urlAction,
                                                       in: range,
                                                       interaction: .invokeDefaultAction);
        }
    }

    // MARK: UIResponder
    override func becomeFirstResponder() -> Bool {
        return textInputView.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        return textInputView.resignFirstResponder()
    }
    
    override var isFirstResponder: Bool {
        return textInputView.isFirstResponder
    }
        
    @objc fileprivate func saveTextEntryAttributes() {
        //Check if the text is empty in which case we can remove the annotation object.
        var shouldRemove = false;
        #if targetEnvironment(macCatalyst)
        shouldRemove = (self.isEmpty && !self.isEditMode && !transitionInProgress)
        #else
        shouldRemove = (self.isEmpty && !self.isFirstResponder && !transitionInProgress)
        #endif
        if shouldRemove {
            self.delegate?.annotationControllerDidRemoveAnnotation(self, annotation: self.annotation)
        }
        else {
            let undoableInfo = self.annotation.undoInfo();
            let rect: CGRect = self.textFrame
            let scale: CGFloat = self.delegate?.contentScale() ?? 1;
            let oneByZoom: CGFloat = 1/scale;
            
            self.annotation.boundingRect = CGRectScale(rect, oneByZoom)
            if let ann = self.annotation as? FTTextAnnotation {
                ann.attributedString = self.attributedString;
            }
            
            if(self.annotationMode == FTAnnotationMode.create) {
                self.delegate?.annotationControllerDidAddAnnotation(self, annotation: self.annotation);
                self.annotationMode = FTAnnotationMode.edit
                
                //*******************************
                 track("Textbox_Created", params: ["text_length" : NSNumber.init(value: self.attributedString.length)])
                //***************************************************
            }
            else {
                self.delegate?.annotationControllerDidChange(self,undoableInfo: undoableInfo);
            }
        }
    }
    
    private func scheduleScrolling(delay: TimeInterval = 0) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.scrollToEditingPoint), object: nil);
        self.perform(#selector(self.scrollToEditingPoint), with: nil, afterDelay: delay);
    }
    
    @objc fileprivate func scrollToEditingPoint() {
        //Bring the current editing area to view if needed
        
        //The text view may have residged first responder already
        //This can happen becasue this nmethod is being called from a dalayed selector
        if !textInputView.isFirstResponder {
            return;
        }
        var targetRect = currentCursorPosition();
        targetRect = self.view.convert(targetRect, from: textInputView);
        self.delegate?.annotationController(self, scrollToRect: targetRect);
    }
    
    internal func presentLookUpScreen(_ text: String) {
        let refLibController = FTReferenceLibraryViewController(term: text)
        refLibController.title = text
        self.referenceLibraryController = refLibController;
        self.editMode = false
        UIMenuController.shared.hideMenu()
        refLibController.onCompletion = { [weak self] in
            self?.setupMenuForTextViewLongPress();
        }
        self.present(refLibController, animated: true, completion: nil)
    }

    internal func handleEditMenuActionForLongPress() {
        self.editMode = true
    }
    
    func allowsEdit() {
        runInMainThread(0.1) {
            self.editMode = true
        }
    }
    
    internal func setRange(_ cursorRange: NSRange, selectedTextRange: UITextRange) {
        self.textInputView.selectedRange = cursorRange
        self.textInputView.selectedTextRange = selectedTextRange
    }

    func setTextColor(_ textColor: UIColor?, in range: NSRange) {
        textInputView.setValue(textColor, forAttribute: NSAttributedString.Key.foregroundColor.rawValue, in: range)
    }
}

//MARK: - Helpers
fileprivate extension FTTextAnnotationViewController {
    
    func adjustFrameOrigin(withinBoundary frame: CGRect) -> CGPoint {
        var newOrigin: CGPoint = frame.origin
        //Always keep the textbox position at least 40px inside the writing area
        let transform = self.view.transform
        self.view.transform = .identity
        let windowBounds: CGRect = self.view.superview!.bounds
        self.view.transform = transform

        let maxWidth = windowBounds.width
        let maxHeight = windowBounds.height
        if newOrigin.x > (maxWidth - 40) {
            newOrigin.x = maxWidth - 40
        }
        
        if newOrigin.y > (maxHeight - 40) {
            newOrigin.y = maxHeight - 40
        }
        
        if newOrigin.x < -frame.size.width + 40 {
            newOrigin.x = -frame.size.width + 40
        }
        
        if newOrigin.y < -frame.size.height + 40 {
            newOrigin.y = -frame.size.height + 40
        }
        return frame.origin
    }
    
    func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        var hitTest: UIView? = self.view.hitTest(point, with: event)
       
        let knoPoint = self.view.convert(point, to: self.contentHolderview);
        let knobFrame = resizeKnobImageView.frame.insetBy(dx: -13, dy: -13);
        if knobFrame.contains(knoPoint) {
            hitTest = resizeKnobImageView
        }
        return hitTest
    }
    
    func defaultTextFont() -> UIFont? {
        return textInputView.defaultAttributes[NSAttributedString.Key.font] as? UIFont
    }
    
    func minSizeToFit() -> CGSize {
        let minSize = NSAttributedString.minSizeToFit(defaultTextFont(),
                                                      scale: self.zoomScale,
                                                      containerInset: textInputView.textContainerInset);
        return minSize
    }
    
    func currentCursorPosition() -> CGRect {
        textInputView.boundsOf(textInputView.selectedTextRange)
    }
        
    func currentBulletType() -> FTBulletType {
        let style = textInputView.typingAttributes[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle
        let currentType : FTBulletType = style?.bulletType(withScale: textInputView.scale * textInputView.transformScale) ?? .none;
        return currentType
    }
    
    func validateKeyboard() {
        let inTextView = textInputView
        let selectedRange: NSRange? = inTextView?.selectedRange
        var typingAttributes = inTextView?.typingAttributes
        if Int(selectedRange?.length ?? 0) > 0 {
            typingAttributes = inTextView?.textStorage.attributes(at: Int(selectedRange?.location ?? 0), effectiveRange: nil)
        }
        self.textSelectionDelegate?.didChangeSelectionAttributes(typingAttributes, scale: textInputView.scale)
    }

    func updateResizeMode() {
        let isClearBackground = self.textInputView.backgroundColor == nil || self.textInputView.backgroundColor == UIColor.clear;
        if self.resizeMode == .none,
            self.annotationMode == .create,
            self.textInputView.attributedText.length == 0,
            (isClearBackground) {
            self.resizeMode = .dynamic;
        }
        else {
            self.resizeMode = .fixed;
        }
    }
    
    func updateLayerBorder() {
        if let bgColor = self.textInputView.backgroundColor,
           !bgColor.hexStringFromColor().isEqual(UIColor.clear.hexStringFromColor()) {
            
            print(bgColor.hexStringFromColor(), UIColor.clear.hexStringFromColor())
            self.contentHolderview?.layer.borderWidth = 1.0
            self.contentHolderview?.layer.borderColor = UIColor.appColor(.black50).cgColor
        }
        else {
            self.contentHolderview?.layer.borderWidth = 1.0
            self.contentHolderview?.layer.borderColor = UIColor.appColor(.grayDim).cgColor
        }
    }
    
    func resizeTextViewAsNeeded() {
        guard let contentView = self.contentHolderview else {
            return;
        }
        
        if let visibleRect = self.delegate?.visibleRect() {
            let minSize: CGSize = minSizeToFit()

            let transform = self.view.transform
            self.view.transform = .identity
            var attributedStringSize = self.textInputView.textUsedSize();
            var newWidth = contentView.bounds.width;
            self.view.transform = transform
            if(self.resizeMode == .dynamic) {
                let offset: CGFloat = TEXT_ANNOTATION_OFFSET;
                let maxWidth = visibleRect.maxX - self.textFrame.minX - offset;
                attributedStringSize = self.textInputView.attributedText.requiredAttributedStringSize(maxWidth: maxWidth, containerInset: self.textInputView.textContainerInset);
                newWidth = max(attributedStringSize.width, newWidth)
            }
            newWidth = max(newWidth, minSize.width);
            
            var newHeight = max(attributedStringSize.height, minSize.height)
            newHeight = max(contentView.bounds.size.height, newHeight)
            
            let curFrame = self.textFrame;
            self.textFrame = CGRect(x: curFrame.origin.x,
                                     y: curFrame.origin.y,
                                     width: newWidth,
                                     height: newHeight);
        }
    }
}

//MARK: - Setting TextView values
fileprivate extension FTTextAnnotationViewController {
    
    func setFontStyle(_ fontStyle : UIFont) {
        let fontStyle1 = UIFont(name: fontStyle.fontName, size: fontStyle.pointSize)
        let selectedRange: NSRange = textInputView.selectedRange
        textInputView.setValue(fontStyle1, forAttribute: NSAttributedString.Key.font.rawValue, in: selectedRange)
    }
    
    func setFontStyle(_ fontStyle : UIFont , range : NSRange) {
        textInputView.setValue(fontStyle, forAttribute: NSAttributedString.Key.font.rawValue, in: range)
    }
    
    func increaseIndent() {
        _ = textInputView.increaseIndentationForcibly(true, editing: textInputView.selectedRange, scale: textInputView.scale * textInputView.transformScale)
    }
    
    func decreaseIndent() {
        _ = textInputView.decreaseIndentationForcibly(true, editing: textInputView.selectedRange, scale: textInputView.scale * textInputView.transformScale)
    }
    
    
    func textInputAccessoryDidChangeTextSize(_ textSize: CGFloat, canUndo: Bool) {
        let currentString: NSAttributedString? = attributedString
        let selectedRange: NSRange = textInputView.selectedRange
        if Int(selectedRange.length) == 0 {
            let typingAttributes = textInputView.typingAttributes
            let currentFont = typingAttributes[NSAttributedString.Key.font] as? UIFont
            if nil != currentFont {
                let newFont: UIFont? = currentFont?.withSize(textSize)
                setFontStyle(newFont!, range: selectedRange)
            }
        }
        else {
            if let currentStringNew = currentString {
                currentStringNew.enumerateAttribute(NSAttributedString.Key.font, in: textInputView.selectedRange, options: [], using: { value, range, _ in
                    let currentFont = value as? UIFont
                    let newFont: UIFont? = currentFont?.withSize(textSize)
                    self.setFontStyle(newFont!, range: range)
                })
            }
        }
        if canUndo {
            saveTextEntryAttributes()
            validateKeyboard()
        }
    }
    
    func setTextBackgroundColor(_ inBackgroundColor: UIColor?) {
        textInputView.setValue(inBackgroundColor, forAttribute: NSAttributedString.Key.backgroundColor.rawValue, in: NSRange(location: 0, length: textInputView.attributedText.length))
        textInputView.setValue(inBackgroundColor, forAttribute: NSAttributedString.Key.backgroundColor.rawValue, in: NSRange(location: 0, length: 0))
        textInputView.backgroundColor = inBackgroundColor
        self.updateLayerBorder();
    }
    
    func removeBullets(_ sender: Any?) {
        textInputView.replaceBullets(withTextLists: nil, for: textInputView.selectedRange, scale: textInputView.scale * textInputView.transformScale)
        saveTextEntryAttributes()
    }
    
    func insertBullet(_ sender: Any?, type: FTBulletType) {
        if currentBulletType() == type {
            removeBullets(nil)
        } else {
            switch type {
            case .one:
                let box = FTTextList.textListWithMarkerFormat("{disc}", option: 0)
                let hyphen = FTTextList.textListWithMarkerFormat("{hyphen}", option: 0)
                textInputView.replaceBullets(withTextLists: [box,hyphen], for: textInputView.selectedRange, scale: textInputView.scale * textInputView.transformScale)
            case .two:
                let box = FTTextList.textListWithMarkerFormat("{box}", option: 0)
                let circle = FTTextList.textListWithMarkerFormat("{square}", option: 0)
                let diamond = FTTextList.textListWithMarkerFormat("{octal}", option: 0)
                
                textInputView.replaceBullets(withTextLists: [box, circle, diamond], for: textInputView.selectedRange, scale: textInputView.scale * textInputView.transformScale)
            case .numbers, .none:
                let decimal = FTTextList.textListWithMarkerFormat("{decimal}", option: 0)
                let alpha = FTTextList.textListWithMarkerFormat("{upper-alpha}", option: 0)
                
                textInputView.replaceBullets(withTextLists: [decimal, alpha], for: textInputView.selectedRange, scale: textInputView.scale * textInputView.transformScale)
            case .checkBox:
                let box = FTTextList.textListWithMarkerFormat("{checkbox}", option: 0)
                textInputView.replaceBullets(withTextLists: [box], for: textInputView.selectedRange, scale: textInputView.scale * textInputView.transformScale)
                
            }
        }
        saveTextEntryAttributes()
    }
}

//MARK: - UITextViewDelegate
extension FTTextAnnotationViewController : UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        validateKeyboard()
        self.scheduleScrolling(delay: 0.4)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        #if !targetEnvironment(macCatalyst)
        if(!transitionInProgress) {
            self.editMode = false
        }
        resizeTextViewAsNeeded()
        saveTextEntryAttributes()
        runInMainThread { [weak self] in
            if nil == self?.referenceLibraryController {
                //self?.setupMenuForTextViewLongPress()
            }
        }
        #else
        resizeTextViewAsNeeded()
        saveTextEntryAttributes()
        #endif
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        #if targetEnvironment(macCatalyst)
        return self.forceEndEditing;
        #else
        return true
        #endif
    }
    
    func textViewDidChange(_ textView: UITextView) {
        resizeTextViewAsNeeded()
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.saveTextEntryAttributes), object: nil)
        perform(#selector(self.saveTextEntryAttributes), with: nil, afterDelay: 2)
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        let rect: CGRect = currentCursorPosition()
        //added below condition as due to internal layout issue in ios 10, the textview will take bit time to reset its caret rect.
        if .infinity == rect.minY && counter < 5 {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.05 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
                // Recall
                self.counter += 1
                self.textViewDidChangeSelection(textView)
            })
        } else {
            counter = 0
            self.scheduleScrolling();
            validateKeyboard()
        }
        
    }
    
        //#if SUPPORTS_BULLETS
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        //Remove any submenu's in toolbar
        let contentScale = self.zoomScale;
        var returnValue = true
        
        if (text == "\n") {
            if textInputView.hasBulletsInLineParagraph(for: textView.selectedRange) {
                returnValue = textView.autoContinueBullets(forEditing: textView.selectedRange, scale: contentScale * textInputView.transformScale)
            }
        }
        
        if (text == "\t") {
            returnValue = textView.increaseIndentationForcibly(false, editing: textView.selectedRange, scale: contentScale * textInputView.transformScale)
        }
        if (text == "") && (range.length <= 1 || textView.shouldConsiderForDecrementIndentation(onDeleting: range, scale: contentScale * textInputView.transformScale)) {
            returnValue = textView.decreaseIndentationForcibly(false, editing: textView.selectedRange, scale: contentScale * textInputView.transformScale)
        }
        return returnValue
    }
    
    func textView(_ textView: UITextView,
                  shouldInteractWith textAttachment: NSTextAttachment,
                  in characterRange: NSRange,
                  interaction: UITextItemInteraction) -> Bool {
        let val = textStorageShouldInteractWith(textView.textStorage , attachment : textAttachment , characterRange : characterRange)
        if val {
            saveTextEntryAttributes()
        }
        return val;
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL,
                  in characterRange: NSRange,
                  interaction: UITextItemInteraction) -> Bool {
        URL.openURL(on: self);
        return false;
    }
    
    func textStorageShouldInteractWith(_ textStorage : NSTextStorage ,
                                       attachment : NSTextAttachment ,
                                       characterRange : NSRange) -> Bool {
        let scale = Float(self.zoomScale * textInputView.transformScale)
        
        let checkBoxOffAttachment = NSTextAttachment()
        checkBoxOffAttachment.image = UIImage(named: "check-off-2x.png")
        checkBoxOffAttachment.updateFileWrapperIfNeeded()
        checkBoxOffAttachment.bounds = CGRect(x: 0, y: Int(CHECK_BOX_OFFSET_Y), width: Int(CHECKBOX_WIDTH), height: Int(CHECKBOX_HEIGHT))
        checkBoxOffAttachment.bounds = CGRectScale(checkBoxOffAttachment.bounds, CGFloat(scale))
        
        let checkBoxonAttachment = NSTextAttachment()
        checkBoxonAttachment.image = UIImage(named: "check-on-2x.png")
        checkBoxonAttachment.updateFileWrapperIfNeeded()
        checkBoxonAttachment.bounds = CGRect(x: 0, y: Int(CHECK_BOX_OFFSET_Y), width: Int(CHECKBOX_WIDTH), height: Int(CHECKBOX_HEIGHT))
        checkBoxonAttachment.bounds = CGRectScale(checkBoxonAttachment.bounds, CGFloat(scale))
        
        let contents: Data? = attachment.fileWrapper?.regularFileContents
        
        let checkOnData: Data? = checkBoxonAttachment.fileWrapper?.regularFileContents
        let checkOffData: Data? = checkBoxOffAttachment.fileWrapper?.regularFileContents
        if nil == checkOnData || nil == checkOffData {
            UIAlertController.showAlertForiOS12TextAttachmentIssue(from: self.view.window?.visibleViewController)
            return false
        }
        var isSameAsCheckOff: Bool = contents == checkOffData
        var isSameAsCheckOn: Bool = contents == checkOnData
        
        if contents != nil && !isSameAsCheckOff && !isSameAsCheckOn {
            //isEqualToData is not working always, if isEqualToData fails checking UIImagePNGRepresentation
            var contentInfo: Data?
            var checkOnContentInfo: Data?
            var checkOffContentInfo: Data?
            if let data = UIImage(data: contents!)!.pngData() {
                contentInfo = data
            }
            if let checkOnData1 = UIImage(data: checkOnData!)!.pngData() {
                checkOnContentInfo = checkOnData1
            }
            if let checkOffData1 = UIImage(data: checkOffData!)!.pngData() {
                checkOffContentInfo = checkOffData1
            }
            
            if checkOffContentInfo != nil {
                isSameAsCheckOff = contentInfo == checkOffContentInfo
            }
            if checkOnContentInfo != nil {
                isSameAsCheckOn = contentInfo == checkOnContentInfo
            }
        }
        
        //since in iOS12 there was an issue where the textattachment was not stored properly and the file wrapper for new textattachment creation was not having file wrapper as a work around we are depending on the data size to determine the type of check box.
        
        if contents != nil && !isSameAsCheckOff && !isSameAsCheckOn {
            let contentLength: Int = contents!.count
            if contentLength <= checkOffData!.count {
                isSameAsCheckOff = true
            } else if contentLength > checkOffData!.count && contentLength <= (checkOnData!.count + 10) {
                isSameAsCheckOn = true
            }
        }
        
        if isSameAsCheckOff {
            let str = NSAttributedString(attachment: checkBoxonAttachment)
            
            var attrs = textStorage.attributes(at: characterRange.location, effectiveRange: nil)
            attrs.removeValue(forKey: NSAttributedString.Key.attachment)
            
            textStorage.beginEditing()
            textStorage.replaceCharacters(in: characterRange, with: str)
            textStorage.addAttributes(attrs, range: characterRange)
            textStorage.endEditing()
        }
        else if isSameAsCheckOn {
            let str = NSAttributedString(attachment: checkBoxOffAttachment)
            var attrs = textStorage.attributes(at: characterRange.location, effectiveRange: nil)
            attrs.removeValue(forKey: NSAttributedString.Key.attachment)
            
            textStorage.beginEditing()
            textStorage.replaceCharacters(in: characterRange, with: str)
            textStorage.addAttributes(attrs, range: characterRange)
            textStorage.endEditing()
        }
        return false
    }
    //    #endif
}

extension FTTextAnnotationViewController: FTTextToolBarDelegate {
    func didSelectTextToolbarOption(_ option: FTTextToolBarOption) {
        switch option {
        case .leftIndent:
            self.textInputAccessoryDidChangeIndent(.left)
        case .rightIndent:
            self.textInputAccessoryDidChangeIndent(.right)
        case .bullets:
            self.textInputAccessoryDidChangeBullet(.one)
        case .numbersList:
            self.textInputAccessoryDidChangeBullet(.numbers)
        case .checkBox:
            self.textInputAccessoryDidChangeBullet(.checkBox)
        default:
            break
        }
    }
    
    func didSelectFontStyle(_ style: FTTextStyleItem) {
        self.textInputDidChangeStyle(style)
    }
    
    func didChangeBackgroundColor(_ color: UIColor) {
        self.textInputAccessoryDidChangeColor(color)
    }
    
    func currentTextInputView() -> FTTextView {
        return textInputView
    }

    func addTextInputView(_ inputController: UIViewController?) {
        textInputView.inputView = inputController?.view
        textInputView.reloadInputViews()
    }
    
    func didChangeTextAlignmentStyle(style: NSTextAlignment) {
        self.textInputAccessoryDidChangeTextAlignment(style)
    }
    
    func didChangeLineSpacing(lineSpace: CGFloat) {
        self.textInputAccessoryDidChangeLineSpacing(lineSpace)
    }

    func didAutoLineSpaceStatusChanged(_ status: Bool) {
        self.textInputAccessoryDidChangeAutoLineSpace(status)
    }

    func didSelectTextRange(range: NSRange?, txtRange: UITextRange?, canEdit: Bool) {
        if canEdit {
            self.allowsEdit()
        }
        guard let _range = range, let _txtRange = txtRange else { return }
        self.textInputView.selectedRange = _range
        self.textInputView.selectedTextRange = _txtRange
    }
    
    func didChangeFontTrait(_ trait: UIFontDescriptor.SymbolicTraits) {
        self.textInputAccessoryDidChangeFontTrait(trait)
    }
    
    func didToggleUnderline() {
        self.textInputAccessoryDidToggleUnderline()
    }
    
    func didToggleStrikeThrough() {
        self.textInputAccessoryDidToggleStrikeThrough()
    }

    func didSetDefaultStyle(_ info: FTDefaultTextStyleItem) {
    if let ann = self._annotation, let page = ann.associatedPage, let document = page.parentDocument {
        if let defaultFont = UIFont(name: info.fontName, size: CGFloat(info.fontSize)) {
                document.localMetadataCache?.defaultBodyFont = defaultFont
                document.localMetadataCache?.defaultTextColor = UIColor(hexString: info.textColor)
                document.localMetadataCache?.defaultIsUnderline = info.isUnderLined
                document.localMetadataCache?.defaultIsStrikeThrough = info.strikeThrough
                document.localMetadataCache?.defaultTextAlignment = info.alignment
                document.localMetadataCache?.defaultAutoLineSpace = info.lineSpace
                document.localMetadataCache?.defaultIsLineSpaceEnabled = info.isAutoLineSpace
                document.saveDocument(completionHandler: nil)
            }
        }
    }

    func textInputViewCurrentTextView() -> FTTextView? {
        return self.textInputView
    }

    func rootViewController() -> UIViewController? {
        return (self.delegate as? FTPageViewController)?.parent
    }
}

extension FTTextAnnotationViewController {
    func textInputAccessoryDidChangeAutoLineSpace(_ status: Bool) {
        textInputView.setAutoLineSpace(status: status, forEditing: NSRange(location: 0, length: textInputView.attributedText.length))
        if status {
            self.textInputAccessoryDidChangeLineSpacing(0)
        } else {
            saveTextEntryAttributes()
            validateKeyboard()
        }
    }

    func textInputAccessoryDidChangeLineSpacing(_ lineSpace: CGFloat) {
        let contentScale = self.zoomScale;
        textInputView.setLineSpacing(lineSpace: lineSpace * contentScale, forEditing: NSRange(location: 0, length: textInputView.attributedText.length))
        saveTextEntryAttributes()
        validateKeyboard()
    }
    
    func textInputAccessoryDidChangeTextAlignment(_ textAlignment: NSTextAlignment) {
        textInputView.setTextAlignment(textAlignment, forEditing: textInputView.selectedRange)
        saveTextEntryAttributes()
        validateKeyboard()
    }
    
    func textInputAccessoryDidChangeIndent(_ indent: FTTextInputIndent) {
        switch indent {
        case .right:
            increaseIndent()
        case .left:
            decreaseIndent()
        }
        saveTextEntryAttributes()
        validateKeyboard()
    }
    
    func textInputAccessoryDidChangeStyle(_ styleFont: UIFont) {
        setFontStyle(styleFont)
        saveTextEntryAttributes()
        validateKeyboard()
    }
    
    func textInputAccessoryDidChangeTextSize(_ textSize: CGFloat) {
        textInputAccessoryDidChangeTextSize(textSize*textInputView.scale, canUndo: true)
    }
    
    func textInputAccessoryDidChangeBullet(_ bulletStyle: FTBulletType) {
        insertBullet(nil, type: bulletStyle)
        validateKeyboard()
    }
    
    func textInputAccessoryDidToggleUnderline() {
        let selectedRange: NSRange = textInputView.selectedRange
        let underlineStyle = textInputView.attribute(NSAttributedString.Key.underlineStyle.rawValue, in: selectedRange) as? NSNumber
        if Int(truncating: underlineStyle ?? 0) == 0 {
            textInputView.setValue(NSNumber(value: NSUnderlineStyle.single.rawValue), forAttribute: NSAttributedString.Key.underlineStyle.rawValue, in: selectedRange)
        } else {
            textInputView.setValue(nil, forAttribute: NSAttributedString.Key.underlineStyle.rawValue, in: selectedRange)
        }
        validateKeyboard()
    }
    
    func textInputAccessoryDidToggleStrikeThrough() {
        let selectedRange: NSRange = textInputView.selectedRange
        let underlineStyle = textInputView.attribute(NSAttributedString.Key.strikethroughStyle.rawValue, in: selectedRange) as? NSNumber
        if Int(truncating: underlineStyle ?? 0) == 0 {
            textInputView.setValue(NSNumber(value: NSUnderlineStyle.single.rawValue), forAttribute: NSAttributedString.Key.strikethroughStyle.rawValue, in: selectedRange)
        } else {
            textInputView.setValue(nil, forAttribute: NSAttributedString.Key.strikethroughStyle.rawValue, in: selectedRange)
        }
        validateKeyboard()
    }
    
    func textInputAccessoryDidChangeFontTrait(_ trait: UIFontDescriptor.SymbolicTraits) {
        let selectedRange: NSRange = textInputView.selectedRange
        
        let font = textInputView.attribute(NSAttributedString.Key.font.rawValue, in: selectedRange) as? UIFont
        
        var removeTrait = false
        if trait == .traitItalic {
            if (font?.isItalicTrait())! {
                removeTrait = true
            }
        } else if trait == .traitBold {
            if (font?.isBoldTrait())! {
                removeTrait = true
            }
        }
        if selectedRange.length == 0 {
            var fontToApply = textInputView.typingAttributes[NSAttributedString.Key.font] as? UIFont
            if removeTrait {
                fontToApply = fontToApply?.removeTrait(trait)
            } else {
                fontToApply = fontToApply?.addTrait(trait)
            }
            textInputView.setValue(fontToApply, forAttribute: NSAttributedString.Key.font.rawValue, in: selectedRange)
        }
        else {
            textInputView.textStorage.enumerateAttribute(NSAttributedString.Key.font,
                                                         in: selectedRange,
                                                         options: [],
                                                         using: { currentFont, range, _ in
                var fontToApply: UIFont? = currentFont as? UIFont
                if removeTrait {
                    fontToApply = fontToApply?.removeTrait(trait)
                } else {
                    fontToApply = fontToApply?.addTrait(trait)
                }
                textInputView.setValue(fontToApply,
                                       forAttribute: NSAttributedString.Key.font.rawValue,
                                       in: range)
            })
            textInputView.textStorage.endEditing()
        }
        validateKeyboard()
    }
    
    func textInputAccessoryDidChangeFontFamily(_ fontFamily: String) {
        let currentString: NSAttributedString? = attributedString
        let selectedRange: NSRange = textInputView.selectedRange
        // IF TO APPLY CHANGE TO ENTIRE CURSOR's LINE
        //        if selectedRange.length == 0 {
        //            selectedRange = textInputView.text.paragraphRange(for: selectedRange)
        //        }
        if selectedRange.length == 0 {
            let typingAttributes = textInputView.typingAttributes
            let currentFont = typingAttributes[NSAttributedString.Key.font] as? UIFont
            if nil != currentFont {
                var descriptpr = UIFontDescriptor()
                descriptpr = descriptpr.withFamily(fontFamily)
                var newFont = UIFont(descriptor: descriptpr, size: currentFont?.pointSize ?? 0.0)
                if currentFont?.isBoldTrait != nil {
                    newFont = newFont.addTrait(UIFontDescriptor.SymbolicTraits.traitBold)
                }
                if currentFont?.isItalicTrait() != nil {
                    newFont = newFont.addTrait(UIFontDescriptor.SymbolicTraits.traitItalic)
                }
                setFontStyle(newFont, range: selectedRange)
            }
        }
        else {
            if let currentStringNew = currentString {
                currentStringNew.enumerateAttribute(NSAttributedString.Key.font, in: selectedRange, options: [], using: { value, range, _ in
                    let currentFont = value as? UIFont
                    
                    var descriptpr = UIFontDescriptor()
                    descriptpr = descriptpr.withFamily(fontFamily)
                    var newFont = UIFont(descriptor: descriptpr, size: (currentFont?.pointSize ?? 0.0) * self.zoomScale)
                    if currentFont?.isBoldTrait() != nil {
                        newFont = newFont.addTrait(UIFontDescriptor.SymbolicTraits.traitBold)
                    }
                    if currentFont?.isItalicTrait() != nil {
                        newFont = newFont.addTrait(UIFontDescriptor.SymbolicTraits.traitItalic)
                    }
                    self.setFontStyle(newFont, range: range)
                })
            }
        }
        saveTextEntryAttributes()
        validateKeyboard()
    }
    
    func textInputDidChangeStyle(_ style: FTTextStyleItem) {
        let contentScale = self.zoomScale;
        let selectedRange: NSRange = textInputView.selectedRange
        let color = UIColor(hexString: style.textColor)
        setTextColor(color, in: selectedRange)
        
        if Int(selectedRange.length) == 0 {
            let typingAttributes = textInputView.typingAttributes
            let currentFont = typingAttributes[NSAttributedString.Key.font] as? UIFont
            if nil != currentFont {
                var fontDescriptor = UIFontDescriptor()
                fontDescriptor = fontDescriptor.withFamily(style.fontFamily)
                fontDescriptor = fontDescriptor.addingAttributes([UIFontDescriptor.AttributeName.name: style.fontName])
                let newFont = UIFont(descriptor: fontDescriptor, size: CGFloat(style.fontSize) * CGFloat(contentScale))
                
                if style.isUnderLined {
                    textInputView.setValue(NSUnderlineStyle.single.rawValue, forAttribute: NSAttributedString.Key.underlineStyle.rawValue, in: selectedRange)
                } else {
                    textInputView.setValue(nil, forAttribute: NSAttributedString.Key.underlineStyle.rawValue, in: selectedRange)
                }
                
                if style.strikeThrough {
                    textInputView.setValue(NSUnderlineStyle.single.rawValue, forAttribute: NSAttributedString.Key.strikethroughStyle.rawValue, in: selectedRange)
                    textInputView.setValue(color, forAttribute: NSAttributedString.Key.strikethroughColor.rawValue, in: selectedRange)
                } else {
                    textInputView?.setValue(nil, forAttribute: NSAttributedString.Key.strikethroughStyle.rawValue, in: selectedRange)
                    textInputView?.setValue(nil, forAttribute: NSAttributedString.Key.strikethroughColor.rawValue, in: selectedRange)
                }
                
                setFontStyle(newFont, range: selectedRange)
            }
        }
        else {
            let newAttributedString: NSMutableAttributedString = NSMutableAttributedString(attributedString: self.attributedString)
            newAttributedString.enumerateAttribute(NSAttributedString.Key.font, in: selectedRange, options: []) { (_, range, _) in
              
                var fontDescriptor = UIFontDescriptor()
                fontDescriptor = fontDescriptor.withFamily(style.fontFamily)
                fontDescriptor = fontDescriptor.addingAttributes([UIFontDescriptor.AttributeName.name: style.fontName])
                let newFont = UIFont(descriptor: fontDescriptor, size: CGFloat(style.fontSize) * CGFloat(contentScale))
                
                if style.isUnderLined {
                    textInputView.setValue(NSUnderlineStyle.single.rawValue, forAttribute: NSAttributedString.Key.underlineStyle.rawValue, in: selectedRange)
                } else {
                    textInputView?.setValue(nil, forAttribute: NSAttributedString.Key.underlineStyle.rawValue, in: selectedRange)
                }
                
                if style.strikeThrough {
                    textInputView.setValue(NSUnderlineStyle.single.rawValue, forAttribute: NSAttributedString.Key.strikethroughStyle.rawValue, in: selectedRange)
                    textInputView.setValue(color, forAttribute: NSAttributedString.Key.strikethroughColor.rawValue, in: selectedRange)
                } else {
                    textInputView?.setValue(nil, forAttribute: NSAttributedString.Key.strikethroughStyle.rawValue, in: selectedRange)
                    textInputView?.setValue(nil, forAttribute: NSAttributedString.Key.strikethroughColor.rawValue, in: selectedRange)
                }
                
                setFontStyle(newFont, range: range)
            }
        }
        saveTextEntryAttributes()
        validateKeyboard()
    }
    
    func textInputAccessoryDidChangeFontFamilyStyle(_ fontFamilyStyle: String) {
        let selectedRange: NSRange = textInputView.selectedRange
        // IF TO APPLY CHANGE TO ENTIRE CURSOR's LINE
        //        if selectedRange.length == 0 {
        //            selectedRange = textInputView.text.paragraphRange(for: selectedRange)
        //        }
        if selectedRange.length == 0 {
            let typingAttributes = textInputView.typingAttributes
            let currentFont = typingAttributes[NSAttributedString.Key.font] as? UIFont
            if nil != currentFont {
                let fontDescriptor = currentFont?.fontDescriptor.addingAttributes([UIFontDescriptor.AttributeName.name: fontFamilyStyle])
                var newFont: UIFont?
                if let aDescriptor = fontDescriptor {
                    newFont = UIFont(descriptor: aDescriptor, size: currentFont?.pointSize ?? 0.0)
                }
                if  let newFont1 = newFont {
                    setFontStyle(newFont1, range: selectedRange)
                }
            }
        }
        else {
            let newAttributedString = attributedString
            newAttributedString.enumerateAttribute(NSAttributedString.Key.font, in: selectedRange, options: [], using: { value, range, _ in
                let currentFont = value as? UIFont
                let fontDescriptor = currentFont?.fontDescriptor.addingAttributes([UIFontDescriptor.AttributeName.name: fontFamilyStyle])
                var newFont: UIFont?
                if let aDescriptor = fontDescriptor {
                    newFont = UIFont(descriptor: aDescriptor, size: (currentFont?.pointSize ?? 0.0) * self.zoomScale)
                }
                if newFont != nil {
                    self.setFontStyle(newFont!, range: range)
                }
            })
        }
        saveTextEntryAttributes()
        validateKeyboard()
    }
    
    func textInputAccessoryDidChangeColor(_ backgroundColor: UIColor) {
        setTextBackgroundColor(backgroundColor)
        saveTextEntryAttributes()
    }
    
    func textInputAccessoryDidChangeTextColor(_ textColor: UIColor) {
        setTextColor(textColor, in: textInputView.selectedRange)
        saveTextEntryAttributes()
    }
    
    func textInputAccessoryDidChangeFavoriteFont(_ fontInfo: FTTextStyleItem) {
        let contentScale = self.zoomScale;

        setTextColor(UIColor(hexString: fontInfo.textColor), in: textInputView.selectedRange)
        
        let selectedRange: NSRange = textInputView.selectedRange
        if Int(selectedRange.length) == 0 {
            let typingAttributes = textInputView.typingAttributes
            let currentFont = typingAttributes[NSAttributedString.Key.font] as? UIFont
            if nil != currentFont {
                var fontDescriptor = UIFontDescriptor()
                fontDescriptor = fontDescriptor.withFamily(fontInfo.fontName)
                fontDescriptor = fontDescriptor.addingAttributes([UIFontDescriptor.AttributeName.name : fontInfo.fontName])
                let newFont = UIFont(descriptor: fontDescriptor, size: CGFloat(fontInfo.fontSize) * CGFloat(contentScale))
//                if fontInfo.isBold {
//                    newFont = newFont.addTrait(UIFontDescriptor.SymbolicTraits.traitBold)
//                }
//                if fontInfo.isItalic {
//                    newFont = newFont.addTrait(UIFontDescriptor.SymbolicTraits.traitItalic)
//                }
                if fontInfo.isUnderLined {
                    textInputView.setValue(NSUnderlineStyle.single.rawValue, forAttribute: NSAttributedString.Key.underlineStyle.rawValue, in: selectedRange)
                } else {
                    textInputView.setValue(nil, forAttribute: NSAttributedString.Key.underlineStyle.rawValue, in: selectedRange)
                }
                setFontStyle(newFont, range: selectedRange)
            }
        }
        else {
            let newAttributedString: NSMutableAttributedString = NSMutableAttributedString(attributedString: self.attributedString)
            newAttributedString.enumerateAttribute(NSAttributedString.Key.font, in: selectedRange, options: []) { (_, range, _) in
                var fontDescriptor = UIFontDescriptor()
                fontDescriptor = fontDescriptor.withFamily(fontInfo.fontName)
                fontDescriptor = fontDescriptor.addingAttributes([UIFontDescriptor.AttributeName.name: fontInfo.fontName])
                var newFont = UIFont(descriptor: fontDescriptor, size: CGFloat(fontInfo.fontSize) * CGFloat(contentScale))
//                if fontInfo.isBold {
//                    newFont = newFont.addTrait(UIFontDescriptor.SymbolicTraits.traitBold)
//                }
//                if fontInfo.isItalic {
//                    newFont = newFont.addTrait(UIFontDescriptor.SymbolicTraits.traitItalic)
//                }
                if fontInfo.isUnderLined {
                    textInputView.setValue(NSUnderlineStyle.single.rawValue, forAttribute: NSAttributedString.Key.underlineStyle.rawValue, in: selectedRange)
                } else {
                    textInputView?.setValue(nil, forAttribute: NSAttributedString.Key.underlineStyle.rawValue, in: selectedRange)
                }
                setFontStyle(newFont, range: range)
            }
        }
        saveTextEntryAttributes()
        validateKeyboard()
    }
}

extension FTTextAnnotationViewController : FTTouchEventProtocol
{
    //MARK: - Touch Handling
    func processTouchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count > 1 {
            return
        }
        guard let touch = touches.first else {
            return;
        }
        self.touchDownTime = touch.timestamp;
        isScaling = false
        isMoving = false
        //******************************
        // Make sure the text is in the current orientation
        // else prompt to rotate
        //******************************
        self.textInputView.isMoving = false
        
        // If touch in scaling hotspot - start scaling - else, start moving
        let hitView: UIView? = hitTest(touch.location(in: self.view), with: event)
        if nil != hitView {
            let tag: Int? = hitView?.tag
            if tag == FTKnobPosition.FTKnobPositionLeft.rawValue || tag == FTKnobPosition.FTKnobPositionRight.rawValue {
                isScaling = true
                isMoving = false
                
                let currentPointWrtView = touch.location(in: self.view.superview);
                let center = self.view.center;
                if(center.x > currentPointWrtView.x && center.y > currentPointWrtView.y) {
                    resizeDirection = .topLeft;
                }
                else if(center.x > currentPointWrtView.x && center.y < currentPointWrtView.y) {
                    resizeDirection = .bottomLeft;
                }
                if(center.x < currentPointWrtView.x && center.y > currentPointWrtView.y) {
                    resizeDirection = .topRight;
                }
                if(center.x < currentPointWrtView.x && center.y < currentPointWrtView.y) {
                    resizeDirection = .bottomRight;
                }
            } else {
                isScaling = false
                if !self.editMode || hitView != self.textInputView {
                    isMoving = true
                }
            }
        }
    }
    
    func processTouchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count > 1 { return }
        guard let touch = touches.first else {
            return;
        }
        if nil == self.view.superview {
            return
        }
        let curFrame = self.textFrame;
        if isMoving {
            let transform = self.view.transform
            self.view.transform = .identity
            let prevLocation = touch.previousLocation(in: self.view);
            let currentLocation = touch.location(in: self.view);
            self.view.transform = transform

            let xOffset: CGFloat = prevLocation.x - currentLocation.x
            let yOffset: CGFloat = prevLocation.y - currentLocation.y
            
            var newOrigin = CGPoint.zero
            newOrigin = CGPoint(x: curFrame.origin.x - xOffset, y: curFrame.origin.y - yOffset)
            
            var frameToSet = CGRect(x: newOrigin.x, y: newOrigin.y, width: curFrame.size.width, height: curFrame.size.height)
            frameToSet.origin = adjustFrameOrigin(withinBoundary: frameToSet)
            if(frameToSet != curFrame) {
                textInputView.isMoving = true
                self.resizeMode = .fixed;
            }
            self.textFrame = frameToSet
            
        }
        else if isScaling {
            let prevPoint: CGPoint = touch.previousLocation(in: self.view)
            let currentPoint: CGPoint = touch.location(in: self.view)

            let xOffset: CGFloat = prevPoint.x - currentPoint.x
            let yOffset: CGFloat = prevPoint.y - currentPoint.y
            
            var newSize = CGSize.zero
            var newOrigin: CGPoint = curFrame.origin

            newSize = CGSize(width: curFrame.size.width - xOffset, height: curFrame.size.height - yOffset)
            if(resizeDirection == .topLeft) {
                newOrigin.x += xOffset;
                newOrigin.y += yOffset;
            }
            else if(resizeDirection == .topRight) {
                newOrigin.y += yOffset;
            }
            else if(resizeDirection == .bottomLeft) {
                newOrigin.x += xOffset;
            }

            let minSize: CGSize = minSizeToFit()
            newSize.height = max(minSize.height, newSize.height)
            
            var frameToSet = CGRect(x: newOrigin.x,
                                    y: newOrigin.y,
                                    width: max(newSize.width, minSize.width),
                                    height: newSize.height)
            frameToSet.origin = adjustFrameOrigin(withinBoundary: frameToSet)
            if(frameToSet != curFrame) {
                self.resizeMode = .fixed;
            }
            self.textFrame = frameToSet
        }
        else {
            if let loupeGesture = textInputView.loupeGestureRecognizer(),
                loupeGesture.state == .failed {
                isMoving = true;
            }
            else if nil == textInputView.loupeGestureRecognizer() {
                isMoving = true;
            }
        }
        
        if (isMoving || isScaling),!self.editMode {
            UIMenuController.shared.hideMenu()
        }

    }
    
    func processTouchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count > 1 { return }
        if nil == self.view.superview {
            return
        }
        
        if isScaling {
            self.resizeTextViewAsNeeded()
        }
        
        let time = touches.first?.timestamp ?? 0;
        if(time - self.touchDownTime < 0.1) {
            self.processEvent(.singleTap, at: touches.first?.location(in: self.textInputView) ?? CGPoint.zero);
//            self.editMode = true
        }
        self.textInputView.isMoving = false
        isMoving = false
        isScaling = false
        
        if !self.editMode {
            saveTextEntryAttributes()
            self.setupMenuForTextViewLongPress();
        }
        self.scheduleScrolling(delay: 0.4);
    }
    
    func processTouchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count > 1 { return }
        
        if nil == self.view.superview {
            return
        }
        
        if isScaling {
            resizeTextViewAsNeeded()
        }
        
        self.textInputView.isMoving = false
        isMoving = false
        isScaling = false
        
        self.delegate?.annotationControllerDidCancel(self)
    }
}

extension FTTextAnnotationViewController : FTAnnotationEditControllerInterface
{
    func endEditingAnnotation(){
        #if targetEnvironment(macCatalyst)
            if let controller = self.delegate?.getInputAccessoryViewController() {
                UIView.animate(withDuration: 0.3, animations: {
                    controller.view.alpha = 0.0
                }) { (_) in
                    controller.view.removeFromSuperview()
                    controller.removeFromParent()
                }
            }
        self.editMode = false;
        self.resizeTextViewAsNeeded();
        self.saveTextEntryAttributes();
        self.annotation.forceRender = true;
        //self.textInputView.inputAccessoryViewController = nil;
        #else
        self.editMode = false;
        self.annotation.forceRender = true;
        //self.textInputView.inputAccessoryViewController = nil;
        #endif
        self.delegate?.annotationControllerDidEnded(self)
    }
    
    func isPointInside(_ point : CGPoint,fromView : UIView) -> Bool
    {
        return self.view.frame.contains(point);
    }
    
    func refreshView()
    {
        let currentFrame = self.textFrame;
        let currentScale = self.delegate?.contentScale() ?? 1;
        let newFrameToSet = CGRect.scale(self.annotation.boundingRect, currentScale);
        
        let currentString = self.attributedString;
        guard let stringToSet = (self.annotation as? FTTextAnnotation)?.attributedString else { return }

        if(!stringToSet.isEqual(toAttributedText: currentString)
            || newFrameToSet.integral != currentFrame.integral
            ) {
            self.textFrame = newFrameToSet;
            self.attributedString = stringToSet;
            self.view.layoutIfNeeded();
        }
    }
    
    func saveChanges()
    {
        self.saveTextEntryAttributes()
    }
    
    func processEvent(_ eventType : FTProcessEventType,at point:CGPoint)
    {
        if(eventType == .singleTap
            || eventType == .none) {
            self.editMode = true;
            if(point != CGPoint.zero) {
                let convertedPoint = self.view.convert(point, to: textInputView)
                self.textInputView.selectTextRange(at: convertedPoint)
                // To fix the issue during unlock of textView
                self.textInputView.placeCurserAtEnd()
            }
        } else if eventType == .longPress {
            if(point != CGPoint.zero) {
                let convertedPoint = self.view.convert(point, to: textInputView)
                self.textInputView.selectTextRange(at: convertedPoint)
                setupMenuForTextViewLongPress()
            }
        }
    }
    
    func updateViewToCurrentScale(fromScale : CGFloat) {
        if let del = self.delegate, del.contentScale() != fromScale {

            var currentFrame = self.textFrame;
            currentFrame = CGRectScale(currentFrame, 1/fromScale);
            
            let attrString = self.attributedString;
            
            let newScale = del.contentScale();
            self.textInputView.scale = newScale;
            
            let newFrame = CGRectScale(currentFrame, newScale);
            self.attributedString = attrString;
            self.textFrame = newFrame;
        }
    }
    
    func annotationControllerLongPressDetected() {
        
    }
}

@objc extension NSAttributedString {
    func requiredAttributedStringSize(maxWidth: CGFloat,
                                      containerInset: UIEdgeInsets) -> CGSize
    {
        let edgeInsetWidth = containerInset.left + containerInset.right;
        
        let constrainedSize = CGSize(width: maxWidth - edgeInsetWidth,
                                     height: CGFloat.greatestFiniteMagnitude);
        
        var sizeToReturn = self.requiredSizeForAttributedStringConStraint(to: constrainedSize);
        sizeToReturn.width += edgeInsetWidth;
        sizeToReturn.height += containerInset.top + containerInset.bottom;
        return sizeToReturn.integral;
    }
    
    private func sizeToFitInSingleLine() -> CGSize {
        let contraintSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude);
        let size = self.requiredSizeForAttributedStringConStraint(to: contraintSize);
        return size.integral;
    }
    
    //font: 1x Font, scale: to apply, containerInset: scaled inset
    class func minSizeToFit(_ font: UIFont?,
                            scale : CGFloat,
                            containerInset: UIEdgeInsets) -> CGSize {
        let attributedString = NSAttributedString(string: "W",
                                                  attributes: [.font : font as Any])
        
        var minSize: CGSize = CGSizeScale(attributedString.sizeToFitInSingleLine(), scale)
        minSize.height += (containerInset.top + containerInset.bottom)
        minSize.width += (containerInset.left + containerInset.right)
        minSize.width = max(minSize.width,100);
        
        return minSize.integral;
    }
}

extension CGSize {
    var integral: CGSize {
        var sizeRect = CGRect.zero;
        sizeRect.size = self;
        return sizeRect.integral.size;
    }
}

private extension UITextView {
    func selectTextRange(at point:CGPoint) {
        let textCount = self.textStorage.length;
        let glyphIndex = self.layoutManager.glyphIndex(for: point,
                                                                in: self.textContainer);
        let charIndex = self.layoutManager.characterIndexForGlyph(at: glyphIndex);
        if charIndex < textCount {
            var rangeToReturn = NSRange(location: charIndex, length: 0)
            if let tapPosition = self.closestPosition(to: point),
                let textRange = self.tokenizer.rangeEnclosingPosition(tapPosition,
                                                                      with:.word,
                                                                      inDirection: UITextDirection(rawValue: 1))
            {
                rangeToReturn = self.rangeFrom(textRange: textRange);
                rangeToReturn.location = NSMaxRange(rangeToReturn);
                rangeToReturn.length = 0;
            }
            self.selectedRange = rangeToReturn;
        }
    }
    
    
    func placeCurserAtEnd() {
        let newPosition = self.endOfDocument
        self.selectedTextRange = self.textRange(from: newPosition, to: newPosition)
    }
    
    func rangeFrom(textRange: UITextRange) -> NSRange {
        let startLocation = self.offset(from: self.beginningOfDocument, to: textRange.start);
        let endLocation = self.offset(from: self.beginningOfDocument, to: textRange.end);
        let length = endLocation - startLocation;
        
        return NSRange(location: startLocation, length: length);
    }
}

private class FTReferenceLibraryViewController: UIReferenceLibraryViewController {
    var onCompletion: (() -> ())?
    
    deinit {
        self.onDismiss()
    }
    
    private func onDismiss() {
        onCompletion?();
        onCompletion = nil;
    }
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion);
        self.onDismiss()
    }
}

#if targetEnvironment(macCatalyst)
extension FTTextAnnotationViewController {    
    func canPerformAction(_ selector: Selector) -> Bool {
        if [#selector(self.copy(_:)),
            #selector(self.cut(_:)),
            #selector(self.delete(_:))
        ].contains(selector) {
            return true;
        }
        return false;
    }
    
    func performAction(_ selector: Selector) {
        if #selector(self.copy(_:)) == selector {
            self.textMenuAction(action: .copy, sender: nil)
        }
        else if #selector(self.cut(_:)) == selector {
            self.textMenuAction(action: .cut, sender: nil)
        }
        else if #selector(self.delete(_:)) == selector {
            self.textMenuAction(action: .delete, sender: nil)
        }
    }
}
#endif
