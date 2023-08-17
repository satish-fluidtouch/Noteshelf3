//
//  FTShapeRectangle_Resizing.swift
//  Noteshelf
//
//  Created by Sameer on 11/01/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

class FTShapeRectangleResizing: FTShapeResizing {

   override init(shapeType: FTShapeType) {
       super.init(shapeType: shapeType)
    }
    
    override func resizedBoundingRect(for touch: UITouch,in view: UIView, rect: CGRect, scale: CGFloat, activeControlPoint: FTControlPoint)->  CGRect {
        let angle = view.transform.angle
        var currentPoint = touch.location(in: view.superview)
        currentPoint.rotate(by: -angle, refPoint: CGPoint(x: view.frame.midX, y: view.frame.midY))
        
        var previous = touch.previousLocation(in: view.superview)
        previous.rotate(by: -angle, refPoint: CGPoint(x: view.frame.midX, y: view.frame.midY))

        var frame = rect
        let deltaWidth = (currentPoint.x - previous.x)
        let deltaHeight = (currentPoint.y - previous.y)
        
        switch activeControlPoint {
        case .topLeft:
            if  currentPoint.x > frame.maxX {
                frame.size.width += deltaWidth
                updateControlPoint()
            } else if currentPoint.y > frame.maxY {
                frame.size.height -= deltaHeight
                self.delegate?.rotateFrame()
                updateControlPoint()
            } else {
                frame.origin.y += deltaHeight
                frame.size.width -= deltaWidth
                frame.size.height -= deltaHeight
            }
        case .topRight:
            if currentPoint.x < frame.minX{
                frame.size.width -= deltaWidth
                updateControlPoint()
            } else if currentPoint.y > frame.maxY {
                frame.size.height += deltaHeight
                self.delegate?.rotateFrame()
                updateControlPoint()
            } else {
                frame.origin.y += deltaHeight
                frame.size.width += deltaWidth
                frame.size.height -= deltaHeight
            }
        case .bottomRight:
            if currentPoint.x < frame.minX {
                frame.size.width -= deltaWidth
                updateControlPoint()
            } else if currentPoint.y < frame.minY {
                frame.size.height += deltaHeight
                self.delegate?.rotateFrame()
                updateControlPoint()
            }  else {
                frame.size.width += deltaWidth
                frame.size.height += deltaHeight
            }
        case .bottomLeft:
            if  currentPoint.x > frame.maxX {
                frame.size.width += deltaWidth
                updateControlPoint()
            } else if currentPoint.y < frame.minY {
                frame.size.height += deltaHeight
                self.delegate?.rotateFrame()
                updateControlPoint()
            } else {
                frame.size.width -= deltaWidth
                frame.size.height += deltaHeight
            }
        case .topMid:
            if frame.maxY < currentPoint.y  && !self.capToSizeIfNeeded {
                frame.size.height += deltaHeight
                self.delegate?.rotateFrame()
            } else {
                frame.size.height -= deltaHeight
            }
        case .bottomMid:
            if currentPoint.y < frame.origin.y && !self.capToSizeIfNeeded {
                frame.size.height -= deltaHeight
                self.delegate?.rotateFrame()
            } else {
                frame.size.height += deltaHeight
            }
        case .leftSideMid:
            if currentPoint.x > frame.maxX && !self.capToSizeIfNeeded {
                frame.size.width += deltaWidth
                updateControlPoint()
            }  else {
                frame.size.width -= deltaWidth
            }
        case .rightSideMid:
            if currentPoint.x < frame.minX && !self.capToSizeIfNeeded {
                frame.size.width -= deltaWidth
                updateControlPoint()
            }  else {
                frame.size.width += deltaWidth
            }
        default:
            frame.size.width -= deltaWidth
            frame.size.height -= deltaHeight
        }
        return frame
    }
    
    private func updateControlPoint() {
        self.delegate?.updateControlPoint()
    }
}

