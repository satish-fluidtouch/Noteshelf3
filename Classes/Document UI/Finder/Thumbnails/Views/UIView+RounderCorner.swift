//
//  FTRounderCornerButton.swift
//  Noteshelf
//
//  Created by Siva on 17/05/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension UIView {
    
    @objc func makeCornersRounded(on rectCorner: UIRectCorner, withRadius radius: CGFloat) {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: rectCorner, cornerRadii: CGSize(width: radius, height: radius));
        let maskLayer = CAShapeLayer();
        maskLayer.frame = self.bounds
        maskLayer.path = path.cgPath;
        self.layer.mask = maskLayer;
    }
    
    func makeAllCornersRounded(withRadius radius: CGFloat) {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: [.allCorners], cornerRadii: CGSize(width: radius, height: radius));
        let maskLayer = CAShapeLayer();
        maskLayer.path = path.cgPath;
        self.layer.mask = maskLayer;
    }
    
    func makeTopCornersRounded(withRadius radius: CGFloat) {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: radius, height: radius));
        let maskLayer = CAShapeLayer();
        maskLayer.path = path.cgPath;
        self.layer.mask = maskLayer;
    }
    
    func setBorderColor(withBorderWidth borderWidth: CGFloat, withColor color: UIColor) {
        self.layer.borderColor = color.cgColor
        self.layer.borderWidth = borderWidth
    }
    func removeRoundedCorners() {
        self.layer.mask = nil;
    }
    func getScreenDemension() -> String {
        let mainScreenBounds = UIScreen.main.bounds
        let deviceWidth = min(mainScreenBounds.width, mainScreenBounds.height)
        let deviceHeight = max(mainScreenBounds.width, mainScreenBounds.height)
        let deviceDemension = "\(Int(deviceWidth))" + "_" + "\(Int(deviceHeight))"
        return deviceDemension
    }
    
    func setInnerBorder(withBorderWidth borderWidth: CGFloat, withColor borderColor: UIColor) {
        self.frame = self.frame.insetBy(dx: -borderWidth, dy: -borderWidth);
        self.layer.borderColor = borderColor.cgColor
        self.layer.borderWidth = borderWidth
    }
    
}

extension CALayer {
    
    func addBorder(edge: UIRectEdge, color: UIColor, thickness: CGFloat) {
        
        let border = CALayer()
        
        switch edge {
        case .top:
            border.frame = CGRect(x: 0, y: 0, width: frame.width, height: thickness)
        case .bottom:
            border.frame = CGRect(x: 0, y: frame.height - thickness, width: frame.width, height: thickness)
        case .left:
            border.frame = CGRect(x: 0, y: 0, width: thickness, height: frame.height)
        case .right:
            border.frame = CGRect(x: frame.width - thickness, y: 0, width: thickness, height: frame.height)
        default:
            break
        }
        
        border.backgroundColor = color.cgColor;
        
        addSublayer(border)
    }
}
