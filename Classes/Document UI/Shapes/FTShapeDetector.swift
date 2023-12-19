//
//  FTShapeDetector.swift
//  Noteshelf
//
//  Created by Narayana on 22/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTShapeDetectorDelegate: NSObjectProtocol {
    
    func addShapeSegment(for stroke: FTStroke!,
                         from startPoint: CGPoint,
                         to endPoint: CGPoint,
                         brushWidth penWidth: CGFloat,
                         opacity: CGFloat)
    
    func trackShape(shapeName: String)
}

class FTShapeDetector: NSObject {
    
    weak var delegate: FTShapeDetectorDelegate?
    
    //For Write and Hold
    static let minimumHoldinterval : TimeInterval = 0.4
    private static let minimumStrokeSize : CGSize = CGSize(width: 10, height: 10)
    private static let minimumMovement : CGFloat = 0.3
    
    init(delegate inDelegate: FTShapeDetectorDelegate?) {
        super.init()
        delegate = inDelegate
    }
    
    func detectShape(for currentStroke: FTStroke, scale: CGFloat) -> [FTStroke] {
        var strokes: [FTStroke] = []
        var avgThickness: CGFloat = 0.0
        var avgAlpha: CGFloat = 0.0
        
        let strokePoints = currentStroke.points(averageThickness: &avgThickness, averageAlpha: &avgAlpha)
        let factory = FTShapeFactory()
        let shape = factory.getShapeForPoints(strokePoints)
        shape?.validate()
        
        if let _shape = shape,let stroke = self.stroke(for: _shape, stroke: currentStroke, thickness: avgThickness, alpha: avgAlpha, scale: scale) {
            strokes.append(stroke)
        }
        
        self.delegate?.trackShape(shapeName: shape?.shapeName() ?? "UnKnown")
        return strokes
    }
    
    func stroke(for shape: FTShape,
                stroke: FTStroke,
                thickness: CGFloat,
                alpha: CGFloat, scale: CGFloat) -> FTStroke? {
        var shapesPoints = shape.drawingPoints(scale: scale)
        //TODO - Refactor
        if let ellipseShape = shape as? FTShapeEllipse {
            let angle = ellipseShape.rotatedAngle;
            ellipseShape.rotatedAngle = 0;
            shapesPoints = shape.drawingPoints(scale: scale);
            ellipseShape.rotatedAngle = angle;
        }
        guard !shapesPoints.isEmpty else {
            return nil;
        }
        let selectedColor = stroke.strokeColor
        let strokeWidth = stroke.strokeWidth
        let penType = stroke.penType
        
        let newStroke = FTShapeAnnotation(withPage: stroke.associatedPage, shapeType: shape.type())
        newStroke.penType = penType
        newStroke.shape = shape
        newStroke.strokeColor = selectedColor
        newStroke.strokeWidth = strokeWidth
        newStroke.properties = FTShapeProperties(strokeThickness: thickness, strokeOpacity: alpha)
        newStroke.boundingRect = stroke.boundingRect
        newStroke.shapeData = FTShapeData(with: shape.type().rawValue, sides: shape.type().shapeSides(), strokeOpacity: alpha)
        if let shape = shape as? FTShapeEllipse {
            newStroke.rotatedAngle = shape.rotatedAngle
            if shape.rotatedAngle < 0 {
                newStroke.rotatedAngle = 360 + shape.rotatedAngle
            }
            newStroke.shapeTransformMatrix = CGAffineTransform(rotationAngle: (shape.rotatedAngle).degreesToRadians)
        }
        let points = removeDuplicates(points: shape.controlPoints())
        newStroke.setShapeControlPoints(points)
        //TODO - Refactor
        self.addSegments(shapesPoints, for: newStroke, brushWidth: thickness, alpha: alpha)
        if(newStroke.shape?.type() == .ellipse) {
            newStroke.regenerateStrokeSegments()
        }
        return newStroke
    }
    
    //When user draws straight line using highlighter, consider as stroke to avoid editing
    func detectedStrokeForLine(for shape: FTShape,
                    stroke: FTStroke,
                    thickness: CGFloat,
                               alpha: CGFloat, scale: CGFloat) -> FTStroke? {
        
        let shapesPoints = shape.drawingPoints(scale: scale)
        guard !shapesPoints.isEmpty else {
            return nil;
        }
        let selectedColor = stroke.strokeColor
        let strokeWidth = stroke.strokeWidth
        let penType = stroke.penType
        
        var newStroke = FTStroke()
        if let page = stroke.associatedPage {
            newStroke = FTStroke(withPage: page)
        } else {
            newStroke = FTStroke(withPage: nil)
        }
        newStroke.penType = penType
        newStroke.strokeColor = selectedColor
        newStroke.strokeWidth = strokeWidth
        
        self.addSegments(shapesPoints, for: newStroke, brushWidth: thickness, alpha: alpha)
        return newStroke
    }
    
    private func removeDuplicates(points: [CGPoint]) -> [CGPoint] {
        return points.removeDuplicates().uniqueElements
    }
    
    func addSegments(_ drawingPoints:  [CGPoint],
                     for inStroke: FTStroke?,
                     brushWidth: CGFloat,
                     alpha avgAlpha: CGFloat) {
        if let inStroke = inStroke {
            inStroke.boundingRect = .null
            inStroke.segmentArray.removeAll();
            inStroke.segmentCount = 0;
            inStroke.segmentsTransientArray.removeAll();
        }
        for (idx,obj) in drawingPoints.enumerated() where idx > 0 {
            let startPoint = drawingPoints[idx - 1]
            let endPoint = obj

            var alpha: CGFloat = 1.0
            if inStroke?.penType == .pencil {
                alpha = avgAlpha
            }
            delegate?.addShapeSegment(for: inStroke,
                                      from: startPoint,
                                      to: endPoint,
                                      brushWidth: brushWidth,
                                      opacity: alpha)
        }
    }
    
    func detectedLineFor(stroke currentStroke: FTStroke, scale: CGFloat) -> ([FTStroke],Bool) {
        var strokes: [FTStroke] = []
        var avgThickness: CGFloat = 0.0
        var avgAlpha: CGFloat = 0.0
        
        let strokePoints = currentStroke.points(averageThickness: &avgThickness, averageAlpha: &avgAlpha)
        let factory = FTShapeFactory()
        let shape = factory.getShapeForPoints(strokePoints)
        shape?.validate()
        if let _shape = shape, _shape.type() == .line, let stroke = self.detectedStrokeForLine(for: _shape, stroke: currentStroke, thickness: avgThickness, alpha: avgAlpha, scale: scale) {
            strokes.append(stroke)
            return (strokes,true)
        }
        return ([],false)
    }
    
    static func canDetectShape(stroke: FTStroke,scale : CGFloat) -> Bool {
        let strokeWidth = stroke.strokeWidth;
        let rect = stroke.boundingRect;
        let boundingRect = CGRect(origin: .zero, size: minimumStrokeSize).insetBy(dx: -strokeWidth/2, dy: -strokeWidth/2)
        let scaledBoundingRect = CGRectScale(boundingRect, scale)
        if (rect.width*scale) < scaledBoundingRect.width && rect.height*scale < scaledBoundingRect.height {
            return false
        }
        return true
    }
    
    static func canConsiderAsLongPress(touch: FTTouch) -> Bool {
        let from = touch.activeUItouch.location(in: touch.activeUItouch.view);
        let to = touch.activeUItouch.previousLocation(in: touch.activeUItouch.view)
         let type = touch.activeUItouch.type
         let distance = from.quadrance(to: to)
         let thresholdDistance = (type == .pencil) ? 0.003 : 0.25
         if  distance > thresholdDistance {
             return false
         }
         return true;
     }
}

extension CGPoint {
    func quadrance(to point: CGPoint) -> Double {
        return pow(Double(x) - Double(point.x), 2) + pow(Double(y) - Double(point.y), 2)
    }
}

extension Array where Element:Equatable {
    func removeDuplicates() -> (uniqueElements: [Element], duplicateExists: Bool) {
        var result = [Element]()
        var duplicateExists = false
        for value in self {
            if result.contains(value) == false {
                result.append(value)
            } else {
                duplicateExists = true
            }
        }
        return (result, duplicateExists)
    }
    
    func indexes(of element: Element) -> [Int] {
        return self.enumerated().filter({ element == $0.element }).map({ $0.offset })
    }

}
