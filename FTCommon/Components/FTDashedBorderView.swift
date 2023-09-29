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

    private let blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .regular)
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
        let visualEffectView = UIVisualEffectView(effect: vibrancyEffect)
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        return visualEffectView
    }()

    public override func layoutSubviews() {
        super.layoutSubviews()
        blurView.frame = self.bounds
    }

    public override func draw(_ rect: CGRect) {
        super.draw(rect)

        if !self.subviews.contains(blurView) {
            self.insertSubview(blurView, at: 0)
        }

        if let context = UIGraphicsGetCurrentContext() {
            if isDottedBorderEnabled {
                let borderWidth: CGFloat = 0.5
                let borderRect = CGRect(x: borderWidth / 2, y: borderWidth / 2, width: rect.width - borderWidth, height: rect.height - borderWidth)
                let borderPath = UIBezierPath(roundedRect: borderRect, cornerRadius: 100.0)
                context.setLineWidth(borderWidth)
                context.setLineDash(phase: 0, lengths: [4, 4])
                context.setStrokeColor(UIColor.appColor(.black10).cgColor)
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
