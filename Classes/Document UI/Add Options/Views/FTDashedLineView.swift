//
//  FTDashedLineView.swift
//  Noteshelf
//
//  Created by Siva on 25/04/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTDashedLineView: UIView {
    
    @IBInspectable var isLight = false;
    
    override var bounds: CGRect {
        didSet {
            self.setNeedsDisplay();
        }
    }
    
    override func draw(_ rect: CGRect) {
        let color: UIColor;
        if isLight {
            color = UIColor.appColor(.black5);
        }
        else {
            color = UIColor.appColor(.black5);
        }
        
        let lineDrawHelper = FTSeparatorLineDrawHelper();
        lineDrawHelper.drawDashedLine(onView: self, lineStyle: FTSeparatorStyle.bottomLeftToBottomRight, offset: 0, color: color);
    }
}
