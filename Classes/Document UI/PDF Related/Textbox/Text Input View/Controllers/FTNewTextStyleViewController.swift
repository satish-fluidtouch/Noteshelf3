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

let defaultFontSize: Int = 16

enum FTTextStyleScreenMode: String {
    case defaultView
    case presetEdit
    case presetAdd
}

protocol FTDefaultTextStyleDelegate: NSObjectProtocol {
    func didSetDefaultStyle(_ info: FTDefaultTextStyleItem)
}

protocol FTRootControllerInfo: NSObjectProtocol {
    func rootViewController() -> UIViewController?
}

protocol FTEditStyleDelegate: FTDefaultTextStyleDelegate, FTRootControllerInfo {
    func didChangeStyle(_ style: FTTextStyleItem?)
    func didTapOnAlignmentStyle(_ style: NSTextAlignment)
    func didChangeLineSpacing(lineSpace: CGFloat)
    func didAutoLineSpaceStatusChanged(_ status: Bool)
    func didSelectTextRange(range: NSRange?, txtRange: UITextRange?, canEdit: Bool)
    func textInputViewCurrentTextView() -> FTTextView?
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
    @IBOutlet private weak var setAsDefaultBtn: UIButton?
    @IBOutlet private weak var autoLineHeightSwitch: UISwitch?

    private var selectedTextRange: UITextRange?
    private var selectedRange: NSRange?
    weak var parentVC: UIViewController?
    private weak var fontSizeStepper: FTStepperView?
    private weak var lineSpaceStepper: FTStepperView?
    private var currentLineSpace: Int = 0
    private var currentAlignment: NSTextAlignment = .left

    var textFontStyle = FTTextStyleItem()
    var collectionView: FTTextColorCollectionView?
    var attributes:[NSAttributedString.Key : Any]?
    var shouldApplyAttributes: Bool = false
    var scale: CGFloat = 1.0
    weak var delegate: FTEditStyleDelegate?
    internal var textStyleMode: FTTextStyleScreenMode = .defaultView

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
        self.loadStepperView()
        self.initInfoLabels()
        self.updateUI()
        self.addObservers()
        self.configureSetAsDefault()
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

    private func initInfoLabels() {
        self.lineHeightLbl?.text = "shelf.notebook.textstyle.textLineHeight".localized
        self.autoLineHeightLbl?.text = "shelf.notebook.textstyle.textautoLineHeight".localized
        self.sizeLbl?.text = "shelf.notebook.textstyle.size".localized
        self.presetNameLbl?.text = "shelf.notebook.textstyle.presetname".localized
    }

    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(changeText(_:)), name: UITextField.textDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didTextAnnotationBoxResign), name: ftDidTextAnnotationResignNotifier, object: nil)
    }

    private func updateUI() {
        self.fontName?.adjustsFontSizeToFitWidth = true
        let shadowColor = UIColor(hexString: "#000000")
        self.view.layer.applySketchShadow(color: shadowColor, alpha: 0.2, x: 0.0, y: 10.0, blur: 60.0, spread: 0)
        self.applyFontChanges()
        if let attr = self.attributes {
            self.validateKeyboard(attributes: attr, scale: scale)
        }
        self.loadColorCollectionView()
        self.txtFontSize?.text = "\(textFontStyle.fontSize)"
        self.fontSizeStepper?.updateInitialValue(textFontStyle.fontSize)
        if let pdfVC = parentVC as? FTPDFRenderViewController, let textAnnot = pdfVC.activeAnnotationController() as? FTTextAnnotationViewController {
            self.selectedRange = textAnnot.textInputView.selectedRange
            self.selectedTextRange = textAnnot.textInputView.selectedTextRange
        }
    }

    private func configureSetAsDefault() {
        self.setAsDefaultBtn?.setTitle("SetAsDefault".localized, for: .normal)
        let menu = UIMenu(title: "text.font.setAsDefault.menuTitle".localized, children: [
            UIAction(title: "text.font.setAsDefault.thisBook".localized, handler: { [weak self] _ in
                guard let self else { return }
                let defaultStyleItem = FTDefaultTextStyleItem(from: self.textFontStyle, isAutoLineSpace: self.isAutoLineSpaceEnabled, lineSpace: self.currentLineSpace, alignment: self.currentAlignment)
                self.delegate?.didSetDefaultStyle(defaultStyleItem)
            }),
            UIAction(title: "text.font.setAsDefault.thisAndFutureBooks".localized, handler: { [weak self] _ in
                guard let self else { return }
                let defaultStyleItem = FTDefaultTextStyleItem(from: self.textFontStyle, isAutoLineSpace: self.isAutoLineSpaceEnabled, lineSpace: self.currentLineSpace, alignment: self.currentAlignment)
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
        self.setAsDefaultBtn?.menu = menu
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func didTextAnnotationBoxResign() {
        // TODO: // Narayana - fix to be optimized, as of now when FTextView is resigned (by end editing)
        // we are dismissing the controller shown as popover over keyboard(using mode)
        if self.textStyleMode == .defaultView {
            self.dismiss(animated: true)
        }
    }

    private func updateNavigationBar() {
        var title = "Font/text style"
        if self.textStyleMode == .presetEdit {
            title = "Edit".localized
        }
        self.title = title
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateNavigationBar()
        self.updateUIChanges(with: self.textStyleMode)
        self.navigationController?.navigationBar.backgroundColor = UIColor.appColor(.popoverBgColor)
        runInMainThread(0.2) {
            self.reloadColorsCollectionIfRequired()
        }
    }

    private func updateUIChanges(with mode: FTTextStyleScreenMode) {
        let isDefaultMode = (textStyleMode == .defaultView)
        self.textAlignmentView?.isHidden = !isDefaultMode
        self.autoLineHeightView?.isHidden = !isDefaultMode
        self.setAsDefaultBtn?.isHidden = !isDefaultMode
        self.presentStyleNameView?.isHidden = isDefaultMode
        self.separatorView?.isHidden = !isDefaultMode
        self.txtStyleName?.isEnabled = !isDefaultMode
        self.txtFontSize?.isEnabled = !isDefaultMode
        self.setAsDefaultBtn?.isHidden = !isDefaultMode
        if !isDefaultMode {
            self.traitStackViewHeightConstraint?.constant = 88.5
            self.lineSpacingStackViewHeightConstraint?.constant = 0
        }
        if let superView = self.txtFontSize?.superview {
            superView.backgroundColor = !isDefaultMode ? UIColor.appColor(.accentBg) : .clear
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        if self.isMovingFromParent {
            var shouldUpdate = false
            if self.textStyleMode == .presetEdit {
                let existingStyles = FTTextStyleManager.shared.fetchTextStylesFromPlist().styles
                let isEqualToExistingStyle = existingStyles.contains { existingStyle in
                    self.textFontStyle.isFullyEqual(existingStyle)
                }
                if !isEqualToExistingStyle {
                    FTTextStyleManager.shared.updateTextStyle(textFontStyle)
                    shouldUpdate = true
                }
            } else if self.textStyleMode == .presetAdd {
                textFontStyle.fontId = UUID().uuidString
                textFontStyle.isDefault = false
                FTTextStyleManager.shared.insertNewTextStyle(textFontStyle)
                shouldUpdate = true
            }
            if shouldUpdate {
                if let presetVC = self.navigationController?.children.first as? FTTextPresetsViewController {
                    presetVC.updateTextStylesList()
                }
            }
        }
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
        textStyleVC.delegate = delegate
        textStyleVC.scale = scale
        textStyleVC.attributes = attributes
        textStyleVC.parentVC = viewController
        (delegate as? FTTextToolBarViewController)?.textSelectionDelegate = textStyleVC
        textStyleVC.ftPresentationDelegate.source = sourceView
        textStyleVC.textStyleMode = .defaultView
        viewController.ftPresentPopover(vcToPresent: textStyleVC, contentSize: CGSize(width: 320, height: 480))
    }

    internal func updateFontTraitsEnableStatus() {
        self.btnBold?.isEnabled = self.canAddTrait(.traitBold)
        self.btnItalic?.isEnabled = self.canAddTrait(.traitItalic)
    }

    private func loadColorCollectionView() {
        let layout = FTTextColorsFlowLayout()
        collectionView = FTTextColorCollectionView.init(frame: .zero, collectionViewLayout: layout)
        collectionView?.textColorDelegate = self
        collectionView?.selectedColor = self.textFontStyle.textColor
        collectionView?.addFullConstraints(self.colorView)
        collectionView?.layoutSubviews()
    }
    
    func applyFontChanges(_ canApplyStyle: Bool = true) {
            let fontAttribute = NSMutableAttributedString(string: textFontStyle.fontFamily)
            self.fontName?.attributedText = fontAttribute.getFormattedAttributedStringFrom(style: textFontStyle)
            let styleNameAttribute = NSMutableAttributedString(string: textFontStyle.displayName)
            self.txtStyleName?.attributedText = styleNameAttribute.getFormattedAttributedStringFrom(style: textFontStyle)
            self.txtStyleName?.textColor = UIColor.appColor(.accent)
            updateTraitButtonsSelectionState()

        if canApplyStyle && (self.textStyleMode == .defaultView) && shouldApplyAttributes {
            self.delegate?.didChangeStyle(textFontStyle)
        }
    }
    
    @objc func applyAttributesStyle() {
        self.txtFontSize?.text = "\(textFontStyle.fontSize)"
        self.applyFontChanges(false)
    }
    
    internal func reloadColorsCollectionIfRequired() {
        if self.collectionView?.selectedColor?.replacingOccurrences(of: "#", with: "") != textFontStyle.textColor.replacingOccurrences(of: "#", with: "") {
            // self.collectionView?.reloadSections(IndexSet(integer: 0))
            self.collectionView?.selectedColor = textFontStyle.textColor
            self.collectionView?.updateSelectedColor()
        } else {
            self.collectionView?.updateSelectedColor()
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
}

extension FTNewTextStyleViewController {
    
    @objc func changeText(_ notification: Notification) {
        self.delegate?.didSelectTextRange(range: selectedRange, txtRange: selectedTextRange, canEdit: false)
        
        guard let txtField = notification.object as? UITextField else { return }
        if txtField == txtFontSize {
            if let value = Int(txtField.text ?? "\(defaultFontSize)") {
                self.textFontStyle.fontSize = value
            }
        }
        if txtField == txtStyleName {
            if let value = txtField.text {
                self.textFontStyle.displayName = value
            }
        }
        self.applyFontChanges()
        if self.textStyleMode == .defaultView {
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
        textFontStyle.fontSize = Int(value)
        txtFontSize?.text = "\(value)"
        if self.textStyleMode == .defaultView {
            shouldApplyAttributes = true
        }
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
        self.currentAlignment = align
        self.delegate?.didTapOnAlignmentStyle(align)
        highLightBackgroundForTextAlignmentButtons(alignment: align)
    }

    private func handleLineSpaceChange(value: Int){
        lblLineSpace?.text = "\(value) pt"
        self.currentLineSpace = value
        self.delegate?.didChangeLineSpacing(lineSpace: CGFloat(value))
    }
    
    @IBAction func tappedOnAutoLineHeightSwitch(_ sender: UISwitch) {
        let isOn = sender.isOn
        self.isAutoLineSpaceEnabled = isOn
        if isOn {
            self.currentLineSpace = 0
        }
        self.delegate?.didAutoLineSpaceStatusChanged(isOn)
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
            textFontStyle.fontFamily = font.familyName
            textFontStyle.fontName = font.fontName
            textFontStyle.fontSize = Int(round(fontPointSize))
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

        if let paragrapghStyle = attributes[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle {
            let lineSpace = (Int)(round(paragrapghStyle.lineSpacing/scale))
            lineSpaceStepper?.updateInitialValue(lineSpace)
            self.currentLineSpace = lineSpace
            lblLineSpace?.text = "\(lineSpace) pt"
           let alignment = paragrapghStyle.alignment
            highLightBackgroundForTextAlignmentButtons(alignment: alignment)
            self.currentAlignment = alignment
        }

        let isLineSpaceAttrKey = NSAttributedString.Key(rawValue: FTFontStorage.isLineSpaceEnabledKey)
        if let isLineSpaceEnabled = attributes[isLineSpaceAttrKey] as? Int {
            self.isAutoLineSpaceEnabled = (isLineSpaceEnabled == 1)
        }
        self.fontSizeStepper?.updateInitialValue(textFontStyle.fontSize)
        self.updateFontTraitsEnableStatus()
        self.reloadColorsCollectionIfRequired()

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
