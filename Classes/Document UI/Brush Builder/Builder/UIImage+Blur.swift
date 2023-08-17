//
//  UIImage+Blur.swift
//  Noteshelf
//
//  Created by Akshay on 08/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension UIImage {
    func applyBlurWithRadius(_ radius:CGFloat) -> UIImage {
        #if !targetEnvironment(macCatalyst)
            let filter = GPUImageGaussianBlurFilter()
            filter.blurRadiusInPixels = radius

            let sourcePicture = GPUImagePicture(image:self)
            sourcePicture?.addTarget(filter)
            filter.useNextFrameForImageCapture()
            sourcePicture?.processImage()
            let outputImage = filter.imageFromCurrentFramebuffer()
            return outputImage ?? self
        #else
            return self
        #endif
    }
}
