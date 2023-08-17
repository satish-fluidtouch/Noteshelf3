//
//  ParalleloGramView.swift
//  ImageScanner
//
//  Created by Prabhu on 7/28/17.
//  Copyright © 2017 FluidTouch. All rights reserved.
//

import UIKit

class ParalleloGramView: UIView {
    var topLeft:CGPoint?
    var topRight:CGPoint?
    var bottomLeft:CGPoint?
    var bottomRight:CGPoint?
    
    let overlayLayer:CAShapeLayer!=CAShapeLayer.init()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.overlayLayer.fillColor=UIColor.init(red: 14/255, green: 205/255, blue: 235/255, alpha: 1).cgColor
        self.layer.addSublayer(self.overlayLayer)
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    func refreshScannedRectangle()
    {
        if let _ = topLeft,let _ = topRight , let _ = bottomLeft , let _ = bottomRight
        {
            let bezier = UIBezierPath.init()
            self.overlayLayer.borderWidth=5.0;
            self.overlayLayer.borderColor=UIColor.init(red: 1, green: 0, blue: 0, alpha: 1).cgColor
            bezier.move(to: topLeft!)
            bezier.addLine(to: topRight!)
            bezier.addLine(to: bottomRight!)
            bezier.addLine(to: bottomLeft!)
            bezier.addLine(to: topLeft!)
            
            let animation = CABasicAnimation(keyPath: "path")
            animation.duration = 1.0
            animation.fromValue = self.overlayLayer.path
            animation.toValue = bezier.cgPath
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            self.overlayLayer.add(animation, forKey: "path")
            self.overlayLayer.path=bezier.cgPath
        }
    }

//    override func draw(_ rect: CGRect) {
//        super.draw(rect)
    
//        if let context = UIGraphicsGetCurrentContext(),let _ = topLeft,let _ = topRight , let _ = bottomLeft , let _ = bottomRight {
//            context.clear(rect)
//            //            context.setStrokeColor(red: 0, green: 0, blue: 1, alpha: 1)
//            context.setFillColor(UIColor.init(red: 14/255, green: 205/255, blue: 235/255, alpha: 1).cgColor)
//            context.setLineWidth(5)
//            context.move(to: topLeft!)
//            context.addLine(to: topRight!)
//            context.addLine(to: bottomRight!)
//            context.addLine(to: bottomLeft!)
//            context.addLine(to: topLeft!)
//            context.fillPath()
//        }
//    }
}


