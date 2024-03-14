//
//  FTZoomOverlyaerViewController_ZoomPanelDelegate.swift
//  Noteshelf
//
//  Created by Amar on 27/04/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

private let stdOffset: CGFloat = 20;

extension FTZoomOverlayViewController {
    func addZoomTouchesNotificationHandlers() {
        self.zoomDidEndTouchesObserver = NotificationCenter.default.addObserver(forName: Notification.Name(FTZoomRenderViewDidEndTouches),
                                               object: nil,
                                               queue: nil)
        { [weak self] (notification) in
            guard let strongSelf = self,
                let notificationWindow = notification.object as? UIWindow,
                notificationWindow == strongSelf.view.window,
                let impactedRectValue = notification.userInfo?[FTImpactedRectKey] as? NSValue,
                let document = strongSelf.nsDocument,
                let docCache = document.localMetadataCache else {
                    return;
            }
            
            let currentMode = strongSelf.currentDeskMode;
            
            let inImpactedRect = impactedRectValue.cgRectValue;
            if (currentMode == .deskModePen || currentMode == .deskModeMarker || currentMode == .deskModeFavorites),
                docCache.zoomPanelAutoAdvanceEnabled
            {
                if nil != strongSelf.autoscrollTimer {
                    strongSelf.scheduleAutoScrollTimer();
                    return;
                }
                
                let impactedRect = CGRect.scale(inImpactedRect, strongSelf.pageContentScale);
                let autoScrollWidth = CGFloat(docCache.zoomAutoscrollWidth);
                
                if(impactedRect.maxX > (strongSelf.visibleFrame.maxX - autoScrollWidth)){
                    strongSelf.lastStrokeInpactedRect = inImpactedRect;
                    if(nil == strongSelf.autoscrollTimer) {
                        strongSelf.scheduleAutoScrollTimer()
                    }
                }
                else {
                    strongSelf.delegate?.zoomOverlayScrollTo(targetRect: strongSelf.zoomTargetRect,
                                                       pageController: strongSelf.currentPageController);
                }
            }
        };
        
        self.zoomDidBeginTouchesObserver = NotificationCenter.default.addObserver(forName: Notification.Name(FTZoomRenderViewDidBeginTouches),
                                               object: nil,
                                               queue: nil)
        { [weak self] (notification) in
            guard let notificationWindow = notification.object as? UIWindow,
                notificationWindow == self?.view.window else {
                    return;
            }
            
            self?.lastStrokeInpactedRect = CGRect.null;
            self?.autoscrollTimer?.invalidate();
            self?.autoscrollTimer = nil;
        };
    }
    
    private func scheduleAutoScrollTimer() {
        self.autoscrollTimer = Timer.scheduledTimer(timeInterval: 0.5,
                                                    target: self,
                                                    selector: #selector(self.zoomPanelPanRight),
                                                    userInfo: nil,
                                                    repeats: false);
    }
}

extension FTZoomOverlayViewController {
    func zoomPanelPanLeft() {
        var newX: CGFloat = 0 ,newY : CGFloat = 0;

        guard let page = self.currentPage,
            let currentPageController = self.currentPageController,
            let contentView = currentPageController.contentHolderView else {
            return;
        }
        
        if shouldMoveToPreviousPage(false),
            let newPage = page.previousPage() {
            let targetRect = CGRect.scale(self.zoomTargetRect, 1/currentPageController.pageContentScale);
            let rightMargin = zoomManagerView.rightZoomMargin;
            newPage.zoomTargetOrigin = CGPoint(x: newPage.pdfPageRect.width - targetRect.width-rightMargin, y: newPage.pdfPageRect.height - targetRect.height);
            self.postPageChange(page: newPage);
            return;
        }

        let zoomManagerView = self.zoomManagerView;
        
        let zoomManagerBounds = contentView.bounds;
        let availableWidth = zoomManagerBounds.width - (zoomManagerView.rightZoomMargin * currentPageController.pageContentScale);
        let targetRect = self.zoomTargetRect;
        
        if (targetRect.origin.x < (5 + zoomManagerView.leftZoomMargin)) && targetRect.origin.y > 5 {
            newX = availableWidth - targetRect.width;
            newY = max(targetRect.origin.y - zoomManagerView.lineHeight, 0);
        }
        else {
            var minx = availableWidth - targetRect.width;
            if(availableWidth - zoomManagerView.leftZoomMargin > targetRect.width) {
                minx = zoomManagerView.leftZoomMargin;
            }
            newX = max(targetRect.origin.x - (targetRect.width * 0.8), minx);
            newY = targetRect.origin.y;
        }
        newX = max(newX, 0);
        var newTargetRect = targetRect;
        newTargetRect.origin = CGPoint(x: newX, y: newY);
        
        self.zoomTargetRect = newTargetRect;
    }
    
    func zoomPanelPanRight() {
        
        guard let page = self.currentPage,
            let currentPageController = self.currentPageController,
            let contentView = currentPageController.contentHolderView else {
                return;
        }

        self.autoscrollTimer?.invalidate();
        self.autoscrollTimer = nil;

        if self.shouldMoveToNextPage(false),
            let newPage = page.nextPage() {
            newPage.zoomTargetOrigin = CGPoint.zero;
            self.postPageChange(page: newPage);
            return;
        }

        let zoomManagerView = self.zoomManagerView;
        let zoomManagerBounds = contentView.bounds;
        let availableWidth = zoomManagerBounds.width - (zoomManagerView.rightZoomMargin * currentPageController.pageContentScale);
        let targetRect = self.zoomTargetRect;

        if (targetRect.maxX + 5) > availableWidth,
            ((zoomManagerBounds.height - targetRect.height) > (targetRect.origin.y + 5)) {
            self.zoomPanelPanNewLineDown();
            return;
        }
        
        var offset = targetRect.width;
        if(!self.lastStrokeInpactedRect.isNull) {
            let scaledImpactRect = CGRectScale(self.lastStrokeInpactedRect, currentPageController.pageContentScale);
            let maxX = scaledImpactRect.maxX;
            offset = max(maxX-targetRect.minX, 0);
        }
        var newX = min(targetRect.origin.x + (offset * 0.8),availableWidth - targetRect.width);
        newX = max(0, newX);

        var newTargetRect = targetRect;
        newTargetRect.origin.x = newX;
        self.zoomTargetRect = newTargetRect;
    }
    
    func zoomPanelPanNewLineDown() {
        guard let page = self.currentPage,
            let currentPageController = self.currentPageController,
            let contentView = currentPageController.contentHolderView else {
                return;
        }
        
        if self.shouldMoveToNextPage(true),
            let newPage = page.nextPage() {
            newPage.zoomTargetOrigin = CGPoint.zero;
            self.postPageChange(page: newPage);
            return;
        }

        let zoomManagerView = self.zoomManagerView;

        let zoomManagerBounds = contentView.bounds;
        let availableWidth = zoomManagerBounds.width - (zoomManagerView.rightZoomMargin * currentPageController.pageContentScale);
        let targetRect = self.zoomTargetRect;
    
        let newX: CGFloat;
        if(availableWidth - zoomManagerView.leftZoomMargin > targetRect.width) {
            newX = max(0,zoomManagerView.leftZoomMargin);
        }
        else {
            newX = max(0,availableWidth - targetRect.width);
        }
        
        let newY = min(targetRect.origin.y + zoomManagerView.lineHeight, zoomManagerBounds.height - targetRect.height);

        var newTargetRect = targetRect;
        newTargetRect.origin = CGPoint(x: newX, y: newY);
        self.zoomTargetRect = newTargetRect;
    }
    
    func zoomPanelPanNewLineUp() {
        guard let page = self.currentPage,
            let currentPageController = self.currentPageController,
            let contentView = currentPageController.contentHolderView else {
                return;
        }
        
        
        if shouldMoveToPreviousPage(true),
            let newPage = page.previousPage() {
            let oneByScale = 1/currentPageController.pageContentScale;
            let targetRect = CGRect.scale(self.zoomTargetRect, oneByScale);
            let leftmargin = zoomManagerView.leftZoomMargin * oneByScale;
            let newX: CGFloat;
            if(newPage.pdfPageRect.width - leftmargin > targetRect.width) {
                newX = max(0,leftmargin);
            }
            else {
                newX = max(0,newPage.pdfPageRect.width - targetRect.width);
            }
            newPage.zoomTargetOrigin = CGPoint(x: newX, y: newPage.pdfPageRect.height - targetRect.height);
            self.postPageChange(page: newPage);
            return;
        }

        let zoomManagerView = self.zoomManagerView;

        let zoomManagerBounds = contentView.bounds;
        let availableWidth = zoomManagerBounds.width - (zoomManagerView.rightZoomMargin * currentPageController.pageContentScale);
        let targetRect = self.zoomTargetRect;
    
        let newX: CGFloat;
        if(availableWidth - zoomManagerView.leftZoomMargin > targetRect.width) {
            newX = max(0,zoomManagerView.leftZoomMargin);
        }
        else {
            newX = max(0,availableWidth - targetRect.width);
        }
        let newY = max(targetRect.origin.y - zoomManagerView.lineHeight, 0);

        var newTargetRect = targetRect;
        newTargetRect.origin = CGPoint(x: newX, y: newY);
        self.zoomTargetRect = newTargetRect;
    }
    
    func zoomPanelDidTapOnPalmRest() {
        self.delegate?.zoomPanelDidTapOnPalmRest();
    }
    
    private func postPageChange(page: FTPageProtocol) {
        if(self.delegate?.pageLayoutType() == .vertical) {
            if let controller = self.mainRenderViewController?.pageController(for: page) {
                self.setCurrentPage(page, pageController: controller);
            }
        }
        else {
            self.delegate?.zoomOverlayNavigateTo(page: page);
        }
    }
}

private extension FTZoomOverlayViewController
{
    func shouldMoveToPreviousPage(_ isNewLine: Bool) -> Bool {
        var shouldMove = false;
        let targetRect = self.zoomTargetRect.integral;
        let minX = min(stdOffset,zoomManagerView.leftZoomMargin);
        if targetRect.origin.y < stdOffset,
            (targetRect.origin.x <= minX || targetRect.origin.x <= zoomManagerView.leftZoomMargin || isNewLine) {
            shouldMove = true;
        }
        return shouldMove;
    }
    
    func shouldMoveToNextPage(_ isNewLine: Bool) -> Bool {
        guard let contentView = self.currentPageController?.contentHolderView else {
            return false;
        }
        var shouldMove = false;
        let targetRect = self.zoomTargetRect.integral;
        let zoomBounds = contentView.bounds;
        if targetRect.maxY >= zoomBounds.height-stdOffset,
            (isNewLine || targetRect.maxX >= zoomBounds.width - stdOffset) {
            shouldMove = true;
        }
        return shouldMove;
    }
}

private extension FTPageProtocol {
    func nextPage() -> FTPageProtocol?
    {
        var page: FTPageProtocol?
        let index = self.pageIndex() + 1;
        let pageCount = self.parentDocument?.pages().count ?? 0;
        if(pageCount > index) {
            page = self.parentDocument?.pages()[index];
        }
        return page;
    }
    
    func previousPage() -> FTPageProtocol?
    {
        var page: FTPageProtocol?
        let index = self.pageIndex() - 1;
        if(index >= 0) {
            page = self.parentDocument?.pages()[index];
        }
        return page;
    }
}
