//
//  FTPageViewController.swift
//  Noteshelf
//
//  Created by Amar on 10/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTLassoInfo: NSObject {
    var lassoOffset: CGPoint = CGPoint.zero;
    var totalLassoOffset: CGPoint = CGPoint.zero;
    var selectedAnnotations: [FTAnnotation] = [FTAnnotation]();
    
    func reset(clearAnnotation: Bool = false) {
        self.lassoOffset = .zero;
        self.totalLassoOffset = .zero;
        if(clearAnnotation) {
            self.selectedAnnotations.removeAll();
        }
    }
}

@objcMembers class FTPageViewController: UIViewController {
    private let THUMBNAIL_SIZE = CGSize(width: 200, height: 248);
    
    private weak var page : FTPageProtocol?
    weak var delegate : FTPDFRenderViewController?;

    @IBOutlet weak var scrollView : FTPDFScrollView?;

    var renderMode: FTRenderMode = FTRenderModeDefault;
    private weak var stickerPlacementview: FTStickerPlacementView?;
    weak var lassoSelectionView: FTLassoSelectionView?;
    weak var lassoContentSelectionViewController: FTLassoContentSelectionViewController?

    // Don't make below viewmodel weak as this is needed for eyedropper delegate to be implemented here(since we are dismissing color edit controller)
    internal var penShortcutViewModel: FTPenShortcutViewModel?

    var lassoInfo: FTLassoInfo = FTLassoInfo();
    var pdfPage : FTPageProtocol? {
        return self.page;
    }
        
    func setPage(_ page: FTPageProtocol,layoutForcibly:Bool) {
        if(self.page?.uuid != page.uuid || layoutForcibly) {
            self.page = page;
            self.scrollView?.setPDFPage(page,layoutForcibly: layoutForcibly);
        }
    }
    
    var isCurrent : Bool = false {
        didSet{
            if(self.isCurrent != oldValue) {
                self.writingView?.isCurrentPage = self.isCurrent;
                if(self.isCurrent) {
                    self.perform(#selector(self.refreshSearchResults), with: nil, afterDelay: 0.1);
                }
                else {
                    NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.refreshSearchResults), object: nil);
                }
            }
        }
    };
        
    var layoutType: FTPageLayout {
        if(self.scrollView?.isIntroScreen ?? false) {
            return .horizontal;
        }
        return UserDefaults.standard.pageLayoutType;
    }
    
    private var currentViewSize : CGSize = CGSize.zero;

    internal weak var activeAnnotationController : FTAnnotationEditController? {
        didSet {
            #if targetEnvironment(macCatalyst)
            self.cancelPreviousInteraction()
            if nil == self.activeAnnotationController {
                self.addInteractionAfterDelayed();
            }
            else {
                if let interaction = self.view.interactions.first(where: { eachInteraction in
                    return eachInteraction is UIContextMenuInteraction
                }) {
                    self.view.removeInteraction(interaction)
                }
            }
            #endif
        }
    }
    internal weak var selectedAnnotation : FTAnnotation?;

    var pageContentScale : CGFloat {
        if let writingView = self.writingView {
            return writingView.scale;
        }
        return 1;
    }
    
    var writingView : FTWritingProtocol? {
        return self.scrollView?.writingView();
    }

    var showPageImmediately : Bool = false;
    var returningFromFinder : Bool = false;

    var contentHolderView : UIView? {
        return self.scrollView?.contentHolderView;
    }
    
    @IBOutlet internal weak var longPressGestureRecognizer : UILongPressGestureRecognizer?
    @IBOutlet internal weak var singleTapGestureRecognizer : UITapGestureRecognizer?
    @IBOutlet internal weak var singleTapSelectionGestureRecognizer : UITapGestureRecognizer?
    @IBOutlet internal weak var doubleTapGestureRecognizer : UITapGestureRecognizer?

    //MARK:- View Lifecycle
    convenience init(page : FTPageProtocol,
                     delegate : FTPDFRenderViewController?) {
        self.init(nibName: nil, bundle: nil);
        self.page = page;
        self.delegate = delegate;
    }

    convenience init(page : FTPageProtocol,
                     mode : FTRenderMode,
                     delegate : FTPDFRenderViewController?) {
        self.init(nibName: nil, bundle: nil);
        self.page = page;
        self.delegate = delegate;
        self.renderMode = mode;
    }

    override func loadView() {
        self.view = UIView.init(frame: UIScreen.main.bounds);
        self.view.clipsToBounds = true;
        
        if let _scrollView = FTPDFScrollView.init(frame: self.view.bounds,
                                                  parentViewController: self,
                                                  withPage: self.page,
                                                  mode: self.renderMode) {
            _scrollView.autoresizingMask = [.flexibleWidth,.flexibleHeight];
            self.scrollView = _scrollView;
            self.view.addSubview(_scrollView);
        }
        currentViewSize = self.view.frame.size;
    }
    
    deinit {
        NSObject.cancelPreviousPerformRequests(withTarget: self);
        NotificationCenter.default.removeObserver(self);
    }
    
    //MARK:- ViewController Default methods
    override func viewDidLoad() {
        super.viewDidLoad();
        self.configureOnLoad();
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        if(self.showPageImmediately) {
            self.loadPage();
            if(self.returningFromFinder) {
                self.writingView?.loadingFirstTime = false;
                self.returningFromFinder = false;
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator);
        self.scrollView?.willBeginInterfaceOrientation();
        let curScale = self.contentScale();

        coordinator.animate(alongsideTransition: { [weak self] (_) in
            self?.activeAnnotationController?.updateViewToCurrentScale(fromScale: curScale);
        }) { [weak self] (_) in
            self?.scrollView?.didEndInterfaceOrientation();
            self?.updateScrollPositionBasedOnCurrentPageViewControllerIndex();
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews();
        self.performViewLayout();
    }
    
    override func overrideTraitCollection(forChild childViewController: UIViewController) -> UITraitCollection? {
        if(childViewController is FTAnnotationEditController) {
            return self.traitCollection;
        }
        return super.overrideTraitCollection(forChild: childViewController);
    }

    private func performViewLayout()
    {
        NSObject.cancelPreviousPerformRequests(withTarget: self,
                                               selector: #selector(performLayout),
                                               object: nil);
        if(self.applicationState() == .background) {
            self.perform(#selector(performLayout), with: nil, afterDelay: 0.01);
        }
        else {
            self.performLayout();
        }
    }
    
    //MARK:- View Layout
    @objc private func performLayout() {
        if(currentViewSize != self.view.frame.size) {
            self.scrollView?.layoutWritingView();
            currentViewSize = self.view.frame.size;
        }
    }
    
    func layoutViewsIfNeeded() {
        self.view.layoutIfNeeded();
        self.scrollView?.layoutIfNeeded();
    }
    
    //MARK:- Public Methods
    func loadPage() {
        let shouldLayout = (self.scrollView?.writingView() == nil)
        self.scrollView?.setPDFPage(self.page,layoutForcibly: false);
        self.writingView?.pageContentDelegate = self;
        self.writingView?.isCurrentPage = self.isCurrent;
        
        if(self.showPageImmediately) {
            self.writingView?.loadingFirstTime = !self.showPageImmediately;
        }
        if(shouldLayout) {
            self.scrollView?.setNeedsLayout()
            self.scrollView?.layoutIfNeeded();
        }
        self.showPageImmediately = false;
        self.addObservers();
        self.updateScrollPositionBasedOnCurrentPageViewControllerIndex();
    }
    
    func setMode(_ mode : RKDeskMode) {
        self.writingView?.currentDrawingMode = mode;
        self.scrollView?.updateGestureConditions();
        self.updateGestureTouchTypes(mode: mode);
        
        if mode == RKDeskMode.deskModeStickers  {
            self.addStickerView();
        }
        else {
            self.removeStickerView();
        }
        
        if mode == RKDeskMode.deskModeClipboard  {
            self.addLassoViewIfNeeded();
        }
        else {
            self.removeLassoView();
        }
    }
    
    func clearPage() {
        if let curPage = self.page {
            FTCLSLog("PDF Page Clear, Page:\(curPage.pageIndex()+1)");
            
            self.endEditingActiveAnnotation(nil, refreshView: false);
            
            // To avoid removing audio annotations
            let otherThanAudioAnnotations = curPage.annotations().filter { element in
                !(element is FTAudioAnnotation)
            }
            self.removeAnnotations(otherThanAudioAnnotations, refreshView: true);

            self.perform(#selector(updateLowResolutionImageBackgroundView), with: nil, afterDelay: 0.001);
        }
    }
    
    func updateThumbanail(inBackground background: Bool) {
        guard let curPage = self.page, curPage.isDirty else {
            return;
        }
        
        UserDefaults.standard.removeObject(forKey: curPage.uuid);
        curPage.thumbnail()?.shouldGenerateThumbnail = true;
        if(background) {
            FTPDFExportView.snapshot(forPage: curPage,
                                     size: THUMBNAIL_SIZE,
                                     screenScale: UIScreen.main.scale)
            { (image, page) in
                DispatchQueue.main.async {
                    if let pageToUpdate = page {
                        let date = Date(timeIntervalSinceReferenceDate: pageToUpdate.lastUpdated.doubleValue);
                        pageToUpdate.thumbnail()?.updateThumbnail(image,updatedDate: date);
                    }
                }
            };
        }
        else {
            if let thumb = self.snapshot(size: THUMBNAIL_SIZE, screenScale: UIScreen.main.scale) {
                let date = Date(timeIntervalSinceReferenceDate: curPage.lastUpdated.doubleValue);
                curPage.thumbnail()?.updateThumbnail(thumb, updatedDate: date);
            }
        }
        curPage.isDirty = false;
    }
    
    #if targetEnvironment(macCatalyst)
    func showHelp(_ sender : Any?)
    {
        FTHelpMenuAction.showHelp(sender);
    }
    #endif
    
    func setContentOffset(_ offset: CGPoint) {
        self.scrollView?.setNeedsLayout();
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    func registerViewForTouchEvents() {
        self.writingView?.registerViewForTouchEvents();
    }

    func unregisterView(forTouchEvents setToDefault: Bool) {
        self.writingView?.unregisterView(forTouchEvents: setToDefault);
    }
    
    func addShapeControllerIfNeeded() {
        let shapeType = FTShapeType.savedShapeType()
        if (shapeType == .freeForm) {
            self.endEditingActiveAnnotation(nil, refreshView: true)
            return
        }
        let shapeInfo = FTShapeAnnotationInfo(with: shapeType)
        self.addAnnotation(info: shapeInfo)
    }
}

//MARK:- Zoom Related
@objc extension FTPageViewController
{
    func unZoomIfNeeded(animate : Bool,completionBlock : (()->())?) {
        self.zoom(scale: 1, animate: animate, completionBlock: completionBlock);
    }
    
    func enterZoomMode() {
        self.setAccessoryViewHeight(0);
        self.scrollView?.lockZoom();
        self.writingView?.willEnterZoomMode();
    }

    func exitZoomMode() {
        self.setAccessoryViewHeight(0);
        self.scrollView?.unlockZoom();
        self.writingView?.didExitZoomMode();
    }
    
    func setAccessoryViewHeight(_ height: CGFloat) {
        self.scrollView?.accessoryViewHeight = Int(height);
    }
    
    func updateScrollPositionBasedOnCurrentPageViewControllerIndex()
    {
        guard let pageScrollView = self.scrollView,
            self.renderMode == FTRenderModeDefault else {
            return;
        }
        
        if let currentPage = self.delegate?.currentlyVisiblePage()?.pageIndex(),
            let thisPage = self.page?.pageIndex() {
            if(currentPage > thisPage) {
                var contentOffset = CGPoint.zero;
                contentOffset.x = max((pageScrollView.contentSize.width - pageScrollView.frame.width),0);
                pageScrollView.contentOffset = contentOffset;
            }
            else if(currentPage < thisPage) {
                pageScrollView.contentOffset = CGPoint.zero;
            }
        }
    }
    
    func zoom(scale inScale: CGFloat,animate : Bool,completionBlock : (() -> ())?) {
        guard let _scrollView = self.scrollView else {
            completionBlock?();
            return;
        }
        let maxZoomScale: CGFloat = _scrollView.maxZoomScale;
        let minZoomScale: CGFloat = _scrollView.minZoomScale;
        
        let scale = max(min(inScale,maxZoomScale),minZoomScale);
        
        if(fabsf(Float(_scrollView.zoom - scale)) < 0.001) {
            completionBlock?();
            return;
        }
        self.scrollView?.isZoomingInProgress = true;
        self.scrollView?.isProgramaticallyZooming = true;
        self.scrollView?.scrollViewDidCompleteZoomBlock = completionBlock;
        
        let percentageOfZoom = (scale/(maxZoomScale-minZoomScale));
        
        let maxZoom = _scrollView.maximumZoomScale;
        let minZoom = _scrollView.minimumZoomScale;
        
        let value = percentageOfZoom*(maxZoom-minZoom);
        self.scrollView?.setZoomScale(value, animated: animate);
        if(!animate) {
            if let scrollDel = _scrollView.delegate, scrollDel.responds(to: #selector(UIScrollViewDelegate.scrollViewDidEndZooming(_:with:atScale:))) {
                self.scrollView?.isZoomingInProgress = true;
                scrollDel.scrollViewDidEndZooming?(_scrollView,
                                                   with: _scrollView.contentHolderView,
                                                   atScale: value);
            }
        }
    }    
}

internal extension FTPageViewController
{
    func refresh(_ rectIn1x : CGRect,
                 scale : CGFloat = -1,
                 renderProperties: FTRenderingProperties = FTRenderingProperties()) {
        if nil != self.lassoSelectionView {
            self.normalizeLassoView();
        }
        
        if let writingView = self.writingView {
            renderProperties.pageID = self.pdfPage?.uuid;
            var scaleToApply = self.pageContentScale;
            if(scale != -1) {
                scaleToApply = scale
            }
            writingView.reloadTiles(in: CGRectScale(rectIn1x, scaleToApply),
                                    properties: renderProperties);
            writingView.updateLowResolutionImageBackgroundView();
        }
        self.refreshZoomViewIfNeeded();
    }
    
    @objc func updateLowResolutionImageBackgroundView() {
        self.writingView?.updateLowResolutionImageBackgroundView();
    }
}

//MARK:- private
extension FTPageViewController
{
    internal func refreshZoomViewIfNeeded() {
        if self.delegate?.isInZoomMode() ?? false {
            self.delegate?.zoomOverlayController.refreshView();
        }
    }

    private func snapshot(size : CGSize,screenScale : CGFloat) -> UIImage? {
        if let curPage = self.page {
            var snapshotSize = size;
            if(snapshotSize == CGSize.zero) {
                snapshotSize = curPage.pageReferenceViewSize();
            }
            return FTPDFExportView.snapshot(forPage: page,
                                            size: snapshotSize,
                                            screenScale: screenScale,
                                            shouldRenderBackground: true)
        }
        return nil;
    }
}

//MARK:- Undo / Redo
private extension FTPageViewController
{
    @objc func pageDidUndoRedoAction(_ notification: Notification) {
        guard let pageNotified = notification.object as? FTPageProtocol,
              pageNotified.uuid == self.page?.uuid else {
            return
        }
        if let rect = notification.userInfo?[FTRefreshRectKey] as? CGRect {
            self.refresh(rect);
        } else {
            if let _scrollView = self.scrollView {
                self.refresh(_scrollView.visibleRect(), scale: 1);
            }
        }

        if(self.renderMode == FTRenderModeDefault) {
            var userInfo : [String : Any] = [String : Any]();
            if let window = self.view.window {
                userInfo[FTRefreshWindowKey] = window;
            }
            NotificationCenter.default.post(name: Notification.Name.FTRefreshExternalView,
                                            object: self.pdfPage,
                                            userInfo: userInfo);
        }
        runInMainThread {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: FTValidateToolBarNotificationName), object: self.view.window);
        }
    }
}

//MARK:- Notification Observers
@objc private extension FTPageViewController
{
    private func configureOnLoad() {
        self.configureForPDFLinks();
        self.configureGestures();
        NotificationCenter.default.addObserver(forName: FTWhiteboardDisplayManager.didChangePageDisplay,
                                               object: nil,
                                               queue: nil)
        { [weak self] (notification) in
            if let pageUUID = notification.object as? String,self?.pdfPage?.uuid == pageUUID {
                self?.contentHolderView?.layer.borderWidth = 2;
                self?.contentHolderView?.layer.borderColor = UIColor.appColor(.accent).cgColor;
            }
            else {
                self?.contentHolderView?.layer.borderWidth = 0;
                self?.contentHolderView?.layer.borderColor = nil;
            }
        }
        
        #if targetEnvironment(macCatalyst)
        self.addContextInteraction();
        #endif
    }
    
    func addObservers()
    {
        let defaultNotificationCenter = NotificationCenter.default;
        if(self.renderMode == FTRenderModeDefault) {
            defaultNotificationCenter.addObserver(self,
                                                  selector: #selector(annotationDidRemove(_:)),
                                                  name: .didRemoveAnnotationNotification,
                                                  object: self.pdfPage);
            
            defaultNotificationCenter.addObserver(self,
                                                  selector: #selector(willPerformUndoRedoAction(_:)),
                                                  name: .willPerformUndoRedoActionNotification,
                                                  object: self.pdfPage?.parentDocument?.undoManager);

            defaultNotificationCenter.addObserver(self,
                                                  selector: #selector(didChangeOrderNotification(_:)),
                                                  name: .didChangeOrderNotification,
                                                  object: self.pdfPage);

            defaultNotificationCenter.addObserver(self,
                                                  selector: #selector(contentScaleHasBeenChanged(_:)),
                                                  name: Notification.Name("FTContentScaleHasBeenChanged"),
                                                  object: nil);
        }
        defaultNotificationCenter.addObserver(self,
                                              selector: #selector(pageDidUndoRedoAction(_:)),
                                              name: .pageDidUndoRedoNotification,
                                              object: self.pdfPage);
        
        defaultNotificationCenter.addObserver(forName: Notification.Name.refreshPageNotification,
                                              object: self.pdfPage,
                                              queue: nil) { [weak self] (notification) in
            let curRenderMode = (notification.userInfo?["RenderMode"] as? FTRenderMode) ?? FTRenderModeDefault;
            guard let strongSelf = self,
                  let userInfi = notification.userInfo,
                  let window = userInfi[FTRefreshWindowKey] as? UIWindow,
                  (window != strongSelf.view.window || curRenderMode != strongSelf.renderMode) else {
                return;
            }
            
            if let rect = userInfi[FTRefreshRectKey] as? CGRect {
                strongSelf.refresh(rect);
            }
            else if let _scrollView = strongSelf.scrollView {
                strongSelf.refresh(_scrollView.visibleRect(), scale: 1);
            }
        }
    }
    
    func willPerformUndoRedoAction(_ notification : Notification) {
        saveActiveAnnotationIfAny()
    }
    
    func annotationDidRemove(_ notification : Notification) {
        guard let undomanager = self.pdfPage?.parentDocument?.undoManager else { return }
        guard let annotation = notification.userInfo?["annotation"] as? FTAnnotation else { return }
        if self.activeAnnotationController == nil {
            activeAnnotationController = self.delegate?.activeAnnotationController()
        }
        guard let activeController = activeAnnotationController,
              activeController.annotation == annotation else { return };
        undomanager.disableUndoRegistration();
        self.endEditingActiveAnnotation(annotation, refreshView: false);
        undomanager.enableUndoRegistration();
    }

    func didChangeOrderNotification(_ notification: Notification) {
        guard let undomanager = self.pdfPage?.parentDocument?.undoManager else { return }
        guard let annotation = notification.userInfo?["annotation"] as? FTAnnotation else { return }
        guard let activeController = self.activeAnnotationController,
              activeController.annotation == annotation else { return };
        undomanager.disableUndoRegistration();
        self.endEditingActiveAnnotation(annotation, refreshView: false);
        undomanager.enableUndoRegistration();
    }
    
    func contentScaleHasBeenChanged(_ notification : Notification)
    {
        guard notification.isSameSceneWindow(for: self.view.window) else {
            return;
        }

        if let zoomedPageController = notification.userInfo?["zoomedPageController"] as? FTPageViewController,
            zoomedPageController != self {
            self.scrollView?.layoutWritingView();
            self.updateScrollPositionBasedOnCurrentPageViewControllerIndex();
        }
    }
    
    private func refreshSearchResults() {
        DispatchQueue.global().async { [weak self] in
            if let curPage = self?.pdfPage as? FTPageSearchProtocol,
                let options = self?.delegate?.finderSearchOptions,
                let searchKey = options.searchedKeyword {
                if(!searchKey.isEmpty) {
                    curPage.searchFor(searchKey, tags: [String](),isGlobalSearch: false);
                }
            }
        }
    }
}

extension FTPageViewController: FTStickerPlacementViewDelegate
{
    func placeSticker(in targetRect: CGRect, sticker: UIImage?, emojiID: Int) {
        guard let placmentView = self.stickerPlacementview,
            let img = sticker else {
                return;
        }
        let scale = self.pageContentScale;
        let emojiName = NSNumber(value: emojiID).stringValue;
        let boundingRect = placmentView.convert(targetRect, to: self.contentHolderView);
        
        let stickyAnnotationInfo = FTStickyAnnotationInfo(image: img, name: emojiName);
        stickyAnnotationInfo.boundingRect = CGRect.scale(boundingRect, 1/scale);
        stickyAnnotationInfo.scale = scale;
        self.addAnnotation(info: stickyAnnotationInfo);
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: FTPDFEnableGestures), object: self.view.window);
    }
    
    func willBeginStickerPlacement(in rect: CGRect, sticker: UIImage?, emojiID: Int) {
        self.stickerPlacementview?.setScale(self.pageContentScale);
    }
}

extension FTPageViewController {
    private func addStickerView() {
        if(nil == self.stickerPlacementview) {
            guard let contentView = self.contentHolderView else {
                return;
            }
            let stickerView = FTStickerPlacementView(frame: contentView.bounds);
            stickerView.delegate = self;
            self.stickerPlacementview = stickerView;
            contentView.addSubview(stickerView);
        }
    }
    
    private func removeStickerView() {
        self.stickerPlacementview?.removeFromSuperview();
    }    
}

extension FTPageViewController : FTDocumentClosing {
    func startProcessAndNotify(_ completionBlock: ((Bool) -> Void)!) {
        if let closingWritingView = self.writingView as? FTDocumentClosing {
            closingWritingView.startProcessAndNotify { (success) in
                runInMainThread {
                    completionBlock?(success);
                }
            };
        }
        else {
            completionBlock(true);
        }
    }
}

extension FTPageViewController {
    func postRefreshNotification(_ rect:CGRect = .null) {
        DispatchQueue.main.async {
            
            var userInfo: [String:Any]?;
            if let window = self.view.window {
                userInfo = [FTRefreshWindowKey: window];
            }
            if !rect.isNull {
                userInfo?[FTRefreshRectKey] = rect;
            }
            userInfo?["RenderMode"] = self.renderMode;
            NotificationCenter.default.post(name: Notification.Name.FTRefreshExternalView,
                                            object: self.pdfPage,
                                            userInfo: userInfo);
            NotificationCenter.default.post(name: .refreshPageNotification,
                                            object: self.pdfPage,
                                            userInfo: userInfo);
        }
    }
}

#if targetEnvironment(macCatalyst)
extension FTPageViewController {
    func canPerformMenuAction(_ selector: Selector) -> Bool {
        if selector == #selector(copy(_:))
            || selector == #selector(cut(_:))
            || selector == #selector(delete(_:)) {
            if let activeContorller = self.activeAnnotationController {
                return activeContorller.canPerformAction?(selector) ?? false;
            }
            if self.currentDeskMode() == .deskModeClipboard,
               let lassoView = self.lassoSelectionView,
               nil != lassoView.antsView,
               let action = self.lassoAction(for: selector) {
                return self.lassoSelectionView(lassoView, canPerform: action);
            }            
        }
        return false;
    }
    
    func performMenuAction(_ selector: Selector) {
        
        if selector == #selector(copy(_:))
            || selector == #selector(cut(_:))
            || selector == #selector(delete(_:)) {
            if let activeContorller = self.activeAnnotationController {
                activeContorller.performAction?(selector)
            }
            else if self.currentDeskMode() == .deskModeClipboard,
               let lassoView = self.lassoSelectionView,
               nil != lassoView.antsView,
               let action = self.lassoAction(for: selector) {
                self.lassoSelectionView(lassoView, perform: action);
            }
            else {
                super.perform(selector);
            }
        }
    }
    
    private func lassoAction(for selector: Selector) -> FTLassoAction? {
        var action: FTLassoAction?
        switch selector {
        case #selector(copy(_:)):
            action = .copy;
        case #selector(cut(_:)):
            action = .cut;
        case #selector(delete(_:)):
            action = .delete;
        default:
            break;
        }
        return action;
    }
}

extension FTPageViewController: UIContextMenuInteractionDelegate {
    private func addInteractionAfterDelayed() {
        self.cancelPreviousInteraction();
        self.perform(#selector(self.addContextInteraction), with: nil, afterDelay: 0.1);
    }
    
    private func cancelPreviousInteraction() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.addContextInteraction), object: nil);
    }
    
    @objc func addContextInteraction() {
        let contextMenu = UIContextMenuInteraction.init(delegate: self)
        self.view.addInteraction(contextMenu)
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        if self.currentDeskMode() == .deskModeClipboard {
            return self.lassoSelectionView?.contextMenuInteraction(interaction, configurationForMenuAtLocation: location)
        }
        
        guard nil == self.activeAnnotationController else {
            return nil;
        }
        
        let actionProvider: UIContextMenuActionProvider = { [weak self] _ in
            guard let strongSelf = self else {
                return nil;
            }
            
            var menuItems = [UIMenuElement]();
            let point = interaction.location(in: strongSelf.contentHolderView);
            if let annotation = strongSelf.annotation(type: .longPress, atPoint: point),annotation.isLocked {
                let unlock = UIAction(title: NSLocalizedString("Unlock", comment: "Unlock")) { [weak self, weak annotation] _ in
                    annotation?.isLocked = false
                    if let _annotation = annotation {
                        self?.editAnnotation(_annotation, eventType: .longPress, at: point);
                    }
                }
                
                menuItems.append(unlock);
            }
            else if UIPasteboard.canPasteContent(),
                    strongSelf.currentDeskMode() != .deskModeClipboard,
                    strongSelf.currentDeskMode() != .deskModeLaser {
                let pasteAction = UIAction(title: NSLocalizedString("Paste", comment: "Paste")) { [weak self] _ in
                    self?.performPasteOperation(at: interaction.location(in: self?.contentHolderView))
                }
                menuItems.append(pasteAction);
            }
            
            guard !menuItems.isEmpty else {
                return nil;
            }
            
            let menu = UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: menuItems)
            return menu;
        }
        
        let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: actionProvider)
        return config;
    }
}
#endif

extension FTPageViewController: FTTextInteractionDelegate {
    func pdfInteractionWillBegin() {
        self.endEditingActiveAnnotation(nil, refreshView: true);
    }
    
    func pdfSelectionView(_ view: FTPDFSelectionView, performAIAction selectedString: String) {
        self.startOpenAiForPage();
    }

    func pdfInteractionShouldBegin(at point: CGPoint) -> Bool {
        if self.renderMode == FTRenderModeDefault,
           nil != self.annotation(type: .longPress, atPoint: point) {
            return false;
        }
        else if let lassoView = self.lassoSelectionView,
                let antsView = lassoView.antsView {
            return antsView.isPointInsidePath(point);
        }
#if targetEnvironment(macCatalyst)
        return self.currentDeskMode() == .deskModeReadOnly
#else
        return true;
#endif
    }
    
    func requiredTapGestureToFail() -> UITapGestureRecognizer? {
        return self.singleTapGestureRecognizer;
    }
}

#if targetEnvironment(macCatalyst)
extension FTPageViewController: FTPDFSelectionViewContextMenuDelegate {
    
}
#endif
