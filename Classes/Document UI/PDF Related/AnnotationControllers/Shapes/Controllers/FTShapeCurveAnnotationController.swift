//
//  FTShapeCurveAnnotationController.swift
//  Noteshelf3
//
//  Created by Fluid Touch on 26/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTShapeCurveAnnotationController: FTShapeAnnotationController {
    var isKnobAdded = false
    required init?(withAnnotation annotation: FTAnnotation, delegate: FTAnnotationEditControllerDelegate?, mode: FTAnnotationMode) {
        super.init(withAnnotation: annotation, delegate: delegate, mode: mode)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        resetDisplayLink()
    }
    
    override func processTouchesMoved(_ firstTouch: UITouch, with event: UIEvent?) {
        hideKnobViews(true)
        if shapeEditType == .resize , !annotation.inLineEditing , let knob = currentKnob {
            var point = firstTouch.location(in: self.view)
            let prevPoint = firstTouch.previousLocation(in: self.view)
            let deltax = prevPoint.x - point.x
            let deltay = prevPoint.y - point.y
            let points = shapeAnnotation.getshapeControlPoints()
            if knob.segmentIndex == 1, points.count >= 3 {
                var controlPoint = convertControlPoint(points[1])
                controlPoint.x -= deltax * 2
                controlPoint.y -= deltay * 2
                point = controlPoint
            }
            index = knob.segmentIndex
            updateSegments(index: index, point: point)
            if knob.segmentIndex == 1 {
                knob.center = self.point(at: 0.5)
            } else {
                knob.center = point
            }
        } else {
            super.processTouchesMoved(firstTouch, with: event)
            self.annotation.inLineEditing = false
        }
    }
    
    func updateContrlPointKnob() {
        view.subviews.forEach { eachView in
            if let knobView = eachView as? FTKnobView, knobView.segmentIndex == 1 {
                knobView.center = self.point(at: 0.5)
            }
        }
    }
    
    override func processTouchesEnded(_ firstTouch: UITouch, with event: UIEvent?) {
        super.processTouchesEnded(firstTouch, with: event)
        updateContrlPointKnob()
    }
    
    override func addKnobsForControlPoints() {
        let points = self.shapeAnnotation.getshapeControlPoints()
        if let firstPoint = points.first, let lastPoint = points.last {
            let controlPoint = point(at: 0.5)
            let knobPoints = [firstPoint, controlPoint, lastPoint]
            for (i, ftPoint) in knobPoints.enumerated() {
                var point = convertControlPoint(ftPoint)
                if i == 1 {
                    point = ftPoint
                }
                let knobView = FTKnobView()
                knobView.segmentIndex = i
                knobView.center = point
                view.addSubview(knobView)
            }
        }
    }
    
    public func point(at t: CGFloat) -> CGPoint {
        let points = shapeAnnotation.getshapeControlPoints()
        guard points.count >= 3 else {
            return .zero
        }
        let p0 = convertControlPoint(points[0])
        let p1 = convertControlPoint(points[1])
        let p2 = convertControlPoint(points[2])
        if t == 0 {
            return p0
        } else if t == 1 {
            return p2
        }
        let mt = 1.0 - t
        let mt2: CGFloat    = mt*mt
        let t2: CGFloat     = t*t
        let a = mt2
        let b = mt * t*2
        let c = t2
        let temp1 = CGPoint(x: a * p0.x, y: a * p0.y)
        let temp2 = CGPoint(x: b * p1.x, y: b * p1.y)
        let temp3 = CGPoint(x: c * p2.x, y: c * p2.y)

        let result = CGPoint(x: temp1.x + temp2.x + temp3.x, y: temp1.y + temp2.y + temp3.y)

        return result
    }
   
    override func isPointInside(_ newPoint: CGPoint, fromView: UIView) -> Bool {
        let finalPoint = newPoint.scaled(scale: 1 / scale)
        let point = convertTappedPoint(newPoint)
        var returnValue = shapeAnnotation.allowsSingleTapSelection(atPoint: finalPoint)
        if returnValue {
            return returnValue
        }
        for eachKnob in self.view.subviews {
            if (eachKnob is FTKnobView || eachKnob is FTRotateKnobView) {
                let frame = convertedViewFrame(eachKnob)
                if frame.contains(newPoint) {
                    returnValue = true
                    break
                }
            }
        }
        return returnValue
    }
    
    override func updateKnobViews(with refPoints: [CGPoint] = []) {
        super.updateKnobViews(with: refPoints)
        updateContrlPointKnob()
    }
}
