//
//  FTHeaderView.swift
//  Noteshelf
//
//  Created by Akshay on 14/02/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTStaticTextLabel: UILabel {
    @IBInspectable var localizationKey: String?
    override func awakeFromNib() {
        super.awakeFromNib()
        if let localizationKey = self.localizationKey {
            self.text = NSLocalizedString(localizationKey, comment: self.text ?? "")
            self.addCharacterSpacing(kernValue: -0.4)
        }
    }
}

class FTStaticTextButton: FTBaseButton {
    @IBInspectable var localizationKey: String?
    @IBInspectable var rounderCorner: CGFloat = 0;
    @IBInspectable var borderWidth: CGFloat = 0;
    @IBInspectable var borderColor: UIColor = UIColor.headerColor;
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if let localizationKey = self.localizationKey {
            self.setTitle(NSLocalizedString(localizationKey, comment: ""), for: .normal)
        }
        
        if(self.rounderCorner>0){
            self.layer.cornerRadius = self.rounderCorner
            self.layer.borderWidth = self.borderWidth
            self.layer.borderColor = self.borderColor.cgColor
        }

    }
}

class FTHeaderView: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}

class FTRounderCornerView: UIView {
    @IBInspectable var rounderCorner: CGFloat = 0;
    @IBInspectable var borderWidth: CGFloat = 0;
    @IBInspectable var borderColor: UIColor = UIColor.appColor(.black10);

    override func awakeFromNib() {
        super.awakeFromNib()
        self.clipsToBounds = true
        self.layer.cornerRadius = self.rounderCorner
        self.layer.borderWidth = self.borderWidth
        self.layer.borderColor = self.borderColor.cgColor
    }
}
