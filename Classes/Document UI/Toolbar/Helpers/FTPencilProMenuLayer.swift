//
//  FTPencilProMenuLAyer.swift
//  Noteshelf3
//
//  Created by Narayana on 29/05/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

protocol FTMenuLayerPathConfig: AnyObject {
    func createPath(with center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat)
}

class FTPencilProLayer: CAShapeLayer, FTMenuLayerPathConfig {
    init(strokeColor: UIColor, lineWidth: CGFloat) {
        super.init()
        self.strokeColor = strokeColor.cgColor
        self.fillColor = UIColor.clear.cgColor
        self.lineWidth = lineWidth
        self.lineCap = .round
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createPath(with center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat) {
        let path = UIBezierPath()
        path.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        self.path = path.cgPath
    }
}

class FTPencilProMenuLayer: FTPencilProLayer {
    override init(strokeColor: UIColor, lineWidth: CGFloat) {
        super.init(strokeColor: .red, lineWidth: 50.0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class FTPencilProBorderLayer: FTPencilProLayer {
    override init(strokeColor: UIColor, lineWidth: CGFloat) {
        super.init(strokeColor: .green, lineWidth: 52.0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
