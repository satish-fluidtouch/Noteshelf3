//
//  FTPenBrushBuilder_V2.swift
//  Noteshelf
//
//  Created by Akshay on 08/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation


final class FTPenBrushBuilder_V2: FTBrushProtocol {
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
        case 1://For Retina only //NS1 1
            attributes.brushWidth = 1.5
            attributes.penVelocityFactor = 0.020
            attributes.penMinFactor = 0.50

        case 2: //NS1 2
            attributes.brushWidth = 2.7
            attributes.penVelocityFactor = 0.020
            attributes.penMinFactor = 0.45

        case 3: //NS1 3
            attributes.brushWidth = 4
            attributes.penVelocityFactor = 0.020 //0.018
            attributes.penMinFactor = 0.30

        case 4: //NS1 5
            attributes.brushWidth = 9
            attributes.penVelocityFactor = 0.018
            attributes.penMinFactor = 0.30

        case 5: //NS1 7
            attributes.brushWidth = 13
            attributes.penVelocityFactor = 0.014
            attributes.penMinFactor = 0.4

        case 6: //NS1 8
            attributes.brushWidth = 19
            attributes.penVelocityFactor = 0.010
            attributes.penMinFactor = 0.4

        case 7: //NS1 9
            attributes.brushWidth = 24
            attributes.penVelocityFactor = 0.007
            attributes.penMinFactor = 0.4

        case 8: //For Non Retina only
            attributes.brushWidth = 20
            attributes.penVelocityFactor = 0.007
            attributes.penMinFactor = 0.4

        default:
            attributes.brushWidth = 5
            attributes.penVelocityFactor = 0.018
            attributes.penMinFactor = 0.30

        }
        if UIScreen.main.scale == 1 {
            attributes.brushWidth += 1
        }

        attributes.velocitySensitive = velocitySensitive

        return attributes
    }

    static func brushImageFor(brushWidth: CGFloat, scale: CGFloat) -> UIImage {
        return self.newStylegenerateImageFromAssetsFor(brushWidth:brushWidth, scale:scale)
    }

    static func thicknessCorrectionFactorFor(brushWidth: CGFloat) -> CGFloat {
        var thicknessCorrectionFactor:CGFloat = 1
        if brushWidth < 3 {
            thicknessCorrectionFactor = 0.5
        }
        else if brushWidth == 3 {
            thicknessCorrectionFactor = 0.55
        }
        else if brushWidth == 4 {
            thicknessCorrectionFactor = 0.4
        }
        else if brushWidth >= 5 && brushWidth <= 6 {
            thicknessCorrectionFactor = 0.65
        }
        else if brushWidth == 7 {
            thicknessCorrectionFactor = 0.75
        }
        else {
            thicknessCorrectionFactor = 0.85
        }
        return thicknessCorrectionFactor
    }
}

private extension FTPenBrushBuilder_V2 {
    static func newStylegenerateImageFromAssetsFor(brushWidth:CGFloat, scale:CGFloat) -> UIImage! {
        let widthInt = Int(brushWidth)
        let roundedScale = max(scale/UIScreen.main.scale,1)
        var newScale = min(Int(roundedScale),3)

        let imageName:String

        switch (widthInt) {
            case 1:
                imageName = "brush-1"
            case 2:
                imageName = "brush-3"
            case 3:
                imageName = "brush-3"
            case 4:
                imageName = "brush-5"
                newScale = 1
            case 5:
                imageName = "brush-7"
                newScale = 1
            case 6:
                imageName = "brush-8"
                newScale = 1
            case 7:
                imageName = "brush-9"
                newScale = 1
            default:
                fatalError("Invalid Size passed v2")
        }

        let bundleImageName = String(format:"BrushAsset_v2/%@-%ld",imageName,newScale)
        guard let img = UIImage(named:bundleImageName) else {
            FTLogError("pen_image_error_v2")
            return UIImage(named:"BrushAsset_v2/brush-1-1")
        }
        return img
    }
}
