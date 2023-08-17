//
//  FTFooterView.swift
//  Noteshelf
//
//  Created by Narayana on 22/10/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTFooterButton: FTStaticTextButton {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = UIColor.blueDodger
        self.titleLabel?.textColor = UIColor.white
        self.titleLabel?.textAlignment = NSTextAlignment.center
        self.layer.cornerRadius = 8.0
    }
    
}
