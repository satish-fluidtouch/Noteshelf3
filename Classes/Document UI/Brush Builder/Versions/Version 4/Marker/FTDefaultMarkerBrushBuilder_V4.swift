//
//  FTDefaultMarkerBrushBuilder_V4.swift
//  Noteshelf
//
//  Created by Akshay on 08/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

private let HIGHLIGHTER_THICKNESS_MULTIPLIER: CGFloat = 3.0

final class FTDefaultMarkerBrushBuilder_V4: FTBrushProtocol {

    static func attributesFor(brushWidth: CGFloat, velocitySensitive: Bool) -> FTPenAttributes {

        var attributes:FTPenAttributes = FTPenAttributes()

        var widthInt = Int(brushWidth)

        attributes.curmass = 0.2
        attributes.curdrag = 0.14
        switch (widthInt) {
            case 1:
                widthInt = 2
            case 2:
                widthInt = 4
            case 3:
                widthInt = 6
            case 4:
                widthInt = 8
            case 5:
                widthInt = 10
            case 6:
                widthInt = 12
            default:
                break
        }
        attributes.brushWidth = HIGHLIGHTER_THICKNESS_MULTIPLIER * CGFloat(widthInt)
        attributes.velocitySensitive = false

        //Just leave defaults (not needed in reality)
        attributes.penDiffFactor = 0.30
        attributes.penVelocityFactor = 0.008
        attributes.penMinFactor = 0.2

        return attributes
    }

    static func brushImageFor(brushWidth: CGFloat, scale: CGFloat) -> UIImage {
        let highImage = self.circularBrushImageFor(brushWidth:brushWidth, scale:scale)
        return highImage
    }

    static func thicknessCorrectionFactorFor(brushWidth: CGFloat) -> CGFloat {
        var thicknessCorrectionFactor:CGFloat = 1
        let brushWidthInt = Int(brushWidth)
        switch (brushWidthInt) {
            case 1:
                thicknessCorrectionFactor = 0.5
            case 2:
                thicknessCorrectionFactor = 0.65
            case 3,
                 4:
                thicknessCorrectionFactor = 0.75
            case 5,
                 6:
                thicknessCorrectionFactor = 0.85
            default:
                break
        }
        return thicknessCorrectionFactor
    }
}

private extension FTDefaultMarkerBrushBuilder_V4 {
    static func circularBrushImageFor(brushWidth:CGFloat, scale:CGFloat) -> UIImage {

        var swatchWidth:CGFloat = 15.0
        let widthScaled = brushWidth * HIGHLIGHTER_THICKNESS_MULTIPLIER

        swatchWidth = max(swatchWidth,widthScaled*2)

        let minStartLocation:CGFloat = 0.5
        let maxStartLocation:CGFloat = 0.85
        let minBrushWidth:CGFloat = 1 * HIGHLIGHTER_THICKNESS_MULTIPLIER
        let maxBrushWidth:CGFloat = 10 * HIGHLIGHTER_THICKNESS_MULTIPLIER
        let effectiveWidth:CGFloat = brushWidth * HIGHLIGHTER_THICKNESS_MULTIPLIER

        let startLocation:CGFloat = minStartLocation + (maxStartLocation - minStartLocation)*(effectiveWidth-minBrushWidth)/(maxBrushWidth-minBrushWidth)

        //NSLog(@"startLocation %.2f", startLocation);

        let startAlpha:CGFloat = 1.0

        let mulFac:CGFloat = scale
        let width:Int = Int(swatchWidth*mulFac)
        let height:Int = Int(swatchWidth*mulFac)

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
            FTLogError("glossGradient_fail")
            return UIImage(named: "BrushAsset_v3/brush-9-3")!
        }

        brushContext?.addEllipse(in: CGRect(x: 0, y: 0, width: width, height: height))
        brushContext?.clip()

        let topCenter:CGPoint = CGPoint(x:width/2, y:height/2)
        let midCenter:CGPoint = CGPoint(x:width/2, y:height/2)

        brushContext?.drawRadialGradient(glossGradient,
                                         startCenter: topCenter, startRadius: 0, endCenter: midCenter, endRadius: CGFloat(height)/2, options: .drawsBeforeStartLocation)

        let highlighterImage : UIImage
        if let cgImage = brushContext?.makeImage() {
            highlighterImage = UIImage(cgImage:cgImage)
        } else {
            //This is a fallback scenario, which should not reach here
            FTLogError("highligheter_texture_fail")
            highlighterImage = UIImage(named: "BrushAsset_v3/brush-9-3")!
        }
        return highlighterImage
    }
}
