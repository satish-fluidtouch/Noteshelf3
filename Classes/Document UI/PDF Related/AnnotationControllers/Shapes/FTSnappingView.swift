//
//  FTSnappingView.swift
//  Noteshelf
//
//  Created by Sameer on 25/03/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
class FTSnapView : UIView {
    private weak var drawLineLayer : CAShapeLayer?;

    override init(frame: CGRect) {
        super.init(frame: frame)
        let _frame = CGRect(origin: .zero, size: frame.size)
        let horizontalLineView = FTLineDashView(frame: _frame)
        let verticalLineView = FTVerticalDashView(frame: _frame)
        horizontalLineView.addFullConstraints(self)
        verticalLineView.addFullConstraints(self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class FTVerticalDashView : UIView {
    private weak var drawLineLayer : CAShapeLayer?;
    
    private var shapeLayer : CAShapeLayer {
        if(nil == drawLineLayer) {
            let shapelayer = CAShapeLayer.init();
            self.layer.addSublayer(shapelayer);
            self.drawLineLayer = shapelayer;
            self.drawLineLayer?.masksToBounds=true
            self.drawLineLayer?.strokeColor = UIColor(hexString: "EE0C6B").cgColor
//            self.drawLineLayer?.lineDashPattern = [4, 4]
            self.drawLineLayer?.lineWidth = 2.0
            self.drawLineLayer?.lineJoin=CAShapeLayerLineJoin.miter
            self.drawLineLayer?.frame = self.bounds;
            self.drawLineLayer?.fillColor = nil;
            let path = UIBezierPath.init();
            path.move(to: leftMidPoint);
            path.addLine(to: rightMidPoint);
            self.drawLineLayer?.path = path.cgPath
            self.drawLineLayer?.allowsEdgeAntialiasing = true;
            self.layer.allowsEdgeAntialiasing = true;
        }
        return drawLineLayer!;
    }
    
    var leftMidPoint: CGPoint {
        var leftMid = frame.origin
        leftMid.y += frame.size.height / 2
        return leftMid
    }
    
    var rightMidPoint: CGPoint {
        var rightMid = frame.origin
        rightMid.x += frame.size.width
        rightMid.y += frame.size.height / 2
        return rightMid
    }
    
    override func layoutSubviews() {
        super.layoutSubviews();
        CATransaction.begin();
        CATransaction.setDisableActions(true);
        self.shapeLayer.frame = self.bounds;
        let path = UIBezierPath.init();
        path.move(to: leftMidPoint);
        path.addLine(to: rightMidPoint);
        self.shapeLayer.path = path.cgPath
        CATransaction.commit();
    }
}
