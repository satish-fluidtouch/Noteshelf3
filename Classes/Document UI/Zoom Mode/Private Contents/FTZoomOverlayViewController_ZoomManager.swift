//
//  FTZoomOverlayViewController_ZoomManager.swift
//  Noteshelf
//
//  Created by Amar on 12/05/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

internal extension FTZoomOverlayViewController {
    var zoomTargetRect: CGRect {
        get {
            var rectToScale = self.zoomManagerView.targetRect;
            rectToScale = self.zoomManagerView.convert(rectToScale, to: self.currentPageController?.contentHolderView);
            return rectToScale;
        }
        set {
            var rectToScale = newValue;
            rectToScale = self.zoomManagerView.convert(rectToScale, from: self.currentPageController?.contentHolderView);
            guard !rectToScale.hasInfiniteEntries else {
                FTCLSLog("Zoom Rect Infitie: \(rectToScale) -- \(newValue)");
                return;
            }
            
            if(self.zoomManagerView.targetRect.integral != rectToScale.integral) {
                let curTargetRect = self.zoomManagerView.targetRect;
                self.zoomManagerView.targetRect = rectToScale;
                if(!self.zoomManagerView.isMoving) {
                    if(self.zoomRectUpdateInProgress) {
                        FTCLSLog("Zoom Rect issue: \(curTargetRect) -- \(rectToScale)");
                    }
                    self.zoomRectUpdateInProgress = true;
                    self.didMovedRect(self.zoomManagerView);
                    self.didFinishMoving(self.zoomManagerView);
                    self.zoomRectUpdateInProgress = false;
                }
                self.updateZoomOriginForCurrentPage();
            }
        }
    }

    func updateZoomOriginForCurrentPage() {
        if let curPage = self.currentPage,
            let curPageController = self.currentPageController,
            let contentView = curPageController.contentHolderView {
            let rect = self.mapRect(self.zoomTargetRect, within: contentView);
            
            let pageContentScale = curPageController.pageContentScale;
            let scaledOrigin = CGPoint.scale(rect.origin, 1/pageContentScale);
            curPage.zoomTargetOrigin = scaledOrigin;
            self.nsDocument?.localMetadataCache?.setZoomOrigin(scaledOrigin, for: curPage.pageIndex());
        }
    }
    
    func refreshZoomTargetRect(forcibly: Bool) {
        if let page = self.currentPage,
            let pageController = self.currentPageController,
            let contentView = pageController.contentHolderView {
            
            var pageOrigin = page.zoomTargetOrigin;
            pageOrigin = CGPoint.scale(pageOrigin, pageController.pageContentScale)
            pageOrigin.x = max(pageOrigin.x,self.leftMargin);
            
            var targetRect = self.zoomTargetRect;
            targetRect.origin = pageOrigin;
            
            targetRect = self.mapRect(targetRect, within: contentView);

            if(forcibly) {
                let rectToScale = self.zoomManagerView.convert(targetRect, from: contentView);
                self.zoomManagerView.targetRect = rectToScale;
            }
            
            self.zoomTargetRect = targetRect;
            self.updateZoomAreaSize();
        }
    }
    
    func addZoomScrollViewNotificationObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didFinishZoom(_:)),
                                               name: NSNotification.Name(rawValue: FTZoomRenderViewDidFinishSizing),
                                               object: nil);
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didFinishScroll(_:)),
                                               name: NSNotification.Name(rawValue: FTZoomRenderViewDidFinishMoving),
                                               object: nil);
        
        NotificationCenter.default.addObserver(forName: .pageLayoutDidChange,
                                               object: nil,
                                               queue: nil)
        { [weak self] (_) in
            self?.removeZoomManagerView()
            self?.currentPageControllerDidChanged();
       }
        
         NotificationCenter.default.addObserver(forName: .pageLayoutWillChange,
                                                object: nil,
                                                queue: nil)
         { [weak self] (_) in
             self?.updateZoomOriginForCurrentPage()
        }

    }

    func addZoomManagerView(to pageVC: FTPageViewController) {
        if self.delegate?.pageLayoutType() == .vertical {
            if nil == self.zoomManagerView.superview,
               let scrollView = self.mainRenderViewController?.mainScrollView,
                let _contentView = scrollView.contentHolderView {
                let pagebounds = _contentView.bounds;
                self.zoomManagerView.frame = pagebounds;
                _contentView.addSubview(self.zoomManagerView);
                self.zoomManagerView.setScrollView(scrollView);
            }
        }
        else {
            self.removeZoomManagerView()
            if let _contentView = pageVC.contentHolderView {
                let pagebounds = _contentView.bounds;
                self.zoomManagerView.frame = pagebounds;
                _contentView.addSubview(self.zoomManagerView);
            }
        }

        self.updateZoomManagerViewAttributes(pageContentScale:pageVC.pageContentScale);
    }
    
    func removeZoomManagerView() {
        self.zoomManagerView.removeFromSuperview();
    }

    func updateZoomTargetRect() {
        self.updateZoomArea(size: true, origin: true);
        self.delegate?.zoomOverlayScrollTo(targetRect: self.zoomTargetRect,
                                           pageController: self.currentPageController);
    }

    func updateZoomManagerViewAttributes(pageContentScale : CGFloat)
    {
        if let pdfPage = self.currentPage {
            zoomManagerView.lineHeight = CGFloat(pdfPage.lineHeight) * pageContentScale;
            zoomManagerView.leftZoomMargin = self.leftMargin;
        }
    }
    
    func willEnterZoomMode() {
        self.zoomManagerRectSized(self.zoomManagerView);
        self.didFinishSizing(self.zoomManagerView,animate: false,forcibly: false);
        self.zoomContentController?.validateUI();
    }

    func updateZoomAreaSize() {
        self.updateZoomArea(size: true, origin: false);
        self.zoomContentController?.validateUI();
    }
    
    func mapRect(_ rect: CGRect,within view:UIView) -> CGRect {
        let bounds = view.bounds;
        var zoomRect = rect;
        zoomRect.origin.x = clamp(zoomRect.origin.x, 0, max(bounds.size.width - zoomRect.size.width,0));
        zoomRect.origin.y = clamp(zoomRect.origin.y, 0, max(bounds.size.height - zoomRect.size.height,0));
        return zoomRect;
    }
}

//MARK:- Notification Observers -
private extension FTZoomOverlayViewController {
    @objc func didFinishZoom(_ notification: Notification)
    {
        if let notWindow = notification.object as? UIWindow,
            self.view.window == notWindow,

            let zoomFactor = notification.userInfo?["zoomFactor"] as? CGFloat {
            if(self.zoomFactor != zoomFactor) {
                self.zoomFactor = zoomFactor;
                self.nsDocument?.localMetadataCache?.zoomFactor = self.zoomFactor;
                self.updateZoomTargetRect();
            }
            self.zoomContentController?.validateUI();
        }
    }

    @objc func didFinishScroll(_ notification: Notification)
    {
        if let notWindow = notification.object as? UIWindow,
            self.view.window == notWindow {
            
            self.updateZoomArea(size: false, origin: true);
            self.delegate?.zoomOverlayScrollTo(targetRect: self.zoomTargetRect,
                                               pageController: self.currentPageController);
        }
    }
}

//MARK:- FTZoomManagerViewDelegate -
extension FTZoomOverlayViewController: FTZoomManagerViewDelegate {
    private func _zoomManagerRectMoved(_ managerView:FTZoomManagerView,point:CGPoint) {
        var zoomRect = managerView.targetRect;
        zoomRect.origin.x = max(zoomRect.origin.x,0);
        zoomRect.origin.y = max(zoomRect.origin.y,0);
        
        if let contr = self.mainRenderViewController?.pageController(point),
            let page = contr.pdfPage,self.currentPageController != contr {
            self.updateZoomOriginForCurrentPage();
            self.setCurrentPage(page, pageController: contr);
            let rectToScale = managerView.convert(zoomRect, to: contr.contentHolderView);
            self.zoomTargetRect = rectToScale;
            self.updateZoomScale();

            self.didFinishSizing(managerView, animate: false,forcibly: true);
        }
        else {
            self.didMovedRect(zoomManagerView);
        }
    }

    func zoomManagerRectMoved(_ managerView:FTZoomManagerView,point:CGPoint) {
        self._zoomManagerRectMoved(managerView, point: point);
        if(managerView.isMoving) {
            self.setUpAutoScroll();
        }
    }
    
    func zoomManagerRectSized(_ managerView: FTZoomManagerView) {
        self.updateZoomScale();
        self.updateZoomAreaSize();
    }
    
    func zoomManagerDidFinishSizing(_ managerView: FTZoomManagerView) {
        guard let curPageController = self.currentPageController,
            let contentView = curPageController.contentHolderView else {
                return;
        }
        self.zoomTargetRect = self.mapRect(self.zoomTargetRect, within: contentView);

        self.didFinishSizing(managerView, animate: true,forcibly: false);
    }
    
    func zoomManagerDidFinishMoving(_ managerView: FTZoomManagerView) {
        self.invalidatesScrollTimer();
        self.didFinishMoving(managerView);
    }
    
    func zoomManager(_ managerView: FTZoomManagerView, didTapAt point: CGPoint) {
        
    }
    
    func didMovedRect(_ managerView: FTZoomManagerView)
    {
        guard let pageVC = self.currentPageController else {
            return;
        }
        var rectToScale = self.zoomTargetRect;
        rectToScale = CGRect.scale(rectToScale, 1/pageVC.pageContentScale)
        self.contentOffset = CGPoint.scale(rectToScale.origin, self.pageContentScale);
        self.updateZoomOriginForCurrentPage();
        
    }
    
    func didFinishMoving(_ managerView: FTZoomManagerView) {
        guard let curPageController = self.currentPageController,
            let contentView = curPageController.contentHolderView else {
                return;
        }
        self.zoomTargetRect = self.mapRect(self.zoomTargetRect, within: contentView);
        self.updateZoomAreaSize()
        self.delegate?.zoomOverlayScrollTo(targetRect: self.zoomTargetRect,
                                           pageController: self.currentPageController);
    }

}

private extension FTZoomOverlayViewController {

    private func didFinishSizing(_ managerView: FTZoomManagerView,animate:Bool,forcibly:Bool) {
        let diffScale = self.targetRectScale;

        var targetRect = self.zoomTargetRect;
        targetRect = CGRect.scale(targetRect, 1/diffScale);

        let center = CGPoint(x: targetRect.midX, y: targetRect.midY);
        self.zoomFrom(center: center, animate: animate,forcibly: forcibly);
    }

    private func updateZoomScale() {
        let width = self.contentFrame.width;
        var zoomFactorToApply = self.zoomFactor;
        
        let diffScale = self.targetRectScale;
        let curTargetRect = self.zoomTargetRect;
        var targetRect = curTargetRect;
        targetRect = CGRect.scale(targetRect, 1/diffScale);

        if(curTargetRect.size.width > 0) {
            zoomFactorToApply = width/targetRect.size.width;
        }
        
        self.zoomFactor = clamp(zoomFactorToApply, FTPDFScrollView.minZoomScale(FTRenderModeZoom), FTPDFScrollView.maxZoomScale(FTRenderModeZoom));
        
        self.nsDocument?.localMetadataCache?.zoomFactor = self.zoomFactor;
    }

}
//MARK:- private -
private extension FTZoomOverlayViewController {
    var targetRectScale: CGFloat {
        guard let pageContent = self.currentPageController?.contentHolderView else {
            return 1;
        }
        let visibleArea = self.contentFrame;
        let zoomBounds = pageContent.bounds;
        
        let diffScale = zoomBounds.width/visibleArea.width;
        return diffScale;
    }
    
    func updateZoomArea(size: Bool,origin: Bool)  {
        guard let pageContent = self.currentPageController?.contentHolderView else {
            return;
        }
        let visibleArea = self.contentFrame;
        let scale = self.zoomFactor;
        
        var targetRect = self.zoomTargetRect;
        let zoomBounds = pageContent.bounds;
        
        let diffScale = self.targetRectScale;
        let mapScale = diffScale/scale;

        if(origin) {
            let currentContentOffset = self.contentOffset;
            targetRect.origin = CGPoint.scale(currentContentOffset, mapScale);
        }
        if(size) {
            targetRect.size = CGSize(width: visibleArea.width * mapScale,
                                     height: visibleArea.height * mapScale);
        }
        
        targetRect.size.height = min(targetRect.size.height,zoomBounds.size.height);        
        var newX = min(targetRect.origin.x,
                       zoomBounds.width - visibleArea.width * mapScale);
        newX = max(0, newX);
        
        var newY = min(targetRect.origin.y,
                       zoomBounds.height - targetRect.height);
        newY = max(0, newY);
        targetRect.origin = CGPoint(x: newX, y: newY);
        self.zoomTargetRect = targetRect;
    }
}

enum FTScrollDirection: Int {
    case none,up,down;
}

private extension  CADisplayLink {
    var direction: FTScrollDirection {
        get {
            let value = self.ft_userInfo["Direction"] as? FTScrollDirection;
            return value ?? FTScrollDirection.none;
        }
        set {
            self.ft_userInfo = ["Direction" : newValue];
        }
    }
}

private extension FTZoomOverlayViewController {
    //autoScroll
    static var displayLink: CADisplayLink?
    var displayLink : CADisplayLink? {
        get {
            return FTZoomOverlayViewController.displayLink;
        }
        set {
            FTZoomOverlayViewController.displayLink = newValue;
        }
    }
    
    func invalidatesScrollTimer() {
        self.displayLink?.invalidate();
        self.displayLink = nil;
    }

    func setUpAutoScroll() {
        guard let mainScrollView = self.mainRenderViewController?.mainScrollView,
            self.delegate?.pageLayoutType() == .vertical else {
                invalidatesScrollTimer();
                return;
        }
        let targetRect = self.zoomManagerView.targetRect;
        
        var visibleRect = mainScrollView.visibleRect;
        visibleRect.size.height -= mainScrollView.contentInset.bottom;
        
        if(targetRect.maxY > visibleRect.maxY) {
            self.setupScrollTimerIn(direction: .down);
        }
        else if(targetRect.minY < visibleRect.minY) {
            self.setupScrollTimerIn(direction: .up);
        }
        else {
            invalidatesScrollTimer();
        }
    }
    
    func setupScrollTimerIn(direction : FTScrollDirection) {
        if let displayLink = self.displayLink,
            !displayLink.isPaused,
            displayLink.direction == direction {
            return;
        }
        self.invalidatesScrollTimer();
        let link = CADisplayLink(target: self, selector: #selector(self.triggerDisplayLink(_:)))
        link.direction = direction;
        self.displayLink = link;
        self.displayLink?.add(to: .main, forMode: .default);
    }
    
    @objc func triggerDisplayLink(_ displayLink: CADisplayLink) {
        
        let direction = displayLink.direction;
        guard let mainScrollView = self.mainRenderViewController?.mainScrollView,
            direction != .none else {
            return;
        }

        let frameSize = mainScrollView.frame.size;
        let contentSize = mainScrollView.contentSize;
        var contentOffset = mainScrollView.contentOffset;
        let contentInset = mainScrollView.contentInset;

        var distance = CGFloat(rint(300 * displayLink.duration));
        switch direction {
        case .up:
            distance *= -1;
            if contentOffset.y + distance <= 0 {
                distance = -contentOffset.y;
            }
        case .down:
            let maxY = max(contentSize.height, frameSize.height) - frameSize.height + contentInset.bottom;
            if contentOffset.y + distance >= maxY {
                distance = maxY - contentOffset.y;
            }
        default:
            break;
        }
        
        contentOffset.translate(dx: 0, dy: Float(distance));
        mainScrollView.contentOffset = contentOffset;
        
        var rect = self.zoomManagerView.targetRect;
        rect.origin.translate(dx: 0, dy: Float(distance));
        rect.origin.y = max(rect.origin.y, 0);
        if(rect != zoomManagerView.targetRect) {
            zoomManagerView.targetRect = rect;

            var point = rect.origin;
            point.y = rect.midY;

            self.zoomManagerRectMoved(zoomManagerView,point: point);
        }
    }
}

private extension CGRect {
    var hasInfiniteEntries: Bool {
        if(self.origin.x.isInfinite
            || self.origin.x.isInfinite
            || self.width.isInfinite
            || self.height.isInfinite) {
            return true;
        }
        return false;
    }
}
