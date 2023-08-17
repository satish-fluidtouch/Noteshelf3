//
//  FTThemeableLabel.swift
//  Noteshelf
//
//  Created by Siva on 09/11/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTThemeableLabel: FTStyledLabel {
    override func awakeFromNib() {
        super.awakeFromNib();
        
        self.updateUI();
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.FTShelfThemeDidChange, object: nil, queue: nil) { [weak self] (_) in
            runInMainThread {
                self?.updateUI();
            }
        }
    }
    
    private func updateUI() {
        let theme = FTShelfThemeStyle.defaultTheme();
        self.textColor = theme.tintColor;
        self.styleText = self.attributedText?.string;
    }
}
