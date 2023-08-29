//
//  FTNewTextStyleViewController.swift
//  Noteshelf
//
//  Created by Mahesh on 31/10/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles
import FTCommon

let maxFontSize: Int = 100
let defaultFontSize: Int = 16

protocol FTEditStyleDelegate: NSObjectProtocol {
    func didChangeStyle(_ style: FTTextStyleItem?)
    func didTapOnAlignmentStyle(_ style: NSTextAlignment)
    func didChangeLineSpacing(lineSpace: CGFloat)
    func didSelectTextRange(range: NSRange?, txtRange: UITextRange?, canEdit: Bool)
    func didSetDefaultStyle(_ info: FTTextStyleItem)
    func textInputViewCurrentTextView() -> FTTextView?
    func rootViewController() -> UIViewController?
}

class FTNewTextStyleViewController: UIViewController, FTPopoverPresentable {
    var ftPresentationDelegate = FTPopoverPresentation()

    @IBOutlet private weak var presetNameLbl: FTCustomLabel?
    @IBOutlet weak var txtStyleName: UITextField?
    @IBOutlet private weak var fontName: UILabel?
    @IBOutlet private weak var sizeLbl: FTCustomLabel?
    @IBOutlet weak var txtFontSize: UITextField?
    @IBOutlet private weak var btnBold: UIButton?
    @IBOutlet private weak var btnItalic: UIButton?
    @IBOutlet private weak var btnUnderline: UIButton?
    @IBOutlet private weak var btnStrikeThrough: UIButton?
    @IBOutlet private weak var colorView: UIView!
    @IBOutlet private weak var textAlignmentView: UIView?
    @IBOutlet private weak var autoLineHeightView: UIStackView?
    @IBOutlet private weak var autoLineHeightSeparatorView: UIView?
    @IBOutlet private weak var presentStyleNameView: UIView?
    @IBOutlet private weak var autoLineHeightStepperView: UIView?
    @IBOutlet private weak var separatorView: UIView?
    @IBOutlet private weak var btnLeftAlignment: UIButton?
    @IBOutlet private weak var btnCentreAlignment: UIButton?
    @IBOutlet private weak var btnRightAlignment: UIButton?
    @IBOutlet private weak var lblLineSpace: UILabel?
    @IBOutlet private weak var traitStackViewHeightConstraint: NSLayoutConstraint?
    @IBOutlet private weak var lineSpacingStackViewHeightConstraint: NSLayoutConstraint?
    
    @IBOutlet private weak var lineHeightStepperView: UIView?
    @IBOutlet private weak var fontSizeStepperView: UIView?
    @IBOutlet weak var lineHeightLbl: UILabel?
    @IBOutlet weak var autoLineHeightLbl: FTCustomLabel?
    @IBOutlet weak var setAsDefaultBtn: UIButton?

    private var selectedTextRange: UITextRange?
    private var selectedRange: NSRange?
    weak var parentVC: UIViewController?
    var iscomeFromTextPreset: Bool = false
    private weak var fontSizeStepper: FTStepperView?
    private weak var lineSpaceStepper: FTStepperView?
    var defaultTextStyleManager = FTDefaultTextStyleManager()
    fileprivate var favoriteFonts: [FTTextStyleItem]!

    weak var delegate: FTEditStyleDelegate?
    var isModifyText: Bool = false
    var textFontStyle: FTTextStyleItem?
    private var newStyle: FTTextStyleItem?
    var collectionView: FTTextColorCollectionView?
     var attributes:[NSAttributedString.Key : Any]?
    var shouldApplyAttributes: Bool = false
    var scale: CGFloat = 1.0
  
    override func viewDidLoad() {
        super.viewDidLoad()
        loadStepperView()
        updateUI()
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.tintColor = .clear
        let shadowColor = UIColor(hexString: "#000000")
        self.view.layer.applySketchShadow(color: shadowColor, alpha: 0.2, x: 0.0, y: 10.0, blur: 60.0, spread: 0)
    }
      
    class func showAsPopover(fromSourceView sourceView: UIView,
                             overViewController viewController: UIViewController,
                             delegate: FTEditStyleDelegate,
                             attributes: [NSAttributedString.Key : Any]?,
                             scale: CGFloat) {
        let storyboard = UIStoryboard.init(name: "FTTextInputUI", bundle: nil)
        guard let textStyleVC = storyboard.instantiateViewController(withIdentifier: "FTNewTextStyleViewController") as? FTNewTextStyleViewController else {
            fatalError("FTNewTextStyleViewController not found")
        }
        textStyleVC.isModifyText = true
        textStyleVC.delegate = delegate
        textStyleVC.scale = scale
        textStyleVC.attributes = attributes
        textStyleVC.parentVC = viewController
        (delegate as? FTTextToolBarViewController)?.textSelectionDelegate = textStyleVC
        textStyleVC.ftPresentationDelegate.source = sourceView
        viewController.ftPresentPopover(vcToPresent: textStyleVC, contentSize: CGSize(width: 320, height: 480))
    }

    private func loadStepperView(){
        let stepper = FTStepperView(frame: CGRect(x: 0, y: 0, width: 90, height: 30), valueCaptureAt: .fontsize)
        configureStepper(stepper)
        fontSizeStepperView?.addSubview(stepper)
        self.fontSizeStepper = stepper

        let linestepper = FTStepperView(frame: CGRect(x: 0, y: 0, width: 90, height: 30), valueCaptureAt: .lineHeight)
        configureStepper(linestepper)
        lineHeightStepperView?.addSubview(linestepper)
        self.lineSpaceStepper = linestepper
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = iscomeFromTextPreset ? "New".localized : "Font/text style"
        self.navigationController?.navigationBar.backgroundColor = UIColor.appColor(.popoverBgColor)
        runInMainThread(0.2) {
            self.reloadColorsCollectionIfRequired()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        if let style = textFontStyle {
            var shouldUpdate = false
            if self.isMovingFromParent {
                if newStyle == nil {
                    FTTextStyleManager.shared.insertNewTextStyle(style)
                    shouldUpdate = true
                } else {
                    if !newStyle!.isFullyEqual(style) {
                        FTTextStyleManager.shared.updateTextStyle(style)
                        shouldUpdate = true
                    }
                }
            }
            if shouldUpdate {
                if let presetVC = self.navigationController?.children.first as? FTTextPresetsViewController {
                    presetVC.updateTextStylesList()
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func updateUI() {
        lineHeightLbl?.text = "shelf.notebook.textstyle.textLineHeight".localized
        autoLineHeightLbl?.text = "shelf.notebook.textstyle.textautoLineHeight".localized
        sizeLbl?.text = "shelf.notebook.textstyle.size".localized
        presetNameLbl?.text = "shelf.notebook.textstyle.presetname".localized

        self.textAlignmentView?.isHidden = !isModifyText
        self.autoLineHeightView?.isHidden = !isModifyText
        self.presentStyleNameView?.isHidden = isModifyText
        self.separatorView?.isHidden = !isModifyText
        self.fontName?.adjustsFontSizeToFitWidth = true
        updateNewTextStyleValue()
        applyFontChanges()
        self.loadColorCollectionView()
        txtFontSize?.text = "\(textFontStyle!.fontSize)"
        NotificationCenter.default.addObserver(self, selector: #selector(changeText(_:)), name: UITextField.textDidChangeNotification, object: nil)
        if let attr = self.attributes {
            self.validateKeyboard(attributes: attr, scale: scale)
        }
        if !self.isModifyText {
            traitStackViewHeightConstraint?.constant = 88.5
            lineSpacingStackViewHeightConstraint?.constant = 0
        }
        
        if let pdfVC = parentVC as? FTPDFRenderViewController, let textAnnot = pdfVC.activeAnnotationController() as? FTTextAnnotationViewController {
            selectedRange = textAnnot.textInputView.selectedRange
            selectedTextRange = textAnnot.textInputView.selectedTextRange
        }
        self.configureTextFields(with: newStyle)
        self.fontSizeStepper?.updateInitialValue(textFontStyle?.fontSize ?? Int(0.0))
        self.updateFontTraitsEnableStatus()
    }

    func updateSetAsDefualtTitle() {
        var title = "SetAsDefault".localized
//        defaultTextStyleManager.customFontInfo.isEqual(newStyle)
        self.setAsDefaultBtn?.setTitle(title, for: .normal)
    }

    internal func updateFontTraitsEnableStatus() {
        self.btnBold?.isEnabled = self.canAddTrait(.traitBold)
        self.btnItalic?.isEnabled = self.canAddTrait(.traitItalic)
    }

    private func configureTextFields(with style: FTTextStyleItem?) {
        var toEnable = false
        if self.isRegularClass() && nil != newStyle {
            toEnable = true
        }
        self.txtStyleName?.isEnabled = toEnable
        self.txtFontSize?.isEnabled = toEnable
        if let superView = self.txtFontSize?.superview {
            superView.backgroundColor = toEnable ? UIColor.appColor(.accentBg) : .clear
        }
    }

    private func updateNewTextStyleValue() {
        guard let fontId = textFontStyle?.fontId else { return }
        newStyle = FTTextStyleManager.shared.fetchTextStyleForId(fontId)
    }
    
    private func loadColorCollectionView() {
        let layout = FTTextColorsFlowLayout()
        collectionView = FTTextColorCollectionView.init(frame: .zero, collectionViewLayout: layout)
        collectionView?.textColorDelegate = self
        collectionView?.selectedColor = self.textFontStyle?.textColor
        collectionView?.addFullConstraints(self.colorView)
        collectionView?.layoutSubviews()
    }
    
    func applyFontChanges(_ canApplyStyle: Bool = true) {
        if textFontStyle == nil {
            textFontStyle = FTTextStyleItem()
        }
        if let item = textFontStyle {
            let fontAttribute = NSMutableAttributedString(string: item.fontFamily)
            self.fontName?.attributedText = fontAttribute.getFormattedAttributedStringFrom(style: item)
            let styleNameAttribute = NSMutableAttributedString(string: item.displayName)
            self.txtStyleName?.attributedText = styleNameAttribute.getFormattedAttributedStringFrom(style: item)
            self.txtStyleName?.textColor = UIColor.appColor(.accent)
            updateTraitButtonsSelectionState()
        }
        
        if canApplyStyle && isModifyText && shouldApplyAttributes {
            self.delegate?.didChangeStyle(textFontStyle)
        }
    }
    
    @objc func applyAttributesStyle() {
        self.txtFontSize?.text = "\(textFontStyle!.fontSize)"
        self.applyFontChanges(false)
    }
    
    private func reloadColorsCollectionIfRequired() {
        if let item = textFontStyle {
            if self.collectionView?.selectedColor?.replacingOccurrences(of: "#", with: "") != item.textColor.replacingOccurrences(of: "#", with: "") {
               // self.collectionView?.reloadSections(IndexSet(integer: 0))
                self.collectionView?.selectedColor = item.textColor
                self.collectionView?.updateSelectedColor()
            } else {
                self.collectionView?.updateSelectedColor()
            }
        }
    }
    
    private func updateTraitButtonsSelectionState() {
        guard let style = textFontStyle else { return }
        if let tempFont = UIFont.init(name: style.fontName, size: CGFloat(style.fontSize)) {
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
            
            if style.isUnderLined {
                btnUnderline?.backgroundColor = UIColor.appColor(.accentBg)
                btnUnderline?.layer.cornerRadius = 8.0
            } else {
                btnUnderline?.backgroundColor = UIColor.clear
            }
            
            if style.strikeThrough {
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
}

extension FTNewTextStyleViewController {
    
    @objc func changeText(_ notification: Notification) {
        self.delegate?.didSelectTextRange(range: selectedRange, txtRange: selectedTextRange, canEdit: false)
        
        guard let txtField = notification.object as? UITextField else { return }
        if txtField == txtFontSize {
            if let value = Int(txtField.text ?? "\(defaultFontSize)") {
                self.textFontStyle?.fontSize = value
            }
        }
        if txtField == txtStyleName {
            if let value = txtField.text {
                self.textFontStyle?.displayName = value
            }
        }
        self.applyFontChanges()
        if isModifyText {
            shouldApplyAttributes = true
        }
    }
    
    @IBAction func tappedOnFontName(_ sender: UIButton) {
        let fontPicker = FTFontPickerViewController(nibName: "FTFontPickerViewController", bundle: Bundle(for: FTFontPickerViewController.self))
        fontPicker.delegate = self
#if !targetEnvironment(macCatalyst)
        self.navigationController?.pushViewController(fontPicker, animated: true)
#else
        self.present(fontPicker, animated: true)
#endif
    }

    private func handlefontSizeChange(value: Int) {
        textFontStyle?.fontSize = Int(value)
        txtFontSize?.text = "\(value)"
        defaultTextStyleManager.textStyleInfo.fontSize = value
        if isModifyText {
            shouldApplyAttributes = true
        }
        applyFontChanges()
    }

    @IBAction func tappedOnFontTraits(_ sender: UIButton) {
        guard let style = textFontStyle else { return }
        if var tempFont = UIFont.init(name: style.fontName, size: CGFloat(style.fontSize)) {
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
                self.textFontStyle?.isUnderLined = !(self.textFontStyle?.isUnderLined ?? false)
                defaultTextStyleManager.textStyleInfo.isUnderLined = self.textFontStyle?.isUnderLined ?? false
            } else if sender.tag == 3 {
                self.textFontStyle?.strikeThrough = !(self.textFontStyle?.strikeThrough ?? false)
                defaultTextStyleManager.textStyleInfo.strikeThrough = self.textFontStyle?.strikeThrough ?? false
            }
            self.textFontStyle?.fontName = tempFont.fontName
            self.shouldApplyAttributes = true
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
        defaultTextStyleManager.textStyleInfo.alignment = align.rawValue
        self.delegate?.didTapOnAlignmentStyle(align)
        highLightBackgroundForTextAlignmentButtons(alignment: align)
    }

    private func handleLineSpaceChange(value: Int){
        lblLineSpace?.text = "\(value) pt"
        defaultTextStyleManager.textStyleInfo.lineSpace = value
        self.delegate?.didChangeLineSpacing(lineSpace: CGFloat(value))
    }
    
    @IBAction func tappedOnAutoLineHeightSwitch(_ sender: UISwitch) {
        let isOn = sender.isOn
        self.autoLineHeightStepperView?.isHidden = isOn
        self.autoLineHeightSeparatorView?.isHidden = isOn
        if isOn {
            self.delegate?.didChangeLineSpacing(lineSpace: 0.0)
        }
        let value = isOn ? 44 : 88.5
        self.lineSpacingStackViewHeightConstraint?.constant = value
    }

    @IBAction func setAsDefaultTapped(_ sender: Any) {
        self.delegate?.didSetDefaultStyle(self.defaultTextStyleManager.textStyleInfo)
        self.resetCustomInfo()
        let alertController = UIAlertController.init(title: "", message: "SetAsDefaultMessage".localized, preferredStyle: UIAlertController.Style.alert)
        let action1 = UIAlertAction.init(title: "No".localized, style: .cancel, handler: { (_) in
        })
        alertController.addAction(action1)

        let action2 = UIAlertAction.init(title: "Yes".localized, style: UIAlertAction.Style.default, handler: { (_) in
            var fontInfoDict: [String: String] = [:]
            fontInfoDict[FTFontStorage.fontNameKey] = self.defaultTextStyleManager.textStyleInfo.fontName
            fontInfoDict[FTFontStorage.fontStyleKey] = self.defaultTextStyleManager.textStyleInfo.fontFamily
            fontInfoDict[FTFontStorage.fontSizeKey] = String(self.defaultTextStyleManager.textStyleInfo.fontSize)
            fontInfoDict[FTFontStorage.textColorKey] = self.defaultTextStyleManager.textStyleInfo.textColor
            fontInfoDict[FTFontStorage.isUnderlinedKey] = self.defaultTextStyleManager.textStyleInfo.isUnderLined ? "1" : "0"
            fontInfoDict[FTFontStorage.isLineSpaceEnabledKey] = self.defaultTextStyleManager.textStyleInfo.isAutoLineSpace ? "1" : "0"
            fontInfoDict[FTFontStorage.lineSpaceKey] = String(self.defaultTextStyleManager.textStyleInfo.lineSpace)
            fontInfoDict[FTFontStorage.isStrikeThroughKey] = self.defaultTextStyleManager.textStyleInfo.strikeThrough ? "1" : "0"
            fontInfoDict[FTFontStorage.textAlignmentKey] = String(self.defaultTextStyleManager.textStyleInfo.alignment)
            FTUserDefaults.saveDefaultFontForAll(fontInfoDict)
        })
        alertController.addAction(action2)

        let controller = self.delegate?.rootViewController()
        if self.isRegularClass() {
            self.dismiss(animated: true) {
                controller?.present(alertController, animated: true, completion: nil)
            }
        } else {
            controller?.present(alertController, animated: true, completion: nil)
        }
    }

    private func resetCustomInfo() {
        if let tempFont = UIFont(name: self.defaultTextStyleManager.textStyleInfo.fontName, size: CGFloat(self.defaultTextStyleManager.textStyleInfo.fontSize)) {
            self.defaultTextStyleManager.textStyleInfo.fontName = tempFont.fontName
            self.defaultTextStyleManager.textStyleInfo.fontFamily = tempFont.familyName
        }
    }
}

extension FTNewTextStyleViewController: FTTextSelectionChangeDelegate {
    func didChangeTextSelectionAttributes(_ attributes: [NSAttributedString.Key : Any]?, scale: CGFloat) {
        if let attr = attributes {
            shouldApplyAttributes = true
            self.validateKeyboard(attributes: attr, scale: scale)
        }
    }
    
    private func validateKeyboard(attributes: [NSAttributedString.Key : Any], scale: CGFloat) {
        if var font = attributes[NSAttributedString.Key.font] as? UIFont {
            if let originalFont = attributes[NSAttributedString.Key(rawValue: "NSOriginalFont")] as? UIFont {
                font = originalFont
            }

            let fontPointSize = font.pointSize/scale
            textFontStyle?.fontFamily = font.familyName
            textFontStyle?.fontName = font.fontName
            textFontStyle?.fontSize = Int(fontPointSize)

            defaultTextStyleManager.textStyleInfo.displayName = font.familyName
            defaultTextStyleManager.textStyleInfo.fontName = font.fontName
            defaultTextStyleManager.textStyleInfo.fontSize = Int(fontPointSize)
        }
        if let fontColor = attributes[NSAttributedString.Key.foregroundColor] as? UIColor {
            textFontStyle?.textColor = fontColor.hexString
            defaultTextStyleManager.textStyleInfo.textColor = fontColor.hexString
        }
        if let isUnderLined = attributes[NSAttributedString.Key.underlineStyle] as? Int {
            textFontStyle?.isUnderLined = (isUnderLined == 1)
        }
        if let isStrikeThrough = attributes[NSAttributedString.Key.strikethroughStyle] as? Int {
            textFontStyle?.strikeThrough = (isStrikeThrough == 1)
        }

        if let paragrapghStyle = attributes[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle {
            let lineSpace = Int(paragrapghStyle.lineSpacing)
            lineSpaceStepper?.updateInitialValue(Int(lineSpace))
            lblLineSpace?.text = "\(Int(lineSpace)) pt"
           let alignment = paragrapghStyle.alignment
            highLightBackgroundForTextAlignmentButtons(alignment: alignment)
            textFontStyle?.lineSpace = lineSpace
            textFontStyle?.alignment = alignment.rawValue
        }

        reloadColorsCollectionIfRequired()

        self.classForCoder.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.applyAttributesStyle), object: self)
        perform(#selector(self.applyAttributesStyle), with: self, afterDelay: 0.5, inModes: [.default])
    }
}

extension FTNewTextStyleViewController: UIPopoverPresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.txtFontSize?.resignFirstResponder()
        self.delegate?.didSelectTextRange(range: selectedRange, txtRange: selectedTextRange, canEdit: true)
    }
}
extension FTNewTextStyleViewController: FTStepperViewDelegate{
    func valueChanged(_ value: Int, valueCaptureAt: StepperValueCapturedIn) {
        if valueCaptureAt == .fontsize{
            handlefontSizeChange(value: value)
        }else{
            handleLineSpaceChange(value: value)
        }
    }
    private func configureStepper(_ fontStepper: FTStepperView) {
        fontStepper.backgroundColor = UIColor.appColor(.accentBg)
        fontStepper.delegate = self
        fontStepper.layer.cornerRadius = 9.0
        fontStepper.clipsToBounds = true
    }
}
