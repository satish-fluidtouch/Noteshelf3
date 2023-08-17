//
//  FTZoomBorderView.swift
//  Noteshelf
//
//  Created by Amar on 10/06/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTZoomBorderView: UIView {
    private let scrollIndicatorOffset: CGFloat = 8.0

    var lineHeight: CGFloat = 0 {
        didSet {
            self.setNeedsDisplay();
        }
    }
    private var _autoscrollWidth: CGFloat = 0;
    var autoscrollWidth: Int {
        set {
            _autoscrollWidth = CGFloat(newValue);
        }
        get {
            return Int(_autoscrollWidth);
        }
    }
    
    var shouldShowAutoAdvance: Bool = false {
        didSet{
            self.setNeedsDisplay();
        }
    }

 
    override init(frame: CGRect) {
        super.init(frame: frame);
        self.backgroundColor = UIColor.clear;
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder);
        self.backgroundColor = UIColor.clear;
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect);
        let context = UIGraphicsGetCurrentContext();
        if(shouldShowAutoAdvance) {
            context?.saveGState();
            context?.addRect(CGRect(x:self.bounds.width - _autoscrollWidth + scrollIndicatorOffset,
                                    y:0,
                                    width:_autoscrollWidth,
                                    height:self.bounds.height));
            UIColor.appColor(.accent).withAlphaComponent(0.08).setFill();
            context?.fillPath();
            context?.restoreGState();
            
        }
        UIColor.appColor(.ftBlue).setStroke();
        context?.setLineWidth(1)
        context?.setLineDash(phase: 0, lengths: [3,1])
        if (lineHeight > 0 && lineHeight < self.bounds.height) {
            context?.move(to: CGPoint(x: 0, y: lineHeight));
            context?.addLine(to: CGPoint(x: self.bounds.width, y: lineHeight));
        }
        context?.strokePath()
    }
}
