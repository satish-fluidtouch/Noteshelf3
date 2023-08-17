//
//  FTShapeTriangleResizing.swift
//  Noteshelf
//
//  Created by Sameer on 12/01/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTShapeTriangleResizing: FTShapeRectangleResizing {
    override init(shapeType: FTShapeType) {
        super.init(shapeType: shapeType)
    }
    
    override func resizedBoundingRect(for touch: UITouch,in view: UIView, rect: CGRect, scale: CGFloat, activeControlPoint: FTControlPoint) -> CGRect {
        return super.resizedBoundingRect(for: touch, in: view, rect: rect, scale: scale, activeControlPoint: activeControlPoint)
    }
}
