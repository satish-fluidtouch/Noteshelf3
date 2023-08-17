//
//  FTShapeDashLine.swift
//  Noteshelf
//
//  Created by Sameer on 28/03/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
class FTShapeDashLine: FTShapeLine {
    override func drawingPoints(scale: CGFloat) -> [CGPoint] {
        return super.drawingPoints(scale: scale)
    }
    
    override func type() -> FTShapeType {
        return FTShapeType.dashLine
    }
    
    override func shapeName() -> String {
        return "Dash Line"
    }
}
