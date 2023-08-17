//
//  FTBrushBuilder_v1.swift
//  Noteshelf
//
//  Created by Akshay on 08/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

final class FTBrushBuilder_v1: FTBrushBuilderVersion {
    var version: Int = 1

    func penAttributesFor(penType: FTPenType, brushWidth: CGFloat, isShapeTool: Bool) -> FTPenAttributes {
        let attributes:FTPenAttributes
        switch (penType) {
            case .pen:
                attributes = FTPenBrushBuilder_V1.attributesFor(brushWidth:brushWidth, velocitySensitive:true)
            case .pencil:
                attributes = FTPencilBrushBuilder_V1.attributesFor(brushWidth:brushWidth, velocitySensitive:false)
            case .caligraphy:

                attributes = FTCalPenBrushBuilder_V1.attributesFor(brushWidth:brushWidth, velocitySensitive:true)
            case .highlighter:

                attributes = FTMarkerBrushBuilder_V1.attributesFor(brushWidth:brushWidth, velocitySensitive:false)
            default:
                fatalError("Invalid penType sent to brush builder")
        }
        return attributes
    }

    func metalBrushTextureFor(penType: FTPenType, brushWidth: CGFloat, scale inScale: CGFloat) -> MTLTexture? {
        let scale:CGFloat = self.appropriateScaleForPenType(penType, brushWidth:brushWidth, scale:inScale)
        let props = FTBrushTextureProps(version: self.version, penType: penType, brushWidth: Int(brushWidth), scale: Int(scale))
        var texture = FTBrushTextures.brushTexture(for: props)

        if nil == texture {
            let dotImage:UIImage = self.imageForPenType(penType, brushWidth:brushWidth, scale:scale)
            if let bTexture = FTMetalUtils.texture(from:dotImage) {
                texture = bTexture
                FTBrushTextures.cacheBrushTexture(bTexture, for: props)
            }
        }
        return texture
    }

    func thicknessCorrectionFactor(penType: FTPenType, brushWidth: CGFloat) -> CGFloat {
        var thicknessCorrectionFactor:CGFloat = 1
        if brushWidth <= 3 {
            thicknessCorrectionFactor = 0.5
        }
        else if brushWidth > 3 && brushWidth <= 6 {
            thicknessCorrectionFactor = 0.65
        }
        else {
            thicknessCorrectionFactor = 0.85
        }
        return thicknessCorrectionFactor
    }

}

private extension FTBrushBuilder_v1 {

    func appropriateScaleForPenType(_ penType:FTPenType, brushWidth:CGFloat, scale inScale:CGFloat) -> CGFloat {
        let screenScaleFactor:CGFloat = UIScreen.main.scale
        var scale:CGFloat = 1
        if inScale > 1.5*screenScaleFactor  && inScale <= 2.5*screenScaleFactor
        {scale = 2}
        else if inScale > 2.5*screenScaleFactor
        {scale = 3}
        return  scale
    }

    func imageForPenType(_ penType:FTPenType, brushWidth:CGFloat, scale:CGFloat) -> UIImage! {
        let screenScaleFactor:CGFloat = UIScreen.main.scale
        let dotImage:UIImage
        switch (penType) {
        case .pen:
            dotImage = FTPenBrushBuilder_V1.brushImageFor(brushWidth: brushWidth, scale:scale * screenScaleFactor)

        case .pencil:
            dotImage = FTPencilBrushBuilder_V1.brushImageFor(brushWidth: brushWidth, scale:scale * screenScaleFactor)

        case .caligraphy:
            dotImage = FTCalPenBrushBuilder_V1.brushImageFor(brushWidth: brushWidth, scale:scale * screenScaleFactor)

        case .highlighter:
            dotImage = FTMarkerBrushBuilder_V1.brushImageFor(brushWidth: brushWidth, scale:scale * screenScaleFactor)

        default:
            fatalError("Invalid penType sent to brush builder")
        }
        return dotImage
    }
}
