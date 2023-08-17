//
//  FTRoundProgressView.swift
//  Noteshelf
//
//  Created by Amar on 25/04/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTRoundProgressView: UIView {

    @IBInspectable var progressRadius : CGFloat = 30;
    
    var progress : CGFloat {
        get {
            return self.roundProgressLayer?.progress ?? 0;
        }
        set {
            self.roundProgressLayer?.progress = newValue;
        }
    }

    var radius : CGFloat {
        get {
            return self.roundProgressLayer?.radius ?? 0;
        }
        set {
            self.roundProgressLayer?.radius = newValue;
        }
    }

    var borderThickness : CGFloat {
        get {
            return self.roundProgressLayer?.borderThickness ?? 0;
        }
        set {
            self.roundProgressLayer?.borderThickness = newValue;
        }
    }

    weak var roundProgressLayer : FTRoundProgressLayer?;
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
    }

    override func awakeFromNib() {
        super.awakeFromNib();
        self.backgroundColor = UIColor.clear;
        self.isUserInteractionEnabled = false;
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        self.backgroundColor = UIColor.clear;
        self.isUserInteractionEnabled = false;
    }

    override func layoutSubviews() {
        super.layoutSubviews();
        self.roundProgressLayer?.frame = self.bounds;
    }
    
    func startAnimation()
    {
        self.resetToDefaults();
        let layer = FTRoundProgressLayer();
        self.roundProgressLayer = layer;
        layer.frame = self.bounds;
        layer.radius = self.progressRadius;
        layer.borderThickness = 2;
        self.layer.addSublayer(layer);
    }
    
    func endAnimation() {
        self.roundProgressLayer?.expandAndRemoveFromSuperLayer();
    }
    
    func resetToDefaults()
    {
        self.progress = 0;
        self.radius = self.progressRadius;
        self.roundProgressLayer?.removeAllAnimations();
        self.roundProgressLayer?.removeFromSuperlayer();
        self.roundProgressLayer = nil;
    }
}
