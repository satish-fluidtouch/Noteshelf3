//
//  FTShapeCurve.swift
//  Noteshelf3
//
//  Created by Fluid Touch on 26/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

@objcMembers public class FTShapeCurve: NSObject, FTShape {
    var vertices: [CGPoint] = []
    var numberOfSides: CGFloat = 0
    var center = CGPoint.zero
    var isClosedShape: Bool = false
    let thresholdAngle:CGFloat = 50
    
    convenience init?(points: [CGPoint]) {
        self.init()
        let simplifiedPoints = SwiftSimplify.simplify(points, tolerance: .good, highQuality: true)
        let filteredPoints = filterStartAndEndPoints(points: simplifiedPoints)
        if filteredPoints.count >= 3 && !hasElbow(points: filteredPoints) {
            if let startPoint = filteredPoints.first, let endPoint = filteredPoints.last, let pointOnCurve = deCasteljau(points: filteredPoints) {
                let controlPoint = calculateCurveControlPoint(pointOnCurve: pointOnCurve, startTouchPoint: startPoint, endTouchPoint: endPoint)
                vertices = [startPoint, controlPoint, endPoint]
            }
        } else {
            return nil
        }
    }
    
    func knobControlPoints() -> [CGPoint] {
        if let startPoint = vertices.first, let endPoint = vertices.last {
            let midPoint = point(at: 0.5)
            return [startPoint, midPoint, endPoint]
        }
        return []
    }

    private func hasElbow(points: [CGPoint]) -> Bool {
        for i in 1..<points.count - 1 {
            let angle = abs(calculateAngle(point1: points[i - 1], point2: points[i], point3: points[i + 1]))
            if angle < thresholdAngle {
                return true
            }
        }
        return false
    }
    
    private func filterStartAndEndPoints(points: [CGPoint]) -> [CGPoint] {
        guard let firstPoint = points.first, let lastPoint = points.last else {
            return []
        }
        let filteredPoints = points.filter { point in
            let distanceFromFirst = sqrt(pow(point.x - firstPoint.x, 2) + pow(point.y - firstPoint.y, 2))
            let distanceFromLast = sqrt(pow(point.x - lastPoint.x, 2) + pow(point.y - lastPoint.y, 2))

            return distanceFromFirst > 3.0 && distanceFromLast > 3.0
        }
        return filteredPoints
    }
    
    func drawingPoints(scale: CGFloat) -> [CGPoint] {
        let factory = FTShapeFactory()
        let inputPoints = stride(from: 0, through: 1, by: 1.0 / 10).map { point(at: $0) }
        let distance = factory.getArcLength(inputPoints)
        return stride(from: 0, through: 1, by: 1.0 / distance).map { point(at: $0) }
    }

    func controlPoints() -> [CGPoint] {
        return vertices
    }
    
    func shapeControlPoints(in view: UIView, for scale: CGFloat) -> [CGPoint] {
        return controlPoints()
    }
    
    func validate() {
    }
    
    func type() -> FTShapeType {
        return FTShapeType.curve
    }
    
    func shapeName() -> String {
        return "Curve"
    }
    
    func isPerfectShape() -> Bool {
        return false
    }
}

extension FTShapeCurve {
    private func calculateAngle(point1: CGPoint, point2: CGPoint, point3: CGPoint) -> Double {
        let vector1 = CGPoint(x: point1.x - point2.x, y: point1.y - point2.y)
        let vector2 = CGPoint(x: point3.x - point2.x, y: point3.y - point2.y)
        let dotProduct = vector1.x * vector2.x + vector1.y * vector2.y
        let magnitudeProduct = sqrt(pow(vector1.x, 2) + pow(vector1.y, 2)) * sqrt(pow(vector2.x, 2) + pow(vector2.y, 2))
        let cosTheta = dotProduct / magnitudeProduct
        return cosTheta * (180.0 / Double.pi)
    }
    
    //https://en.wikipedia.org/wiki/De_Casteljau%27s_algorithm
    //Finds the curve influenced point on drawn path at given position. This will be used to find the actual control point to draw curve
    private func deCasteljau(points: [CGPoint], position: CGFloat = 0.5) -> CGPoint? {
        var a: CGPoint
        var b: CGPoint
        var midpoints: [CGPoint] = []
        var mutablePoints = points
        while mutablePoints.count > 1 {
            let num = mutablePoints.count - 1
            for i in 0..<num {
                a = mutablePoints[i]
                b = mutablePoints[i+1]
                midpoints.append(CGPoint(
                    x: a.x + (b.x - a.x) * position,
                    y: a.y + (b.y - a.y) * position
                ))
            }
            mutablePoints = midpoints
            midpoints = []
        }
        return mutablePoints.first
    }
    
    //Quadratic Bezier equation to find the curve control point
    //B = 2*P - 0.5*A - 0.5*C
    //P = Point on the curve at T = 0.5
    //A = Start point
    //B = End point
    func calculateCurveControlPoint(pointOnCurve: CGPoint, startTouchPoint: CGPoint, endTouchPoint: CGPoint) -> CGPoint {
        let x = 2 * pointOnCurve.x - 0.5 * startTouchPoint.x - 0.5 * endTouchPoint.x
        let y = 2 * pointOnCurve.y - 0.5 * startTouchPoint.y - 0.5 * endTouchPoint.y
        return CGPoint(x: x, y: y)
    }
    
    public func point(at t: CGFloat) -> CGPoint {
        guard vertices.count >= 3 else {
            return .zero
        }
        let p0 = vertices[0]
        let p1 = vertices[1]
        let p2 = vertices[2]
        if t == 0 {
            return p0
        } else if t == 1 {
            return p2
        }
        let mt = 1.0 - t
        let mt2: CGFloat    = mt*mt
        let t2: CGFloat     = t*t
        let a = mt2
        let b = mt * t*2
        let c = t2
        let temp1 = CGPoint(x: a * p0.x, y: a * p0.y)
        let temp2 = CGPoint(x: b * p1.x, y: b * p1.y)
        let temp3 = CGPoint(x: c * p2.x, y: c * p2.y)

        let result = CGPoint(x: temp1.x + temp2.x + temp3.x, y: temp1.y + temp2.y + temp3.y)

        return result
    }
}
