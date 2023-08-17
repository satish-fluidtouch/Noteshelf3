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
        self.contentHolderView?.isUserInteractionEnabled = enable;
        self.delegate?.setToolbarEnabled(enable);
    }
    
    func currentDeskMode() -> RKDeskMode {
        return self.delegate?.currentDeskMode ?? RKDeskMode.deskModeView;
    }
    
    func setToPreviousTool() {
        self.delegate?.setToPreviousTool();
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
