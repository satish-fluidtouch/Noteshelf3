//
//  FTDocumentScrollView.swift
//  Noteshelf
//
//  Created by Amar on 04/03/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

enum FTScrollViewMode: Int {
    case none,scroll,zoom;
}

 enum FTScrollVelocityThreshold : CGFloat {
     case left = -1000
     case right = 1000;
}

@objc protocol FTScrollViewDelegate : UIScrollViewDelegate {
    func canAcceptTouch(for gesture:UIGestureRecognizer) -> Bool;
    func currentPageScrollView() -> UIScrollView?;

    func isInZoomMode() -> Bool;
    
    func scrollViewDidEndPanningPage();
    
    func frame(for page:Int) -> CGRect;
    func page(for point:CGPoint) -> Int;
    func moveToNextPage(_ currentPage : Int) -> Int;
    func moveToPreviousPage(_ currentPage : Int) -> Int;
    func viewDidZoom()
}

@objcMembers class FTDocumentScrollView: FTCenterContentScrollView {
    weak var scrollViewDelegate : FTScrollViewDelegate?
    private var scrollViewMode: FTScrollViewMode = .none;
    private var scaleJump: Int = 0;
    private weak var pageHolderView: UIView?;
    var isProgramaticallyZooming: Bool = false
    private var canScrollToNewPage: Bool = false
    
    override weak var delegate: UIScrollViewDelegate? {
        didSet {
            if let del = self.delegate, !(del is FTDocumentScrollView) {
                fatalError("delegate should be FTDocumentScrollView");
            }
        }
    }
    
    private lazy var panGesture : FTPanGestureRecognizer = {
        let gesture = FTPanGestureRecognizer(target: self, action: #selector(FTDocumentScrollView.handleFTPanGesture(_:)));
        self.addGestureRecognizer(gesture);
        self.scrollViewPanGesture.require(toFail: gesture);
        return gesture;
    }();
     
    var scrollViewPanGesture: UIPanGestureRecognizer {
        return self.panGestureRecognizer;
    }
        
    private lazy var pinchGesture : UIPinchGestureRecognizer = {
        let gesture = UIPinchGestureRecognizer(target: self, action: #selector(FTDocumentScrollView.handlePinchGesture(_:)));
        self.addGestureRecognizer(gesture);
        self.pinchGestureRecognizer?.require(toFail: gesture);
        return gesture;
        
    }();
    private var refreshControllers = [FTRefreshViewController]();
    
    private var lastTranslationPoint : CGPoint = .zero;
    private var layoutType = FTPageLayout.horizontal;
    private var currentpage: Int = 0;
    private var previousScrollviewScale: CGFloat = 1;
    
    private var zoomAnimationCompletionBlock: (()->())?;

    var position: [FTRefreshPosition] = [.top, .bottom]
    weak var layOutDelegate: FTRefreshSelectedItemDelegate?

    override var zoomFactor: CGFloat {
        get {
            return previousScrollviewScale;
        }
        set {
            previousScrollviewScale =  newValue;
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame);
        self.initialize();
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder);
        self.initialize();
    }
    
    func addPageView(_ view: UIView) {
        self.pageHolderView?.addSubview(view);
    }
    
    var isZoomingInProgress: Bool {
        guard let contentView = self.contentHolderView else {
            return false;
        }
        
        if self.isZoomBouncing
            || self.isZooming
        || contentView.transform != .identity {
            return true;
        }
        return false;
    }
    
    func updateContentHolderViewSize(_ size: CGSize)
    {
        //https://www.notion.so/fluidtouch/Page-is-not-centred-when-finder-is-opened-side-by-side-in-landscape-mode-with-portrait-page-and-docu-522615ed9f704a508c18e9305f41d382?pvs=4
        self.contentHolderView?.frame = CGRect(origin: self.contentHolderView?.frame.origin ?? .zero, size: size);
        var contentSize = size;
        contentSize.width = max(size.width,self.frame.width);
        contentSize.height = max(size.height,self.frame.height);
        self.contentSize = contentSize;
    }
    
    func enablePanDetection(_ allowsFreeScrolling : Bool) {
        self.scrollViewPanGesture.isEnabled = true;
        self.panGesture.isEnabled = true;

        if allowsFreeScrolling {
            self.panGesture.maxNumberOfTouches = 0;
            self.scrollViewPanGesture.minimumNumberOfTouches = 1;
        }
        else {
            self.panGesture.maxNumberOfTouches = 2;
            self.scrollViewPanGesture.minimumNumberOfTouches = 2;
        }
        self.unlockZoom();
    }
    
    func disablePanDetection() {
        self.panGesture.isEnabled = false;
        self.scrollViewPanGesture.isEnabled = false;
        self.lockZoom();
    }
    
    func disableNewPageCreationOptions(){
        for eachRefreshController in self.refreshControllers {
            eachRefreshController.isInReadOnlyMode = true
            //_ = eachRefreshController.hideNewPageOptions();
        }
    }
    
    func enableNewPageCreationOptions(){
        for eachRefreshController in self.refreshControllers {
            eachRefreshController.isInReadOnlyMode = false
           // _ = eachRefreshController.showNewPageOptions();
        }
    }
    
    func setRefreshPositions(_ position : [FTRefreshPosition],
                             delegate : FTRefreshSelectedItemDelegate) {
        self.position = position
        self.layOutDelegate = delegate
        deallocateAllRefreshViewControllers()
        position.forEach { direction in
            if let del = layOutDelegate, let controller = FTRefreshViewController.initialise(with: self, scrollDirection: direction, delegate: del) {
                self.refreshControllers.append(controller);
            }
        }
    }

    func addRefreshView(position: FTRefreshPosition) {
        var addView = true
        self.refreshControllers.forEach { (refreshVC) in
            let vc = refreshVC
            if vc.scrollDirection == position {
                addView = false
                return
            }
        }

        if addView, let del = layOutDelegate, let controller = FTRefreshViewController.initialise(with: self, scrollDirection: position, delegate: del) {
            self.refreshControllers.append(controller)
        }
    }
    
    private func deallocateAllRefreshViewControllers() {
        self.contentInset = .zero
        self.refreshControllers.forEach { (refreshVC) in
            refreshVC.view.removeFromSuperview()
        }
        self.refreshControllers.removeAll()
    }
    
    func setPageLayoutType(_ type : FTPageLayout) {
        self.setLayoutType(type, force: false);
    }
    
    override var maximumSupportedZoomScale: CGFloat {
        return 6;
    }
    
    private var _miniumSupportedZoomScale: CGFloat = 1;
    override var miniumSupportedZoomScale: CGFloat {
        get {
            return _miniumSupportedZoomScale
        }
        set {
            _miniumSupportedZoomScale = newValue;
        }
    }
        
    func zoom(_ inScale : CGFloat,animate : Bool,completionBlock : (() -> ())?)
    {
        let minZoomScale = self.miniumSupportedZoomScale;
        let maxZoomScale = self.maximumSupportedZoomScale;

        let scale = max(min(inScale,maxZoomScale),minZoomScale);
        
        if(fabsf(Float(self.zoomFactor - scale)) < 0.001) {
            completionBlock?();
            return;
        }
        self.zoomAnimationCompletionBlock = completionBlock;
        let percentageOfZoom = (scale/(maxZoomScale-minZoomScale));
        
        let maxZoom = self.maximumZoomScale;
        let minZoom = self.minimumZoomScale;
        
        let value = percentageOfZoom*(maxZoom-minZoom);
        self.setZoomScale(value, animated: animate);
        if(!animate) {
            self.delegate?.scrollViewDidEndZooming?(self,
                                                    with: self.contentHolderView,
                                                    atScale: value);
        }
    }
    
    func zoomTo(_ zoomPoint: CGPoint, scale inScale: CGFloat, animate: Bool,onCompletion: (() -> ())?) {
        guard abs(1-inScale) > 0.01 else {
            onCompletion?();
            return;
        }
        let minZoomScale = self.miniumSupportedZoomScale;
        let maxZoomScale = self.maximumSupportedZoomScale;

        let scale = max(min(inScale,maxZoomScale),minZoomScale);
        
        if(fabsf(Float(self.zoomFactor - scale)) < 0.01) {
            onCompletion?();
            return;
        }
        self.zoomAnimationCompletionBlock = onCompletion;
        self.zoomTo(zoomPoint, scale: inScale, animate: animate);
    }
    
    override func zoomTo(_ zoomPoint: CGPoint, scale inScale: CGFloat, animate: Bool) {
        self.isProgramaticallyZooming = true;
        super.zoomTo(zoomPoint, scale: inScale, animate: animate);
    }
}

//MARK- Private Methods -
private extension FTDocumentScrollView
{
    func addPageView() {
        guard let _contentView = self.contentHolderView else {
            return;
        }
        let view = UIView.init(frame: _contentView.bounds);
        view.autoresizingMask = [.flexibleWidth,.flexibleHeight];
        _contentView.addSubview(view);
        self.pageHolderView = view;
    }

    func initialize()
    {
        self.addPageView();
        self.maximumZoomScale = self.maximumSupportedZoomScale
        self.minimumZoomScale = self.miniumSupportedZoomScale
        
        self.scrollsToTop = false;
        self.delaysContentTouches = false;
        self.isPagingEnabled = false;

        self.showsHorizontalScrollIndicator = false;
        self.showsVerticalScrollIndicator = false;
        
        self.scrollViewPanGesture.maximumNumberOfTouches = 2;
        self.scrollViewPanGesture.minimumNumberOfTouches = 2;
        self.scrollViewPanGesture.cancelsTouchesInView = true;
        self.scrollViewPanGesture.delaysTouchesEnded = false;
        self.scrollViewPanGesture.delegate = self;
        
        self.panGesture.delegate = self;
        self.panGesture.cancelsTouchesInView = false;
        self.panGesture.delaysTouchesEnded = false;
        
        self.setLayoutType(.horizontal, force: true);
        self.delegate = self;
        
//        self.decelerationRate = .fast;
    }
        
    func setLayoutType(_ type : FTPageLayout,force : Bool) {
        if(self.layoutType != type || force) {
            self.layoutType = type;
            switch type {
            case .horizontal:
                self.scrollViewPanGesture.addTarget(self, action: #selector(FTDocumentScrollView.handleHorizontalPanGesture(_:)))
                self.scrollViewPanGesture.removeTarget(self, action: #selector(FTDocumentScrollView.handleVerticalPanGesture));
                self.alwaysBounceHorizontal = true;
                self.alwaysBounceVertical = false;
                
                self.lockZoom()
            case .vertical:
                self.scrollViewPanGesture.addTarget(self, action: #selector(FTDocumentScrollView.handleVerticalPanGesture))
                self.scrollViewPanGesture.removeTarget(self, action: #selector(FTDocumentScrollView.handleHorizontalPanGesture(_:)));
                self.alwaysBounceHorizontal = false;
                self.alwaysBounceVertical = true;
                
                self.unlockZoom();
            }
        }
    }
    
    @objc func handlePinchGesture(_ gesture:UIPinchGestureRecognizer)
    {
        switch gesture.state {
        case .began:
            scaleJump = 0;
            self.scheduleDisablePinchGesture();
        case .recognized,.changed:
            scaleJump += 1;
            let scale = fabsf(Float(gesture.scale - 1));
            if scale > 0.3 , scaleJump > 3, self.scrollViewMode == .none {
                debugLog(">> Pinch In Progress");
                self.cancelDisablePinchGesture();
                self.scrollViewMode = .zoom;
                self.pinchGesture.isEnabled = false;
                self.panGesture.isEnabled = false;
                enableAndDisableNewPageRefreshControls()
            }
        default:
            break;
        }
    }
    
    private func enableAndDisableNewPageRefreshControls() {
        if self.scrollViewMode == .zoom {
            for eachRefreshController in self.refreshControllers {
                eachRefreshController.hideNewPageOptions();
            }
        } else {
            for eachRefreshController in self.refreshControllers {
                eachRefreshController.showNewPageOptions();
            }
        }
    }
    
    @objc private func delayedPinchGesture()
    {
        self.lockZoom()
    }

    private func cancelDisablePinchGesture()
    {
        NSObject.cancelPreviousPerformRequests(withTarget: self,
                                               selector: #selector(delayedPinchGesture),
                                               object: nil);
    }
    
    private func scheduleDisablePinchGesture()
    {
        self.perform(#selector(delayedPinchGesture),
                     with: nil,
                     afterDelay: 0.5);
    }

    @objc func handleFTPanGesture(_ gesture:UIGestureRecognizer)
    {
        if gesture.state == .failed
            , self.scrollViewMode == .none
            , !UserDefaults.isApplePencilEnabled() {
            self.lockZoom();
            debugLog(">> ScrollPan: handleFTPanGesture: failed");
        }
    }
}

//MARK- Gesture Actions -
private extension FTDocumentScrollView
{
    private func lockZoom()
    {
        self.pinchGesture.isEnabled = false
        self.pinchGestureRecognizer?.isEnabled = false;
    }
    
    private func unlockZoom()
    {
        self.scrollViewMode = .none;
        if(self.layoutType == .vertical) {
            self.pinchGesture.isEnabled = true
            self.pinchGestureRecognizer?.isEnabled = true;
        }
    }

    @objc func handleVerticalPanGesture(_ gesture:UIPanGestureRecognizer)
    {
        switch gesture.state {
        case .changed:
            self.canScrollToNewPage = false
           // if !self.isDecelerating && isScrolling {
                let yOffset = self.contentOffset.y
                if yOffset >= contentSize.height - self.frame.height {
                    //bottom last page
                    self.canScrollToNewPage = true
                    self.addRefreshView(position: .bottom)
                } else if yOffset < FTVerticalLayout.firstPageOffsetY {
                    //top first page
                    self.canScrollToNewPage = true
                    self.addRefreshView(position: .top)
                } else {
                    deallocateAllRefreshViewControllers()
                }
            //}
        case .ended:
            if self.canScrollToNewPage {
                for eachRefreshController in self.refreshControllers {
                    eachRefreshController.handleGesture(gesture);
                }
            }
        default:
            break
        }
    }
    
    @objc func handleHorizontalPanGesture(_ gesture:UIPanGestureRecognizer)
    {
        //debugLog("handlePanGesture State: \(gesture.state.rawValue)");
        
        for eachRefreshController in self.refreshControllers {
            _ = eachRefreshController.handleGesture(gesture);
        }
        switch gesture.state {
        case .began:
            self.currentpage = self.scrollViewDelegate?.page(for: self.contentOffset) ?? -1;
            if (self.contentOffset.x > (self.contentSize.width - self.frame.width)) || (self.contentOffset.x < 0.0) {
                return
            }
            gesture.setTranslation(CGPoint.zero, in: self);
            lastTranslationPoint = CGPoint.zero;
        case .changed:
            if (self.contentOffset.x > (self.contentSize.width - self.frame.width)) || (self.contentOffset.x < 0.0) {
                return
            }
            let translation = gesture.translation(in: gesture.view);
            if(translation != CGPoint.zero) {
                lastTranslationPoint = translation;
            }
            
            var currenOffset = self.contentOffset;
            currenOffset.x -= translation.x;
            let maxOffsetWidth = self.frame.size.width / 2;
            
            currenOffset.x = max(currenOffset.x, -maxOffsetWidth);
            currenOffset.x = min(currenOffset.x, self.contentSize.width-self.frame.size.width + maxOffsetWidth);
            self.setContentOffset(currenOffset, animated: false);
            
            gesture.setTranslation(CGPoint.zero, in: self);
        case .ended,.cancelled:
            #if !targetEnvironment(macCatalyst)
            if (self.contentOffset.x > (self.contentSize.width - self.frame.width)) || (self.contentOffset.x < 0.0) {
                self.scrollViewDelegate?.scrollViewDidEndPanningPage();
                return
            }
            #endif
            var page = self.scrollViewDelegate?.page(for: self.contentOffset) ?? self.currentpage;
            let velocity = gesture.velocity(in: gesture.view);
            if(velocity.x < FTScrollVelocityThreshold.left.rawValue
                && lastTranslationPoint.x < 0) {
                page = self.scrollViewDelegate?.moveToNextPage(self.currentpage) ?? -1;
            }
            else if(velocity.x > FTScrollVelocityThreshold.right.rawValue
                && lastTranslationPoint.x > 0) {
                page = self.scrollViewDelegate?.moveToPreviousPage(self.currentpage) ?? -1;
            }
            if page != -1, let pageFrame = self.scrollViewDelegate?.frame(for: page) {
                var newOffset = self.contentOffset;
                newOffset.x = pageFrame.origin.x;
                UIView.animate(withDuration: 0.2,
                               delay: 0,
                               options: .allowUserInteraction,
                               animations: {
                                self.setContentOffset(newOffset, animated: false);
                }) { (_) in
                    self.delegate?.scrollViewDidEndScrollingAnimation?(self);
                }
            }
            self.scrollViewDelegate?.scrollViewDidEndPanningPage();
        default:
            break;
        }
    }
}

//MARK- UIGestureRecognizerDelegate -
extension FTDocumentScrollView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var canAccept = true
        if(gestureRecognizer == self.scrollViewPanGesture ||
            gestureRecognizer == self.panGesture) {
            if(touch.majorRadius >= CGFloat(majorRadiusThresholdForGestures)) {
                canAccept = false;
            }
        }
        return canAccept;
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        var canBegin = super.gestureRecognizerShouldBegin(gestureRecognizer);
        let _panGestureRecognizer = self.scrollViewPanGesture;
        
        if(gestureRecognizer == _panGestureRecognizer) {
            canBegin = self.scrollViewDelegate?.canAcceptTouch(for: gestureRecognizer) ?? false;
            if (canBegin) {
                if let insideScrolLView = self.scrollViewDelegate?.currentPageScrollView() {
                    let translation = _panGestureRecognizer.translation(in: _panGestureRecognizer.view);
                    if(translation.x > 0) {
                        //swiping left
                        if(insideScrolLView.contentOffset.x >= 20) {
                            canBegin = false;
                        }
                    }
                    else {
                        //swiping right
                        let maxX = Int(insideScrolLView.contentSize.width - insideScrolLView.frame.width);
                        if(insideScrolLView.contentOffset.x < CGFloat(maxX)) {
                            canBegin = false;
                        }
                    }
                } else if self.contentOffset.x < 0 {
                    canBegin = true;
                } else if self.contentOffset.x <= self.contentSize.width {
                    canBegin = true;
                }
                else {
                    canBegin = false;
                }
            }
        }
        else if(gestureRecognizer == self.panGesture) {
            canBegin = self.scrollViewDelegate?.canAcceptTouch(for: gestureRecognizer) ?? false;
        }
        else if(gestureRecognizer == self.pinchGestureRecognizer) {
            canBegin = self.scrollViewDelegate?.canAcceptTouch(for: gestureRecognizer) ?? false;
        }
        return canBegin;
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true;
    }
}

extension FTDocumentScrollView: UIScrollViewDelegate
{
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        if(self.layoutType == .vertical && !(self.scrollViewDelegate?.isInZoomMode() ?? false)) {
            self.scrollViewDelegate?.viewDidZoom()
            return self.contentHolderView;
        }
        else {
            return nil;
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.unlockZoom();
        self.scrollViewDelegate?.scrollViewDidEndScrollingAnimation?(scrollView);
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.scrollViewMode = .scroll;
        self.scrollViewDelegate?.scrollViewWillBeginDragging?(scrollView);
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.unlockZoom();
        self.scrollViewDelegate?.scrollViewDidEndDecelerating?(scrollView);
        self.scrollViewDelegate?.scrollViewDidEndPanningPage();
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if(!decelerate) {
            self.unlockZoom();
        }
        self.scrollViewDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate);
        
        if(!decelerate) {
            self.scrollViewDelegate?.scrollViewDidEndPanningPage();
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.scrollViewDelegate?.scrollViewDidScroll?(scrollView);
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if let zoomingView = contentHolderView, isProgramaticallyZooming {
            scrollView.centerContentHolderView(zoomingView);
        }
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        self.isProgramaticallyZooming = false
        guard let contentHolderView = self.contentHolderView else {
            return;
        }
        let newScale = scale * self.zoomFactor;
        if(newScale != self.zoomFactor) {
            self.zoomFactor = newScale;
            self.minimumZoomScale /= scale;
            self.maximumZoomScale /= scale;
            
            var frame = contentHolderView.frame;
            frame.origin = CGPoint.zero;
            
            contentHolderView.transform = CGAffineTransform.identity;
            contentHolderView.frame = frame;

            self.scrollViewDelegate?.scrollViewDidEndZooming?(scrollView, with: view, atScale: scale);
        }
        var contentSize = scrollView.contentSize;
        if contentSize.width < scrollView.frame.width 
            || contentSize.height < scrollView.frame.height {
            contentSize.width = max(contentSize.width, scrollView.frame.width);
            contentSize.height = max(contentSize.height, scrollView.frame.height);
            scrollView.contentSize = contentSize;
            scrollView.centerContentHolderView(contentHolderView);
        }
        self.unlockZoom();
        enableAndDisableNewPageRefreshControls()
        self.zoomAnimationCompletionBlock?();
        self.zoomAnimationCompletionBlock = nil;
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let offset = targetContentOffset.pointee.y
        var nearstOffsetY: CGFloat = offset
        if self.layoutType == .vertical {
            if !self.canScrollToNewPage {
                if offset <= 0.0 {
                    nearstOffsetY = 0.0
                } else {
                    let contentSize = scrollView.contentSize
                    let contentHeight = max(contentSize.height,scrollView.frame.height);
                    let maxY = contentHeight - scrollView.frame.height;
                    if(offset > maxY) {
                        nearstOffsetY = contentSize.height - scrollView.frame.height
                    }
                }
                if offset != nearstOffsetY {
//                    targetContentOffset.pointee.y = CGFloat(nearstOffsetY)
                }
            }
        }
    }
}
