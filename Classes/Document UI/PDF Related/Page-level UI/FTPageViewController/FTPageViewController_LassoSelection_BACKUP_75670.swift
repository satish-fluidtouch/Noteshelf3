//
//  FTPageViewController_LassoSelection.swift
//  Noteshelf
//
//  Created by Amar on 27/05/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
#if !targetEnvironment(macCatalyst)
import Flurry_iOS_SDK
#endif
import MobileCoreServices

private let customTransitioningDelegate = FTSlideInPresentationManager(mode: .topToBottom)

//MARK:- Lasso View add/remove -
extension FTPageViewController
{
    @objc func finalizeLassoView() {
        self.normalizeLassoView();
        self.lassoSelectionView?.resignFirstResponder();
        self.lassoSelectionView?.removeFromSuperview();
        self.lassoSelectionView = nil;
        self.removeLassoObserver();
    }
    
    @objc func normalizeLassoView() {
        self.lassoContentSelectionViewController?.endEditing();
        if(self.lassoSelectionView?.isSelectionActive ?? false) {
            self.lassoSelectionView?.finalizeMove();
        }
    }

    var isSelectionActive: Bool {
        return self.lassoSelectionView?.isSelectionActive ?? false;
    }
    
    func showPasteOptionsIfNeeded(at touchPoint:CGPoint) {
        guard self.currentDeskMode() == .deskModeClipboard,
            let contentView = self.contentHolderView else {
                return
        }
        self.lassoContentSelectionViewController?.endEditing();
        if nil == self.activeAnnotationController,UIPasteboard.canPasteLassoContent() {
            self.showCopyPasteOptions(touchPoint,in:contentView);
        }
    }
    
    func canAcceptTouch(for gesture:UIGestureRecognizer) -> Bool {
        guard let contentView = self.contentHolderView else {
            return false;
        }
        if(nil != self.lassoContentSelectionViewController) {
            return false;
        }
        let point = gesture.location(in: contentView);
        if let activeController = self.activeAnnotationController,
            activeController.isPointInside(point, fromView: contentView) {
            return false;
        }
        
        if let lassoView = self.lassoSelectionView, let antsView = lassoView.antsView {
            let currentAntsViewPoint = contentView.convert(point, to: antsView);
            if antsView.isPointInsidePath(currentAntsViewPoint) {
                return false;
            }
        }
        return true;
    }
    
    func addLassoViewIfNeeded() {
        guard isCurrent, let _scrollView = self.scrollView else {
            return;
        }
        if(nil == lassoSelectionView) {
            let view = FTLassoSelectionView(frame: _scrollView.visibleRect());
            view.delegate = self;
            self.lassoSelectionView = view;
            if let _view = activeAnnotationController?.view {
                self.contentHolderView?.insertSubview(view, belowSubview: _view)
            } else {
                self.contentHolderView?.addSubview(view);
            }
            self.addLassoObserver();
        }
        self.lassoSelectionView?.frame = _scrollView.visibleRect();
    }
    
    func removeLassoView() {
        self.finalizeLassoView();
    }
    
    @objc func showMenu(_ sourceView : UIView?) -> Bool {
        var menuShown = false;
        
        self.lassoContentSelectionViewController?.endEditing();
        if let lassoView = self.lassoSelectionView {
            if(lassoView.isSelectionActive) {
                lassoView.showMenuFrom(rect: lassoView.antsView?.frame ?? CGRect.zero);
                menuShown = true;
            }
            else {
                self.finalizeLassoView();
            }
        }
        return menuShown;
    }
    
    func performPasteOperation() {
        self.paste(at: nil);
    }
}

//MARK:- FTLassoSelectionViewDelegate -
extension FTPageViewController: FTLassoSelectionViewDelegate {
    func lassoSelectionViewDidEndTouch(_ lassoSelectionView: FTLassoSelectionView) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: FTPDFEnableGestures),
                                        object: self.view.window);
    }
    
    func lassoSelectionView(_ lassoSelectionView: FTLassoSelectionView,
                            didBeganTouch touch: UITouch?) {
        if nil != touch {
            NotificationCenter.default.post(name: Notification.Name(rawValue: FTPDFDisableGestures), object: self.view.window);
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: "FTDidReceiveLassoTouch"),
                                        object: self.view.window,
                                        userInfo: ["PageVC" : self]);
    }
    
    func lassoSelectionView(_ lassoSelectionView: FTLassoSelectionView, selectionAreaMovedByOffset offset: CGPoint) {
        let selectedAnnotations = self.lassoInfo.selectedAnnotations;
        self.lassoInfo.lassoOffset = CGPointTranslate(self.lassoInfo.lassoOffset, offset.x, offset.y);

        if let lassowritingView = self.writingView as? FTLassoProtocol {
            lassowritingView.moveSelectedAnnotations(selectedAnnotations,
                                                     offset: offset,
                                                     refreshForcibly: false);
        }
    }
    
    func lassoSelectionView(_ lassoSelectionView: FTLassoSelectionView, initiateSelection cutPath: CGPath) {
        self.lassoInfo.reset(clearAnnotation: true);

        NotificationCenter.default.post(name: NSNotification.Name(rawValue: FTPDFEnableGestures),
                                        object: self.view.window);
        
        let scale = self.pageContentScale;
        let annotations = self.pdfPage?.annotations();
        let offset = self.scrollView?.visibleRect().origin ?? CGPoint.zero;
        
        annotations?.forEach({ (eachAnnotation) in
            if eachAnnotation.allowsLassoSelection,
                let annotate = eachAnnotation as? FTAnnotationContainsProtocol,
                annotate.intersectsPath(cutPath, withScale: scale, withOffset: offset) {
                eachAnnotation.selected = true;
                self.lassoInfo.selectedAnnotations.append(eachAnnotation);
            }
        });
    }
    
    func lassoSelectionViewFinalizeMoves(_ lassoSelectionView: FTLassoSelectionView) {
        let selectedAnnotations = self.lassoInfo.selectedAnnotations;

        selectedAnnotations.forEach { (eachAnnotation) in
            eachAnnotation.selected = false;
        }
        
        if let lassowritingView = self.writingView as? FTLassoProtocol {
            lassowritingView.finalizeSelection(byAddingAnnotations: nil);
        }
        
        self.lassoInfo.reset(clearAnnotation: true);

        var userInfo: [String:Any]?;
        if let window = self.view.window {
            userInfo = [FTRefreshWindowKey: window];
        }
        
        NotificationCenter.default.post(name: Notification.Name.FTRefreshExternalView,
                                        object: self.pdfPage,
                                        userInfo: userInfo);
    }

    func lassoSelectionViewDidCompleteMove(_ lassoSelectionView: FTLassoSelectionView) {
        let selectedAnnotations = self.lassoInfo.selectedAnnotations;
        if let lassoWritingView = self.writingView as? FTLassoProtocol,
            let antsView = lassoSelectionView.antsView,
            let path = antsView.currentPath {
            let lassoOffet = self.lassoInfo.lassoOffset;
            lassoWritingView.lassoDidMoved(byOffset: CGPointScale(lassoOffet, -1));

            var frame = antsView.frame;
            frame.origin.x -= lassoOffet.x;
            frame.origin.y -= lassoOffet.y;
            antsView.frame = frame;

            var info = [String:Any]();
            info["antsViewFrame"] = frame;
            info["antsViewPath"] = path;
            info["selectedAnotations"] = selectedAnnotations;
            info["zoomScale"] = self.pageContentScale;

            self.translateSelectionViewWith(properties: info,by:lassoOffet);
            self.pdfPage?.isDirty = true;
        }
        self.lassoInfo.lassoOffset = CGPoint.zero;
    }
    
    func lassoSelectionView(_ lassoSelectionView: FTLassoSelectionView,
                            canPerform action:FTLassoAction) -> Bool
    {
        var supports = false;
        guard let page = self.pdfPage else {
            return supports;
        }
        let selectedAnnotations = self.lassoInfo.selectedAnnotations;
        if(action == .convertToText) {
            let pageAnnotations = page.annotations();
            var isMigratedNotebook = false;
            if nil != pageAnnotations.first(where: {$0.isReadonly}) {
                isMigratedNotebook = true;
            }
            let strokeAnnotations = selectedAnnotations.filter({$0.supportsHandwrittenRecognition});
            let hasPenStrokes = !strokeAnnotations.isEmpty;

            supports = (hasPenStrokes || isMigratedNotebook);
        }
        else if(action == .takeScreenshot){
            supports = true;
        }
        else {
            supports = !selectedAnnotations.isEmpty;
        }
        return supports;
    }
    
    func lassoSelectionView(_ lassoSelectionView: FTLassoSelectionView,
                            perform action: FTLassoAction) {
        switch action {
        case .cut:
            self.lassoSelectionViewCutCommand(lassoSelectionView);
        case .copy:
            self.lassoSelectionViewCopyCommand(lassoSelectionView)
        case .delete:
            self.lassoSelectionViewDeleteCommand(lassoSelectionView);
        case .resize:
            self.lassoSelectionViewTransformCommand(lassoSelectionView);
        case .takeScreenshot:
            self.lassoSelectionViewTakeScreenshotCommand(lassoSelectionView);
        case .color:
            self.lassoSelectionViewColorCommand(lassoSelectionView);
        case .convertToText:
            self.lassoSelectionViewRecognitionCommand(lassoSelectionView);
        case .moveToFront:
            self.lassoSelectionViewMoveToFrontCommand(lassoSelectionView);
        case .moveToBack:
            self.lassoSelectionViewMoveToBackCommand(lassoSelectionView);
        }
    }
    
    #if targetEnvironment(macCatalyst)
    func lassoSelectionViewPasteCommand(_ lassoSelectionView: FTLassoSelectionView, at touchedPoint: CGPoint) {
        self.paste(at: touchedPoint);
    }
    #endif
}

//MARK:- Lasso Actions -
private extension FTPageViewController {
    func lassoSelectionViewCutCommand(_ lassoSelectionView: FTLassoSelectionView) {
        let selectedAnnotations = self.lassoInfo.selectedAnnotations;
        if selectedAnnotations.isEmpty {
            return;
        }
        
        #if !targetEnvironment(macCatalyst)
        let flurryInfo = ["Type" : "Cut",
                          "Annotation Count" : selectedAnnotations.count] as [String : Any];
        
        Flurry.logEvent("PDF Clipboard Operation", withParameters: flurryInfo);
        #endif
        FTCLSLog("PDF Clipboard Operation - Cut");

        self.copySelectedAnnotations();

        selectedAnnotations.forEach { (annotation) in
            annotation.selected = false;
        }
        self.removeAnnotations(selectedAnnotations, refreshView: true);
        self.lassoSelectionView?.resignFirstResponder();
        self.lassoInfo.reset();

        if let lassowritingView = self.writingView as? FTLassoProtocol {
            lassowritingView.finalizeSelection(byAddingAnnotations: nil);
        }
    }
    
    func lassoSelectionViewCopyCommand(_ lassoSelectionView: FTLassoSelectionView) {
        let selectedAnnotations = self.lassoInfo.selectedAnnotations;
        if selectedAnnotations.isEmpty {
            return;
        }
        
        #if !targetEnvironment(macCatalyst)
        let flurryInfo = ["Type" : "Copy",
                          "Annotation Count" : selectedAnnotations.count] as [String : Any];
        
        Flurry.logEvent("PDF Clipboard Operation", withParameters: flurryInfo);
        #endif
        FTCLSLog("PDF Clipboard Operation - Copy");

        self.copySelectedAnnotations();

        self.lassoSelectionView?.resignFirstResponder();
        self.lassoInfo.reset();
    }
    
    func lassoSelectionCanShowConvert(toText lassoSelectionView: FTLassoSelectionView) -> Bool {
        guard let page = self.pdfPage else {
            return false;
        }
        
        let pageAnnotations = page.annotations();
<<<<<<< HEAD

        var isMigratedNotebook = false;
        if nil != pageAnnotations.first(where: {$0.isReadonly}) {
            isMigratedNotebook = true;
        }
        let strokeAnnotations = pageAnnotations.filter({$0.supportsHandwrittenRecognition});
        let hasPenStrokes = !strokeAnnotations.isEmpty;

=======

        var isMigratedNotebook = false;
        if nil != pageAnnotations.first(where: {$0.isReadonly}) {
            isMigratedNotebook = true;
        }
        let strokeAnnotations = pageAnnotations.filter({$0.supportsHandwrittenRecognition});
        let hasPenStrokes = !strokeAnnotations.isEmpty;

>>>>>>> develop
        return hasPenStrokes || isMigratedNotebook;
    }
    
    func lassoSelectionViewPasteCommand(_ lassoSelectionView: FTLassoSelectionView, at touchedPoint: CGPoint) {
        self.paste(at: touchedPoint);
    }
    
    func lassoSelectionViewTakeScreenshotCommand(_ lassoSelectionView: FTLassoSelectionView) {
        let selectedAnnotations = self.lassoInfo.selectedAnnotations;
        #if !targetEnvironment(macCatalyst)
        let flurryInfo = ["Type" : "Screenshot",
                          "Annotation Count" : selectedAnnotations.count] as [String : Any];
        
        Flurry.logEvent("PDF Clipboard Operation", withParameters: flurryInfo);
        #endif
        FTCLSLog("PDF Clipboard Operation - Screenshot");

        self.lassoSelectionView?.resignFirstResponder();
        self.lassoInfo.reset();

        if let screenshot = self.lassoSelectedAnnotationsSnapshotEnclosingRect(lassoSelectionView) {
            self.showShareScreenshot(screenshot);
        }
    }
    
    func lassoSelectionViewColorCommand(_ lassoSelectionView: FTLassoSelectionView) {
        let selectedAnnotations = self.lassoInfo.selectedAnnotations;
        if selectedAnnotations.isEmpty {
            return;
        }
        self.presentColorPickerController(with: lassoSelectionView);
    }
    
    func lassoSelectionViewRecognitionCommand(_ lassoSelectionView: FTLassoSelectionView) {
        guard let page = self.pdfPage,
            let cache = page.parentDocument?.localMetadataCache else {
            return;
        }

        let convertToText = FTConvertToTextViewController();
        convertToText.canvasSize = page.pdfPageRect.size;
        convertToText.annotations = [FTAnnotation]();
        convertToText.defaultTextFont = cache.defaultBodyFont;
        convertToText.defaultTextColor = cache.defaultTextColor;
        convertToText.currentPage = page;
        convertToText.delegate = self;

        convertToText.searchOptions = self.delegate?.finderSearchOptions ?? FTFinderSearchOptions();

        let selectedAnnotations = self.lassoInfo.selectedAnnotations;
        if(!selectedAnnotations.isEmpty) {
            let strokesArray = selectedAnnotations.filter{$0.supportsHandwrittenRecognition};
            convertToText.annotations = strokesArray;
        }
        self.parent?.ftPresentModally(convertToText, animated: true, completion: nil)
    }

    func lassoSelectionViewMoveToFrontCommand(_ lassoSelectionView: FTLassoSelectionView) {
        let selectedAnnotations = self.lassoInfo.selectedAnnotations;
        guard !selectedAnnotations.isEmpty else {
            return;
        }

        self.moveAnnotationsToFront(selectedAnnotations, shouldRefresh: true)

        self.lassoSelectionView?.resignFirstResponder();
        self.lassoInfo.reset();

        if let lassowritingView = self.writingView as? FTLassoProtocol {
            lassowritingView.finalizeSelection(byAddingAnnotations: nil);
        }
    }

    func lassoSelectionViewMoveToBackCommand(_ lassoSelectionView: FTLassoSelectionView) {
        let selectedAnnotations = self.lassoInfo.selectedAnnotations;
        guard !selectedAnnotations.isEmpty else {
            return;
        }

        self.moveAnnotationsToBack(selectedAnnotations, shouldRefresh: true)

        self.lassoSelectionView?.resignFirstResponder();
        self.lassoInfo.reset();

        if let lassowritingView = self.writingView as? FTLassoProtocol {
            lassowritingView.finalizeSelection(byAddingAnnotations: nil);
        }
    }
    
    func lassoSelectionViewTransformCommand(_ lassoSelectionView: FTLassoSelectionView) {
        self.initiateTransformSelection();
    }
    
    func lassoSelectionViewDeleteCommand(_ lassoSelectionView: FTLassoSelectionView) {
        
        let selectedAnnotations = self.lassoInfo.selectedAnnotations;
        if selectedAnnotations.isEmpty {
            return;
        }
        
        #if !targetEnvironment(macCatalyst)
        let flurryInfo = ["Type" : "Delete",
                          "Annotation Count" : selectedAnnotations.count] as [String : Any];
        
        Flurry.logEvent("PDF Clipboard Operation", withParameters: flurryInfo);
        #endif
        FTCLSLog("PDF Clipboard Operation - Delete");
        
        selectedAnnotations.forEach { (annotation) in
            annotation.selected = false;
        }

        self.removeAnnotations(selectedAnnotations, refreshView: true);
        self.lassoSelectionView?.resignFirstResponder();
        self.lassoInfo.reset();
        

        if let lassowritingView = self.writingView as? FTLassoProtocol {
            lassowritingView.finalizeSelection(byAddingAnnotations: nil);
        }

        var userInfo: [String:Any]?;
        if let window = self.view.window {
            userInfo = [FTRefreshWindowKey: window];
        }
        
        NotificationCenter.default.post(name: Notification.Name.FTRefreshExternalView,
                                        object: self.pdfPage,
                                        userInfo: userInfo);
    }
}

//MARK:- FTEditColorsViewControllerDelegate -
extension FTPageViewController: FTConvertToTextViewControllerDelegate {
    func didFinishConversion(withText recognisedString: String, controller: FTConvertToTextViewController) {
        
    }
    
    func didChooseReplace(withInfo recognitionInfo: FTRecognitionResult?, useDefaultFont: Bool, controller: FTConvertToTextViewController) {
        controller.dismiss(animated: true) {
            let selectedAnnotations = self.lassoInfo.selectedAnnotations;
            guard !selectedAnnotations.isEmpty,
                let _recognitionInfo = recognitionInfo else {
                return;
            }
            
            #if !targetEnvironment(macCatalyst)
            let flurryInfo = ["Type" : "ConvertToTextbox",
                              "Annotation Count" : selectedAnnotations.count] as [String : Any];
            
            Flurry.logEvent("PDF Clipboard Operation", withParameters: flurryInfo);
            #endif
            FTCLSLog("PDF Clipboard Operation - ConvertToTextbox");

            let writingScale = self.pageContentScale;

            let actualOffset = CGPoint.scale(self.lassoInfo.totalLassoOffset, 1/writingScale);
            
            selectedAnnotations.forEach { (annotation) in
                annotation.setOffset(actualOffset);
                annotation.selected = false;
            }

            let strokeAnnotations = selectedAnnotations.filter{$0.supportsHandwrittenRecognition};
            if !strokeAnnotations.isEmpty {
                self.removeAnnotations(strokeAnnotations, refreshView: true);
            }
            self.finalizeLassoView();
            self.lassoInfo.reset();

            if let lassoWritingView = self.writingView as? FTLassoProtocol {
                lassoWritingView.finalizeSelection(byAddingAnnotations: nil);
            }

            var userInfo: [String : Any]?;
            if let window = self.view.window {
                userInfo = [FTRefreshWindowKey: window];
            }
            NotificationCenter.default.post(name: Notification.Name.FTRefreshExternalView,
                                            object: self.pdfPage,
                                            userInfo: userInfo);
            
            var combinedRect = CGRect.null;
            
            _recognitionInfo.characterRects.forEach({ (rect) in
                if(rect != CGRect.zero) {
                    combinedRect = combinedRect.union(rect);
                }
            });
            if(combinedRect.isNull) {
                return;
            }
            self.delegate?.switch(.deskModeText, sourceView: nil);
            combinedRect = combinedRect.integral;
            
            let combinedRectWithPadding = combinedRect.insetBy(dx: -10, dy: -10);
            let info = FTTextAnnotationInfo();
            info.boundingRect = combinedRectWithPadding;
            info.scale = self.pageContentScale;
            info.localmetadataCache = self.pdfPage?.parentDocument?.localMetadataCache;

            if !useDefaultFont {
                var attrs = info.defaultTextTypingAttributes();
                var defaultFont = attrs[.font] as? UIFont ?? UIFont.defaultTextFont();
                if let stroke = controller.annotations?.first as? FTStroke {
                    attrs[.foregroundColor] = stroke.strokeColor;
                }

                let attrstring = NSMutableAttributedString(string: _recognitionInfo.recognisedString,
                                                           attributes: attrs);

                let range = NSRange(location: 0, length: attrstring.length);
                let constraintSize = CGSize(width: combinedRect.width, height: CGFloat.greatestFiniteMagnitude);
                for fontSize in 10..<999 {
                    defaultFont = defaultFont.withSize(CGFloat(fontSize));
                    attrstring.addAttribute(.font, value: defaultFont, range: range);
                    let expectedSize = attrstring.requiredSizeForAttributedStringConStraint(to: constraintSize);
                    if (expectedSize.height > (combinedRect.size.height-5)){
                        defaultFont = defaultFont.withSize(CGFloat(fontSize-1));
                        break;
                    }
                }
                attrstring.addAttribute(.font, value: defaultFont, range: range);
                info.attributedString = attrstring;
            }
            else {
                info.string = _recognitionInfo.recognisedString;
            }
            self.addAnnotation(info: info);
            self.saveActiveAnnotationIfAny();
        }
    }
    
    func didCancelConversion(_ controller: FTConvertToTextViewController) {
        
    }
}

//MARK:- FTEditColorsViewControllerDelegate -
extension FTPageViewController: FTEditColorsViewControllerDelegate {
    func editColorsWillDismiss(_ controller: FTEditColorsViewController) {
        
    }
    
    func colorSelected(_ controller: FTEditColorsViewController, hexColor: String) {
        let annotations = self.lassoInfo.selectedAnnotations
        if  !annotations.isEmpty, let color = UIColor(hexString: hexColor) {
            (self.pdfPage as? FTPageUndoManagement)?.update(annotations: annotations, color: color)
            if self.lassoSelectionView?.antsView != nil,
                let lassoWritingView = self.writingView as? FTLassoProtocol {
                lassoWritingView.moveSelectedAnnotations(annotations,
                                                         offset: .zero,
                                                         refreshForcibly: true)
            }
        }
    }

    func updateExistingColors(_ controller: FTEditColorsViewController) -> [String] {
        var userActivity : NSUserActivity?;
        if #available(iOS 13.0, *) {
            userActivity = self.view.window?.windowScene?.userActivity
        }
        let penRack = FTRack(type: .pen,userActivity: userActivity);
        penRack.colors = FTRackProvider.resetCurrentColorsInRack(ofType: penRack.type).compactMap({ (item) -> String? in
            return item
        })
        return penRack.colors
    }
    
    func replaceCurrentColors(_ controller: FTEditColorsViewController, _ colors: [String]) {
        var userActivity : NSUserActivity?;
        if #available(iOS 13.0, *) {
            userActivity = self.view.window?.windowScene?.userActivity
        }
        let penRack = FTRack(type: .pen,userActivity: userActivity);
        penRack.colors = colors
        FTRackProvider.replaceCurrentColorsInRack(penRack.colors, forType: penRack.type)
    }
}

//MARK:- Private Methods -
private extension FTPageViewController
{
    func copySelectedAnnotations() {
        let selectedAnnotations = self.lassoInfo.selectedAnnotations;
        guard let lassoVew = self.lassoSelectionView,
            let antsView = lassoVew.antsView,
            let scrollView = self.scrollView,
            let path = antsView.currentPath,
            let contentView = scrollView.contentHolderView else {
                return;
        }
        
        // Get the General pasteboard.
        let pasteBoard = UIPasteboard.general;
        
        selectedAnnotations.forEach { (annotaion) in
            annotaion.copyMode = true;
        }
        do {
            let annotationData = try NSKeyedArchiver.archivedData(withRootObject: selectedAnnotations, requiringSecureCoding: true);
            selectedAnnotations.forEach { (annotaion) in
                annotaion.copyMode = false;
            }
            
            var dict: [String: Any] = [String: Any]();
            dict["annotations"] = annotationData;
            dict["antsViewPath"] = UIBezierPath(cgPath: path);

            let zoomScale = self.pageContentScale;
            let oneByZoomScale = 1/zoomScale;

            let frame = antsView.frame;
            dict["antsViewFrame"] = CGRectScale(frame, oneByZoomScale);

            let offset = scrollView.contentOffset;
            
            var antsViewRelativeOrigin = lassoVew.convert(antsView.frame, to: contentView).origin;
            antsViewRelativeOrigin = CGPoint.scale(antsViewRelativeOrigin, oneByZoomScale);

            var antsViewOrigin = CGPointTranslate(antsView.frame.origin, offset.x, offset.y);
            antsViewOrigin = CGPoint.scale(antsViewOrigin, oneByZoomScale);

            let lastAnnotationRect = selectedAnnotations.last!.boundingRect;

            let offsetFromlastAnnotation = CGPoint(x: antsViewRelativeOrigin.x-lastAnnotationRect.origin.x, y: antsViewRelativeOrigin.y-lastAnnotationRect.origin.y);
            dict["offsetFromlastAnnotation"] = offsetFromlastAnnotation;

            dict["antsViewScale"] = zoomScale;
            dict["antsViewOriginAtNormalScale"] = antsViewOrigin;

            let pbData = try NSKeyedArchiver.archivedData(withRootObject: dict,
                                                          requiringSecureCoding: true);

            var pbInfo: [String: Any] = [String: Any]();
            pbInfo[UIPasteboard.pdfAnnotationUTI()] = pbData;
            var rect = CGRect.null;
            if let img = self.snapshotOf(annotations: selectedAnnotations, enclosedRect: &rect) {
                pbInfo[kUTTypePNG as String] = img;
            }
            pasteBoard.items = [pbInfo];
        }
        catch {
            
        }
    }
    
    func lassoSelectedAnnotationsSnapshotEnclosingRect(_ lassoSelectionView: FTLassoSelectionView) -> UIImage?
    {
        guard let contentHolderView = self.contentHolderView,
            let _scrollView = self.scrollView,
            let antsView = lassoSelectionView.antsView else {
            return nil;
        }
        var snapshot: UIImage?;

        //Calculate the union of all selected annotation bounding rects
        var lassoFrame = antsView.frame;

        var antsViewRelativeOrigin = lassoSelectionView.convert(lassoFrame, to: contentHolderView).origin;
        antsViewRelativeOrigin.x = max(antsViewRelativeOrigin.x, 0);
        antsViewRelativeOrigin.y = max(antsViewRelativeOrigin.y, 0);
        
        lassoFrame.origin = antsViewRelativeOrigin;
        let finalRect = lassoFrame;
        
        var visibleRect = _scrollView.visibleRect();
        visibleRect = visibleRect.intersection(finalRect);

        lassoSelectionView.isHidden = true;
      
        let maxScreenSize: CGFloat = 4000;//since if the contentview frame is greater than 4000pixels, the screenshot method is returning black image.Hence to switch to alternate way this condition is added
        let viewMaxSize = max(contentHolderView.frame.width,contentHolderView.frame.height);
        
        var useAlternateApproach = viewMaxSize > maxScreenSize;
        
        if !useAlternateApproach {
            UIGraphicsBeginImageContextWithOptions(visibleRect.size, true, 0);
            var screenRect = contentHolderView.bounds;
            screenRect.origin.x -= visibleRect.origin.x;
            screenRect.origin.y -= visibleRect.origin.y;
            let success = contentHolderView.drawHierarchy(in: screenRect, afterScreenUpdates: true);
            snapshot = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            useAlternateApproach = !success;
        }
        
        if(useAlternateApproach) {
            //since if the contentview frame is greater than 4000pixels, the screenshot method is returning black image in order to overrule this approach we are using this alreate way of rendering.
            //Since UIGraphicsImageRenderer is bit slower, we will be using only if the zoom scale is more than 3.5;
            let renderer = UIGraphicsImageRenderer.init(bounds: visibleRect);
            snapshot = renderer.image { (context) in
                contentHolderView.layer.render(in: context.cgContext)
            }
        }

        lassoSelectionView.isHidden = false;
        return snapshot;
    }
    
    func snapshotOf(annotations: [FTAnnotation],enclosedRect rect : inout CGRect) -> UIImage? {
        let selectedAnnotations = annotations;
        guard let page = self.pdfPage else {
            return nil;
        }

        var snapshot: UIImage?
        
        //Calculate the union of all selected annotation bounding rects
        
        var finalRect = CGRect.null;
        selectedAnnotations.forEach { (annotation) in
            finalRect = finalRect.union(annotation.renderingRect);
        }
        finalRect = finalRect.integral;

        let pageRect = page.pdfPageRect;
        let referencerect = page.pageReferenceViewSize()
        let scale = referencerect.width/pageRect.size.width;
        
        //Get the snapshot of the whole page in normal size, with selected annotations and without pdf background
        if let img = FTPDFExportView.snapshot(forPage: page,
                                            screenScale: UIScreen.main.scale,
                                            withAnnotations: selectedAnnotations) {
            //Crop the image to the final rect and render the image.
            UIGraphicsBeginImageContextWithOptions(finalRect.size, false, 0);
            let context = UIGraphicsGetCurrentContext();
            context?.translateBy(x: -finalRect.origin.x, y: -finalRect.origin.y);
            context?.scaleBy(x: scale, y: scale);
            img.draw(in: CGRect.init(origin: CGPoint.zero, size: img.size))
            snapshot = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
        
        rect = finalRect;
        return snapshot;
    }
    
    func initiateTransformSelection()
    {
        let selectedAnnotations = self.lassoInfo.selectedAnnotations;
        guard !selectedAnnotations.isEmpty,
            let contentView = self.contentHolderView else {
            return;
        }
        
        self.lassoSelectionView?.finalizeMove();
        selectedAnnotations.forEach { (eachAnnotation) in
            eachAnnotation.selected = true;
        }

        self.lassoInfo.selectedAnnotations = selectedAnnotations;
        var boundingRect = CGRect.zero;
        if let selectedImage = self.snapshotOf(annotations: selectedAnnotations, enclosedRect: &boundingRect) {
            let imageResizeViewController = FTLassoContentSelectionViewController(withImage: selectedImage, boundingRect: contentView.bounds);
            imageResizeViewController.delegate = self;
            self.addChild(imageResizeViewController);
            contentView.addSubview(imageResizeViewController.view);
            var targetRect = imageResizeViewController.view.convert(boundingRect, from: contentView);
            targetRect = CGRect.scale(targetRect, self.pageContentScale);
            imageResizeViewController.initialFrame = targetRect;
            self.lassoContentSelectionViewController = imageResizeViewController;
            
            if let lassoWriting = self.writingView as? FTLassoProtocol {
                lassoWriting.finalizeSelection(byAddingAnnotations: nil);
            }
        }
    }
    
    func showShareScreenshot(_ screenshot:UIImage)
    {
        let controller = FTLassoScreenshotViewController.init(nibName:
            "FTLassoScreenshotViewController", bundle: nil)
        controller.screenshot = screenshot
        if self.isRegularClass() {
            let navigationController = UINavigationController(rootViewController: controller)
            navigationController.modalPresentationStyle = UIModalPresentationStyle.formSheet
            navigationController.isNavigationBarHidden = true
            self.present(navigationController, animated: true, completion: nil)
        } else {
            self.ftPresentModally(controller, animated: true, completion: nil)
        }
    }
    
    func presentColorPickerController(with lassoSelectionView: FTLassoSelectionView) {
        var userActivity : NSUserActivity?;
        if #available(iOS 13.0, *) {
            userActivity = self.view.window?.windowScene?.userActivity
        }
        guard let colors = FTRack(type: .pen,userActivity: userActivity).colors else { return }
        let colorProvider = FTColorProvider(existingColors: colors, selectedColor: "06A6A6", isEditing: false)
        let editColorsViewController = FTEditColorsViewController.viewController(with: colorProvider,
                                                                                 delegate: self,
                                                                                 rackType: .pen,
                                                                                 isLassoMode: true)
        
        if self.isRegularClass() {
            let navigationController = UINavigationController.init(rootViewController: editColorsViewController)
            navigationController.isNavigationBarHidden = true
            navigationController.preferredContentSize = CGSize(width: 390, height: 420)
            navigationController.modalPresentationStyle = .popover
            let controller = navigationController.popoverPresentationController
            controller?.sourceRect = CGRect(x:(lassoSelectionView.selectionRect).midX-5, y:(lassoSelectionView.selectionRect).midY+5, width:10, height:10);
            controller?.sourceView = lassoSelectionView;
            controller?.overrideTraitCollection = self.traitCollection;
            self.present(navigationController, animated: true, completion: nil)
        }
        else
        {
            let rackColorContainerController = FTRackColorsContainerViewController.embedWith(viewController: editColorsViewController, rackType:.pen)
            rackColorContainerController.modalPresentationStyle = .custom;
            rackColorContainerController.transitioningDelegate = customTransitioningDelegate;
            self.present(rackColorContainerController, animated: true, completion: nil);
        }
    }
    
    func paste(at point: CGPoint?)
    {
        finalizeLassoView();
        let menuController = UIMenuController.shared;
        #if targetEnvironment(macCatalyst)
        menuController.hideMenu();
        #else
        if #available(iOS 13.0, *) {
            menuController.hideMenu();
        } else {
            menuController.setMenuVisible(false, animated: true)
        }
        #endif
        
        guard let contentHolderView = self.contentHolderView else {
            return;
        }
        
        let pasteBoard = UIPasteboard.general;
        if UIPasteboard.canPasteLassoContent() {
            let pbItems = pasteBoard.items;
            //Case something copied from our own PDF
            if let data = pbItems.first?[UIPasteboard.pdfAnnotationUTI()] as? Data {
                do {
                    if let dict = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSObject.self],
                        from: data) as? [String:Any] {
                        let annotationData = dict["annotations"] as! Data;
                        let bezierPath = dict["antsViewPath"] as! UIBezierPath;
                        
                        let antsViewFrame = dict["antsViewFrame"] as! CGRect;
                        let antsViewScale = dict["antsViewScale"] as! CGFloat;
                        let offsetFromlastAnnotation = dict["offsetFromlastAnnotation"] as! CGPoint;

                        let contentOffset = self.scrollView?.visibleRect().origin ?? CGPoint.zero;
                        let zoomScale = self.pageContentScale;

                        var antsViewNewFrame = CGRectScale(antsViewFrame, zoomScale);
                        if let tappedPoint = point {
                            let convertedTappedPoint = CGPointTranslate(tappedPoint, -contentOffset.x, -contentOffset.y);
                            
                            antsViewNewFrame.origin.x = convertedTappedPoint.x - (antsViewNewFrame.width)*0.5;
                            antsViewNewFrame.origin.y = convertedTappedPoint.y - (antsViewNewFrame.height)*0.5;

                        }
                        
                        let pastedAnnotations = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSObject.self],
                                                                                       from: annotationData) as?
                                                                                        [FTAnnotation] ?? [FTAnnotation]();
                        

                        //Find the antsview origin point wrt to pdfrender view at normal scale
                        var antsViewOrigin = CGPointTranslate(antsViewNewFrame.origin, contentOffset.x, contentOffset.y);
                        antsViewOrigin = CGPoint.scale(antsViewOrigin, 1/zoomScale);

                        let lastAnnotationBoundingRect = pastedAnnotations.last?.boundingRect ?? CGRect.zero;

                        let offset = CGPoint(x:antsViewOrigin.x-lastAnnotationBoundingRect.origin.x-offsetFromlastAnnotation.x,y: antsViewOrigin.y-lastAnnotationBoundingRect.origin.y-offsetFromlastAnnotation.y);
                        pastedAnnotations.forEach { (annotation) in
                            annotation.selected = true;
                            annotation.uuid = FTUtils.getUUID();
                            annotation.setOffset(offset);
                            annotation.associatedPage = self.pdfPage;
                        }
                        self.lassoInfo.selectedAnnotations = pastedAnnotations;
                        self.addAnnotations(pastedAnnotations, refreshView: false);
                        self.addLassoViewIfNeeded();
                        
                        let rect = bezierPath.bounds;
                        let antsView = FTMarchingAntsView(frame: rect);
                        self.lassoSelectionView?.addSubview(antsView);
                        self.lassoSelectionView?.antsView = antsView;
                        
                        antsView.marchingAntsVisible = true;
                        antsView.frame = antsViewNewFrame;
                        let antsViewScaleFactor = zoomScale/antsViewScale;
                        let t = CGAffineTransform.init(scaleX: antsViewScaleFactor, y: antsViewScaleFactor);
                        bezierPath.apply(t);
                        antsView.setMarchingAntsPath(bezierPath.cgPath);
                        //If antsview frame is outside the visible area, move the lasso view so that its visible
                        if let lassoWritingView = self.writingView as? FTLassoProtocol {
                            lassoWritingView.moveSelectedAnnotations(pastedAnnotations,
                                                                     offset: .zero,
                                                                     refreshForcibly: false);
                        }
                        
                        #if !targetEnvironment(macCatalyst)
                        let flurryInfo = ["Type" : "Paste",
                                          "Annotation Count" : pastedAnnotations.count,
                                          "Source" : "Annotations"] as [String : Any];
                        Flurry.logEvent("PDF Clipboard Operation", withParameters: flurryInfo);
                        #endif
                        FTCLSLog("PDF Clipboard Operation - Paste");
                    }
                }
                catch {
                    
                }
            }
            else if let pbimage = pasteBoard.image, let image = pbimage.scaleAndRotateImageFor1x() {
                let startingFrame = image.aspectFrame(withinScreenArea: contentHolderView.frame, zoomScale: self.pageContentScale);
                let imageInfo = FTImageAnnotationInfo(image: image);
                imageInfo.boundingRect = startingFrame;
                imageInfo.scale = self.pageContentScale;
                self.addAnnotation(info: imageInfo);
                
                #if !targetEnvironment(macCatalyst)
                let flurryInfo = ["Type" : "Paste",
                                  "Source" : "Image"] as [String : Any];
                
                Flurry.logEvent("PDF Clipboard Operation", withParameters: flurryInfo);
                #endif
                FTCLSLog("PDF Clipboard Operation - Paste");
            }
        }
    }
    
    func translateSelectionViewWith(properties: [String:Any],by offset:CGPoint) {
        guard let page = self.pdfPage as? FTPageUndoManagement else {
            return;
        }
        let annotations: [FTAnnotation] = (properties["selectedAnotations"] as? [FTAnnotation]) ?? [FTAnnotation]();
        let zoomScale: CGFloat = (properties["zoomScale"] as? CGFloat) ?? 1;
        
        
        page.translate(annotations: annotations,
                       offset:CGPoint.scale(offset, 1/zoomScale),
                       shouldRefresh: false);
        self.refreshZoomViewIfNeeded();

        //If the user has come out of selection mode or selection view is no more available, we just translate the annotations
        //May also need to check for path
        if(self.lassoSelectionView?.antsView == nil || annotations != self.lassoInfo.selectedAnnotations) {
            //Do nothing
        }
        else {
            if let lassoWritingView = self.writingView as? FTLassoProtocol {
                lassoWritingView.lassoDidMoved(byOffset: offset);
                if let antsView = self.lassoSelectionView?.antsView {
                    var frameRect = antsView.frame;
                    frameRect.origin.x += offset.x;
                    frameRect.origin.y += offset.y;
                    antsView.frame = frameRect;
                }
                self.lassoInfo.totalLassoOffset.x += offset.x;
                self.lassoInfo.totalLassoOffset.y += offset.y;
            }
        }
    }
    
    func removeLassoObserver() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("FTDidReceiveLassoTouch"), object: self.view.window);
    }

    func addLassoObserver() {
        NotificationCenter.default.addObserver(forName: Notification.Name("FTDidReceiveLassoTouch"), object: self.view.window, queue: nil) { [weak self] (notification) in
            
            guard let strongSelf = self,
                notification.isSameSceneWindow(for: strongSelf.view.window) else {
                return;
            }
            if strongSelf.currentDeskMode() == .deskModeClipboard,
                strongSelf != notification.userInfo?["PageVC"] as? FTPageViewController {
                strongSelf.normalizeLassoView();
            }
        }
    }
    
    func showCopyPasteOptions(_ touchPoint:CGPoint,in view:UIView)
    {
        #if !targetEnvironment(macCatalyst)
        let rect = CGRect(x: touchPoint.x+10,
                          y: touchPoint.y-10,
                          width: 10,
                          height: 10);

        self.becomeFirstResponder();
        
        let menu = UIMenuController.shared;
        let pasteMenuItem = FTMenutItem(title: NSLocalizedString("Paste", comment: "Paste"),
                                       action: #selector(FTPageViewController.pasteAction(_:)));
        pasteMenuItem.tapPoint = touchPoint;
        menu.menuItems = [pasteMenuItem];
        if #available(iOS 13.0, *) {
            view.window?.makeKey();
            menu.showMenu(from: view, rect: rect);
        }
        else {
            menu.setTargetRect(rect, in: view);
            menu.setMenuVisible(true, animated: true);
        }
        #endif
    }
    @objc func pasteAction(_ sender: Any?)
    {
        if let menuContorller = sender as? UIMenuController,
            let menuItems = menuContorller.menuItems {
            var curMenuitem: UIMenuItem?
            for eachMenu in menuItems where eachMenu.action == #selector(FTPageViewController.pasteAction(_:)) {
                curMenuitem = eachMenu;
                break;
            }
            if let tapPosition = (curMenuitem as? FTMenutItem)?.tapPoint {
                self.paste(at: tapPosition)
            }
            else {
                self.paste(at: nil)
            }
        }
    }
}

//MARK:- Menu Handler -
extension FTPageViewController {
    @objc override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        var canPerform: Bool = super.canPerformAction(action, withSender: sender);
        if self.currentDeskMode() == .deskModeClipboard {
            if (action == #selector(self.pasteAction(_:))) {
                canPerform = true
            }
        }
        return canPerform;
    }
}

//MARK:- FTLassoContentSelectionDelegate -
extension FTPageViewController: FTLassoContentSelectionDelegate
{
    func lassoContentViewControllerDidEndEditing(with initialFrame: CGRect, currentFrame: CGRect, angle: CGFloat, refPoint: CGPoint, controller: FTLassoContentSelectionViewController) {
        guard let contentView = self.contentHolderView,
        let page = self.pdfPage as? FTPageUndoManagement else {
            self.lassoInfo.reset(clearAnnotation: true);
            return;
        }
                
        let writingScale = self.pageContentScale;
        let oneByScale = 1/writingScale;
        
        var targetRect = contentView.convert(currentFrame, from: controller.view);
        targetRect = CGRect.scale(targetRect, oneByScale);
        
        var startRect = contentView.convert(initialFrame, from: controller.view);
        startRect = CGRect.scale(startRect, oneByScale);

        page.translate(annotations: self.lassoInfo.selectedAnnotations,
                       startRect:startRect,
                       targetRect:targetRect,
                       shouldRefresh: false);
        var convertedPoint = contentView.convert(refPoint, from: controller.view)
        convertedPoint = CGPointScale(convertedPoint, 1/writingScale);
        page.rotate(annotations: self.lassoInfo.selectedAnnotations,
                    angle: angle,
                    refPoint: convertedPoint,
                    shouldRefresh: false)

        if let lassoWritingView = self.writingView as? FTLassoProtocol {
            lassoWritingView.finalizeSelection(byAddingAnnotations: nil);
        }
        controller.view.removeFromSuperview();
        controller.removeFromParent();
        self.lassoContentSelectionViewController = nil;

        self.lassoInfo.reset(clearAnnotation: true);
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: FTPDFEnableGestures),
                                        object: self.view.window);
    }
}

private class FTMenutItem: UIMenuItem {
    var tapPoint: CGPoint = .zero;
}
