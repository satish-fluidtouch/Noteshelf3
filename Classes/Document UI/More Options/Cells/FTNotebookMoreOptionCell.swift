//
//  FTNotebookMoreOptionsCell.swift
//  Noteshelf
//
//  Created by Akshay on 08/02/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTNotebookMoreOptionsCell: UITableViewCell {

    @IBOutlet weak var cellSeperatorView: UIView?
    @IBOutlet fileprivate var lblCenterYConstraint: NSLayoutConstraint?
    @IBOutlet fileprivate var imgViewIcon: UIImageView?
    @IBOutlet fileprivate var lblText: UILabel?
    @IBOutlet fileprivate var lblDetails: UILabel?
    @IBOutlet fileprivate var lblSelectedValue: UILabel?
    @IBOutlet fileprivate(set) var scrollingValueLbl: UILabel?
    @IBOutlet fileprivate(set) var siriSubLbl: UILabel?

    @IBOutlet weak var onboardingDotView: UIView?
    var toggleTapped: ((_ currentValue: Bool, _ setting: FTNotebookMoreOption) -> Void)?

    fileprivate var setting: FTNotebookMoreOption?

    var isEnabled: Bool = true {
        didSet {
            if self.isEnabled {                
                let enableAlpha: CGFloat = 1.0
                self.lblText?.alpha = enableAlpha
                self.lblDetails?.alpha = enableAlpha
                self.lblSelectedValue?.alpha = enableAlpha
                self.imgViewIcon?.alpha = enableAlpha
            }
            else {
                let disableAlpha: CGFloat = 0.7
                self.lblText?.alpha = disableAlpha
                self.lblDetails?.alpha = disableAlpha
                self.lblSelectedValue?.alpha = disableAlpha
                self.imgViewIcon?.alpha = disableAlpha
            }
        }
    }
    
    override var canBecomeFocused: Bool {
        return false
    }
    
    var shoudlHighlightDotView: Bool = false {
        didSet {
            if let onboardingDotView = self.onboardingDotView {
                onboardingDotView.layer.cornerRadius = onboardingDotView.bounds.width/2
                onboardingDotView.isHidden = !self.shoudlHighlightDotView
            }
        }
    }

    override func awakeFromNib() {
        self.applySelectionStyleGray();
        super.awakeFromNib()
        self.layoutIfNeeded();
        imgViewIcon?.tintColor = .appColor(.accent)
    }
    
    func setValueForScrollDirection() {
        let value = UserDefaults.standard.pageLayoutType.localizedTitle
        scrollingValueLbl?.text = value
    }

    func applySelectionStyleGray() {
        let backgroundView = UIView();
        backgroundView.backgroundColor = UIColor.appColor(.black5)
        self.selectedBackgroundView = backgroundView;
    }

    func configure(with setting: FTNotebookMoreOption) {
        self.setting = setting
        self.lblSelectedValue?.isHidden = true
        lblText?.text = setting.localizedTitle
        lblText?.addCharacterSpacing(kernValue: -0.32)
        lblDetails?.text = setting.localizedSubtitle
        let image = UIImage(icon: setting.imageIcon)
        imgViewIcon?.image = image
        if let toggleSetting = setting as? FTNotebookOptionToggle, setting.type == .toggleAccessory {
            self.accessoryType = .none
            let toggleSwitch = UISwitch(frame: CGRect.zero)
            toggleSwitch.isOn = toggleSetting.isToggleTurnedOn
            self.accessoryView = toggleSwitch
            toggleSwitch.addTarget(self, action: #selector(switchvalueChanged(_:)), for: .valueChanged)
        } else if setting.type == .disclosure {
            self.accessoryType = .disclosureIndicator
            self.accessoryView = nil
        } else {
            self.accessoryType = .none
            self.accessoryView = nil
        }
        if setting is FTNotebookOptionGoToPage {
            let titleLabel = UILabel()
            titleLabel.text = setting.localizedSubtitle
            titleLabel.font = UIFont.appFont(for: .regular, with: 17)
            titleLabel.textColor = UIColor.appColor(.black50)
            titleLabel.sizeToFit()
            self.accessoryView = titleLabel
        }
        self.contentView.alpha = setting.isDisabled ? 0.5 : 1
        self.isUserInteractionEnabled = setting.isDisabled ? false : true
    }
        
    @objc
    fileprivate func switchvalueChanged(_ sender: UISwitch) {
        guard let currentSetting = self.setting as? FTNotebookOptionToggle else { return }
        toggleTapped?(currentSetting.isToggleTurnedOn, currentSetting)
    }

    fileprivate func enableSubviews(_ status: Bool, forView view: UIView) {
        for eachView in view.subviews {
            if let control = eachView as? UIControl {
                control.isEnabled = status
            } else if let label = eachView as? FTStyledLabel {
                label.isEnabled = status
            } else {
                self.enableSubviews(status, forView: eachView);
            }
        }
    }
}

class FTNotebookMetadataCell: UITableViewCell {

    @IBOutlet weak var cellSeperatorView: UIView!
    @IBOutlet private var lblTitle: UILabel?
    @IBOutlet private var lblSubTitle: UILabel?

    func configure(info: FTNotebookInfoProperty) {
        self.lblTitle?.text = info.title
        self.lblTitle?.addCharacterSpacing(kernValue: -0.32)
        if info is FTNotebookInfoPageNumber || info is FTNotebookInfoCategory  {
            self.lblSubTitle?.textColor = UIColor.appColor(.accent)
        }
        self.lblSubTitle?.text = info.description
        self.lblSubTitle?.addCharacterSpacing(kernValue: -0.41)
    }
}

protocol FTNotebookTitleDelegate: AnyObject {
    func renameShelfItem(title: String, onCompletion: @escaping (Bool) -> ())
    func handleGoToPage(pageNumber: Int)
    func numberOfPages() -> Int
}

class FTNotebookTitleCell: UITableViewCell {

    @IBOutlet weak var cellSeperatorView: UIView!
    @IBOutlet private var lblTitle: UILabel?
    @IBOutlet private var textField: UITextField?
    weak var delegate: FTNotebookTitleDelegate?
    
    func configure(info: FTNotebookInfoProperty) {
        self.textField?.layer.borderWidth = 0.0
        self.textField?.layer.borderColor = UIColor.clear.cgColor
        self.textField?.borderStyle = .none
        self.textField?.textAlignment = .right
        self.textField?.textColor = UIColor.appColor(.black50)
        textField?.keyboardType = .phonePad
        self.lblTitle?.text = info.title
        self.lblTitle?.addCharacterSpacing(kernValue: -0.32)
        #if targetEnvironment(macCatalyst)
        self.textField?.isUserInteractionEnabled = false
        #endif
        self.textField?.placeholder = info.description
    }
}

extension FTNotebookTitleCell: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.autocapitalizationType = UITextAutocapitalizationType.words
        textField.borderStyle = .roundedRect
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.appColor(.black10).cgColor
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.handleEndEdit(textField: textField)
        FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.nbk_more_getinfo_gotopage_tap)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let aSet = CharacterSet(charactersIn:"0123456789").inverted
        let compSepByCharInSet = string.components(separatedBy: aSet)
        let numberFiltered = compSepByCharInSet.joined()
        let pages = self.delegate?.numberOfPages() ?? 0
        var isValid = (string == numberFiltered)
        if isValid, !string.isEmpty, let numberText = textField.text {
            guard let textRange = Range(range, in: numberText) else { return false }
            let numberText = textField.text?.replacingCharacters(in: textRange, with: string)
            if let pageNumber = (numberText as NSString?)?.integerValue, (pageNumber < 1 || pageNumber > pages) {
                isValid = false
            }
        }
        return isValid
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.handleEndEdit(textField: textField)
        return true
    }
    
    private func handleEndEdit(textField: UITextField) {
        textField.layer.borderWidth = 0.0
        textField.layer.borderColor = UIColor.clear.cgColor
        textField.borderStyle = .none
        textField.textAlignment = .right
        if let pageNumber = (textField.text as? NSString)?.integerValue {
            self.delegate?.handleGoToPage(pageNumber: pageNumber)
        }
    }
}
