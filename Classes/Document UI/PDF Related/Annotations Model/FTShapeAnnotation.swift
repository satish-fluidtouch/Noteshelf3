//
//  FTShapeAnnotation.swift
//  Noteshelf
//
//  Created by Akshay on 21/05/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTRenderKit
import CoreGraphics

extension FTShapeProperties {

    init(data: Data) {
        self.init()
        if let props = try? JSONDecoder().decode(FTShapeProperties.self, from: data) {
            self.strokeOpacity = props.strokeOpacity
            self.strokeThickness = props.strokeThickness
        }
    }

    var data: Data {
        do {
            let _data = try JSONEncoder().encode(self)
            return _data
        } catch {
            fatalError("Unable to encode shape Data")
        }
    }
}

final class FTShapeAnnotation: FTStroke, FTShapeAnnotationProtocol {
    
    var shapeBoundingRect: CGRect {
        get {
            let halfThickness = properties.strokeThickness*0.5;
            var rect = boundingRect;
            rect = rect.insetBy(dx: halfThickness, dy: halfThickness);
            let isFiniteRect = !rect.origin.x.isInfinite && !rect.origin.y.isInfinite &&
                               !rect.size.width.isInfinite && !rect.size.height.isInfinite
            if !isFiniteRect {
                return boundingRect
            }
            return rect;
        }
        set {
            let halfThickness = properties.strokeThickness*0.5;
            boundingRect = newValue.insetBy(dx: -halfThickness, dy: -halfThickness);
        }
    }
    
    func controlPointTexture(scale: CGFloat) -> MTLTexture? {
        if brushTexture == nil {
            let image = UIImage(named: "resizeKnob")! //"cal-brush-5"
            brushTexture = FTMetalUtils.texture(from: image)
        }
        return brushTexture
    }
    
    var shapeControlPoints: [CGPoint] {
        return [CGPoint]()
    }

    var rotatedAngle : CGFloat = 0
    var shape: FTShape?
    private var brushTexture: MTLTexture?
    var defaultBoundingRect = CGRect(origin: .zero, size: CGSize(width: 5, height: 5))
    private var _shapeControlPoints: [CGPoint] = []
    
    func setShapeControlPoints(_ points: [CGPoint]) {
        objc_sync_enter(self)
        _shapeControlPoints = points
        shapeData.controlPoints = points
        self._drawingPoints.removeAll()
        objc_sync_exit(self)
    }
    
    func getshapeControlPoints() -> [CGPoint] {
        objc_sync_enter(self)
        let pointsToReturn = _shapeControlPoints
        defer {
            objc_sync_exit(self)
        }
        return pointsToReturn
    }
    
    func knobControlPoints() -> [CGPoint] {
        if let shape, shape.type() == .curve {
            return shape.knobControlPoints?() ?? []
        }
        return getshapeControlPoints()
    }
    
    private var _shapeTransformMatrix = CGAffineTransform.identity;
    @objc var shapeTransformMatrix : CGAffineTransform {
        get {
            return _shapeTransformMatrix
        }
        set {
            if(newValue != _shapeTransformMatrix) {
                _shapeTransformMatrix = newValue;
            }
        }
    };
    
    override var allowsLocking: Bool {
        return false
    }

    private var _drawingPoints: [CGPoint] = []
    private var _prevScale: CGFloat = 1.0
    func shapeDrawingPoints(for scale: CGFloat) -> [CGPoint] {
        if _drawingPoints.isEmpty || _prevScale != scale {
            _drawingPoints = drawingPointsForControlPoints(scale: scale)
            _prevScale = scale
        }
        return _drawingPoints
    }
    var properties: FTShapeProperties {
        get {
            if let _properties = shapeData.properties {
                return _properties
            }
            var brushWidth = strokeWidth
            if isArrowType() {
                brushWidth = min(5, brushWidth)
            }
            strokeWidth = brushWidth
            let properties = FTBrushBuilder.penAttributesFor(penType: penType,
                                                             brushWidth: strokeWidth,
                                                             isShapeTool: true,
                                                             version: FTStroke.defaultAnnotationVersion());
            shapeData.properties = FTShapeProperties(strokeThickness: properties.brushWidth, strokeOpacity: shapeData.strokeOpacity)
            return shapeData.properties ?? FTShapeProperties()
        }
        
        set {
            shapeData.properties = newValue
        }
    }
    var shapeData: FTShapeData = FTShapeData()
    let shapeDataDecodeString = "shape.data"

    override init() {
        super.init()
    }

    convenience init(withPage page : FTPageProtocol?, shapeType: FTShapeType) {
        self.init()
        self.associatedPage = page
        shapeData.shapeType = shapeType.rawValue
    }
    
    override var supportsZoomMode: Bool {
        return true
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        let data = (aDecoder.decodeObject(forKey: shapeDataDecodeString) as? Data)!
        shapeData = FTShapeData(data: data)
        setControlPoints(shapeData.controlPoints)
        shapeTransformMatrix = aDecoder.decodeCGAffineTransform(forKey: "shapeTransformMatrix");
    }

    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(shapeData.data, forKey: shapeDataDecodeString)
        aCoder.encode(shapeTransformMatrix, forKey: "shapeTransformMatrix");
    }

    override var annotationType: FTAnnotationType {
        return .shape
    }
    
    override func canSelectUnderLassoSelection() -> Bool {
        return FTRackPreferenceState.allowAnnotations().contains(annotationType)
    }

    override func addSegment(startPoint: CGPoint,
                             endPoint: CGPoint,
                             thickness: CGFloat,
                             opacity: CGFloat) {
        objc_sync_enter(self);
        let segment = FTSegmentStruct(startPoint: FTPoint(cgpoint: startPoint),
                                      endPoint: FTPoint(cgpoint: endPoint),
                                      thickness: Float(thickness),
                                      opacity: Float(opacity),
                                      isErased: false);
        self.segmentArray.append(segment);
        self.segmentCount = segmentCount + 1;
        maxThickness = max(maxThickness, segment.thickness)
        var transient = FTSegmentTransient()
        transient.bounds = segment.bounds()
        self.segmentsTransientArray.append(transient);
        objc_sync_exit(self);
    }

    override func deepCopyAnnotation(_ toPage: FTPageProtocol, onCompletion: @escaping (FTAnnotation?) -> Void) {
        let shape = FTShapeAnnotation(withPage : toPage, shapeType: shapeData.shapeSubType);
        shape.isReadonly = self.isReadonly;
        shape.version = self.version;
        shape.strokeColor = self.strokeColor;
        shape.strokeWidth = self.strokeWidth;
        shape.penType = self.penType;
        shape.boundingRect = self.boundingRect;
        shape.segmentCount = self.segmentCount;
        shape.segmentsTransientArray = self.segmentsTransientArray;
        shape.segmentArray = self.segmentArray;
        shape._shapeControlPoints = self._shapeControlPoints;
        shape.rotatedAngle = self.rotatedAngle
        shape.properties = self.properties
        shape.shapeData = self.shapeData
        onCompletion(shape);
    }

    func updateShapeSides(sides: CGFloat) {
        shape?.numberOfSides = sides
        shapeData.numberOfSides = Int(sides)
    }
    
    func updateShapeType() {
        if shape == nil {
            shape = shapeData.shapeSubType.getDefaultShape()
        }
    }
    
    func isPerfectShape() -> Bool {
        return shape?.isPerfectShape() ?? false
    }
    
    func isFreeFormSelected() -> Bool {
        let shapeType = FTShapeType.savedShapeType()
        return shapeType == .freeForm
    }
    
    func isLineType() -> Bool {
        return shape?.isLineType?() ?? false
    }
    
    func isArrowType() -> Bool {
        return (shape?.type() == .arrow || shape?.type() == .doubleArrow)
    }
    
    func shouldSnapShape() -> Bool {
        return (shape?.type() == .rectangle || shape?.type() == .ellipse)
    }
    
    func setControlPoints(_ points : [CGPoint]) {
        self.setShapeControlPoints(points)
        self.regenerateStrokeSegments()
    }

    func translateAt(index: Int, to point: CGPoint) {
        var controlPoints = getshapeControlPoints()
        controlPoints[index] = point
        self.setShapeControlPoints(controlPoints)
    }
   
    func moveShape(xoffSet: CGFloat, yOffset: CGFloat) {
        var controlPoints = getshapeControlPoints()
        for index in controlPoints.indices {
            var point = controlPoints[index]
            point.x -= xoffSet
            point.y -= yOffset
            controlPoints[index] = point
        }
        setShapeControlPoints(controlPoints)
    }
    
    func didEndEditing() {
        regenerateStrokeSegments()
    }
    
    func asStroke() -> FTStroke {
        let stroke = FTStroke()
        stroke.boundingRect = self.renderingRect
        stroke.segmentArray = self.segmentArray
        stroke.segmentsTransientArray = self.segmentsTransientArray
        stroke.segmentCount = self.segmentCount
        stroke.penType = self.penType
        stroke.strokeColor = self.strokeColor
        stroke.strokeWidth = self.strokeWidth
        stroke.associatedPage = self.associatedPage
        return stroke;
    }
    
    @objc override var renderingRect: CGRect {
        let transform = self.shapeTransformMatrix;
        var renderingRect = self.boundingRect.applying(transform)
        renderingRect.origin.x = self.boundingRect.midX - renderingRect.width*0.5;
        renderingRect.origin.y = self.boundingRect.midY - renderingRect.height*0.5;
        return isPerfectShape() ? renderingRect : boundingRect
    }
    
    override func intersectsPath(_ inSelectionPath: CGPath, withScale scale: CGFloat, withOffset selectionOffset: CGPoint) -> Bool {
         objc_sync_enter(self);
         var result = false;
         var selectionPathBounds = inSelectionPath.boundingBox;
         selectionPathBounds.origin = CGPoint.init(x: selectionPathBounds.origin.x + selectionOffset.x,
                                                   y: selectionPathBounds.origin.y + selectionOffset.y);
         let boundingRect1 = CGRectScale(self.renderingRect, scale);
         if(boundingRect1.intersects(selectionPathBounds)) {
             //Check if any of the segment is within the selection path
             for i in 0..<self.segmentCount {
                 let segment = self.segmentArray[i];
                 if !segment.isErased {
                     var scaledPoint = CGPointScale(CGPoint.init(ftpoint: segment.startPoint), scale);
                     scaledPoint = CGPointTranslate(scaledPoint, -selectionOffset.x, -selectionOffset.y);
                     if(inSelectionPath.contains(scaledPoint)) {
                         result = true;
                         break;
                     }
                 }
             }
         }
         objc_sync_exit(self);
         return result;
     }

    
    func hasErasedSegments() -> Bool {
        var hasErasedSegments: Bool = false
        objc_sync_enter(self)
        if self.segmentArray.contains(where: { $0.isErased == true }) {
            hasErasedSegments = true
        }
        objc_sync_exit(self)
        return hasErasedSegments
    }
    
    override func setOffset(_ offset: CGPoint) {
        super.setOffset(offset)
        if hasErasedSegments() {
            return
        }
        if(offset != CGPoint.zero) {
            var controlPoints = getshapeControlPoints()
            for index in controlPoints.indices {
                var point = controlPoints[index]
                point.translate(dx: Float(offset.x), dy: Float(offset.y))
                controlPoints[index] = point
            }
            setShapeControlPoints(controlPoints)
        }
        regenerateStrokeSegments()
    }
    
    override func setRotation(_ angle: CGFloat, refPoint: CGPoint) {
        if hasErasedSegments() {
            super.setRotation(angle, refPoint: refPoint)
            return
        }
        if angle != 0 {
            (self.associatedPage as? FTPageTileAnnotationMap)?.tileMapRemoveAnnotation(self);
            let rotation = CGAffineTransform(rotationAngle: angle)
            let transform = CGAffineTransform(translationX: refPoint.x, y: refPoint.y)
                .rotated(by: angle)
                .translatedBy(x: -refPoint.x, y: -refPoint.y)

            let center = CGPoint(x: self.boundingRect.midX, y: self.boundingRect.midY)
            let newCenter = center.applying(transform)
            let newOriginX = newCenter.x - boundingRect.width/2
            let newOriginY = newCenter.y - boundingRect.height/2
            self.boundingRect.origin = CGPoint(x: newOriginX, y: newOriginY)
            var controlPoints = getshapeControlPoints()
            for index in controlPoints.indices {
                var point = controlPoints[index]
                point.rotate(by: angle, refPoint: refPoint)
                controlPoints[index] = point
            }
            setShapeControlPoints(controlPoints)
            let finalTransform = self.shapeTransformMatrix.concatenating(rotation)
            self.shapeTransformMatrix = finalTransform
            (self.associatedPage as? FTPageTileAnnotationMap)?.tileMapAddAnnotation(self);
        }
        regenerateStrokeSegments()
    }
    
    override func apply(_ scale: CGFloat) {
        if hasErasedSegments() {
            super.apply(scale)
            return
        }
        var strokeBoundingRect = self.boundingRect;
        var thickness =  properties.strokeThickness * scale
        if isArrowType() {
            thickness = min(5, thickness)
            let props =  FTBrushBuilder.penAttributesFor(penType: penType,
                                                             brushWidth: thickness,
                                                             isShapeTool: true,
                                                             version: FTStroke.defaultAnnotationVersion())
            thickness = props.brushWidth
        }
        properties.strokeThickness = thickness
        var controlPoints = getshapeControlPoints()
        for index in controlPoints.indices {
            let point = controlPoints[index]
            let endPointOffsetx = (point.x - strokeBoundingRect.origin.x)*scale;
            let endPointOffsety = (point.y - strokeBoundingRect.origin.y)*scale;
            let finalEndPoint = CGPointTranslate(strokeBoundingRect.origin, endPointOffsetx, endPointOffsety);
            controlPoints[index] = finalEndPoint
        }
        setShapeControlPoints(controlPoints)
        strokeBoundingRect.size.height *= scale;
        strokeBoundingRect.size.width *= scale;
        self.boundingRect = strokeBoundingRect;
        regenerateStrokeSegments()
    }
}

//MARK:- Private
 extension FTShapeAnnotation {
    func drawingPointsForControlPoints(scale: CGFloat) -> [CGPoint] {
        if shape == nil  {
            shape = shapeData.shapeSubType.getDefaultShape()
        }
        guard let _shape = shape else {
            return [CGPoint]();
        }
        objc_sync_enter(_shape);
        if let shape = shape as? FTShapeEllipse {
            shape.rotatedAngle = shapeTransformMatrix.angle.radiansToDegrees
            let boundRect = shapeBoundingRect;
            shape.boundingRectSize = boundRect.size
            shape.center = CGPoint(x: boundRect.midX, y: boundRect.midY);
        }
        _shape.numberOfSides = CGFloat(shapeData.numberOfSides)
        _shape.vertices = getshapeControlPoints()
        objc_sync_exit(_shape);
        var points = _shape.drawingPoints(scale: scale);
        if (_shape.type() == .dashLine) {
            points = drawingPointsForDashLine(points: points)
        }
        return points
    }
     
     func drawingPointsForDashLine(points: [CGPoint]) -> [CGPoint] {
         let lineDashSpacing = 3 * Int(strokeWidth)
         let const = 5 * Int(strokeWidth)
         var intermIndex = 0
         
         var newPoints = [CGPoint]()
         for (index, point) in points.enumerated() {
             if index % const == 0 && index > 0 {
                 intermIndex = index
             }
             if (intermIndex > 0 && (index % intermIndex) <= lineDashSpacing) {
                 continue
             }
             newPoints.append(point)
         }
         return newPoints
     }

     func regenerateStrokeSegments() {
        let drawingPoints = self.drawingPointsForControlPoints(scale: _prevScale)
        objc_sync_enter(self)
        self.segmentArray.removeAll();
        self.segmentCount = 0;        
        self.segmentsTransientArray.removeAll();
        if (!self.isPerfectShape()) {
            self.boundingRect = .null
        }
        objc_sync_exit(self)
        for (idx,obj) in drawingPoints.enumerated() where idx > 0 {
            let startPoint = drawingPoints[idx - 1]
            let endPoint = obj

            var alpha: CGFloat = 1.0
            if self.penType == .pencil {
                alpha = self.properties.strokeOpacity
            }
            self.addSegment(startPoint: startPoint,
                            endPoint: endPoint,
                            thickness: self.properties.strokeThickness,
                            opacity: alpha);
            if (!self.isPerfectShape()) {
                let width = abs(startPoint.x - endPoint.x);
                let height = abs(startPoint.y - endPoint.y);
                
                let halfPenWidth = self.properties.strokeThickness*0.5;
                let controlPointRect = CGRect(origin: startPoint, size: CGSize(width: width, height: height))
                    .insetBy(dx: -halfPenWidth, dy: -halfPenWidth)
                self.boundingRect = self.boundingRect.union(controlPointRect)
            }
        }
    }
}

//undo info
extension FTShapeAnnotation
{
    override func undoInfo() -> FTUndoableInfo {
        let info = FTShapeUndoableInfo.init(withAnnotation: self);
        info.controlPoints = getshapeControlPoints()
        info.shapeTransform = shapeTransformMatrix
        info.color = strokeColor
        return info;
    }
    
    override func updateWithUndoInfo(_ info: FTUndoableInfo)
    {
        guard let shapeInfo = info as? FTShapeUndoableInfo else {
            fatalError("info should be of type FTShapeUndoableInfo");
        }
        self.boundingRect = info.boundingRect;
        self.shapeTransformMatrix = shapeInfo.shapeTransform
        self.setShapeControlPoints(shapeInfo.controlPoints)
        if let _color = shapeInfo.color {
            self.strokeColor = _color
        }
        self.regenerateStrokeSegments()
    }
}

private class FTShapeUndoableInfo : FTUndoableInfo
{
    var shapeTransform : CGAffineTransform = CGAffineTransform.identity
    var controlPoints = [CGPoint]();
    var color: UIColor?

    override func isEqual(_ object: Any?) -> Bool {
        guard let shapeInfo = object as? FTShapeUndoableInfo else {
            return false;
        }
        if(super.isEqual(shapeInfo)
           && shapeInfo.shapeTransform == self.shapeTransform
           && controlPoints == shapeInfo.controlPoints
           && self.color?.hexStringFromColor() == shapeInfo.color?.hexStringFromColor()) {
            return true;
        }
        return false;
    }
    
    override func canUndo(_ object : FTUndoableInfo) -> Bool {
        if(self.annotationversion != FTImageAnnotation.defaultAnnotationVersion()) {
            return false
        }
        return super.canUndo(object);
    }

}

extension FTShapeAnnotation {
    public override class var supportsSecureCoding: Bool {
        return true;
    }
}

extension CGPoint {
    public mutating func rotate(by angle: CGFloat, refPoint: CGPoint) {
        let transform = CGAffineTransform(translationX: refPoint.x, y: refPoint.y).rotated(by: angle).translatedBy(x: -refPoint.x, y: -refPoint.y)
        self = self.applying(transform)
    }
}
