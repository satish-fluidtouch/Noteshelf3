//
//  UIImage+.swift
//  EditImage
//
//  Created by Matra on 17/05/18.
//  Copyright © 2018 Matra. All rights reserved.
//

import UIKit

extension UIImage {

    
    func crop(rect: CGRect, withscaleWidth scaleWidth: CGFloat, scaleHeight: CGFloat) -> UIImage? {
        var scaledRect = rect
        let ratio = min(size.width/scaleWidth, size.height/scaleHeight)
        let mulScale = self.scale * ratio
        scaledRect.origin.x *= mulScale
        scaledRect.origin.y *= mulScale
        scaledRect.size.width *= mulScale
        scaledRect.size.height *= mulScale
        #if DEBUG
        debugPrint("****** : crop : **** : \(scaledRect) original rect :- \(self.size)")
        #endif
        guard let imageRef: CGImage = cgImage?.cropping(to: scaledRect) else {
            return self
        }
        let image = UIImage(cgImage: imageRef, scale: scale, orientation: imageOrientation)
        return image
    }
    
    @objc func addSchoolworkIcon() -> UIImage{
        let swIconImage =  UIImage(named: "schoolworkbadge")
        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        let scale = swIconImage!.scale
        UIGraphicsBeginImageContextWithOptions(self.size, false, scale/self.scale)
        let context = UIGraphicsGetCurrentContext()
        
        context!.setFillColor(UIColor.white.cgColor)
        context!.fill(rect)
        
        self.draw(in: rect, blendMode: .normal, alpha: 1)
        swIconImage!.draw(in: CGRect(x: 0, y: rect.height - (swIconImage!.size.height * scale/self.scale), width: (swIconImage!.size.width * scale/self.scale), height: (swIconImage!.size.height * scale/self.scale)), blendMode: .normal, alpha: 1)
        
        let combinedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if combinedImage != nil {
            return combinedImage!
        }else{
            return self
        }
    }
}
