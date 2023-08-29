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
        guard let style = textFontStyle else { return false }
        let testFont = UIFont.init(name: style.fontName, size: CGFloat(style.fontSize))
        return testFont!.canAddTrait(trait)
    }
}

extension FTNewTextStyleViewController : FTSystemFontPickerDelegate, UIFontPickerViewControllerDelegate {
    
    func didPickFontFromSystemFontPicker(_ viewController : FTFontPickerViewController?, selectedFontDescriptor: UIFontDescriptor) {
        if let fontFamily = selectedFontDescriptor.object(forKey: .family) as? String, let displayName = selectedFontDescriptor.object(forKey: .visibleName) as? String {
            if let _ = selectedFontDescriptor.object(forKey: .face) as? String, let fontName = selectedFontDescriptor.object(forKey: .name) as? String {
                self.textFontStyle?.fontName = fontName
                self.textFontStyle?.fontFamily = fontFamily
            } else {
                self.textFontStyle?.fontFamily = displayName
                self.textFontStyle?.fontName = fontFamily
            }
        }
        self.shouldApplyAttributes = true
        self.updateFontTraitsEnableStatus()
        applyFontChanges()
    }
}

extension FTNewTextStyleViewController: FTTextColorCollectionViewDelegate {
    func didSelectTextColor(_ colorStr: String) {
        self.textFontStyle?.textColor = colorStr
        if isModifyText {
            shouldApplyAttributes = true
        }
        applyFontChanges()
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
                    if size > maxFontSize {
                        canAllow = false
                    }
                }
            }
            return canAllow
        }
        return true
    }
}
