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
        if shapeEditType == .resize {
            hideKnobViews(true)
            var point = firstTouch.location(in: self.view)
            let prevPoint = firstTouch.previousLocation(in: self.view)
            let deltax = prevPoint.x - point.x
            let deltay = prevPoint.y - point.y
            if let knob = currentKnob {
                if knob.segmentIndex == 1 {
                    var controlPoint = shapeAnnotation.getshapeControlPoints()[1]
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
            }
        } else {
            super.processTouchesMoved(firstTouch, with: event)
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
    
    public func point(at t: CGFloat) -> CGPoint {
        let points = shapeAnnotation.getshapeControlPoints()
        let p0 = points[0]
        let p1 = points[1]
        let p2 = points[2]
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
   
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if isTwoFingerRotationInProgress(touches, with: event) {
//            super.touchesBegan(touches, with: event)
//            return
//        }
//        guard let touch = touches.first else {
//            return
//        }
//        updateGestures(touch: touch)
//        processTouchesBegan(touch, with: event)
//    }
//
//    
//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        processTouchesMoved(touches.first!, with: event)
//    }
//    
//    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        self.delayedEnableGesture();
//        processTouchesEnded(touches.first!, with: event)
//    }
//    
//    override func addKnobsForControlPoints() {
//        let controlPoint = (shapeAnnotation.shape as? FTShapeCurve)?.point(at: 0.5) ?? curvePoints[1]
//        let points = [curvePoints[0], controlPoint, curvePoints[2]]
//        for (i, ftPoint) in points.enumerated() {
//            let point = convertControlPoint(ftPoint)
//            let knobView = FTKnobView()
//            knobView.segmentIndex = i
//            knobView.center = point
//            view.addSubview(knobView)
//        }
//        isKnobAdded = true
//    }
//    
//    override func processTouchesBegan(_ firstTouch: UITouch, with event: UIEvent?) {
//        let point = firstTouch.location(in: self.view)
//        let convertedPoint = convertPoint(point)
//        let knobView = isPointInsdeKnobView(point: point)
//        touchTime = DispatchTime.now()
//        if let knob = knobView as? FTKnobView {
//            currentKnob = knob
//            knob.center = point
//            index = knob.segmentIndex
//            shapeEditType = .resize;
//        } else if (knobView as? FTRotateKnobView) != nil {
//            super.processTouchesBegan(firstTouch, with: event)
//        } else if shapeAnnotation.allowsSingleTapSelection(atPoint: convertedPoint) {
//           super.processTouchesBegan(firstTouch, with: event)
//        } else if self.annotationMode == .create {
//            removeKnobViews()
//            isKnobAdded = false
//            shapeAnnotation.setShapeControlPoints([convertedPoint, convertedPoint])
//            if resizableView == nil {
//                resizableView = FTEmptyView(frame: shapeAnnotation.defaultBoundingRect)
//                resizableView?.delegate = self
//                if let resizableView = resizableView {
//                    self.view.addSubview(resizableView)
//                    resizableView.updateDragHandles()
//                }
//            }
//            hideKnobViews(true)
//        }
//        self.displayLink?.isPaused = false
//    }
//    
//    override func processTouchesMoved(_ firstTouch: UITouch, with event: UIEvent?) {
//        let point = firstTouch.location(in: self.view)
//        if (currentKnob != nil) || shapeEditType == .rotate || shapeEditType == .move {
//            super.processTouchesMoved(firstTouch, with: event)
//        } else if self.annotationMode == .create {
//            updateSegments(index: index, point: point)
//        } else {
//            if shapeAnnotation.shape?.type() == .line {
//                super.processTouchesMoved(firstTouch, with: event)
//            }
//        }
//    }
//    
//    override func processTouchesEnded(_ firstTouch: UITouch, with event: UIEvent?) {
//        if removeShapeIfNeeded() {
//            return
//        }
//        shouldSaveAnnotation = true;
//        angleSnappingView?.isHidden = true
//        resizableView?.showAngleInfoView(show: false)
//        hideKnobViews(false)
//        NSObject.cancelPreviousPerformRequests(withTarget: self,
//                                               selector: #selector(generateStrokeSegments),
//                                               object: nil)
//        self.perform(#selector(generateStrokeSegments), with: nil, afterDelay: 0.1);
//        if !isKnobAdded {
//            addKnobsForControlPoints()
//        }
//        updateFreeFormShapeRect()
//        if annotationMode == .create {
//            updateBoundingRect()
//        }
//        self.displayLink?.isPaused = true
//        publishChanges(nil)
//        NotificationCenter.default.post(name: Notification.Name(FTPDFEnableGestures), object: self.view.window);
//        _setupTapGestures()
//        trackControlPointDrag()
//        resetActions()
//        addAngleSnappingView()
//    }
//    
//    func _setupTapGestures() {
//        if tapGesture == nil {
//            tapGesture = UITapGestureRecognizer(target: self, action: #selector(_didTap(tap:)));
//            tapGesture?.numberOfTapsRequired = 1
//            tapGesture?.cancelsTouchesInView = false
//            if let tapGesture = tapGesture {
//                resizableView?.addGestureRecognizer(tapGesture)
//            }
//        }
//        if let resizableView = resizableView {
//            _setUpRotateHandleGesture()
//            setUpFingerRotateGesture()
//        }
//    }
//    
//    func _setUpRotateHandleGesture() {
//        if let rotateHandle = resizableView?.rotateHandle {
//            if rotateTapGesture == nil {
//                rotateTapGesture = FTRotateTapGesture(target: self, action: #selector(_rotateHandleTapped(_ :)))
//                rotateTapGesture?.numberOfTapsRequired = 1
//                rotateTapGesture?.cancelsTouchesInView = false
//                rotateHandle.addGestureRecognizer(rotateTapGesture!)
//            }
//        }
//    }
//    
//    @objc fileprivate func _didTap(tap: UITapGestureRecognizer) {
//        if (tap.state == .recognized) {
//            showMenu(true)
//        }
//    }
//    
//    @objc  func _rotateHandleTapped(_ gesture: UITapGestureRecognizer) {
//        if gesture.state == .recognized {
//            resizableView?.rotateHandleTapped()
//            trackRotateTapped()
//        }
//    }
//    
//    override func updateSegments(index: Int, point: CGPoint) {
//        let contentOffset = self.delegate?.visibleRect().origin ?? .zero
//        let convertedTappedPoint = CGPointTranslate(point, contentOffset.x, contentOffset.y);
//        let finalPoint = convertedTappedPoint.scaled(scale: 1/self.scale)
//        shapeAnnotation.translateAt(index: index, to: finalPoint)
//    }
//
//    
//    override func isPointInside(_ newPoint: CGPoint, fromView: UIView) -> Bool {
//        let finalPoint = newPoint.scaled(scale: 1 / scale)
//        let point = convertTappedPoint(newPoint)
//        var returnValue = shapeAnnotation.allowsSingleTapSelection(atPoint: finalPoint)
//        if returnValue {
//            return returnValue
//        }
//        for eachKnob in self.view.subviews {
//            if (eachKnob is FTKnobView || eachKnob is FTRotateKnobView) {
//                let frame = convertedViewFrame(eachKnob)
//                if frame.contains(newPoint) {
//                    returnValue = true
//                    break
//                }
//            }
//        }
//        return returnValue
//    }
}
