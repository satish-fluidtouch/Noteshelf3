//
//  FTShapeAnnotation_Resizing.swift
//  Noteshelf
//
//  Created by Sameer on 11/01/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

protocol FTShapeRezingDelegate: AnyObject {
    func _setAnchorPoint()
    func resetAnchorPoint()
    func rotateFrame()
    func updateControlPoint()
}

class FTShapeResizing : NSObject {
    var shapeType: FTShapeType?
    var shapeControlPoints : [CGPoint] = []
    var boundingRect = CGRect.zero
    weak var delegate: FTShapeRezingDelegate?
    var capToSizeIfNeeded = false
    class func shapeResizeObject(shapeType: FTShapeType) -> FTShapeResizing? {
        var shapeReizeObj = FTShapeResizing(shapeType: shapeType)
        if (shapeType == .rectangle) {
            shapeReizeObj = FTShapeRectangleResizing(shapeType: shapeType)
        } else if (shapeType == .ellipse) {
            shapeReizeObj = FTShapeEllipseResizing(shapeType: shapeType)
        } else if (shapeType == .triangle) {
            shapeReizeObj = FTShapeTriangleResizing(shapeType: shapeType)
        } else if (shapeType == .rombus) {
            shapeReizeObj = FTShapeRombusResizing(shapeType: shapeType)
        } else if (shapeType == .pentagon) {
            shapeReizeObj = FTShapePentagonResizing(shapeType: shapeType)
        } else if shapeType == .paralalleogram {
            shapeReizeObj = FTShapeParallelogramResizing(shapeType: shapeType)
        } else if shapeType == .arrow {
            shapeReizeObj = FTShapeArrowResizing(shapeType: shapeType)
        } else if shapeType == .doubleArrow {
            shapeReizeObj = FTShapeDoubleArrowResizing(shapeType: shapeType)
        }
        return shapeReizeObj
    }
    
    init(shapeType: FTShapeType) {
        self.shapeType = shapeType
    }
    
    func resizedBoundingRect(for touch: UITouch,in view: UIView, rect: CGRect, scale: CGFloat, activeControlPoint: FTControlPoint) -> CGRect {
        return CGRect.zero
    }
    
    func drawingPointsForArrow(for controlPoints: [CGPoint],  points: [CGPoint]) -> [CGPoint]{
        return [CGPoint]()
    }
    
    func resizeProportionally(for touch: UITouch,in view: UIView) -> CGRect {
        .zero
    }
}
