//
//  FTGradientView.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 15/04/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTGradientView: UIView {
    @IBInspectable var gradientColors: [UIColor] = [UIColor.appColor(.welcometopGradiantColor)
                                                    , UIColor.appColor(.welcomeBottonGradiantColor)]
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        // Create a CGContext
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Create a gradient with the colors array
        let gradient = CGGradient(colorsSpace: nil, colors: gradientColors.map { $0.cgColor } as CFArray, locations: nil)
        
        // Draw the gradient
        context.drawLinearGradient(gradient!,
                                    start: CGPoint(x: 0, y: 0),
                                    end: CGPoint(x: bounds.width, y: bounds.height),
                                    options: [])
    }
}
