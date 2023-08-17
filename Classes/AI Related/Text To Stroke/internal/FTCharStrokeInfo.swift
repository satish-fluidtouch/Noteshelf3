//
//  FTCharStrokeInfo.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 27/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTCharStrokeInfo: NSObject {
    let character: String;
    let strokes: [FTStroke]
    let glyphInfo: FTStrokeGlyphInfo
    private(set) var strokeBoundingRect: CGRect = .null;
    
    init(char: String
         , strokes: [FTStroke]
         , glyphInfo: FTStrokeGlyphInfo
         , scale: CGFloat) {
        self.character = char;
        self.strokes = strokes
        self.glyphInfo = glyphInfo.scaledInfo(scale);
        super.init();
        
        strokes.forEach { eachAnnotation in
            self.strokeBoundingRect = self.strokeBoundingRect.union(eachAnnotation.boundingRect);
        }
    }
}
