//
//  FTShapeTriangle.swift
//  Noteshelf
//
//  Created by Narayana on 21/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

@objcMembers public class FTShapeTriangle: FTShapePolygon {
    
    override func type() -> FTShapeType {
        return FTShapeType.triangle
    }
    
    override func isPerfectShape() -> Bool {
        return true
    }
    
    override func shapeName() -> String {
        return "Triangle"
    }
    
    override func shapeControlPoints(in view: UIView, for scale: CGFloat) -> [CGPoint] {
        let point1 = view.transformedTopMid().scaled(scale: 1 / scale)
        let point2 = view.transformedBottomRight().scaled(scale: 1 / scale)
        let point3 = view.transformedBottomLeft().scaled(scale: 1 / scale)
        return [point1, point2, point3]
    }
}
