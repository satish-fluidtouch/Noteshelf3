//
//  FTPencilBrushBuilder_v5.swift
//  Noteshelf
//
//  Created by Akshay on 05/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

final class FTPencilBrushBuilder_v5: FTBrushProtocol {
    static func attributesFor(brushWidth: CGFloat, velocitySensitive: Bool) -> FTPenAttributes {
        let minBrushWidth = floor(brushWidth)
        let maxBrushWidth = ceil(brushWidth)
        let attributes : FTPenAttributes
        //Treated as intermediate value
        if minBrushWidth != maxBrushWidth {
            let minAttri = _attributesFor(brushWidth: minBrushWidth, velocitySensitive: velocitySensitive)
            let maxAttri = _attributesFor(brushWidth: maxBrushWidth, velocitySensitive: velocitySensitive)

            attributes = FTBrushBuilder.normalize(brushWidth: brushWidth, min: minAttri, max: maxAttri)
        } else {
            attributes = _attributesFor(brushWidth: brushWidth, velocitySensitive: velocitySensitive)
        }

        return attributes
    }

    static func brushImageFor(brushWidth: CGFloat, scale: CGFloat) -> UIImage {
        return _brushImageFor(brushWidth: brushWidth, scale: scale)
    }

    static func thicknessCorrectionFactorFor(brushWidth: CGFloat) -> CGFloat {
        return FTPencilBrushBuilder_V4.thicknessCorrectionFactorFor(brushWidth: brushWidth)
    }
}

//MARK: Zero Size
private extension FTPencilBrushBuilder_v5 {

    static func _attributesFor(brushWidth: CGFloat, velocitySensitive: Bool) -> FTPenAttributes {
        var attributes = FTPenAttributes();
        if(Int(brushWidth) == 0) {
            attributes.curmass = 0.2;
            attributes.curdrag = 0.14;
            attributes.penDiffFactor = 0.30;
            attributes.velocitySensitive = velocitySensitive

            //Zero size
            attributes.penVelocityFactor = 0.4;
            attributes.penMinFactor = 0.4;
            attributes.brushWidth = 0.25;

            //We're incrementing the size by 1 for all pencil sizes.
            attributes.brushWidth += 1;

        }
        else {
            attributes = FTPencilBrushBuilder_V4.attributesFor(brushWidth: brushWidth, velocitySensitive: velocitySensitive);
        }
        return attributes;
    }

    static func _brushImageFor(brushWidth: CGFloat, scale: CGFloat) -> UIImage {
        let widthInt = Int(brushWidth);
        let brushImage: UIImage
        if (widthInt == 0) {
            brushImage = UIImage(named: "BrushAsset_v3/pencil-brush-small")!
            #if DEBUG
            print("Pen Passing Zero image")
            #endif
        } else {
            brushImage = FTPencilBrushBuilder_V4.brushImageFor(brushWidth: brushWidth, scale: scale)
        }
        return brushImage
    }
}
