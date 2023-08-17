//
//  FTShapePentagon.swift
//  Noteshelf
//
//  Created by Sameer on 16/03/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit
@objcMembers public class FTShapePentagon: FTShapePolygon {
    
    override func validate() {
        super.validate()
    }

    override func type() -> FTShapeType {
        return FTShapeType.pentagon
    }
    
    override func shapeName() -> String {
        return "Pentagon"
    }
    
    override func shapeControlPoints(in view: UIView, for scale: CGFloat) -> [CGPoint] {
        if numberOfSides == 0.0 {
            print("Number Of Sides ", numberOfSides)
        }
        return polygonPointArray(sides: Int(numberOfSides), view: view, scale: scale, rotationAngle: view.transform.angle)
    }
    
    
    func polygonPointArray(sides:Int,view: UIView,scale: CGFloat, rotationAngle: CGFloat) -> [CGPoint] {
        let angle = (360/CGFloat(sides)).degreesToRadians
        let offset: CGFloat = 90
        let frame = view.contentFrame()
        let cx = frame.midX
        let cy = frame.midY
        var r1 = min(frame.width / 2, frame.height / 2)
        if (frame.width < frame.height) {
             r1 = max(frame.width / 2, frame.height / 2)
        }
        var i = 0
        var points = [CGPoint]()
        while i <= sides {
            var r2 = r1
            if(i !=  0 && i != sides) {
                if (frame.width > frame.height) {
                    r2 = max(frame.width / 2, frame.height / 2)
                } else {
                    r2 = min(frame.width / 2, frame.height / 2)
                }
            }
            let xpo = cx + r2 * cos(angle * CGFloat(i) - offset.degreesToRadians)
            let ypo = cy + r1 * sin(angle * CGFloat(i) - offset.degreesToRadians)
            var point = CGPoint(x: xpo, y: ypo)
            point.rotate(by: rotationAngle, refPoint: CGPoint(x: cx, y: cy))
            point = point.scaled(scale: 1 / scale)
            points.append(point)
            i += 1
        }
        return points
    }
    
    override func isPerfectShape() -> Bool {
        return true
    }
}
