//
//  FTPilotPenBrushBuilder_V3.swift
//  Noteshelf
//
//  Created by Amar on 17/01/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

let debugMode = false;

@objcMembers class FTPilotPenBrushBuilder_V3 : FTBrushProtocol {
    static func attributesFor(brushWidth: CGFloat, velocitySensitive: Bool) -> FTPenAttributes {
        let widthInt = Int(brushWidth);

        var attributes = FTPenAttributes();
        attributes.curmass = 0.2;
        attributes.curdrag = 0.14;
        attributes.penDiffFactor = 0.30;
        attributes.penVelocityFactor = 0.008;
        attributes.penMinFactor = 0.2;
        attributes.brushWidth = CGFloat(widthInt);

        switch (widthInt) {
        case 1:
            attributes.brushWidth = 1.5;
            attributes.penVelocityFactor = 0.007;//0.020;
            attributes.penMinFactor = 0.50;
        case 2:
            attributes.brushWidth = 2.3//2.7;
            attributes.penVelocityFactor = 0.007;//0.020;
            attributes.penMinFactor = 0.45;
        case 3:
            attributes.brushWidth = 3.2;//4;
            attributes.penVelocityFactor = 0.007;//0.020;
            attributes.penMinFactor = 0.45;
        case 4:
            attributes.brushWidth = 4;
            attributes.penVelocityFactor = 0.007;//0.018;
            attributes.penMinFactor = 0.30;
        case 5:
            attributes.brushWidth = 7;
            attributes.penVelocityFactor = 0.007;//0.018;
            attributes.penMinFactor = 0.30;
        case 6:
            attributes.brushWidth = 13;
            attributes.penVelocityFactor = 0.007;//0.014;
            attributes.penMinFactor = 0.4;
        case 7:
            attributes.brushWidth = 19;
            attributes.penVelocityFactor = 0.007;//0.010;
            attributes.penMinFactor = 0.4;
        case 8:
            attributes.brushWidth = 24;
            attributes.penVelocityFactor = 0.007;
            attributes.penMinFactor = 0.4;
        default:
            attributes.brushWidth = 4;
            attributes.penVelocityFactor = 0.007;//0.018;
            attributes.penMinFactor = 0.30;
        }
        if (UIScreen.main.scale == 1)
        {
            attributes.brushWidth += 1;
        }

        attributes.velocitySensitive = velocitySensitive;

        return attributes;
    }

    static func brushImageFor(brushWidth: CGFloat, scale: CGFloat) -> UIImage {
        let imgName : String;

        let newScale = max(1,Int(scale / UIScreen.main.scale))

        if(brushWidth >= 5) {
            if(brushWidth <= 6) {
                if(newScale == 1) {
                    imgName = "BrushAsset_v3/default_pen";
                }
                else {
                    imgName = "BrushAsset_v3/default_pen-1";
                }
            }
            else {
                imgName = "BrushAsset_v3/default_pen-1";
            }
        }
        else {
            if(brushWidth == 1) {
                if(newScale == 1) {
                    imgName = "BrushAsset_v3/pen1-1";
                }
                else if(newScale == 2) {
                    imgName = "BrushAsset_v3/pen1-2";
                }
                else {
                    imgName = "BrushAsset_v3/pen1-3";
                }
            }
            else {
                if(newScale <= 1) { //To Support Backward compatability for variable size pens
                    if(brushWidth == 2) {
                        imgName = "BrushAsset_v3/pen2-1-1";
                    }
                    else {
                        imgName = "BrushAsset_v3/pen2-1";
                    }
                }
                else if(newScale == 2) {
                    imgName = "BrushAsset_v3/pen2-2";
                }
                else {
                    imgName = "BrushAsset_v3/pen2-3";
                }
            }
        }
        guard let image = UIImage(named: imgName) else {
            return UIImage(named: "BrushAsset_v3/default_pen")!
        }
        return image;
    }

    static func thicknessCorrectionFactorFor(brushWidth: CGFloat) -> CGFloat {
        var thicknessCorrectionFactor = CGFloat(1);
        if(brushWidth <= 3) {
            thicknessCorrectionFactor = 0.5;
        }
        else if(brushWidth == 4) {
            thicknessCorrectionFactor = 0.55;
        }
        else if(brushWidth >= 5 && brushWidth < 7) {
            thicknessCorrectionFactor = 0.65;
        }
        else if(brushWidth >= 7 && brushWidth <= 8) {
            thicknessCorrectionFactor = 0.65;
        }
        else {
            thicknessCorrectionFactor = 0.85;
        }
        return thicknessCorrectionFactor;
    }

}
