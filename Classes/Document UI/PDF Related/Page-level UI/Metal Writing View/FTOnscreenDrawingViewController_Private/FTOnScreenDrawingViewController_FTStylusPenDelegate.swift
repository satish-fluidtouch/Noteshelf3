//
//  FTOnScreenWritingViewController_FTStylusPenDelegate.swift
//  Noteshelf
//
//  Created by Amar on 24/12/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTRenderKit

//MARK:- FTStylusPenDelegate
extension FTOnScreenWritingViewController : FTStylusPenDelegate
{
    func sizeOfCurrentStroke() -> CGSize {
        if(nil == self.currentStroke) {
            return CGSize.zero;
        }
        return CGSizeScale(self.currentStroke!.stroke.boundingRect.size, self.scale);
    }

    func shouldProcessTouch(_ touch: UITouch!) -> Bool {
        if let activeController = self.delegate?.activeController() as? FTShapeAnnotationController {
            return activeController.shouldReceiveTouch(for: touch.location(in: self.view))
        }
        return false
    }
    
    func shouldAlwaysUseFingerTouch() -> Bool {
        if let del = self.delegate, del.isIntroScreen {
            return true;
        }
        return false;
    }
    
    func penType() -> FTPenType {
        if let stroke = self.currentStroke?.stroke as? FTStroke {
            return stroke.penType;
        }
        return self.currentSelectedPenSet().type;
    }
    
    func isApplePencilEnabled() -> Bool {
        if let del = self.delegate, del.isIntroScreen {
            return false;
        }
        return UserDefaults.isApplePencilEnabled();
    }
    
    func enableApplePencil()
    {
        if let del = self.delegate, !del.isIntroScreen {
            UserDefaults.setApplePencilEnable(true);
            #if !targetEnvironment(macCatalyst)
            PressurePenEngine.shared().refresh();
            #endif
        }
    }
    
    func stylusPenTouchBegan(_ touch: FTTouch!) {
        if self.selectedTextRange != nil {
            return;
        }
        self.cancelDelayedDisableGesture();
        self.cancelDelayedEnableGesture();
        self.perform(#selector(self.hideQuickPageNavigator), with: nil, afterDelay: 0.1)
        FTRefreshViewController.addObserversForHideNewPageOptions()
        let supportedModes: [RKDeskMode] = [.deskModePen,.deskModeMarker,.deskModeLaser,.deskModeEraser,.deskModeShape, .deskModeFavorites];
        guard supportedModes.contains(self.currentDrawingMode) else {
            return;
        }
        
        if(touch.stylusType == kStylusApplePencil) {
            NotificationCenter.default.post(name: NSNotification.Name.init(FTPDFDisableGestures), object: self.view.window);
            disablePDFSelectionGesture();
        }
        else {
            self.scheduleDelayedDisableGesture()
        }
        let selectedShape = FTShapeType.savedShapeType()
        if self.currentDrawingMode == RKDeskMode.deskModeShape && selectedShape != .freeForm {
            self.delegate?.addShapeAnnotation()
            if let controller = self.delegate?.activeController() as? FTShapeAnnotationController {
                activeAnnotationController = controller
                self.strokeInProgress = true
                controller.processTouchesBegan(touch.activeUItouch, with: nil)
            }
            return
        }
        
        if(self.currentDrawingMode == RKDeskMode.deskModePen
            || self.currentDrawingMode == RKDeskMode.deskModeMarker
            || self.currentDrawingMode == RKDeskMode.deskModeShape
           || self.currentDrawingMode == RKDeskMode.deskModeLaser || self.currentDrawingMode == RKDeskMode.deskModeFavorites) {
            self.strokeInProgress = true
            self.processVertex(touch: touch, vertexType: .FirstVertex);
            self.displayLink?.isPaused = false;
        }
        
        if(self.currentDrawingMode == RKDeskMode.deskModeEraser) {
            self.strokeInProgress = true
            (self.delegate as? FTEraseTouchHandling)?.eraserTouchesBegan(touch);
        }
    }
    
    func stylusPenTouchMoved(_ touch: FTTouch!) {
        if(!self.strokeInProgress) {
            if let controller = self.delegate?.activeController() as? FTShapeAnnotationController {
                controller.processTouchesMoved(touch.activeUItouch, with: nil)
            } else {
                if let editableShapeAnnotaion, let uiTouch = touch.activeUItouch {
                    let touchLocation = uiTouch.location(in: self.view)
                    let previousLocation = uiTouch.previousLocation(in: self.view)
                    let distanceX = touchLocation.x - previousLocation.x
                    let distanceY = touchLocation.y - previousLocation.y
                    let totalDistance = sqrt(distanceX * distanceX + distanceY * distanceY)
                    if totalDistance > 0.5 {
                        self.delegate?.editShapeAnnotation(with:editableShapeAnnotaion, point: touch.activeUItouch.location(in: self.view))
                    }
                }
            }
            return;
        }
        
        if(touch.stylusType == kStylusApplePencil) {
            FTRefreshViewController.addObserversForHideNewPageOptions()
        }
        
        let selectedShape = FTShapeType.savedShapeType()
        if self.currentDrawingMode == RKDeskMode.deskModeShape && selectedShape != .freeForm {
            if let controller = self.delegate?.activeController() as? FTShapeAnnotationController {
                self.strokeInProgress = true
                controller.processTouchesMoved(touch.activeUItouch, with: nil)
            }
            return
        }
        
        if(self.currentDrawingMode == RKDeskMode.deskModePen
           || self.currentDrawingMode == RKDeskMode.deskModeMarker
           || self.currentDrawingMode == RKDeskMode.deskModeShape
           || self.currentDrawingMode == RKDeskMode.deskModeLaser || self.currentDrawingMode == RKDeskMode.deskModeFavorites) {
            self.strokeInProgress = true
            self.processVertex(touch: touch, vertexType: .InterimVertex);
            self.displayLink?.isPaused = false;
        }
        if(self.currentDrawingMode == RKDeskMode.deskModeEraser) {
            (self.delegate as? FTEraseTouchHandling)?.eraserTouchesMoved(touch);
        }
    }
    
    func stylusPenTouchEnded(_ touch: FTTouch!) {
        self.stylusPenTouchEnded(touch, isShapeEnabled: false);
    }
    
    func stylusPenTouchEnded(_ touch: FTTouch,isShapeEnabled: Bool = false) {
        self.cancelDelayedDisableGesture();
        
        if(!self.strokeInProgress) {
            if let controller = self.delegate?.activeController() as? FTShapeAnnotationController {
                controller.processTouchesEnded(touch.activeUItouch, with: nil)
                controller.generateStrokeSegments()
                self.delegate?.endActiveShapeAnnotation(with: controller.shapeAnnotation)
                controller.shapeAnnotation.inLineEditing = false
            } else {
                editableShapeAnnotaion?.inLineEditing = false
            }
            editableShapeAnnotaion = nil
            return;
        }
        self.strokeInProgress = false;

        let selectedShape = FTShapeType.savedShapeType()
        if self.currentDrawingMode == RKDeskMode.deskModeShape && selectedShape != .freeForm {
            if let controller = self.delegate?.activeController() as? FTShapeAnnotationController {
                controller.processTouchesEnded(touch.activeUItouch, with: nil)
            }
            return
        }
        
        if(self.currentDrawingMode == RKDeskMode.deskModePen
        || self.currentDrawingMode == RKDeskMode.deskModeMarker
        || self.currentDrawingMode == RKDeskMode.deskModeShape
           || self.currentDrawingMode == RKDeskMode.deskModeLaser || self.currentDrawingMode == RKDeskMode.deskModeFavorites) {
            self.processVertex(touch: touch, vertexType: .LastVertex,isShapeEnabled: isShapeEnabled)
        }
       
        if(self.currentDrawingMode == RKDeskMode.deskModeEraser) {
            (self.delegate as? FTEraseTouchHandling)?.eraserTouchesEnded(touch);
        }
        
        if touch.stylusType == kStylusApplePencil {
            FT24HrEventLogger.trackEvent("ApplePencilUser",
                                         screen: nil,
                                         maxCounter: 0,
                                         param: nil);
        }
        if self.delegate?.mode == FTRenderModeZoom {
            var eventName = "ZoomModeUser";
            if touch.stylusType == kStylusApplePencil {
                eventName = "ZoomModeUser_ApplePencil"
            }
            FT24HrEventLogger.trackEvent(eventName,
                                         screen: nil,
                                         maxCounter: 5,
                                         param: nil);
        }
        
        self.displayLink?.isPaused = true
    }
    func stylusPenTouchCancelled(_ touch: FTTouch!) {
        self.cancelDelayedDisableGesture();
        if(!self.strokeInProgress) {
            return;
        }
        self.strokeInProgress = false;
        if(nil != self.currentStroke) {
            self.cancelCurrentStroke();
            if let del = self.delegate, del.mode == FTRenderModeZoom {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: FTZoomRenderViewDidCancelledTouches), object: self.view.window);
            }
        }
        
        if self.currentDrawingMode == .deskModeLaser {
            (self.delegate as? FTLaserTouchEventsHandling)?.cancelCurrentLaserStroke();
        }
        if self.currentDrawingMode == .deskModeShape {
            self.removeActiveAnnotation()
            activeAnnotationController = nil
        }
        if(self.currentDrawingMode == RKDeskMode.deskModeEraser ) {
            (self.delegate as? FTEraseTouchHandling)?.eraserTouchesCancelled(touch);
        }
        self.displayLink?.isPaused = true
    }
    
    private func removeActiveAnnotation() {
        if let activeVc = self.activeAnnotationController,let del = self.delegate, del.activeController() == nil {
            activeVc.delegate?.annotationControllerDidRemoveAnnotation(activeVc, annotation: activeVc.annotation)
        }
    }
    
    func stylusPenButtonAction(_ actionToPerform: RKAccessoryButtonAction) {
        NotificationCenter.default.post(name: Notification.Name("FTPressuePenActionChangedNotification"),
                                        object: nil,
                                        userInfo: ["PressurePenAction" : NSNumber(value: actionToPerform.rawValue)]);
    }
    
    @objc fileprivate func delayedDisableGesture()
    {
        NotificationCenter.default.post(name: NSNotification.Name.init(FTPDFDisableGestures), object: self.view.window);
    }
    
    fileprivate func scheduleDelayedDisableGesture()
    {
        self.perform(#selector(delayedDisableGesture),
                     with: nil,
                     afterDelay: 0.3);
        scheduleDelayedDisablePDFSelectionGesture()
    }
    
    fileprivate func cancelDelayedDisableGesture()
    {
        cancelDelayedDisablePDFSelectionGesture()
        NSObject.cancelPreviousPerformRequests(withTarget: self,
                                               selector: #selector(delayedDisableGesture),
                                               object: nil);
    }

    
    fileprivate func cancelDelayedDisablePDFSelectionGesture()
    {
        NSObject.cancelPreviousPerformRequests(withTarget: self,
                                               selector: #selector(disablePDFSelectionGesture),
                                               object: nil);
    }
    
    fileprivate func scheduleDelayedDisablePDFSelectionGesture()
    {
        self.perform(#selector(disablePDFSelectionGesture),
                     with: nil,
                     afterDelay: 0.6);
    }

    @objc fileprivate func disablePDFSelectionGesture() {
        self.pdfSelectionView?.allowsSelection = false;
    }

}

extension FTOnScreenWritingViewController {
    
    @objc private func hideQuickPageNavigator() {
        FTQuickPageNavigatorViewController.hidePageNavigator(forController: self)
    }
    
    func addObserversForQuickPageNavigator(){
        self.pageNavigationShowObserver = NotificationCenter.default.addObserver(forName: .quickPageNavigatorShowNotification,
                                               object: nil,
                                               queue: nil)
        { [weak self] (_) in
            if let `self` = self {
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.hideQuickPageNavigator), object: nil)
            }
        };
    }
    
}
