//
//  FTShapeAnnotationController.swift
//  FTRenderDemo
//
//  Created by Akshay on 19/04/21.
//  Copyright © 2021 Fluid Touch. All rights reserved.
//

import UIKit
import FTRenderKit
@objc enum FTShapeEditAction: Int {
    case copy,cut,delete
}

enum FTShapeEditTye {
    case none,resize,move,rotate;
}

class FTShapeAnnotationController: FTAnnotationEditController {

    weak var delegate: FTAnnotationEditControllerDelegate?
    var annotationMode: FTAnnotationMode = FTAnnotationMode.create
    var shapeEditVC: FTShapeEditController?
    private var isEditMode: Bool  {
        return shapeEditType != .none;
    }
    var allowsLocking = false
    var annotation: FTAnnotation {
        return shapeAnnotation;
    }
    var supportOrientationChanges : Bool {
        return true
    }
    private var intialBoundingRect: CGRect = .null
    public var touchTime = DispatchTime.now()
    var shouldSaveAnnotation = false
    public var resizableView: FTResizableView?
    private var activeControlPoint : FTControlPoint = .none;
    var currentKnob: FTKnobView?
    public var displayLink : CADisplayLink?
    var shapeEditType = FTShapeEditTye.none;
    private var isSelected: Bool = false
    private var isMenuVisible: Bool = false
    private var _renderer : FTShapeRenderer?
    
    var index = 1
    let thresholdAngle: CGFloat = 10
    var lastPrevPointInRotation : CGPoint = CGPoint.zero;
    var shapeResizeObj: FTShapeResizing?
    var snappingView: FTSnapView?
    var angleSnappingView: FTLineDashView?
    var tapGesture: UITapGestureRecognizer?
    var rotateTapGesture: UITapGestureRecognizer?
    var fingerRotationGesture: UIRotationGestureRecognizer?
    var annotationStates: [FTAnnotationState]?
    var eventType: FTProcessEventType = .none
    private var renderer: FTShapeRenderer? {
        if _renderer == nil {
            _renderer = FTRendererFactory.createShapeRender(size: self.view.bounds.size)
        }
        _renderer?.bind(view: self.view as! FTMetalView)
        return _renderer
    }
    
    private(set) var shapeAnnotation: FTShapeAnnotation;
    private var initialUndoableInfo: FTUndoableInfo;
    // Don't make below viewmodel weak as this is needed for eyedropper delegate to be implemented here(since we are dismissing color edit controller)
    internal var penShortcutViewModel: FTPenShortcutViewModel?

    required init?(withAnnotation annotation: FTAnnotation, delegate: FTAnnotationEditControllerDelegate?, mode: FTAnnotationMode) {
        guard let _shapeAnnotation = annotation as? FTShapeAnnotation else {
            fatalError("Requires shape annotation")
        }
        annotationMode = mode
        shapeAnnotation = _shapeAnnotation
        initialUndoableInfo = annotation.undoInfo();
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
        let frame = delegate?.visibleRect() ?? .zero
        self.view.frame = frame
        self.allowsLocking = shapeAnnotation.allowsLocking
        shapeAnnotation.updateShapeType()
        intialBoundingRect = shapeAnnotation.boundingRect
        self.shapeResizeObj = FTShapeResizing.shapeResizeObject(shapeType: shapeAnnotation.shape?.type() ?? .rectangle)
        shapeResizeObj?.delegate = self
         if (shapeAnnotation.shape?.type() == .pentagon) {
            shapeAnnotation.updateShapeSides(sides: CGFloat(shapeAnnotation.shapeData.numberOfSides))
        }
        NotificationCenter.default.addObserver(forName: Notification.Name.didUpdateAnnotationNotification,
                                               object: annotation,
                                               queue: nil) { [weak self] (_) in
            self?.refreshView();
        }
        NotificationCenter.default.addObserver(forName: Notification.Name.didReplaceAnnotationNotification,
                                               object: shapeAnnotation,
                                               queue: nil) { [weak self] (_) in
            self?.didReplaceShape();
        }

        addPenAttributes(to: shapeAnnotation)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let view = FTShapeView(frame: UIScreen.main.bounds)
        view.parentVc = self
        view.layer.isOpaque = false;
        view.layer.backgroundColor = UIColor.clear.cgColor;
        self.view = view;
    }

    var scale : CGFloat {
        var scaleToReturn : CGFloat = 1;
        if let del = self.delegate {
            scaleToReturn = del.contentScale();
        }
        return scaleToReturn;
    };
    
    override func viewDidLoad() {
        super.viewDidLoad()

        #if DEBUG
//        if(FTDeveloperOption.showOnScreenBorder) {
//            self.view.layer.borderWidth = 5.0
//            self.view.layer.borderColor = UIColor.blue.cgColor
//        }
        #endif
        self.displayLink = CADisplayLink(target: self, selector: #selector(publishChanges))
        self.displayLink?.isPaused = true;
        self.displayLink?.add(to: RunLoop.current, forMode: RunLoop.Mode.default);
        if shapeAnnotation.inLineEditing {
            shapeEditType = .resize;
            self.displayLink?.isPaused = false;
        }
    }
    
    deinit {
        resetDisplayLink()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resetDisplayLink()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (annotationMode == .edit) {
            configureResizableView()
            shapeEditVC?.configureShapeEditView()
            addAngleSnappingView()
            addPenAttributes(to: shapeAnnotation)
            publishChanges(nil)
            setupTapGestures()
            if eventType == .longPress {
                track("shape_longpressed", screenName: FTScreenNames.shapes)
            } else {
                track("shape_tapped", screenName: FTScreenNames.shapes)
            }
            #if targetEnvironment(macCatalyst)
            if let resizableView = resizableView {
                let contextMenu = UIContextMenuInteraction.init(delegate: resizableView)
                resizableView.addInteraction(contextMenu)
            }
            #else
            if let annotationStates = annotationStates, annotationStates.contains(.showMenu) {
                showMenu(true)
            }
            #endif
        }
    }
    
    private func didReplaceShape() {
        endEditingAnnotation()
        self.delegate?.annotationControllerDidCancel(self)
    }
    
    private func configureResizableView() {
        var frame = CGRectScale(shapeAnnotation.shapeBoundingRect, scale)
        if frame.size == .zero {
            return
        }
        let offSet = self.delegate?.visibleRect().origin ?? CGPoint.zero
        frame.origin = CGPointTranslate(frame.origin, -offSet.x, -offSet.y)
        resizableView = FTResizableObject.resizableView(with: frame, isPerfectShape: shapeAnnotation.isPerfectShape())
        addKnobsForControlPoints()
        if let resizableView = resizableView {
            resizableView.delegate = self
            resizableView.transform = shapeAnnotation.shapeTransformMatrix
            self.view.addSubview(resizableView)
            resizableView.updateDragHandles()
        }
        updateFreeFormShapeRect()
    }
    
    override var canBecomeFirstResponder: Bool {
        return true;
    }
 
    @objc func publishChanges(_ displayLink : CADisplayLink?) {
        let renderRequest = FTOnScreenRenderRequest(with: self.view.window?.hash)
        renderRequest.annotations = [shapeAnnotation]
        renderRequest.backgroundColor = UIColor.white;
        renderRequest.areaToRefresh = self.view.frame;
        renderRequest.contentSize = self.delegate?.visibleRect().size ?? self.view.frame.size
        renderRequest.visibleArea = self.view.frame;
        renderRequest.scale = self.scale;
        _ = renderer?.render(request: renderRequest)
    }
}

//MARK: - Touches related
@objc extension FTShapeAnnotationController {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isTwoFingerRotationInProgress(touches, with: event) {
            super.touchesBegan(touches, with: event)
            return
        }
        guard let touch = touches.first else {
            return
        }
        updateGestures(touch: touch)
        processTouchesBegan(touch, with: event)
    }
    
    func isTwoFingerRotationInProgress(_ touches: Set<UITouch>, with event: UIEvent?) -> Bool {
        var touchesCount = touches.count;
        if let touchEvent = event {
            let localTouches = touchEvent.allTouches;
            touchesCount = (localTouches != nil) ? localTouches!.count : touchesCount;
        }
        if(touchesCount > 1 || self.shapeEditType == .rotate) {
           return true
        }
        return false
    }
    
    func updateGestures(touch: UITouch) {
            NotificationCenter.default.post(name: NSNotification.Name.init(FTPDFDisableGestures), object: self.view.window);
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        processTouchesMoved(touches.first!, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.delayedEnableGesture();
        processTouchesEnded(touches.first!, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.delayedEnableGesture();
        if removeShapeIfNeeded() {
            return
        }
    }
    
    public func processTouchesBegan(_ firstTouch: UITouch, with event: UIEvent?) {
        let point = firstTouch.location(in: self.view)
        let touchPoint = firstTouch.location(in: self.view.superview)
        let knobView = isPointInsdeKnobView(point: point)
        touchTime = DispatchTime.now()
        if let knob = knobView as? FTKnobView  {
            shapeEditType = .resize;
            if let resizableView = resizableView, shapeAnnotation.isPerfectShape() {
                activeControlPoint = resizableView.getActiveControlPoint(for: knob)
                setAnchorPoint()
            } else {
                currentKnob = knob
                index = knob.segmentIndex
            }
            if shapeAnnotation.shape?.type() == .pentagon {
                shapeEditVC?.removeCircleView()
            }
        } else if (knobView as? FTRotateKnobView) != nil {
            didBeganRotation(at: point)
        } else if let resizableView = resizableView, resizableView.frame.contains(point) || self.isPointInside(touchPoint, fromView: self.view) {
            self.shapeEditType = .move
            self.hideMenu()
            if shapeAnnotation.shape?.type() == .pentagon {
                shapeEditVC?.removeCircleView()
            }
        } else if annotationMode == .create && shapeAnnotation.isPerfectShape() {
            drawFactoryShape(with: point)
            activeControlPoint = .bottomRight
            setAnchorPoint()
        }
        self.displayLink?.isPaused = false
    }
    
    public func processTouchesMoved(_ firstTouch: UITouch, with event: UIEvent?) {
        hideKnobViews(true)
        let point = firstTouch.location(in: self.view)
        let prevPoint = firstTouch.previousLocation(in: self.view)
        if let knob = currentKnob {
            knob.center = point
            index = knob.segmentIndex
            updateSegments(index: index, point: point)
        } else if activeControlPoint != .none {
            processShapeResizing(touch: firstTouch, point: point)
        } else if shapeEditType == .rotate {
            processShapeRotate(curPoint: point, prevPoint: prevPoint)
        } else if shapeEditType == .move {
            processShapeMoving(curPoint: point, prevPoint: prevPoint)
        } else {
            if shapeAnnotation.shape?.type() == .ellipse {
                processEllipseShapeResizing(touch: firstTouch)
            } else if shapeAnnotation.isPerfectShape(), let controlPoint = resizableView?.activeControlPoint(for: point) {
                activeControlPoint = controlPoint
                setAnchorPoint()
                processShapeResizing(touch: firstTouch, point: point)
            } else {
                let points = shapeAnnotation.getshapeControlPoints()
                guard !points.isEmpty else {
                    return
                }
                index = points.count - 1
                if shapeAnnotation.shape?.isClosedShape ?? false {
                    index = 0
                }
                currentKnob = activeKnob(for: points[index])
                currentKnob?.center = point
                updateSegments(index: index, point: point)
            }
        }
    }
    
    private func processEllipseShapeResizing(touch: UITouch) {
        guard let resizableView, let shapeResizeObj = shapeResizeObj else {
            return
        }
        let minSize: CGFloat = 20
        let center = resizableView.center
        let newFrame = shapeResizeObj.resizeProportionally(for: touch, in: resizableView)
        let shouldResize = (newFrame.width > minSize && newFrame.height > minSize)
        if shouldResize {
            self.updateContentFrame(with: newFrame, updateCenter: true)
//            resizableView.center = resizableView.centerWithinBoundary(center)
            updateEllipseRect()
            shapeAnnotation.setShapeControlPoints(drawingPoints())
            resizableView.updateDragHandles()
        }
    }
    
    private func activeKnob(for point: CGPoint) -> FTKnobView? {
        let convertedPoint = convertControlPoint(point)
        let view = view.subviews.first { eachView in
            return eachView.center == convertedPoint
        }
       return view as? FTKnobView
    }
    
    public func processTouchesEnded(_ firstTouch: UITouch, with event: UIEvent?) {
        if removeShapeIfNeeded() {
            return
        }
        shouldSaveAnnotation = true;
        finalizeTouchesEnded(for: firstTouch)
    }
    
    func didRemoveAnnotation() {
        self.delegate?.annotationControllerDidRemoveAnnotation(self, annotation: shapeAnnotation)
        resetDisplayLink()
    }
}

//MARK: - FTAnnotationEditControllerInterface
extension FTShapeAnnotationController {
    func endEditingAnnotation() {
        if (shouldSaveAnnotation || self.annotationMode == .edit) {
            handleAnnotationChanges()
            if self.delegate?.isZoomModeEnabled() ?? false {
                var refreshRect = shapeAnnotation.boundingRect
                if intialBoundingRect != .null {
                    refreshRect = refreshRect.union(intialBoundingRect)
                }
                let notification = Notification.init(name: Notification.Name.FTZoomRenderViewDidEndCurrentStroke,
                                                     object: self.view.window,
                                                     userInfo: [FTImpactedRectKey : NSValue.init(cgRect: refreshRect)]);
                NotificationCenter.default.post(notification);
            }
        }
    }
    
    private func handleAnnotationChanges() {
        if annotationMode == .edit {
            (self.shapeAnnotation.associatedPage as? FTPageTileAnnotationMap)?.tileMapRemoveAnnotation(shapeAnnotation)
        }
        updateBoundingRect()
        if let resizableView = resizableView {
            shapeAnnotation.shapeTransformMatrix = resizableView.transform
        }
        if annotationMode == .edit {
            (self.shapeAnnotation.associatedPage as? FTPageTileAnnotationMap)?.tileMapAddAnnotation(shapeAnnotation);
        }
        if(self.annotationMode == FTAnnotationMode.create) {
            self.delegate?.annotationControllerDidAddAnnotation(self, annotation: self.annotation)
            self.annotationMode = FTAnnotationMode.edit
        }
        else {
            self.delegate?.annotationControllerDidChange(self,undoableInfo: self.initialUndoableInfo);
        }
    }
    
    func annotationControllerLongPressDetected() {
        if !self.isFreeForm() && annotationMode == .create {
            didRemoveAnnotation()
         }
    }

    func updateBoundingRect() {
        if shapeAnnotation.isPerfectShape() {
            var rect: CGRect = contentFrame()
            // translate resizable view's origin w.r.t visible area
            let contentOffset = self.delegate?.visibleRect().origin ?? .zero
            rect.origin = CGPointTranslate(rect.origin, contentOffset.x, contentOffset.y);
            shapeAnnotation.shapeBoundingRect =  CGRectScale(rect, 1 / scale)
        }
    }
    
    func resetDisplayLink() {
        self.displayLink?.invalidate();
        self.displayLink = nil;
    }

    func processEvent(_ eventType: FTProcessEventType,at point:CGPoint) {
        let states = self.state(forEvent: eventType)
        
        if states.contains(.select) {
            isSelected = true
        }
       
        if states.contains(.showMenu) {
            showMenu(true)
        }
        
        if states.contains(.hideMenu) {
            showMenu(false)
        }
    }
    
    private func state(forEvent eventType: FTProcessEventType) -> [FTAnnotationState] {
        var states: [FTAnnotationState] = []
        if eventType == .none {
            states = [.select, .edit]
        } else {
            if self.isSelected {
                states = isMenuVisible ? [.hideMenu] : [.showMenu]
            } else {
                switch eventType {
                case .longPress:
                    states = [.select, .showMenu]
                case .singleTap:
                    states = [.select, .edit]
                default:
                    break
                }
            }
        }
        annotationStates = states
        return states
    }

    func refreshView() {
        if let resizableView = resizableView {
            let currentTransform = resizableView.transform
            resizableView.transform = shapeAnnotation.shapeTransformMatrix
            let currentFrame = resizableView.frame;
            let currentScale = self.delegate?.contentScale() ?? 1;
            let newFrameToSet = CGRect.scale(shapeAnnotation.shapeBoundingRect, currentScale);
            if newFrameToSet.integral != currentFrame.integral
               || currentTransform != shapeAnnotation.shapeTransformMatrix {
                self.initialUndoableInfo = shapeAnnotation.undoInfo()
                self.updateContentFrame(with: newFrameToSet)
                resizableView.updateDragHandles()
                if !shapeAnnotation.isPerfectShape() {
                    updateKnobViews()
                }
                publishChanges(nil)
           }
        }
    }

    func saveChanges() {
        handleAnnotationChanges()
    }

    func isPointInside(_ newPoint: CGPoint, fromView: UIView) -> Bool {
        let finalPoint = newPoint.scaled(scale: 1 / scale)//convertPoint(newPoint)
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
        if shapeAnnotation.isPerfectShape() && !returnValue {
            returnValue = _isPointInsideFrame(newPoint)
        } else {
           if let resizableView = resizableView {
               let frame = convertedViewFrame(resizableView)
               if frame.contains(newPoint) {
                   returnValue = true
               }
           }
        }

        if let shapeEditvc = shapeEditVC {
            let newPoint = self.view.convert(point, to: shapeEditvc.view)
            if shapeEditvc.knobView(for: newPoint) != nil {
                returnValue = true
            }
        }
        return returnValue
    }
    
    func convertedViewFrame(_ view: UIView) -> CGRect {
        let contentOffset = (self.delegate?.visibleRect().origin ?? .zero)
        let newOriginPoint = CGPointTranslate(view.frame.origin, contentOffset.x, contentOffset.y)
        return CGRect(origin: newOriginPoint, size: view.frame.size)
    }

    func updateViewToCurrentScale(fromScale: CGFloat) {
        if scale != fromScale {
            self.view.frame = scaledRect(for: view.frame, fromScale: fromScale);
            let scaledRect = scaledRect(for: self.contentFrame(), fromScale: fromScale)
            updateContentFrame(with: scaledRect)
            resizableView?.updateDragHandles()
            
            if !(shapeAnnotation.isPerfectShape()) {
                var points = shapeAnnotation.getshapeControlPoints()
                for  index in points.indices {
                    let eachPoint = points[index]
                    let scaleDownPoint = eachPoint.scaled(scale: 1/fromScale)
                    let scaleUpPoint = scaleDownPoint.scaled(scale: fromScale)
                    points[index] = scaleUpPoint
                }
                updateKnobViews(with: points)
            }
        }
    }
    
    private func scaledRect(for frame: CGRect, fromScale: CGFloat) -> CGRect {
        var currentFrame = frame
        currentFrame = CGRectScale(currentFrame, 1/fromScale);
        let newFrame = CGRectScale(currentFrame, scale);
        return newFrame
    }
    
    private func updateContentFrame(with rect : CGRect, updateCenter: Bool = false) {
        if let resizableView = resizableView, !(rect.isInfinite) {
            let transform = resizableView.transform;
            let center = resizableView.center;
            resizableView.transform = CGAffineTransform.identity;
            resizableView.frame = rect;
            resizableView.transform = transform;
            if updateCenter {
                resizableView.center = center
            }
        } else {
            FTLogError("frameToSet is isInfinite");
        }
    }
    
    func resetActions() {
        currentKnob = nil
        activeControlPoint = .none
        shapeEditType = .none
        hideKnobViews(false)
    }
    
    func trackControlPointDrag() {
        if annotationMode == .edit && isEditMode {
            if currentKnob != nil {
                let eventName = shapeAnnotation.isPerfectShape() ? "shape_controlpoint_dragged" : "freeform_controlpoint_dragged"
                track(eventName,screenName: FTScreenNames.shapes)
            } else if activeControlPoint != .none {
                track("shape_controlpoint_dragged",screenName: FTScreenNames.shapes)
            }
        }
    }
}

//MARK: - Shape resizing, moving, rotation
private extension FTShapeAnnotationController {
    func processShapeResizing(touch: UITouch, point: CGPoint) {
        if let shapeResizeObj = shapeResizeObj {
            if let resizableView = resizableView {
                let frame  = shapeResizeObj.resizedBoundingRect(for: touch, in: resizableView, rect: resizableView.contentFrame(), scale: scale, activeControlPoint: activeControlPoint)
                self.updateContentFrame(with: frame, updateCenter: true)
                shapeEditVC?.view.bounds = resizableView.bounds
                updateEllipseRect()
                if shapeAnnotation.shouldSnapShape() {
                    if validatePerfectShape() {
                        addSnappingView()
                    }  else {
                        removeSnappingView()
                    }
                }
                shapeAnnotation.setShapeControlPoints(drawingPoints())
                resizableView.updateDragHandles()
            }
        }
    }
    
    func updateEllipseRect() {
        if let resizableView = resizableView, shapeAnnotation.shape?.type() == .ellipse {
            let size = resizableView.contentFrame().size
            var newRect = CGRect(origin: resizableView.contentFrame().origin, size: size)
            let contentOffset = (self.delegate?.visibleRect().origin ?? .zero)
            newRect.origin = CGPointTranslate(newRect.origin, contentOffset.x, contentOffset.y);
            newRect = CGRectScale(newRect, 1 / scale)
            shapeAnnotation.shapeBoundingRect = newRect;
            shapeAnnotation.rotatedAngle = resizableView.transform.angle.radiansToDegrees
        }
    }
    
    func processShapeMoving(curPoint: CGPoint, prevPoint: CGPoint) {
        updateResizableView(curPoint: curPoint, prevPoint: prevPoint)
        if !shapeAnnotation.isPerfectShape() {
            let scaledPrevPoint = convertPoint(prevPoint)
            let scaledCurPoint = convertPoint(curPoint)
            let yOffset = scaledPrevPoint.y - scaledCurPoint.y;
            let xoffSet = scaledPrevPoint.x - scaledCurPoint.x;
            shapeAnnotation.moveShape(xoffSet: xoffSet, yOffset: yOffset)
            updateKnobViews()
        } else {
            shapeAnnotation.setShapeControlPoints(drawingPoints())
        }
        updateEllipseRect()
    }
    
    func performShapeRotation(with angle: CGFloat) {
        if let resizableView = resizableView {
            resizableView.transform = resizableView.transform.rotated(by: angle)
            shapeAnnotation.shapeTransformMatrix = resizableView.transform
            if let shapeEditVc = shapeEditVC {
                shapeEditVc.view.transform = shapeEditVc.view.transform.rotated(by: angle)
            }
            resizableView.updateDragHandles()
            if !shapeAnnotation.isPerfectShape() {
                let point = CGPoint(x: resizableView.frame.midX , y: resizableView.frame.midY)
                let contentOffset = self.delegate?.visibleRect().origin ?? .zero
                var convertedPoint = CGPointTranslate(point, contentOffset.x, contentOffset.y);
                convertedPoint =  CGPointScale(convertedPoint, 1/scale);
                rotatePoints(angle: angle, refPoint: convertedPoint)
                updateKnobViews()
            } else {
                shapeAnnotation.setShapeControlPoints(drawingPoints()) 
            }
        }
        updateEllipseRect()
        resizableView?.updateAngleInfo()
    }
        
    func processShapeRotate(curPoint: CGPoint, prevPoint: CGPoint) {
        let location = curPoint
        let angle = angleBetweenPoints(startPoint: lastPrevPointInRotation, endPoint: location)
        if let resizableView = self.resizableView {
            if(resizableView.isAngleNearToSnapArea(byAddingAngle: angle)) {
                let snapAttrs = resizableView.snapToNear90IfNeeded(byAddingAngle: angle)
                if(snapAttrs.isNearst90) {
                    angleSnappingView?.isHidden = false
                    self.performShapeRotation(with: snapAttrs.angle)
                    lastPrevPointInRotation = location
                }
            }
            else {
                angleSnappingView?.isHidden = true
                self.performShapeRotation(with: angle)
                lastPrevPointInRotation = location
            }
        }
    }
    
    func didBeganRotation(at point : CGPoint) {
        self.shapeEditType = .rotate
        self.lastPrevPointInRotation  = point
        resizableView?.showAngleInfoView(show: true)
        resizableView?.updateAngleInfo()
    }
    
    func finalizeTouchesEnded(for touch: UITouch?) {
        if annotationMode == .create && !isEditMode, let shape = shapeAnnotation.shape {
            track("shapes_shape_created",params: ["shape_type": shape.shapeName()] ,screenName: FTScreenNames.shapes)
        }
        angleSnappingView?.isHidden = true
        resizableView?.showAngleInfoView(show: false)
        resizableView?.setAnchorPoint(anchorPoint: CGPoint(x: 0.5, y: 0.5))
        shapeEditVC?.view.setAnchorPoint(anchorPoint: CGPoint(x: 0.5, y: 0.5))
        removeSnappingView()
        if let shapEditVc = shapeEditVC {
            shapEditVc.configureShapeEditView()
        }
        if shapeAnnotation.isPerfectShape() {
            shapeAnnotation.setShapeControlPoints(generateRawDrawingPoints())
            if annotationMode == .create {
                updateBoundingRect()
            }
        } else {
            updateFreeFormShapeRect()
        }
        (self.view as? FTShapeView)?.dragView = shapeEditVC?.specialKnob
        (self.view as? FTShapeView)?.shapeEditView = shapeEditVC?.view
        trackControlPointDrag()
        if shapeEditType == .rotate {
            track("activeshape_rotated", screenName: FTScreenNames.shapes)
        }
        resetActions()
        NSObject.cancelPreviousPerformRequests(withTarget: self,
                                               selector: #selector(generateStrokeSegments),
                                               object: nil)
        self.perform(#selector(generateStrokeSegments), with: nil, afterDelay: 0.1);
        self.displayLink?.isPaused = true
        publishChanges(nil)
    }
}

extension FTShapeAnnotationController {
    @objc fileprivate func delayedDisableGesture()
    {
        NotificationCenter.default.post(name: NSNotification.Name.init(FTPDFDisableGestures), object: self.view.window);
    }
    
    fileprivate func scheduleDelayedDisableGesture()
    {
        self.perform(#selector(delayedDisableGesture),
                     with: nil,
                     afterDelay: 0.3);
    }
    
    fileprivate func cancelDelayedDisableGesture()
    {
        NSObject.cancelPreviousPerformRequests(withTarget: self,
                                               selector: #selector(delayedDisableGesture),
                                               object: nil);
    }
    
    @objc func delayedEnableGesture()
    {
        NotificationCenter.default.post(name: NSNotification.Name.init(FTPDFEnableGestures), object: self.view.window);
    }
    
    func scheduleDelayedEnableGesture()
    {
        self.perform(#selector(delayedEnableGesture),
                     with: nil,
                     afterDelay: 0.2);
    }
}

//MARK: - Helper methods
extension FTShapeAnnotationController {
    func removeShapeIfNeeded() -> Bool {
        var shouldRemove = false
        if (DispatchTime.now() - touchTime) < 150 && annotationMode == .create && !isEditMode {
            shouldSaveAnnotation = false
            self.delegate?.annotationControllerDidRemoveAnnotation(self, annotation: shapeAnnotation)
            resetDisplayLink()
            shouldRemove = true
        }
        return shouldRemove
    }
    
    func setupTapGestures() {
        if tapGesture == nil {
            tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(tap:)));
            tapGesture?.numberOfTapsRequired = 1
            tapGesture?.cancelsTouchesInView = false
            if let tapGesture = tapGesture {
                resizableView?.addGestureRecognizer(tapGesture)
            }
        }
        if nil != resizableView {
            setUpRotateHandleGesture()
            setUpFingerRotateGesture()
        }
    }
    
    private func setUpRotateHandleGesture() {
        if let rotateHandle = resizableView?.rotateHandle {
            if rotateTapGesture == nil {
                rotateTapGesture = FTRotateTapGesture(target: self, action: #selector(rotateHandleTapped(_ :)))
                rotateTapGesture?.numberOfTapsRequired = 1
                rotateTapGesture?.cancelsTouchesInView = false
                rotateHandle.addGestureRecognizer(rotateTapGesture!)
            }
        }
    }
    
    func setUpFingerRotateGesture() {
        if let resizableView = self.resizableView {
            if fingerRotationGesture == nil {
                let fingerRotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(fingerRotateAction(_ :)))
                fingerRotateGesture.isEnabled = true
                resizableView.addGestureRecognizer(fingerRotateGesture)
            }
        }
    }
    
    @objc fileprivate func didTap(tap: UITapGestureRecognizer) {
        if (tap.state == .recognized) {
            showMenu(true)
            track("activeshape_tapped", screenName: FTScreenNames.shapes)
        }
    }
    
    @objc func rotateHandleTapped(_ gesture: UITapGestureRecognizer) {
        resizableView?.rotateHandleTapped()
        resizableView?.updateAngleInfo()
        resizableView?.showAngleInfoView(show: true)
        trackRotateTapped()
    }
    
    func trackRotateTapped() {
        track("activeshape_rotate_tapped", screenName: FTScreenNames.shapes)
    }
 
    @objc func fingerRotateAction(_ gesture: UIRotationGestureRecognizer) {
        switch gesture.state {
        case .began:
            self.shapeEditType = .rotate
            hideKnobViews(true)
            resizableView?.updateAngleInfo()
        case .changed:
            let angle = gesture.rotation
            resizableView?.showAngleInfoView(show: true)
            if let resizableView = self.resizableView {
                if(resizableView.isAngleNearToSnapArea(byAddingAngle: angle)) {
                    let snapAttrs = resizableView.snapToNear90IfNeeded(byAddingAngle: angle)
                    if(snapAttrs.isNearst90) {
                        gesture.rotation = 0
                        angleSnappingView?.isHidden = false
                        self.performShapeRotation(with: snapAttrs.angle)
                    }
                }
                else {
                    gesture.rotation = 0
                    angleSnappingView?.isHidden = true
                    self.performShapeRotation(with: angle)
                }
            }

        case .cancelled, .ended:
            angleSnappingView?.isHidden = true
            resizableView?.showAngleInfoView(show: false)
            self.shapeEditType = .none
            hideKnobViews(false)
            NSObject.cancelPreviousPerformRequests(withTarget: self,
                                                   selector: #selector(generateStrokeSegments),
                                                   object: nil)
            self.perform(#selector(generateStrokeSegments), with: nil, afterDelay: 0.1);
            track("activeshape_rotatedbyfingers", screenName: FTScreenNames.shapes)
        default:
            break
        }
    }
    
    func setAnchorPoint() {
        var anchorPoint = CGPoint(x: 1, y: 1)
        switch activeControlPoint {
        case .topLeft, .topMid, .leftSideMid:
            anchorPoint = CGPoint(x: 1, y: 1)
        case .topRight:
            anchorPoint = CGPoint(x: 0, y: 1)
        case .bottomLeft:
            anchorPoint = CGPoint(x: 1, y: 0)
        case .bottomRight, .bottomMid, .rightSideMid:
            anchorPoint = CGPoint.zero
        default:
            anchorPoint = CGPoint(x: 1, y: 1)
        }
        resizableView?.setAnchorPoint(anchorPoint: anchorPoint)
        shapeEditVC?.view.setAnchorPoint(anchorPoint: anchorPoint)
    }
    
    func drawFactoryShape(with point: CGPoint) {
        removeKnobViews()
        if (annotation.renderingRect.size != .zero) {
            self.delegate?.refreshView(refreshArea: annotation.renderingRect)
            let newStroke = FTShapeAnnotation.init(withPage: shapeAnnotation.associatedPage, shapeType: shapeAnnotation.shapeData.shapeSubType)
            shapeAnnotation = newStroke
            resizableView?.removeFromSuperview()
        }
        addPenAttributes(to: shapeAnnotation)
        shapeAnnotation.defaultBoundingRect.origin = point
        resizableView = FTResizableView(frame: shapeAnnotation.defaultBoundingRect)
        resizableView?.delegate = self
        self.view.addSubview(resizableView!)
        resizableView?.updateDragHandles()
        setupTapGestures()
        hideKnobViews(true)
        addAngleSnappingView()
    }
    
    public func contentFrame() -> CGRect {
        if let resizableView = self.resizableView {
            let transform = resizableView.transform;
            resizableView.transform = CGAffineTransform.identity;
            let frame = resizableView.frame;
            resizableView.transform = transform;
            return frame;
        }
        return CGRect.zero
    }
    
    func drawingPoints() -> [CGPoint] {
        if let shape = shapeAnnotation.shape, shape.type() != .ellipse {
           return generateRawDrawingPoints()
        }
        return shapeAnnotation.getshapeControlPoints()
    }
    
    private func generateRawDrawingPoints() -> [CGPoint] {
        //Generates drawing points for perfect shape with respect to view
        var _points = shapeAnnotation.getshapeControlPoints()
        if let resizableView = resizableView, let shape = shapeAnnotation.shape {
            let points = shape.shapeControlPoints?(in: resizableView, for: scale) ?? [CGPoint]()
            var drawingPoints = [CGPoint]()
            for eachPoint in points {
                let newPoint = convertTappedPoint(eachPoint)
                drawingPoints.append(newPoint)
            }
            if !(drawingPoints.isEmpty) {
                _points = drawingPoints
            }
        }
        return _points
    }
    
    private func addPenAttributes(to shapeAnn: FTShapeAnnotation) {
        let currentPenset = self.currentPenSet()
        shapeAnn.penType = (annotationMode == .edit) ? shapeAnnotation.penType : currentPenset.type
        shapeAnn.strokeColor = (annotationMode == .edit) ? shapeAnnotation.strokeColor : UIColor(hexString: currentPenset.color)
        shapeAnn.strokeWidth = (annotationMode == .edit) ? shapeAnnotation.strokeWidth : CGFloat(currentPenset.size.rawValue)
    }

    @objc func updateSegments(index: Int, point: CGPoint) {
        let contentOffset = self.delegate?.visibleRect().origin ?? .zero
        let convertedTappedPoint = CGPointTranslate(point, contentOffset.x, contentOffset.y);
        let finalPoint = convertedTappedPoint.scaled(scale: 1/self.scale)
        shapeAnnotation.translateAt(index: index, to: finalPoint)
    }
    
    //Translate point w.r.t visible rect and scale down
    func convertPoint(_ point: CGPoint) -> CGPoint {
        let contentOffset = self.delegate?.visibleRect().origin ?? .zero
        let convertedTappedPoint = CGPointTranslate(point, contentOffset.x, contentOffset.y);
        return convertedTappedPoint.scaled(scale: 1/self.scale)
    }
    
    //Scale down visible rect and translate point w.r.t visible rect
    func convertTappedPoint(_ point: CGPoint) -> CGPoint {
        let contentOffset = (self.delegate?.visibleRect().origin ?? .zero).scaled(scale: 1 / scale)
        let convertedTappedPoint = CGPointTranslate(point, contentOffset.x, contentOffset.y);
        return convertedTappedPoint
    }
    
    func angleBetweenPoints(startPoint:CGPoint, endPoint:CGPoint) -> CGFloat {
        let newCenter = resizableView?.center ?? .zero
        let a = startPoint.x - newCenter.x
        let b = startPoint.y - newCenter.y
        let c = endPoint.x - newCenter.x
        let d = endPoint.y - newCenter.y
        let atanA = atan2(a, b)
        let atanB = atan2(c, d)
        return atanA - atanB
    }
    
    func updateResizableView(curPoint: CGPoint, prevPoint: CGPoint) {
        if let resizableView = resizableView {
            var origin = resizableView.center
            origin.x -= (prevPoint.x - curPoint.x)
            origin.y -= (prevPoint.y - curPoint.y)
            resizableView.center = origin
            resizableView.updateDragHandles()
        }
    }
    
    func shouldReceiveTouch(for point: CGPoint) -> Bool {
        var returnValue = false
        let scaledPoint = point.scaled(scale: 1/self.scale)
        if isPointInsdeKnobView(point: point) != nil {
            returnValue = true
        }
        if (!returnValue && annotation.boundingRect.contains(scaledPoint)) {
            returnValue = true
        }
        return returnValue
    }
    
    private func rotatePoints(angle: CGFloat, refPoint: CGPoint) {
        var shapeControlPoints = shapeAnnotation.getshapeControlPoints()
        for index in shapeControlPoints.indices {
            var point = shapeControlPoints[index]
            point.rotate(by: angle, refPoint: refPoint)
            shapeControlPoints[index] = point
        }
        shapeAnnotation.setShapeControlPoints(shapeControlPoints)
    }
    
    private func currentPenSet() -> FTPenSetProtocol {
        let userActivity = self.view.window?.windowScene?.userActivity
       return FTRackData(type: FTRackType.shape,userActivity: userActivity).getCurrentPenSet()
    }
    
    private func validatePerfectShape() -> Bool {
        let kVariancePercentage: CGFloat = 0.3
        var isPerfectShape = false
        let boundingRectSize = contentFrame().size
        if boundingRectSize.width != 0 && boundingRectSize.height != 0 {
            var max = boundingRectSize.height
            var variance: CGFloat = (boundingRectSize.height / boundingRectSize.width) * 100
            if boundingRectSize.width < boundingRectSize.height {
                variance = (boundingRectSize.width / boundingRectSize.height) * 100
                max = boundingRectSize.width
            }
            variance = 100 - variance
            if variance <= kVariancePercentage {
                isPerfectShape = true
                if let resizableView = resizableView {
                    resizableView.bounds.size = CGSize(width: max, height: max)
                }
            }
        }
        return isPerfectShape
    }
    
    private func addSnappingView() {
        if let resizableView = resizableView, snappingView == nil {
            let scaledFrame = CGRectScale(resizableView.frame, 1)
            snappingView = FTSnapView(frame: scaledFrame)
            snappingView?.addFullConstraints(resizableView)
        }
    }
    
    func addAngleSnappingView() {
        if let resizableView = resizableView, angleSnappingView == nil {
            let scaledFrame = CGRectScale(resizableView.frame, 1)
            angleSnappingView = FTLineDashView(frame: scaledFrame)
            angleSnappingView?.addFullConstraints(resizableView)
            angleSnappingView?.isHidden = true
        }
    }
    
    private func removeSnappingView() {
        snappingView?.removeFromSuperview()
        snappingView = nil
    }
    
    func updateFreeFormShapeRect() {
        if let resizableView = resizableView, !shapeAnnotation.isPerfectShape(), shapeAnnotation.shape != nil {
            var invertedPoints = [CGPoint]()
            var newFrame =  resizableView.contentFrame()
            if shapeEditType == .resize || newFrame.size == .zero {
                newFrame = newRectForResizing()
            }
            let convertedPoint = CGPoint(x: newFrame.midX , y: newFrame.midY)
            let points = shapeAnnotation.knobControlPoints()
            points.forEach { eachPoint in
                var point = convertControlPoint(eachPoint)
                point.rotate(by: -resizableView.transform.angle, refPoint: convertedPoint)
                invertedPoints.append(point)
            }
            let rect = rectFromControPoints(invertedPoints)
            updateContentFrame(with: rect)
            resizableView.updateDragHandles()
        }
    }
    
    func newRectForResizing() -> CGRect {
        var invertedPoints = [CGPoint]()
        let points = shapeAnnotation.knobControlPoints()
        points.forEach { eachPoint in
            let point = convertControlPoint(eachPoint)
            invertedPoints.append(point)
        }
        return rectFromControPoints(invertedPoints)
    }
    
    func rectFromControPoints(_ points: [CGPoint]) -> CGRect {
        let boundingRect = FTShapeUtility.boundingRect(points)
        return boundingRect.insetBy(dx: -shapeAnnotation.properties.strokeThickness, dy: -shapeAnnotation.properties.strokeThickness)
    }

    // TODO: (Sameer) create segments only when we exit from the edit mode.
    @objc func generateStrokeSegments() {
        shapeAnnotation.regenerateStrokeSegments()
    }
    
    func isFreeForm() -> Bool {
        return shapeAnnotation.isFreeFormSelected()
    }
}

//MARK: - ResizableDelegate
extension FTShapeAnnotationController: FTResizableViewDelegate {
    func rotateShape(with angle: CGFloat) {
        self.shapeEditType = .rotate;
        performShapeRotation(with: angle)
    }
    
    func contextMenuInteraction(action: FTShapeEditAction) {
        switch action  {
        case .cut:
            self.cutMenuAction(nil)
        case .copy:
            self.copyMenuAction(nil)
        case .delete:
            self.deleteMenuAction(nil)
        }
    }
}

//MARK: - Knobs related
 extension FTShapeAnnotationController {
    func removeKnobViews() {
        let knobViews = self.view.subviews
        knobViews.forEach { eachView in
            if eachView is FTKnobView || eachView is FTRotateKnobView {
                eachView.removeFromSuperview()
            }
        }
    }
    
    func updateKnobViews(with refPoints: [CGPoint] = []) {
        let _contentOffSet = self.delegate?.visibleRect().origin ?? .zero
        var knobViews = [UIView]()
        guard let view = self.view else {
            return
        }
        for eachView in view.subviews where eachView is FTKnobView {
            knobViews.append(eachView)
        }
        var controlPoints = shapeAnnotation.getshapeControlPoints()
        if (!refPoints.isEmpty) {
            controlPoints = refPoints
        }
        for (index,view) in knobViews.enumerated() {
            if let _knobView = view as? FTKnobView, !controlPoints.isEmpty {
                let controlPoint = controlPoints[index]
                let scaledPoint = controlPoint.scaled(scale: self.scale)
                let finalPoint = CGPointTranslate(scaledPoint, -_contentOffSet.x, -_contentOffSet.y);
                _knobView.center = finalPoint
            }
        }
    }
    
    func hideKnobViews(_ show: Bool) {
        for eachView in view.subviews {
            if eachView is FTKnobView || eachView is FTRotateKnobView {
                eachView.isHidden = show
            }
        }
    }
    
    @objc func addKnobsForControlPoints() {
        if !shapeAnnotation.isPerfectShape() {
            let points = shapeAnnotation.getshapeControlPoints()
            for (i, ftPoint) in points.enumerated() {
                let point = convertControlPoint(ftPoint)
                let knobView = FTKnobView()
                knobView.segmentIndex = i
                knobView.center = point
                view.addSubview(knobView)
            }
        }
    }
     
     func convertControlPoint(_ point: CGPoint) -> CGPoint {
         let cgPoint = point.scaled(scale: self.scale)
         let contentOffset = self.delegate?.visibleRect().origin ?? .zero
         let convertedTappedPoint = CGPointTranslate(cgPoint, -contentOffset.x, -contentOffset.y);
         return convertedTappedPoint
     }
    
    @objc public func isPointInsdeKnobView(point: CGPoint) -> UIView? {
        var knobView: UIView?
        for eachKnob in view.subviews {
            if eachKnob is FTKnobView || eachKnob is FTRotateKnobView {
                if eachKnob.frame.contains(point) {
                    knobView = eachKnob
                    break
                }
            }
        }
        return knobView
    }
     
     private func _isPointInsideFrame(_ point : CGPoint) -> Bool {
         if let resizableView = resizableView {
             let topLeftFrame = convertedViewFrame(resizableView.topLeft)
             let bottomLeftFrame = convertedViewFrame(resizableView.bottomLeft)
             let bottomRightFrame = convertedViewFrame(resizableView.bottomRight)
             let topRightFrame = convertedViewFrame(resizableView.topRight)
             
             let bezierPath = UIBezierPath.init();
             bezierPath.move(to: CGPoint.init(x: topLeftFrame.minX, y: topLeftFrame.minY));
             bezierPath.addLine(to: CGPoint.init(x: bottomLeftFrame.minX, y: bottomLeftFrame.maxY));
             bezierPath.addLine(to: CGPoint.init(x: bottomRightFrame.maxX, y: bottomRightFrame.maxY));
             bezierPath.addLine(to: CGPoint.init(x: topRightFrame.maxX, y: topRightFrame.minY));
             bezierPath.close();
             return bezierPath.contains(point)
         }
         return false
     }
}

extension CGPoint {
    func scaled(scale: CGFloat) -> CGPoint {
        return CGPoint.scale(self, scale)
    }
}


extension FTShapeAnnotationController : FTShapeRezingDelegate {
    func _setAnchorPoint() {
        self.setAnchorPoint()
    }
    
    func resetAnchorPoint() {
        resizableView?.setAnchorPoint(anchorPoint: CGPoint(x: 0.5, y: 0.5))
    }
    
    func rotateFrame() {
        resetAnchorPoint()
        let angleToadd = CGFloat.pi + (resizableView?.transform.angle ?? 0)
        resizableView?.transform = CGAffineTransform(rotationAngle: angleToadd)
        setAnchorPoint();
    }

    func updateControlPoint() {
        var point = FTControlPoint.bottomRight
        switch self.activeControlPoint {
        case .topLeft:
            point = .topRight
        case .topRight:
            point = .topLeft
        case .bottomLeft:
            point = .bottomRight
        case .bottomRight:
            point = .bottomLeft
        case .leftSideMid:
            point = .rightSideMid
        case .rightSideMid:
            point = .leftSideMid
        default:
            point = activeControlPoint
        }
        self.activeControlPoint = point
        setAnchorPoint()
    }
}
