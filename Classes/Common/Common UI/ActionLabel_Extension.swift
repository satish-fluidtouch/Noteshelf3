//
//  ActionLabel_Extension.swift
//  Noteshelf
//
//  Created by Siva on 09/11/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit
import FTCommon

class ActionLabel: UILabel {}

extension ActionLabel {
    override open func awakeFromNib() {
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
    }
}
