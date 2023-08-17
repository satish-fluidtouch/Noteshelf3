//
//  FTWhatsNewButton.swift
//  Noteshelf
//
//  Created by Siva on 14/11/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTWhatsNewButton: FTBaseButton {

    override func awakeFromNib() {
        super.awakeFromNib();

        self.layer.shadowOpacity = 0.1;
        self.layer.shadowRadius = 20;
        self.layer.shadowColor = UIColor.black.cgColor;
        self.layer.shadowOffset = CGSize(width: 0, height: 4);

        self.layer.cornerRadius = self.bounds.height / 2
    }
    func applyReviewBorderStyle() {
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor(hexString: "383838").cgColor
        self.titleLabel?.textColor = UIColor(hexString: "383838")
    }
}
