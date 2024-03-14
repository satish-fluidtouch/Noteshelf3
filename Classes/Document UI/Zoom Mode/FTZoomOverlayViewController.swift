//
//  FTZoomOverlayViewController.swift
//  Noteshelf
//
//  Created by Amar on 13/04/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension UIView {
   func zoomboxRoundCorners(radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds,
                                byRoundingCorners: [.topLeft, .topRight],
                                cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}

@objcMembers class FTZoomPanelConstant : NSObject {
    static let overlayHeight:CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 200.0 : 360;
    static let contentHeight: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 156 : 290;
}

@objc protocol FTZoomOverlayViewControllerDelegate: NSObjectProtocol
{
    func zoomPanelDidChangeTool(_ deskMode: RKDeskMode);

    func zoomPanelUndoTapped();
    func zoomPanelRedoTapped();
    func zoomPanelDidTapOnPalmRest();

    func zoomOverlayNavigateTo(page : FTPageProtocol);
    func zoomOverlayScrollTo(targetRect: CGRect,pageController:FTPageViewController?);
    func zoomOverlayDidChangePanelFrame(_ frame: CGRect,pageController:FTPageViewController?);
    func zoomOverlayWillChangePanelFrame(_ frame: CGRect)

    func pageLayoutType() -> FTPageLayout;
}

@objcMembers class FTZoomOverlayViewController: UIViewController {
    
    internal weak var pageLayoutDidChangeObserver: NSObjectProtocol?;
    internal weak var pageLayoutWillChangeObserver: NSObjectProtocol?;
    internal weak var zoomDidBeginTouchesObserver: NSObjectProtocol?;
    internal weak var zoomDidEndTouchesObserver: NSObjectProtocol?;

    internal var zoomRectUpdateInProgress = false;
    private var oldSize = CGSize.zero;
    private var isWindowResizeInProgress = false;
    
    @IBOutlet private weak var contentViewHeightConstraint: NSLayoutConstraint?;
    
    private(set) weak var nsDocument: FTDocumentProtocol?;
    weak var delegate: FTZoomOverlayViewControllerDelegate?;
    
    @IBOutlet private weak var visualEffectView: UIVisualEffectView?
    @IBOutlet private weak var contentHolderView : UIView?
    @IBOutlet private weak var toolbarHolderView : UIView?
    @IBOutlet private weak var palmRestView : UIView?
    
    private weak var mainDocumentRenderController: FTPDFRenderViewController?;
    private(set) weak var currentPageController: FTPageViewController?;
    private(set) var shortcutModeZoom: FTZoomShortcutMode = .auto

    private(set) weak var zoomPanelController : FTZoomPanelViewController? {
        didSet {
            self.zoomPanelController?.dataSource = self;
            self.zoomPanelController?.delegate = self;
        }
    }
    
    private(set) weak var zoomContentController : FTZoomContentViewController? {
        didSet {
            self.zoomContentController?.dataSource = self;
            self.zoomContentController?.delegate = self;
        }
    }
    private weak var zoomSettingsViewController : FTZoomSettingsViewController?
    
    private var maxPalmPosition:CGFloat {
        guard let superView = self.view.superview else {
            return 0
        }
        var areaTopOffset: CGFloat = FTToolbarConfig.Height.regular

        if UIDevice.current.isPhone() {
            areaTopOffset = FTToolbarConfig.Height.compact
            areaTopOffset += 100.0 // offset to see notebook
            if let window = UIApplication.shared.keyWindow {
                let topSafeAreaInset = window.safeAreaInsets.top
                if topSafeAreaInset > 0 {
                    areaTopOffset += topSafeAreaInset
                }
            }
        } else {
            areaTopOffset += 150.0 // offset to see notebook
        }
        let maxPalmPosition = superView.frame.height - FTZoomPanelConstant.overlayHeight - areaTopOffset
        return maxPalmPosition
    }
    
    private(set)weak var currentPage: FTPageProtocol?;
    
    internal var lastStrokeInpactedRect : CGRect = .null;
    internal var autoscrollTimer: Timer?;
    internal lazy var zoomManagerView: FTZoomManagerView = {
        let zoomManagerView = FTZoomManagerView.init(frame: CGRect.zero);
        zoomManagerView.delegate = self;
        return zoomManagerView;
    }();
    
    var currentDeskMode: RKDeskMode = .deskModeView {
        didSet{
            self.zoomContentController?.didChangeDeskMode(self.currentDeskMode);
        }
    }
    
    private var previousRect : CGRect = .null;

    override func updateViewConstraints() {
        self.contentViewHeightConstraint?.constant = FTZoomPanelConstant.contentHeight;
        super.updateViewConstraints();
    }
    
    static func zoomOverlayController(document: FTDocumentProtocol,
                                      renderViewController: FTPDFRenderViewController) -> FTZoomOverlayViewController {
        
        let storyboard = UIStoryboard.init(name: "FTZoomOverlay", bundle: nil);
        guard let controller = storyboard.instantiateInitialViewController() as? FTZoomOverlayViewController else {
            fatalError("root should be FTZoomOverlayViewController");
        }
        controller.mainDocumentRenderController = renderViewController;
        controller.nsDocument = document;
        return controller;
    }
    
    deinit {
        self.removeZoomManagerView();
        if let observer = self.pageLayoutDidChangeObserver {
            NotificationCenter.default.removeObserver(observer);
        }
        if let observer = self.pageLayoutWillChangeObserver {
            NotificationCenter.default.removeObserver(observer);
        }
        if let observer = self.zoomDidEndTouchesObserver {
            NotificationCenter.default.removeObserver(observer);
        }
        if let observer = self.zoomDidBeginTouchesObserver {
            NotificationCenter.default.removeObserver(observer);
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.autoresizingMask = [.flexibleWidth,.flexibleTopMargin];
        self.visualEffectView?.shapeTopCorners(16.0)
        self.visualEffectView?.setBorderColor(withBorderWidth: 1.0, withColor: UIColor.label.withAlphaComponent(0.04))
        self.view.clipsToBounds = false
        self.view.addShadow(cornerRadius: 16.0, color: UIColor.label.withAlphaComponent(0.1), offset: CGSize(width: 0.0, height: 10.0), opacity: 1.0, shadowRadius: 60.0)
        self.addObservers();
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        (self.view as? FTZoomOverlayView)?.contentHolderView = self.contentHolderView
        (self.view as? FTZoomOverlayView)?.pdfRenderVc = self.mainRenderViewController
    }
    
    private func addObservers(){
        self.addZoomTouchesNotificationHandlers();
        self.addZoomScrollViewNotificationObservers();
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews();
        if !isWindowResizeInProgress,self.view.bounds.size != self.oldSize  {
            self.oldSize = self.view.bounds.size;
            self.updateFrameIfNeeded();
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender);
        if segue.identifier == "EmbedZoomPanelVC" {
            self.zoomPanelController = segue.destination as? FTZoomPanelViewController;
        }
        else if segue.identifier == "EmbedZoomContentVC" {
            self.zoomContentController = segue.destination as? FTZoomContentViewController;
        }
    }
    
    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator)
    {
        NSObject.cancelPreviousPerformRequests(withTarget: self,
                                               selector: #selector(self.performLayout),
                                               object: nil);
        super.viewWillTransition(to: size, with: coordinator);
        
        guard let currentPageController = self.currentPageController else {
            return;
        }
        
        let zoomTargetRect = self.zoomTargetRect;
        self.previousRect = CGRect.scale(zoomTargetRect, 1/currentPageController.pageContentScale);
        coordinator.animate(alongsideTransition: { (_) in
            if(self.applicationState() != .background) {
                self.performLayout();
            }
            else {
                self.perform(#selector(self.performLayout),
                             with: nil,
                             afterDelay: 0.01);
            }
        }) { (_) in
            
        }
    }
    
    @objc private func performLayout() {
        guard let currentPageController = self.currentPageController else {
            return;
        }
        let newTargetRect = CGRect.scale(self.previousRect, currentPageController.pageContentScale);
        if self.zoomTargetRect.integral != newTargetRect.integral {
            self.zoomTargetRect = newTargetRect;
            self.updateZoomAreaSize();
        }
        else {
            self.zoomTargetRect = newTargetRect;
            self.didMovedRect(self.zoomManagerView);
            self.didFinishMoving(self.zoomManagerView);
        }
        self.updateZoomManagerViewAttributes(pageContentScale: currentPageController.pageContentScale);
    }
    
    func addZoomOverlay(for page: FTPageProtocol,pageController : FTPageViewController) {
        guard let mainController = self.mainRenderViewController,
            let contentView = mainController.view else {
                return;
        }
        //Add the Zoom Panel view at the bottom
        var storedZoomHeight = FTZoomPanelConstant.overlayHeight;
        storedZoomHeight += self.nsDocument?.localMetadataCache?.zoomPalmRestHeight ?? 0;
        
        let contentBounds = contentView.bounds;
        var endTargetFrame = contentBounds;
        endTargetFrame.origin = CGPoint(x:0, y:endTargetFrame.height - storedZoomHeight);
        endTargetFrame.size = CGSize(width:endTargetFrame.width, height:storedZoomHeight);
        
        var initialRect = endTargetFrame;
        initialRect.origin.y = contentBounds.height;
        mainController.addChild(self);
        self.view.frame = initialRect;
        contentView.addSubview(self.view);
        
        if let zoomOrigin = self.nsDocument?.localMetadataCache?.zoomOrigin(for: page.pageIndex()) {
            page.zoomTargetOrigin = zoomOrigin;
        }
        
        self.setCurrentPage(page,
                            pageController: pageController);
        self.view.layoutIfNeeded();
        self.willEnterZoomMode();
        
        contentView.window?.isUserInteractionEnabled = false;
        UIView.animate(withDuration: 0.2,
                       animations: {
                        self.view.frame = endTargetFrame;
        }) { [weak self] (_) in
            contentView.window?.isUserInteractionEnabled = true;
            self?.becomeFirstResponder();
        }
    }

    @objc func updateZoomShortcutMode(_ mode: FTZoomShortcutMode) {
        self.shortcutModeZoom = mode
    }

    func removeZoomOverlay()
    {
        let window = self.view.window;
        var zoomFrame = self.view.frame;
        zoomFrame.origin.y = zoomFrame.maxY;
        
        window?.isUserInteractionEnabled = false;
        UIView.animate(withDuration: 0.2,
                       animations: {
                        self.view.frame = zoomFrame;
        }) { (_) in
            self.removeFromParent();
            self.view.removeFromSuperview();
            window?.isUserInteractionEnabled = true;
        }
        self.zoomContentController?.didEndActiveAnnotation()
    }
    
    func setCurrentPage(_ page: FTPageProtocol,
                        pageController: FTPageViewController) {
        if let curPage = self.currentPage,
            let curPageVC = self.currentPageController,
            curPage.uuid != page.uuid {
            curPage.zoomTargetOrigin = CGPoint.scale(self.zoomTargetRect.origin, 1/curPageVC.pageContentScale)
        }
        
        self.currentPage = page;
        self.zoomContentController?.setPageToDisplay(page);
        self.zoomPanelController?.validateUI();
        
        self.currentPageController = pageController;
        self.currentPageControllerDidChanged();
    }
    
    internal func currentPageControllerDidChanged() {
        guard let pageController = self.currentPageController else {
            return;
        }
        self.addZoomManagerView(to: pageController);
        
        self.delegate?.zoomOverlayDidChangePanelFrame(self.view.frame,
                                                       pageController: pageController);
        if !self.zoomManagerView.isMoving,
            !self.zoomManagerView.isSizing {
            refreshZoomTargetRect(forcibly: false);
        }
    }
    
    func isTouchInsideZoomManager(_ gesture:UIGestureRecognizer) -> Bool {
        let point = gesture.location(in: self.currentPageController?.contentHolderView);
        let targetRect = self.zoomTargetRect.insetBy(dx: -10, dy: -10);
        if(targetRect.contains(point)
            || self.zoomManagerView.isSizing ||
            self.zoomManagerView.isMoving) {
            return true;
        }
        return false;
    }
    
    func updateGestureConditions() {
        self.zoomContentController?.updateGestureConditions();
    }
    
    func registerViewForTouchEvents() {
        self.zoomContentController?.registerViewForTouchEvents();
    }
    
    func unregisterView(forTouchEvents setToDefault: Bool) {
        self.zoomContentController?.unregisterView(forTouchEvents: setToDefault);
    }
    
    func refreshView() {
        self.zoomContentController?.refreshView();
    }
    
    func updateZoomAreaTargetRect()
    {
        self.updateZoomTargetRect();
    }
    
    override var canBecomeFirstResponder: Bool {
        return true;
    }
    
    //MARK:- UIKeyCommand & Actions -
    override var keyCommands: [UIKeyCommand]? {
        #if targetEnvironment(macCatalyst)
        return nil;
        #else
        return [.zoomOverlayPanLeft,
                .zoomOverlayPanRight,
                .zoomOverlayPanDown,
                .zoomOverlayPanUp];
        #endif
    }
    
    override func zoomOverlayPanDown(_ sender:Any?) {
        debugLog("ZooomOverlay - zoomOverlayPanDown")
        self.zoomPanelPanNewLineDown();
    }
    
    override func zoomOverlayPanLeft(_ sender:Any?) {
        debugLog("ZooomOverlay - zoomOverlayPanLeft")
        self.zoomPanelPanLeft();
    }
    
    override func zoomOverlayPanRight(_ sender:Any?) {
        debugLog("ZooomOverlay - zoomOverlayPanRight")
        self.lastStrokeInpactedRect = CGRect.null;
        self.zoomPanelPanRight();
    }
    
    override func zoomOverlayPanUp(_ sender:Any?) {
        debugLog("ZooomOverlay - zoomOverlayPanUp")
        self.zoomPanelPanNewLineUp();
    }
}

//MARK: - Internal -
internal extension FTZoomOverlayViewController
{
    var visibleFrame: CGRect {
        return self.zoomContentController?.visibleFrame ?? CGRect.null;
    }
    
    var contentOffset: CGPoint {
        set {
            self.zoomContentController?.contentOffset = newValue;
        }
        get {
            return self.zoomContentController?.contentOffset ?? CGPoint.zero;
        }
    }
    
    var contentFrame: CGRect {
        return self.zoomContentController?.view.frame ?? CGRect.null;
    }
    
    var pageContentScale: CGFloat {
        return self.zoomContentController?.pageContentScale ?? 1;
    }
    
    var zoomFactor: CGFloat {
        set {
            self.zoomContentController?.zoomFactor = newValue;
        }
        get {
            return self.zoomContentController?.zoomFactor ?? 1;
        }
    }
    
    func zoomFrom(center pointIn1x: CGPoint,animate:Bool,forcibly: Bool)
    {
        self.zoomContentController?.zoomFrom(center: pointIn1x,
                                             animate: animate,
                                             forcibly: forcibly);
    }
    
    var leftMargin: CGFloat {
        guard let localCache = self.currentPage?.parentDocument?.localMetadataCache else {
            return 0;
        }
        let zoomMarginPercent = localCache.zoomLeftMargin;
        let leftMargin = zoomMarginPercent * 0.01 * zoomManagerView.frame.width
        return leftMargin;
    }
}

//MARK: - Private -
private extension FTZoomOverlayViewController
{    
    func penButtonAction(_ sender: UIView) {
        if self.currentDeskMode == .deskModePen {
            let userActivity = self.view.window?.windowScene?.userActivity
            FTPenRackViewController.setRackType(penTypeRack: FTRackData(type: .pen, userActivity: userActivity))
            FTPenRackViewController.showPopOver(presentingController: self, sourceView: sender)
            return
        }
        self.delegate?.zoomPanelDidChangeTool(.deskModePen)
    }
    
    func highlighterButtonAction(_ sender: UIView) {
        if self.currentDeskMode == .deskModeMarker {
            let userActivity = self.view.window?.windowScene?.userActivity
            FTPenRackViewController.setRackType(penTypeRack: FTRackData(type: .highlighter, userActivity: userActivity))
            FTPenRackViewController.showPopOver(presentingController: self, sourceView: sender)
            return
        }
        self.delegate?.zoomPanelDidChangeTool(.deskModeMarker)
    }
    
    func eraserButtonAction(_ sender: UIView) {
        if self.currentDeskMode == .deskModeEraser {
            if let eraserVc =  FTEraserRackViewController.showPopOver(presentingController: self, sourceView: sender) as? FTEraserRackViewController {
                eraserVc.eraserDelegate = self
            }
            return
        }
        self.delegate?.zoomPanelDidChangeTool(.deskModeEraser)
    }
    
    func shapeButtonAction(_ sender: UIView) {
        guard let doc = self.nsDocument else {
            return
        }
        let shapeEnabled = doc.localMetadataCache?.shapeDetectionEnabled ?? false;
        if !shapeEnabled {
            doc.localMetadataCache?.shapeDetectionEnabled = !shapeEnabled;
        }
        if self.currentDeskMode == .deskModeShape {
            let userActivity = self.view.window?.windowScene?.userActivity
            FTShapesRackViewController.setRackType(penTypeRack: FTRackData(type: .highlighter, userActivity: userActivity))

            FTShapesRackViewController.showPopOver(presentingController: self, sourceView: sender, sourceRect: sender.bounds)
            return;
        }
        
        self.delegate?.zoomPanelDidChangeTool(.deskModeShape);
    }
    
    func favoriteButtonAction(_ sender: UIView) {
        if self.currentDeskMode == .deskModeFavorites {
            return
        }
        self.delegate?.zoomPanelDidChangeTool(.deskModeFavorites)
    }

    func settingsButtonAction(_ action: UIButton?) {
        if(self.isSettingsShown) {
            action?.backgroundColor = .clear
            self.dismissSettings();
            return;
        }
        
        guard let curPage = self.currentPage,
            let contentHolderView = self.contentHolderView else {
                return;
        }
                
        action?.layer.backgroundColor =  UIColor.label.withAlphaComponent(0.04).cgColor
        action?.layer.cornerRadius = 8
        

        let settingsViewController = FTZoomSettingsViewController(nibName: "FTZoomSettingsViewController", bundle: nil);
        settingsViewController.delegate = self;
        settingsViewController.document = self.nsDocument;
        settingsViewController.currentPage = curPage;
        self.addChild(settingsViewController);
        settingsViewController.view.frame = contentHolderView.bounds;
        self.contentHolderView?.addSubview(settingsViewController.view);
        self.zoomSettingsViewController = settingsViewController;
        
        let endFrame = self.contentHolderView?.bounds ?? CGRect.zero;
        var startFrame = settingsViewController.view.frame;
        startFrame.origin.y -= startFrame.size.height;
        settingsViewController.view.frame = startFrame;
        
        UIView.animate(withDuration: 0.2) {
            settingsViewController.view.frame = endFrame;
        }
        self.zoomPanelController?.validateUI();
    }
    
    func dismissSettings() {
        guard let settingsViewController = self.zoomSettingsViewController,
            let contentHolderView = self.contentHolderView else {
                return;
        }
        
        let startFrame = contentHolderView.bounds;
        var endFrame = settingsViewController.view.frame;
        endFrame.origin.y -= startFrame.size.height;
        settingsViewController.view.frame = startFrame;
        UIView.animate(withDuration: 0.2,
                       animations: {[weak settingsViewController] in
                        settingsViewController?.view.frame = endFrame
                        
        }) { [weak settingsViewController] (_) in
            settingsViewController?.view.removeFromSuperview();
        }
        self.zoomSettingsViewController = nil;
        self.zoomPanelController?.validateUI();
    }
    
    private func snapViewFrameToNearest() {
        guard let localCache = self.nsDocument?.localMetadataCache else {
            return;
        }
        let oldHeight = localCache.zoomPalmRestHeight;
        if(oldHeight < 0) {
            let newHeight: CGFloat = 0;
            if(oldHeight > -FTZoomPanelConstant.overlayHeight*0.5) {
                UIView.animate(withDuration: 0.3) {
                    self.updateFrameIfNeeded();
                }
            }
            else {
                localCache.zoomPalmRestHeight = newHeight;
                self.zoomPanelDidTapOnPalmRest();
            }
        }
    }

    private func snapViewToExit() {
        guard let localCache = self.nsDocument?.localMetadataCache else {
            return
        }
        localCache.zoomPalmRestHeight = 0.0
        self.zoomPanelDidTapOnPalmRest()
    }

    private func updateFrameIfNeeded() {
        guard let localCache = self.nsDocument?.localMetadataCache else {
            return;
        }
        let oldHeight = localCache.zoomPalmRestHeight;
        let newHeight = clamp(oldHeight, 0, self.maxPalmPosition);
        if(newHeight != oldHeight) {
            localCache.zoomPalmRestHeight = newHeight;
            var newFrame = self.view.frame;
            newFrame.origin.y += (oldHeight - newHeight);
            let heightToSet = newFrame.size.height - oldHeight + newHeight;
            newFrame.size.height = heightToSet;
            self.view.frame = newFrame;
        }
        self.delegate?.zoomOverlayDidChangePanelFrame(self.view.frame,
                                                      pageController: self.currentPageController);
    }
}

//MARK: - FTZoomPanelViewControllerDataSource -
extension FTZoomOverlayViewController: FTZoomPanelViewControllerDataSource {
    var canUndo: Bool {
        return self.nsDocument?.undoManager.canUndo ?? false
    }
    
    var canRedo: Bool {
        return self.nsDocument?.undoManager.canRedo ?? false
    }
    
    var isShapeEnabled: Bool {
        return self.nsDocument?.localMetadataCache?.shapeDetectionEnabled ?? false;
    }
        
    var zoomPanelButtonPositionIsLeft: Bool {
        return self.nsDocument?.localMetadataCache?.zoomPanelButtonPositionIsLeft ?? true;
    }
    
    var isSettingsShown: Bool {
        if let zoomSettingsController = self.zoomSettingsViewController,!zoomSettingsController.isBeingDismissed {
            return true;
        }
        return false;
    }
}

//MARK: - FTZoomPanelViewControllerDelegate -
extension FTZoomOverlayViewController: FTZoomPanelViewControllerDelegate {
    func zoomPanelViewController(_ viewController: FTZoomPanelViewController,
                                 didTapOnView view: UIView,
                                 actionType: FTZoomPanelActionType) {
        if(actionType != .settings) {
            self.dismissSettings();
        }
        switch actionType {
        case .pen:
            self.penButtonAction(view)
        case .highlighter:
            self.highlighterButtonAction(view)
        case .eraser:
            self.eraserButtonAction(view)
        case .shape:
            self.shapeButtonAction(view)
        case .favorite:
            self.favoriteButtonAction(view)
        case .settings:
            self.settingsButtonAction(view as? UIButton)
        case .undo:
            self.delegate?.zoomPanelUndoTapped();
        case .redo:
            self.delegate?.zoomPanelRedoTapped();
        case .panLeft:
            self.zoomPanelPanLeft();
        case .panRight:
            self.lastStrokeInpactedRect = CGRect.null;
            self.zoomPanelPanRight();
        case .panNewLine:
            self.zoomPanelPanNewLineDown();
        case .palmResize:
            self.zoomPanelDidTapOnPalmRest();
        }
    }
    
    func zoomPanelViewControllerWillShowUndoOptions(_ viewController: FTZoomPanelViewController) {
        self.dismissSettings();
    }
    
    func zoomPanelHandleResizePanGesture(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            self.isWindowResizeInProgress = true;
            self.dismissSettings();
        case .changed:
            guard let localCache = self.nsDocument?.localMetadataCache else {
                return;
            }
            let translate = gesture.translation(in: self.view);
            gesture.setTranslation(CGPoint.zero, in: self.view);
            
            let oldHeight = localCache.zoomPalmRestHeight;

            var newHeight = oldHeight - translate.y;
            newHeight = clamp(newHeight, -FTZoomPanelConstant.overlayHeight, self.maxPalmPosition);

            localCache.zoomPalmRestHeight = newHeight;
            
            var newFrame = self.view.frame;
            newFrame.origin.y += (oldHeight - newHeight);
            let heightToSet = newFrame.size.height - oldHeight + newHeight;
            newFrame.size.height = heightToSet;
            self.view.frame = newFrame;
            self.delegate?.zoomOverlayWillChangePanelFrame(self.view.frame)
        case .ended,.cancelled:
            self.isWindowResizeInProgress = false
            if self.view.frame.height < 300.0 {
                let velocity = gesture.velocity(in: gesture.view)
                if velocity.y > 1000.0 {
                    self.delegate?.zoomOverlayDidChangePanelFrame(self.view.frame,
                                                                  pageController: self.currentPageController)
                    self.snapViewToExit()
                    return
                }
            }
            self.delegate?.zoomOverlayDidChangePanelFrame(self.view.frame,
                                                           pageController: self.currentPageController)
            self.snapViewFrameToNearest()
        default:
            break;
        }
    }
}

//MARK: - FTPenRackSelectDelegate,FTEraserRackControllerDelegate
extension FTZoomOverlayViewController: FTPenRackSelectDelegate, FTEraserRackControllerDelegate
{
    func didSelectPenSet(penSet: FTPenSet) {
        (self.delegate as? FTPenRackSelectDelegate)?.didSelectPenSet(penSet: penSet)
    }
    
    func didChooseClearPage(_ rackViewController: FTEraserRackViewController)
    {
        (self.delegate as? FTEraserRackControllerDelegate)?.didChooseClearPage?(rackViewController);
    }
}

//MARK: - ZoomSettingsViewControllerDelegate -
extension FTZoomOverlayViewController: FTZoomSettingsViewControllerDelegate {
    func zoomSettingsButtonsPositionChangedAction() {
        self.zoomPanelController?.layoutForcibly();
    }
    
    func zoomSettingsAutoAdvanceSettingsChanged(_ shouldShow: Bool) {
        self.zoomContentController?.validateUI();
    }
    
    func zoomSettingsMarginPositionChanged(_ newPosition: Int) {
        self.currentPage?.parentDocument?.localMetadataCache?.zoomLeftMargin = CGFloat(newPosition);
        self.updateZoomManagerViewAttributes(pageContentScale: self.currentPageController?.pageContentScale ?? 1);
    }
    
    func leftMarginMappedValue(forPercentage percentage: Int) -> CGFloat {
        if let pageRect = self.currentPage?.pdfPageRect {
            return pageRect.size.width * CGFloat(percentage) * 0.01;
        }
        return 10;
    }
    
    func zoomSettingsDidChangeLineHeight(_ newLineHeight: Int) {
        self.zoomContentController?.lineHeight = CGFloat(newLineHeight);
        self.updateZoomManagerViewAttributes(pageContentScale: self.currentPageController?.pageContentScale ?? 1);
    }
}

//MARK: - FTZoomContentViewControllerDelegate -
extension FTZoomOverlayViewController: FTZoomContentViewControllerDelegate
{
    func zoomContentViewController(_ viewController: FTZoomContentViewController,
                                   didChangeAutoScrollWidth width: Int)
    {
        self.nsDocument?.localMetadataCache?.zoomAutoscrollWidth = width;
    }
    
}

//MARK: - FTZoomContentViewControllerDataSource -
extension FTZoomOverlayViewController: FTZoomContentViewControllerDataSource {
    var noteshelfDocument: FTDocumentProtocol? {
        return self.nsDocument;
    }

    var mainRenderViewController: FTPDFRenderViewController? {
        return self.mainDocumentRenderController;
    }
}

class FTZoomOverlayView: UIView {
    weak var contentHolderView: UIView?
    weak var pdfRenderVc: UIViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return super.hitTest(point, with: event)
    }
}
