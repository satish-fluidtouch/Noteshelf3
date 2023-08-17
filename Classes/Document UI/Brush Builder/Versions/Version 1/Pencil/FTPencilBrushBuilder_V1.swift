//
//  FTPencilBrushBuilder_V1.swift
//  Noteshelf
//
//  Created by Akshay on 08/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

final class FTPencilBrushBuilder_V1: FTBrushProtocol {
    static func attributesFor(brushWidth: CGFloat, velocitySensitive: Bool) -> FTPenAttributes {
        var attributes = FTPenAttributes();
        attributes.brushWidth = brushWidth+1;
        attributes.velocitySensitive = false;
        return attributes;
    }

    static func brushImageFor(brushWidth: CGFloat, scale: CGFloat) -> UIImage {
        let contentScaleFactor = UIScreen.main.scale;

        let dotImage : UIImage;
        if(contentScaleFactor > 1.0){
            dotImage = UIImage(named:"BrushAsset_v1/pencil-brush-large")!;
        }else{
            dotImage = UIImage(named:"BrushAsset_v1/pencil-brush-small")!;
        }
        return dotImage;
    }

    static func thicknessCorrectionFactorFor(brushWidth: CGFloat) -> CGFloat {
        //Optional, no need to implement
        return 1.0
    }
}
