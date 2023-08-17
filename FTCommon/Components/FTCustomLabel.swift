//
//  FTCustomLabel.swift
//  Noteshelf3
//
//  Created by Sameer on 22/08/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

public class FTCustomLabel: UILabel {
    //Set the custom style in story board to set the custom font
//    @IBInspectable var style: Int = 0;
    @IBInspectable var localizationKey: String?

    public override func awakeFromNib() {
        super.awakeFromNib()
        //setStyle()
        if let localizationKey = self.localizationKey {
            text =  NSLocalizedString(localizationKey, comment: self.text ?? "")
        } else {
            text = text?.localized
        }
        self.adjustsFontForContentSizeCategory = true
        setUpFont()
        NotificationCenter.default.addObserver(self, selector: #selector(preferredContentSizeChanged(_:)), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }
    
    private func setUpFont() {
        if  let font = self.font {
            let style = UIFont.textStyle(for: font.pointSize)
            let scaledFont = UIFont.scaledFont(for: font, with: style)
            self.font = scaledFont
        }
    }
    
    @objc func preferredContentSizeChanged(_ notification: Notification) {
//        setStyle()
    }
}
