//
//  Siri+Common.swift
//  Noteshelf
//
//  Created by Sameer on 13/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//
// This file has methods which are used in both NoteShelf & NS2Siri Intent TargetShips.

import Foundation
extension UIColor {
    @objc convenience init(hexString: String?) {
        let scanner = Scanner(string: hexString ?? "")
        
        var hex = UInt64()
        scanner.scanHexInt64(&hex)
        
        let r = Int((hex >> 16) & 0xff)
        let g = Int((hex >> 8) & 0xff)
        let b = Int(hex) & 0xff
        
        let red   = CGFloat(Double(r) / 255.0)
        let green = CGFloat(Double(g) / 255.0)
        let blue  = CGFloat(Double(b) / 255.0)
        let alpha = 1.0
        self.init(red:red, green:green, blue:blue, alpha:CGFloat(alpha))
    }
}

extension UIImage {
    
    func imageByScalingProportionallyToSize(_ targetSize:CGSize) -> UIImage! {
        return self.imageByScalingProportionallyToSize(targetSize, withCornerRadius:0)
    }

    func imageByScalingProportionallyToSize(_ targetSize:CGSize, withCornerRadius radius:CGFloat) -> UIImage! {

        let sourceImage:UIImage! = self
        var newImage:UIImage! = nil

        let imageSize:CGSize = sourceImage.size
        let width:CGFloat = imageSize.width
        let height:CGFloat = imageSize.height

        let targetWidth:CGFloat = targetSize.width
        let targetHeight:CGFloat = targetSize.height

        var scaleFactor:CGFloat = 0.0
        var scaledWidth:CGFloat = targetWidth
        var scaledHeight:CGFloat = targetHeight

        var thumbnailPoint:CGPoint = CGPoint(x: 0.0,y: 0.0)

        if imageSize.equalTo(targetSize) == false {

            let widthFactor:CGFloat = targetWidth / width
            let heightFactor:CGFloat = targetHeight / height

            if widthFactor < heightFactor
                {scaleFactor = widthFactor}
            else
                {scaleFactor = heightFactor}

            scaledWidth  = width * scaleFactor
            scaledHeight = height * scaleFactor

            // center the image

            if widthFactor < heightFactor {
                thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5
            } else if widthFactor > heightFactor {
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5
            }
        }


        // this is actually the interesting part:

        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
        if let context = UIGraphicsGetCurrentContext() {
            context.interpolationQuality = CGInterpolationQuality.high
        }
        var thumbnailRect:CGRect = .zero
        thumbnailRect.origin = thumbnailPoint
        thumbnailRect.size.width  = scaledWidth
        thumbnailRect.size.height = scaledHeight

        if radius > 0 {
            UIBezierPath(roundedRect: thumbnailRect, cornerRadius:2 * UIScreen.main.scale).addClip()
        }
        sourceImage.draw(in: thumbnailRect)

        newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if newImage == nil {print("could not scale image")}

        return newImage
    }

}

