//
//  FTMarkerBrushBuilder_V3.swift
//  Noteshelf
//
//  Created by Akshay on 08/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
private let HIGHLIGHTER_THICKNESS_MULTIPLIER: CGFloat = 3.0

final class FTMarkerBrushBuilder_V3: FTBrushProtocol {
    static func attributesFor(brushWidth: CGFloat, velocitySensitive: Bool) -> FTPenAttributes {
        var attributes = FTPenAttributes()

        var widthInt = Int(brushWidth)

        attributes.curmass = 0.2
        attributes.curdrag = 0.14
        switch (widthInt) {
        case 1:
            widthInt = 2
        case 2:
            widthInt = 6
        case 3:
            widthInt = 10
        case 4:
            widthInt = 2
        case 5:
            widthInt = 6
        case 6:
            widthInt = 10
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
        let highImage:UIImage
        if brushWidth < 4 {
            highImage = self.circularBrushImageForWidth(brushWidth, scale:scale)
        }
        else {
            let scaleInt = max(1,Int(scale / UIScreen.main.scale))
            switch (scaleInt) {
                case 1:
                    highImage = UIImage(named:"BrushAsset_v3/marker-1")!
                case 2:
                    highImage = UIImage(named:"BrushAsset_v3/marker-2")!
                case 3:
                    highImage = UIImage(named:"BrushAsset_v3/marker-3")!
                default:
                    highImage = UIImage(named:"BrushAsset_v3/marker-3")!
            }
        }
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
            case 3:
                thicknessCorrectionFactor = 0.85
            case 4:
                thicknessCorrectionFactor = 0.5
            case 5:
                thicknessCorrectionFactor = 0.65
            case 6:
                thicknessCorrectionFactor = 0.85

            default:
                break
        }
        return thicknessCorrectionFactor
    }
}

private extension FTMarkerBrushBuilder_V3 {
    class func circularBrushImageForWidth(_ brushWidth:CGFloat, scale:CGFloat) -> UIImage {

        var swatchWidth:CGFloat = 15.0
        let widthInt = Int(brushWidth * HIGHLIGHTER_THICKNESS_MULTIPLIER)

        swatchWidth = max(swatchWidth,CGFloat(widthInt*2))

        let minStartLocation:CGFloat = 0.5
        let maxStartLocation:CGFloat = 0.85
        let minBrushWidth:CGFloat = 1 * HIGHLIGHTER_THICKNESS_MULTIPLIER
        let maxBrushWidth:CGFloat = 10 * HIGHLIGHTER_THICKNESS_MULTIPLIER
        let effectiveWidth:CGFloat = brushWidth * HIGHLIGHTER_THICKNESS_MULTIPLIER

        let startLocation:CGFloat = minStartLocation + (maxStartLocation - minStartLocation)*(effectiveWidth-minBrushWidth)/(maxBrushWidth-minBrushWidth)

        //NSLog(@"startLocation %.2f", startLocation);

        let startAlpha:CGFloat = 1.0


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
            FTLogError("marker_glossGradient_fail_v3")
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
            FTLogError("marker_texture_fail_v3")
            dotImage = UIImage(named: "BrushAsset_v3/brush-1-1")!
        }
        return dotImage
    }
}

