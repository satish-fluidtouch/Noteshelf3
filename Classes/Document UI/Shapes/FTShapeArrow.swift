//
//  FTShapeArrow.swift
//  Noteshelf
//
//  Created by Sameer on 23/03/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTShapeArrow: FTShapeLineStrip {
    var arrowPoints = [CGPoint]()
    override func type() -> FTShapeType {
        return .arrow
    }

    override func shapeName() -> String {
        return "Arrow"
    }
    
    override func isLineType() -> Bool {
        return true
    }
    
    override func drawingPoints(scale: CGFloat) -> [CGPoint] {
        let vertices = vertices
        var drawingPoints = super.drawingPoints(scale: scale)
        if drawingPoints.count > 10 {
            let refPoint = drawingPoints[drawingPoints.count - 10]
            let start = vertices[0]
            let end = vertices[1]
            arrowPoints = FTArrowUtility.arrowDrawingPoints(start: start, end: end, refPoint: refPoint)
            let newPoints = pointsToDraw(scale: scale)
            drawingPoints.append(contentsOf: newPoints)
        }
        return drawingPoints
    }
    
    func pointsToDraw(scale: CGFloat) -> [CGPoint] {
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
    
    private func getLines() -> [FTShapeLine] {
        var lines: [FTShapeLine] = []
        if (arrowPoints.isEmpty) {
            return lines
        }
        for i in 1..<arrowPoints.count {
            let pointA = arrowPoints[i - 1]
            let pointB = arrowPoints[i]
            lines.append(FTShapeLine(point: pointA, end: pointB))
        }
        return lines
    }
}
