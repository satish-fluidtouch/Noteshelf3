//
//  FTSquareMarkerBrushBuilder_v5.swift
//  Noteshelf
//
//  Created by Akshay on 05/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

final class FTSquareMarkerBrushBuilder_v5: FTBrushProtocol {
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
        return FTSquareMarkerBrushBuilder_V4.brushImageFor(brushWidth: brushWidth, scale: scale)
    }

    static func thicknessCorrectionFactorFor(brushWidth: CGFloat) -> CGFloat {
        return FTSquareMarkerBrushBuilder_V4.thicknessCorrectionFactorFor(brushWidth: brushWidth)
    }
}

//MARK: Zero Size
private extension FTSquareMarkerBrushBuilder_v5 {
    //Currenlty we're not supporting Zero size for Highlighters
    static func _attributesFor(brushWidth: CGFloat, velocitySensitive: Bool) -> FTPenAttributes {
        let attributes = FTSquareMarkerBrushBuilder_V4.attributesFor(brushWidth: brushWidth, velocitySensitive: velocitySensitive);
        return attributes;
    }
}
