//
//  FTWritingViewController_LaserPresentation.swift
//  Noteshelf
//
//  Created by Amar on 30/04/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

@objc protocol FTLaserAnnotationHandler: NSObjectProtocol {
    func addLaserAnnotation(_ annotation: FTAnnotation,for page: FTPageProtocol);
    func laserAnnotations(for page: FTPageProtocol) -> [FTAnnotation];
}

protocol FTLaserTouchEventsHandling: NSObjectProtocol {
    func cancelCurrentLaserStroke();
    func publishLaserChanges();
    func processLaserVertex(touch : FTTouch,vertexType : FTVertexType);
}

extension FTWritingViewController {
    
    func reloadLaserView(rect: CGRect,properties: FTRenderingProperties) {
        if !self.isZooming,
//           !(self.scrollView?.isScrolling ?? false),
           let scrollView = self.scrollView,
           let laserController = self.laserPresenterController {
            let currentFrame = laserController.view.frame;
            let frame = scrollView.visibleRect();
            if(frame != currentFrame) {
                laserController.view.frame = frame;
                laserController.view.layoutIfNeeded();
            }
            self.laserPresenterController?.reloadTiles(in: rect, properties: properties);
        }
    }
    
    func addLaserPresentationController() {
        if nil == self.laserPresenterController,
           nil != self.onscreenViewController {
            let controller = FTLaserPresentationViewController();
            controller.delegate = self;
            controller.view.autoresizingMask = [.flexibleWidth,.flexibleHeight];
            controller.view.frame = self.visibleRect;
            self.addChild(controller);
            self.view.addSubview(controller.view);
            self.laserPresenterController = controller;
            
            let properties = FTRenderingProperties();
            self.laserPresenterController?.reloadTiles(in: self.visibleRect, properties: properties);
        }
    }
    
    func removeLaserPresentationController() {
        self.laserPresenterController?.view.removeFromSuperview();
        self.laserPresenterController?.removeFromParent();
        self.laserPresenterController = nil;
    }
}

extension FTWritingViewController: FTLaserPresentationDelegate {
    func addLaserAnnotation(_ annotation: FTAnnotation) {
        guard let page = self.pageToDisplay else {
            return;
        }
        self.addLaserAnnotation(annotation, for: page);
    }
    
    var page: FTPageProtocol? {
        return self.pageToDisplay;
    }
    
    var visibleRect: CGRect {
        return self.scrollView?.visibleRect() ?? CGRect.zero;
    }
    
    func lasserAnnotations() -> [FTAnnotation] {
        guard let page = self.pageToDisplay else {
            return [FTAnnotation]();
        }
        return self.laserAnnotations(for: page);
    }
}

private extension FTWritingViewController
{
    func addLaserAnnotation(_ annotation: FTAnnotation,for page: FTPageProtocol) {
        guard let del = self.pageContentDelegate as? FTLaserAnnotationHandler else {
            return;
        }
        del.addLaserAnnotation(annotation, for: page);
    }
        
    func laserAnnotations(for page: FTPageProtocol) -> [FTAnnotation] {
        guard let del = self.pageContentDelegate as? FTLaserAnnotationHandler else {
            return [FTAnnotation]();
        }
        return del.laserAnnotations(for: page);
    }
}

extension FTWritingViewController: FTLaserTouchEventsHandling {
    func processLaserVertex(touch: FTTouch, vertexType: FTVertexType) {
        self.laserPresenterController?.processs(touch, vertexType: vertexType);
    }
    
    func publishLaserChanges() {
        self.laserPresenterController?.publishChanges();
    }
    
    func cancelCurrentLaserStroke() {
        self.laserPresenterController?.cancelCurrentStroke();
    }
}
