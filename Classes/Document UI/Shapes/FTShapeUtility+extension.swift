//
//  FTShapeUtility+extension.swift
//  Noteshelf
//
//  Created by Narayana on 25/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

public let SHAPE_VARIANCE_PERCENTAGE = 0.3
public let SHAPE_MIN_LINE_LENGTH = 2

enum FTShapeLineType : Int {
    case normal
    case horizontal
    case vertical
}

extension FTShapeUtility {
    
    class func rotatePoint(byAngle center: CGPoint, andPoint point1: CGPoint, angle: CGFloat) -> CGPoint {
        var angle = angle
        angle = angle * .pi / 180
        //    p'x = cos(theta) * (px-ox) - sin(theta) * (py-oy) + ox
        //    p'y = sin(theta) * (px-ox) + cos(theta) * (py-oy) + oy
        let px = point1.x
        let py = point1.y
        
        let ox = center.x
        let oy = center.y
        
        let pX = cos(angle) * (px - ox) - sin(angle) * (py - oy) + ox
        let pY = sin(angle) * (px - ox) + cos(angle) * (py - oy) + oy
        return CGPoint(x: pX, y: pY)
    }
    
    class func distanceBetween2Points(_ point1: CGPoint, andPoint point2: CGPoint) -> CGFloat {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        let distance = CGFloat(sqrt(dx * dx + dy * dy))
        return distance
    }
    
    class func point(onLine point2: CGPoint, point point1: CGPoint, distance: CGFloat) -> CGPoint {
        var newPoint: CGPoint = .zero
        
        var vx = point2.x - point1.x
        var vy = point2.y - point1.y
        
        //Then calculate the length:
        let mag = sqrt(vx * vx + vy * vy)
        
        //Normalize the vector to unit length:
        vx /= mag
        vy /= mag
        
        //Finally calculate the new vector, which is x2y2 + vxvy * (mag + distance).
        newPoint.x = point1.x + vx * (mag - distance)
        newPoint.y = point1.y + vy * (mag - distance)
        
        return newPoint
    }
    
    class func points(inLine startPoint: CGPoint, end endPoint: CGPoint) -> [CGPoint] {
        var points: [CGPoint] = []
        let kMinDistance: CGFloat = 1
        let totalDistance = FTShapeUtility.distanceBetween2Points(startPoint, andPoint: endPoint)
        var distance: CGFloat = 0.0
        while distance < totalDistance {
            let newPoint = FTShapeUtility.point(onLine: startPoint, point: endPoint, distance: distance)
            points.append(newPoint)
            distance += kMinDistance
        }
        points.append(endPoint)
        return points
    }
    
    class func isStraitLine(_ pointA: CGPoint, andPointB pointB: CGPoint) -> FTShapeLineType {
        let KLineVarianceDifference: CGFloat = 10
        
        var lineType = FTShapeLineType.normal
        let angle = abs(angleBetweenPoints(pointA, pointB))
        //check if horizontal
        var diff = abs(angle - 180)
        if diff <= KLineVarianceDifference || angle <= KLineVarianceDifference {
            lineType = FTShapeLineType.horizontal
        }
        //check if verticle
        diff = abs(angle - 90)
        if diff <= KLineVarianceDifference {
            lineType = FTShapeLineType.vertical
        }
        return lineType
    }
    
    class func vertices(for inRect: CGRect) -> [CGPoint] {
        var array: [CGPoint] = []
        
        array.append(CGPoint(x: inRect.origin.x, y: inRect.origin.y))
        array.append(CGPoint(x: inRect.origin.x + inRect.size.width, y: inRect.origin.y))
        array.append(CGPoint(x: inRect.origin.x + inRect.size.width, y: inRect.origin.y + inRect.size.height))
        array.append(CGPoint(x: inRect.origin.x, y: inRect.origin.y + inRect.size.height))
        array.append(CGPoint(x: inRect.origin.x, y: inRect.origin.y))
        
        return array
    }
}
