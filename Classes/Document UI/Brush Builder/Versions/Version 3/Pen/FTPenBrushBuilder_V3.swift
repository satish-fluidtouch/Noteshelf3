//
//  FTPenBrushBuilder_V3.swift
//  Noteshelf
//
//  Created by Akshay on 08/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

final class FTPenBrushBuilder_V3: FTBrushProtocol {
    static func attributesFor(brushWidth: CGFloat, velocitySensitive: Bool) -> FTPenAttributes {

        let widthInt = Int(brushWidth)

        var attributes = FTPenAttributes()
        attributes.curmass = 0.2
        attributes.curdrag = 0.14
        attributes.penDiffFactor = 0.30
        attributes.penVelocityFactor = 0.008
        attributes.penMinFactor = 0.2
        attributes.brushWidth = CGFloat(widthInt)

        switch (widthInt) {
            case 1:
                attributes.brushWidth = 1.5
                attributes.penVelocityFactor = 0.020
                attributes.penMinFactor = 0.50
            case 2:
                attributes.brushWidth = 2.3
                attributes.penVelocityFactor = 0.020
                attributes.penMinFactor = 0.45
            case 3:
                attributes.brushWidth = 3.2
                attributes.penVelocityFactor = 0.020
                attributes.penMinFactor = 0.45
            case 4:
                attributes.brushWidth = 4
                attributes.penVelocityFactor = 0.020
                attributes.penMinFactor = 0.30
            case 5:
                attributes.brushWidth = 7
                attributes.penVelocityFactor = 0.018
                attributes.penMinFactor = 0.30
            case 6:
                attributes.brushWidth = 13
                attributes.penVelocityFactor = 0.014
                attributes.penMinFactor = 0.4
            case 7:
                attributes.brushWidth = 19
                attributes.penVelocityFactor = 0.010
                attributes.penMinFactor = 0.4
            case 8:
                attributes.brushWidth = 24
                attributes.penVelocityFactor = 0.007
                attributes.penMinFactor = 0.4
            default:
                attributes.brushWidth = 5
                attributes.penVelocityFactor = 0.018
                attributes.penMinFactor = 0.30
        }
        if UIScreen.main.scale == 1
        {
            attributes.brushWidth += 1
        }

        attributes.velocitySensitive = velocitySensitive

        return attributes

    }

    static func brushImageFor(brushWidth: CGFloat, scale: CGFloat) -> UIImage {
        let widthInt = Int(brushWidth)
        let roundedScale = max(scale/UIScreen.main.scale,1)
        var newScale = min(Int(roundedScale),3)
        let imageName:String
        switch (widthInt) {
        case 1:
            imageName = "brush-1"
        case 2:
            imageName = "brush-2"
        case 3:
            imageName = "brush-3"
        case 4:
            imageName = "brush-4"
        case 5:
            imageName = "brush-5"
            newScale = 1
        case 6:
            imageName = "brush-7"
            newScale = 1
        case 7:
            imageName = "brush-8"
            newScale = 1
        case 8:
            imageName = "brush-9"
            newScale = 1
        default:
            imageName = "brush-1"
        }

        let bundleImageName:String = String(format:"BrushAsset_v3/%@-%ld",imageName,newScale)
        guard let img = UIImage(named:bundleImageName) else {
            return UIImage(named: "BrushAsset_v3/brush-1-1")!
        }
        return img
    }

    static func thicknessCorrectionFactorFor(brushWidth: CGFloat) -> CGFloat {
        var thicknessCorrectionFactor:CGFloat = 1
        if brushWidth <= 3 {
            thicknessCorrectionFactor = 0.5
        }
        else if brushWidth == 4 {
            thicknessCorrectionFactor = 0.55
        }
        else if brushWidth >= 5 && brushWidth < 7 {
            thicknessCorrectionFactor = 0.75
        }
        else if brushWidth >= 7 && brushWidth <= 8 {
            thicknessCorrectionFactor = 0.85
        }
        else {
            thicknessCorrectionFactor = 0.85
        }
        return thicknessCorrectionFactor
    }
}
