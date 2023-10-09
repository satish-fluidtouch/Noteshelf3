//
//  FTWritingViewController.swift
//  Noteshelf
//
//  Created by Amar on 21/12/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

extension Notification.Name {
    static let didCompleteRenderingNotification = Notification.Name(rawValue: "didCompleteRenderingNotification")
}

@objc protocol FTPageContentDelegate : NSObjectProtocol {
    func showZoomPanelIfNeeded();
    func change(mode : RKDeskMode);
    func isInZoomMode() -> Bool;
    func setUserInteraction(enable : Bool);
    func currentDeskMode() -> RKDeskMode;
    func setToPreviousTool();
}

@objc protocol FTPageAnnotationHandler : NSObjectProtocol
{
    func removeAnnotations(_ annotations : [FTAnnotation], refreshView shouldRefresh:Bool)
    func addAnnotations(_ annotations : [FTAnnotation], refreshView shouldRefresh:Bool);
    func moveAnnotationsToFront(_ annotations : [FTAnnotation], shouldRefresh:Bool)
    func moveAnnotationsToBack(_ annotations : [FTAnnotation], shouldRefresh:Bool)
    func addShapeAnnotation()
    func activeController() -> UIViewController?
}

protocol FTEraseTouchHandling : AnyObject {
    func eraserTouchesBegan(_ touch : FTTouch);
    func eraserTouchesMoved(_ touch : FTTouch);
    func eraserTouchesEnded(_ touch : FTTouch);
    func eraserTouchesCancelled(_ touch : FTTouch);
}

protocol FTTouchEventsHandling : AnyObject {
    func processTouchesBegan(_ touches: Set<UITouch>, with event: UIEvent?);
    func processTouchesMoved(_ touches: Set<UITouch>, with event: UIEvent?);
    func processTouchesEnded(_ touches: Set<UITouch>, with event: UIEvent?);
    func processTouchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?);
}

protocol FTContentDelegate : FTPageAnnotationHandler {
    var contentScale : CGFloat {get};
    var contentSize : CGSize {get};

    var backgroundTexture : MTLTexture? {get};
    var backgroundTextureTileContent : FTBackgroundTextureTileContent? {get};
    var pageToDisplay : FTPageProtocol? {get};

    var penAttributesProvider : FTPenAttributesProviderDelegate? {get};
    var currentDrawingMode : RKDeskMode {get};
    var mode : FTRenderMode {get};

    var isIntroScreen : Bool {get};
    
    func reloadTiles(forIntents intents:[FTRendererIntent],rect : CGRect,properties : FTRenderingProperties);
    func addShapeAnnotation()
    func activeController()-> UIViewController?
}

//MARK:- FTWritingViewController
class FTWritingViewController: UIViewController,FTViewControllerSupportsScene {
    private var backImagegenInProgress = false;
    private var shouldRegenBgImage = false;

    var addedObserverOnScene: Bool = false;
    weak var penAttributesProvider: FTPenAttributesProviderDelegate?
    
    fileprivate weak var offscreenTileViewController : FTOffscreenWritingViewController?;
    private(set) weak var onscreenViewController : FTOnScreenWritingViewController?;
    weak var laserPresenterController: FTLaserPresentationViewController?;

    @objc weak var scrollView : FTPDFScrollView?;

    var loadingFirstTime : Bool = true;
    fileprivate var _backgroundTexture : FTBackgroundTexture = FTBackgroundTexture();
    fileprivate var renderingInProgress = false;

    fileprivate var shouldUpdateBackgorundImage = false;
    var mode : FTRenderMode = FTRenderModeDefault;

    var isIntroScreen : Bool = false;

    @objc var orientationChanging = false {
        didSet{
            if(self.orientationChanging) {
                self.onscreenViewController?.endCurrentStroke();
            }
        }
    };
    
    //zoomscale - scaled wrt to scrollview i.e from minZoom to maxzoom scale of scrollview
    var zoomScale : CGFloat = 1 {
        didSet {
            self._backgroundTexture.scale = zoomScale;
        }
    };
    var isZooming = false;
    var contentScale : CGFloat = 1;
    var pdfInitialScale : CGFloat = 1;
    
    var contentSize : CGSize = CGSize.zero;
    
    internal var lassoImageView : UIImageView?
    internal var lassoViewPreparationIsInProgress : Bool = false;
    internal var lassoViewShouldPrepareView = true;
    internal let lassoQueue : DispatchQueue = DispatchQueue.init(label: "com.lasso.execution");

    fileprivate var refreshRectWhileTextureGen : CGRect = CGRect.zero;
    fileprivate var refreshIntentsWhileTextureGen : [FTRendererIntent] = [FTRendererIntent]();
    fileprivate var refreshRenderingPropertiesWhileTextureGen : FTRenderingProperties = FTRenderingProperties();
    
    fileprivate lazy var eraseTouchHandler = FTPageEraseTouchHandler(dataSource: self);
    fileprivate var viewFrameObservation : NSKeyValueObservation?

    private var shouldPauseRendering: Bool = false

    private weak var pageUpdatePropertyObserver: NSObjectProtocol?;
    private weak var pageReleasedObserver: NSObjectProtocol?;
    
    weak var pageToDisplay : FTPageProtocol? {
        didSet {
            if(oldValue?.uuid != self.pageToDisplay?.uuid) {
                self.reset(self.mode != FTRenderModeDefault);
                self.shouldUpdateBackgorundImage = true;
                self.addNotificationObservers(self.pageToDisplay);
                self.onscreenViewController?.pageToDisplay = self.pageToDisplay;
            }
        }
        willSet {
            if(newValue?.uuid != self.pageToDisplay?.uuid) {
                self.removeNotificationObservers(self.pageToDisplay);
            }
        }
    }

    @objc weak var pageContentDelegate : (FTPageContentDelegate & FTPageAnnotationHandler)? {
        didSet {
            if !(oldValue?.isEqual(self.pageContentDelegate) ?? false) {
                if let del = self.pageContentDelegate {
                    self.currentDrawingMode = del.currentDeskMode();
                    del.change(mode: self.currentDrawingMode);
                }
            }
        }
    };
    
    var currentDrawingMode : RKDeskMode {
        get {
            return self.pageContentDelegate?.currentDeskMode() ?? .deskModeView
        }
        set {
            self.onscreenViewController?.didChangeDeskMode(newValue);
            self.eraseTouchHandler.finalizeEraseAction();
            self.onscreenViewController?.cancelCurrentStroke();
            if newValue == .deskModeLaser {
                self.addLaserPresentationController();
            }
            else {
                self.removeLaserPresentationController();
            }
        }
    };

    override func loadView() {
        let view = UIView.init(frame: UIScreen.main.bounds);
        view.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth,UIView.AutoresizingMask.flexibleHeight];
        self.view = view;
    }
    
    deinit {
        self.offscreenTileViewController?.removeFromParent();
        self.offscreenTileViewController?.view.removeFromSuperview();
        self.offscreenTileViewController?.willMove(toParent: nil);

        self.removeOnScreenViewController();
        self.viewFrameObservation?.invalidate();
        self.viewFrameObservation = nil;

        NotificationCenter.default.removeObserver(self);
        self.removeNotificationObservers(self.pageToDisplay);
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let offscreenController = FTOffscreenWritingViewController.viewController(delegate: self);
        self.offscreenTileViewController = offscreenController;
        self.addChild(offscreenController);
        offscreenController.view.frame = self.view.bounds;
        self.view.addSubview(offscreenController.view);
        offscreenController.didMove(toParent: self);

        viewFrameObservation = self.observe(\.self.view.frame, options: .new) { (selfObject, value) in
            selfObject.contentSize = value.newValue?.size ?? selfObject.view.frame.size;
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
        self.configureSceneNotifications();
    }

    private func resumeOperations() {
        if let scrollView = self.scrollView,self.renderingInProgress {
            let properties = FTRenderingProperties();
            properties.renderImmediately = true;
            properties.pageID = self.pageToDisplay?.uuid;
            self.loadTiles(inRect: scrollView.visibleRect(), properties: properties);
        }
    }

    var isCurrentPage : Bool = false {
        didSet {
            if(oldValue != self.isCurrentPage) {
                if(self.isCurrentPage) {
                    if(self.mode != FTRenderModeDefault || !self.isInZoomMode()) {
                        self.pageContentDelegate?.setUserInteraction(enable: false);
                    }
                    if(self.mode == FTRenderModeDefault && !self.isInZoomMode()) {
                        self.addOnScreenViewController();
                    }
                    else if(self.mode == FTRenderModeZoom) {
                        self.addOnScreenViewController();
                    }
                    if(self.mode == FTRenderModeDefault) {
                        NotificationCenter.default.addObserver(forName: Notification.Name.FTZoomRenderViewDidEndCurrentStroke,
                                                               object: nil,
                                                               queue: nil)
                        { [weak self] (notification) in
                            guard notification.isSameSceneWindow(for: self?.view.window) else {
                                return;
                            }
                            if let weakSelf = self, let scrollView = self?.scrollView {
                                var impactedRect = scrollView.visibleRect();
                                if let rectToRefresh = notification.userInfo?[FTImpactedRectKey] as? NSValue {
                                    impactedRect = CGRectScale(rectToRefresh.cgRectValue, weakSelf.scale);
                                }
                                let renderPropeties = FTRenderingProperties();
                                renderPropeties.pageID = weakSelf.pageToDisplay?.uuid;
                                weakSelf.reloadTiles(in: impactedRect, properties: renderPropeties);
                            }
                        }
                    }
                }
                else {
                    self.removeOnScreenViewController();
                    NotificationCenter.default.removeObserver(self, name: Notification.Name.FTZoomRenderViewDidEndCurrentStroke, object: nil);
                }
            }
        }
    }
}

extension FTWritingViewController :  FTWritingProtocol
{
    var scale: CGFloat {
        get {
            return self.contentScale;
        }
        set {
            self.contentScale = newValue;
        }
    }
    
    var zooming: Bool {
        get {
            return isZooming;
        }
        set {
            isZooming = newValue;
        }
    }
    
    func didEndZooming(_ scale: CGFloat) {
        self.onscreenViewController?.hideWritingView()
        self.onscreenViewController?.presentsWithTransaction = true;
        self.reset(false);
        self.zoomScale = scale;
        self.perform(#selector(self.updateLowResolutionImageBackgroundView),
                     with: nil,
                     afterDelay: 0.001);
    }
    
    func willBeginZooming() {
        self.updateLowResolutionImageBackgroundView();
    }
    
    func cancelCurrentStroke() {
        self.onscreenViewController?.cancelCurrentStroke();
        self.cancelCurrentLaserStroke();
    }
    
    func performEraseAction(_ erasePoint: CGPoint, eraserSize: Int, touchPhase phase: UITouch.Phase) {
        self.onscreenViewController?.performEraseAction(erasePoint, eraserSize: eraserSize, touchPhase: phase);
    }
    
    @objc func reloadTiles(in rect: CGRect, presentImmediately: Bool, properties: FTRenderingProperties!) {
        properties.renderImmediately = presentImmediately;
        self.reloadTiles(in: rect, properties: properties);
    }
    
    var bounds: CGRect {
        get {
            return self.view.bounds;
        }
        set {
            self.view.bounds = newValue;
        }
    }
    
    func registerViewForTouchEvents() {
        if let writingView = self.onscreenViewController?.view {
            FTStylusPenManager.sharedInstance()?.register(writingView, delegate: self.onscreenViewController);
        }
    }
    func unregisterView(forTouchEvents setToDefault: Bool) {
        if let writingView = self.onscreenViewController?.view {
            FTStylusPenManager.sharedInstance()?.unregisterView(writingView, setToDefault: setToDefault);
        }
    }

    func reset(_ forcibly: Bool)
    {
        if let page = self.pageToDisplay,!page.templateInfo.isImageTemplate || forcibly {
            self._backgroundTexture.resetForCurrentScale(self.zoomScale, forceReset: forcibly);
        }
        if(self.isCurrentPage &&
            self.mode == FTRenderModeDefault &&
            !self.isInZoomMode()) {
            self.pageContentDelegate?.setUserInteraction(enable: false);
        }
        self.offscreenTileViewController?.reloadTiles();
    }
    
    @objc func reloadTiles(in rect : CGRect,properties : FTRenderingProperties) {
        guard let pageToDisplay = self.pageToDisplay else {
            return;
        }
        if let pageID = properties.pageID, pageID != pageToDisplay.uuid {
            return;
        }
        self.offscreenTileViewController?.markTilesAsDirty(inRect: rect);
        self.loadTiles(inRect: rect, properties: properties);
    }
    
    func releaseTilesNot(in rect : CGRect,extraTilesCount : Int)
    {
        self.offscreenTileViewController?.releaseTilesNot(in: rect, extraTilesCount: extraTilesCount);
    }
    
    func removeTilesMarkedAsShouldRemove()
    {
        self.offscreenTileViewController?.removeTilesMarkedAsShouldRemove();
    }

    @objc func loadTiles(inRect rect : CGRect,properties : FTRenderingProperties) {
        self.loadTiles(inRect: rect,
                       intents: [FTRendererIntent.onScreen,
                                 FTRendererIntent.offScreen,
                                 .presentation],
                       properties: properties);
    }
        
    func waitUntilComplete() {
        if(self.mode == FTRenderModeDefault && self.isCurrentPage) {
            self.onscreenViewController?.waitUntilComplete();
        }
    }
    
    func willEnterZoomMode() {
        if(isCurrentPage) {
            self.removeOnScreenViewController();
            if let scrollView = self.scrollView {
                let properties = FTRenderingProperties();
                properties.cancelPrevious = true;
                properties.renderImmediately = true;
                properties.pageID = self.pageToDisplay?.uuid;
                self.loadTiles(inRect: scrollView.visibleRect(),
                               intents: [FTRendererIntent.onScreen], properties: properties);
            }
        }
    }
    
    func didExitZoomMode() {
        if(isCurrentPage) {
            self.addOnScreenViewController();
            if let scrollView = self.scrollView {
                let properties = FTRenderingProperties();
                properties.cancelPrevious = true;
                properties.renderImmediately = true;
                properties.pageID = self.pageToDisplay?.uuid;
                self.loadTiles(inRect: scrollView.visibleRect(),
                               intents: [FTRendererIntent.onScreen], properties: properties);
            }
        }
    }
    
    func updateLowResolutionImageBackgroundView()
    {
        if(self.shouldUpdateBackgorundImage) {
            NSObject.cancelPreviousPerformRequests(withTarget: self,
                                                   selector: #selector(self.updateBackgroundImage(_:)),
                                                   object: nil);
            self.updateBackgroundImage(nil);
        }
    }

    func isPDFTextSelected() -> Bool {
        if let onscreen = self.onscreenViewController,
           let range = onscreen.selectedTextRange,
           !range.isEmpty {
            return true;
        }
        return false;
    }
    
    var selectedTextRange: UITextRange? {
        set {
            self.onscreenViewController?.selectedTextRange = newValue;
        }
        get {
            return self.onscreenViewController?.selectedTextRange;
        }
    }
    
    func selectedPDFString() -> String? {
        if isPDFTextSelected() {
            return self.onscreenViewController?.selectedText;
        }
        return nil;
    }
}

private extension FTWritingViewController
{
    func _reloadTiles(inRect: CGRect, intents:[FTRendererIntent], properties : FTRenderingProperties)
    {

        let rect = inRect.intersection(self.scrollView?.visibleRect() ?? inRect)
        if nil != self.pageToDisplay {
            if(self.mode == FTRenderModeDefault) {
                if(!self.isCurrentPage || self.isCurrentPage && self.isInZoomMode()) {
                    self.offscreenTileViewController?.renderTiles(inRect: rect,properties: properties);
                    self.renderingInProgress = false;
//                    NotificationCenter.default.post(name: .didCompleteRenderingNotification, object: nil)
                    return;
                }
            }
            else if(self.mode == FTRenderModeExternalScreen) {
                self.offscreenTileViewController?.renderTiles(inRect: rect,properties: properties);
                return;
            }
            
            if(intents.contains(FTRendererIntent.offScreen)) {
                self.offscreenTileViewController?.renderTiles(inRect: rect,properties: properties);
            }
            if intents.contains(FTRendererIntent.onScreen),
                let scrollView = self.scrollView,
                let metalViewController = self.onscreenViewController {
                if(!self.isZooming && !(self.scrollView?.isScrolling ?? true)) {
                    let isCurrentStrokeInProgress = (metalViewController.currentStroke == nil) ? false : true;
                    let frame = scrollView.visibleRect();
                    metalViewController.setVisibleRect(frame);
                    if((!self.orientationChanging && !isCurrentStrokeInProgress) || properties.forcibly) {
                        self.onscreenViewController?.renderTiles(inRect: rect,
                                                                 properties: properties,
                                                                 onCompletion:
                            { [weak self] (success) in
                                self?.renderingInProgress = false;
                                if(success) {
                                    DispatchQueue.main.async { [weak self] in
                                        self?.updateCurrentPageProperties();
                                        NotificationCenter.default.post(name: .didCompleteRenderingNotification, object: nil)
                                    }
                                }
                        });
                    }
                }
            }
            if intents.contains(.presentation) && !self.orientationChanging {
                self.reloadLaserView(rect: rect, properties: properties);
            }
        }
    }
    
    func loadTiles(inRect : CGRect, intents:[FTRendererIntent], properties : FTRenderingProperties) {

        guard let pageToDisplay = self.pageToDisplay else {
            return;
        }
        if let pageID = properties.pageID, pageID != pageToDisplay.uuid {
            return;
        }
        
        let rectToRefresh = inRect.intersection(self.scrollView?.visibleRect() ?? inRect);
        self.renderingInProgress = true;
        if(shouldPauseRendering) {
            if(self.mode == FTRenderModeDefault && self.isCurrentPage && !self.isInZoomMode()) {
                self.onscreenViewController?.hideWritingView();
            }
            return;
        }

        if(FTRenderConstants.USE_BG_TILING) {
            let targetRect = self.view.bounds;
            let textureContent = pageToDisplay.backgroundTextureTiles(scale: self.scale, targetRect: targetRect, visibleRect: rectToRefresh);
            self._backgroundTexture.backgroundTextureTileContent = textureContent;
            self._reloadTiles(inRect: rectToRefresh, intents: intents, properties: properties);
        } else {
            if(nil == self._backgroundTexture.texture) {
                var asynchronous = self.loadingFirstTime;
                if(self.mode == FTRenderModeDefault) {
                    if(!self.isCurrentPage || (self.isInZoomMode())) {
                        asynchronous = true;
                    }
                }
                else if(self.mode == FTRenderModeExternalScreen){
                    asynchronous = true;
                }
                self.refreshRectWhileTextureGen = rectToRefresh;
                self.refreshIntentsWhileTextureGen = intents;
                self.refreshRenderingPropertiesWhileTextureGen = properties;

                if(!_backgroundTexture.isBackgroundTextureGenInProgress) {
                    _backgroundTexture.isBackgroundTextureGenInProgress = true;
                    self.loadBackgroundTexture(asynchronously: asynchronous) {[weak self] (texture) in
                        self?._backgroundTexture.isBackgroundTextureGenInProgress = false;
                        self?._backgroundTexture.texture = texture;
                        self?.loadingFirstTime = false;
                        if let strongSelf = self {
                            self?._reloadTiles(inRect: strongSelf.refreshRectWhileTextureGen,
                                               intents: strongSelf.refreshIntentsWhileTextureGen,
                                               properties: strongSelf.refreshRenderingPropertiesWhileTextureGen);
                        }
                    }
                }
            } else {
                self._reloadTiles(inRect: rectToRefresh, intents: intents, properties: properties);
            }
        }
    }
    
    func addOnScreenViewController()
    {
        let onScreenController = FTOnScreenWritingViewController.viewController(delegate: self);
        onScreenController.view.frame = self.view.bounds;
        self.view.addSubview(onScreenController.view);
        self.addChild(onScreenController);
        onScreenController.didMove(toParent: self);
        if let scrollViewRect = self.scrollView?.visibleRect() {
            onScreenController.setVisibleRect(scrollViewRect);
        }
        self.onscreenViewController = onScreenController;
        self.registerViewForTouchEvents();
    
        if self.currentDrawingMode == .deskModeLaser {
            self.addLaserPresentationController();
        }
        onScreenController.pageToDisplay = self.pageToDisplay;
    }
    
    func removeOnScreenViewController()
    {
        self.unregisterView(forTouchEvents: false);
        self.onscreenViewController?.view.removeFromSuperview();
        self.onscreenViewController?.removeFromParent();
        self.onscreenViewController?.willMove(toParent: nil);
        self.removeLaserPresentationController()
    }
    
    func loadBackgroundTexture(asynchronously : Bool,
                               onCompletion : @escaping (MTLTexture?)->())
    {
        guard let pageToRead = self.pageToDisplay else {
            onCompletion(nil)
            return
        }
        
        let targetRect = self.view.bounds;
        if asynchronously {
            pageToRead.backgroundTexture(toFitIn: targetRect) { (texture) in
                DispatchQueue.main.async {
                    onCompletion(texture);
                }
            };
        }
        else {
            let texture = pageToRead.backgroundTexture(toFitIn: targetRect);
            onCompletion(texture);
        }
    }
    
    func updateCurrentPageProperties()
    {
        self.pageContentDelegate?.setUserInteraction(enable: true);
        
//        if(self.mode == FTRenderModeDefault) {
//            self.pageContentDelegate?.showZoomPanelIfNeeded();
//        }
    }
}

//MARK:- Notification Add/Remove
private extension FTWritingViewController
{
    func addNotificationObservers(_ page : FTPageProtocol?)
    {
        if(nil != page) {
            self.pageUpdatePropertyObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue:FTPageDidUpdatedPropertiesNotification),
                                                                                     object: page,
                                                                                     queue: nil) { [weak self] (_) in
                if let selfObject = self, selfObject.isCurrentPage {
                    self?.shouldUpdateBackgorundImage = true;
                }
            }
            
            NotificationCenter.default.addObserver(forName: NSNotification.Name.FTPageDidChangePageTemplate,
                                                   object: page,
                                                   queue: nil) { [weak self] (_) in
                if let selfObject = self, selfObject.isCurrentPage {
                    self?.shouldUpdateBackgorundImage = true;
                }
            }
            
            self.pageReleasedObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue:FTPageDidGetReleasedNotification),
                                                                               object: page,
                                                                               queue: nil) { [weak self] (note) in
                if let pageObject = note.object as? FTPageProtocol {
                    self?.removeNotificationObservers(pageObject);
                }
            }
        }
    }
    
    func removeNotificationObservers(_ page : FTPageProtocol?)
    {
        if let _observer = self.pageUpdatePropertyObserver {
            NotificationCenter.default.removeObserver(_observer);
            self.pageUpdatePropertyObserver = nil;
        }
        if let _observer = self.pageReleasedObserver {
            NotificationCenter.default.removeObserver(_observer);
            self.pageReleasedObserver = nil;
        }
    }

    @objc func updateBackgroundImage(_ sender : Any?)
    {
        if(self.mode == FTRenderModeExternalScreen || !self.isCurrentPage || !self._backgroundTexture.loadedBackground) {
            return;
        }
        self.shouldUpdateBackgorundImage = false;
        guard let pageToRead = self.pageToDisplay else { return }

        if(backImagegenInProgress) {
            shouldRegenBgImage = true;
            return;
        }
        backImagegenInProgress = true;
        let pageRectSize = pageToRead.pdfPageRect.size;
        let viewFrame = UIScreen.main.bounds.size;
        let textureSize = CGSize.aspectFittedSize(pageRectSize, max: viewFrame);
        let pageID = pageToRead.uuid
        FTPDFExportView.snapshot(forPage: pageToRead, size: textureSize, screenScale: UIScreen.main.scale, offscreenRenderer: nil, purpose: FTSnapshotPurposeDefault, windowHash: self.view.window?.hash) {[weak self] image, page in
            runInMainThread { [weak self] in
                if let pageUUID = page?.uuid, pageUUID == pageID,let thumbImage = image {
                    let indexView = self?.scrollView?.pageIndexView;
                    indexView?.image = thumbImage;
                }
                self?.backImagegenInProgress = false;
                if(self?.shouldRegenBgImage ?? false) {
                    self?.shouldRegenBgImage = false;
                    self?.updateBackgroundImage(nil);
                }
            }
        }
    }
}

extension FTWritingViewController : FTContentDelegate
{
    var backgroundTextureTileContent: FTBackgroundTextureTileContent? {
        return self._backgroundTexture.backgroundTextureTileContent
    }
    
    func addShapeAnnotation() {
        self.pageContentDelegate!.addShapeAnnotation()
    }
    
    func activeController()-> UIViewController? {
        return self.pageContentDelegate!.activeController()
    }

    var backgroundTexture: MTLTexture? {
        return self._backgroundTexture.texture;
    }
    
    func reloadTiles(forIntents intents: [FTRendererIntent], rect: CGRect, properties: FTRenderingProperties) {
        guard let pageToDisplay = self.pageToDisplay else {
            return;
        }
        if let pageID = properties.pageID, pageID != pageToDisplay.uuid {
            return;
        }
        if(intents.contains(FTRendererIntent.offScreen)) {
            self.offscreenTileViewController?.markTilesAsDirty(inRect: rect);
        }
        if intents.contains(.onScreen) || intents.contains(.offScreen) {
            self.loadTiles(inRect: rect, intents: intents, properties: properties);
        }
    }
    
    func isInZoomMode() -> Bool {
        return self.pageContentDelegate?.isInZoomMode() ?? false;
    }
}

extension FTWritingViewController : FTPageAnnotationHandler
{
    func moveAnnotationsToFront(_ annotations: [FTAnnotation], shouldRefresh: Bool) {
        self.pageContentDelegate?.addAnnotations(annotations,
                                                 refreshView: shouldRefresh);

    }

    func moveAnnotationsToBack(_ annotations: [FTAnnotation], shouldRefresh: Bool) {
        self.pageContentDelegate?.addAnnotations(annotations,
                                                 refreshView: shouldRefresh);

    }

    func addAnnotations(_ annotations : [FTAnnotation],refreshView shouldRefresh:Bool) {
        self.pageContentDelegate?.addAnnotations(annotations,
                                                 refreshView: shouldRefresh);
    }

    func removeAnnotations(_ annotations: [FTAnnotation], refreshView shouldRefresh: Bool) {
        self.pageContentDelegate?.removeAnnotations(annotations, refreshView: shouldRefresh)
    }
}

extension FTWritingViewController : FTEraseTouchHandling
{
    func eraserTouchesBegan(_ touch: FTTouch) {
        self.eraseTouchHandler.eraserTouchesBegan(touch);
    }
    
    func eraserTouchesEnded(_ touch: FTTouch) {
        self.eraseTouchHandler.eraserTouchesEnded(touch);
        self.pageContentDelegate?.setToPreviousTool();
    }
    
    func eraserTouchesCancelled(_ touch: FTTouch) {
        self.eraseTouchHandler.eraserTouchesCancelled(touch);
    }
    
    func eraserTouchesMoved(_ touch: FTTouch) {
        self.eraseTouchHandler.eraserTouchesMoved(touch);
    }
}

extension FTWritingViewController : FTTouchEventsHandling
{
    func processTouchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        (self.pageContentDelegate as? FTTouchEventsHandling)?.processTouchesBegan(touches, with: event);
    }
    
    func processTouchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        (self.pageContentDelegate as? FTTouchEventsHandling)?.processTouchesEnded(touches, with: event);
    }
    
    func processTouchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        (self.pageContentDelegate as? FTTouchEventsHandling)?.processTouchesMoved(touches, with: event);
    }
    
    func processTouchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        (self.pageContentDelegate as? FTTouchEventsHandling)?.processTouchesCancelled(touches, with: event);
    }
}

extension FTWritingViewController : FTDocumentClosing
{
    func startProcessAndNotify(_ completionBlock: ((Bool) -> Void)!) {
        var operations = ["OnScreen","lasso"];
        
        let completionCallBack : (String)->() = { (refID) in
            if let index = operations.index(of: refID) {
                operations.remove(at: index);
            }
            if(operations.isEmpty) {
                completionBlock(true);
            }
        }
        if(nil == onscreenViewController) {
            completionCallBack("OnScreen");
        }
        else {
            self.onscreenViewController?.startProcessAndNotify({ (_) in
                completionCallBack("OnScreen");
            });
        }
        
        self.stopLassoOperationAndNotifiy { (_, label) in
            completionCallBack(label);
        }
    }
}

extension FTWritingViewController : FTPageEraseDataSource
{
    var contentHolderView: UIView? {
        return self.view;
    }
    
    var writingView: FTWritingProtocol? {
        return self;
    }
    
    var pageContentScale: CGFloat {
        return self.contentScale;
    }
}

//MARK:- FTSceneBackgroundHandling
extension FTWritingViewController: FTSceneBackgroundHandling {
    func configureSceneNotifications() {
        let object = self.sceneToObserve;
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sceneWillEnterForeground(_:)),
                                               name: UIApplication.sceneWillEnterForeground,
                                               object: object)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sceneDidEnterBackground(_:)),
                                               name: UIApplication.sceneDidEnterBackground,
                                               object: object)
    }
        
    func sceneWillEnterForeground(_ notification: Notification) {
        if(!self.canProceedSceneNotification(notification)) {
            return;
        }

        shouldPauseRendering = false
        resumeOperations()
    }

    func sceneDidEnterBackground(_ notification: Notification) {
        if(!self.canProceedSceneNotification(notification)) {
            return;
        }
        shouldPauseRendering = true
    }
}

extension FTWritingViewController: FTTextInteractionDelegate {
    func pdfSelectionView(_ view: FTPDFSelectionView, performAIAction selectedString: String) {
        (self.pageContentDelegate as? FTTextInteractionDelegate)?.pdfSelectionView?(view, performAIAction: selectedString);
    }
    
    func pdfInteractionWillBegin() {
        (self.pageContentDelegate as? FTTextInteractionDelegate)?.pdfInteractionWillBegin?();
    }
    
    func pdfInteractionShouldBegin(at point: CGPoint) -> Bool {
        return (self.pageContentDelegate as? FTTextInteractionDelegate)?.pdfInteractionShouldBegin?(at: point) ?? false;
    }
    
    func pdfInteractionDidEnd() {
        (self.pageContentDelegate as? FTTextInteractionDelegate)?.pdfInteractionDidEnd?();
    }
    
    func requiredTapGestureToFail() -> UITapGestureRecognizer? {
        return (self.pageContentDelegate as? FTPageViewController)?.requiredTapGestureToFail()
    }
}

#if targetEnvironment(macCatalyst)
extension FTWritingViewController: FTPDFSelectionViewContextMenuDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        if let del = self.pageContentDelegate as? FTPDFSelectionViewContextMenuDelegate {
            return del.contextMenuInteraction(interaction, configurationForMenuAtLocation: location);
        }
        return nil;
    }
}
#endif
