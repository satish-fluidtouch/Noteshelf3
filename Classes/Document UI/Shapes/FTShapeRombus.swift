//
//  FTShapeRombus.swift
//  Noteshelf
//
//  Created by Sameer on 23/03/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
@objcMembers public class FTShapeRombus: FTShapePolygon {
    
    override func type() -> FTShapeType {
        return FTShapeType.rombus
    }
    
    override func isPerfectShape() -> Bool {
        return true
    }
    
    override func shapeName() -> String {
        return "Rombus"
    }
    
    override func shapeControlPoints(in view: UIView, for scale: CGFloat) -> [CGPoint] {
        let point1 = view.transformedTopMid().scaled(scale: 1 / scale)
        let point2 = view.transformedRightMid().scaled(scale: 1 / scale)
        let point3 = view.transformedBottomMid().scaled(scale: 1 / scale)
        let point4 = view.transformedLeftMid().scaled(scale: 1 / scale)
        return [point1, point2, point3, point4]
    }
}
