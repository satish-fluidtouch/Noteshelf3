//
//  FTThemeableImageView.swift
//  Noteshelf
//
//  Created by Siva on 10/11/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTThemeableImageView: UIImageView {
    @IBInspectable var normalImageName: String?
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        
        self.registerForThemeUpdateNotification();
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        
        self.registerForThemeUpdateNotification();
    }
    
    override func awakeFromNib() {
        super.awakeFromNib();
        
        self.updateUI();
    }
    
    private func registerForThemeUpdateNotification() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.FTShelfThemeDidChange, object: nil, queue: nil) { [weak self] (_) in
            runInMainThread { 
                self?.updateUI();
            }
        }
    }
    
    private func updateUI() {
        let theme = FTShelfThemeStyle.defaultTheme();
        if let normalImageName = self.normalImageName {
            self.image = UIImage(named: normalImageName + theme.imageNameSuffix);
        }
    }
}
