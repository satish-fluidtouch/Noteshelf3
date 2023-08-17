//
//  FTSettingsLabel.swift
//  Noteshelf
//
//  Created by Matra on 13/02/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

@objc
enum FTSettingFontStyle: Int {
    case leftHeader = 0
    case leftOption
    case rightOption
    case details
    case regularTitle
    case smallDetail
    case sectionHeader
    case popoverHeader
}

class FTSettingsLabel: UILabel {

    @IBInspectable var localizationKey: String?
    @IBInspectable var localizationTable: String?

    @IBInspectable var fontStyle: Int = 0 {
        didSet {
            self.font = self.getFontStyle()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        if let localizationKey = self.localizationKey {
            var title = NSLocalizedString(localizationKey, comment: self.text ?? "");
            if let table = self.localizationTable,!table.isEmpty {
                title =  NSLocalizedString(localizationKey,
                                           tableName: table,
                                           bundle: Bundle.main,
                                           value: "",
                                           comment:self.text ?? "")
            }
            self.text = title;
            self.addCharacterSpacing(kernValue: -0.41)
        }
        self.font = getFontStyle()
    }

    fileprivate func getFontStyle() -> UIFont {
        let fontType = FTSettingFontStyle(rawValue: self.fontStyle)
        guard fontType != nil else {
            return UIFont.appFont(for: .regular, with: 17)
        }
        switch fontType! {
        case .leftHeader:
            if isRegularClass() {
                return UIFont.appFont(for: .bold, with: 34)
            } else {
                return UIFont.appFont(for: .heavy, with: 28)
            }
        case .leftOption:
            return UIFont.appFont(for: .regular, with: 17)
        case .rightOption:
            return UIFont.appFont(for: .regular, with: 16)
        case .details:
            return UIFont.appFont(for: .regular, with: 13)
        case .regularTitle:
            return UIFont.appFont(for: .regular, with: 22)
        case .smallDetail:
            return UIFont.appFont(for: .medium, with: 12)
        case .sectionHeader:
            return UIFont.appFont(for: .semibold, with: 11)
        case .popoverHeader:
            if isRegularClass() {
                return UIFont.appFont(for: .semibold, with: 19)
            } else {
                return UIFont.appFont(for: .semibold, with: 17)
            }
        default:
            return UIFont.appFont(for: .regular, with: 17)
        }
    }
}
