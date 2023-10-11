//
//  UIView+Extension.swift
//  FTCommon
//
//  Created by Narayana on 22/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension UIView {
    // When you have rounded corners along with shadow, use this. It requires its contsainer view to have same size to have shadow
    public func applyshadowWithCorner(containerView: UIView, cornerRadius: CGFloat, color: UIColor, offset: CGSize, shadowRadius: CGFloat) {
        self.clipsToBounds = true
        self.layer.cornerRadius = cornerRadius
        containerView.clipsToBounds = false
        containerView.layer.shadowColor = color.cgColor
        containerView.layer.shadowOpacity = 1.0
        containerView.layer.shadowOffset = offset
        containerView.layer.shadowRadius = shadowRadius
    }

   public func addShadow(cornerRadius: CGFloat, color: UIColor, offset: CGSize, opacity: Float, shadowRadius: CGFloat) {
        self.layer.masksToBounds = false
        self.layer.shadowOpacity = 0.0
        self.layer.cornerRadius = cornerRadius
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOffset = offset
        self.layer.shadowOpacity = opacity
        self.layer.shadowRadius = shadowRadius
    }
    public func addShadow(color: UIColor, offset: CGSize, opacity: Float, shadowRadius: CGFloat) {
         self.layer.masksToBounds = false
         self.layer.shadowOpacity = 0.0
         self.layer.shadowColor = color.cgColor
         self.layer.shadowOffset = offset
         self.layer.shadowOpacity = opacity
         self.layer.shadowRadius = shadowRadius
     }

    public func dropShadowWith(color: UIColor?, offset:CGSize, radius:CGFloat, scale: Bool = true) {
        self.layer.masksToBounds = false
        self.layer.shadowColor = color?.cgColor
        self.layer.shadowOffset = offset
        self.layer.shadowRadius = radius
        self.layer.shouldRasterize = true
        self.layer.shadowOpacity = 1
        self.layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }

    public func removeShadow() {
        layer.shadowRadius = CGFloat(0.0)
        layer.shadowOffset = CGSize.zero
        layer.shadowOpacity = 0.0
    }

   public func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }

    public func shapeTopCorners(_ radius: CGFloat = 16.0) {
        self.clipsToBounds = true
        self.layer.cornerRadius = radius
        self.layer.maskedCorners = [.layerMinXMinYCorner,.layerMaxXMinYCorner]
    }

    @objc public func isRegularClass() -> Bool
    {
#if targetEnvironment(macCatalyst)
        return true
#else
        if let keyWindow = self.window {
            return keyWindow.traitCollection.isRegular
        }
        return false
#endif
    }

    public func getCornerRadiiPath(topLeft: CGFloat = 0, topRight: CGFloat = 0, bottomLeft: CGFloat = 0, bottomRight: CGFloat = 0) -> CGPath {
        let topLeftRadius = CGSize(width: topLeft, height: topLeft)
        let topRightRadius = CGSize(width: topRight, height: topRight)
        let bottomLeftRadius = CGSize(width: bottomLeft, height: bottomLeft)
        let bottomRightRadius = CGSize(width: bottomRight, height: bottomRight)
        let maskPath = UIBezierPath(shouldRoundRect: bounds, topLeftRadius: topLeftRadius, topRightRadius: topRightRadius, bottomLeftRadius: bottomLeftRadius, bottomRightRadius: bottomRightRadius)
        return maskPath.cgPath
    }

@discardableResult
   public func roundCorners(topLeft: CGFloat = 0, topRight: CGFloat = 0, bottomLeft: CGFloat = 0, bottomRight: CGFloat = 0) -> CGPath {
        let topLeftRadius = CGSize(width: topLeft, height: topLeft)
        let topRightRadius = CGSize(width: topRight, height: topRight)
        let bottomLeftRadius = CGSize(width: bottomLeft, height: bottomLeft)
        let bottomRightRadius = CGSize(width: bottomRight, height: bottomRight)
        let maskPath = UIBezierPath(shouldRoundRect: bounds, topLeftRadius: topLeftRadius, topRightRadius: topRightRadius, bottomLeftRadius: bottomLeftRadius, bottomRightRadius: bottomRightRadius)
        let shape = CAShapeLayer()
        shape.path = maskPath.cgPath
        self.layer.mask = shape
       return maskPath.cgPath
    }

    public func getVisualEffectBlur(style: UIBlurEffect.Style = .systemThinMaterial, cornerRadius: CGFloat, frameToBlur: CGRect = .zero) -> UIVisualEffectView {
        let blurEffectView: UIVisualEffectView = {
            let blurEffect = UIBlurEffect(style: style)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.translatesAutoresizingMaskIntoConstraints = false
            let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
            let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
            blurEffectView.contentView.addSubview(vibrancyView)
            return blurEffectView
        }()
        blurEffectView.frame = (frameToBlur == .zero ? self.bounds : frameToBlur)
        blurEffectView.backgroundColor = UIColor.clear
        blurEffectView.layer.cornerRadius = cornerRadius
        blurEffectView.isUserInteractionEnabled = false
        blurEffectView.layer.masksToBounds = true
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return blurEffectView
    }

    @discardableResult
    public func addVisualEffectBlur(style: UIBlurEffect.Style = .systemThinMaterial, cornerRadius: CGFloat, frameToBlur: CGRect = .zero) -> UIVisualEffectView {
        let reqView = self.getVisualEffectBlur(style: style, cornerRadius: cornerRadius, frameToBlur: frameToBlur)
        self.insertSubview(reqView, at: 0)
        return reqView
    }

    public func removeVisualEffectBlur() {
        for subView in self.subviews where subView is UIVisualEffectView {
            subView.removeFromSuperview()
        }
    }

    public func addEqualConstraintsToView(toView:UIView,safeAreaLayout: Bool = false) {
        self.translatesAutoresizingMaskIntoConstraints = false
        if safeAreaLayout {
            self.leadingAnchor.constraint(equalTo: toView.safeAreaLayoutGuide.leadingAnchor, constant: 0).isActive = true
            self.trailingAnchor.constraint(equalTo: toView.safeAreaLayoutGuide.trailingAnchor, constant: 0).isActive = true
            self.topAnchor.constraint(equalTo: toView.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
            self.bottomAnchor.constraint(equalTo: toView.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
        } else {
            self.leadingAnchor.constraint(equalTo: toView.leadingAnchor, constant: 0).isActive = true
            self.trailingAnchor.constraint(equalTo: toView.trailingAnchor, constant: 0).isActive = true
            self.topAnchor.constraint(equalTo: toView.topAnchor, constant: 0).isActive = true
            self.bottomAnchor.constraint(equalTo: toView.bottomAnchor, constant: 0).isActive = true
        }
    }

    public func asImage() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}

@IBDesignable class FTDropShadowView: UIView {
    private var dashedBorder:CAShapeLayer!
    private var dashedRadius: CGFloat = 0.0;
    private var dashedLineWidth: CGFloat = 1.0;
    private var dashedLineColor: UIColor = UIColor.blue;
  
    @IBInspectable var radius: CGFloat {
        set {
            dashedRadius = newValue
        }
        get{
            return dashedRadius
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        set {
            dashedLineWidth = newValue
        }
        get{
            return dashedLineWidth
        }
    }
    
    @IBInspectable var borderColor: UIColor {
        set {
            dashedLineColor = newValue
        }
        get{
            return dashedLineColor
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.dashedBorder = CAShapeLayer()
        self.dashedBorder.strokeColor = dashedLineColor.cgColor
        self.dashedBorder.lineDashPattern = [3, 3]
        self.dashedBorder.lineWidth = dashedLineWidth
        self.dashedBorder.lineJoin=CAShapeLayerLineJoin.miter
        self.dashedBorder.frame = self.bounds
        self.dashedBorder.fillColor = nil
        self.dashedBorder.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: dashedRadius).cgPath
        self.dashedBorder.allowsEdgeAntialiasing = true;
        self.layer.allowsEdgeAntialiasing = true;
        self.layer.addSublayer(self.dashedBorder)
    }
    
    override func layoutSubviews() { //To refresh border layer when changed to various split modes
        super.layoutSubviews()
        self.dashedBorder.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: dashedRadius).cgPath
        self.dashedBorder.frame = self.bounds
        self.dashedBorder.allowsEdgeAntialiasing = true;
        self.dashedBorder.layoutIfNeeded()
    }
}
