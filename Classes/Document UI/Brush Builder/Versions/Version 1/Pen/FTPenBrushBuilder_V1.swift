//
//  FTPenBrushBuilder_V1.swift
//  Noteshelf
//
//  Created by Akshay on 08/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

final class FTPenBrushBuilder_V1: FTBrushProtocol {
    static func attributesFor(brushWidth: CGFloat, velocitySensitive: Bool) -> FTPenAttributes {
        let widthInt = Int(brushWidth)

        var attributes:FTPenAttributes = FTPenAttributes()
        attributes.curmass = 0.2
        attributes.curdrag = 0.14
        attributes.penDiffFactor = 0.30
        attributes.penVelocityFactor = 0.008
        attributes.penMinFactor = 0.2
        attributes.brushWidth = CGFloat(widthInt)

        switch (widthInt) {
            case 1://For Retina only
                attributes.brushWidth = 2
                attributes.penVelocityFactor = 0.015//old value 0.020
                attributes.penMinFactor = 0.80 //old value 0.6
            case 2:
                attributes.brushWidth = 3
                attributes.penVelocityFactor = 0.015 //old value 0.020
                attributes.penMinFactor = 0.45
            case 3:
                attributes.brushWidth = 4
                attributes.penVelocityFactor = 0.020
                attributes.penMinFactor = 0.30
            case 4:
                attributes.brushWidth = 5
                attributes.penVelocityFactor = 0.018
                attributes.penMinFactor = 0.30
            case 5:
                attributes.brushWidth = 7
                attributes.penVelocityFactor = 0.018
                attributes.penMinFactor = 0.30
            case 6:
                attributes.brushWidth = 9
                attributes.penVelocityFactor = 0.017
                attributes.penMinFactor = 0.4
            case 7:
                attributes.brushWidth = 13
                attributes.penVelocityFactor = 0.014
                attributes.penMinFactor = 0.4
            case 8:
                attributes.brushWidth = 19
                attributes.penVelocityFactor = 0.010
                attributes.penMinFactor = 0.4
            case 9:
                attributes.brushWidth = 24
                attributes.penVelocityFactor = 0.007
                attributes.penMinFactor = 0.4
            case 10:
                attributes.brushWidth = 26
                attributes.penVelocityFactor = 0.007
                attributes.penMinFactor = 0.4
            case 11: //For Non Retina only
                attributes.brushWidth = 29
                attributes.penVelocityFactor = 0.007
                attributes.penMinFactor = 0.4
            default:
                attributes.brushWidth = 5
                attributes.penVelocityFactor = 0.018
                attributes.penMinFactor = 0.30
        }
        attributes.brushWidth -= 1
        attributes.velocitySensitive = velocitySensitive

        return attributes
    }

    static func brushImageFor(brushWidth: CGFloat, scale: CGFloat) -> UIImage {
        var startLocation:CGFloat
        var startAlpha:CGFloat = 1.0

        let widthInt = Int(brushWidth)
        let _brushWidth = self.penAttributesForBrushWidth(brushWidth).brushWidth
        var swatchWidth:CGFloat = 15.0

        switch (widthInt) {
            case 1:
                startAlpha = 0.40 //old value 0.60
            case 2:
                startAlpha = 0.45
            case 3:
                startAlpha = 0.50
            case 4:
                startAlpha = 0.55
            case 5:
                startAlpha = 0.75
            case 6:
                startAlpha = 0.95
            case 7:
                startAlpha = 1.0
            case 8:
                startAlpha = 1.0
            case 9:
                startAlpha = 1.0
            case 10:
                startAlpha = 1.0
            case 11:
                startAlpha = 1.0
            default:
                startAlpha = 1.0
            break
        }

        //swatchWidth = brushWidth*3;

        swatchWidth = max(swatchWidth,CGFloat(widthInt*2))

        let minStartLocation:CGFloat = 0.30
        let maxStartLocation:CGFloat = 0.90
        let minBrushWidth:CGFloat = self.penAttributesForBrushWidth(1).brushWidth
        let maxBrushWidth:CGFloat = self.penAttributesForBrushWidth(10).brushWidth
        if widthInt == 11
        {
            startLocation = maxStartLocation
        }
        else
        {
            startLocation = minStartLocation + (maxStartLocation - minStartLocation)*(_brushWidth-minBrushWidth)/(maxBrushWidth-minBrushWidth)
        }

        //NSLog(@"startLocation %.2f", startLocation);

        let mulFac:CGFloat = scale
        let width = Int(swatchWidth*mulFac)
        let height = Int(swatchWidth*mulFac)

        let brushData = calloc(width * height * 4, MemoryLayout<GLubyte>.stride)
        defer {
            if let data = brushData {
                free(data)
            }
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGImageByteOrderInfo.orderDefault.rawValue
        let brushContext = CGContext(data: brushData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width*4, space: colorSpace, bitmapInfo: bitmapInfo)

        let num_locations:size_t = 2

        //NSLog(@"%f", startLocation);
        let locations:[CGFloat] = [ startLocation, 1.0]

        let components:[CGFloat] = [
            1.0, 1.0, 1.0, startAlpha,    // Start color
            1.0, 1.0, 1.0, 0.0
        ]    // End color


        guard let glossGradient = CGGradient(colorSpace: colorSpace, colorComponents: components, locations: locations, count: num_locations) else {
            //This is a fallback scenario, unable to create CGGradient
            FTLogError("pen_glossGradient_fail_v1")
            return UIImage(named: "BrushAsset_v3/brush-1-1")!
        }

        brushContext?.addEllipse(in: CGRect(x: 0, y: 0, width: width, height: height))
        brushContext?.clip()

        let topCenter:CGPoint = CGPoint(x:width/2, y:height/2)
        let midCenter:CGPoint = CGPoint(x:width/2, y:height/2)

        brushContext?.drawRadialGradient(glossGradient,
                                         startCenter: topCenter, startRadius: 0, endCenter: midCenter, endRadius: CGFloat(height)/2, options: .drawsBeforeStartLocation)
        let dotImage : UIImage
        if let cgImage = brushContext?.makeImage() {
            dotImage = UIImage(cgImage:cgImage)
        } else {
            //This is a fallback scenario, which should not reach here
            FTLogError("pen_texture_fail_v1")
            dotImage = UIImage(named: "BrushAsset_v3/brush-1-1")!
        }
        return dotImage
    }

    static func thicknessCorrectionFactorFor(brushWidth: CGFloat) -> CGFloat {
        return 1.0
    }
}

private extension FTPenBrushBuilder_V1 {
    static func penAttributesForBrushWidth(_ brushWidth:CGFloat) -> FTPenAttributes {
        return self.attributesFor(brushWidth:brushWidth, velocitySensitive:true)
    }
}
