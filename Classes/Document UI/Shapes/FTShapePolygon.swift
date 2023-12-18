//
//  FTShapePolygon.swift
//  Noteshelf
//
//  Created by Narayana on 21/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

@objcMembers public class FTShapePolygon: NSObject, FTShape {
    var vertices: [CGPoint] = []
    var isClosedShape: Bool = false
    var numberOfSides: CGFloat = 0
    func getLines() -> [FTShapeLine] {
        var _vertices = [CGPoint]();
        objc_sync_enter(self);
        _vertices.append(contentsOf: vertices);
        objc_sync_exit(self);
        
        var lines: [FTShapeLine] = []
        if (_vertices.isEmpty) {
            return lines
        }
        for i in 1..._vertices.count {
            let pointB: CGPoint
            let pointA = _vertices[i - 1]
            if i == _vertices.count {
                pointB = _vertices[0]
            } else {
                pointB = _vertices[i]
            }
            lines.append(FTShapeLine(point: pointA, end: pointB))
        }
        return lines
    }
    
    public func validatePoints() -> [CGPoint] {
        objc_sync_enter(self);
        var kThresholdDistance: CGFloat = 0
        var newPoints: [CGPoint] = []
        
        for i in 1..<vertices.count {
            let line = FTShapeLine(point: vertices[i - 1], end: vertices[i])
            line.validate()
            let pointA = line.startPoint
            let pointB = line.endPoint
            vertices[i - 1] = pointA
            vertices[i] = pointB
            kThresholdDistance = FTShapeUtility.distanceBetween2Points(pointA, andPoint: pointB) * CGFloat(SHAPE_VARIANCE_PERCENTAGE)
            
            if i == vertices.count - 1 {
                //Last Point means snap to the first point if distance is closer
                let fistPoint = vertices[0]
                let distance = FTShapeUtility.distanceBetween2Points(pointB, andPoint: fistPoint)
                if distance <= kThresholdDistance && vertices.count > 2 {
                    vertices[i] = vertices[0]
                }
            }
            newPoints.append(pointA)
        }
        if let firstVertex = vertices.first, let lastVertex = vertices.last {
            isClosedShape = (firstVertex == lastVertex)
        }
        newPoints.append(self.vertices[self.vertices.count - 1])
        objc_sync_exit(self);
        return newPoints
    }
    
    func drawingPoints(scale: CGFloat) -> [CGPoint] {
        var points: [CGPoint] = []
        let lines = getLines()
        for line in lines {
            let drawingPoints = line.drawingPoints(scale: scale)
            if !drawingPoints.isEmpty {
                points.append(contentsOf: drawingPoints)
            }
        }
        return points
    }

    func controlPoints() -> [CGPoint] {
        return vertices
    }
    
    func shapeControlPoints(in view: UIView, for scale: CGFloat) -> [CGPoint] {
        return vertices
    }

    func validate()  {
        vertices = validatePoints()
    }
    
    func type() -> FTShapeType {
        return FTShapeType.polygon
    }
    
    func shapeName() -> String {
        return "Polygon"
    }
    
    func isPerfectShape() -> Bool {
        return false
    }
}
