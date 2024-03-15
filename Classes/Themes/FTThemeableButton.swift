//
//  FTThemeableButton.swift
//  Noteshelf
//
//  Created by Siva on 09/11/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

@objc class FTThemeableButton: FTBaseButton {
    @IBInspectable var normalImageName: String?
    @IBInspectable var selectedImageName: String?
    @IBInspectable var supportsTint: Bool = false
    
    private weak var themeChangeObserver: NSObjectProtocol?;
    
    override func awakeFromNib() {
        super.awakeFromNib();
        self.updateUI();
        self.themeChangeObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.FTShelfThemeDidChange, object: nil, queue: nil) { [weak self] (_) in
            runInMainThread {
                self?.updateUI();
            }
        }
    }
    
    deinit {
        if let observer = self.themeChangeObserver {
            NotificationCenter.default.removeObserver(observer);
        }
    }

    private func updateUI() {
        #if !targetEnvironment(macCatalyst)
        let theme = FTShelfThemeStyle.defaultTheme();
        
        if let normalImageName = self.normalImageName, normalImageName != "" {
            self.setImage(UIImage(named: normalImageName + theme.imageNameSuffix), for: .normal);
        }
        if let selectedImageName = self.selectedImageName, selectedImageName != "" {
            self.setImage(UIImage(named: selectedImageName + theme.imageNameSuffix), for: .selected);
        }
        self.setTitleColor(theme.tintColor, for: .normal);
        if supportsTint {
            self.tintColor = theme.tintColor
        }
        #endif
    }
}
