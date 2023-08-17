//
//  FTCalPenBrushBuilder_v5.swift
//  Noteshelf
//
//  Created by Akshay on 05/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

final class FTCalPenBrushBuilder_v5: FTBrushProtocol {

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
        return FTCalPenBrushBuilder_V4.thicknessCorrectionFactorFor(brushWidth: brushWidth)
    }

    static func scaleForBrushWidth(_ brushWidth:CGFloat, scale inScale:CGFloat) -> CGFloat {
        FTCalPenBrushBuilder_V4.scaleForBrushWidth(brushWidth, scale: inScale)
    }
}

//MARK: - Zero Size
private extension FTCalPenBrushBuilder_v5 {

    static func _attributesFor(brushWidth: CGFloat, velocitySensitive: Bool) -> FTPenAttributes {
        var attributes = FTPenAttributes();
        if(Int(brushWidth) == 0) {
            attributes.velocitySensitive = velocitySensitive
            attributes.curmass = 0.2;
            attributes.curdrag = 0.15;
            attributes.penDiffFactor = 0.3;

            //Zero size
            attributes.penVelocityFactor = 0.005;
            attributes.penMinFactor = 0.4;
            attributes.brushWidth = 1;

        }
        else {
            attributes = FTCalPenBrushBuilder_V4.attributesFor(brushWidth: brushWidth, velocitySensitive: velocitySensitive);
        }
        return attributes;
    }

    static func _brushImageFor(brushWidth: CGFloat, scale: CGFloat) -> UIImage {
        let widthInt = Int(brushWidth);
        let brushImage: UIImage
        if (widthInt == 0) {
            let newScale : Int = Int(max(scale/UIScreen.main.scale,1));
            let imageName: String
            switch (newScale) {
                case 1:
                    imageName = "BrushAsset_v3/cal-brush-0.5";
                case 2:
                    imageName = "BrushAsset_v3/cal-brush-1";
                case 3:
                    imageName = "BrushAsset_v3/cal-brush-2";
                case 4:
                    imageName = "BrushAsset_v3/cal-brush-3";
                case 5:
                    imageName = "BrushAsset_v3/cal-brush-4";
                default:
                    imageName = "BrushAsset_v3/cal-brush-5";
            }
            brushImage = UIImage(named: imageName)!
            #if DEBUG
            print("Pen Passing Zero image")
            #endif
        } else {
            brushImage = FTCalPenBrushBuilder_V4.brushImageFor(brushWidth: brushWidth, scale: scale)            
        }
        return brushImage
    }
}
