//
//  FTPageViewController_OpenAIExtension.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 01/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import Reachability

extension FTPageViewController {
    
    @objc func startOpenAiForPage() {
        guard let connection = Reachability.forInternetConnection(),connection.currentReachabilityStatus() != NetworkStatus.NotReachable  else {
            FTOPenAIError.noInternetConnection.showAlert(from: self);
            return;
        }
        
        guard let page = self.pdfPage else {
            return;
        }
        var annotationsToConsider = [FTAnnotation]();

        if let selectedText = self.writingView?.selectedPDFString(), !selectedText.isEmpty {
            self.writingView?.selectedTextRange = nil;
            self.generateOpenAIContentFor(annotations: annotationsToConsider
                                          ,pdfContent: selectedText
                                          ,isFullPage: false);
            return;
        }
        
        var shouldReadPDFContent = true;
        if currentDeskMode() == .deskModeClipboard {
            annotationsToConsider = self.lassoInfo.selectedAnnotations;
            self.lassoSelectionView?.finalizeMove();
            shouldReadPDFContent = annotationsToConsider.isEmpty;
        }
        let isFullPage = annotationsToConsider.isEmpty;
        annotationsToConsider = annotationsToConsider.isEmpty ? page.annotations() : annotationsToConsider
        
        var pdfContent = "";
        if !page.templateInfo.isTemplate
            , shouldReadPDFContent
            , page.hasPDFText()
            , let pdfString = page.pdfPageRef?.string?.openAITrim()
            ,!pdfString.isEmpty {
            pdfContent = pdfString;
        }
        self.generateOpenAIContentFor(annotations: annotationsToConsider
                                      ,pdfContent: pdfContent
                                      ,isFullPage: isFullPage);
    }
    
    @objc private func generateOpenAIContentFor(annotations : [FTAnnotation]
                                                ,pdfContent: String
                                                ,isFullPage: Bool) {
        var annotationsToConsider = [FTAnnotation]();
        
        let pageContent = FTPageContent();
        if !pdfContent.isEmpty {
            pageContent.pdfContent = pdfContent;
        }
        annotations.forEach { eachAnnotation in
            if(eachAnnotation.supportsHandwrittenRecognition) {
                annotationsToConsider.append(eachAnnotation)
            }
            else if let textAnnotation = eachAnnotation as? FTTextAnnotation,let string = textAnnotation.attributedString?.string.openAITrim(), !string.isEmpty {
                pageContent.textContent.append(string);
            }
        }
        
        if annotationsToConsider.isEmpty {
            self.showNoteshelfAIController(pageContent);
        }
        else {
            let isPremium = FTIAPManager.shared.premiumUser.isPremiumUser;
            let pageLastUpdated = self.pdfPage?.lastUpdated;

            if isPremium,isFullPage, let recognizedString = self.recognizedString() {
                pageContent.writtenContent = recognizedString;
                self.showNoteshelfAIController(pageContent);
                return;
            }
            
            let canvasSize = self.pdfPage?.pdfPageRect.size ?? CGSize.zero;
            let loadingIndicator = FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self.delegate ?? self, withText: NSLocalizedString("Indexing", comment: "Indexing"))
            
            DispatchQueue.global().async { [weak self] in
                if let weakSelf  = self {
                    let lang: String;
                    let recognitionProcessor: FTRecognitionProcessor;
                    if isPremium {
                        if let curLang = FTLanguageResourceManager.shared.currentLanguageCode, curLang != languageCodeNone {
                            lang = curLang;
                        }
                        else {
                            lang = FTConvertToTextViewModel.convertPreferredLanguage;
                        }
                        recognitionProcessor = FTRecognitionTaskProcessor(with: lang)
                    }
                    else {
                        lang = FTUtils.currentLanguage();
                        recognitionProcessor = FTDigitalInkRecognitionTaskProcessor(with: lang)
                    }
                    let task: FTRecognitionTask = FTRecognitionTask(language: lang
                                                                    , annotations: annotationsToConsider
                                                                    , canvasSize: canvasSize);
                    
                    task.onCompletion = { (info, error) in
                        runInMainThread {
                            debugLog("\(recognitionProcessor) executed");
                            loadingIndicator.hide(nil);
                            guard let recogInfo = info else {
                                weakSelf.showNoteshelfAIController(pageContent);
                                return
                            }
                            let text = recogInfo.recognisedString.openAITrim();
                            if isPremium, isFullPage, let lastUpdated = pageLastUpdated {
                                recogInfo.lastUpdated = lastUpdated;
                                self?.pdfPage?.recognitionInfo = recogInfo;
                            }
                            if !text.isEmpty {
                                pageContent.writtenContent = text;
                            }
                            weakSelf.showNoteshelfAIController(pageContent);
                        }
                    }
                    recognitionProcessor.startTask(task, onCompletion: nil)
                }
            }
        }
    }
    
    private func showNoteshelfAIController(_ content:FTPageContent) {
        FTNoteshelfAIViewController.showNoteshelfAI(from: self
                                                    , content: content
                                                    , delegate: self);
    }
    
    private func recognizedString() -> String? {
        guard let recognitionInfo = self.pdfPage?.recognitionInfo
                ,let lastUpdated = self.pdfPage?.lastUpdated else {
            return nil;
        }
        if recognitionInfo.languageCode == FTLanguageResourceManager.shared.currentLanguageCode
            , recognitionInfo.lastUpdated.doubleValue == lastUpdated.doubleValue {
            return recognitionInfo.recognisedString;
        }
        return nil;
    }
}

extension FTPageViewController: FTNoteshelfAIDelegate {
    private func originToInsertHandwrite() -> CGPoint {
        var origin = FTTextToStrokeProperties.defaultOrigin;
        
        if let page = self.pdfPage {
            origin = page.startMargin;
            let annotations: [FTAnnotation];
            if !self.lassoInfo.selectedAnnotations.isEmpty {
                annotations = self.lassoInfo.selectedAnnotations;
            }
            else {
                annotations = page.annotations();
            }
            annotations.forEach { eachAnnotaiton in
                origin.y = max(origin.y, eachAnnotaiton.boundingRect.maxY);
            }
            if !annotations.isEmpty {
                let offset = (origin.y - page.pageTopMargin).toInt;
                let yquotient = (offset / page.lineHeight) + 1;
//                if offset % page.lineHeight > 0 {
//                    yquotient += 1;
//                }
                origin.y = (yquotient * page.lineHeight).toCGFloat() + page.pageTopMargin
            }
        }
        origin.x += FTTextToStrokeProperties.paragraphMargin;
        return origin;
    }
    
    func noteshelfAIController(_ ccntroller: FTNoteshelfAIViewController
                               , didTapOnAction action: FTNotesehlfAIAction
                               , content: FTAIContent) {
        ccntroller.dismiss(animated: true) {
            if action == .copyToClipboard {
                if let content = content.normalizedAttrText {
                    UIPasteboard.general.string = content.string;
                }
            }
            else if action == .addToPage {
                guard let page = self.pdfPage else {
                    return;
                }
                
                let origin = self.originToInsertHandwrite();

                if page.pdfPageRect.height - page.pageBottomMargin - origin.y < 100 {
                    self.delegate?.insertNewPage(page, addContent: content);
                }
                else {
                    if let annotation = self.pdfPage?.addTextAnnotation(content, at: origin) {
                        self.refreshView(refreshArea: annotation.boundingRect);
                    }
                }
            }
            else if action == .addToNewPage {
                if let page = self.pdfPage {
                    self.delegate?.insertNewPage(page, addContent: content);
                }
            }
            else if action == .addHandwriting {
                let origin = self.originToInsertHandwrite();
                if let page = self.pdfPage,page.isAtTheEndOfPage(origin) {
                    self.delegate?.insertNewPage(page, addContent: content, isHandwrite: true);
                }
                else {
                    let loadingIndicator = FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self.delegate ?? self, withText: NSLocalizedString("Generating", comment: "Generating"))
                    runInMainThread {
                        self.convertTextToStroke(content,origin: origin);
                        loadingIndicator.hide(nil);
                    }
                }
                
            }
            else if action == .addNewPageHandwriting {
                if let page = self.pdfPage {
                    self.delegate?.insertNewPage(page, addContent: content, isHandwrite: true);
                }
            }
        }
    }
}

extension FTPageViewController {
    @objc func convertTextToStroke(_ text: String,origin inOrigin: CGPoint) {
        guard let nsPage = self.pdfPage else {
            return;
        }
        let content = FTAIContent(with: NSAttributedString(string: text));
        self.delegate?.addTextAsStrokes(to: nsPage, content: content,origin: inOrigin)
    }

    func convertTextToStroke(_ content: FTAIContent,origin inOrigin: CGPoint) {
        guard let nsPage = self.pdfPage else {
            return;
        }
        self.delegate?.addTextAsStrokes(to: nsPage, content: content,origin: inOrigin)
    }
}

extension FTPDFRenderViewController {
    func insertNewPage(_ after: FTPageProtocol
                       , addContent content:FTAIContent
                       , isHandwrite: Bool = false) {
        func showPage(_ index: Int) {
            runInMainThread {
                self.showPage(at: index,forceReLayout: false);
            }
        }
        
        if  let document = self.pdfDocument
                ,let newPage = document.insertPageBelow(page: after) as? FTNoteshelfPage {
            var loadingIndicator: FTLoadingIndicatorViewController?
            if isHandwrite {
                loadingIndicator = FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self, withText: NSLocalizedString("Generating", comment: "Generating"))
            }
            
            var origin = newPage.startMargin;
            origin.x += FTTextToStrokeProperties.paragraphMargin;
            
            runInMainThread {
                if isHandwrite {
                    self.addTextAsStrokes(to: newPage, content: content,origin:origin);
                }
                else {
                    newPage.addTextAnnotation(content);
                }
                loadingIndicator?.hide(nil);
                showPage(newPage.pageIndex())
            }
        }
    }
        
    func addTextAsStrokes(to page:FTPageProtocol
                          ,content: FTAIContent
                          ,origin: CGPoint) {
        let textRenderer: FTCharToStrokeRender = FTCharToStrokeRender.renderer(FTDeveloperOption.textToStrokeWrapChar ? .char : .word);
        
        textRenderer.convertTextToStroke(for: page
                                         , content: content
                                         , origin: origin) { (annotations,currentPage,shouldCreateNew) in
            (currentPage as? FTPageUndoManagement)?.addAnnotations(annotations, indices: nil);
            self.postRefreshNotification(for: currentPage, annotations: annotations);
            if shouldCreateNew, let curPage = currentPage, let document = curPage.parentDocument {
                let newPage = document.insertPageBelow(page: curPage);
                return newPage;
            }
            return currentPage;
        } onComplete: {
            
        }
    }

    private func postRefreshNotification(for inPage:FTPageProtocol?, annotations: [FTAnnotation]) {
        if !annotations.isEmpty, let page = inPage {
            var refreshRect: CGRect = .null;
            annotations.forEach { eachAnnotation in
                refreshRect = refreshRect.union(eachAnnotation.renderingRect);
            }
            if !refreshRect.isNull {
                var userInfo : [String : Any] = [String : Any]();

                userInfo[FTRefreshRectKey] = refreshRect;
                NotificationCenter.default.post(name: .pageDidUndoRedoNotification,
                                                object: page,
                                                userInfo: userInfo)
            }
        }
    }
}

extension FTPageProtocol {
    var pageLeftMargin: CGFloat {
        return (leftMargin > 0 ? leftMargin : Int(FTTextToStrokeProperties.leftMargin)).toCGFloat();
    }
    var pageRightMargin: CGFloat {
        return FTTextToStrokeProperties.rightMargin;
    }

    var pageTopMargin: CGFloat {
        return (topMargin > 0 ? topMargin : Int(FTTextToStrokeProperties.topMargin)).toCGFloat();
    }
    
    var pageBottomMargin: CGFloat {
        return (bottomMargin > 0 ? bottomMargin : Int(FTTextToStrokeProperties.bottomMargin)).toCGFloat();
    }
    
    func isAtTheEndOfPage(_ point: CGPoint) -> Bool {
        if (point.y + CGFloat(self.lineHeight)) > self.pdfPageRect.height - self.pageBottomMargin {
            return true;
        }
        return false;
    }
    
    var startMargin: CGPoint {
        return CGPoint(x: pageLeftMargin, y: pageTopMargin);
    }
    
    @discardableResult
    func addTextAnnotation(_ content: FTAIContent,at point: CGPoint = .zero) -> FTAnnotation? {
        guard let contentAttr = content.normalizedAttrText else {
            return nil;
        }
        
        let info = FTTextAnnotationInfo();
        info.scale = 1;
        info.visibleRect = CGRect(origin: .zero, size: self.pdfPageRect.size).insetBy(dx: 20, dy: 20);
        if CGPoint.zero != point {
            info.atPoint = point;
        }
        let startPoint = startMargin;
        info.atPoint.x = max(info.atPoint.x , startPoint.x)
        info.atPoint.y = max(info.atPoint.y , startPoint.y)
        
        info.localmetadataCache = self.parentDocument?.localMetadataCache;
        info.fromConvertToText = true;
        info.enterEditMode = false;
        
        var textDefaultColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1);
        if self.templateInfo.isTemplate
            , let bgColor = (self as? FTPageBackgroundColorProtocol)?.pageBackgroundColor
            , let curColor = bgColor.blackOrWhiteContrastingColor() {
            textDefaultColor = curColor;
        }

        let mutableAttr = NSMutableAttributedString(attributedString: contentAttr);
        mutableAttr.beginEditing();
        mutableAttr.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: contentAttr.length)) { color, effectiveRange, stop in
            if let fgColor = color as? UIColor, fgColor == UIColor.label {
                mutableAttr.addAttribute(.foregroundColor, value: textDefaultColor, range: effectiveRange);
            }
        }
        mutableAttr.endEditing();
        info.attributedString = mutableAttr;

        if let txtAnnotation = info.annotation() {
            (self as? FTPageUndoManagement)?.addAnnotations([txtAnnotation], indices: nil);
            return txtAnnotation;
        }
        return nil;
    }
}
