//
//  FTArrowUtility.swift
//  Noteshelf
//
//  Created by Sameer on 16/04/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTArrowUtility {
    static func arrowDrawingPoints(start: CGPoint, end: CGPoint, refPoint: CGPoint) -> [CGPoint] {
        let arrowUtil = FTArrowUtility()
       var _arrowHeadPoints = [CGPoint]()
        let angle = arrowUtil.angleBetweenPoint(end , andPoint: start)
        let arrowPoints = arrowUtil.arrowHeadPoints(refPoint: refPoint, angle: angle)
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


