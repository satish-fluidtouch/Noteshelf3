//
//  FTExportSettingsButton.swift
//  Noteshelf
//
//  Created by Siva on 6/12/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTExportSettingsButton: UIButton {
    override var isEnabled: Bool {
        didSet {
            if isEnabled {
                self.backgroundColor = UIColor.clear;
            }
            else {
                self.backgroundColor = UIColor(red: 255.0, green: 85 / 255.0, blue: 67/255.0, alpha: 1.0);
            }
        }
    }
}
