//
//  FTPDFRenderViewController_FTScrollViewDelegate.swift
//  Noteshelf
//
//  Created by Amar on 13/03/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension FTPDFRenderViewController: FTScrollViewDelegate {
    func viewDidZoom() {
        self.endActiveEditingAnnotations()
    }
    
    func canAcceptTouch(for gesture:UIGestureRecognizer) -> Bool {
        if let controller = self.pageController(gesture.location(in: self.mainScrollView.contentHolderView)) {
            if self.isInZoomMode(), self.zoomOverlayController.isTouchInsideZoomManager(gesture) ?? false {
                return false;
            }
            return controller.canAcceptTouch(for: gesture);
        }
        return true;
    }
    
    func currentPageScrollView() -> UIScrollView? {
        let insideZoomView = self.visiblePageViewControllers().first?.scrollView;
        return insideZoomView;
    }

    func frame(for page:Int) -> CGRect {
        return self.pageLayoutHelper.frame(for: page);
    }
    
    func page(for point:CGPoint) -> Int {
        return self.pageLayoutHelper.page(for: point);
    }
    
    func moveToNextPage(_ currentPage : Int) -> Int {
        var page = currentPage + 1;
        if (page >= self.numberOfPages()) {
            page = self.numberOfPages()-1;
        }
        self.moveTo(page: page, currentPage: currentPage);
        return page;
    }
    
    func moveToPreviousPage(_ currentPage : Int) -> Int {
        var page = currentPage - 1;
        if (page < 0) {
            page = 0;
        }
        self.moveTo(page: page, currentPage: currentPage);
        return page;
    }
    
    func moveTo(page : Int,currentPage: Int) {
        if self.isInZoomMode(), page != currentPage {
        }
    }
    
    func scrollViewDidEndPanningPage() {
        FTCLSLog("Interaction: Main Scroll view did end drag");
        let currentControlelrs = self.visiblePageViewControllers();
        currentControlelrs.forEach { (pageVC) in
            pageVC.startAcceptingTouches(true);
        }
    }
}

extension FTPDFRenderViewController: UIScrollViewDelegate
{
    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        let visiblePages = self.visiblePageViewControllersWithOffset();
        for eachController in visiblePages {
            eachController.writingView?.willBeginZooming();
        }
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView,
                                        with view: UIView?,
                                        atScale scale: CGFloat) {
        self.updateContentOffsetPercentage();
        let visiblePages = self.visiblePageViewControllersWithOffset();
        for eachController in visiblePages {
            eachController.writingView?.didEndZooming(self.mainScrollView.zoomFactor);
        }
        self.setNeedsLayoutForcibly();
    }
}
