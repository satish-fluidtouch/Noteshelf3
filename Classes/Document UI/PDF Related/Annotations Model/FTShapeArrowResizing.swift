//
//  FTShapeArrowResizing.swift
//  Noteshelf
//
//  Created by Sameer on 23/03/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
class FTShapeArrowResizing: FTShapeResizing {
    override func drawingPointsForArrow(for controlPoints: [CGPoint],  points: [CGPoint]) -> [CGPoint]  {
        var drawingPoints = controlPoints
        let refPoint = points[points.count - 10]
        let start = drawingPoints[0]
        let end = drawingPoints[1]
        //drawingPoints.removeAll()
        drawingPoints.append(contentsOf: arrowDrawingPoints(start: start, end: end, refPoint: refPoint))
        return drawingPoints
    }
    
    func arrowDrawingPoints(start: CGPoint, end: CGPoint, refPoint: CGPoint) -> [CGPoint] {
        var _arrowHeadPoints = [CGPoint]()
        let angle = angleBetweenPoint(end , andPoint: start)
        let arrowPoints = arrowHeadPoints(refPoint: refPoint, angle: angle)
        _arrowHeadPoints.append(contentsOf: arrowPoints)
        return _arrowHeadPoints
    }
    
    func arrowHeadPoints(refPoint: CGPoint, angle: CGFloat) -> [CGPoint] {
        var arrowHeadPoints = [CGPoint]()
        var radius: CGFloat = 10
        for _ in 1...30 {
            let triPoints = buildTriangle(center: refPoint, radius: radius, angle: angle)
            arrowHeadPoints.append(contentsOf: triPoints)
            radius -= CGFloat(0.5)
        }
        return arrowHeadPoints
    }
    
    fileprivate func angleBetweenPoint(_ point1 : CGPoint, andPoint point2 : CGPoint) -> CGFloat {
        let deltaY = point1.y - point2.y;
        let deltaX = point1.x - point2.x;
        let angle = atan2(deltaY, deltaX);
        return angle;
    }
    
    func buildTriangle(center: CGPoint, radius: CGFloat, angle: CGFloat) -> [CGPoint] {
        var points = [CGPoint]()
        for i in 0..<3 {
            var p1 = CGPoint.zero
            p1.x = center.x + radius * cos(angle + Double(i * 2) * Double.pi / 3)
            p1.y = center.y + radius * sin(angle + Double(i * 2) * Double.pi / 3)
            points.append(p1)
        }
        return points
    }
}

class FTShapeDoubleArrowResizing: FTShapeArrowResizing {
    override func drawingPointsForArrow(for controlPoints: [CGPoint],  points: [CGPoint]) -> [CGPoint]  {
        var drawingPoints = controlPoints

        let start = drawingPoints[0]
        let end = drawingPoints[1]
        drawingPoints.removeAll()

        var refPoint = points[10]
        drawingPoints.append(contentsOf: arrowDrawingPoints(start: end, end: start, refPoint: refPoint))
        
        drawingPoints.append(contentsOf: [start, end])
        
        refPoint = points[points.count - 10]
        drawingPoints.append(contentsOf: arrowDrawingPoints(start: start, end: end, refPoint: refPoint))
        return drawingPoints
    }
}
