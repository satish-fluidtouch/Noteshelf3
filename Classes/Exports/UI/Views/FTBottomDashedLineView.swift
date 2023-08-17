//
//  FTBottomDashedLineView.swift
//  Noteshelf
//
//  Created by Siva on 19/04/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTBottomDashedLineView: UIView {
    @IBInspectable var lineColor:UIColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.12)
    @IBInspectable var offset:CGFloat = 0.0
    
    override func draw(_ rect: CGRect) {
        let lineDrawHelper = FTSeparatorLineDrawHelper();
        lineDrawHelper.drawDashedLine(onView: self, lineStyle: FTSeparatorStyle.bottomLeftToBottomRight, offset: offset, color: lineColor);
    }
}
