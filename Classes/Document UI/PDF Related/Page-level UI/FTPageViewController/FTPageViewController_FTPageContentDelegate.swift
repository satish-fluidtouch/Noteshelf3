//
//  FTPageViewController_FTPageContentDelegate.swift
//  Noteshelf
//
//  Created by Amar on 11/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension FTPageViewController : FTPageContentDelegate {
    func showZoomPanelIfNeeded() {
        self.delegate?.showZoomPanelIfNeeded();
    }
    
    func change(mode : RKDeskMode) {
        self.delegate?.change(mode);
    }
    
    func isInZoomMode() -> Bool {
        return self.delegate?.isInZoomMode() ?? false
    }
    
    func setUserInteraction(enable : Bool) {
        self.setUserInteraction(enable: enable, applyToToolbar: true)
    }
    
    private var pageIndex: Int {
        return self.pdfPage?.pageIndex() ?? -1;
    }
    
    func setUserInteraction(enable : Bool,applyToToolbar : Bool) {
        if self.contentHolderView?.isUserInteractionEnabled != enable {
            FTCLSLog("Interaction: Content interaction: \(enable) \(self.pageIndex) isCurrent: \(self.isCurrent)");
            self.cancenlScheduledUserIneractionTimeLimit();
            if !enable {
                self.scheduleUserIneractionTimeLimit();
            }
        }
        self.contentHolderView?.isUserInteractionEnabled = enable;
        if applyToToolbar {
            self.delegate?.setToolbarEnabled(enable);
        }
    }
    
    func currentDeskMode() -> RKDeskMode {
        return self.delegate?.currentDeskMode ?? RKDeskMode.deskModeView;
    }
    
    func setToPreviousTool() {
        self.delegate?.setToPreviousTool();
    }
    
    private func scheduleUserIneractionTimeLimit() {
        self.cancenlScheduledUserIneractionTimeLimit();
        self.perform(#selector(self.delayedEnableUserInteraction), with: nil, afterDelay: 5);
    }
    
    func cancenlScheduledUserIneractionTimeLimit() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.delayedEnableUserInteraction), object: nil);
    }
    
    @objc private func delayedEnableUserInteraction() {
        FTCLSLog("Interaction: Delayed Enable triggered \(self.pageIndex) \(self.isCurrent)");
        guard let scrollView = (self.layoutType == .vertical) ? self.delegate?.mainScrollView : self.scrollView
        , self.isCurrent else {
            return;
        }
        if scrollView.isDragging || scrollView.isZooming {
            FTCLSLog("Interaction: drag \(scrollView.isDragging) zoom: \(scrollView.isZooming) in progress");
            self.scheduleUserIneractionTimeLimit();
            return;
        }
        let contentOffset = scrollView.contentOffset;
        if (contentOffset.x < 0 || contentOffset.x > scrollView.contentSize.width - scrollView.frame.width) {
            FTCLSLog("Interaction:: ScrollView offset = \(contentOffset)")
            scrollView.setNeedsLayout();
        }
        FTLogError("App Freeze", attributes: ["pageindex" : self.pageIndex]);
        self.setUserInteraction(enable: true);
    }
}

extension FTPageViewController : FTPageAnnotationHandler
{
    func removeAnnotations(_ annotations : [FTAnnotation], refreshView shouldRefresh:Bool) {
        if !annotations.isEmpty {            
            (self.pdfPage as? FTPageUndoManagement)?.removeAnnotations(annotations);
            refreshModifiedArea(for: annotations, shouldRefresh: shouldRefresh)
        }
    }
    
    func addShapeAnnotation() {
        self.addShapeControllerIfNeeded()
    }
    
    func editShapeAnnotation(with annotation: FTAnnotation, point: CGPoint) {
        self.editAnnotation(annotation, eventType: .singleTap, at: point)
    }
    
    func endActiveShapeAnnotation(with annotation: FTAnnotation) {
        self.endEditingActiveAnnotation(annotation, refreshView: true)
    }
    
    func activeController() -> UIViewController? {
        return self.activeAnnotationController
    }
    
    func addAnnotations(_ annotations : [FTAnnotation], refreshView shouldRefresh:Bool) {
        if !annotations.isEmpty {
            (self.pdfPage as? FTPageUndoManagement)?.addAnnotations(annotations, indices: nil);
            refreshModifiedArea(for: annotations, shouldRefresh: shouldRefresh)
        }
    }

    func moveAnnotationsToFront(_ annotations : [FTAnnotation], shouldRefresh:Bool) {
        (self.pdfPage as? FTPageUndoManagement)?.moveAnnotationsToFront(annotations);
        refreshModifiedArea(for: annotations, shouldRefresh: shouldRefresh)
    }

    func moveAnnotationsToBack(_ annotations : [FTAnnotation], shouldRefresh:Bool) {
        (self.pdfPage as? FTPageUndoManagement)?.moveAnnotationsToBack(annotations);
        refreshModifiedArea(for: annotations, shouldRefresh: shouldRefresh)
    }

    func groupAnnotations(_ annotations : [FTAnnotation]) {
        (self.pdfPage as? FTPageUndoManagement)?.group(annotations: annotations)
    }

    func ungroupAnnotations(_ annotations : [FTAnnotation]) {
        (self.pdfPage as? FTPageUndoManagement)?.ungroup(annotations: annotations)
    }

    private func refreshModifiedArea(for annotations:[FTAnnotation], shouldRefresh: Bool) {

        let refreshArea = annotations.reduce(CGRect.null) { (rect, annotation) -> CGRect in
            return rect.union(annotation.renderingRect)
        }

        if(shouldRefresh) {
            self.refresh(refreshArea);
        }

        self.postRefreshNotification(refreshArea);
    }
}

extension FTPageViewController: FTLaserAnnotationHandler {    
    func addLaserAnnotation(_ annotation: FTAnnotation,for page: FTPageProtocol) {
        self.delegate?.addLaserAnnotation(annotation, for: page);
    }
        
    func laserAnnotations(for page: FTPageProtocol) -> [FTAnnotation] {
        return self.delegate?.laserAnnotations(for: page) ?? [FTAnnotation]();
    }
}
