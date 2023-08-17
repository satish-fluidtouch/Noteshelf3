//
//  FTIndicatorView.swift
//  Noteshelf
//
//  Created by Naidu on 12/9/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTIndicatorView: UIView,CAAnimationDelegate {
    var shapeLayer:CAShapeLayer!
    var ovalRect:CGRect=CGRect.zero
    var arrowHeight:CGFloat = 100
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.shapeLayer = CAShapeLayer()
        self.shapeLayer.masksToBounds=true
        self.shapeLayer.strokeColor = UIColor.clear.cgColor
        self.shapeLayer.lineWidth=2.0
        self.shapeLayer.fillColor=nil
        self.shapeLayer.lineJoin=CAShapeLayerLineJoin.round
        self.layer.addSublayer(self.shapeLayer)
    }
    override func layoutSubviews() { //To refresh indicator when changed to various split modes
        super.layoutSubviews()
        self.refreshIndicators();
    }
    func refreshIndicators(){
        self.shapeLayer.frame = self.bounds
        
        let ovalShapeRect=CGRect.init(x: (self.frame.size.width-self.ovalRect.size.width)/2.0, y: self.ovalRect.origin.y, width: self.ovalRect.size.width, height: self.ovalRect.size.height)
        
        let ovalShape = UIBezierPath.init(ovalIn: ovalShapeRect)
        let arrowShape = UIBezierPath.arrow(from: CGPoint.init(x: self.shapeLayer.frame.size.width/2.0, y: self.ovalRect.origin.y+self.ovalRect.height), to: CGPoint.init(x: self.shapeLayer.frame.size.width/2.0, y: self.ovalRect.origin.y+self.ovalRect.height+self.arrowHeight), tailWidth: 1, headWidth: 20, headLength: 16)
        UIColor.white.setFill()
        arrowShape.fill()
        
        let mutablePath:CGMutablePath=CGMutablePath()
        mutablePath.addPath(ovalShape.cgPath)
        mutablePath.addPath(arrowShape.cgPath)
        self.shapeLayer.path = mutablePath
        self.shapeLayer.layoutIfNeeded()
    }
    func manageVisibility(_ shouldVisible:Bool){

        let animationAlpha = CABasicAnimation(keyPath: "strokeColor")
        animationAlpha.fromValue         = shouldVisible ? UIColor.clear.cgColor : UIColor.white.cgColor
        animationAlpha.toValue           = shouldVisible ? UIColor.white.cgColor : UIColor.clear.cgColor
        animationAlpha.duration          = 0.5;
        animationAlpha.repeatCount       = 0;
        animationAlpha.autoreverses      = false
        self.shapeLayer.strokeColor = shouldVisible ? UIColor.white.cgColor : UIColor.clear.cgColor

        self.shapeLayer.add(animationAlpha, forKey: "strokeColor")
    }
}

extension UIBezierPath {
    
    class func arrow(from start: CGPoint, to end: CGPoint, tailWidth: CGFloat, headWidth: CGFloat, headLength: CGFloat) -> Self {
        let length = hypot(end.x - start.x, end.y - start.y)
        let tailLength = length - headLength
        
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { return CGPoint(x: x, y: y) }
        let points: [CGPoint] = [
            p(0, tailWidth / 2),
            p(tailLength, tailWidth / 2),
            p(tailLength, headWidth / 2),
            p(length, 0),
            p(tailLength, -headWidth / 2),
            p(tailLength, -tailWidth / 2),
            p(0, -tailWidth / 2)
        ]
        
        let cosine = (end.x - start.x) / length
        let sine = (end.y - start.y) / length
        let transform = CGAffineTransform(a: cosine, b: sine, c: -sine, d: cosine, tx: start.x, ty: start.y)
        
        let path = CGMutablePath()
        path.addLines(between: points, transform: transform)
        path.closeSubpath()
        
        return self.init(cgPath: path)
    }
    
}
