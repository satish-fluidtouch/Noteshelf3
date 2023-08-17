//
//  FTPenBrushBuilder_v5.swift
//  Noteshelf
//
//  Created by Akshay on 05/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

final class FTPenBrushBuilder_v5: FTBrushProtocol {
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
        if Int(brushWidth) == 0 {
            return 0.4
        } else {
            return FTPenBrushBuilder_V4.thicknessCorrectionFactorFor(brushWidth: brushWidth)
        }
    }
}

//MARK: Zero Size
private extension FTPenBrushBuilder_v5 {

    static func _attributesFor(brushWidth: CGFloat, velocitySensitive: Bool) -> FTPenAttributes {
        var attributes = FTPenAttributes();
        if(Int(brushWidth) == 0) {
            attributes.curmass = 0.2;
            attributes.curdrag = 0.14;
            attributes.penDiffFactor = 0.10;
            attributes.velocitySensitive = velocitySensitive

            //Zero size
            attributes.penVelocityFactor = 0.020;
            attributes.penMinFactor = 0.1;
            attributes.brushWidth = 0.1;

        }
        else {
            attributes = FTPenBrushBuilder_V4.attributesFor(brushWidth: brushWidth, velocitySensitive: velocitySensitive);
        }
        return attributes;
    }

    static func _brushImageFor(brushWidth: CGFloat, scale: CGFloat) -> UIImage {
        let widthInt = Int(brushWidth);
        let brushImage: UIImage
        if (widthInt == 0) {
            var newScale : Int = Int(max(scale/UIScreen.main.scale,1));
            newScale = min(newScale,3);
            //For Zero size, we're applying the same image as One size.
            brushImage = UIImage(named: "BrushAsset_v3/brush-0-\(newScale)")!
            #if DEBUG
            print("Pen Passing Zero image")
            #endif
        } else {
            brushImage = FTPenBrushBuilder_V4.brushImageFor(brushWidth: brushWidth, scale: scale)
        }
        return brushImage
    }
}
