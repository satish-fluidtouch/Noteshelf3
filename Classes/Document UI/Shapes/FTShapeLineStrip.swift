//
//  FTShapeLineStrip.swift
//  Noteshelf
//
//  Created by Akshay on 06/06/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTRenderKit

@objcMembers public class FTShapeLineStrip: NSObject, FTShape {
    var numberOfSides: CGFloat = 0
    
    var vertices = [CGPoint]()
    var isClosedShape: Bool = false

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

    private func getLines() -> [FTShapeLine] {
        var lines: [FTShapeLine] = []
        if (vertices.isEmpty) {
            return lines
        }
        for i in 1..<vertices.count {
            let pointA = vertices[i - 1]
            let pointB = vertices[i]
            lines.append(FTShapeLine(point: pointA, end: pointB))
        }
        return lines
    }
    
    func validate() {

    }

    func type() -> FTShapeType {
        .lineStrip
    }

    func shapeName() -> String {
        "Line Strip"
    }
    
    func defaultControlPoints() -> [CGPoint] {
        return [CGPoint()]
    }
    
    func isPerfectShape() -> Bool {
        return false
    }
    
    func isLineType() -> Bool {
        return false
    }
}
