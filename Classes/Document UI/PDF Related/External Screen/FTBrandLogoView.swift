//
//  FTBrandLogoView.swift
//  Noteshelf
//
//  Created by Siva on 28/09/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTBrandLogoView: UIView {
    @IBOutlet weak var titleLabel: FTStyledLabel!
    @IBOutlet weak var whiteboardModeLabel: FTStyledLabel!
    
    override func awakeFromNib() {
        super.awakeFromNib();
        
        self.titleLabel.style = FTLabelStyle.style16.rawValue;
        self.titleLabel.styleText = "NOTESHELF";

        self.whiteboardModeLabel.style = FTLabelStyle.style17.rawValue;
        self.whiteboardModeLabel.styleText = NSLocalizedString("WHITEBOARDMODE", comment: "WHITEBOARD MODE");
    }
}
