//
//  FTShapeRectangle.swift
//  Noteshelf
//
//  Created by Narayana on 21/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

@objcMembers public class FTShapeRectangle: FTShapePolygon {
    
    convenience init?(points: [CGPoint]) {
        self.init()
        vertices = points
        if (!validateRectangle()) {
            return nil
        }
    }
    
    func validateRectangle() -> Bool {
        var straightLineCount = 0
        var isPerfectRectangle = true
        let lineArray = getLines()
        for line in lineArray {
            let lineType = FTShapeUtility.isStraitLine(line.startPoint, andPointB: line.endPoint)
            if lineType != FTShapeLineType.normal {
                straightLineCount += 1
            }
        }
        
        if straightLineCount >= 3 {
            let boudingRect = FTShapeUtility.boundingRect(vertices)
            objc_sync_enter(self);
            vertices =  FTShapeUtility.vertices(for: boudingRect);
            objc_sync_exit(self);
            isPerfectRectangle = true
        } else {
            isPerfectRectangle = false
        }
        return isPerfectRectangle
    }
    
    override func validate() {
        super.validate()
        _ = validateRectangle()
    }
    
    override func type() -> FTShapeType {
        return FTShapeType.rectangle
    }
    
    override func shapeName() -> String {
        return "Rectangle"
    }
    
    override func shapeControlPoints(in view: UIView, for scale: CGFloat) -> [CGPoint] {
        let point1 = view.transformedTopLeft().scaled(scale: 1 / scale)
        let point2 = view.transformedTopRight().scaled(scale: 1 / scale)
        let point3 = view.transformedBottomRight().scaled(scale: 1 / scale)
        let point4 = view.transformedBottomLeft().scaled(scale: 1 / scale)
        return [point1, point2, point3, point4]
    }
    
    override func isPerfectShape() -> Bool {
        return true
    }
}
