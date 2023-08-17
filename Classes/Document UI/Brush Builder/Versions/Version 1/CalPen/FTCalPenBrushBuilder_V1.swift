//
//  FTCalPenBrushBuilder_V1.swift
//  Noteshelf
//
//  Created by Akshay on 08/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

final class FTCalPenBrushBuilder_V1: FTBrushProtocol {
    static func attributesFor(brushWidth: CGFloat, velocitySensitive: Bool) -> FTPenAttributes {
        var attributes:FTPenAttributes = FTPenAttributes()
        let widthInt = Int(brushWidth)

        attributes.curmass = 0.2
        attributes.curdrag = 0.15

        attributes.penVelocityFactor = 0.005
        attributes.penMinFactor = 0.4
        attributes.penDiffFactor = 0.3
        attributes.brushWidth = brushWidth

        switch (widthInt) {
            case 1:
                attributes.brushWidth = 3
                attributes.penVelocityFactor = 0.002
            case 2:
                attributes.brushWidth = 4
                attributes.penVelocityFactor = 0.003
            case 3:
                attributes.brushWidth = 5
                attributes.penVelocityFactor = 0.004
            case 4:
                attributes.brushWidth = 8
                attributes.penVelocityFactor = 0.005
            case 5:
                attributes.brushWidth = 10
            case 6:
                attributes.brushWidth = 13
            case 7:
                attributes.brushWidth = 17
            case 8:
                attributes.brushWidth = 24
            case 9:
                attributes.brushWidth = 30
            case 10:
                attributes.brushWidth = 40
            case 11:
                attributes.brushWidth = 43
            default:
                break
        }
        attributes.brushWidth -= 2
    //    attributes.brushWidth++;
        attributes.velocitySensitive = velocitySensitive
        return attributes
    }

    static func brushImageFor(brushWidth: CGFloat, scale: CGFloat) -> UIImage {
        let attributes:FTPenAttributes = self.penAttributesForBrushWidth(brushWidth)
        let brushWidth:CGFloat = attributes.brushWidth

        var minBrushWidth:CGFloat = self.penAttributesForBrushWidth(1).brushWidth
        var maxBrushWidth:CGFloat = self.penAttributesForBrushWidth(10).brushWidth

        let widthInt = Int(brushWidth)

    //    widthInt += 2.0f; //add 3 for creation of image

        var swatchWidth:CGFloat = 25
        let maximumCalPenBrushSizeWidth:CGFloat = 10
        let minimumCalPenBrushSizeWidth:CGFloat = 7

        swatchWidth = max(swatchWidth,CGFloat(widthInt*2))

        let mulFac = scale

        let width = Int(swatchWidth*mulFac)
        let height = Int(swatchWidth*mulFac)

        guard (width != 0 && height != 0) else {
            fatalError("Something wrong with Cal Pen brushWidth dimensions")
        }

    //    CGRect imageRect = CGRectMake(0, 0, minimumSizeBrushWidth*mulFac, height*0.75);
        var imageWidth:CGFloat = minimumCalPenBrushSizeWidth
        if brushWidth < 4
        {
            imageWidth = (maximumCalPenBrushSizeWidth + (minimumCalPenBrushSizeWidth - maximumCalPenBrushSizeWidth)*(brushWidth-minBrushWidth)/(4-minBrushWidth))*mulFac
        }
        let imageRect:CGRect = CGRect(x:0, y:0, width:imageWidth, height:CGFloat(height)*0.75)

        let brushData = calloc(width * height * 4, MemoryLayout<GLubyte>.stride)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGImageByteOrderInfo.orderDefault.rawValue
        let brushContext = CGContext(data: brushData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width*4, space: colorSpace, bitmapInfo: bitmapInfo)

        brushContext?.saveGState()
        brushContext?.translateBy(x: +(CGFloat(width) * 0.5), y: +(CGFloat(height) * 0.5))

        let radians:CGFloat = CGFloat(45*CGFloat.pi/180)
        brushContext?.rotate(by: radians)

        /// Draw the image in the bitmap context
        let fillRect:CGRect = CGRect(x:-imageRect.size.width * 0.5, y: -imageRect.size.height * 0.5, width:imageRect.size.width, height:imageRect.size.height)
        brushContext?.setFillColor(UIColor.white.cgColor)
        brushContext?.fill(fillRect.integral)

        brushContext?.restoreGState()

        var dotImage : UIImage
        if let cgImage = brushContext?.makeImage() {
            dotImage = UIImage(cgImage:cgImage)
        } else {
            //This is a fallback scenario, which should not reach here
            FTLogError("CalPen_texture_fail")
            dotImage = UIImage(named: "BrushAsset_v3/brush-9-3")!
        }

        //blur vary from 2.0 to 0.8 from brush of offset 1 to 5
        //blur vary from 0.8 to from 6 to 10
        var blurToApply:CGFloat = 0.2
        var maxSizeBrushBlur:CGFloat = 0.6
        var minimumBrushBlur:CGFloat = 0.2

        if brushWidth < 4
        {
            maxSizeBrushBlur = 2.0
            minimumBrushBlur = 0.6
            maxBrushWidth = self.penAttributesForBrushWidth(4).brushWidth
        }
        else
        {
            minBrushWidth = self.penAttributesForBrushWidth(5).brushWidth
        }

        blurToApply = maxSizeBrushBlur + (minimumBrushBlur - maxSizeBrushBlur)*(brushWidth-minBrushWidth)/(maxBrushWidth-minBrushWidth)
        dotImage = dotImage.applyBlurWithRadius(blurToApply)

        return dotImage
    }

    static func thicknessCorrectionFactorFor(brushWidth: CGFloat) -> CGFloat {
        //default
        return 1.0
    }
}

private extension FTCalPenBrushBuilder_V1 {

    static func penAttributesForBrushWidth(_ brushWidth:CGFloat) -> FTPenAttributes {
        return self.attributesFor(brushWidth:brushWidth, velocitySensitive:true)
    }
}
