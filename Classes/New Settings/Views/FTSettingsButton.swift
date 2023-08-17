//
//  FTSettingsButton.swift
//  Noteshelf
//
//  Created by Matra on 13/02/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

enum FTSettingsButtonStyle: Int {
    case bigButton
    case smallButton
}

class FTSettingsButton: FTBaseButton {

    @IBInspectable var localizationKey: String?
    @IBInspectable var localizationTable: String?
    @IBInspectable var fontStyle: Int = 0 {
        didSet {
            self.titleLabel?.font = getFontStyle()
        }
    }
    @IBInspectable var rounderCorner: CGFloat = 0;
    @IBInspectable var borderWidth: CGFloat = 0;
    @IBInspectable var borderColor: UIColor = UIColor.clear;

    override func awakeFromNib() {
        super.awakeFromNib()
        if let localizationKey = self.localizationKey {
            var title = NSLocalizedString(localizationKey, comment: localizationKey);
            if let table = self.localizationTable,!table.isEmpty {
                title =  NSLocalizedString(localizationKey,
                                           tableName: table,
                                           bundle: Bundle.main,
                                           value: "",
                                           comment: localizationKey)
            }
            self.setTitle(title, for: .normal)
        }
        if(self.rounderCorner > 0) {
            self.layer.cornerRadius = self.rounderCorner
            self.layer.borderWidth = self.borderWidth
            self.layer.borderColor = self.borderColor.cgColor
        }
    }

    fileprivate func getFontStyle() -> UIFont {
        let fontType = FTSettingsButtonStyle(rawValue: self.fontStyle)
        guard fontType != nil else {
            return UIFont.appFont(for: .medium, with: 17)
        }

        switch fontType! {
        case .bigButton:
            if isRegularClass() {
                return UIFont.appFont(for: .medium, with: 16)
            } else {
                return UIFont.appFont(for: .medium, with: 15)
            }
        default:
            return UIFont.appFont(for: .medium, with: 17)
        }
    }
}
