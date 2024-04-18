//
//  UIImage+RounderCorner.swift
//  Noteshelf3
//
//  Created by Sameer on 14/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
extension UIImage {
    public func makeCover(shouldAddSpine: Bool = false, shouldAddCorner: Bool = false, isCover: Bool = false) -> UIImage {
        let size = self.size
        guard let ftcontext = FTImageContext.imageContext(size, scale: UIScreen.main.scale) else {
            return self
        }
        let context = ftcontext.cgContext;
        var scaledImageRect = CGRect.zero;
        let aspectWidth:CGFloat = size.width / self.size.width;
        let aspectHeight:CGFloat = size.height / self.size.height;
        let aspectRatio:CGFloat = max(aspectWidth, aspectHeight);
        scaledImageRect.size.width = self.size.width * aspectRatio;
        scaledImageRect.size.height = self.size.height * aspectRatio;
        scaledImageRect.origin.x = (size.width - scaledImageRect.size.width) / 2.0;
        scaledImageRect.origin.y = (size.height - scaledImageRect.size.height) / 2.0;
        let defaultCornerRadius = CGSize(width: 10, height: 10)
        var maskPath = UIBezierPath(shouldRoundRect:  scaledImageRect, topLeftRadius: defaultCornerRadius, topRightRadius: defaultCornerRadius, bottomLeftRadius: defaultCornerRadius, bottomRightRadius: defaultCornerRadius)
        if isCover {
            let topLeftRadius = CGSize(width:   6, height: 6)
            let topRightRadius = CGSize(width: 15, height: 15)
            let bottomLeftRadius = CGSize(width: 6, height: 6)
            let bottomRightRadius = CGSize(width: 15, height: 15)
            maskPath = UIBezierPath(shouldRoundRect:  scaledImageRect, topLeftRadius: topLeftRadius, topRightRadius: topRightRadius, bottomLeftRadius: bottomLeftRadius, bottomRightRadius: bottomRightRadius)
        }
        if shouldAddCorner {
            context.addPath(maskPath.cgPath)
            context.clip()
        }
        context.interpolationQuality = .high
        context.translateBy(x: 0.0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        ftcontext.drawImage(self, in: scaledImageRect);
        if shouldAddSpine {
            ftcontext.drawImage(UIImage(named:"cover_line.png")!, in: CGRect(x: 0, y: 0, width: 15, height: scaledImageRect.height));
        }
        let newImage = ftcontext.uiImage()
        return newImage ?? self
    }
    
    public func addSpineToImageIfneeded(shouldAddSpine: Bool) -> UIImage {
        let size = self.size
        
        guard let ftcontext = FTImageContext.imageContext(size, scale: UIScreen.main.scale), shouldAddSpine else {
            return self
        }
        let context = ftcontext.cgContext;
        let frame = CGRect(origin: .zero, size: size)
        context.interpolationQuality = .high
        context.translateBy(x: 0.0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        ftcontext.drawImage(self, in: frame);
        ftcontext.drawImage(UIImage(named:"cover_spine")!, in: CGRect(origin: .zero, size: CGSize(width: 70, height: frame.height)));
        let newImage = ftcontext.uiImage()
        return newImage ?? self
    }
}

extension UIBezierPath {
    public convenience init(shouldRoundRect rect: CGRect, topLeftRadius: CGSize = .zero, topRightRadius: CGSize = .zero, bottomLeftRadius: CGSize = .zero, bottomRightRadius: CGSize = .zero){

        self.init()

        let path = CGMutablePath()

        let topLeft = rect.origin
        let topRight = CGPoint(x: rect.maxX, y: rect.minY)
        let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)
        let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)

        if topLeftRadius != .zero{
            path.move(to: CGPoint(x: topLeft.x+topLeftRadius.width, y: topLeft.y))
        } else {
            path.move(to: CGPoint(x: topLeft.x, y: topLeft.y))
        }

        if topRightRadius != .zero{
            path.addLine(to: CGPoint(x: topRight.x-topRightRadius.width, y: topRight.y))
            path.addCurve(to:  CGPoint(x: topRight.x, y: topRight.y+topRightRadius.height), control1: CGPoint(x: topRight.x, y: topRight.y), control2:CGPoint(x: topRight.x, y: topRight.y+topRightRadius.height))
        } else {
             path.addLine(to: CGPoint(x: topRight.x, y: topRight.y))
        }

        if bottomRightRadius != .zero{
            path.addLine(to: CGPoint(x: bottomRight.x, y: bottomRight.y-bottomRightRadius.height))
            path.addCurve(to: CGPoint(x: bottomRight.x-bottomRightRadius.width, y: bottomRight.y), control1: CGPoint(x: bottomRight.x, y: bottomRight.y), control2: CGPoint(x: bottomRight.x-bottomRightRadius.width, y: bottomRight.y))
        } else {
            path.addLine(to: CGPoint(x: bottomRight.x, y: bottomRight.y))
        }

        if bottomLeftRadius != .zero{
            path.addLine(to: CGPoint(x: bottomLeft.x+bottomLeftRadius.width, y: bottomLeft.y))
            path.addCurve(to: CGPoint(x: bottomLeft.x, y: bottomLeft.y-bottomLeftRadius.height), control1: CGPoint(x: bottomLeft.x, y: bottomLeft.y), control2: CGPoint(x: bottomLeft.x, y: bottomLeft.y-bottomLeftRadius.height))
        } else {
            path.addLine(to: CGPoint(x: bottomLeft.x, y: bottomLeft.y))
        }

        if topLeftRadius != .zero{
            path.addLine(to: CGPoint(x: topLeft.x, y: topLeft.y+topLeftRadius.height))
            path.addCurve(to: CGPoint(x: topLeft.x+topLeftRadius.width, y: topLeft.y) , control1: CGPoint(x: topLeft.x, y: topLeft.y) , control2: CGPoint(x: topLeft.x+topLeftRadius.width, y: topLeft.y))
        } else {
            path.addLine(to: CGPoint(x: topLeft.x, y: topLeft.y))
        }

        path.closeSubpath()
        cgPath = path
    }
}
