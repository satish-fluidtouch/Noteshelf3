//
//  FTPilotPenBrushBuilder_V4.swift
//  Noteshelf
//
//  Created by Amar on 17/01/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

final class FTPilotPenBrushBuilder_V4: FTBrushProtocol {
    static func attributesFor(brushWidth: CGFloat, velocitySensitive: Bool) -> FTPenAttributes {
        return FTPilotPenBrushBuilder_V3.attributesFor(brushWidth:brushWidth, velocitySensitive:velocitySensitive);
    }

    static func brushImageFor(brushWidth: CGFloat, scale: CGFloat) -> UIImage {
        return FTPilotPenBrushBuilder_V3.brushImageFor(brushWidth:brushWidth, scale:scale);
    }

    static func thicknessCorrectionFactorFor(brushWidth: CGFloat) -> CGFloat {
        return FTPilotPenBrushBuilder_V3.thicknessCorrectionFactorFor(brushWidth:brushWidth);
    }
}
