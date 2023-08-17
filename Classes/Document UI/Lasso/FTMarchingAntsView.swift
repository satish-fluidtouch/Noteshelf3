//
//  FTMarchingAntsView.swift
//  Noteshelf
//
//  Created by Amar on 15/06/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTMarchingAntsView: UIView {
    private var lineWidth: CGFloat = 2;
    private var lineColor: UIColor = UIColor.appColor(.groupNotesCountTint);
    var currentPath: CGPath?;

    var marchingAntsVisible = false {
        didSet {
            UIView.animate(withDuration: 0.2) { [weak self] in
                guard let strongSelf = self else { return };
                strongSelf.marchingAntsLayer?.isHidden = !strongSelf.marchingAntsVisible;
            }
        }
    };
    
    private var marchingAntsLayer: CAShapeLayer?;

    override init(frame: CGRect) {
        super.init(frame: frame);
        self.isUserInteractionEnabled = false;
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder);
        self.isUserInteractionEnabled = false;
    }
    
    func setMarchingAntsPath(_ path: CGPath) {
        let shapeLayer = CAShapeLayer();
        shapeLayer.bounds = self.bounds;
        shapeLayer.position = CGPoint(x:self.bounds.width*0.5,y:self.bounds.height*0.5);
        shapeLayer.fillColor = UIColor.clear.cgColor;
        shapeLayer.strokeColor = self.lineColor.cgColor;
        shapeLayer.lineWidth = self.lineWidth;
        shapeLayer.lineCap = .square;
        shapeLayer.lineJoin = .round;
        shapeLayer.shadowColor = UIColor.black.cgColor;
        shapeLayer.shadowOpacity = 0.2;
        shapeLayer.shadowRadius = 1;
        shapeLayer.shadowOffset = CGSize(width: 1, height: 1);
        shapeLayer.lineDashPattern = [NSNumber(value: 10),NSNumber(value: 5)];

        self.currentPath = path;
        shapeLayer.path = path;
        // Set the layer's contents
        self.layer.addSublayer(shapeLayer);

        //now animate
        let dashAnimation = CABasicAnimation(keyPath: "lineDashPhase");
        dashAnimation.fromValue = NSNumber(value: 0);
        dashAnimation.toValue = NSNumber(value: 15);
        dashAnimation.duration = 0.2;
        dashAnimation.repeatCount = 10000;
        shapeLayer.add(dashAnimation, forKey: "linePhase");
        
        self.marchingAntsLayer = shapeLayer;
    }
    
    func removeMovingAntsPath() {
        self.marchingAntsLayer?.removeAllAnimations();
        self.marchingAntsLayer?.removeFromSuperlayer();

        self.marchingAntsLayer = nil;
        self.currentPath = nil;
    }
    
    func isPointInsidePath(_ point: CGPoint) -> Bool {
        return self.currentPath?.contains(point) ?? false;
    }
}
