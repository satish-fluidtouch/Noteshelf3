//
//  FTShapeEllipseResizing.swift
//  Noteshelf
//
//  Created by Sameer on 11/01/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTShapeEllipseResizing : FTShapeRectangleResizing {
    override init(shapeType: FTShapeType) {
        super.init(shapeType: shapeType)
    }
    
    override func resizedBoundingRect(for touch: UITouch,in view: UIView, rect: CGRect, scale: CGFloat, activeControlPoint: FTControlPoint) -> CGRect {
        return super.resizedBoundingRect(for: touch, in: view, rect: rect, scale: scale, activeControlPoint: activeControlPoint)
    }

    private func updateEllipseSize(index: Int, point: CGPoint) {
        let pointA = shapeControlPoints[index]
        let pointB = point
        var offSet = CGFloat.zero
        if (index == 0) {
            offSet = pointB.x - pointA.x;
            updateWidth(with: offSet)
        } else if (index == 1) {
            offSet = pointB.y - pointA.y;
            updateHeight(with: offSet)
        } else if(index == 2) {
            offSet = pointA.x - pointB.x;
            updateWidth(with: offSet)
        } else if(index == 3) {
            offSet = pointA.y - pointB.y;
            updateHeight(with: offSet)
        }
    }
   
    private func updateHeight(with offSet: CGFloat) {
        var _size = boundingRect.size
        _size.height +=  offSet * 2
        if(_size.height < 0) {
            _size.height *= -1
        }
        boundingRect.size = _size;
    }
    
    private func updateWidth(with offSet: CGFloat) {
        var _size = boundingRect.size
        _size.width +=  offSet * 2
        if(_size.width < 0) {
            _size.width *= -1
        }
        boundingRect.size = _size;
    }
 
}
