//
//  FTContinuousLineView.swift
//  Noteshelf
//
//  Created by Siva on 25/04/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTContinuousLineView: UIView {
    
    override func draw(_ rect: CGRect) {
        let lineDrawHelper = FTSeparatorLineDrawHelper();
        lineDrawHelper.drawLine(onView: self, lineStyle: FTSeparatorStyle.bottomLeftToBottomRight, lineWidth: 0.25, offset: 0, color: UIColor.separator);
    }

}

class FTContinuousVerticalLineView: UIView {
    
    override func draw(_ rect: CGRect) {
        let lineDrawHelper = FTSeparatorLineDrawHelper();
        lineDrawHelper.drawLine(onView: self, lineStyle: FTSeparatorStyle.topRightToBottomRight, lineWidth: 0.25, offset: 0, color: UIColor.separator);
    }
    
}
