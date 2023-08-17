//
//  FTThemeableSeparatorView.swift
//  Noteshelf
//
//  Created by Siva on 10/11/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTThemeableSeparatorView: UIView {
    override func awakeFromNib() {
        super.awakeFromNib();
        
        self.backgroundColor = FTShelfThemeStyle.defaultTheme().separatorColor;
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.FTShelfThemeDidChange, object: nil, queue: nil) { [weak self] (_) in
            runInMainThread {
                self?.backgroundColor = FTShelfThemeStyle.defaultTheme().separatorColor;
            }
        }
    }
}
