//
//  FTTextToolBarViewController.swift
//  Noteshelf
//
//  Created by Mahesh on 27/10/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

let minSpacing: CGFloat = 8
let defaultButtonWidth: Int = 44
let textToolbarHeight: CGFloat = 48.0

enum FTTextToolBarOption {
    case title
    case subtitle
    case body
    case heading
    case caption
    case rightIndent
    case leftIndent
    case bullets
    case numbersList
    case checkBox
}

@objc protocol FTTextToolbarControllerDelegate: NSObjectProtocol {
    @objc optional func didAddTextToolBar(_ controller: FTTextToolBarViewController)
    @objc optional func didRemoveTextToolBar()
}

protocol FTTextSelectionChangeDelegate: NSObjectProtocol {
    func didChangeTextSelectionAttributes(_ attributes: [NSAttributedString.Key : Any]?, scale: CGFloat)
}

protocol FTStyleSelectionDelegate: NSObjectProtocol {
    func didHighLightSelectedStyle(attr: [NSAttributedString.Key : Any]?, scale: CGFloat)
}

protocol FTTextToolBarDelegate: FTRootControllerInfo {
    func didSelectTextToolbarOption(_ option: FTTextToolBarOption)
    func didSelectFontStyle(_ style: FTTextStyleItem)
    func didChangeBackgroundColor(_ color: UIColor)
    func currentTextInputView() -> FTTextView
    func addTextInputView(_ inputController: UIViewController?)
    func didChangeTextAlignmentStyle(style: NSTextAlignment)
    func didChangeLineSpacing(lineSpace: CGFloat)
    func didAutoLineSpaceStatusChanged(_ status: Bool)
    func didSelectTextRange(range: NSRange?, txtRange: UITextRange?, canEdit: Bool)
    func didChangeFontTrait(_ trait: UIFontDescriptor.SymbolicTraits)
    func didToggleUnderline()
    func didToggleStrikeThrough()
    func didSetDefaultStyle(_ info: FTDefaultTextStyleItem)
    func textInputViewCurrentTextView() -> FTTextView?
}

class FTTextToolBarViewController: UIViewController {
    @IBOutlet private weak var rootToolsView: UIView?
    @IBOutlet private weak var textStyleView: UIStackView?
    @IBOutlet private weak var textIndentStackView: UIStackView?
    @IBOutlet private weak var textBulletsStackView: UIStackView?
    @IBOutlet private weak var textBackGroundColorBtn: UIButton?
    @IBOutlet private weak var btnBullets: UIButton?
    @IBOutlet private weak var btnNumberBullets: UIButton?
    @IBOutlet private weak var btnCheckBox: UIButton?
    @IBOutlet private weak var compactView: UIStackView?
    @IBOutlet private weak var textStyleEditView: UIView?
    @IBOutlet private weak var textStyleEditUnderlineView: UIButton?

    var btnInputItemBold: UIBarButtonItem?
    var btnInputItemItalic: UIBarButtonItem?
    var btnInputItemUnderLine: UIBarButtonItem?
    var btnInputItemStrikeThrough: UIBarButtonItem?
    
    weak var toolBarDelegate: FTTextToolBarDelegate?
    weak var textSelectionDelegate: FTTextSelectionChangeDelegate?
    weak var textHighLightSyleDelegate: FTStyleSelectionDelegate?
    private var currentSize = CGSize.zero
    private var attributes: [NSAttributedString.Key : Any]?
    private var scale: CGFloat = 1.0
    
    weak var documentRenderVC: FTDocumentRenderViewController?
    
    private var isRegular: Bool {
        return documentRenderVC?.isRegularClass() ?? false
    }
    
    var parentVC: UIViewController? {
        return self.documentRenderVC
    }
    
    var accessoryViewItems: [FTTextInputAcessoryViewProtocol] {
        var items = FTTextInputAccessoryViewManager.shared.getShortCompactModeTextInputAcessoryItems()
        if self.view.frame.width > 420 {
            items = FTTextInputAccessoryViewManager.shared.getLongCompactModeTextInputAcessoryItems()
        }
        return items
    }
    
    private var previousTraitCollection: UITraitCollection?;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        switchMode()
        let gesture = UITapGestureRecognizer(target: self, action: #selector(tapOnTextEditStyle))
        self.textStyleEditView?.addGestureRecognizer(gesture)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let color = self.attributes?[NSAttributedString.Key.foregroundColor] as? UIColor {
            self.updateUnderlineTint(color)
        }
    }

    func updateUnderlineTint(_ color: UIColor) {
        self.textStyleEditUnderlineView?.tintColor = color
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let currentFrameSize = self.view.frame.size
        if(currentFrameSize != self.currentSize) {
            self.currentSize = currentFrameSize
        }
    }

    @objc func tapOnTextEditStyle() {
        guard let presentingVC = parentVC, let editView = self.textStyleEditView else { return }
        FTNewTextStyleViewController.showAsPopover(fromSourceView: editView, overViewController: presentingVC, delegate: self, attributes: self.attributes, scale: self.scale)
    }

    func switchMode() {
        rootToolsView?.isHidden = isRegular ? false : true
        compactView?.isHidden = isRegular ? true : false
        loadTextStyles()
        configKeyboardInputAssistantItem()
    }
}

//MARK:- Private methods

extension FTTextToolBarViewController {
    private func loadTextStyles() {
        updateElementsInTextInputAccessoryView()
         let textStyles = fetchStyles()
        var showCount = textStyles.styles.count
        if showCount >= 5 {
            showCount = 5
        }
        if showCount < 2 {
            showCount = 2
        }
        let styles = textStyles.styles.prefix(Int(showCount))
        if styles.count > 0 {
            textStyleView?.arrangedSubviews.forEach { $0.removeFromSuperview() }
            for (idx, item) in styles.enumerated() {
                let button = FTTextToolbarButton(type: .custom)
                button.tag = idx
                var attributeText = NSMutableAttributedString(string: item.textStyleShortName())
                attributeText = attributeText.getFormattedAttributedStringFrom(style: item, defaultFont: 16, toPreviewDefault: true)
                button.isPointerInteractionEnabled = true
                button.addTarget(self, action:#selector(didSelectedStyle(_:)), for: .touchUpInside)

                var config = UIButton.Configuration.plain()
                config.attributedTitle = AttributedString(attributeText)
                config.cornerStyle = .medium
                config.titleAlignment = .leading
                config.contentInsets.leading = .zero
                config.contentInsets.trailing = .zero
                let bgConfig = UIBackgroundConfiguration.listPlainCell()
                config.background = bgConfig
                button.configuration = config

                textStyleView?.addArrangedSubview(button)
                NSLayoutConstraint.activate([
                    button.widthAnchor.constraint(equalToConstant: 45)
                ])
            }
        }
    }
    
    private func resetBackgroundColorForTextStyles() {
        textStyleView?.arrangedSubviews.forEach({ vw in
            if let btn = vw as? UIButton {
                btn.isSelected = false
            }
        })
    }
    
    private func resetBackgroundColorForCompactView() {
        compactView?.arrangedSubviews.forEach({ vw in
            if let btn = vw as? UIButton {
                btn.backgroundColor = .clear
                btn.layer.cornerRadius = .zero
            }
        })
    }
    
    private func updateElementsInTextInputAccessoryView() {
        let items = self.accessoryViewItems
        compactView?.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (idx, item) in items.enumerated() {
            let button = UIButton(type: .custom)
            if item.type == .bullets {
                button.showsMenuAsPrimaryAction = true
                button.menu = menuForBulletsInCompactMode()
            }
            button.tag = idx
            button.tintColor = UIColor.appColor(.black1)
            button.setImage(item.itemImage, for: .normal)
            button.addTarget(self, action:#selector(didSelectAccessoryView(_:)), for: .touchUpInside)
            compactView?.addArrangedSubview(button)
        }
    }
    
    private func validateTextbackgroundColor() {
        if let textView = self.toolBarDelegate?.currentTextInputView() {
            let selectedRange = textView.selectedRange;
            var attributes = textView.typingAttributes;
            
            if(selectedRange.length > 0) {
                attributes = textView.textStorage.attributes(at: selectedRange.location, effectiveRange: nil);
            }
            self.scale = textView.scale
            self.updateToolBarSelectionForattributes(attributes, scale: scale)
        }
    }
    
    private func updateToolBarSelectionForattributes(_ attributes: [NSAttributedString.Key : Any]?, scale: CGFloat) {
        self.attributes = attributes
        self.scale = scale
        if let attr = attributes {
            let textStyles = fetchStyles() 
            //Highlight select font style in preset View controller
            self.textHighLightSyleDelegate?.didHighLightSelectedStyle(attr: attr, scale: scale)
            
            //Update selection for textStyle on toolbar, if style match with text attributes
            let textStyle = FTTextStyleItem().textStyleFromAttributes(attr, scale: scale)
            let visibleStylesCount = self.textStyleView?.arrangedSubviews.count ?? 0
            if visibleStylesCount > 0 {
                resetBackgroundColorForTextStyles()
                let styles = textStyles.styles.prefix(Int(visibleStylesCount))
                let index = styles.firstIndex(where: {$0.isEqual(textStyle)})
                if index != NSNotFound {
                    let btn = textStyleView?.arrangedSubviews.filter({$0.tag == index}).first
                    if let styleButton = btn as? UIButton {
                        styleButton.isSelected = true
                    }
                }
            }
            
            // Update Text background color on Toolbar
            let color = attributes?[.backgroundColor] as? UIColor;
            self.updateBackgroundColorPickerButton(color);
            
            //Update Text bullets styles on Toolbar
            let paragraphStyle = attributes?[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle;
            let bulletList = paragraphStyle?.bulletType(withScale: scale);
            updateBackGroundsForBulletsStylesView(bulletList)
            
            var font = attr[NSAttributedString.Key.font] as! UIFont;
            let originalFont = attr[NSAttributedString.Key(rawValue: "NSOriginalFont")] as? UIFont;
            let isUnderLined = attr[NSAttributedString.Key.underlineStyle] as? Int
            let isStrikeThrough = attr[NSAttributedString.Key.strikethroughStyle] as? Int
            if(nil != originalFont) {
                font = originalFont!;
            }
            let isUnderLineText = (isUnderLined != nil && isUnderLined == 1) ? true : false
            let isStrikeThroughText = (isStrikeThrough != nil && isStrikeThrough == 1) ? true : false
            let isBold = font.isBoldTrait()
            let isItalic = font.isItalicTrait()
            updateKeyboardInputAssistantItemsSelectionState(canBold: isBold, canItalic: isItalic, canUnderLine: isUnderLineText, canStrike: isStrikeThroughText)
        }
        if let color = self.attributes?[NSAttributedString.Key.foregroundColor] as? UIColor {
            self.updateUnderlineTint(color)
        }
    }
    
    private func updateBackGroundsForBulletsStylesView(_ type: FTBulletType?) {
        
        func resetBackgroundForBulletsStackView() {
            textBulletsStackView?.arrangedSubviews.forEach({ vw in
                if let btn = vw as? UIButton {
                    btn.isSelected = false
                }
            })
        }
        if type == nil {
            return
        }
        resetBackgroundForBulletsStackView()
        switch type! {
        case .one:
            btnBullets?.isSelected = true
        case .numbers:
            btnNumberBullets?.isSelected = true
        case .checkBox:
            btnCheckBox?.isSelected = true
        default:
            break
        }
    }
    
    private func updateBackgroundColorPickerButton(_ color: UIColor?) {
        var colorToSet = UIColor.clear;
        let clearColor = UIColor.clear.hexStringFromColor();
        if let bgColor = color {
            let colorStr = bgColor.hexStringFromColor()
            if colorStr != clearColor {
                colorToSet = bgColor;
            }
        }
        textBackGroundColorBtn?.applyTintColorTo(withColor: colorToSet)
    }
    
    private func fetchStyles() -> FTTextStyle {
        let textStyles = FTTextStyleManager.shared.fetchTextStylesFromPlist()
        return textStyles
    }
    
    private func menuForBulletsInCompactMode() -> UIMenu {
        let bullets = UIAction(title: NSLocalizedString("Bullet List", comment: "Bullet List"), image: UIImage(systemName: "list.bullet"), handler: { [weak self] _ in
            guard let self = self else { return }
            self.toolBarDelegate?.didSelectTextToolbarOption(.bullets)
        })
        
        let number = UIAction(title: NSLocalizedString("Numbered List", comment: "Numbered List"), image: UIImage(systemName: "list.number"), handler: { [weak self] _ in
            guard let self = self else { return }
            self.toolBarDelegate?.didSelectTextToolbarOption(.numbersList)
        })
        
        let checkList =  UIAction(title: NSLocalizedString("Checklist", comment: "Checklist"), image: UIImage(systemName: "checklist"), handler: { [weak self] _ in
            guard let self = self else { return }
            self.toolBarDelegate?.didSelectTextToolbarOption(.checkBox)
        })
        
        let items = self.accessoryViewItems.count > 5 ? [bullets, number] : [bullets, number, checkList]
        let menu = UIMenu(title: "", options: .displayInline, children: items)
        return menu
    }
    
    private func textStyleCompactView() {
        if let textView = self.toolBarDelegate?.currentTextInputView() {
            textView.autocorrectionType = .no
            if textView.inputView == nil {
                let textStyleCompactVC = FTTextStyleCompactViewController.viewControllerForCompact(self, attributes: self.attributes, scale: self.scale)
                let safeInsets = textView.window?.safeAreaInsets ?? UIEdgeInsets.zero;
                var frame = textStyleCompactVC.view.frame
                frame.size.height = 280;
                frame.size.height += safeInsets.bottom;
                textStyleCompactVC.view.frame = frame;
                self.toolBarDelegate?.addTextInputView(textStyleCompactVC)
            }
        }
    }
    
    private func configKeyboardInputAssistantItem() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            if let textView = self.toolBarDelegate?.currentTextInputView() {
                let bold = FTTextInputAccessoryButton(type: .system)
                bold.isPointerInteractionEnabled = true
                bold.addTarget(self, action: #selector(self.tappedOnFontTraitStyle(_:)), for: .touchUpInside)
                bold.tag = 0
                bold.configuration = UIButton.Configuration.plainConfiguration(with:  UIImage(systemName: "bold"))
                btnInputItemBold = UIBarButtonItem(button: bold)

                let italic = FTTextInputAccessoryButton(type: .system)
                italic.isPointerInteractionEnabled = true
                italic.addTarget(self, action: #selector(self.tappedOnFontTraitStyle(_:)), for: .touchUpInside)
                italic.tag = 1
                italic.configuration = UIButton.Configuration.plainConfiguration(with:  UIImage(systemName: "italic"))
                btnInputItemItalic = UIBarButtonItem(button: italic)

                let underline = FTTextInputAccessoryButton(type: .system)
                underline.isPointerInteractionEnabled = true
                underline.configuration = UIButton.Configuration.plainConfiguration(with:  UIImage(systemName: "underline"))
                underline.addTarget(self, action: #selector(self.tappedOnFontTraitStyle(_:)), for: .touchUpInside)
                underline.tag = 2
                btnInputItemUnderLine = UIBarButtonItem(button: underline)
                btnInputItemUnderLine?.tag = 2

                let strikethrough = FTTextInputAccessoryButton(type: .system)
                strikethrough.isPointerInteractionEnabled = true
                strikethrough.configuration = UIButton.Configuration.plainConfiguration(with:  UIImage(systemName: "strikethrough"))
                strikethrough.addTarget(self, action: #selector(self.tappedOnFontTraitStyle(_:)), for: .touchUpInside)
                strikethrough.tag = 3

                btnInputItemStrikeThrough = UIBarButtonItem(button: strikethrough)

                let trailingBtns = UIBarButtonItemGroup(barButtonItems: [btnInputItemBold!, btnInputItemItalic!, btnInputItemUnderLine!,btnInputItemStrikeThrough!], representativeItem: nil)
                textView.inputAssistantItem.trailingBarButtonGroups = [trailingBtns]
            }
        }
    }
    
    private func updateKeyboardInputAssistantItemsSelectionState(canBold: Bool = false, canItalic: Bool = false, canUnderLine: Bool = false, canStrike: Bool = false) {
        btnInputItemBold?.isSelected = canBold
        btnInputItemItalic?.isSelected = canItalic
        btnInputItemUnderLine?.isSelected = canUnderLine
        btnInputItemStrikeThrough?.isSelected = canStrike
    }
}


//MARK:- Action Handlers
extension FTTextToolBarViewController {
    
    @objc func didSelectedStyle(_ sender: UIButton) {
         let textStyles = fetchStyles()
        resetBackgroundColorForTextStyles()
        sender.isSelected = true
        let style = textStyles.styles[sender.tag]
        self.toolBarDelegate?.didSelectFontStyle(style)
    }
    
    @objc func didSelectAccessoryView(_ sender: UIButton) {
        resetBackgroundColorForCompactView()
        
        let items = self.accessoryViewItems
        let item = items[sender.tag]
        switch item.type {
        case .textFormat:
            textStyleCompactView()
        case .bullets:
            //Menu action performed for respective button
            break
        case .checkbox:
            self.toolBarDelegate?.didSelectTextToolbarOption(.checkBox)
        case .numbers:
            self.toolBarDelegate?.didSelectTextToolbarOption(.numbersList)
        case .rightIndent:
            self.toolBarDelegate?.didSelectTextToolbarOption(.rightIndent)
        case .leftIndent:
            self.toolBarDelegate?.didSelectTextToolbarOption(.leftIndent)
        case .keyboardDown:
            self.toolBarDelegate?.addTextInputView(nil)
        default:
            break
        }
    }
   
    @IBAction func tappedOnTextPresetButton(_ sender: UIButton) {
        guard let presentingVC = parentVC else { return }
        FTTextPresetsViewController.showAsPopover(fromSourceView: sender, overViewController: presentingVC, delegate: self, attributes: self.attributes, scale: self.scale)
    }
    
    @IBAction func tappedOnTextHighLightColorButton(_ sender: UIButton) {
        guard let presentingVC = parentVC else { return }
        FTTextBackGroundColorViewController.showAsPopover(fromSourceView: sender, overViewController: presentingVC, delegate: self)
    }
    
    @IBAction func tappedOnRightIndentButton(_ sender: UIButton) {
        self.toolBarDelegate?.didSelectTextToolbarOption(.rightIndent)
    }
    
    @IBAction func tappedOnLeftIndentButton(_ sender: UIButton) {
        self.toolBarDelegate?.didSelectTextToolbarOption(.leftIndent)
    }
    
    @IBAction func tappedOnBulletsButton(_ sender: UIButton) {
        self.toolBarDelegate?.didSelectTextToolbarOption(.bullets)
    }
    
    @IBAction func tappedOnNumberedBulletsButton(_ sender: UIButton) {
        self.toolBarDelegate?.didSelectTextToolbarOption(.numbersList)
    }
    
    @IBAction func tappedOnCheckMarkButton(_ sender: UIButton) {
        self.toolBarDelegate?.didSelectTextToolbarOption(.checkBox)
    }
    
    @objc func tappedOnFontTraitStyle(_ sender: UIButton) {
        sender.isSelected.toggle()
        switch sender.tag {
        case 0:
            self.toolBarDelegate?.didChangeFontTrait(.traitBold)
        case 1:
            self.toolBarDelegate?.didChangeFontTrait(.traitItalic)
        case 2:
            self.toolBarDelegate?.didToggleUnderline()
        case 3:
            self.toolBarDelegate?.didToggleStrikeThrough()
        default:
            break
        }
    }
}

extension FTTextToolBarViewController: FTTextPresetSelectedDelegate {
    func didSelectedPresetStyleId(_ style: FTTextStyleItem) {
        self.toolBarDelegate?.didSelectFontStyle(style)
    }
    
    func reloadStylesStackView() {
        loadTextStyles()
        resetBackgroundColorForTextStyles()
    }

    func dismissKeyboard() {
        self.parentVC?.view.endEditing(true)
    }
}

extension FTTextToolBarViewController: FTTextBackGroundColorDelegate {
    func didSelectColor(_ color: UIColor) {
        if(color == UIColor.clear) {
            UserDefaults.standard.removeObject(forKey: "text_background_color")
        } else {
            let colorString = color.hexStringFromColor()
            UserDefaults.standard.set(colorString, forKey: "text_background_color")
        }
        self.toolBarDelegate?.didChangeBackgroundColor(color)
        self.updateBackgroundColorPickerButton(color)
    }
}

extension FTTextToolBarViewController: FTDefaultTextStyleDelegate {
    func didSetDefaultStyle(_ info: FTDefaultTextStyleItem) {
        self.toolBarDelegate?.didSetDefaultStyle(info)
    }
}

extension FTTextToolBarViewController: FTEditStyleDelegate {
    func didChangeStyle(_ style: FTTextStyleItem?) {
        guard let _style = style else { return }
        self.toolBarDelegate?.didSelectFontStyle(_style)
        self.updateUnderlineTint(UIColor(hexString: _style.textColor))
    }
    
    func didTapOnAlignmentStyle(_ style: NSTextAlignment) {
        self.toolBarDelegate?.didChangeTextAlignmentStyle(style: style)
    }
    
    func didChangeLineSpacing(lineSpace: CGFloat) {
        self.toolBarDelegate?.didChangeLineSpacing(lineSpace: lineSpace)
    }

    func didAutoLineSpaceStatusChanged(_ status: Bool) {
        self.toolBarDelegate?.didAutoLineSpaceStatusChanged(status)
    }

    func didSelectTextRange(range: NSRange?, txtRange: UITextRange?, canEdit: Bool) {
        self.toolBarDelegate?.didSelectTextRange(range: range, txtRange: txtRange, canEdit: canEdit)
    }

    func textInputViewCurrentTextView() -> FTTextView? {
        return self.toolBarDelegate?.currentTextInputView()
    }

    func rootViewController() -> UIViewController? {
        return self.toolBarDelegate?.rootViewController()
    }
}

extension FTTextToolBarViewController: FTTextAnnotationDelegate {
    
    func didChangeSelectionAttributes(_ attributes: [NSAttributedString.Key : Any]?, scale: CGFloat) {
        self.textSelectionDelegate?.didChangeTextSelectionAttributes(attributes, scale: scale)
        self.updateToolBarSelectionForattributes(attributes, scale: scale)
    }
}

extension FTTextToolBarViewController: FTTextStyleCompactDelegate {
    
    func didSelectFontStyle(_ style: FTTextStyleItem) {
        self.toolBarDelegate?.didSelectFontStyle(style)
    }
    
    func didChangeAlignmentStyle(_ style: NSTextAlignment) {
        self.toolBarDelegate?.didChangeTextAlignmentStyle(style: style)
    }
    
    func changeLineSpacing(_ lineSpace: CGFloat) {
        self.toolBarDelegate?.didChangeLineSpacing(lineSpace: lineSpace)
    }
    
    func changeBackgroundColor(_ color: UIColor) {
        self.toolBarDelegate?.didChangeBackgroundColor(color)
    }
}

extension FTTextToolBarViewController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        guard let traitCollection = self.view.window?.traitCollection else {
            return;
        }
        guard self.previousTraitCollection != traitCollection else {
            return;
        }
        self.previousTraitCollection = traitCollection;
        switchMode()
        self.updateToolBarSelectionForattributes(self.attributes, scale: self.scale)
        if let textView = self.toolBarDelegate?.currentTextInputView() {
            textView.inputView = nil
            textView.reloadInputViews()
        }
    }
}

extension UIButton {
    func applyTintColorTo(withColor: UIColor) {
        imageView?.image = nil
        imageView?.image = UIImage(named: "tooliconBgcolor")
        let mask = CALayer()
        let maskImage = UIImage(named: "tooliconBgcolormask")
        mask.contents = maskImage?.cgImage
        mask.frame = CGRect(x: 0, y: 0, width: maskImage?.size.width ?? 0.0 , height: maskImage?.size.height ?? 0.0)
        imageView?.backgroundColor = withColor
        imageView?.layer.mask = mask
        imageView?.layer.masksToBounds = true
    }
}
