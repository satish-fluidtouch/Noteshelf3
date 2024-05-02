//
//  FTNewTextStyleViewController_Extension.swift
//  Noteshelf
//
//  Created by Mahesh on 01/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension FTNewTextStyleViewController  {
    func canAddTrait(_ trait : UIFontDescriptor.SymbolicTraits) -> Bool {
        guard let testFont = UIFont.init(name: self.textFontStyle.fontName, size: CGFloat(self.textFontStyle.fontSize)) else {
            return false
        }
        return testFont.canAddTrait(trait)
    }
}

extension FTNewTextStyleViewController : FTSystemFontPickerDelegate, UIFontPickerViewControllerDelegate {
    
    func didPickFontFromSystemFontPicker(_ viewController : FTFontPickerViewController?, selectedFontDescriptor: UIFontDescriptor, fontStyle: FTTextStyleItem) {
        self.textFontStyle = fontStyle
        self.shouldApplyAttributes = true
        self.updateFontTraitsEnableStatus()
        applyFontChanges()
    }
}

extension FTNewTextStyleViewController: FTTextColorCollectionViewDelegate {
    func didSelectTextColor(_ colorStr: String) {
        self.textFontStyle.textColor = colorStr
        if self.textStyleMode == .defaultView {
            shouldApplyAttributes = true
        }
        applyFontChanges()
        self.reloadColorsCollectionIfRequired()
    }
}

extension FTNewTextStyleViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == txtFontSize {
            let allowedCharacters = CharacterSet.decimalDigits
            let characterSet = CharacterSet(charactersIn: string)
            var canAllow = allowedCharacters.isSuperset(of: characterSet)
            if canAllow {
                if let text = textField.text, let textRange = Range(range, in: text) {
                    let updatedText = text.replacingCharacters(in: textRange,
                                                               with: string)
                    let size = Int(updatedText) ?? defaultFontSize
                    if size > Int(StepperValueCapturedIn.fontsize.maxSupportValue) {
                        canAllow = false
                    }
                }
            }
            return canAllow
        }
        return true
    }
}
