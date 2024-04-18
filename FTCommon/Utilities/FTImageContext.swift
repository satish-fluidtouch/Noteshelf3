//
//  FTImageContext.swift
//  FTCommon
//
//  Created by Amar Udupa on 20/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTRenderKit
import CoreGraphics

public class FTImageContext: NSObject {
    public private(set) var cgContext: CGContext
    var screenScale: CGFloat = UIScreen.main.scale;
    
    required init(context inCTX: CGContext,screenScale scale: CGFloat) {
        cgContext = inCTX;
        self.screenScale = scale;
    }
    
    public static func imageContext(_ size:CGSize,scale: CGFloat = UIScreen.main.scale) -> FTImageContext? {
        let scaleToApply = scale == 0 ? UIScreen.main.scale : scale;
        let width = Int(size.width * scaleToApply);
        let height = Int(size.height * scaleToApply);

        let bitsPerComponent = 8
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let options = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        
        if let context = CGContext(data: nil
                                   , width: width
                                   , height: height
                                   , bitsPerComponent: bitsPerComponent
                                   , bytesPerRow: bytesPerRow
                                   , space: colorSpace
                                   , bitmapInfo: options) {
            context.translateBy(x: 0, y: CGFloat(height))
            context.scaleBy(x: 1, y: -1)
            context.scaleBy(x: scaleToApply, y: scaleToApply)
            UIGraphicsPushContext(context);
            return FTImageContext(context: context,screenScale: scaleToApply)
        }
        return nil;
    }
    
    public func drawImage(_ image:UIImage,in rect:CGRect) {
        if let cgImage = image.cgImage {
            self.cgContext.draw(cgImage, in: rect)
        }
    }
    
    public func uiImage() -> UIImage? {
        UIGraphicsPopContext()
        guard let cgimage = self.cgContext.makeImage() else {
            return nil;
        }
        return UIImage(cgImage: cgimage,scale: self.screenScale, orientation: .up);
    }
}
