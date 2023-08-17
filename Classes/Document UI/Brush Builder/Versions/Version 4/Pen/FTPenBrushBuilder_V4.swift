//
//  FTPenBrushBuilder_V4.swift
//  Noteshelf
//
//  Created by Akshay on 08/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

final class FTPenBrushBuilder_V4: FTBrushProtocol {
    static func attributesFor(brushWidth: CGFloat, velocitySensitive: Bool) -> FTPenAttributes {
        return FTPenBrushBuilder_V3.attributesFor(brushWidth:brushWidth, velocitySensitive:velocitySensitive);
    }

    static func brushImageFor(brushWidth: CGFloat, scale: CGFloat) -> UIImage {
        return FTPenBrushBuilder_V3.brushImageFor(brushWidth:brushWidth, scale:scale);
    }

    static func thicknessCorrectionFactorFor(brushWidth: CGFloat) -> CGFloat {
        return FTPenBrushBuilder_V3.thicknessCorrectionFactorFor(brushWidth:brushWidth);
    }
}
