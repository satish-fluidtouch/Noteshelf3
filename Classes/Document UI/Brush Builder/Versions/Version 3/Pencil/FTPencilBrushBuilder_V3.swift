//
//  FTPencilBrushBuilder_V3.swift
//  Noteshelf
//
//  Created by Akshay on 08/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

final class FTPencilBrushBuilder_V3: FTBrushProtocol {
    static func attributesFor(brushWidth: CGFloat, velocitySensitive: Bool) -> FTPenAttributes {
        var attributes = FTPenAttributes()
        let widthInt = Int(brushWidth)
        switch (widthInt) {
        case 8:
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
        let dotImage:UIImage
        if contentScaleFactor > 1.0 {
            dotImage = UIImage(named:"BrushAsset_v3/pencil-brush-large")!
        }else{
            dotImage = UIImage(named:"BrushAsset_v3/pencil-brush-small")!
        }
        return dotImage
    }

    static func thicknessCorrectionFactorFor(brushWidth: CGFloat) -> CGFloat {
        var thicknessCorrectionFactor:CGFloat = 1
        if brushWidth <= 4
        {thicknessCorrectionFactor = 0.5}
        else if brushWidth > 4 && brushWidth <= 8
        {thicknessCorrectionFactor = 0.65}
        else
        {thicknessCorrectionFactor = 0.85}
        return thicknessCorrectionFactor
    }
}
