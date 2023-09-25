//
//  FTDashedBorderView.swift
//  FTCommon
//
//  Created by Narayana on 25/09/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

public class FTDashedBorderView: UIView {
    public var isDottedBorderEnabled: Bool = true {
        didSet {
            self.setNeedsDisplay()
        }
    }

    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        let borderColor: UIColor = UIColor.appColor(.black10)
        let borderWidth: CGFloat = 0.5
        let dashPattern: [CGFloat] = [4, 4]

        if let context = UIGraphicsGetCurrentContext() {
            if isDottedBorderEnabled {
                let borderRect = CGRect(x: borderWidth / 2, y: borderWidth / 2, width: rect.width - borderWidth, height: rect.height - borderWidth)
                let borderPath = UIBezierPath(roundedRect: borderRect, cornerRadius: 10.0)
                context.setLineWidth(borderWidth)
                context.setLineDash(phase: 0, lengths: dashPattern)
                context.setStrokeColor(borderColor.cgColor)
                context.addPath(borderPath.cgPath)
                context.strokePath()
            } else {
                context.setLineWidth(0.0)
                context.setLineDash(phase: 0, lengths: [0, 0])
                context.setStrokeColor(UIColor.clear.cgColor)
            }
        }
    }
}
