//
//  FTShapeParallelogram.swift
//  Noteshelf
//
//  Created by Narayana on 12/04/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

@objcMembers public class FTShapeParallelogram: FTShapePolygon {
            
    override func type() -> FTShapeType {
        return FTShapeType.paralalleogram
    }
    
    override func shapeName() -> String {
        return "paralalleogram"
    }
    
    override func shapeControlPoints(in view: UIView, for scale: CGFloat) -> [CGPoint] {
        let point1 = self.requiredTopLeftPoint(view: view).scaled(scale: 1 / scale)
        let point2 = view.transformedTopRight().scaled(scale: 1 / scale)
        let point3 = self.requiredBottomRightPoint(view: view).scaled(scale: 1 / scale)
        let point4 = view.transformedBottomLeft().scaled(scale: 1 / scale)
        return [point1, point2, point3, point4]
    }
    
    private func requiredTopLeftPoint(view: UIView) -> CGPoint {
        let frame = view.originalFrame()
        var point = frame.origin
        let threshold = view.bounds.width/4
        point.x += threshold
        return view.pointInTransformedView(point: point)
    }
    
    private func requiredBottomRightPoint(view: UIView) -> CGPoint {
        let frame = view.originalFrame()
        let threshold = view.bounds.width/4
        var point = frame.origin
        point.x += (frame.size.width - threshold)
        point.y += frame.size.height
        return view.pointInTransformedView(point: point)
    }

    override func isPerfectShape() -> Bool {
        return true
    }
}
