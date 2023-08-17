//
//  FTLaserPenPointerBrushBuilder_v5.swift
//  Noteshelf
//
//  Created by Amar on 06/05/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTLaserPenPointerBrushBuilder_v5: FTBrushProtocol {
    static func brushImageFor(brushWidth: CGFloat, scale: CGFloat) -> UIImage {
        let imgName: String;
        if brushWidth == FTLaserPenThickness.secondary.rawValue {
            imgName = "laser_pointer_innerCore";
        }
        else {
            imgName = "laser_pointer";
        }
        let bundleImageName = String(format: "BrushAsset_v5/%@", imgName);
        guard let img = UIImage(named:bundleImageName) else {
            return UIImage(named: "BrushAsset_v3/brush-1-1")!
        }
        return img;
    }
    
    static func thicknessCorrectionFactorFor(brushWidth: CGFloat) -> CGFloat {
        return FTLaserPenBrushBuilder_v5.thicknessCorrectionFactorFor(brushWidth: brushWidth);
    }
    
    static func attributesFor(brushWidth: CGFloat, velocitySensitive: Bool) -> FTPenAttributes {
        var attributes = FTLaserPenBrushBuilder_v5.attributesFor(brushWidth: brushWidth, velocitySensitive: false);
        attributes.brushWidth = 44 * UIScreen.main.scale;
        return attributes;
    }
}
