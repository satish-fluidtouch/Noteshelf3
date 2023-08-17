//
//  FTLaserPenBrushBuilder_v5.swift
//  Noteshelf
//
//  Created by Amar on 29/04/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

enum FTLaserPenThickness: CGFloat {
    case primary,secondary;
}

class FTLaserPenBrushBuilder_v5: FTBrushProtocol {
    static func attributesFor(brushWidth: CGFloat, velocitySensitive: Bool) -> FTPenAttributes {
        var attributes = FTPenAttributes()
        attributes.curmass = 0.2
        attributes.curdrag = 0.14
        attributes.penDiffFactor = 0.30
        attributes.brushWidth = 10
        attributes.penVelocityFactor = 0.007
        attributes.penMinFactor = 0.4
        attributes.velocitySensitive = false
        return attributes
    }
    
    static func brushImageFor(brushWidth: CGFloat, scale: CGFloat) -> UIImage {
        let imageName: String;
        if brushWidth == FTLaserPenThickness.secondary.rawValue {
            imageName = "laser_stroke_innerCore";
        }
        else {
            imageName = "laser_stroke";
        }
        
        let bundleImageName = String(format:"BrushAsset_v5/%@",imageName)
        guard let img = UIImage(named:bundleImageName) else {
            return UIImage(named: "BrushAsset_v3/brush-1-1")!
        }
        return img
    }
    
    static func thicknessCorrectionFactorFor(brushWidth: CGFloat) -> CGFloat {
        return brushWidth;
    }
}
