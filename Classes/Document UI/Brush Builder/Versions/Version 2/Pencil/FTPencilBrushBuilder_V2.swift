//
//  FTPencilBrushBuilder_V2.swift
//  Noteshelf
//
//  Created by Akshay on 08/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

final class FTPencilBrushBuilder_V2: FTBrushProtocol {
    static func attributesFor(brushWidth: CGFloat, velocitySensitive: Bool) -> FTPenAttributes {
        var attributes:FTPenAttributes = FTPenAttributes()
        let widthInt = Int(brushWidth)
        switch (widthInt) {
            case 6:
                attributes.brushWidth = 7
            case 7:
                attributes.brushWidth = 9
            default:
                attributes.brushWidth = CGFloat(widthInt)
        }
        attributes.brushWidth = brushWidth+1

        attributes.velocitySensitive = false
        return attributes
    }

    static func brushImageFor(brushWidth: CGFloat, scale: CGFloat) -> UIImage {
        let contentScaleFactor:CGFloat = UIScreen.main.scale
        var dotImage:UIImage
        if contentScaleFactor > 1.0 {
            dotImage = UIImage(named:"BrushAsset_v2/pencil-brush-large")!
        } else {
            dotImage = UIImage(named:"BrushAsset_v2/pencil-brush-small")!
        }
        return dotImage
    }

    static func thicknessCorrectionFactorFor(brushWidth: CGFloat) -> CGFloat {
        var thicknessCorrectionFactor:CGFloat = 1
        if brushWidth <= 3
            {thicknessCorrectionFactor = 0.5}
        else if brushWidth > 3 && brushWidth <= 6
            {thicknessCorrectionFactor = 0.65}
        else
            {thicknessCorrectionFactor = 0.85}
        return thicknessCorrectionFactor
    }
}
