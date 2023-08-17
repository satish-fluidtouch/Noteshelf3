//
//  FTTileMap.swift
//  Noteshelf
//
//  Created by Amar on 27/08/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTTileMap : NSObject {
    var annotations = Set<FTAnnotation>();
    var boundingRect = CGRect.zero;
    
    func tileContainsRect(_ rects : [CGRect]) -> Bool
    {
        var intersects = false
        for rect in rects where self.boundingRect.integral.intersects(rect.integral) {
            intersects = true
            break
        }
        return intersects
    }
}
