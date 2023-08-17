//
//  FTWatchButton.swift
//  Noteshelf
//
//  Created by Amar on 11/04/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTWatchButton: FTThemeableButton
{
    override func awakeFromNib() {
        super.awakeFromNib();
    }
    
    deinit {
        #if DEBUG
        debugPrint("dinit \(self.classForCoder)");
        #endif
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
    }
    
    required init(frame: CGRect) {
        super.init(frame: frame)
        FTBaseButton.applyPointInteraction(to: self)
    }

    override func layoutSubviews() {
        super.layoutSubviews();
    }
    
    fileprivate func updateUI() {
        
    }
    
    func setSelected(_ selected : Bool,animate : Bool = false) {
        if(animate) {
            UIView.transition(with: self, duration: 0.2, options: UIView.AnimationOptions.transitionCrossDissolve, animations: {
                self.isSelected = selected;
            }, completion: nil)
        }
        else {
            self.isSelected = selected;
        }
    }
    
    private func updateProviderIfNeeded()
    {
        
    }
}
