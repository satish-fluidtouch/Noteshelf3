//
//  FTShapeLine.swift
//  Noteshelf
//
//  Created by Narayana on 21/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

@objcMembers public class FTShapeLine: NSObject, FTShape {
    var vertices: [CGPoint] = []
    var numberOfSides: CGFloat = 0
    var  startPoint:  CGPoint = .zero
    var  endPoint: CGPoint = .zero
    var isClosedShape: Bool = false

    init(point startPoint: CGPoint, end endPoint: CGPoint) {
        self.startPoint = startPoint
        self.endPoint = endPoint
    }
    
    override init() {
        super.init()
    }
    
    func length() -> CGFloat {
        return FTShapeUtility.distanceBetween2Points(startPoint, andPoint: endPoint)
    }
    
    func drawingPoints(scale: CGFloat) -> [CGPoint] {
        var array: [CGPoint] = []
        //TODO:- Apply scale here
        if (vertices.count > 1) {
            startPoint = vertices[0]
            endPoint = vertices[1]
        }
        let start = startPoint.scaled(scale: 1.0)
        let end = endPoint.scaled(scale: 1.0)
        let distance = FTShapeUtility.distanceBetween2Points(start, andPoint: end)
        if distance <= CGFloat(SHAPE_MIN_LINE_LENGTH) {
            array = []
        } else {
            array = FTShapeUtility.points(inLine: start, end: end)
        }
        return array
    }

    func controlPoints() -> [CGPoint] {
        return [startPoint, endPoint]
    }
    
    func validate()  {
        let lineType = FTShapeUtility.isStraitLine(startPoint, andPointB: endPoint)
        switch lineType {
        case FTShapeLineType.vertical:
            endPoint = CGPoint(x: startPoint.x, y: endPoint.y)
        case FTShapeLineType.horizontal:
            endPoint = CGPoint(x: endPoint.x, y: startPoint.y)
        default:
            break
        }
    }
    
    func type() -> FTShapeType {
        return FTShapeType.line
    }
    
    func shapeName() -> String {
        return "Line"
    }
    
    func isPerfectShape() -> Bool {
        return false
    }
    
    func isLineType() -> Bool {
        return true
    }
    
    func defaultControlPoints() -> [CGPoint] {
        return [CGPoint()]
    }
}
