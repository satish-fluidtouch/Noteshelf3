//
//  FTTextStyleCompactViewController.swift
//  Noteshelf
//
//  Created by Mahesh on 12/12/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

protocol FTTextStyleCompactDelegate: FTDefaultTextStyleDelegate, FTRootControllerInfo {
    func didSelectFontStyle(_ style: FTTextStyleItem)
    func didChangeAlignmentStyle(_ style: NSTextAlignment)
    func changeLineSpacing(_ lineSpace: CGFloat)
    func changeBackgroundColor(_ color: UIColor)
    func dismissKeyBoard()
}

protocol FTTextColorUpdateDelegate: NSObjectProtocol {
    func didUpdateTextColor()
}

class FTTextStyleCompactViewController: UIInputViewController {
    @IBOutlet weak private var stylesStackView: UIStackView?
    @IBOutlet weak private var fontNameLbl: UILabel?
    @IBOutlet private weak var lineHeightLbl: UILabel?
    @IBOutlet private weak var sizeLbl: UILabel?
    @IBOutlet private weak var autolineHeightLbl: FTCustomLabel?
    @IBOutlet weak private var txtFontSize: UITextField?
    @IBOutlet private weak var fontSizeStepper: UIStepper?
    @IBOutlet private weak var btnBold: UIButton?
    @IBOutlet private weak var btnItalic: UIButton?
    @IBOutlet private weak var btnUnderline: UIButton?
    @IBOutlet private weak var btnStrikeThrough: UIButton?
    @IBOutlet private weak var btnLeftAlignment: UIButton?
    @IBOutlet private weak var btnCentreAlignment: UIButton?
    @IBOutlet private weak var btnRightAlignment: UIButton?
    
    @IBOutlet private weak var autoLineHeightView: UIStackView?
    @IBOutlet private weak var autoLineHeightStepperView: UIView?
    @IBOutlet private weak var autoLineHeightSeparatorView: UIView?
    @IBOutlet private weak var lblLineSpace: UILabel?
    @IBOutlet private weak var lineSpaceStepper: UIStepper?
    @IBOutlet private weak var lineSpacingStackViewHeightConstraint: NSLayoutConstraint?
    @IBOutlet private weak var mainViewWidthConstraint: NSLayoutConstraint?
    @IBOutlet private weak var btnTextColor: UIButton?
    @IBOutlet private weak var btnTextBackGroundColor: UIButton?
    @IBOutlet private weak var autoLineHeightSwitch: UISwitch?

    private var currentSize = CGSize.zero
    private var attributes:[NSAttributedString.Key: Any]?
    private var currentLineSpace: Int = 0
    private var currentAlignment: NSTextAlignment = .left

    var scale: CGFloat = 1.0
    var shouldApplyAttributes = false
    var textFontStyle = FTTextStyleItem()
    weak var delegate: FTTextStyleCompactDelegate?
    weak var textColorDelegate: FTTextColorUpdateDelegate?

    private var isAutoLineSpaceEnabled = false {
        didSet {
            self.autoLineHeightStepperView?.isHidden = isAutoLineSpaceEnabled
            self.autoLineHeightSeparatorView?.isHidden = isAutoLineSpaceEnabled
            self.autoLineHeightSwitch?.isOn = isAutoLineSpaceEnabled
            self.lineSpacingStackViewHeightConstraint?.constant = isAutoLineSpaceEnabled ? 44 : 88.5
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        if let attr = self.attributes {
            self.validateKeyboard(attributes: attr, scale: scale)
        }
    }
    
    class func viewControllerForCompact(_ delegate: FTTextStyleCompactDelegate,
                                        attributes: [NSAttributedString.Key : Any]?,
                                        scale: CGFloat) -> FTTextStyleCompactViewController {
        let storyboard = UIStoryboard.init(name: "FTTextInputUI", bundle: nil);
        let controller = storyboard.instantiateViewController(withIdentifier: "FTTextStyleCompactViewController") as! FTTextStyleCompactViewController;
        controller.delegate = delegate
        controller.attributes = attributes
        controller.scale = scale
        (delegate as? FTTextToolBarViewController)?.textSelectionDelegate = controller
        controller.view.autoresizingMask = UIView.AutoresizingMask.init(rawValue: 0)
        return controller;
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let currentFrameSize = self.view.frame.size
        if(currentFrameSize != self.currentSize) {
            self.currentSize = currentFrameSize
            if (self.delegate as? UIViewController)?.isRegularClass() ?? false {
                self.mainViewWidthConstraint?.constant = 375
            } else {
                if UIDevice.current.userInterfaceIdiom == .phone {
                    self.mainViewWidthConstraint?.constant = currentFrameSize.width - 32
                } else {
                    self.mainViewWidthConstraint?.constant = 375
                }
            }
        }
    }
    
    private func configureUI() {
        self.txtFontSize?.isEnabled = false
        self.navigationController?.navigationBar.backgroundColor = UIColor.appColor(.popoverBgColor)
        lineHeightLbl?.text = "shelf.notebook.textstyle.textLineHeight".localized
        autolineHeightLbl?.text = "shelf.notebook.textstyle.textautoLineHeight".localized
        sizeLbl?.text = "shelf.notebook.textstyle.size".localized
        loadTextStyles()
    }
    
    private func fetchStyles() -> FTTextStyle {
        let textStyles = FTTextStyleManager.shared.fetchTextStylesFromPlist()
        return textStyles
    }
    
    private func loadTextStyles() {
         let textStyles = fetchStyles()
        let styles = textStyles.styles.prefix(Int(3))
        if styles.count > 0 {
            stylesStackView?.arrangedSubviews.forEach { $0.removeFromSuperview() }
            for (idx, item) in styles.enumerated() {
                let button = UIButton(type: .custom)
                button.frame = CGRect(x: idx * defaultButtonWidth, y: 0, width: defaultButtonWidth, height: 36)
                button.tag = idx
                let attributeText = NSMutableAttributedString(string: item.textStyleShortName())
                button.setAttributedTitle(attributeText.getFormattedAttributedStringFrom(style: item, defaultFont: 16), for: .normal)
                button.addTarget(self, action:#selector(didSelectedStyle(_:)), for: .touchUpInside)
                stylesStackView?.addArrangedSubview(button)
            }
        }
    }
    
    private func resetBackgroundColorForTextStyles() {
        stylesStackView?.arrangedSubviews.forEach({ vw in
            if let btn = vw as? UIButton {
                btn.backgroundColor = .clear
                btn.layer.cornerRadius = .zero
            }
        })
    }
    
    func applyFontChanges(_ canApplyStyle: Bool = true) {
        let fontAttribute = NSMutableAttributedString(string: textFontStyle.fontFamily)
        self.fontNameLbl?.attributedText = fontAttribute.getFormattedAttributedStringFrom(style: textFontStyle)
        self.fontSizeStepper?.value = Double(textFontStyle.fontSize)
        updateTraitButtonsSelectionState()
        btnTextColor?.tintColor = UIColor(hexString: textFontStyle.textColor)
        if canApplyStyle {
            self.delegate?.didSelectFontStyle(textFontStyle)
        }
    }
    
    private func updateTraitButtonsSelectionState() {
        if let tempFont = UIFont.init(name: textFontStyle.fontName, size: CGFloat(textFontStyle.fontSize)) {
            if tempFont.isItalicTrait() {
                btnItalic?.backgroundColor = UIColor.appColor(.accentBg)
                btnItalic?.layer.cornerRadius = 8.0
            } else {
                btnItalic?.backgroundColor = UIColor.clear
            }
            
            if tempFont.isBoldTrait() {
                btnBold?.backgroundColor = UIColor.appColor(.accentBg)
                btnBold?.layer.cornerRadius = 8.0
            } else {
                btnBold?.backgroundColor = UIColor.clear
            }
            
            if textFontStyle.isUnderLined {
                btnUnderline?.backgroundColor = UIColor.appColor(.accentBg)
                btnUnderline?.layer.cornerRadius = 8.0
            } else {
                btnUnderline?.backgroundColor = UIColor.clear
            }
            
            if textFontStyle.strikeThrough {
                btnStrikeThrough?.backgroundColor = UIColor.appColor(.accentBg)
                btnStrikeThrough?.layer.cornerRadius = 8.0
            } else {
                btnStrikeThrough?.backgroundColor = UIColor.clear
            }
        }
    }
    
    private func resetTextAlignmentButtonsBackgroundColor() {
        btnLeftAlignment?.backgroundColor = UIColor.clear
        btnCentreAlignment?.backgroundColor = UIColor.clear
        btnRightAlignment?.backgroundColor = UIColor.clear
    }
    
    private func highLightBackgroundForTextAlignmentButtons(alignment: NSTextAlignment) {
        resetTextAlignmentButtonsBackgroundColor()
        var btn: UIButton?
        switch alignment {
        case .left:
            btn = btnLeftAlignment
        case .center:
            btn = btnCentreAlignment
        case .right:
            btn = btnRightAlignment
        default:
            break
        }
        btn?.backgroundColor = UIColor.appColor(.accentBg)
        btn?.layer.cornerRadius = 8.0
    }
    
    func didHighLightSelectedStyle(attr: [NSAttributedString.Key : Any]?, scale: CGFloat) {
        guard let attributes = attr else { return }
        let textStyles = fetchStyles() 
        let styles = textStyles.styles.prefix(3)
        let style = FTTextStyleItem().textStyleFromAttributes(attributes, scale: scale)
        if let index = styles.firstIndex(where: {$0.isEqual(style)}) {
            if let btn = stylesStackView?.arrangedSubviews.filter({$0.tag == index}).first as? UIButton {
                self.highLightSelectedStyle(btn)
            }
        } else {
            resetBackgroundColorForTextStyles()
        }
    }
    
    private func highLightSelectedStyle(_ sender: UIButton) {
        resetBackgroundColorForTextStyles()
        sender.backgroundColor = UIColor.appColor(.accentBg)
        sender.layer.cornerRadius = 8.0
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
        btnTextBackGroundColor?.applyTintColorTo(withColor: colorToSet)
    }
}

//MARK:- Action Handlers
extension FTTextStyleCompactViewController {
    @objc func didSelectedStyle(_ sender: UIButton) {
        let textStyles = fetchStyles()
        highLightSelectedStyle(sender)
        let style = textStyles.styles[sender.tag]
        self.delegate?.didSelectFontStyle(style)
    }
    
    @IBAction func tappedOnStylesList(_ sender: UIButton) {
        FTTextPresetsViewController.showAsPopover(fromSourceView: sender, overViewController: self, delegate: self, attributes: nil, scale: 1.0)
    }
    
    @IBAction func tappedOnFontSelector(_ sender: UIButton) {
        let fontPicker: FTFontPickerViewController = FTFontPickerViewController(nibName: "FTFontPickerViewController", bundle: Bundle(for: FTFontPickerViewController.self))
        fontPicker.delegate = self
        self.present(fontPicker, animated: true)
    }
    
    @IBAction func tappedOnFontSizeStepper(_ sender: UIStepper) {
        let stepperValue = Int(sender.value)
        textFontStyle.fontSize = Int(stepperValue)
        txtFontSize?.text = "\(stepperValue)"
        applyFontChanges()
    }
    
    @IBAction func tappedOnFontTraits(_ sender: UIButton) {
        if var tempFont = UIFont.init(name: textFontStyle.fontName, size: CGFloat(textFontStyle.fontSize)) {
            if sender.tag == 0 {
                if self.canAddTrait(.traitBold) {
                    if tempFont.isBoldTrait() {
                        tempFont = tempFont.removeTrait(.traitBold)
                    } else {
                        tempFont = tempFont.addTrait(.traitBold)
                    }
                }
            } else if sender.tag == 1 {
                if self.canAddTrait(.traitItalic) {
                    if tempFont.isItalicTrait() {
                        tempFont = tempFont.removeTrait(.traitItalic)
                    } else {
                        tempFont = tempFont.addTrait(.traitItalic)
                    }
                }
            } else if sender.tag == 2 {
                self.textFontStyle.isUnderLined = !(self.textFontStyle.isUnderLined)
            } else if sender.tag == 3 {
                self.textFontStyle.strikeThrough = !(self.textFontStyle.strikeThrough)
            }
            self.textFontStyle.fontName = tempFont.fontName
            self.applyFontChanges()
        }
    }
    
    @IBAction func tappedOnTextAlignment(_ sender: UIButton) {
        var align: NSTextAlignment = .justified
        if sender.tag == 0 {
            align = .left
        } else if sender.tag == 1 {
            align = .center
        } else if sender.tag == 2 {
            align = .right
        }
        self.delegate?.didChangeAlignmentStyle(align)
        self.currentAlignment = align
        highLightBackgroundForTextAlignmentButtons(alignment: align)
    }
    
    @IBAction func tappedOnLineSpaceStepper(_ sender: UIStepper) {
        let stepperValue = Int(sender.value)
        lblLineSpace?.text = "\(stepperValue) pt"
        self.currentLineSpace = stepperValue
        self.delegate?.changeLineSpacing(CGFloat(stepperValue))
    }
    
    @IBAction func tappedOnAutoLineHeightSwitch(_ sender: UISwitch) {
        let isOn = sender.isOn
        self.isAutoLineSpaceEnabled = isOn
        if isOn {
            self.delegate?.changeLineSpacing(0.0)
            self.currentLineSpace = 0
        }
    }
    
    @objc func applyAttributesStyle() {
        self.txtFontSize?.text = "\(textFontStyle.fontSize)"
        self.applyFontChanges(false)
        self.updateFontTraitsEnableStatus()
        self.didHighLightSelectedStyle(attr: self.attributes, scale: self.scale)
    }
    
    @IBAction func tappedOnBackgroundColor(_ sender: UIButton) {
        FTTextBackGroundColorViewController.showAsPopover(fromSourceView: sender, overViewController: self, delegate: self)
    }
    
    @IBAction func tappedOnTextColorButton(_ sender: UIButton) {
        FTTextColorViewController.showAsPopover(fromSourceView: sender, textStyle: textFontStyle, delegate: self)
    }

    @IBAction func setAsDefaultTapped(_ sender: Any) {
        let defaultStyleItem = FTDefaultTextStyleItem(from: self.textFontStyle, isAutoLineSpace: self.isAutoLineSpaceEnabled, lineSpace: self.currentLineSpace, alignment: self.currentAlignment)
        let menu = UIMenu(title: "text.font.setAsDefault.menuTitle".localized, children: [
            UIAction(title: "text.font.setAsDefault.thisBook".localized, handler: { [weak self] _ in
                guard let self else { return }
                self.delegate?.didSetDefaultStyle(defaultStyleItem)
            }),
            UIAction(title: "text.font.setAsDefault.thisAndFutureBooks".localized, handler: { [weak self] _ in
                guard let self else { return }
                self.delegate?.didSetDefaultStyle(defaultStyleItem)

                var fontInfoDict: [String: String] = [:]
                defaultStyleItem.alignment = self.currentAlignment.rawValue
                defaultStyleItem.isAutoLineSpace = self.isAutoLineSpaceEnabled
                defaultStyleItem.lineSpace = self.currentLineSpace

                fontInfoDict[FTFontStorage.fontNameKey] = defaultStyleItem.fontName
                fontInfoDict[FTFontStorage.fontStyleKey] = defaultStyleItem.fontFamily
                fontInfoDict[FTFontStorage.fontSizeKey] = String(defaultStyleItem.fontSize)
                fontInfoDict[FTFontStorage.textColorKey] = defaultStyleItem.textColor
                fontInfoDict[FTFontStorage.isUnderlinedKey] = defaultStyleItem.isUnderLined ? "1" : "0"
                fontInfoDict[FTFontStorage.isLineSpaceEnabledKey] = defaultStyleItem.isAutoLineSpace ? "1" : "0"
                fontInfoDict[FTFontStorage.lineSpaceKey] = String(defaultStyleItem.lineSpace)
                fontInfoDict[FTFontStorage.isStrikeThroughKey] = defaultStyleItem.strikeThrough ? "1" : "0"
                fontInfoDict[FTFontStorage.textAlignmentKey] = String(defaultStyleItem.alignment)
                FTUserDefaults.saveDefaultFontForAll(fontInfoDict)
            }),
        ])
        (sender as? UIButton)?.menu = menu
    }
}

extension FTTextStyleCompactViewController: FTTextPresetSelectedDelegate {
    func rootViewController() -> UIViewController? {
        return self.delegate?.rootViewController()
    }

    func reloadStylesStackView() {
        loadTextStyles()
    }
    
    func didSelectedPresetStyleId(_ style: FTTextStyleItem) {
        print(style)
    }

    override func dismissKeyboard() {
//        self.view.endEditing(true)
        self.delegate?.dismissKeyBoard()
    }
}

extension FTTextStyleCompactViewController : FTSystemFontPickerDelegate, UIFontPickerViewControllerDelegate {
    
    func didPickFontFromSystemFontPicker(_ viewController : FTFontPickerViewController?, selectedFontDescriptor: UIFontDescriptor) {
        if let fontFamily = selectedFontDescriptor.object(forKey: .family) as? String, let displayName = selectedFontDescriptor.object(forKey: .visibleName) as? String {
            if let _ = selectedFontDescriptor.object(forKey: .face) as? String, let fontName = selectedFontDescriptor.object(forKey: .name) as? String {
                self.textFontStyle.fontName = fontName
                self.textFontStyle.fontFamily = fontFamily
            } else {
                self.textFontStyle.fontName = displayName
                self.textFontStyle.fontFamily = fontFamily
            }
        }
        self.applyFontChanges()
    }
}

extension FTTextStyleCompactViewController  {
    func canAddTrait(_ trait : UIFontDescriptor.SymbolicTraits) -> Bool {
        guard let testFont = UIFont.init(name: textFontStyle.fontName, size: CGFloat(textFontStyle.fontSize)) else {
            return false
        }
        return testFont.canAddTrait(trait)
    }

    internal func updateFontTraitsEnableStatus() {
        self.btnBold?.isEnabled = self.canAddTrait(.traitBold)
        self.btnItalic?.isEnabled = self.canAddTrait(.traitItalic)
    }
}

extension FTTextStyleCompactViewController: FTTextSelectionChangeDelegate {
    func didChangeTextSelectionAttributes(_ attributes: [NSAttributedString.Key: Any]?, scale: CGFloat) {
        if let attr = attributes {
            shouldApplyAttributes = true
            self.validateKeyboard(attributes: attr, scale: scale)
        }
    }
    
    private func validateKeyboard(attributes: [NSAttributedString.Key : Any], scale: CGFloat) {
        self.attributes = attributes
        self.scale = scale
        if var font = attributes[NSAttributedString.Key.font] as? UIFont {
            if let originalFont = attributes[NSAttributedString.Key(rawValue: "NSOriginalFont")] as? UIFont {
                font = originalFont
            }
            let fontPointSize = font.pointSize/scale
            textFontStyle.fontFamily = font.familyName
            textFontStyle.fontName = font.fontName
            textFontStyle.fontSize = Int(fontPointSize)
        }
        if let fontColor = attributes[NSAttributedString.Key.foregroundColor] as? UIColor {
            textFontStyle.textColor = fontColor.hexString
        }
        if let isUnderLined = attributes[NSAttributedString.Key.underlineStyle] as? Int {
            textFontStyle.isUnderLined = (isUnderLined == 1)
        }
        if let isStrikeThrough = attributes[NSAttributedString.Key.strikethroughStyle] as? Int {
            textFontStyle.strikeThrough = (isStrikeThrough == 1)
        }
        if let bgColor = attributes[.backgroundColor] as? UIColor {
            self.updateBackgroundColorPickerButton(bgColor)
        }

        if let paragrapghStyle = attributes[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle {
            let lineSpace = Int(paragrapghStyle.lineSpacing)
            lblLineSpace?.text = "\(Int(lineSpace)) pt"
            self.currentLineSpace = lineSpace
            let alignment = paragrapghStyle.alignment
            highLightBackgroundForTextAlignmentButtons(alignment: alignment)
            self.currentAlignment = alignment
        }

        let isLineSpaceAttrKey = NSAttributedString.Key(rawValue: FTFontStorage.isLineSpaceEnabledKey)
        if let isLineSpaceEnabled = attributes[isLineSpaceAttrKey] as? Int {
            self.isAutoLineSpaceEnabled = (isLineSpaceEnabled == 1)
        }
        self.classForCoder.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.applyAttributesStyle), object: self)
        perform(#selector(self.applyAttributesStyle), with: self, afterDelay: 0.5, inModes: [.default])
    }
}

extension FTTextStyleCompactViewController: FTTextBackGroundColorDelegate {
    func didSelectColor(_ color: UIColor) {
        if(color == UIColor.clear) {
            UserDefaults.standard.removeObject(forKey: "text_background_color")
        } else {
            let colorString = color.hexStringFromColor()
            UserDefaults.standard.set(colorString, forKey: "text_background_color")
        }
        self.delegate?.changeBackgroundColor(color)
        self.updateBackgroundColorPickerButton(color)
    }
}

extension FTTextStyleCompactViewController: FTTextColorDelegate {
    func didSelectColor(_ colorStr: String) {
        self.textFontStyle.textColor = colorStr
        applyFontChanges()
    }
}
