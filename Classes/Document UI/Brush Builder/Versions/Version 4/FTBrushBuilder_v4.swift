//
//  FTBrushBuilder_v4.swift
//  Noteshelf
//
//  Created by Akshay on 08/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

final class FTBrushBuilder_v4: FTBrushBuilderVersion {
    var version: Int = 4

    func penAttributesFor(penType: FTPenType, brushWidth: CGFloat, isShapeTool: Bool) -> FTPenAttributes {
        let attributes : FTPenAttributes
        switch (penType) {
            case .pen:
                attributes = FTPenBrushBuilder_V4.attributesFor(brushWidth:brushWidth, velocitySensitive:true)

            case .pencil:
                attributes = FTPencilBrushBuilder_V4.attributesFor(brushWidth:brushWidth, velocitySensitive:false)

            case .caligraphy:
                attributes = FTCalPenBrushBuilder_V4.attributesFor(brushWidth:brushWidth, velocitySensitive:true)

            case .highlighter:
                attributes = FTDefaultMarkerBrushBuilder_V4.attributesFor(brushWidth:brushWidth, velocitySensitive:false)

            case .pilotPen:
                attributes = FTPilotPenBrushBuilder_V4.attributesFor(brushWidth:brushWidth, velocitySensitive:true)

            case .flatHighlighter:
                attributes = FTSquareMarkerBrushBuilder_V4.attributesFor(brushWidth: brushWidth, velocitySensitive:false)
            default:
                fatalError("Invalid Brush type Passed")
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
        switch (penType) {
            case .pen:
                thicknessCorrectionFactor = FTPenBrushBuilder_V4.thicknessCorrectionFactorFor( brushWidth:brushWidth)

            case .caligraphy:
                thicknessCorrectionFactor = FTCalPenBrushBuilder_V4.thicknessCorrectionFactorFor( brushWidth:brushWidth)

            case .highlighter:
                thicknessCorrectionFactor = FTDefaultMarkerBrushBuilder_V4.thicknessCorrectionFactorFor( brushWidth:brushWidth)

            case .pencil:
                thicknessCorrectionFactor = FTPencilBrushBuilder_V4.thicknessCorrectionFactorFor( brushWidth:brushWidth)

            case .pilotPen:

                thicknessCorrectionFactor = FTPilotPenBrushBuilder_V4.thicknessCorrectionFactorFor( brushWidth:brushWidth)


            case .flatHighlighter:

                thicknessCorrectionFactor = FTSquareMarkerBrushBuilder_V4.thicknessCorrectionFactorFor( brushWidth:brushWidth)


            default:
                break
        }
        return thicknessCorrectionFactor
    }
}

private extension FTBrushBuilder_v4 {

    func appropriateScaleForPenType(_ penType:FTPenType, brushWidth: CGFloat, scale inScale:CGFloat) -> CGFloat {
        let screenScaleFactor:CGFloat = UIScreen.main.scale
        var scale:CGFloat = 1
        switch (penType) {
            case .caligraphy:
                scale = FTCalPenBrushBuilder_V4.scaleForBrushWidth(brushWidth, scale:inScale)

            default:
                if inScale > 1.5*screenScaleFactor  && inScale <= 2.5*screenScaleFactor
                    {scale = 2}
                else if inScale > 2.5*screenScaleFactor
                    {scale = 3}
                
        }
        return scale
    }

    func imageForPenType(_ penType:FTPenType, brushWidth:CGFloat, scale:CGFloat) -> UIImage {
        let dotImage:UIImage
        let screenScaleFactor:CGFloat = UIScreen.main.scale
        switch (penType) {
            case .pen:

                dotImage = FTPenBrushBuilder_V4.brushImageFor(brushWidth:brushWidth,
                                                                     scale:scale * screenScaleFactor)

            case .pencil:

                dotImage = FTPencilBrushBuilder_V4.brushImageFor(brushWidth:brushWidth,
                                                                        scale:scale * screenScaleFactor)

            case .caligraphy:

                dotImage = FTCalPenBrushBuilder_V4.brushImageFor(brushWidth:brushWidth,
                                                                        scale:scale * screenScaleFactor)

            case .highlighter:

                dotImage = FTDefaultMarkerBrushBuilder_V4.brushImageFor(brushWidth:brushWidth,
                                                                               scale:scale * screenScaleFactor)

            case .pilotPen:

                dotImage = FTPilotPenBrushBuilder_V4.brushImageFor(brushWidth:brushWidth,
                                                                               scale:scale*screenScaleFactor)

            case .flatHighlighter:

                dotImage = FTSquareMarkerBrushBuilder_V4.brushImageFor(brushWidth:brushWidth,
                                                                                   scale:scale * screenScaleFactor)

            default:
                fatalError("Invalid penType sent to brush builder")
        }
        return dotImage
    }
}
