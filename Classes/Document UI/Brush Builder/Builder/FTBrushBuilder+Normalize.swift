//
//  FTBrushBuilder.swift
//  Noteshelf
//
//  Created by Akshay on 11/08/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension FTBrushBuilder {
    static func normalize(brushWidth: CGFloat,
                          min:FTPenAttributes,
                          max:FTPenAttributes) -> FTPenAttributes {
        var attributes = min;
        let value = brushWidth - floor(brushWidth);
        
        let _brushWidth = flerp(min.brushWidth, max.brushWidth, value)
        let _penVelocityFactor = flerp(min.penVelocityFactor, max.penVelocityFactor, value)
        let _penMinFactor = flerp(min.penMinFactor, max.penMinFactor, value)
        
        attributes.penVelocityFactor = _penVelocityFactor;
        attributes.penMinFactor = _penMinFactor;
        attributes.brushWidth = _brushWidth;
        return attributes;
    }

}

func flerp(_ f0: CGFloat,_ f1: CGFloat,_ p: CGFloat) -> CGFloat{
    return ((f0 * (1.0 - p)) + (f1 * p))
}
