//
//  FTShelfCollectionReusableView.swift
//  Noteshelf
//
//  Created by Paramasivan on 18/10/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTShelfCollectionReusableView: UICollectionReusableView {
    
    static func kind() -> String {
        return "FTShelfCollectionReusableViewKind"
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        NotificationCenter.default.addObserver(self, selector: #selector(self.themeDidChanged), name: NSNotification.Name.FTShelfThemeDidChange, object: nil);
        themeDidChanged()
    }
    
    @objc func themeDidChanged() {
        if let color = FTShelfThemeStyle.defaultTheme().shelfThemeColor {
            backgroundColor = color.withAlphaComponent(1.0)
        } else {
            backgroundColor = UIColor.appColor(.secondaryBG)
        }
    }
}
