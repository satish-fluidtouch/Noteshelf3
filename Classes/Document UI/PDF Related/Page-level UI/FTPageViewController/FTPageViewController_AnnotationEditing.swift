//
//  FTPageViewController_AnnotationEditing.swift
//  Noteshelf
//
//  Created by Amar on 15/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

//MARK:- Annotation Add/End Editing
@objc extension FTPageViewController {
    func endEditingActiveAnnotation(_ annotation : FTAnnotation?,refreshView : Bool)
    {
        guard let activeController = self.activeAnnotationController else { return };
        self.delegate?.removePencilProMenuIfExist()
        if ((nil == annotation) || (annotation == activeController.annotation)) {
            var refreshArea = activeController.annotation.renderingRect;
            activeController.annotation.setSelected(false, for: self.windowHash);
            activeController.endEditingAnnotation();
            refreshArea = refreshArea.union(activeController.annotation.renderingRect);
            
            activeController.view.removeFromSuperview();
            activeController.removeFromParent();
            
            if refreshView {
                let properties = FTRenderingProperties();
                properties.synchronously = true;
                properties.forcibly = true;
                self.refresh(refreshArea,
                             scale: self.pageContentScale,
                             renderProperties: properties);
            }
            self.activeAnnotationController = nil;
            
            var userInfo : [String : Any] = [String : Any]();
            if let window = self.view.window {
                userInfo[FTRefreshWindowKey] = window;
            }

            if(annotation?.annotationType == .text) {
                refreshArea = .null;
            }
            postRefreshNotification(refreshArea);
        }
    }
    
    func addAnnotation(info : FTAnnotationInfo)
    {
        self.delegate?.removePencilProMenuIfExist()
        self.endEditingActiveAnnotation(nil, refreshView: true);
        if let annotation = info.annotation() {
            annotation.associatedPage = self.pdfPage;
            if(info.enterEditMode) {
                if let controller = (annotation as? FTEditAnnotationInterface)?.editController(delegate: self,
                                                                                               mode: .create) {
                    annotation.setSelected(true, for: self.windowHash);
                    self.scrollView?.contentHolderView.addSubview(controller.view);
                    self.addChild(controller);
                    self.view.layoutIfNeeded();
                    self.activeAnnotationController = controller;
                    if let textInfo = info as? FTTextAnnotationInfo,textInfo.fromConvertToText {
                        
                    }
                    else {
                        controller.processEvent(.singleTap,at:CGPoint.zero);
                    }
                }
            }
            else {
                self.addAnnotations([annotation], refreshView: true);
            }
        }
    }
    
    func saveActiveAnnotationIfAny()
    {
        self.activeAnnotationController?.saveChanges();
    }
}

//MARK:- Internal methods
internal extension FTPageViewController
{
    func annotation(type : FTProcessEventType,
                    atPoint point : CGPoint) -> FTAnnotation?
    {
        var annotation : FTAnnotation?;
        
        // TODO: (AK) Optimise, ideally this should be looped through the tiled annotations like Eraser
        let annotations = self.pdfPage?.annotations().reversed() ?? [FTAnnotation]();
        let scaledDownPoint = CGPointScale(point, 1/self.pageContentScale);
        for eachAnnotation in annotations {
            var canHandle = false;
            if(!eachAnnotation.isReadonly) {
                switch type {
                case .longPress:
                    if let _annotation = eachAnnotation as? FTAnnotationLongPressHandler {
                        canHandle = _annotation.canHandleLongPressEvent(atPoint: scaledDownPoint);
                    }
                case .singleTap:
                    if let _annotation = eachAnnotation as? FTAnnotationSingleTapHandler {
                        canHandle = _annotation.canHandleSingleTapEvent(atPoint: scaledDownPoint)
                    }
                case .singleTapSelection:
                    canHandle = eachAnnotation.allowsSingleTapSelection(atPoint: scaledDownPoint, mode: currentDeskMode())
                default:
                    break;
                }
            }
            if(canHandle) {
                annotation = eachAnnotation;
                break;
            }
        }
        return annotation;
    }
    
    func editAnnotation(_ annotation : FTAnnotation,
                        eventType : FTProcessEventType,
                        at point: CGPoint)
    {
        var startEditing = true;
        if let activeAnnotation = self.activeAnnotationController?.annotation, annotation == activeAnnotation {
            startEditing = false;
        }
        if  (currentDeskMode() == .deskModeReadOnly || currentDeskMode() == .deskModeView) && annotation.allowsEditing{
            startEditing = false;
        }
        if startEditing {
            if annotation.isLocked {
                showUnlockMenu(annotation: annotation)
            } else {
                if let groupId = annotation.groupId {
                    self.enterGroupEditing(groupId: groupId,
                                           eventType: eventType,
                                           at: point)
                } else {
                    self.enterEditing(annotation: annotation,
                                      eventType: eventType,
                                      at: point);
                }
            }
        }
    }
}

//MARK:- Private Methods
private extension FTPageViewController
{
    func showUnlockMenu(annotation: FTAnnotation) {
        if let contentView = self.scrollView?.contentHolderView {
            self.selectedAnnotation = annotation
            let unlockMenuItem = UIMenuItem(title: NSLocalizedString("Unlock", comment: "Unlock"), action: #selector(unlockMenuAction(_:)))
            UIMenuController.shared.menuItems = [unlockMenuItem]
            self.becomeFirstResponder()
            let rect = CGRectScale(annotation.boundingRect, self.pageContentScale)
            UIMenuController.shared.showMenu(from: contentView, rect: rect)
        }
    }

    @objc func unlockMenuAction(_ sender: Any?) {
        track("textbox_unlock_tapped", params: [:], screenName: FTScreenNames.textbox)
        self.selectedAnnotation?.isLocked = false
        if let annotation = self.selectedAnnotation {
            enterEditing(annotation: annotation,
                         eventType: .singleTap,
                         at:CGPoint.zero);
        }
    }

    func enterEditing(annotation : FTAnnotation,
                      eventType : FTProcessEventType,
                      at point:CGPoint) {
        
        func startEditing() {
            annotation.currentScale = self.pageContentScale;
            if let controller = (annotation as? FTEditAnnotationInterface)?.editController(delegate: self,
                                                                                           mode: .edit) {
                if(eventType == .longPress || eventType == .singleTap) {
                    NotificationCenter.default.post(name: Notification.Name.FTEnteringEditMode,
                                                    object: self.delegate,
                                                    userInfo: ["annotation" : annotation,
                                                               "EventType" : NSNumber(value: eventType.rawValue)]);
                }

                annotation.setSelected(true, for: self.windowHash);
                self.contentHolderView?.addSubview(controller.view);
                self.addChild(controller);
                self.activeAnnotationController = controller;
                let pointInView = self.contentHolderView?.convert(point, to: controller.view);
                controller.processEvent(eventType,at: pointInView ?? CGPoint.zero);

                self.updateLowResolutionImageBackgroundView();
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.delayedRender(_:)), object: self.activeAnnotationController?.annotation);
                self.perform(#selector(self.delayedRender(_:)), with: annotation, afterDelay: 0.001);
            }
        }
        
        self.endEditingActiveAnnotation(nil, refreshView: true);
        if(annotation.shouldAlertForMigration) {
            UIAlertController.showAlertForImageAnnotationMigration(from: self.view.window?.visibleViewController, onCompletion: { (proceed) -> (Void) in
                if(proceed) {
                    startEditing();
                }
            })
        }
        else {
            startEditing();
        }
    }

    func enterGroupEditing(groupId : String,
                           eventType : FTProcessEventType,
                           at point:CGPoint) {
        guard let groupAnnotations = self.pdfPage?.annotations(groupId: groupId) else {
            return
        }

        initiateGroupedAnnotationEditing(annotations: groupAnnotations)
        FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.clip_tap)
    }

    @objc func delayedRender(_ annotation : FTAnnotation)
    {
        let displayRect = annotation.renderingRect;
        if(displayRect.width > 0 && displayRect.height > 0) {
            let properties = FTRenderingProperties();
            properties.renderImmediately = true;
            self.refresh(displayRect,
                         scale:self.pageContentScale,
                         renderProperties: properties);
        }
    }
}

//MARK:- FTAnnotationEditControllerDelegate
@objc extension FTPageViewController : FTAnnotationEditControllerDelegate
{
    func shapeAnnotationOptions(perform action:FTShapeEditAction, annotation: FTAnnotation) {
        switch action {
        case .copy:
            self.copyShapeAnnotation(annotation: annotation);
        case .cut:
            self.performCutCommand(annotation: annotation)
        case .delete:
            self.performDeleteCommand(annotation: annotation, shouldRefresh: true)
        }
    }
    
    func annotationController(_ controller: FTAnnotationEditController, scrollToRect targetRect: CGRect) {
        let scrollView: UIScrollView?
        if self.layoutType == .vertical {
            scrollView = self.delegate?.mainScrollView;
        }
        else {
            scrollView = self.scrollView;
        }
        if let _scrollView = scrollView {
            let rectToScroll = _scrollView.convert(targetRect, from: controller.view).integral;
            _scrollView.scrollRectToVisible(rectToScroll, animated: true);
        }
    }
    
    func annotationControllerDidRemoveAnnotation(_ controller: FTAnnotationEditController, annotation: FTAnnotation) {
        if(self.pdfPage?.annotations().contains(annotation) ?? false) {
            self.removeAnnotations([annotation], refreshView: false);
        }
        controller.view.removeFromSuperview();
        controller.removeFromParent();
        self.activeAnnotationController = nil;
        #if targetEnvironment(macCatalyst)
        self.activeAnnotationController = nil;
        #endif
        if let writeView = self.writingView,
           writeView.mode == FTRenderModeZoom {
               let notification = Notification.init(name: Notification.Name.FTZoomRenderViewDidEndCurrentStroke,
                                                    object: self.view.window,
                                                    userInfo: [FTImpactedRectKey : NSValue.init(cgRect: annotation.renderingRect)]);
               NotificationCenter.default.post(notification);
               
           }
        self.delegate?.removeInputAccessoryViewForTextAnnotation()
    }
    
    func annotationControllerDidAddAnnotation(_ controller: FTAnnotationEditController, annotation: FTAnnotation) {
        self.addAnnotations([annotation], refreshView: false);
    }
    
    func annotationControllerDidChange(_ controller: FTAnnotationEditController, undoableInfo: FTUndoableInfo) {
        if(self.pdfPage?.annotations().contains(controller.annotation) ?? false) {
            self.updateAnnotation(controller.annotation,
                                  info: undoableInfo,
                                  shouldRefresh: false);
        }
    }
    
    func moveAnnotationToFront(_ annotation: FTAnnotation) {
        self.endEditingActiveAnnotation(annotation, refreshView: false)
        self.moveAnnotationsToFront([annotation], shouldRefresh: true)
    }
    
    func moveAnnotationToBack(_ annotation: FTAnnotation) {
        self.endEditingActiveAnnotation(annotation, refreshView: false)
        self.moveAnnotationsToBack([annotation], shouldRefresh: true)
    }

    func contentScale() -> CGFloat {
        return self.pageContentScale;
    }
    
    func visibleRect() -> CGRect {
        return self.scrollView?.visibleRect() ?? CGRect.null;
    }
    func annotationControllerDidCancel(_ controller: FTAnnotationEditController) {
        if let activeController = self.activeAnnotationController, activeController == controller {
            self.endEditingActiveAnnotation(nil, refreshView: true);
        }
    }
    
    func convertToStroke(_ controller : FTAnnotationEditController,
                         annotation : FTAnnotation) {
        if let textAnnotation = annotation as? FTTextAnnotation {
            if let string = textAnnotation.attributedString?.string {
                self.removeAnnotations([annotation], refreshView: false);
                self.convertTextToStroke(string,origin: textAnnotation.boundingRect.origin);
            }
        }
    }
    
    func isZoomModeEnabled() -> Bool {
        return self.isInZoomMode()
    }
    
    func refreshView(refreshArea: CGRect) {
        let properties = FTRenderingProperties();
        properties.synchronously = true;
        properties.forcibly = true;
        self.refresh(refreshArea,
                     scale: self.pageContentScale,
                     renderProperties: properties);
        postRefreshNotification()
    }
    
    func annotationControllerDidAdded(_ controller: FTTextAnnotationViewController) {
        self.delegate?.getInputAccessoryViewForTextAnnotation(controller)
    }
    
    func annotationControllerDidEnded(_ controller: FTTextAnnotationViewController) {
        self.delegate?.removeInputAccessoryViewForTextAnnotation()
    }
    
    #if targetEnvironment(macCatalyst)
    func annotationControllerWillBeginEditing(_ controller : FTTextAnnotationViewController) {
//        guard let parentController = self.parent else {
//            return
//        }
//        if let controller = self.inputAccessoryController {
//            controller.view?.removeFromSuperview()
//            controller.removeFromParent()
//            self.inputAccessoryController = nil
//        }
//        if let targetView = parentController.view {
//            let accerssoryController = FTTextInputAccerssoryViewController.viewController(controller, textDelegate: controller)
//            accerssoryController.view.alpha = 0.0
//            targetView.addSubview(accerssoryController.view)
//            parentController.addChild(accerssoryController)
//            self.inputAccessoryController = accerssoryController
//
//            targetView.addConstraint(NSLayoutConstraint(item: accerssoryController.view, attribute: .trailing, relatedBy: .equal, toItem: targetView, attribute: .trailing, multiplier: 1, constant: 0))
//            targetView.addConstraint(NSLayoutConstraint(item: accerssoryController.view, attribute: .leading, relatedBy: .equal, toItem: targetView, attribute: .leading, multiplier: 1, constant: 0))
//            targetView.addConstraint(NSLayoutConstraint(item: accerssoryController.view, attribute: .bottom, relatedBy: .equal, toItem: targetView, attribute: .bottom, multiplier: 1, constant: 0))
//            targetView.addConstraint(NSLayoutConstraint(item: accerssoryController.view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 44))
//
//            self.scrollView?.accessoryViewHeight = 44;
//            UIView.animate(withDuration: 0.3, animations: {
//                accerssoryController.view.alpha = 1.0
//            }) { (_) in
//            }
//        }
    }
        
    func getInputAccessoryViewController() -> FTTextToolBarViewController? {
        nil//return self.inputAccessoryController
    }
    #endif
}

//MARK:- Undo/Redo management
extension FTPageViewController
{
    func updateAnnotation(_ annotation : FTAnnotation,
                         info: FTUndoableInfo,
                         shouldRefresh: Bool)
    {
        let currentBoundingRect = annotation.renderingRect;

        if annotation.supportsUndo {
            (self.pdfPage as? FTPageUndoManagement)?.update(annotation: annotation, info: info, shouldUpdate: false)
        }
        if(shouldRefresh) {
            annotation.forceRender = true;
            
            let refreshRect = info.renderingRect.union(currentBoundingRect);
            let properties = FTRenderingProperties()
            properties.synchronously = true;
            self.refresh(refreshRect,
                         scale:self.pageContentScale,
                         renderProperties: properties);
        }
        if let activeAnnotation = self.activeAnnotationController?.annotation, activeAnnotation == annotation {
            self.activeAnnotationController?.refreshView();
        }
    }
}

extension FTPageViewController {
    var windowHash: Int {
        return self.view.window?.hash ?? 0;
    }
}
