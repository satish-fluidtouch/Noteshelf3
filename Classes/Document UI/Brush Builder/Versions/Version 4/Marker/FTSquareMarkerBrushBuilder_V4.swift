//
//  FTSquareMarkerBrushBuilder_V4.swift
//  Noteshelf
//
//  Created by Akshay on 08/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

private let HIGHLIGHTER_THICKNESS_MULTIPLIER: CGFloat = 3.0

final class FTSquareMarkerBrushBuilder_V4: FTBrushProtocol {
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
        var highImage:UIImage! = nil
        let widthInt = Int(brushWidth)
        switch (widthInt) {
            case 1,2:
                highImage = UIImage(named:"BrushAsset_v4/square_marker-1")
            case 3,4:
                highImage = UIImage(named:"BrushAsset_v4/square_marker-2")
            case 5,6:
                highImage = UIImage(named:"BrushAsset_v4/square_marker-3")
            default:
                highImage = UIImage(named:"BrushAsset_v4/square_marker-3")
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
            case 3,4:
                thicknessCorrectionFactor = 0.75
            case 5,6:
                thicknessCorrectionFactor = 0.85
            default:
                break
        }
        return thicknessCorrectionFactor
    }
}
