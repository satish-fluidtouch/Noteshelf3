//
//  FTPenAttributes.swift
//  Noteshelf
//
//  Created by Amar on 09/08/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

struct FTPenAttributes {
    var curmass : CGFloat = 0.2;
    var curdrag : CGFloat = 0.15;
    var penDiffFactor : CGFloat = 0.1;
    var penVelocityFactor : CGFloat = 0.008;
    var penMinFactor : CGFloat = 0.2;
    var brushWidth : CGFloat = 1.0;
    var velocitySensitive = true;
    var scaleFactor = 1
}

extension FTPenAttributes {
    func asStrokeAttributes() -> FTStrokeAttributes {
        return FTStrokeAttributes(curDrag: self.curdrag,
                                  curmass: self.curmass,
                                  penDiffFactor: self.penDiffFactor,
                                  penMinFactor: self.penMinFactor,
                                  penVelocityFactor: self.penVelocityFactor,
                                  brushWidth: self.brushWidth,
                                  velocitySensitive: self.velocitySensitive);

    }
}
