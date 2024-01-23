//
//  FTPageViewController_LassoSelection.swift
//  Noteshelf
//
//  Created by Amar on 27/05/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon
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
        var showPasteOptions = isInZoomMode() ? false : true
        if isInZoomMode(), UIPasteboard.canPasteShapeContent() {
            showPasteOptions = true
        }

        guard let contentView = self.contentHolderView, showPasteOptions else {
            return
        }
        if self.currentDeskMode() == .deskModeClipboard {
            self.lassoContentSelectionViewController?.endEditing()
            if nil == self.activeAnnotationController,UIPasteboard.canPasteContent() {
                self.showCopyPasteOptions(touchPoint,in:contentView)
            }
        }
        if self.currentDeskMode() != .deskModeLaser && self.currentDeskMode() != .deskModeReadOnly {
            if nil == self.activeAnnotationController, UIPasteboard.canPasteContent() {
                self.showCopyPasteOptions(touchPoint,in:contentView)
            }
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
            let type: FTLassoSelectionType = FTRackPreferenceState.lassoSelectionType == 0 ? .freeForm : .rectangularForm
            let view = FTLassoSelectionView(frame: _scrollView.visibleRect(), type: type);
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
    
    func performPasteOperation(at point:CGPoint) {
        self.paste(at: point == .zero ? nil : point);
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
        let integralRect = finalRect.integral;

        let pageRect = page.pdfPageRect;
        let referencerect = page.pageReferenceViewSize()
        let scale = referencerect.width/pageRect.size.width;
        
        //Get the snapshot of the whole page in normal size, with selected annotations and without pdf background
        if let img = FTPDFExportView.snapshot(forPage: page,
                                            screenScale: UIScreen.main.scale,
                                            withAnnotations: selectedAnnotations) {
            //Crop the image to the final rect and render the image.
            UIGraphicsBeginImageContextWithOptions(integralRect.size, false, 0);
            let context = UIGraphicsGetCurrentContext();
            context?.translateBy(x: -integralRect.origin.x, y: -integralRect.origin.y);
            context?.scaleBy(x: scale, y: scale);
            img.draw(in: CGRect.init(origin: CGPoint.zero, size: img.size))
            snapshot = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
        
        rect = finalRect;
        return snapshot;
    }

    func resizeSavedClipFor(annotations: [FTAnnotation]) {
        normalizeLassoView()
        let selectedAnnotations = annotations;
        guard !selectedAnnotations.isEmpty,
            let contentView = self.contentHolderView else {
            return;
        }

        self.lassoSelectionView?.finalizeMove();
        let hashKey = self.windowHash;
        selectedAnnotations.forEach { (eachAnnotation) in
            eachAnnotation.setSelected(true, for: hashKey);
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
        let hashKey = self.windowHash;
        annotations?.forEach({ (eachAnnotation) in
            let canSelect = eachAnnotation.canSelectUnderLassoSelection()
            if canSelect {
                if eachAnnotation.allowsLassoSelection,
                   let annotate = eachAnnotation as? FTAnnotationContainsProtocol,
                   annotate.intersectsPath(cutPath, withScale: scale, withOffset: offset) {
                    eachAnnotation.setSelected(true, for: hashKey);
                    self.lassoInfo.selectedAnnotations.append(eachAnnotation);
                }
            }
        });
        
        #if targetEnvironment(macCatalyst)
        runInMainThread { [weak self] in
            if let annotations = self?.lassoInfo.selectedAnnotations,
               !annotations.isEmpty,
               let lassowritingView = self?.writingView as? FTLassoProtocol {
                lassowritingView.moveSelectedAnnotations(annotations,
                                                         offset: CGPoint.zero,
                                                         refreshForcibly: true);
            }
        }
        #endif
    }
    
    func lassoSelectionViewFinalizeMoves(_ lassoSelectionView: FTLassoSelectionView) {
        let selectedAnnotations = self.lassoInfo.selectedAnnotations;
        let hashKey = self.windowHash;
        selectedAnnotations.forEach { (eachAnnotation) in
            eachAnnotation.setSelected(false, for: hashKey);
        }
        
        if let lassowritingView = self.writingView as? FTLassoProtocol {
            lassowritingView.finalizeSelection(byAddingAnnotations: nil);
        }
        
        self.lassoInfo.reset(clearAnnotation: true);

        self.postRefreshNotification();
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
        case .openAI:
            self.startOpenAiForPage();
        case .saveClip:
            self.lassoSelectionViewCreateSnippetCommand(lassoSelectionView)
        }
    }
    #if targetEnvironment(macCatalyst)
    func lassoSelectionViewPasteCommand(_ lassoSelectionView: FTLassoSelectionView, at touchedPoint: CGPoint) {
        self.paste(at: touchedPoint);
    }
    #endif
}

//MARK:- Lasso Actions -
private extension FTPageViewController  {
    func lassoSelectionViewCutCommand(_ lassoSelectionView: FTLassoSelectionView) {
        let selectedAnnotations = self.lassoInfo.selectedAnnotations;
        if selectedAnnotations.isEmpty {
            return;
        }
        FTCLSLog("PDF Clipboard Operation - Cut");
        track("Lasso_Cut",screenName: FTScreenNames.lasso)

        self.copySelectedAnnotations();

        let hashKey = self.windowHash;
        selectedAnnotations.forEach { (annotation) in
            annotation.setSelected(false, for: hashKey);
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
        FTCLSLog("PDF Clipboard Operation - Copy");
        track("Lasso_Copy",screenName: FTScreenNames.lasso)

        self.copySelectedAnnotations();

        self.lassoSelectionView?.resignFirstResponder();
        self.lassoInfo.reset();
    }
    
    func lassoSelectionCanShowConvert(toText lassoSelectionView: FTLassoSelectionView) -> Bool {
        guard let page = self.pdfPage else {
            return false;
        }
        
        let pageAnnotations = page.annotations();

        var isMigratedNotebook = false;
        if nil != pageAnnotations.first(where: {$0.isReadonly}) {
            isMigratedNotebook = true;
        }
        let strokeAnnotations = pageAnnotations.filter({$0.supportsHandwrittenRecognition});
        let hasPenStrokes = !strokeAnnotations.isEmpty;

        return hasPenStrokes || isMigratedNotebook;
    }
        
    func lassoSelectionViewTakeScreenshotCommand(_ lassoSelectionView: FTLassoSelectionView) {
        let selectedAnnotations = self.lassoInfo.selectedAnnotations;
        FTCLSLog("PDF Clipboard Operation - Screenshot");
        track("Lasso_Screenshot",screenName: FTScreenNames.lasso)

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
        let rackData = FTRackData(type: .shape, userActivity: self.view.window?.windowScene?.userActivity)
        let editMode = FTPenColorSegment.savedSegment(for: .lasso)
        var contentSize = FTPenColorEditController.presetViewSize
        if editMode == .grid {
            contentSize = FTPenColorEditController.gridViewSize
        }
        let model = FTPenShortcutViewModel(rackData: rackData)
        let hostingVc = FTPenColorEditController(viewModel: model, delegate: self)
        self.penShortcutViewModel = model
        hostingVc.ftPresentationDelegate.source = lassoSelectionView
        hostingVc.ftPresentationDelegate.sourceRect = lassoSelectionView.selectionRect
        hostingVc.ftPresentationDelegate.permittedArrowDirections = [UIPopoverArrowDirection.left, UIPopoverArrowDirection.right]
        self.ftPresentPopover(vcToPresent: hostingVc, contentSize: contentSize, hideNavBar: true)
    }
    
    func lassoSelectionViewRecognitionCommand(_ lassoSelectionView: FTLassoSelectionView) {
        guard let page = self.pdfPage,
            let cache = page.parentDocument?.localMetadataCache else {
            return;
        }

        guard FTIAPManager.shared.premiumUser.isPremiumUser else {
            FTIAPurchaseHelper.shared.showIAPAlertForFeature(feature: "Convert to Text", on: self);
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
        self.parent?.ftPresentFormsheet(vcToPresent: convertToText, hideNavBar: false)
    }

    func lassoSelectionViewMoveToFrontCommand(_ lassoSelectionView: FTLassoSelectionView) {
        let selectedAnnotations = self.lassoInfo.selectedAnnotations;
        guard !selectedAnnotations.isEmpty else {
            return;
        }
        track("Lasso_Front",screenName: FTScreenNames.lasso)
        
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

        track("Lasso_Back",screenName: FTScreenNames.lasso)
        self.moveAnnotationsToBack(selectedAnnotations, shouldRefresh: true)

        self.lassoSelectionView?.resignFirstResponder();
        self.lassoInfo.reset();

        if let lassowritingView = self.writingView as? FTLassoProtocol {
            lassowritingView.finalizeSelection(byAddingAnnotations: nil);
        }
    }
    
    func lassoSelectionViewTransformCommand(_ lassoSelectionView: FTLassoSelectionView) {
        self.initiateTransformSelection();
        track("Lasso_Resize",screenName: FTScreenNames.lasso)
    }
    
    func lassoSelectionViewDeleteCommand(_ lassoeSelectionView: FTLassoSelectionView) {
        self.deleteLassoAnnotations()
        if let lassowritingView = self.writingView as? FTLassoProtocol {
            lassowritingView.finalizeSelection(byAddingAnnotations: nil);
        }
    }
    
    func deleteLassoAnnotations() {
        let selectedAnnotations = self.lassoInfo.selectedAnnotations;
        if selectedAnnotations.isEmpty {
            return;
        }
        var refreshRect = CGRect.null;
        let hashKey = self.windowHash;
        selectedAnnotations.forEach { (annotation) in
            annotation.setSelected(false, for: hashKey);
            refreshRect = refreshRect.union(annotation.renderingRect);
        }
        self.removeAnnotations(selectedAnnotations, refreshView: true);
        self.lassoSelectionView?.resignFirstResponder();
        self.lassoInfo.reset();
    }

    func lassoSelectionViewCreateSnippetCommand(_ lassoSelectionView: FTLassoSelectionView) {
        let selectedAnnotations = self.lassoInfo.selectedAnnotations;
        guard !selectedAnnotations.isEmpty else {
            return
        }
        var boundingRect = CGRect.zero;

        let storyboard = UIStoryboard.init(name: "FTDocumentEntity", bundle: nil)
        guard let saveClipPreview = storyboard.instantiateViewController(withIdentifier: "FTSaveClipPreviewViewController") as? FTSaveClipPreviewViewController else {
            fatalError("FTSaveClipPreviewViewController not found")
        }
        if let selectedImage = self.snapshotOf(annotations: selectedAnnotations, enclosedRect: &boundingRect) {
            saveClipPreview.previewImage = selectedImage
        }
        saveClipPreview.delegate = self
        self.parent?.ftPresentFormsheet(vcToPresent: saveClipPreview, hideNavBar: true)
    }

}

extension FTPageViewController: FTSaveClipDelegate {
    func didSelectCategory(name: String) {
        let selectedAnnotations = self.lassoInfo.selectedAnnotations;
        guard !selectedAnnotations.isEmpty else {
            return;
        }
        var boundingRect = CGRect.zero

        let tempDocURL = FTDocumentFactory.tempDocumentPath(FTUtils.getUUID());
        let ftdocument = FTDocumentFactory.documentForItemAtURL(tempDocURL);

        let totalBoundingRect: CGRect = selectedAnnotations.reduce(.null) { partialResult, annotation in
            partialResult.union(annotation.boundingRect)
        }

        let pdfGenerator = PDFGenerator()
        let pdfPath = pdfGenerator.createPDF(frame: self.lassoSelectionView?.selectionRect ?? .zero)

        let info = FTDocumentInputInfo();
        info.isTemplate = false
        info.inputFileURL = pdfPath
        info.overlayStyle = .clearWhite
        info.isNewBook = true;
        ftdocument.createDocument(info) { (error, _) in
            let doc = (ftdocument as? FTNoteshelfDocument)
            doc?.openDocument(purpose: .write, completionHandler: { success, error in
                let page = doc?.pages().first as? FTNoteshelfPage
                page?.deepCopyAnnotations(selectedAnnotations, onCompletion: {
                })
                page?.annotations().forEach { annotation in
                    annotation.setOffset(CGPoint(x: -totalBoundingRect.origin.x, y: -totalBoundingRect.origin.y))
                }
                doc?.saveAndCloseWithCompletionHandler({ success in
                    if let selectedImage = self.snapshotOf(annotations: selectedAnnotations, enclosedRect: &boundingRect) {
                       _ = try? FTSavedClipsProvider.shared.saveFileFrom(url: tempDocURL, to: name, thumbnail: selectedImage)
                    }
                })
            })
            print(tempDocURL)
        }
    }
}

class PDFGenerator {

    func createPDF(frame: CGRect) -> URL {
        let render = UIPrintPageRenderer()
        render.setValue(NSValue(cgRect: frame), forKey: "paperRect")
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, .zero, nil)

        UIGraphicsBeginPDFPage()
        let bounds = UIGraphicsGetPDFContextBounds()
        render.drawPage(at: 0, in: bounds)
        UIGraphicsEndPDFContext();

        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let pdfFilePath = documentsDirectory.appendingPathComponent("SaveClip.pdf")

        do {
            try pdfData.write(to: pdfFilePath)
        } catch {
            print("Error writing PDF to file: \(error.localizedDescription)")
        }
        return pdfFilePath
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
            FTCLSLog("PDF Clipboard Operation - ConvertToTextbox");
            track("Lasso_ConvertToText",screenName: FTScreenNames.lasso)

            let writingScale = self.pageContentScale;

            let actualOffset = CGPoint.scale(self.lassoInfo.totalLassoOffset, 1/writingScale);
            
            var refreshRect = CGRect.null;
            var refreshRectAfter = CGRect.null;
            let hashKey = self.windowHash;
            selectedAnnotations.forEach { (annotation) in
                refreshRect = refreshRect.union(annotation.renderingRect);
                annotation.setOffset(actualOffset);
                annotation.setSelected(false, for: hashKey);
                refreshRectAfter = refreshRectAfter.union(annotation.renderingRect);
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
}

//MARK:- FTEditColorsViewControllerDelegate -
extension FTPageViewController: FTFavoriteColorNotifier {
    func didSelectColorFromEditScreen(_ penset: FTPenSetProtocol)  {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateLassoColor(_:)), object: nil)
        self.perform(#selector(updateLassoColor(_ :)), with: penset.color, afterDelay: 0.1)
    }

    @objc func updateLassoColor(_ hex: String) {
        let annotations = self.lassoInfo.selectedAnnotations
        if  !annotations.isEmpty {
            (self.pdfPage as? FTPageUndoManagement)?.update(annotations: annotations, color: UIColor(hexString: hex))
            if self.lassoSelectionView?.antsView != nil,
               let lassoWritingView = self.writingView as? FTLassoProtocol {
                lassoWritingView.moveSelectedAnnotations(annotations,
                                                         offset: .zero,
                                                         refreshForcibly: true)
            }
        }
    }
    
    func saveFavoriteColorsIfNeeded() {
        
    }
}

extension FTPageViewController: FTColorEyeDropperPickerDelegate {
    func colorPicker(picker: FTColorEyeDropperPickerController,didPickColor color:UIColor) {
        self.updateLassoColor(color.hexString)
        self.penShortcutViewModel = nil
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
    
    func initiateTransformSelection()
    {
        let selectedAnnotations = self.lassoInfo.selectedAnnotations;
        guard !selectedAnnotations.isEmpty,
            let contentView = self.contentHolderView else {
            return;
        }
        
        self.lassoSelectionView?.finalizeMove();
        let hashKey = self.windowHash;
        selectedAnnotations.forEach { (eachAnnotation) in
            eachAnnotation.setSelected(true, for: hashKey);
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
    
    func paste(at point: CGPoint?)
    {
        finalizeLassoView()
        let menuController = UIMenuController.shared
        menuController.hideMenu()
        
        if UIPasteboard.canPasteContent() {
            self.pasteContent(at: point)
        }
    }
    
    
    func pasteContent(at point: CGPoint?) {
        let content = UIPasteboard.getContent()
        if let image = content as? UIImage {
            self.pasteImageContent(img: image, at: point)
        } else if let text = content as? String {
            self.pasteTextContent(text: text, at: point)
        }  else if let data = content as? Data {
            self.unArchieveAndPasteContent(at: point, data: data)
        }
    }
    
    private func unArchieveAndPasteContent(at point: CGPoint?, data: Data) {
        do {
        if let pastableAnnotation = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSObject.self],
                                                                           from: data) as? FTAnnotation {
            self.pasteAnnotation(at: point, annotation: pastableAnnotation)
        } else {
            self.pasteLassoData(at: point, data: data)
        }
        } catch {
            FTCLSLog("Error in Unarchieving and pasting the content \(error.localizedDescription)")
        }
    }
    
    private func pasteImageContent(img: UIImage, at point: CGPoint?) {
        if let image = img.scaleAndRotateImageFor1x() {
            guard let contentHolderView = self.contentHolderView else {
                return
            }
            let startingFrame = image.aspectFrame(withinScreenArea: contentHolderView.frame, zoomScale: self.pageContentScale)
            let imageInfo = FTImageAnnotationInfo(image: image)
            imageInfo.boundingRect = startingFrame
            imageInfo.scale = self.pageContentScale
            self.addAnnotation(info: imageInfo)
            self.addLassoViewIfNeeded()
            
            if self.currentDeskMode() != .deskModeClipboard {
                self.finalizeLassoView()
            }

        }
    }
    
    private func pasteTextContent(text: String, at point: CGPoint?) {
        let info = FTTextAnnotationInfo()
        info.localmetadataCache = self.pdfPage?.parentDocument?.localMetadataCache
        info.visibleRect = self.scrollView?.visibleRect() ?? self.view.bounds
        info.string = text
        if let point = point {
            info.atPoint = point
        }
        info.scale = self.pageContentScale
        self.addAnnotation(info: info)
        self.addLassoViewIfNeeded()
        
        if self.currentDeskMode() != .deskModeClipboard {
            self.finalizeLassoView()
        }

    }
    
    private func pasteAnnotation(at point: CGPoint?, annotation: FTAnnotation) {
        do {
            var reqAnnotation: FTAnnotation!
            if let imgAnnotation = annotation as? FTImageAnnotation {
                reqAnnotation = imgAnnotation
            } else if let textAnnotation = annotation as? FTTextAnnotation {
                reqAnnotation = textAnnotation
            } else if annotation is FTShapeAnnotation {
                reqAnnotation = annotation
                pasteShapeAnnotation(annotation: annotation, point: point)
                return
            }
            
            reqAnnotation.uuid = FTUtils.getUUID()
            reqAnnotation.associatedPage = self.pdfPage
            var frame = reqAnnotation.boundingRect
            
            if let tappedPoint = point {
                let point1X = CGPointScale(tappedPoint, 1/pageContentScale)
                frame.origin.x = point1X.x - frame.width * 0.5
                frame.origin.y = point1X.y - frame.height * 0.5
            }
            
            reqAnnotation.boundingRect = frame
            self.addAnnotations([reqAnnotation], refreshView: false)
            if let tappedPoint = point {
                self.editAnnotation(reqAnnotation, eventType: .longPress, at: tappedPoint)
            } else {
                self.editAnnotation(reqAnnotation, eventType: .longPress, at: frame.origin)
            }
            self.addLassoViewIfNeeded()
            
            if self.currentDeskMode() != .deskModeClipboard {
                self.finalizeLassoView()
            }

        }
    }
    
    private func pasteShapeAnnotation(annotation: FTAnnotation, point: CGPoint?) {
        annotation.uuid = FTUtils.getUUID()
        annotation.associatedPage = self.pdfPage
        let boundingRect = annotation.boundingRect
        if let tappedPoint = point {
            var scaledPoint = CGPointScale(tappedPoint, 1/pageContentScale)
            scaledPoint.x -=  boundingRect.width * 0.5
            scaledPoint.y -=  boundingRect.height * 0.5
            scaledPoint.x -=  boundingRect.origin.x
            scaledPoint.y -=  boundingRect.origin.y
            annotation.setOffset(scaledPoint)
        }
        self.addAnnotations([annotation], refreshView: false)
        if let tappedPoint = point {
            self.editAnnotation(annotation, eventType: .longPress, at: tappedPoint)
        } else {
            self.editAnnotation(annotation, eventType: .longPress, at: annotation.boundingRect.origin)
        }
    }
    
    private func pasteLassoData(at point: CGPoint?, data: Data) {
        do {
            if let dict = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSObject.self],
                                                                 from: data) as? [String:Any] {
                guard let annotationData = dict["annotations"] as? Data,
                      let bezierPath = dict["antsViewPath"] as? UIBezierPath,
                      let antsViewFrame = dict["antsViewFrame"] as? CGRect,
                      let antsViewScale = dict["antsViewScale"] as? CGFloat,
                      let offsetFromlastAnnotation = dict["offsetFromlastAnnotation"] as? CGPoint else {
                    return
                }
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
                let hashKey = self.windowHash;
                pastedAnnotations.forEach { (annotation) in
                    annotation.setSelected(true, for: hashKey);
                    annotation.uuid = FTUtils.getUUID();
                    annotation.setOffset(offset);
                    annotation.associatedPage = self.pdfPage;
                }
                self.lassoInfo.selectedAnnotations = pastedAnnotations;
                self.addAnnotations(pastedAnnotations, refreshView: false);
                self.addLassoViewIfNeeded()

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
                
                if self.currentDeskMode() != .deskModeClipboard {
                    self.delegate?.switch(.deskModeClipboard, sourceView: nil)
                    _ = self.showMenu(nil)
                }

                FTCLSLog("PDF Clipboard Operation - Paste");
                track("Lasso_Paste",screenName: FTScreenNames.lasso)
            }
        }
        catch {
            FTCLSLog("Error - \(error.localizedDescription)")
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
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didReceiveLassoTouchNotification(_:)),
                                               name: Notification.Name("FTDidReceiveLassoTouch"),
                                               object: self.view.window)
    }
    
    @objc private func didReceiveLassoTouchNotification(_ notification: Notification) {
        guard notification.isSameSceneWindow(for: self.view.window) else {
            return;
        }
        if self.currentDeskMode() == .deskModeClipboard,
           self != notification.userInfo?["PageVC"] as? FTPageViewController {
            self.normalizeLassoView();
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
        view.window?.makeKey();
        menu.showMenu(from: view, rect: rect);
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
                       shouldRefresh: false,
                       windowHash: self.windowHash);
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
        self.postRefreshNotification();
    }
    
    func deleteLassoSelectedAnnotation(controller: FTLassoContentSelectionViewController) {
        if !self.lassoInfo.selectedAnnotations.isEmpty {
            self.deleteLassoAnnotations()
            controller.view.removeFromSuperview();
            controller.removeFromParent();
            self.lassoContentSelectionViewController = nil;
            self.lassoInfo.reset(clearAnnotation: true);
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: FTPDFEnableGestures),
                                            object: self.view.window);
        }
    }
}

private class FTMenutItem: UIMenuItem {
    var tapPoint: CGPoint = .zero;
}
