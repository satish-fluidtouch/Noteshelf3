//
//  FTAudioPlayerContentView.swift
//  Noteshelf3
//
//  Created by Sameer on 29/12/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTAudioPlayerContentView: UIView {
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let bgColor = UIColor(hexString: "E5E5E5").withAlphaComponent(0.6)
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        context.saveGState()
        context.setBlendMode(.luminosity)
        bgColor.setFill()
        let viewPath = UIBezierPath(roundedRect: rect, cornerRadius: 12.0)
        viewPath.fill()
        context.restoreGState()
        self.removeVisualEffectBlur()
        self.addVisualEffectBlur(style: .regular, cornerRadius: 12.0)
    }
}
