//
//  FTResizable_Extesnion.swift
//  Noteshelf
//
//  Created by Sameer on 10/02/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
extension UIView {
    
    func offsetPointToParentCoordinates(point: CGPoint) -> CGPoint {
        return CGPoint(x: point.x + self.center.x,y: point.y + self.center.y)
    }
    
    func pointInViewCenterTerms(point:CGPoint) -> CGPoint {
        return CGPoint(x: point.x - self.center.x, y: point.y - self.center.y)
    }
    
    func pointInTransformedView(point: CGPoint) -> CGPoint {
        let offsetItem = self.pointInViewCenterTerms(point: point)
        let updatedItem = offsetItem.applying(self.transform)
        let finalItem = self.offsetPointToParentCoordinates(point: updatedItem)
        return finalItem
    }
    
    func originalFrame() -> CGRect {
        let currentTransform = self.transform
        self.transform = .identity
        let originalFrame = self.frame
        self.transform = currentTransform
        return originalFrame
    }
    
    //These four methods return the positions of view elements
    //with respect to the current transformation
    
    func transformedTopLeft() -> CGPoint {
        let frame = self.originalFrame()
        let point = frame.origin
        return self.pointInTransformedView(point: point)
    }
    
    func transformedTopMid() -> CGPoint {
        let frame = self.originalFrame()
        var point = frame.origin
        point.x += frame.size.width / 2
        return self.pointInTransformedView(point: point)
    }
    
    func transformedTopRight() -> CGPoint {
        let frame = self.originalFrame()
        var point = frame.origin
        point.x += frame.size.width
        return self.pointInTransformedView(point: point)
    }
    
    func transformedRightMid() -> CGPoint {
        let frame = self.originalFrame()
        var point = frame.origin
        point.x += frame.size.width
        point.y += frame.size.height / 2
        return self.pointInTransformedView(point: point)
    }
    
    func transformedBottomRight() -> CGPoint {
        let frame = self.originalFrame()
        var point = frame.origin
        point.x += frame.size.width
        point.y += frame.size.height
        return self.pointInTransformedView(point: point)
    }
    
    func transformedBottomMid() -> CGPoint {
        let frame = self.originalFrame()
        var point = frame.origin
        point.x += frame.size.width / 2
        point.y += frame.size.height
        return self.pointInTransformedView(point: point)
    }
    
    func transformedBottomLeft() -> CGPoint {
        let frame = self.originalFrame()
        var point = frame.origin
        point.y += frame.size.height
        return self.pointInTransformedView(point: point)
    }
    
    func transformedLeftMid() -> CGPoint {
        let frame = self.originalFrame()
        var point = frame.origin
        point.y += frame.size.height / 2
        return self.pointInTransformedView(point: point)
    }
    
    public func contentFrame() -> CGRect {
        let transform = self.transform;
        let anchorPoint = self.layer.anchorPoint
        self.setAnchorPoint(anchorPoint: CGPoint(x: 0.5, y: 0.5))
        self.transform = CGAffineTransform.identity;
        let frame = self.frame;
        self.transform = transform;
        self.setAnchorPoint(anchorPoint: anchorPoint)
        return frame;
    }
    
    
    func transformedRotateHandle(with offSet: CGFloat) -> CGPoint {
        let frame = self.originalFrame()
        var point = frame.origin
        point.x += frame.size.width / 2
        point.y += frame.size.height + offSet
        return self.pointInTransformedView(point: point)
    }
    
    func transformedRotateDegree() -> CGPoint {
        let frame = self.originalFrame()
        var point = frame.origin
        point.x += frame.size.width / 2
        point.y -= 30
        return self.pointInTransformedView(point: point)
    }
    
//    func setAnchorPoints(anchorPoint:CGPoint) {
//        var newPoint = CGPoint(x: self.bounds.size.width * anchorPoint.x, y: self.bounds.size.height * anchorPoint.y)
//        var oldPoint = CGPoint(x: self.bounds.size.width * self.layer.anchorPoint.x, y: self.bounds.size.height * self.layer.anchorPoint.y)
//
//        newPoint = newPoint.applying(self.transform)
//        oldPoint = oldPoint.applying(self.transform)
//
//        var position = self.layer.position
//        position.x -= oldPoint.x
//        position.x += newPoint.x
//        position.y -= oldPoint.y
//        position.y += newPoint.y
//
//        self.layer.position = position
//        print("Position ", position)
//        self.layer.anchorPoint = anchorPoint
//    }
    
    func setAnchorPoint(anchorPoint: CGPoint) {
        let oldOrigin = self.frame.origin
        self.layer.anchorPoint = anchorPoint
        let newOrigin = self.frame.origin
        let translation = CGPoint(x: newOrigin.x - oldOrigin.x, y: newOrigin.y - oldOrigin.y)
        self.center = CGPoint(x: self.center.x - translation.x, y: self.center.y - translation.y)
    }
    
    func nearestNextSnapAngle(angleInRadians: CGFloat) -> CGFloat {
        let angle = self.angleWRT360Degree(angleInRadians: angleInRadians)
        let angleQuotent = Int(angle/ANGLE_JUMP)
        let newAngle = CGFloat(angleQuotent)*ANGLE_JUMP+ANGLE_JUMP
        return newAngle
    }

    func nearestPrevSnapAngle(angleInRadians : CGFloat) -> CGFloat {
        let angle = self.angleWRT360Degree(angleInRadians: angleInRadians)
        let angleQuotent = Int(angle/ANGLE_JUMP)
        let previous90 = CGFloat(angleQuotent)*ANGLE_JUMP
        return previous90
    }

    func angleWRT360Degree(angleInRadians : CGFloat) -> CGFloat {
        var angle = round(angleInRadians*RADIANS_TO_DEGREE)
        if(abs(angle) < 0.01) {
            angle = 0
        }
        let angleWrt360 = Int(abs(angle)/360)
        
        if(angle < 0) {
            angle = (CGFloat(angleWrt360)*360.0)+angle
        }
        else {
            angle -= (CGFloat(angleWrt360)*360)
        }
        
        if(angle < 0) {
            angle = 360.0 + angle
        }
        if(angle >= 360.0) {
            angle = (angle - 360.0)
        }
        return angle
    }
    
    func currentViewAngle() -> CGFloat {
        return self.transform.angle
    }

    func setRotationAngle(_ angleInRadians: CGFloat) {
        self.transform  = self.transform.rotated(by: angleInRadians)
    }
    
    func isAngleNearToSnapArea(byAddingAngle angleInRadians: CGFloat) -> Bool {
        let angle = self.angleWRT360Degree(angleInRadians: self.currentViewAngle()+angleInRadians)
        let previous90 = self.nearestPrevSnapAngle(angleInRadians: self.currentViewAngle()+angleInRadians)
        let next90 = self.nearestNextSnapAngle(angleInRadians: self.currentViewAngle()+angleInRadians)
        
        if(abs(angle - previous90) <= THRESHOLD_ANGLE) {
            return true
        }
        else if(abs(next90 - angle) <= THRESHOLD_ANGLE) {
            return true
        }
        return false
    }
    
    func snapToNear90IfNeeded(byAddingAngle angleInRadians: CGFloat) -> (isNearst90: Bool, angle: CGFloat)
    {
        let angle = self.angleWRT360Degree(angleInRadians: self.currentViewAngle())
        let angleToConsider = self.angleWRT360Degree(angleInRadians: self.currentViewAngle()+angleInRadians)
        
        let previous90 = self.nearestPrevSnapAngle(angleInRadians: self.currentViewAngle())
        let next90 = self.nearestNextSnapAngle(angleInRadians: self.currentViewAngle())
        
        var nearestAngle = angle
        if(abs(angleToConsider - previous90) <= THRESHOLD_ANGLE) {
             nearestAngle = previous90 - angle
            if(abs(nearestAngle) > 0.01)  {
                return (true, nearestAngle*DEGREE_TO_RADIANS)
            }
        }
        else if(abs(next90 - angleToConsider) <= THRESHOLD_ANGLE) {
             nearestAngle = next90 - angle
            if(abs(nearestAngle) > 0.01)  {
                return (true, nearestAngle*DEGREE_TO_RADIANS)
            }
        }
        return (false, nearestAngle)
    }
}
