//
//  FTWordStrokeInfo.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 27/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTWordStrokeInfo: NSObject {
    let word: String;
    var wordStrokesInfo = [FTCharStrokeInfo]();
    var strokeBoundingRect: CGRect = .null;
    private(set) var glyphWidth: CGFloat = 0;
    
    init(with word: String) {
        self.word = word;
    }
    
    func addStrokeInfo(_ strokeInfo: FTCharStrokeInfo) {
        self.wordStrokesInfo.append(strokeInfo);
        self.strokeBoundingRect = self.strokeBoundingRect.union(strokeInfo.strokeBoundingRect);
        self.glyphWidth += strokeInfo.glyphInfo.width;
    }
}
