//
//  FTShapeEllipse.swift
//  Noteshelf
//
//  Created by Narayana on 21/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

func DEGREES_RADIANS(_ angle:  CGFloat) -> CGFloat {
    return CGFloat(angle * .pi / 180)
}

@objcMembers public class FTShapeEllipse: NSObject, FTShape {
    var vertices: [CGPoint] = []
    var numberOfSides: CGFloat = 0
    var center = CGPoint.zero
    var boundingRectSize = CGSize.zero
    var rotatedAngle: CGFloat = 0.0
    var isClosedShape: Bool = false

    
    func point(onEllipse angle: CGFloat) -> CGPoint {
        var newPoint: CGPoint
        let x: CGFloat = center.x + (boundingRectSize.width / 2) * cos(DEGREES_RADIANS(angle))
        let y: CGFloat = center.y + (boundingRectSize.height / 2) * sin(DEGREES_RADIANS(angle))
        newPoint = FTShapeUtility.rotatePoint(byAngle: center, andPoint: CGPoint(x: x, y: y), angle: rotatedAngle)
        return newPoint
    }
    
    func drawingPoints(scale: CGFloat) -> [CGPoint] {
        var points: [CGPoint] = []
        let area: CGFloat = boundingRectSize.width * boundingRectSize.height
        if area > CGFloat(SHAPE_MIN_LINE_LENGTH) {
            let kMaxAngle: CGFloat = 360
            var t: CGFloat = 0.0
            while t <= kMaxAngle {
                let point = self.point(onEllipse: t)
                points.append(point)
                t += 1
            }
        }
        return points
    }
    
    func validatePerfectCircle() {
        let kVariancePercentage: CGFloat = 20
        
        if boundingRectSize.width != 0 && boundingRectSize.height != 0 {
            var max = boundingRectSize.height
            var variance: CGFloat = (boundingRectSize.height / boundingRectSize.width) * 100
            if boundingRectSize.width < boundingRectSize.height {
                variance = (boundingRectSize.width / boundingRectSize.height) * 100
                max = boundingRectSize.width
            }
            
            variance = 100 - variance
            if variance <= kVariancePercentage {
                boundingRectSize = CGSize(width: max, height: max)
                rotatedAngle = 0
            }
        }
    }

    func controlPoints() -> [CGPoint] {
        var points: [CGPoint] = []
        let area: CGFloat = boundingRectSize.width * boundingRectSize.height
        if area > CGFloat(SHAPE_MIN_LINE_LENGTH) {
            let kMaxAngle: CGFloat = 270
            var t: CGFloat = 0.0
            while t <= kMaxAngle {
                let point = self.point(onEllipse: t)
                points.append(point)
                t += 90
            }
        }
        return points
    }
    
    func shapeControlPoints(in view: UIView, for scale: CGFloat) -> [CGPoint] {
        boundingRectSize = view.contentFrame().size
        center = CGPoint(x: view.contentFrame().midX, y: view.contentFrame().midY)
        rotatedAngle = view.transform.angle.radiansToDegrees
        return controlPoints()
    }
    
    func validate() {
        validatePerfectCircle()
    }
    
    func type() -> FTShapeType {
        return FTShapeType.ellipse   
    }
    
    func shapeName() -> String {
        return "Ellipse"
    }
    
    func isPerfectShape() -> Bool {
        return true
    }
}
