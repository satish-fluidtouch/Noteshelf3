//
//  FTOnScreenWritingViewController.swift
//  Noteshelf
//
//  Created by Amar on 21/12/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FirebaseAnalytics

private let SHOW_INSTANCE_COUNTER = false;
private var instance_Counter = Int(0);

class FTOnScreenWritingViewController: UIViewController {
    
    weak var delegate : FTContentDelegate?;
    internal weak var pageNavigationShowObserver: NSObjectProtocol?;
    
    private weak var metalView: FTMetalView!;
    fileprivate var currentExecutingRequest : FTOnScreenRenderRequest?;
    fileprivate var currentExecutingID : String?;
    fileprivate var previousRefreshRect = CGRect.null;
    fileprivate var previousTouch: FTTouch?;
    
    var lastWritingMode : RKDeskMode = RKDeskMode.deskModePen;
    var currentWritingModeChanged : Bool = false;
    var strokeInProgress = false;
    weak var activeAnnotationController: FTAnnotationEditController?
    fileprivate var erasedSegmentCache = FTSegmentTransientCache();
    fileprivate var eraserBackgroundQueue = DispatchQueue.init(label: "com.fluidtouch.noteshelf.eraserOperation", qos: .userInteractive);
    fileprivate var accumulatedRects = [CGRect]()
    fileprivate var eraseInProgress : Bool = false;
    fileprivate var eraseOperationCancelled : Bool = false;
    fileprivate var lastEraserOperationRect : CGRect = CGRect.null;
    fileprivate var eraserOperationLastRenderedRect : CGRect = CGRect.null;
    fileprivate var annotationsToRemove:[FTAnnotation] = []
    fileprivate var isEraseQueueInProgress = false;
    fileprivate var isEraseRenderInProgress = false;
    var displayLink : CADisplayLink?;
    private var isShapeDetectonScheduled = false;
    internal weak var pdfSelectionView: FTPDFSelectionView? {
        return self.view as? FTPDFSelectionView;
    }

    fileprivate weak var _onScreenRenderer : FTOnScreenRenderer?
    fileprivate var currentRenderer : FTOnScreenRenderer?
    {
        if(nil == _onScreenRenderer) {
            _onScreenRenderer = FTRendererProvider.shared.dequeOnscreenRenderer();
        }
        _onScreenRenderer?.bind(view: self.metalView);
        return _onScreenRenderer
    }
    
    private weak var eraserStopObserver : NSObjectProtocol?
    var currentStroke : FTCurrentStroke?;

    var currentDrawingMode : RKDeskMode {
        var mode = RKDeskMode.deskModeView;
        if let penAttributesProvider = self.delegate?.penAttributesProvider {
            return penAttributesProvider.currentDeskMode();
        }
        else if let del = self.delegate {
            mode = del.currentDrawingMode;
        }
        return mode;
    };
    
    class func viewController(delegate : FTContentDelegate) -> FTOnScreenWritingViewController
    {
        let vc = FTOnScreenWritingViewController.init(nibName: "FTOnScreenWritingViewController", bundle: nil);
        vc.delegate = delegate;
        return vc;
    }
    
    override func loadView()
    {
        let _metalView = FTMetalView.init(frame: UIScreen.main.bounds);
        _metalView.isUserInteractionEnabled = false;
        self.metalView = _metalView;

        let view = FTPDFSelectionView(frame: UIScreen.main.bounds);
        view.isMultipleTouchEnabled = true;
        view.setDelegate(self)
        view.autoresizingMask = [.flexibleWidth,.flexibleHeight];
        view.addSubview(_metalView);
        self.view = view;
    }
    
    var scale : CGFloat {
        var scaleToReturn : CGFloat = 1;
        if let del = self.delegate {
            scaleToReturn = del.contentScale;
        }
        return scaleToReturn;
    };
    
    func setVisibleRect( _ rect: CGRect) {
        let currentFrame = self.metalView.frame;
        if(rect != currentFrame) {
            self.metalView.frame = rect;
            self.view.layoutIfNeeded();
        }
    }
        
    func didChangeDeskMode(_ mode: RKDeskMode) {
        self.selectedTextRange = nil;
    }
    
    var selectedTextRange: UITextRange? {
        get {
            return self.pdfSelectionView?.selectedTextRange;
        }
        set {
            self.pdfSelectionView?.selectedTextRange = newValue;
        }
    }
    
    var selectedText: String? {
        guard let range = self.selectedTextRange, !range.isEmpty else {
            return nil;
        }
        return self.pdfSelectionView?.text(in: range);
    }
    func hideWritingView() {
        self.metalView.isHidden = true;
    }
    
    var presentsWithTransaction: Bool {
        get {
            return (self.metalView.layer as? CAMetalLayer)?.presentsWithTransaction ?? false;
        }
        set {
            (self.metalView.layer as? CAMetalLayer)?.presentsWithTransaction = newValue
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad();
        if(SHOW_INSTANCE_COUNTER) {
            instance_Counter += 1;
            debugPrint("FTDrawingView init:\(instance_Counter)");
        }
        
        if(nil == self.displayLink) {
            self.displayLink = CADisplayLink.init(target: self, selector: #selector(self.renderMetalView));
            self.displayLink?.isPaused = true;
            self.displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 20, maximum: 60, preferred: 60);
            self.displayLink?.add(to: RunLoop.current, forMode: RunLoop.Mode.default);
        }
        addObserverForOnScreenRendererReleaseNotification()
        self.addObserversForQuickPageNavigator()
        setupSingleTapPopoverDismissNotification()
        #if DEBUG
//        if(FTDeveloperOption.showOnScreenBorder) {
//            self.view.layer.borderWidth = 5.0
//            self.view.layer.borderColor = UIColor.red.cgColor
//        }
        #endif
    }

    var pageToDisplay: FTPageProtocol? {
        get {
            return self.delegate?.pageToDisplay;
        }
        set {
            self.selectedTextRange = nil;
            self.pdfSelectionView?.page = newValue;
        }
    }
    
    deinit {
        FTRendererProvider.shared.enqueOnscreenRenderer(_onScreenRenderer);
        self.currentExecutingRequest?.cancelRequest();
        NotificationCenter.default.removeObserver(self);
        
        if let observer = self.pageNavigationShowObserver {
            NotificationCenter.default.removeObserver(observer);
        }
        
        NSObject.cancelPreviousPerformRequests(withTarget: self);
        if(SHOW_INSTANCE_COUNTER) {
            instance_Counter -= 1;
            debugPrint("FTDrawingView deinit:\(instance_Counter)");
        }
        self.clearEraseBuffer();
    }
    
    override func willMove(toParent parent: UIViewController?) {
        if(parent == nil) {
            self.displayLink?.invalidate();
            self.displayLink = nil;
        }
    }
    
    func renderTiles(inRect rect: CGRect,
                     properties: FTRenderingProperties,
                     onCompletion:((Bool)->())?)
    {
        if self.currentExecutingRequest?.areaToRefresh == rect, !properties.synchronously {
            onCompletion?(false)
            return
        }
        
        if let pageToRead = self.pageToDisplay {
            if(self.previousRefreshRect != self.metalView.frame && !properties.synchronously) {
                self.metalView.isHidden = true;
            }
            self.previousRefreshRect = self.metalView.frame;

            let annotations = pageToRead.annotations() as [FTAnnotationProtocol];
            var bgColor = UIColor.white
            //We're using the background color to change the render mode for the highlighter, only for the templates, as we;re getting issues with the custom templates.
            if pageToRead.templateInfo.isTemplate == true {
                bgColor = (pageToRead as? FTPageBackgroundColorProtocol)?.pageBackgroundColor ?? .white;
            }
            let renderRequest = FTOnScreenRenderRequest(with: self.view.window?.hash);
            renderRequest.backgroundColor = bgColor;
            renderRequest.annotations = annotations;
            
            renderRequest.areaToRefresh = rect;
            renderRequest.contentSize = self.delegate?.contentSize ?? self.metalView.frame.size;
            renderRequest.visibleArea = self.metalView.frame;
            renderRequest.scale = self.scale;
            renderRequest.renderingProperties.synchronously = properties.synchronously;
            if FTRenderConstants.USE_BG_TILING {
                renderRequest.backgroundTextureTileContent = self.delegate?.backgroundTextureTileContent
            } else {
                renderRequest.backgroundTexture = self.delegate?.backgroundTexture;
            }
            if(properties.cancelPrevious) {
                self.currentExecutingRequest?.cancelRequest();
            }
            self.currentExecutingRequest = renderRequest;
            let currentID = self.currentRenderer?.render(request: renderRequest)
            self.currentExecutingID = currentID;
            renderRequest.completionBlock = { [weak self] (success) in
                DispatchQueue.main.async {[weak self] in
                var opSuccess = success;
                if(success) {
                    if self?.currentExecutingID != currentID {
                        opSuccess = false;
                    }
                    else {
                        self?.currentExecutingRequest = nil;
                    }
                }
                if(opSuccess){
                    self?.presentsWithTransaction = false;
                    self?.metalView.isHidden = false;
                }
                onCompletion?(opSuccess);
                }
            }
            
        }
        else {
            onCompletion?(false);
        }
    }
    
    func waitUntilComplete() {
        if(nil != self.currentRenderer) {
            self.currentRenderer?.waitUntilComplete();
            self.metalView.isHidden = false;
        }
    }
}

extension FTOnScreenWritingViewController
{
    @objc fileprivate func renderMetalView(_ displayLink : CADisplayLink)
    {
        if self.currentDrawingMode == .deskModeLaser {
            (self.delegate as? FTLaserTouchEventsHandling)?.publishLaserChanges();
            return;
        }
        
        if let currentRenderStroke = self.currentStroke {
            currentRenderStroke.encode(clipRect: CGRect.scale(currentRenderStroke.stroke.boundingRect, self.scale));
        }
        if eraseInProgress {
            refreshViewForEraser()
        } else {
            var writingMode: FTWritingMode = .pen;
            if self.currentDrawingMode == .deskModeMarker {
                writingMode = .highlighter;
            } else if self.currentDrawingMode == .deskModeFavorites {
                let mode = FTFavoritePensetManager(activity: self.view.userActivity).fetchCurrentFavoriteMode()
                if mode == .highlighter {
                    writingMode = .highlighter
                }
            }
            self.currentRenderer?.publishChanges(mode: writingMode, onCompletion: nil)
        }
    }
    
    private func refreshViewForEraser() {
        if !isEraseRenderInProgress && !eraserOperationLastRenderedRect.isNull {
            let properties = FTRenderingProperties();
            properties.renderImmediately = true;
            var rectToRefresh = CGRect.scale(self.eraserOperationLastRenderedRect, self.scale);
            let offset = CGFloat(-10) * self.scale;
            rectToRefresh = rectToRefresh.insetBy(dx: offset, dy: offset).integral;
            self.eraserOperationLastRenderedRect = CGRect.null
            isEraseRenderInProgress = true
            
            self.renderTiles(inRect: rectToRefresh, properties: properties) { _ in
                self.isEraseRenderInProgress = false
            }
            properties.avoidOffscreenRefresh = true;

            self.delegate?.reloadTiles(forIntents: [.offScreen],
                                       rect: rectToRefresh,
                                       properties: properties);
        }
    }
    
    private func schedulShapeDetection(_ touch:FTTouch) {
        if(!isShapeDetectonScheduled) {
            cancelScheduledShapeDetection(touch);
            self.perform(#selector(performShapeRenderingFor(_:)),
                         with: touch,
                         afterDelay: FTShapeDetector.minimumHoldinterval)
            isShapeDetectonScheduled = true;
        }
    }

    private func cancelScheduledShapeDetection(_ touch: FTTouch) {
        if(isShapeDetectonScheduled) {
            NSObject.cancelPreviousPerformRequests(withTarget: self,
                                                   selector: #selector(performShapeRenderingFor(_:)),
                                                   object: touch);
            isShapeDetectonScheduled = false;
        }
    }
    
    func processVertex(touch : FTTouch,vertexType : FTVertexType,isShapeEnabled : Bool = false)
    {
        self.previousTouch = touch
        switch vertexType {
        case .FirstVertex:
            if self.currentDrawingMode == .deskModeLaser {
                (self.delegate as? FTLaserTouchEventsHandling)?.processLaserVertex(touch: touch,
                                                                                  vertexType: vertexType)
                self.cancelDisableLongPressGesture();
                break;
            }
            if self.currentRenderer != nil {
                cancelScheduledShapeDetection(touch)
                let penSet = self.currentSelectedPenSet()
                let stroke = FTStroke();
                stroke.strokeWidth = CGFloat(penSet.size.rawValue)
                stroke.strokeColor = UIColor(hexString: penSet.color);
                stroke.penType = penSet.type.penType();

                let properties = FTBrushBuilder.penAttributesFor(penType:stroke.penType,
                                                                 brushWidth: penSet.preciseSize,
                                                                 isShapeTool: self.isShapeDetectionEnabled(),
                                                                 version: FTStroke.defaultAnnotationVersion());
                let strokeAttributes = properties.asStrokeAttributes()
                self.currentStroke = FTCurrentStroke(withScale: self.scale,
                                                     stroke: stroke,
                                                     attributes:strokeAttributes,
                                                     renderDelegate: self)
            }
            self.currentStroke?.processTouch(touch,
                                             vertexType: .FirstVertex,
                                             touchView: self.view);
            self.cancelDisableLongPressGesture();
            if let del = self.delegate, del.mode == FTRenderModeZoom {
                NotificationCenter.default.post(name: NSNotification.Name(FTZoomRenderViewDidBeginTouches), object: self.view.window);
            }
        case .InterimVertex:
            if self.currentDrawingMode == .deskModeLaser {
                (self.delegate as? FTLaserTouchEventsHandling)?.processLaserVertex(touch: touch,
                                                                                  vertexType: vertexType)
            }
            else {
                self.currentStroke?.processTouch(touch,
                                                 vertexType: .InterimVertex,
                                                 touchView: self.view);
            }
            self.cancelDisableLongPressGesture();
            self.scheduleDisableLongPressGesture();
            
            if shouldScheduleShapeDetection(), let curStroke = self.currentStroke?.stroke as? FTStroke
            {
                let canDetect = FTShapeDetector.canDetectShape(stroke: curStroke, scale: self.scale)
                if(!FTShapeDetector.canConsiderAsLongPress(touch:touch)) {
                    cancelScheduledShapeDetection(touch)
                }
                if(canDetect) {
                    schedulShapeDetection(touch);
                }
            }
            else {
                cancelScheduledShapeDetection(touch);
            }
        case .LastVertex:
            if self.currentDrawingMode == .deskModeLaser {
                (self.delegate as? FTLaserTouchEventsHandling)?.processLaserVertex(touch: touch,
                                                                                  vertexType: vertexType)
                self.cancelDisableLongPressGesture();
                break;
            }
            self.previousTouch = nil;
            cancelScheduledShapeDetection(touch);
            self.currentStroke?.processTouch(touch,
                                             vertexType: .LastVertex,
                                             touchView: self.view);
            var rectToRefresh = CGRect.null;
            let shapeDetectionEnabled = self.isShapeDetectionEnabled();
            var isShapeRendered = false
            //For drawing straight lines in highlighter mode when draw straight lines option is turned on
            //isShapeEnabled - This will be true only when user holds and convert to shape
            if self.toDrawStraightLineInFavoriteMode(),
               let curStroke = self.currentStroke?.stroke as? FTStroke, !isShapeEnabled {
                let shapeDetector = FTShapeDetector.init(delegate: self)
                let lineDetected = shapeDetector.detectedLineFor(stroke: curStroke, scale: self.scale).1
                let strokes = shapeDetector.detectedLineFor(stroke: curStroke, scale: self.scale).0
                if lineDetected {
                    rectToRefresh = curStroke.boundingRect
                    if !strokes.isEmpty {
                        rectToRefresh = self.renderDetectedShapeStrokes(strokes, rectToRefresh: rectToRefresh);
                        isShapeRendered = true
                    }
                }
            }
            if(shapeDetectionEnabled || isShapeEnabled) {
                let detectedShape = self.drawDetectedShape()
                isShapeRendered = detectedShape.hasShape
                if detectedShape.hasShape {
                    rectToRefresh = detectedShape.areaToRefresh;
                    if let ann = detectedShape.strokes?.first as? FTAnnotation {
                        ann.inLineEditing = isShapeEnabled
                        self.delegate?.editShapeAnnotation(with: ann, point: touch.activeUItouch.location(in: self.view))
                    }
                }
            }
            if(!isShapeRendered) {
                guard let curStroke = self.currentStroke?.stroke as? FTAnnotation else { return }
                rectToRefresh = curStroke.renderingRect;
                self.delegate?.addAnnotations([curStroke],
                                              refreshView: false);
                let properties = FTRenderingProperties();
                properties.avoidOffscreenRefresh = true;
                self.delegate?.reloadTiles(forIntents: [.offScreen],
                                           rect: CGRectScale(rectToRefresh, self.scale).integral,
                                           properties: properties);
                self.currentStroke = nil;
            }

            NSObject.cancelPreviousPerformRequests(withTarget: self,
                                                   selector: #selector(performShapeRenderingFor(_:)),
                                                   object: touch);
            if let del = self.delegate, del.mode == FTRenderModeZoom, !isShapeRendered {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
                    let notification = Notification.init(name: Notification.Name.FTZoomRenderViewDidEndCurrentStroke,
                                                         object: self.view.window,
                                                         userInfo: [FTImpactedRectKey : NSValue.init(cgRect: rectToRefresh)]);
                    NotificationCenter.default.post(notification);
                }
                
                NotificationCenter.default.post(name: NSNotification.Name(FTZoomRenderViewDidEndTouches),
                                                object: self.view.window,
                                                userInfo: [FTImpactedRectKey : NSValue.init(cgRect: rectToRefresh)])
            }
            self.cancelDisableLongPressGesture();
            
        }
    }
    
    private func shouldScheduleShapeDetection() -> Bool {
        var valurToReturn = false
        if ((currentDrawingMode == .deskModePen && FTUserDefaults.isHoldToConvertToShapeOnForPen()) ||
            (currentDrawingMode == .deskModeMarker && FTUserDefaults.isHoldToConvertToShapeOnForHighlighter()) ||
            (currentDrawingMode == .deskModeShape) ||
            self.toDetectShapeInFavoritesMode()) {
            valurToReturn = true
        }
        return valurToReturn
    }
    
    func endCurrentStroke() {
        if let _touch = self.previousTouch,nil != self.currentStroke {
            self.stylusPenTouchEnded(_touch);
        }
    }
    
    func cancelCurrentStroke()
    {
        if let currentStroke = self.currentStroke,let page = self.pageToDisplay {
            currentStroke.didCancelCurrentStroke();
            //highlighter does not require cancel stroke as it is not yet finalized
            if(!currentStroke.stroke.penType.isHighlighterPenType()) {
                if let stroke = self.currentStroke?.stroke, !stroke.boundingRect.isNull {
                    let annotations = page.annotations();
                    let bgColor = (page as? FTPageBackgroundColorProtocol)?.pageBackgroundColor ?? .white
                    let renderRequest = FTOnScreenRenderRequest(with: self.view.window?.hash);
                    renderRequest.backgroundColor = bgColor;
                    renderRequest.annotations = annotations;
                    
                    renderRequest.areaToRefresh = CGRectScale(stroke.boundingRect, self.scale);
                    renderRequest.contentSize = self.delegate?.contentSize ?? self.metalView.frame.size;
                    renderRequest.visibleArea = self.metalView.frame;
                    renderRequest.scale = self.scale;
                    
                    renderRequest.renderingProperties.synchronously = true;
                    if FTRenderConstants.USE_BG_TILING {
                        renderRequest.backgroundTextureTileContent = self.delegate?.backgroundTextureTileContent;
                    } else {
                        renderRequest.backgroundTexture = self.delegate?.backgroundTexture;
                    }
                    _ = self.currentRenderer?.render(request: renderRequest);
                    self.currentRenderer?.waitUntilComplete();
                }
            }
        }
        
        self.cancelDisableLongPressGesture();
        self.currentStroke = nil;
        self.previousTouch = nil;
    }
    
    @objc private func performShapeRenderingFor(_ touch : FTTouch){
        self.stylusPenTouchEnded(touch, isShapeEnabled: true);
    }
    
    private func toDetectShapeInFavoritesMode() -> Bool {
        guard self.currentDrawingMode == .deskModeFavorites else {
            return false
        }
        let isHighlighter = self.currentSelectedPenSet().type.isHighlighterPenType()
        
        if (isHighlighter && FTUserDefaults.isHoldToConvertToShapeOnForHighlighter()) ||
           (!isHighlighter && FTUserDefaults.isHoldToConvertToShapeOnForPen()) {
            return true
        }
        return false
    }

    private func toDrawStraightLineInFavoriteMode() -> Bool {
        guard self.currentDrawingMode == .deskModeFavorites || self.currentDrawingMode == .deskModeMarker else {
            return false
        }
        if FTUserDefaults.isDrawStraightLinesOn() && self.currentSelectedPenSet().type.isHighlighterPenType() {
            return true
        }
        return false
    }
    
    private func drawDetectedShape() -> (areaToRefresh:CGRect, hasShape:Bool, strokes: [FTStroke]?) {
        var hasShape = false;
        guard let curStroke = self.currentStroke?.stroke as? FTStroke else { return (CGRect.null,hasShape,nil) }

        let shapeDetector = FTShapeDetector.init(delegate: self);
        let strokes = shapeDetector.detectShape(for: curStroke, scale: self.scale)

        var rectToRefresh = curStroke.boundingRect
        if !strokes.isEmpty {
            hasShape = true;
            rectToRefresh = self.renderDetectedShapeStrokes(strokes, rectToRefresh: rectToRefresh)
        }
        return (rectToRefresh,hasShape, strokes)
    }
    private func renderDetectedShapeStrokes(_ strokes : [FTStroke],rectToRefresh : CGRect) -> CGRect{
        var rectToRefresh = rectToRefresh;
        strokes.forEach({ (stroke) in
            let shapeBoudingRect = stroke.renderingRect;
            rectToRefresh  = rectToRefresh.union(shapeBoudingRect);
            self.delegate?.addAnnotations([stroke],
                                          refreshView: false);
        });
        
        
        let refreshRect = CGRectScale(rectToRefresh, self.scale).integral;
        let properties = FTRenderingProperties();
        properties.renderImmediately = true;
        properties.synchronously = true;
        if refreshRect.size != CGSize.zero{
            properties.avoidOffscreenRefresh = true;
            self.cancelCurrentStroke()
            self.currentStroke = nil;
            self.delegate?.reloadTiles(forIntents: [.offScreen,.onScreen],
                                       rect: refreshRect,
                                       properties: properties);
        }
        return rectToRefresh
    }
    fileprivate func isShapeDetectionEnabled() -> Bool
    {
        return self.pageToDisplay?.parentDocument?.localMetadataCache?.shapeDetectionEnabled ?? false;
    }
    
    func currentSelectedPenSet() -> FTPenSetProtocol
    {
        if let penAttributesProvider = self.delegate?.penAttributesProvider {
            return penAttributesProvider.penAttributes();
        }
        let userActivity = self.view.window?.windowScene?.userActivity

        if(self.currentDrawingMode == .deskModeFavorites) {
            return FTFavoritePensetManager(activity: userActivity).fetchCurrentPenset()
        } else if self.currentDrawingMode == .deskModeMarker {
            return FTRackData(type: FTRackType.highlighter,userActivity: userActivity).getCurrentPenSet();
        } else if(self.currentDrawingMode == .deskModeShape) {
            return FTRackData(type: FTRackType.shape, userActivity: userActivity).getCurrentPenSet()
        } else {
            return FTRackData(type: FTRackType.pen,userActivity: userActivity).getCurrentPenSet();
        }
    }
}

//mark:- Eraser
extension FTOnScreenWritingViewController
{
    func performEraseAction(_ erasePoint: CGPoint, eraserSize: Int, touchPhase phase: UITouch.Phase) {
        switch phase {
        case .began:
            self.displayLink?.isPaused = false
            FTCLSLog("Erase Start")
            self.eraseInProgress = true;
            self.eraseOperationCancelled = false;
        case .moved:
            let eraserRect = CGRect(x: erasePoint.x - CGFloat(eraserSize)*0.5,
                                    y: erasePoint.y - CGFloat(eraserSize)*0.5,
                                    width: CGFloat(eraserSize),
                                    height: CGFloat(eraserSize));
            let eraseRectIn1x = CGRectScale(eraserRect,1/self.scale);
            
            guard !isEraseQueueInProgress else {
                accumulatedRects.append(eraseRectIn1x)
                return
            }
            accumulatedRects.append(eraseRectIn1x)
            isEraseQueueInProgress = true
            self.performErase(onCompletion:{ [weak self] (_) in
                self?.isEraseQueueInProgress = false
            })
        case .ended:
            FTCLSLog("Erase End")
            let eraserRect = CGRect(x: erasePoint.x - CGFloat(eraserSize)*0.5,
                                    y: erasePoint.y - CGFloat(eraserSize)*0.5,
                                    width: CGFloat(eraserSize),
                                    height: CGFloat(eraserSize));
            let eraseRectIn1x = CGRectScale(eraserRect,1/self.scale);
            accumulatedRects.append(eraseRectIn1x)
            self.displayLink?.isPaused = true
            self.performErase(onCompletion:{[weak self] (hasModifications) in
                self?.isEraseQueueInProgress = false
                self?.isEraseRenderInProgress = false
                self?.refreshViewForEraser()
                self?.eraseInProgress = false;

                guard let strongSelf = self else { return }
                var shouldPostNotification = false;
                let eraseFullStroke = FTUserDefaults.shouldEraseEntireStroke();
                if !strongSelf.annotationsToRemove.isEmpty {                    strongSelf.delegate?.removeAnnotations(strongSelf.annotationsToRemove, refreshView: false)
                    strongSelf.annotationsToRemove.removeAll()
                    shouldPostNotification = true;
                }
                
                let cacheCount = strongSelf.erasedSegmentCache.cacheItemCount();
                if(cacheCount > 0) {
                    shouldPostNotification = true;
                    (strongSelf.pageToDisplay as? FTPageUndoManagement)?.eraseStroke(segmentCache: strongSelf.erasedSegmentCache, isErased: true)
                    strongSelf.pageToDisplay?.isDirty = true;
                }
                 if shouldPostNotification {
                    strongSelf.clearEraseBuffer();
                 }	

                if(shouldPostNotification || hasModifications) {
                    var userInfo : [String : Any] = [String : Any]();
                    if let window = self?.view.window {
                        userInfo[FTRefreshWindowKey] = window;
                    }
                    NotificationCenter.default.post(name: NSNotification.Name.FTRefreshExternalView,
                                                    object: self?.pageToDisplay,
                                                    userInfo: userInfo);
                    NotificationCenter.default.post(name: NSNotification.Name.refreshPageNotification,
                                                    object: self?.pageToDisplay,
                                                    userInfo: userInfo);
                    if self?.delegate?.mode == FTRenderModeZoom {
                        let notification = Notification.init(name: Notification.Name.FTZoomRenderViewDidEndCurrentStroke,
                                                             object: self?.view.window,
                                                             userInfo: nil);
                        NotificationCenter.default.post(notification);
                    }
                }
                
                NotificationCenter.default.post(name: NSNotification.Name.init("FTDidEndEraserOperationNotification"), object: self);
            })
        case .cancelled:
            FTCLSLog("Erase Cancel")
            self.eraseOperationCancelled = true;
            self.cancelCurrentEraserOperation();
            self.eraseInProgress = false;
        default:
            break;
        }
    }
    
    private func cancelCurrentEraserOperation() {
        if !self.annotationsToRemove.isEmpty {
            DispatchQueue.main.async {
                self.annotationsToRemove.forEach({ (annotation) in
                    annotation.hidden = false
                })
                self.annotationsToRemove.removeAll()
            }
        }
       
        let eraseFullStroke = FTUserDefaults.shouldEraseEntireStroke();
        if !eraseFullStroke {
            self.erasedSegmentCache.reset()
        }
        
        if(!self.lastEraserOperationRect.isNull) {
            let properties = FTRenderingProperties();
            properties.renderImmediately = true;
            properties.avoidOffscreenRefresh = true;
            self.delegate?.reloadTiles(forIntents: [.offScreen,.onScreen],
                                       rect: CGRectScale(lastEraserOperationRect, self.scale),
                                       properties: properties);
        }
        self.eraserOperationLastRenderedRect = CGRect.null;
        self.clearEraseBuffer();
    }
    
    fileprivate func clearEraseBuffer()
    {
        self.erasedSegmentCache.clear();
        self.lastEraserOperationRect = CGRect.null;
    }
    
    private func performErase(onCompletion onComplete : ((Bool)->())?)
    {
        
        var hasModifications = false;
        let eraseFullStroke = FTUserDefaults.shouldEraseEntireStroke();
        let eraseHighlighterOnly = FTUserDefaults.shouldEraseHighlighterOnly()
        let erasePencilOnly = FTUserDefaults.shouldErasePencilOnly()

        let rectsToErase = accumulatedRects
        self.accumulatedRects.removeAll()
        self.eraserBackgroundQueue.async { [weak self] in
            guard let strongSelf = self, !strongSelf.eraseOperationCancelled, !rectsToErase.isEmpty else {
                DispatchQueue.main.async {
                    onComplete?(false);
                }
                return
            }
            if let tilesAffected = (strongSelf.pageToDisplay as? FTPageTileAnnotationMap)?.tileMappingRect(rectsToErase) {
                var annotations : Set<FTAnnotation> = Set<FTAnnotation>()
                tilesAffected.forEach({ (eachtile) in
                    annotations = annotations.union(eachtile.annotations)
                });
                
                
                //--Erase Highlighter or Pencil Only----//
                if(eraseHighlighterOnly || erasePencilOnly) {
                    annotations = annotations.filter({ (annotation) -> Bool in
                        var toErase: Bool = false
                        if let strokeAnnotation = annotation as? FTStrokeAnnotationProtocol {
                            if ((eraseHighlighterOnly && strokeAnnotation.penType.isHighlighterPenType()) || (erasePencilOnly && strokeAnnotation.penType == .pencil)){
                                toErase = true
                            }
                        }
                        return toErase
                    })
                }
                //-------------------------//
                annotations.forEach({ (annotation) in
                    if (eraseFullStroke) {
                        guard let stroke = annotation as? FTAnnotationErase else { return }
                        let strokeShouldErased = stroke.canErase(eraseRect: rectsToErase);
                        if strokeShouldErased && !annotation.hidden {
                            strongSelf.annotationsToRemove.append(annotation)
                            annotation.hidden = true;
                            strongSelf.lastEraserOperationRect = strongSelf.lastEraserOperationRect.union(annotation.renderingRect);
                            DispatchQueue.main.async {
                                strongSelf.eraserOperationLastRenderedRect = strongSelf.eraserOperationLastRenderedRect.union(annotation.renderingRect);
                            }
                            hasModifications = true;
                        }
                    } else {
                        if(strongSelf.erasedSegmentCache.cacheItemCount() == 0) {
                            strongSelf.lastEraserOperationRect = CGRect.null;
                        }
                        guard let stroke = annotation as? FTAnnotationStrokeErase else { return }
                        let erasedRect = stroke.eraseSegments(in: rectsToErase,
                                                              addTo: strongSelf.erasedSegmentCache);
                        if(!erasedRect.isNull) {
                            strongSelf.lastEraserOperationRect = strongSelf.lastEraserOperationRect.union(erasedRect);
                            DispatchQueue.main.async {
                                strongSelf.eraserOperationLastRenderedRect = strongSelf.eraserOperationLastRenderedRect.union(erasedRect);
                            }
                            hasModifications = true;
                        }
                    }
                })
            }
            
            //Sticky erase
            hasModifications = strongSelf.eraseStickiesIfRequired(in: rectsToErase)
            
            DispatchQueue.main.async {
                onComplete?(hasModifications);
            }
        }
    }
    
    //This can be optimized to per operation only basis.
    fileprivate func eraseStickiesIfRequired(in rects:[CGRect]) -> Bool {
        var hasModifications = false
        let eraseHighlighterOnly = FTUserDefaults.shouldEraseHighlighterOnly()
        let erasePencilOnly = FTUserDefaults.shouldErasePencilOnly()

        if(!eraseHighlighterOnly && !erasePencilOnly) {
            guard let annotations = self.pageToDisplay?.annotations() else {
                return false
            }
            
            var erasedRenderedRect = CGRect.null;
            
            for eachAnnotation in annotations where !(eachAnnotation is FTStrokeAnnotationProtocol) {
                if let annotation = eachAnnotation as? FTAnnotationErase,
                   !eachAnnotation.hidden,
                    annotation.canErase(eraseRect: rects) {
                    self.annotationsToRemove.append(eachAnnotation);
                    eachAnnotation.hidden = true	;
                    erasedRenderedRect = erasedRenderedRect.union(eachAnnotation.boundingRect);
                    hasModifications = true;
                }
            }
            
            if(!erasedRenderedRect.isNull) {
                DispatchQueue.main.async {
                    self.eraserOperationLastRenderedRect = self.eraserOperationLastRenderedRect.union(erasedRenderedRect);
                }
            }
        }
        return hasModifications
    }
}

extension FTOnScreenWritingViewController : FTShapeDetectorDelegate
{
    func addShapeSegment(for stroke: FTStroke!,
                         from startPoint: CGPoint,
                         to endPoint: CGPoint,
                         brushWidth penWidth: CGFloat,
                         opacity: CGFloat)
    {
        let ftpoint = CGPoint(x: min(startPoint.x,endPoint.x), y: min(startPoint.y,endPoint.y));
        let width = fabsf(Float(startPoint.x) - Float(endPoint.x));
        let height = fabsf(Float(startPoint.y) - Float(endPoint.y));
        let controlPointRect = CGRect(origin: ftpoint, size: CGSize(width: CGFloat(width), height: CGFloat(height)))
            .insetBy(dx: -penWidth*0.5, dy: -penWidth*0.5)
        stroke.boundingRect = stroke.boundingRect.union(controlPointRect)
        stroke.addSegment(startPoint: startPoint,
                          endPoint: endPoint,
                          thickness: penWidth,
                          opacity: opacity);
    }
    
    func trackShape(shapeName: String) {
        var eventName = "pen_shape_created"
        if self.currentDrawingMode == .deskModeShape {
             eventName = "shapes_shape_created"
        }
        track(eventName,params:["shape_type": shapeName])
    }
}

extension FTOnScreenWritingViewController : FTDocumentClosing
{
    func startProcessAndNotify(_ completionBlock: ((Bool) -> Void)!) {
        var operations = ["eraser"];
        
        let completionCallBack : (String)->() = { (refID) in
            if let index = operations.firstIndex(of: refID) {
                operations.remove(at: index);
            }
            if operations.isEmpty {
                completionBlock(true);
            }
        }
        self.stopEraserOperationAndNotifiy { (_, refID) in
            completionCallBack(refID);
        }
    }
    
    private func stopEraserOperationAndNotifiy(_ completionBlock : @escaping (Bool,String) -> ())
    {
        if(!self.eraseInProgress) {
            completionBlock(true,"eraser");
        }
        else {
            self.eraserBackgroundQueue.async {
                if(self.eraseInProgress) {
                    self.eraserStopObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name("FTDidEndEraserOperationNotification"),
                                                                                     object: self,
                                                                                     queue: OperationQueue.main,
                                                                                     using:
                                                                                        { [weak self] (_) in
                        if let strongSelf = self?.eraserStopObserver {
                            NotificationCenter.default.removeObserver(strongSelf);
                        }
                        completionBlock(true,"eraser");
                    });
                }
                else {
                    DispatchQueue.main.async {
                        completionBlock(true,"eraser");
                    }
                }
            }
        }
    }
}

extension FTOnScreenWritingViewController
{
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.currentDrawingMode != .deskModeClipboard {
            FTStylusPenManager.sharedInstance().processTouchesBegan(touches, event: event, view: self.view);
        }
        (self.delegate as? FTTouchEventsHandling)?.processTouchesBegan(touches, with: event);
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.currentDrawingMode != .deskModeClipboard {
            FTStylusPenManager.sharedInstance().processTouchesMoved(touches, event: event, view: self.view);
        }
        (self.delegate as? FTTouchEventsHandling)?.processTouchesMoved(touches, with: event);
        super.touchesMoved(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.currentDrawingMode != .deskModeClipboard {
            FTStylusPenManager.sharedInstance().processTouchesEnded(touches, event: event, view: self.view);
            if let view = touches.first?.view, let touchEvents = event?.touches(for: view) {
                if(touchEvents.count == touches.count) {
                    self.scheduleDelayedEnableGesture();
                }
            }
        }
        (self.delegate as? FTTouchEventsHandling)?.processTouchesEnded(touches, with: event);
        super.touchesEnded(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.currentDrawingMode != .deskModeClipboard {
            FTStylusPenManager.sharedInstance().processTouchesCancelled(touches, event: event, view: self.view);
        }
        (self.delegate as? FTTouchEventsHandling)?.processTouchesCancelled(touches, with: event);
        super.touchesCancelled(touches, with: event)
    }
}

extension FTOnScreenWritingViewController
{
    @objc func delayedEnableGesture()
    {
        NotificationCenter.default.post(name: NSNotification.Name.init(FTPDFEnableGestures), object: self.view.window);
    }
    
    func scheduleDelayedEnableGesture()
    {
        self.perform(#selector(delayedEnableGesture),
                     with: nil,
                     afterDelay: 0.2);
        self.scheduleDelayedEnablePDFSelectionGesture();
    }
    
    func cancelDelayedEnableGesture()
    {
        NSObject.cancelPreviousPerformRequests(withTarget: self,
                                               selector: #selector(delayedEnableGesture),
                                               object: nil);
        cancelDelayedEnablePDFSelectionGesture();
    }
    
    @objc func delayedDisableLongPressGesture()
    {
        NotificationCenter.default.post(name: NSNotification.Name.init("FTDisableLongPressGestureNotification"), object: self.view.window);
    }
    
    func cancelDisableLongPressGesture()
    {
        NSObject.cancelPreviousPerformRequests(withTarget: self,
                                               selector: #selector(delayedDisableLongPressGesture),
                                               object: nil);
    }
    
    func scheduleDisableLongPressGesture()
    {
        self.perform(#selector(delayedDisableLongPressGesture),
                     with: nil,
                     afterDelay: 0.5);
    }

    func cancelDelayedEnablePDFSelectionGesture() {
        NSObject.cancelPreviousPerformRequests(withTarget: self,
                                               selector: #selector(enablePDFSelectionGesture),
                                               object: nil);
    }

    func scheduleDelayedEnablePDFSelectionGesture()
    {
        self.perform(#selector(enablePDFSelectionGesture),
                     with: nil,
                     afterDelay: 0.5);
    }

    @objc func enablePDFSelectionGesture()
    {
        self.pdfSelectionView?.allowsSelection = true;
    }
}

//MARK:-  
extension FTOnScreenWritingViewController {
    func addObserverForOnScreenRendererReleaseNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(releaseOnScreenRendererIfNeeded(_:)), name: UIApplication.releaseOnScreenRendererIfNeeded, object: nil)
    }
    
    @objc func releaseOnScreenRendererIfNeeded(_ notification: Notification) {
        if self.view.window?.isInBackgroundState() == true {
            FTRendererProvider.shared.enqueOnscreenRenderer(_onScreenRenderer);
            _onScreenRenderer = nil;
        }
    }
}

extension FTOnScreenWritingViewController: FTRendererDelegate {
    func renderer(inRect rect: CGRect) -> [FTOnScreenRenderer] {
        if let renderer = self.currentRenderer {
            return [renderer]
        }
        return []
    }
}

extension FTOnScreenWritingViewController: FTPDFSelectionViewDelegate {
    
    func pdfSelectionView(_ view: FTPDFSelectionView,
                          didTapOnAction action: FTPDFSelectionAction,
                          lineRects rects: [CGRect]) {
        guard let page = self.pageToDisplay else {
            return;
        }
        let onebyscale = 1/self.scale;
        var strokes = [FTStroke]();
        
        var rectToRefresh = CGRect.null;
        
        let isVertical = self.pageToDisplay?.isVerticalLayout() ?? false;
        rects.forEach { eachRect in
            let _rect = CGRectScale(eachRect, onebyscale);
            
            let startPoint: CGPoint;
            let endPoint: CGPoint;
            let thickness: CGFloat;
            
            if !isVertical {
                startPoint = CGPoint(x: _rect.minX, y: _rect.midY);
                endPoint = CGPoint(x: _rect.maxX, y: _rect.midY);
                thickness = _rect.height;
            }
            else {
                startPoint = CGPoint(x: _rect.midX, y: _rect.minY);
                endPoint = CGPoint(x: _rect.midX, y: _rect.maxY);
                thickness = _rect.width;
            }
                     
            let penSet  = action.penSet(self.view.window?.windowScene?.userActivity,thickness: thickness);
            let stroke = FTStroke.init(withPage: page);
            stroke.boundingRect = _rect;
            stroke.strokeColor = UIColor(hexString: penSet.color)
            stroke.strokeWidth = CGFloat(penSet.size.rawValue);
            stroke.penType = penSet.type.penType();

            let segWidth: CGFloat;
            if action == .strikeOut {
                let attributes = FTBrushBuilder.penAttributesFor(penType: penSet.type,
                                                                 brushWidth: stroke.strokeWidth,
                                                                 isShapeTool: true,
                                                                 version: FTStroke.defaultAnnotationVersion());
                segWidth = attributes.brushWidth;
            }
            else {
                segWidth = thickness;
            }
            let shapePoints = FTShapeUtility.points(inLine: startPoint, end: endPoint);
            for (idx,obj) in shapePoints.enumerated() where idx > 0 {
                let startPoint = shapePoints[idx - 1]
                let endPoint = obj
                self.addShapeSegment(for: stroke,
                                     from: startPoint,
                                     to: endPoint,
                                     brushWidth: segWidth,
                                     opacity: 1.0);
            }
            strokes.append(stroke);
            rectToRefresh = rectToRefresh.union(stroke.renderingRect)
        }
        self.delegate?.addAnnotations(strokes, refreshView: true);

        let properties = FTRenderingProperties();
        properties.avoidOffscreenRefresh = true;
        self.delegate?.reloadTiles(forIntents: [.offScreen],
                                   rect: CGRectScale(rectToRefresh, self.scale).integral,
                                   properties: properties);
        
        if let del = self.delegate, del.mode == FTRenderModeZoom {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
                let notification = Notification.init(name: Notification.Name.FTZoomRenderViewDidEndCurrentStroke,
                                                     object: self.view.window,
                                                     userInfo: [FTImpactedRectKey : NSValue.init(cgRect: rectToRefresh)]);
                NotificationCenter.default.post(notification);
            }
        }


    }
    
    func pdfSelectionViewDisableGestures(_ view: FTPDFSelectionView) {
        NotificationCenter.default.post(name: NSNotification.Name.init(FTPDFDisableGestures), object: self.view.window);
        self.cancelDelayedEnableGesture();
        self.scheduleDelayedEnableGesture()
    }
    
    func pdfInteractionShouldBegin(at point: CGPoint) -> Bool {
        if self.delegate?.mode == FTRenderModeZoom {
            return false;
        }
        return (self.delegate as? FTTextInteractionDelegate)?.pdfInteractionShouldBegin?(at: point) ?? true;
    }
    
    func requiredTapGestureToFail() -> UITapGestureRecognizer? {
        return (self.delegate as? FTWritingViewController)?.requiredTapGestureToFail()
    }

    func pdfInteractionWillBegin() {
        (self.delegate as? FTTextInteractionDelegate)?.pdfInteractionWillBegin?();
    }
    
    func pdfSelectionView(_ view: FTPDFSelectionView, performAIAction selectedString: String) {
        (self.delegate as? FTTextInteractionDelegate)?.pdfSelectionView?(view, performAIAction: selectedString);
    }
}

#if targetEnvironment(macCatalyst)
extension FTOnScreenWritingViewController: FTPDFSelectionViewContextMenuDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        if let del = self.delegate as? FTPDFSelectionViewContextMenuDelegate {
            return del.contextMenuInteraction(interaction, configurationForMenuAtLocation: location)
        }
        return nil
    }
}
#endif
