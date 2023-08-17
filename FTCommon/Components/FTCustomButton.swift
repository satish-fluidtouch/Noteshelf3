//
//  FTCustomButton.swift
//  Noteshelf3
//
//  Created by Sameer on 22/08/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

public class FTCustomButton: UIButton {
    //Set the custom style in story board to set the custom font
//    @IBInspectable var style: Int = 0;
    @IBInspectable var localizationKey: String?

    public override func awakeFromNib() {
        super.awakeFromNib()
        var title = ""
        if let localizationKey = self.localizationKey {
            title = NSLocalizedString(localizationKey, comment: self.title(for: .normal) ?? "")
        } else {
            title = self.title(for: .normal)?.localized ?? ""
        }

        var config = self.configuration
        config?.title = title
        self.configuration = config
        setUpFont()
        NotificationCenter.default.addObserver(self, selector: #selector(preferredContentSizeChanged(_:)), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }
    
    private func setUpFont() {
        self.titleLabel?.adjustsFontForContentSizeCategory = true
        if  let font = self.titleLabel?.font {
            let style = UIFont.textStyle(for: font.pointSize)
            let scaledFont = UIFont.scaledFont(for: font, with: style)
            self.titleLabel?.font = scaledFont
        }
    }
    
    @objc func preferredContentSizeChanged(_ notification: Notification) {
//        setStyle()
    }
}
