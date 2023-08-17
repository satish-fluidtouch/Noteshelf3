//
//  FTStroke.swift
//  Noteshelf
//
//  Created by Amar on 24/07/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

struct FTSegmentStruct: FTSegmentProtocol {
    var startPoint : FTPoint;
    var endPoint : FTPoint;
    var thickness : Float;
    var opacity : Float;
    var isErased: Bool;

    init(startPoint: FTPoint, endPoint: FTPoint, thickness: Float, opacity: Float, isErased: Bool) {
        self.startPoint = startPoint;
        self.endPoint = endPoint;
        self.thickness = thickness;
        self.opacity = opacity;
        self.isErased = isErased
    }

    func bounds() -> CGRect {
        let halfPenWidth = thickness*0.5;
        let bounds = CGRect(x: CGFloat(min(startPoint.x , endPoint.x) - halfPenWidth),
                            y: CGFloat(min(startPoint.y , endPoint.y) - halfPenWidth),
                            width: CGFloat(abs(startPoint.x - endPoint.x) + thickness),
                            height: CGFloat(abs(startPoint.y - endPoint.y) + thickness));
        return bounds
    }
}
private let usePointSimpliedLogicForHightlighter = false;

struct FTSegmentTransient {
    var bounds: CGRect = .null
}

extension FTPenType {
    func penType() -> FTPenType {
        let penType: FTPenType;
        switch self {
        case .pen:
            penType = .pen;
        case .caligraphy:
            penType = .caligraphy;
        case .pencil:
            penType = .pencil;
        case .pilotPen:
            penType = .pilotPen;
        case .highlighter:
            penType = .highlighter;
        case .flatHighlighter:
            penType = .flatHighlighter;
        case .laser:
            penType = .laser;
        case .laserPointer:
            penType = .laserPointer;
        default:
            penType = .pen
        }
        return penType;
    }
}
@objcMembers class FTStroke: FTAnnotation,FTStrokeAnnotationProtocol {
    let highlighterOpacity: Float = 0.5;
    
    var strokeColor: UIColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 1);
    var strokeWidth: CGFloat = 0.0
    lazy var maxThickness: Float = {
        let value = self.segmentArray.max(by: {$0.thickness > $1.thickness})?.thickness ?? 0.0
        return value;
    }();

    var penType: FTPenType = FTPenType.pen
    var segmentCount: Int = 0
    var strokeInProgress: Bool = false;
    var segmentArray: [FTSegmentStruct] = [FTSegmentStruct]()
    
    var segmentsTransientArray: [FTSegmentTransient] = [FTSegmentTransient]()

    override var annotationType : FTAnnotationType
    {
        return .stroke;
    }
    
    var minBrushSizeFactor : CGFloat = -1;
    
    override init() {
        super.init();
    }
    
    func isErasedSegment(_ segment: FTSegmentProtocol, index: Int) -> Bool {
        return (segment as? FTSegmentStruct)?.isErased ?? false;
    }
    
    func segment(at index: Int) -> FTSegmentProtocol {
        return self.segmentArray[index];
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);

        strokeWidth = CGFloat(aDecoder.decodeFloat(forKey: "strokeWidth"));
        if let color = aDecoder.decodeObject(forKey: "strokeColor") as? UIColor
        {
            self.strokeColor = color;
        }
        
        self.penType = FTPenType.init(rawValue:aDecoder.decodeInteger(forKey: "penType"))!;
        
        self.segmentCount = aDecoder.decodeInteger(forKey: "segmentCount")
        if let segmentsData = aDecoder.decodeObject(forKey: "segments") as? Data {
            self.setSegmentsData(segmentsData, segmentCount: self.segmentCount);
        }
        
        if let segmentsTransientData = aDecoder.decodeObject(forKey: "segmentsTransient") as? Data {
            self.setSegmentsTransientData(segmentsTransientData, segmentCount: self.segmentCount)
        }
                
        self.minBrushSizeFactor = -1;
    }
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder);

        aCoder.encode(Float(strokeWidth), forKey: "strokeWidth");
        aCoder.encode(strokeColor, forKey: "strokeColor");
        
        aCoder.encode(penType.rawValue, forKey: "penType");
        aCoder.encode(segmentCount, forKey: "segmentCount");

        let data = self.segmentData();
        aCoder.encode(data, forKey: "segments");

        if (self.copyMode) {
            let data = self.transientSegmentData();
            aCoder.encode(data, forKey: "segmentsTransient");
        }
    }


    func addSegment(startPoint: CGPoint,
                    endPoint: CGPoint,
                    thickness: CGFloat,
                    opacity: CGFloat)
    {
        objc_sync_enter(self);
        let segment = FTSegmentStruct(startPoint: FTPoint(cgpoint: startPoint),
                                      endPoint: FTPoint(cgpoint: endPoint),
                                      thickness: Float(thickness),
                                      opacity: Float(opacity),
                                      isErased: false);
        self.segmentArray.append(segment);
        self.segmentCount = segmentCount + 1;
        maxThickness = max(maxThickness, segment.thickness)
        self.segmentsTransientArray.append(FTSegmentTransient());
        objc_sync_exit(self);
    }
    
    func segmentBounds(index:Int) -> CGRect {
        objc_sync_enter(self)
        let item = self.segmentsTransientArray[index];
        if item.bounds.isNull {
            self.segmentsTransientArray[index].bounds = self.segmentArray[index].bounds()
        }
        let itemBounds = self.segmentsTransientArray[index].bounds
        objc_sync_exit(self)
        return itemBounds
    }

    func shouldUseQuadRender(scale: CGFloat) -> Bool {
        #if targetEnvironment(macCatalyst)
            return true
        #else
            return maxThickness*Float(scale) > 511
        #endif
    }

    override func canSelectUnderLassoSelection() -> Bool {
        if self.penType == .highlighter {
            return true
        }
        return FTRackPreferenceState.allowAnnotations().contains(annotationType)
    }
  
    func segmentData() -> Data
    {
        let data = Data(from: self.segmentArray);
        return data;
    }

    func setSegmentsData(_ data : Data, segmentCount inSegmentCount : Int)
    {
        self.segmentArray = data.toArray(type: FTSegmentStruct.self, count: inSegmentCount);
        segmentCount = inSegmentCount;
        self.segmentsTransientArray = Array(repeating: FTSegmentTransient(), count: inSegmentCount);
    }

    private func transientSegmentData() -> Data {
        let data = Data(from: self.segmentsTransientArray);
        return data;
    }

    private func setSegmentsTransientData(_ data : Data, segmentCount inSegmentCount : Int) {
        self.segmentsTransientArray = data.toArray(type: FTSegmentTransient.self, count: inSegmentCount);
    }

    override class func defaultAnnotationVersion() -> Int {
        //version 1: //migrated books from NS1
        //version 2: initial version of NS2
        //version 3: fine pen [pilot pen] introduced and increased sizes from 7 to 8.
        //version 4: introduced 2 types of marker pens and increased
        //version 5: introduced 0 pen size and dynmaic variation of pen size
        return Int(5);
    }
    
    func metalBrushTexture(scale : CGFloat) -> MTLTexture? {
        var inScale = scale
        let width: CGFloat
        if penType == .laser || penType == .laserPointer {
            width = FTLaserPenThickness.primary.rawValue
            inScale = 1
        } else {
            width = self.strokeWidth
        }
        let texture = FTBrushBuilder.metalBrushTextureFor(penType: penType,
                                                          brushWidth: width,
                                                          scale: inScale,
                                                          version: self.version)
        return texture
    }

    override func loadContents() {
        super.loadContents();
        let boundingRect = self.boundingRect;
        var maxX : Float = -1, maxY  : Float = -1,minX  : Float = -1, minY  : Float  = -1;
        var maxSegBrushWidh : Float = -1;
        
        if(boundingRect.origin.x < 0 || boundingRect.origin.y < 0) {
            for i in 0..<segmentCount {
                let segment = self.segmentArray[i];
                if(maxSegBrushWidh == -1) {
                    minX = min(segment.startPoint.x, segment.endPoint.x);
                    minY = min(segment.startPoint.y, segment.endPoint.y);
                    maxX = max(segment.startPoint.x, segment.endPoint.x);
                    maxY = max(segment.startPoint.y, segment.endPoint.y);
                }
                else {
                    minX = min(minX,min(segment.startPoint.x, segment.endPoint.x));
                    minY = min(minY,min(segment.startPoint.y, segment.endPoint.y));
                    maxX = max(maxX,max(segment.startPoint.x, segment.endPoint.x));
                    maxY = max(maxY,max(segment.startPoint.y, segment.endPoint.y));
                }
                maxSegBrushWidh = max(maxSegBrushWidh, segment.thickness);
            }
            if(maxSegBrushWidh != -1) {
                var newBoundingRect = CGRect.init(x: CGFloat(minX),
                                                  y: CGFloat(minY),
                                                  width: CGFloat(maxX-minX),
                                                  height: CGFloat(maxY-minY));
                newBoundingRect = newBoundingRect.insetBy(dx: -CGFloat(maxSegBrushWidh*0.5),
                                                          dy: -CGFloat(maxSegBrushWidh*0.5));
                self.boundingRect = newBoundingRect;
            }
        }
    }

    override func setOffset(_ offset: CGPoint) {
        objc_sync_enter(self);
        if(offset != CGPoint.zero) {
            (self.associatedPage as? FTPageTileAnnotationMap)?.tileMapRemoveAnnotation(self);
            for i in 0..<self.segmentCount {
                self.segmentArray[i].startPoint.translate(dx: Float(offset.x), dy: Float(offset.y));
                self.segmentArray[i].endPoint.translate(dx: Float(offset.x), dy: Float(offset.y));

                self.segmentsTransientArray[i].bounds = self.segmentArray[i].bounds();
            }
            var strokeBoundRect = self.boundingRect;
            var originPoint = strokeBoundRect.origin;
            originPoint.translate(dx: Float(offset.x), dy: Float(offset.y));
            strokeBoundRect.origin = originPoint;
            self.boundingRect = strokeBoundRect;
            self.associatedPage?.isDirty = true;
            (self.associatedPage as? FTPageTileAnnotationMap)?.tileMapAddAnnotation(self);
        }
        objc_sync_exit(self);
    }

    override func setRotation(_ angle: CGFloat, refPoint: CGPoint) {
        objc_sync_enter(self);
        if angle != 0 {
            (self.associatedPage as? FTPageTileAnnotationMap)?.tileMapRemoveAnnotation(self);
            var strokeBoundRect = CGRect.null;
            for i in 0..<self.segmentCount {
                self.segmentArray[i].startPoint.rotate(by: angle, refPoint: refPoint)
                self.segmentArray[i].endPoint.rotate(by: angle, refPoint: refPoint);

                let bounds = self.segmentArray[i].bounds();
                self.segmentsTransientArray[i].bounds = bounds
                strokeBoundRect = strokeBoundRect.union(bounds)
            }
            self.boundingRect = strokeBoundRect;
            self.associatedPage?.isDirty = true;
            (self.associatedPage as? FTPageTileAnnotationMap)?.tileMapAddAnnotation(self);
        }
        objc_sync_exit(self);
    }
    
    func points(averageThickness : UnsafeMutablePointer<CGFloat>,averageAlpha : UnsafeMutablePointer<CGFloat>) -> [CGPoint]
    {
        objc_sync_enter(self);
        var totalThickness = CGFloat(0);
        var totalalpha = CGFloat(0);
        
        var points = [CGPoint]();
        let segCount = self.segmentCount;
        for index in 0..<segCount {
            let seg = self.segmentArray[index];
            points.append(CGPoint(ftpoint: seg.startPoint));
            points.append(CGPoint(ftpoint: seg.endPoint));
            totalThickness += CGFloat(seg.thickness);
            totalalpha += CGFloat(seg.opacity);
        }
        averageThickness.pointee = totalThickness/CGFloat(segCount);
        averageAlpha.pointee = totalalpha/CGFloat(segCount);
        objc_sync_exit(self);
        return points;
    }
    
    override var supportsHandwrittenRecognition : Bool {
        if(self.penType.isHighlighterPenType()) {
            return false;
        }
        return true;
    }

    //MARK: - Repair
    ///Fixed some segment corrution when duplicated or copied NS1 Contents.
    override func repairIfRequired() -> Bool {
        var shouldSave = false
        if FTUserDefaults.isInSafeMode() {
            var previousSeg : FTSegmentStruct?
            for i in 0..<segmentCount {
                let segment = self.segmentArray[i];
                if let _prevSeg = previousSeg {
                    if segment.startPoint.x != _prevSeg.endPoint.x
                        || segment.startPoint.y != _prevSeg.endPoint.y {

                        self.segmentArray[i].startPoint = _prevSeg.endPoint;
                        self.segmentArray[i].endPoint = self.segmentArray[i].startPoint;
                        self.segmentArray[i].thickness = _prevSeg.thickness;
                        shouldSave = true
                    }
                }
                previousSeg = segment
            }
        }
        return shouldSave
    }
}

extension FTStroke
{
    func generateStrokesByRemovingErasedSegments() -> [FTAnnotation]
    {
        //1.Go through each segment and find the first segment which is not erased.
        //2.Create a new FTStroke object and add all subsequent segments that are not erased.
        //3.Continue till you find a segment which is erased.
        //4.End the stroke and add it to an array.

        //Returning same stroke if it has no erased segments, to avoid processing of creating
        let firstErasedSegment = self.segmentArray.first(where: { $0.isErased })
        guard nil != firstErasedSegment else {
            return [self]
        }


        var newStrokes = [FTStroke]();
        var index = Int(0);

        let segCount = self.segmentCount;
        while(index < segCount) {
            if(!segmentArray[index].isErased) {
                let stroke = FTStroke();
                stroke.strokeWidth = self.strokeWidth;
                stroke.strokeColor = self.strokeColor;
                stroke.penType = self.penType;

                stroke.isReadonly = self.isReadonly;
                stroke.version = self.version;

                var minX = Float(0),minY = Float(0),maxX = Float(0),maxY = Float(0);
                var maxSegBrushWidth = Float(0);

                var firstTime = true;
                while (index < segCount && !segmentArray[index].isErased) {
                    let segment = segmentArray[index];
                    if(firstTime) {
                        firstTime = false;
                        minX = min(segment.startPoint.x, segment.endPoint.x);
                        minY = min(segment.startPoint.y, segment.endPoint.y);
                        maxX = max(segment.startPoint.x, segment.endPoint.x);
                        maxY = max(segment.startPoint.y, segment.endPoint.y);
                    }
                    else {
                        minX = min(minX,min(segment.startPoint.x, segment.endPoint.x));
                        minY = min(minY,min(segment.startPoint.y, segment.endPoint.y));
                        maxX = max(maxX,max(segment.startPoint.x, segment.endPoint.x));
                        maxY = max(maxY,max(segment.startPoint.y, segment.endPoint.y));
                    }
                    maxSegBrushWidth = max(maxSegBrushWidth, segment.thickness);

                    stroke.addSegment(startPoint: CGPoint.init(ftpoint: segment.startPoint),
                                      endPoint: CGPoint.init(ftpoint: segment.endPoint),
                                      thickness: CGFloat(segment.thickness),
                                      opacity: CGFloat(segment.opacity));
                    index += 1;
                }

                var boundingRect = CGRect.init(x: CGFloat(minX), y: CGFloat(minY), width: CGFloat(maxX-minX), height: CGFloat(maxY-minY));
                boundingRect = boundingRect.insetBy(dx: CGFloat(-maxSegBrushWidth*0.5), dy: CGFloat(-maxSegBrushWidth*0.5));
                stroke.boundingRect = boundingRect;
                newStrokes.append(stroke);
                index += 1;
            }
            else {
                index += 1;
            }
        }
        return newStrokes;
    }
}

//MARK:- FTTransformColorUpdate
extension FTStroke : FTTransformColorUpdate    
{
    func update(color: UIColor) -> FTUndoableInfo {
        let undoInfo = self.undoInfo()
        self.strokeColor = color;
        return undoInfo
    }

    var currentColor: UIColor? {
        return self.strokeColor;
    }
}
//MARK:- FTAnnotationUndoRedo
extension FTStroke
{
    override func undoInfo() -> FTUndoableInfo {
        let undoInfo = FTStrokeUndoableInfo()
        undoInfo.color = strokeColor
        return undoInfo
    }

    override func updateWithUndoInfo(_ info: FTUndoableInfo) {
        guard let strokeInfo = info as? FTStrokeUndoableInfo else {
            fatalError("info should be of type FTStrokeUndoableInfo");
        }
        if let _color = strokeInfo.color {
            self.strokeColor = _color
        }
    }
}

private class FTStrokeUndoableInfo : FTUndoableInfo {
    var color: UIColor?
    override func isEqual(_ object: Any?) -> Bool {
        guard let strokeInfo = object as? FTStrokeUndoableInfo else {
            return false
        }
        if(super.isEqual(strokeInfo) &&
            self.color?.hexStringFromColor() == strokeInfo.color?.hexStringFromColor()) {
            return true;
        }
        return false;
    }
}

//MARK:- FTCopying
extension FTStroke
{
    override func deepCopyAnnotation(_ toPage: FTPageProtocol, onCompletion: @escaping (FTAnnotation?) -> Void) {
        let stroke = FTStroke.init(withPage : toPage);

        stroke.isReadonly = self.isReadonly;
        stroke.version = self.version;

        stroke.strokeColor = self.strokeColor;
        stroke.strokeWidth = self.strokeWidth;
        stroke.penType = self.penType;
        stroke.boundingRect = self.boundingRect;
        
        stroke.segmentCount = self.segmentCount;

        stroke.segmentsTransientArray = self.segmentsTransientArray;
        stroke.segmentArray = self.segmentArray;
        onCompletion(stroke);
    }
}

//MARK:- FTTransformScale
extension FTStroke
{
    override func apply(_ scale: CGFloat) {
        if(scale == 1) {
            return;
        }
        objc_sync_enter(self);
        var strokeBoundingRect = self.boundingRect;
        for i in 0..<self.segmentCount {
            let endPoint = CGPoint.init(ftpoint: self.segmentArray[i].endPoint);
            let endPointOffsetx = (endPoint.x - strokeBoundingRect.origin.x)*scale;
            let endPointOffsety = (endPoint.y - strokeBoundingRect.origin.y)*scale;
            let finalEndPoint = CGPointTranslate(strokeBoundingRect.origin, endPointOffsetx, endPointOffsety);
            self.segmentArray[i].endPoint = FTPoint.init(cgpoint : finalEndPoint);
            
            let startPoint = CGPoint.init(ftpoint: self.segmentArray[i].startPoint);
            let stPointOffsetx = (startPoint.x - strokeBoundingRect.origin.x)*scale;
            let stPointOffsety = (startPoint.y - strokeBoundingRect.origin.y)*scale;
            let finalStartPoint = CGPointTranslate(strokeBoundingRect.origin, stPointOffsetx, stPointOffsety);
            self.segmentArray[i].startPoint = FTPoint.init(cgpoint : finalStartPoint);
            self.segmentArray[i].thickness *= Float(scale);
            self.segmentsTransientArray[i].bounds = self.segmentArray[i].bounds()
        }
        
        strokeBoundingRect.size.height *= scale;
        strokeBoundingRect.size.width *= scale;
        self.boundingRect = strokeBoundingRect;
        objc_sync_exit(self);
    }
}

//MARK:- FTAnnotationContainsProtocol
extension FTStroke : FTAnnotationContainsProtocol
{
    @objc func isPointInside(_ point: CGPoint) -> Bool {
        return self.boundingRect.contains(point);
    }
    
    func intersectsPath(_ inSelectionPath: CGPath, withScale scale: CGFloat, withOffset selectionOffset: CGPoint) -> Bool {
        objc_sync_enter(self);
        var result = false;
        var selectionPathBounds = inSelectionPath.boundingBox;
        selectionPathBounds.origin = CGPoint.init(x: selectionPathBounds.origin.x + selectionOffset.x,
                                                  y: selectionPathBounds.origin.y + selectionOffset.y);
        let boundingRect1 = CGRectScale(self.boundingRect, scale);
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
}

extension FTStroke : FTCGContextRendering {
    func render(in context: CGContext!, scale: CGFloat) {
        let strokes = self.generateStrokesByRemovingErasedSegments();
        for stroke in strokes {
            (stroke as? FTStroke)?.renderFinalStroke(in:context, scale: scale)
        }
    }
    
    private func renderFinalStroke(in context: CGContext!, scale: CGFloat) {
        context.saveGState();
        
        let rect = context.boundingBoxOfClipPath;
        context.translateBy(x: rect.origin.x, y: rect.size.height);
        context.scaleBy(x: 1, y: -1);
        if(self.penType.isHighlighterPenType() || self.penType == .pencil) {
            var bgColor = UIColor.white
            //We're using the background color to change the render mode for the highlighter, only for the templates, as we;re getting issues with the custom templates.
            if self.associatedPage?.templateInfo.isTemplate == true {
                bgColor = (self.associatedPage as? FTPageBackgroundColorProtocol)?.pageBackgroundColor ?? .white;
            }

            if bgColor.isDarkColor {
                context.setAlpha((self.penType == .pencil) ? 0.7 : 0.3)
                context.setBlendMode(CGBlendMode.screen)
            } else {
                context.setAlpha((self.penType == .pencil) ? 0.7 : 0.5)
                let rgbComp = self.strokeColor.rgbComp;
                if (rgbComp.x > 0.95 && rgbComp.y > 0.95 && rgbComp.z > 0.95) {
                    context.setBlendMode(.destinationOut)
                } else {
                    context.setBlendMode(CGBlendMode.multiply)
                }
            }
            context.beginTransparencyLayer(auxiliaryInfo: nil);
        }
        //Iterate through the segments and render each segment using CGPath
        let optimizedSegments = SwiftSimplify.simplify(self.segmentArray, tolerance: .good, highQuality:true)
        let segmentsToRender: [FTSegmentStruct];
        
        if(usePointSimpliedLogicForHightlighter) {
            segmentsToRender = optimizedSegments;
        }
        else {
            segmentsToRender = (self.penType == .flatHighlighter) ? self.segmentArray : optimizedSegments;
        }
        
        for i in 0..<segmentsToRender.count {
            var prevSeg : FTSegmentStruct?;
            let curSeg : FTSegmentStruct = segmentsToRender[i];
            
            if(i > 0) {
                prevSeg = segmentsToRender[i-1];
            }
            self.renderSegment(prevSegment: prevSeg,
                               currentSegment: curSeg,
                               index: i,
                               scale: scale,
                               context: context);
        }
        if(self.penType.isHighlighterPenType() || self.penType == .pencil) {
            context.endTransparencyLayer()
        }
        context.restoreGState();
    }
    
    private func renderSegment(prevSegment : FTSegmentStruct?,
                               currentSegment : FTSegmentStruct,
                               index : Int,
                               scale : CGFloat,
                               context : CGContext)
    {
        var start = CGPoint.zero,end = CGPoint.zero,cp = CGPoint.zero;
        if(index > 0) {
            start = CGPoint.init(x: CGFloat((prevSegment!.startPoint.x + prevSegment!.endPoint.x)*0.5),
                                 y: CGFloat((prevSegment!.startPoint.y + prevSegment!.endPoint.y)*0.5));
            end = CGPoint.init(x: CGFloat((currentSegment.startPoint.x + currentSegment.endPoint.x)*0.5),
                               y: CGFloat((currentSegment.startPoint.y + currentSegment.endPoint.y)*0.5));
            cp = CGPoint.init(ftpoint: currentSegment.startPoint);
            
            self.renderSegment(scale: scale,
                               start: start,
                               end: end,
                               controlPoint: cp,
                               context: context,
                               segmentThickness: CGFloat(currentSegment.thickness));
        }
        else {
            //first segment
            start = CGPoint.init(ftpoint: currentSegment.startPoint);
            end = CGPoint.init(x: CGFloat((currentSegment.startPoint.x + currentSegment.endPoint.x)*0.5),
                               y: CGFloat((currentSegment.startPoint.y + currentSegment.endPoint.y)*0.5));
            self.renderSegment(scale: scale,
                               start: start,
                               end: end,
                               controlPoint: start,
                               context: context,
                               segmentThickness: CGFloat(currentSegment.thickness));
        }
        
        if(index == segmentCount-1)
        {
            //last segment
            start = CGPoint.init(x: CGFloat((currentSegment.startPoint.x + currentSegment.endPoint.x)*0.5),
                                 y: CGFloat((currentSegment.startPoint.y + currentSegment.endPoint.y)*0.5));
            end = CGPoint.init(ftpoint: currentSegment.endPoint);

            self.renderSegment(scale: scale,
                               start: start,
                               end: end,
                               controlPoint: start,
                               context: context,
                               segmentThickness: CGFloat(currentSegment.thickness));
        }
    }
    
    private func renderSegment(scale : CGFloat,
                               start : CGPoint,
                               end : CGPoint,
                               controlPoint cp : CGPoint,
                               context : CGContext,
                               segmentThickness : CGFloat)
    {
        context.saveGState();
        var thicknessCorrectionFactor = CGFloat(0);
        
        //This thicknes varying logic based on stroke width is to match the existing stroke thickness for export.
        thicknessCorrectionFactor = FTBrushBuilder.thicknessCorrectionFactor(penType: penType,brushWidth: self.strokeWidth,version: self.version);
        let thickness = segmentThickness * scale * thicknessCorrectionFactor;
        var startPoint = CGPointScale(start, scale);
        var endPoint = CGPointScale(end, scale);
        var controlPoint = CGPointScale(cp, scale);

        let path = UIBezierPath.init();
        let renderTruCal = true;
        if(renderTruCal && (self.penType == .flatHighlighter || self.penType == .caligraphy)) {
            let xOffset: CGFloat;
            let angle: CGFloat;
            if(self.penType == .flatHighlighter) {
                if(usePointSimpliedLogicForHightlighter) {
                    xOffset = 0;
                }
                else {
                    xOffset = self.highlighterRenderingOffsetFactor();
                }
                angle = 90*CGFloat.pi/180;
            }
            else {
                xOffset = 0;
                angle = 45*CGFloat.pi/180;
            }
            
            startPoint = CGPointTranslate(startPoint, -xOffset, thickness*0.5);
            endPoint = CGPointTranslate(endPoint, xOffset, thickness*0.5);
            controlPoint = CGPointTranslate(controlPoint, 0, thickness*0.5);
            
            path.move(to: startPoint);
            path.addQuadCurve(to: endPoint, controlPoint: controlPoint);

            let distance = thickness;
            var X = distance*cos(angle) + endPoint.x;
            var Y = -distance*sin(angle) + endPoint.y;
            
            let endOtherSidePoint = CGPoint.init(x: X, y: Y);
            
            X = distance*cos(angle) + startPoint.x;
            Y = -distance*sin(angle) + startPoint.y;
            
            let startOtherSidePoint = CGPoint.init(x: X, y: Y);
            
            X = distance*cos(angle) + controlPoint.x;
            Y = -distance*sin(angle) + controlPoint.y;
            let controlOtherSidePoint = CGPoint.init(x: X, y: Y);
            
            path.addLine(to: endOtherSidePoint);
            path.addQuadCurve(to: startOtherSidePoint, controlPoint: controlOtherSidePoint);
            path.addLine(to: startPoint);
            path.close();
        }
        else {
            path.move(to: startPoint);
            path.addQuadCurve(to: endPoint, controlPoint: controlPoint);
        }
        context.addPath(path.cgPath);
        let color = self.strokeColor;

        if(renderTruCal && (self.penType == .flatHighlighter || self.penType == .caligraphy)) {
            if(self.penType == .caligraphy) {
                context.setStrokeColor(color.cgColor);
                context.setLineWidth(self.strokeWidth/10);
                context.strokePath();
            }
            else {
                if(usePointSimpliedLogicForHightlighter) {
                    context.setStrokeColor(color.cgColor);
                    context.setLineWidth(self.highlighterRenderingOffsetFactor());
                    context.strokePath();
                }
            }
            
            context.addPath(path.cgPath);
            context.setFillColor(color.cgColor);
            context.fillPath();
        }
        else {
            context.setStrokeColor(color.cgColor);
            context.setLineWidth(thickness);
            context.setLineCap(CGLineCap.round);
            context.strokePath();
        }
        
        context.restoreGState();
    }
}

extension FTStroke : NSSecureCoding {
    public class var supportsSecureCoding: Bool {
        return true;
    }
}

extension FTStroke : FTAnnotationErase
{
    func canErase(eraseRect rects: [CGRect]) -> Bool {
        objc_sync_enter(self);
        var shouldErase = false
        main: for index in 0..<segmentCount {
            let boundRect = self.segmentBounds(index: index);
            for rectIn1x in rects where rectIn1x.intersects(boundRect) {
                shouldErase = true
                break main;
            }
        }
        objc_sync_exit(self);
        return shouldErase
    }
}

extension FTStroke : FTAnnotationStrokeErase
{
    func eraseSegments(in rects: [CGRect],addTo segCache : FTSegmentTransientCache) -> (CGRect)
        {
            objc_sync_enter(self);
            var erasedSegmentsRect : CGRect = CGRect.null;
            for i in 0..<segmentCount {
                let transientSegment = self.segmentsTransientArray[i]
                if !segmentArray[i].isErased {
                    let boundRect = transientSegment.bounds;
                    if(boundRect.intersects(with:rects)) {
                        self.segmentArray[i].isErased = true;
                        erasedSegmentsRect = erasedSegmentsRect.union(boundRect);
                        let cacheSegment = FTErasedSegmentCache(stroke: self, index: i)
                        segCache.addEraseCache(cacheSegment);
                    }
                }
            }
            objc_sync_exit(self);
            return erasedSegmentsRect;
        }

    func setErase(isErased: Bool, index: Int) {
        objc_sync_enter(self)
        if index < segmentCount {
            self.segmentArray[index].isErased = isErased
        }
        objc_sync_exit(self)
    }
}

private extension FTStroke {
    private func _highlighterRenderingOffsetFactorSimpliedPoints() -> CGFloat {
        let factor: CGFloat;
        switch(self.strokeWidth) {
        case 1:
            factor = 2;
        case 2:
            factor = 4;
        case 3:
            factor = 5;
        case 4:
            factor = 6;
        case 5:
            factor = 7;
        case 6:
            factor = 9;
        default:
            factor = 0;
        }
        return factor;
    }
    private func _highlighterRenderingOffsetNormal() -> CGFloat {
        let factor: CGFloat;
        switch(self.strokeWidth) {
        case 1:
            factor = 1;
        case 2:
            factor = 2;
        case 3:
            factor = 3;
        case 4:
            factor = 3.5;
        case 5:
            factor = 4.25;
        case 6:
            factor = 5;
        default:
            factor = 0;
        }
        return factor;
    }

    func highlighterRenderingOffsetFactor() -> CGFloat {
        if(usePointSimpliedLogicForHightlighter) {
            return _highlighterRenderingOffsetFactorSimpliedPoints();
        }
        else {
            return _highlighterRenderingOffsetNormal();
        }
    }
}

extension FTStroke:FTLaserStrokeAnnotationProtocol {
    func laserBrushTexture(scale: CGFloat) -> FTLaserBrushTexture {
        let texture = FTLaserBrushTexture();
        texture.innerStrokeColor = UIColor.white
        if self.penType == .laser {
            texture.innerStrokeScaleFactor = 4/10
        }
        else {
            texture.innerStrokeScaleFactor = (5/44)*Float(UIScreen.main.scale);
        }
        texture.innerCoreTexture = FTBrushBuilder.metalBrushTextureFor(penType: self.penType,
                                                                       brushWidth: FTLaserPenThickness.secondary.rawValue,
                                                                       scale: 1,
                                                                       version: self.version)
        
        
        return texture;
    }
}
