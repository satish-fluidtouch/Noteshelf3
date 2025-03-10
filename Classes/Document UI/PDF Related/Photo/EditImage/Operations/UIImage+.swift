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
}
