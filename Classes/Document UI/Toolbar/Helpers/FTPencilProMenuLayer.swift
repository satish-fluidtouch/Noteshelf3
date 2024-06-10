//
//  FTPencilProMenuLAyer.swift
//  Noteshelf3
//
//  Created by Narayana on 29/05/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

protocol FTMenuLayerPathConfig: AnyObject {
    func setPath(with center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat)
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
    
    func setPath(with center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat) {
        let path = UIBezierPath()
        path.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        self.path = path.cgPath
    }
}

class FTPencilProMenuLayer: FTPencilProLayer {
    override init(strokeColor: UIColor = .red, lineWidth: CGFloat = 40.0) {
        super.init(strokeColor: strokeColor, lineWidth: lineWidth)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class FTPencilProBorderLayer: FTPencilProLayer {
    override init(strokeColor: UIColor = .green, lineWidth: CGFloat = 42.0) {
        super.init(strokeColor: strokeColor, lineWidth: lineWidth)
        self.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        self.shadowOpacity = 0.5
        self.shadowOffset = CGSize(width: 0, height: 2)
        self.shadowRadius = 4.0
        self.masksToBounds = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
