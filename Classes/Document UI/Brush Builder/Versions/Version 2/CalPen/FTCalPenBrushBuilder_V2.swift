//
//  FTCalPenBrushBuilder_V2.swift
//  Noteshelf
//
//  Created by Akshay on 08/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

final class FTCalPenBrushBuilder_V2: FTBrushProtocol {
    static func attributesFor(brushWidth: CGFloat, velocitySensitive: Bool) -> FTPenAttributes {
        var attributes:FTPenAttributes = FTPenAttributes()
        let widthInt = Int(brushWidth)

        attributes.curmass = 0.2
        attributes.curdrag = 0.15

        attributes.penVelocityFactor = 0.005
        attributes.penMinFactor = 0.4
        attributes.penDiffFactor = 0.3
        attributes.brushWidth = brushWidth

        switch (widthInt) {
            case 1:
                attributes.brushWidth = 2
                attributes.penVelocityFactor = 0.002
            case 2:
                attributes.brushWidth = 3
                attributes.penVelocityFactor = 0.003
            case 3:
                attributes.brushWidth = 4
                attributes.penVelocityFactor = 0.004
            case 4:
                attributes.brushWidth = 7
                attributes.penVelocityFactor = 0.005
            case 5:
                attributes.brushWidth = 9
            case 6:
                attributes.brushWidth = 12
            case 7:
                attributes.brushWidth = 16
            case 8:
                attributes.brushWidth = 23
            default:
                break
        }
        if UIScreen.main.scale == 1 {
            attributes.brushWidth += 1
        }
        attributes.velocitySensitive = velocitySensitive
        return attributes
    }

    static func brushImageFor(brushWidth: CGFloat, scale: CGFloat) -> UIImage {
        let zoomScale = max(1,Int(scale / UIScreen.main.scale))

        let brushIndex = Int(brushWidth)
        let imageName:String

        switch (brushIndex) {
        case 1:
            switch (zoomScale) {
            case 1:
                imageName = "BrushAsset_v2/cal-brush-0.5"
            case 2:
                imageName = "BrushAsset_v2/cal-brush-1"
            case 3:
                imageName = "BrushAsset_v2/cal-brush-2"
            case 4:
                imageName = "BrushAsset_v2/cal-brush-3"
            case 5:
                imageName = "BrushAsset_v2/cal-brush-4"
            default:
                imageName = "BrushAsset_v2/cal-brush-5"
            }
        case 2:
            switch (zoomScale) {
            case 1:
                imageName = "BrushAsset_v2/cal-brush-1"
            case 2:
                imageName = "BrushAsset_v2/cal-brush-2"
            case 3:
                imageName = "BrushAsset_v2/cal-brush-3"
            case 4:
                imageName = "BrushAsset_v2/cal-brush-4"
            default:
                imageName = "BrushAsset_v2/cal-brush-5"
            }
        case 3:
            switch (zoomScale) {
            case 1:
                imageName = "BrushAsset_v2/cal-brush-2"
            case 2:
                imageName = "BrushAsset_v2/cal-brush-3"
            case 3:
                imageName = "BrushAsset_v2/cal-brush-4"
            default:
                imageName = "BrushAsset_v2/cal-brush-5"
            }
        case 4:
            switch (zoomScale) {
            case 1:
                imageName = "BrushAsset_v2/cal-brush-size4-1"
            case 2:
                imageName = "BrushAsset_v2/cal-brush-size4-2"
            default:
                imageName = "BrushAsset_v2/cal-brush-size4-3"
            }
        case 5:
            imageName = "BrushAsset_v2/cal-brush-size5-1"
        case 6:
            imageName = "BrushAsset_v2/cal-brush-size6-1"
        case 7:
            imageName = "BrushAsset_v2/cal-brush-size7-1"
        default:
            imageName = "BrushAsset_v2/cal-brush-5"
        }
        guard let image:UIImage = UIImage(named:imageName) else {
            return UIImage(named:"BrushAsset_v2/cal-brush-5")!
        }
        return image
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

    //Utility Method
    static func scaleForBrushWidth(_ brushWidth:CGFloat, scale inScale:CGFloat) -> CGFloat {
        var scale:CGFloat = 1
        let screenScaleFactor:CGFloat = UIScreen.main.scale
        let acutualScale:CGFloat = inScale/screenScaleFactor
        
        let brushIndex = Int(brushWidth)
        switch (brushIndex) {
        case 1:
            if acutualScale <= 0.9 {
                scale = 1
            }
            else if acutualScale <= 1.5 {
                scale = 2
            }
            else if acutualScale <= 2.5 {
                scale = 3
            }
            else if acutualScale <= 3.5 {
                scale = 4
            }
            else if acutualScale <= 4.5 {
                scale = 5
            }
            else {
                scale = 6
            }
        case 2:
            if acutualScale <= 1.5 {
                scale = 1
            }
            else if acutualScale <= 2.5 {
                scale = 2
            }
            else if acutualScale <= 3.5 {
                scale = 3
            }
            else if acutualScale <= 4.5 {
                scale = 4
            }
            else {
                scale = 5
            }
        case 3:
            if acutualScale <= 1.5 {
                scale = 1
            }
            else if acutualScale <= 2.5 {
                scale = 2
            }
            else if acutualScale <= 3.5 {
                scale = 3
            }
            else {
                scale = 4
            }
        default:
            if acutualScale > 1.5  && acutualScale <= 2.5
            {scale = 2}
            else if acutualScale > 2.5
            {scale = 3}
        }
        return scale
    }
}
