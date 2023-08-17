//
//  FTBrushBuilder_v5.swift
//  Noteshelf
//
//  Created by Akshay on 05/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

final class FTBrushBuilder_v5: FTBrushBuilderVersion {
    var version: Int = 5

    func penAttributesFor(penType: FTPenType, brushWidth: CGFloat, isShapeTool: Bool) -> FTPenAttributes {

        let attributes : FTPenAttributes
        switch penType {
        case .pen:
            attributes = FTPenBrushBuilder_v5.attributesFor(brushWidth: brushWidth, velocitySensitive: true)
        case .caligraphy:
            attributes = FTCalPenBrushBuilder_v5.attributesFor(brushWidth: brushWidth, velocitySensitive: true)

        case .pilotPen:
            attributes = FTPilotPenBrushBuilder_v5.attributesFor(brushWidth: brushWidth, velocitySensitive: true)

        case .pencil:
            attributes = FTPencilBrushBuilder_v5.attributesFor(brushWidth: brushWidth, velocitySensitive: false)

        case .highlighter:
            attributes = FTDefaultMarkerBrushBuilder_v5.attributesFor(brushWidth: brushWidth, velocitySensitive: false)

        case .flatHighlighter:
            attributes = FTSquareMarkerBrushBuilder_v5.attributesFor(brushWidth: brushWidth, velocitySensitive: false)

        case .laser:
            attributes = FTLaserPenBrushBuilder_v5.attributesFor(brushWidth: brushWidth, velocitySensitive: false)
            
        case .laserPointer:
            attributes = FTLaserPenPointerBrushBuilder_v5.attributesFor(brushWidth: brushWidth, velocitySensitive: false)
            
        default:
            fatalError("Invalid Pen type Passed")
        }
        #if DEBUG
        //print("🖋 V5",penType, brushWidth, attributes)
        #endif
        return attributes
    }

    func metalBrushTextureFor(penType: FTPenType, brushWidth: CGFloat, scale inScale: CGFloat) -> MTLTexture? {
        let scale = appropriateScale(penType: penType, brushWidth: brushWidth, scale: inScale)
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
        let thickness : CGFloat
        switch penType {
        case .pen:
            thickness =  FTPenBrushBuilder_v5.thicknessCorrectionFactorFor(brushWidth: brushWidth)
        case .caligraphy:
            thickness = FTCalPenBrushBuilder_v5.thicknessCorrectionFactorFor(brushWidth: brushWidth)
        case .pilotPen:
            thickness = FTPilotPenBrushBuilder_v5.thicknessCorrectionFactorFor(brushWidth: brushWidth)
        case .pencil:
            thickness = FTPencilBrushBuilder_v5.thicknessCorrectionFactorFor(brushWidth: brushWidth)
        case .highlighter:
            thickness = FTDefaultMarkerBrushBuilder_v5.thicknessCorrectionFactorFor(brushWidth: brushWidth)
        case .flatHighlighter:
            thickness = FTSquareMarkerBrushBuilder_v5.thicknessCorrectionFactorFor(brushWidth: brushWidth)
        case .laser,.laserPointer:
            thickness = FTLaserPenBrushBuilder_v5.thicknessCorrectionFactorFor(brushWidth: brushWidth);
        default:
            fatalError("Invalid Pen type Passed")
        }
        return thickness
    }
}

private extension FTBrushBuilder_v5 {

    func appropriateScale(penType: FTPenType, brushWidth: CGFloat, scale inScale: CGFloat) -> CGFloat {
        let screenScaleFactor = UIScreen.main.scale;
        var scale: CGFloat = 1;
        switch (penType) {
        case .caligraphy:
            scale = FTCalPenBrushBuilder_v5.scaleForBrushWidth(brushWidth, scale: inScale)
        default:
            if(inScale > 1.5*screenScaleFactor  && inScale <= 2.5*screenScaleFactor) {
                scale = 2;
            } else if(inScale > 2.5*screenScaleFactor) {
                scale = 3;
            }
        }
        return scale
    }

    func imageForPenType(_ penType: FTPenType, brushWidth: CGFloat, scale: CGFloat) -> UIImage {
        let image : UIImage
        let screenScaleFactor:CGFloat = UIScreen.main.scale
        switch penType {
        case .pen:
            image =  FTPenBrushBuilder_v5.brushImageFor(brushWidth: brushWidth, scale: scale*screenScaleFactor)
        case .caligraphy:
            image = FTCalPenBrushBuilder_v5.brushImageFor(brushWidth: brushWidth, scale: scale*screenScaleFactor)
        case .pilotPen:
            image = FTPilotPenBrushBuilder_v5.brushImageFor(brushWidth: brushWidth, scale: scale*screenScaleFactor)
        case .pencil:
            image = FTPencilBrushBuilder_v5.brushImageFor(brushWidth: brushWidth, scale: scale*screenScaleFactor)
        case .highlighter:
            image = FTDefaultMarkerBrushBuilder_v5.brushImageFor(brushWidth: brushWidth, scale: scale*screenScaleFactor)
        case .flatHighlighter:
            image = FTSquareMarkerBrushBuilder_v5.brushImageFor(brushWidth: brushWidth, scale: scale*screenScaleFactor)
        case .laser:
            image = FTLaserPenBrushBuilder_v5.brushImageFor(brushWidth: brushWidth, scale: scale)
        case .laserPointer:
            image = FTLaserPenPointerBrushBuilder_v5.brushImageFor(brushWidth: brushWidth, scale: scale)
        default:
            fatalError("Invalid Pen type Passed")
        }
        return image
    }


//MARK:- Experrimental
//    func classTypeFor<T : FTBrushProtocol.Type>(penType: FTPenType) -> T {
//        switch penType {
//        case .pen:
//            return FTPenBrushBuilder_v5
//        case .caligraphy:
//            return FTCalPenBrushBuilder_v5
//        case .pilotPen:
//            return FTPilotPenBrushBuilder_v5
//        case .pencil:
//            return FTPencilBrushBuilder_v5
//        case .highlighter:
//            return FTDefaultMarkerBrushBuilder_v5
//        case .flatHighlighter:
//            return FTSquareMarkerBrushBuilder_v5
//        default:
//            fatalError("Invalid Pen type Passed")
//        }
//    }
}
