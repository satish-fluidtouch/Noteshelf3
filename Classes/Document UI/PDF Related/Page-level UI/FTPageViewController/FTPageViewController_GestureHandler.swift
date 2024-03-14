//
//  FTPageViewController_GestureHandler.swift
//  Noteshelf
//
//  Created by Amar on 16/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension FTPageViewController {
    func configureGestures()
    {
        self.addGestures();
        self.disableLongPressNotificationObserver = NotificationCenter.default.addObserver(forName: Notification.Name("FTDisableLongPressGestureNotification"),
                                               object: nil,
                                               queue: nil)
        { [weak self] (notification) in
            guard notification.isSameSceneWindow(for: self?.view.window) else { return }
            self?.longPressGestureRecognizer?.isEnabled = false;
        };
        
        self.disableGestureNotificationObserver = NotificationCenter.default.addObserver(forName: Notification.Name(FTPDFDisableGestures),
                                               object: nil,
                                               queue: nil)
        { [weak self] (notification) in
            guard notification.isSameSceneWindow(for: self?.view.window) else { return }
            self?.doubleTapGestureRecognizer?.isEnabled = false;
            self?.singleTapSelectionGestureRecognizer?.isEnabled = false;
        };

        self.enableGestureNotificationObserver = NotificationCenter.default.addObserver(forName: Notification.Name(FTPDFEnableGestures),
                                               object: nil,
                                               queue: nil)
        { [weak self] (notification) in
            guard notification.isSameSceneWindow(for: self?.view.window) else { return }
            if self?.renderMode == FTRenderModeDefault {
                self?.singleTapGestureRecognizer?.isEnabled = true;
                self?.doubleTapGestureRecognizer?.isEnabled = true;
            }
            self?.longPressGestureRecognizer?.isEnabled = true;
            self?.singleTapSelectionGestureRecognizer?.isEnabled = true;
        };
        
        self.addObserverForQuickPageNavigator()
    }
    private func addGestures()
    {
        if(nil == self.longPressGestureRecognizer) {
            let gesture = UILongPressGestureRecognizer.init(target: self, action: #selector(self.longPressDetected(_:)));
            self.longPressGestureRecognizer = gesture;
            gesture.delaysTouchesEnded = false;
            gesture.delegate = self;
            gesture.minimumPressDuration = 0.51;
            self.view.addGestureRecognizer(gesture);
        }
        
        if(nil == self.singleTapGestureRecognizer) {
            let gesture = UITapGestureRecognizer.init(target: self, action: #selector(self.singleTapGestureRecognized(_:)));
            self.singleTapGestureRecognizer = gesture;
            gesture.delaysTouchesEnded = false;
            gesture.delegate = self;
            self.view.addGestureRecognizer(gesture);
        }

        if(nil == self.singleTapSelectionGestureRecognizer) {
            let gesture = UITapGestureRecognizer.init(target: self, action: #selector(self.singleTapSelectionGestureRecognized(_:)));
            self.singleTapSelectionGestureRecognizer = gesture;
            gesture.delaysTouchesEnded = false;
            gesture.delegate = self;
            gesture.require(toFail: singleTapGestureRecognizer!)
            self.view.addGestureRecognizer(gesture);
        }

        if(nil == self.doubleTapGestureRecognizer) {
            let gesture = UITapGestureRecognizer.init(target: self, action: #selector(self.doubleTapGestureRecognized(_:)));
            gesture.numberOfTapsRequired = 2
            self.doubleTapGestureRecognizer = gesture;
            gesture.delaysTouchesEnded = false;
            gesture.delegate = self;
            self.view.addGestureRecognizer(gesture);
            #if !targetEnvironment(macCatalyst)
            self.doubleTapGestureRecognizer?.allowedTouchTypes = [NSNumber(integerLiteral: UITouch.TouchType.direct.rawValue)];
            self.singleTapSelectionGestureRecognizer?.require(toFail: gesture);
            if let singleTapGest = self.singleTapGestureRecognizer {
                gesture.require(toFail: singleTapGest);
            }
            #endif
        }

        let whiteboardIndicatorGesture = FTWhiteboardTouchGestureRecognizer(target: self, action: #selector(FTPageViewController.didRecieveTouches(_:)));
        whiteboardIndicatorGesture.delaysTouchesBegan = false;
        whiteboardIndicatorGesture.delaysTouchesEnded = false;
        whiteboardIndicatorGesture.cancelsTouchesInView = false;
        if let panGesture = self.delegate?.mainScrollView?.panGestureRecognizer {
            whiteboardIndicatorGesture.require(toFail: panGesture);
        }
        self.contentHolderView?.addGestureRecognizer(whiteboardIndicatorGesture);
    }
    
    @objc func didRecieveTouches(_ gesture :UIGestureRecognizer) {
        if(gesture.state == .recognized) {
            NotificationCenter.default.post(name: FTWhiteboardDisplayManager.didRecieveTouchOnPage, object: self);
        }
    }
    
    func updateGestureTouchTypes(mode : RKDeskMode)
    {
        if(mode == .deskModeMarker
            || mode == .deskModePen
            || mode == .deskModeFavorites
            || mode == .deskModeEraser
            || mode == .deskModeShape
            ) {
            self.longPressGestureRecognizer?.allowedTouchTypes = [
                NSNumber(value: UITouch.TouchType.direct.rawValue)
            ];
            self.startAcceptingTouches(true);
        }
        else {
            self.longPressGestureRecognizer?.allowedTouchTypes = [
                NSNumber(value: UITouch.TouchType.direct.rawValue),
                NSNumber(value: UITouch.TouchType.pencil.rawValue),
                NSNumber(value: UITouch.TouchType.indirect.rawValue)
            ];
        }
    }

    @IBAction func singleTapSelectionGestureRecognized(_ gesture : UITapGestureRecognizer) {
        if(gesture.state == .recognized) {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(disableSingleTapGesture), object: nil)
            let hitPoint = gesture.location(in: self.contentHolderView);
            if let annotation = self.annotation(type: .singleTapSelection, atPoint: hitPoint) {
                self.editAnnotation(annotation,
                                    eventType: .singleTap,
                                    at:hitPoint);
            } else  if(self.currentDeskMode() == .deskModeText) {
                guard let contentView = self.contentHolderView else { return };
                if let activeController = self.activeAnnotationController {
                    if !activeController.isPointInside(hitPoint, fromView: contentView) {
                        self.endEditingActiveAnnotation(activeController.annotation, refreshView: true);
                    }
                    return
                }
                let info = FTTextAnnotationInfo();
                info.localmetadataCache = self.pdfPage?.parentDocument?.localMetadataCache;
                info.visibleRect = self.scrollView?.visibleRect() ?? contentView.bounds;
                info.atPoint = hitPoint;
                info.scale = self.pageContentScale;
                self.addAnnotation(info: info);
            }
        }
    }

    @objc func disableSingleTapGesture() {
        self.singleTapSelectionGestureRecognizer?.isEnabled = false;
        self.singleTapSelectionGestureRecognizer?.isEnabled = true;
    }

    @IBAction func singleTapGestureRecognized(_ gesture : UITapGestureRecognizer)
    {
        if(gesture.state == .recognized) {

            let hitPoint = gesture.location(in: self.contentHolderView);
            let hitPoint1x = CGPointScale(hitPoint, 1/self.pageContentScale);
            
            if let annotation = self.annotation(type: .singleTap, atPoint: hitPoint) {
                if  !(annotation.annotationType == .audio
                        || annotation.annotationType == .text),currentDeskMode() == .deskModeReadOnly {
                    return
                }

                if let undoableInfo = (annotation as? FTAnnotationSingleTapHandler)?.performSingleTapEvent(atPoint: hitPoint1x) {
                    DispatchQueue.main.async {
                        self.updateAnnotation(annotation,
                                              info: undoableInfo,
                                              shouldRefresh: true);
                    }
                }
                else {
                    self.editAnnotation(annotation,
                                        eventType: .singleTap,
                                        at:hitPoint);
                }
            }
            else if self.highlightPDFLink(atPoint: hitPoint) {
                self.performPDFLinkAction(atPoint: hitPoint);
            }
        }
    }

    @IBAction func doubleTapGestureRecognized(_ gesture : UITapGestureRecognizer)
    {
        if(gesture.state == .recognized) {
            var contentViewWidth: CGFloat = self.view.frame.width
            var contentViewHeight: CGFloat = self.view.frame.height
            var _currentScrView: UIScrollView?
            //**********************************
            if UserDefaults.standard.pageLayoutType == .vertical {
                _currentScrView = self.delegate?.mainScrollView
            }
            else {
                _currentScrView = self.scrollView
            }
            if let contentHolderView = self.scrollView?.contentHolderView {
                contentViewWidth = contentHolderView.frame.width
                contentViewHeight = contentHolderView.frame.height
            }
            //**********************************
            
            guard let currentScrView = _currentScrView else {
                return;
            }
            let screenWidth = currentScrView.frame.width
            let screenHeight = currentScrView.frame.height
            var zoomScale: CGFloat = 0.0
            if UserDefaults.standard.pageLayoutType == .vertical {
                zoomScale = screenWidth / contentViewWidth
                if abs(1-zoomScale) < 0.1 {
                    zoomScale = currentScrView.minimumZoomScale;
                }
            }
            else {
                if abs(contentViewWidth-screenWidth) <= 1 {
                    zoomScale = screenHeight / contentViewHeight
                }
                else {
                    zoomScale = screenWidth / contentViewWidth
                }
            }
            //scrView.minimumZoomScale is returning 0.99999999 sometimes in mac
            if currentScrView.zoomScale != 1.0 {
                zoomScale = currentScrView.minimumZoomScale
            }
            zoomScale = fmin(currentScrView.maximumZoomScale, zoomScale)
            zoomScale = fmax(currentScrView.minimumZoomScale, zoomScale)
            
            if zoomScale == currentScrView.maximumZoomScale,currentScrView.maximumZoomScale == 1 {
                zoomScale = currentScrView.minimumZoomScale
            }
            //**********************************
            
            guard let zoomingView = currentScrView.delegate?.viewForZooming?(in: currentScrView),
                  abs(1-zoomScale) > 0.01 else {
                return;
            }
            var point = gesture.location(in: zoomingView);
            point.x = zoomingView.bounds.midX;
            if zoomScale == currentScrView.minimumZoomScale,UserDefaults.standard.pageLayoutType == .vertical {
                point.y = currentScrView.visibleRect.midY
            }
            currentScrView.zoomTo(point, scale: zoomScale, animate: true);
        }
    }
    
    @IBAction func longPressDetected(_ gesture : UILongPressGestureRecognizer)
    {
        var isAnnotationDetected = false
        if(gesture.state == .began) {
            self.activeAnnotationController?.annotationControllerLongPressDetected()
            let hitPoint = gesture.location(in: self.contentHolderView);
            if let annotation = self.annotation(type: FTProcessEventType.longPress,
                                                atPoint: hitPoint) {
                self.editAnnotation(annotation,
                                    eventType: .longPress,
                                    at:hitPoint)
                isAnnotationDetected = true
                if annotation.isLocked {
                    return
                }
            }
            self.activeAnnotationController?.annotationControllerLongPressDetected()
            self.showPasteOptionsIfNeeded(at: hitPoint);
        }
    }
}

extension FTPageViewController : UIGestureRecognizerDelegate
{
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if(gestureRecognizer is FTWhiteboardTouchGestureRecognizer || otherGestureRecognizer is FTWhiteboardTouchGestureRecognizer) {
            return true;
        }
        return false;
    }
    
    public func shouldAcceptTouch(touch: UITouch) -> Bool {
        guard let contentView = self.contentHolderView else { return false;};
        var valueToReturn = true
        let locationInView = touch.location(in: contentView);
        if let activeController = self.activeAnnotationController,
            activeController.isPointInside(locationInView, fromView: contentView) {
            valueToReturn = false;
        }

        if let lassoView = self.lassoSelectionView,
            let antsView = lassoView.antsView,
            antsView.isPointInsidePath(touch.location(in: antsView)) {
            valueToReturn = false;
        }
        
        if let lassoContentResizeView = self.lassoContentSelectionViewController,
            lassoContentResizeView.isPointInside(locationInView) {
            valueToReturn = false;
        }
        return valueToReturn
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldReceive touch: UITouch) -> Bool {
        #if targetEnvironment(macCatalyst)
        if (gestureRecognizer == self.doubleTapGestureRecognizer) {
            return currentDeskMode() == RKDeskMode.deskModeView
        }
        #endif
        if(gestureRecognizer == self.longPressGestureRecognizer
            || gestureRecognizer == self.singleTapGestureRecognizer
            || gestureRecognizer == self.singleTapSelectionGestureRecognizer
            || gestureRecognizer == self.doubleTapGestureRecognizer) {
            guard let contentView = self.contentHolderView else { return false;}

            if !shouldAcceptTouch(touch: touch) {
                return false
            }
            let locationInView = touch.location(in: contentView);
            var valueToReturn = false;
            if(gestureRecognizer == self.longPressGestureRecognizer) {
                //Long press
                if currentDeskMode() == RKDeskMode.deskModeClipboard,
                    let lassoView = self.lassoSelectionView,
                    nil == lassoView.antsView {
                    valueToReturn = true;
                }
                else if let annotation = self.annotation(type: FTProcessEventType.longPress,
                                                atPoint: locationInView) {
                    valueToReturn = true
                    if (isInZoomMode() && !annotation.supportsZoomMode) {
                        valueToReturn = false
                    }
                }
                else if currentDeskMode() != RKDeskMode.deskModeLaser {
                    valueToReturn = true
                }
                if let annotation = self.annotation(type: FTProcessEventType.longPress,
                                                         atPoint: locationInView), (annotation.annotationType == .image || annotation.annotationType == .sticky || annotation.annotationType == .stroke || annotation.annotationType == .text || annotation.annotationType == .shape), currentDeskMode() == .deskModeReadOnly {
                    valueToReturn = false
                }
            } else if (gestureRecognizer == self.singleTapSelectionGestureRecognizer) {

                if (currentDeskMode() == .deskModePen || currentDeskMode() == .deskModeFavorites || currentDeskMode() == .deskModeMarker || currentDeskMode() == .deskModeEraser ||
                    currentDeskMode() == .deskModeShape) {
                    if touch.type == .pencil || !UserDefaults.isApplePencilEnabled() {
                        if let activeController = self.delegate?.activeAnnotationController() {
                            let controller = self.delegate?.pageControllerFor(activeAnnotationController: activeController);
                            controller?.endEditingActiveAnnotation(activeController.annotation, refreshView: true)
                        }
                        return false;
                    }
                }
              
                if let activeController = self.delegate?.activeAnnotationController() {
                    let controller = self.delegate?.pageControllerFor(activeAnnotationController: activeController);
                    controller?.endEditingActiveAnnotation(activeController.annotation, refreshView: true)
                    if touch.type == .direct
                        ,nil != self.annotation(type: .singleTapSelection, atPoint: locationInView) {
                        return true;
                    }
                    else {
                        return false;
                    }
                }

                if !contentView.bounds.contains(locationInView) {
                    return false
                }

                if nil != self.lassoSelectionView?.antsView ||
                    nil != self.lassoContentSelectionViewController {
                    self.normalizeLassoView()
                    return false;
                }

                if let annotation = self.annotation(type: .singleTapSelection, atPoint: locationInView) {
                    valueToReturn = true
                    if (isInZoomMode() && !annotation.supportsZoomMode) {
                        valueToReturn = false
                    }
                }
                if currentDeskMode() == .deskModeStickers || (isInZoomMode() && !allowsEditinginZoomMode()) {
                    valueToReturn = false
                }

                if currentDeskMode() == .deskModeText {
                    valueToReturn = true
                }
                if let annotation = self.annotation(type: FTProcessEventType.singleTapSelection,
                                                         atPoint: locationInView), (annotation.annotationType == .image
                                                                                        || annotation.annotationType == .sticky
                                                                                        || annotation.annotationType == .stroke
                                                                                        || annotation.annotationType == .text), currentDeskMode() == .deskModeReadOnly {
                    valueToReturn = false
                }
                if valueToReturn == true {
                    NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(disableSingleTapGesture), object: nil)
                    self.perform(#selector(disableSingleTapGesture), with: nil, afterDelay: 0.2)
                }
            }
            else if(gestureRecognizer == self.doubleTapGestureRecognizer) {
                let currenttDeskMode = currentDeskMode();
                if currenttDeskMode == .deskModeReadOnly || currenttDeskMode == .deskModeView {
                    valueToReturn = true;
                }
                else if UserDefaults.isApplePencilEnabled(),
                   (currenttDeskMode == .deskModePen
                    || currenttDeskMode == .deskModeFavorites
                    || currenttDeskMode == .deskModeMarker
                        || currenttDeskMode == .deskModeEraser
                        || currenttDeskMode == .deskModeClipboard
                        || currenttDeskMode == .deskModeLaser
                        || currenttDeskMode == .deskModeShape),
                   !self.isInZoomMode() {
                    valueToReturn = true;
                }
            }
            else {
                //Single Tap
                if let activeAnnotationController = activeAnnotationController, !(activeAnnotationController is FTShapeAnnotationController) {
                    return false;
                }
                if self.writingView?.isPDFTextSelected() ?? false {
                    return false;
                }
                if let annotation = self.annotation(type: .singleTap, atPoint: locationInView) {
                    valueToReturn = true
                    if (isInZoomMode() && !annotation.supportsZoomMode) {
                        valueToReturn = false
                    }
                }

                if(!valueToReturn) {
                    valueToReturn = self.highlightPDFLink(atPoint: locationInView);
                }
                if currentDeskMode() == .deskModeReadOnly {
                    valueToReturn = true

                }
            }
            self.perform(#selector(self.hideQuickPageNavigator), with: nil, afterDelay: 0.1)
            return valueToReturn;
        }
        return true;
    }
    
    private func allowsEditinginZoomMode() -> Bool {
        return (currentDeskMode() == .deskModePen || currentDeskMode() == .deskModeFavorites || currentDeskMode() == .deskModeMarker || currentDeskMode() == .deskModeEraser || currentDeskMode() == .deskModeShape)
    }

}

extension FTPageViewController {
    
    private func addObserverForQuickPageNavigator() {
        self.quickPageNavigationShowNotificationObserver = NotificationCenter.default.addObserver(forName: .quickPageNavigatorShowNotification,
                                               object: nil,
                                               queue: nil)
        { [weak self] (_) in
            if let `self` = self {
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.hideQuickPageNavigator), object: nil)
            }
        };
    }
    
    @objc private func hideQuickPageNavigator() {
        FTQuickPageNavigatorViewController.hidePageNavigator(forController: self)
    }
}

private class FTWhiteboardTouchGestureRecognizer : UIGestureRecognizer {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event);
        if(self.hasBottomEdgeTouch(touches)) {
            self.state = .failed;
        }
        else {
            self.state = .possible;
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event);
        self.state = .recognized;
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event);
        self.state = .failed;
    }
    
    private func hasBottomEdgeTouch(_ touches: Set<UITouch>) -> Bool {
        var isBottomEdgePan = true;
        if let view = self.view, let window = view.window {
            isBottomEdgePan = false;
            let safeAreaInset = window.safeAreaInsets;
            var rect = window.bounds;
            let height = max(safeAreaInset.bottom,10);
            rect.origin.y = rect.height - height;
            rect.size.height = height;
            
            for eachTouch in touches {
                let loc = eachTouch.location(in: nil);
                if(rect.contains(loc)) {
                    isBottomEdgePan = true;
                    break;
                }
            }
        }
        return isBottomEdgePan;
    }
}
