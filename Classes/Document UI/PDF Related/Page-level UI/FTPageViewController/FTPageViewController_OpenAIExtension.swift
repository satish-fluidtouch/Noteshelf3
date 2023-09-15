//
//  FTPageViewController_OpenAIExtension.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 01/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension FTPageViewController {
    
    @objc func startOpenAiForPage() {

        guard FTIAPManager.shared.premiumUser.isPremiumUser else {
            FTIAPurchaseHelper.shared.showIAPAlertForFeature(feature: "Noteshelf AI", on: self);
            return;
        }

        guard let page = self.pdfPage else {
            return;
        }
        var annotationsToConsider = [FTAnnotation]();

        if let selectedText = self.writingView?.selectedPDFString(), !selectedText.isEmpty {
            self.writingView?.selectedTextRange = nil;
            self.generateOpenAIContentFor(annotations: annotationsToConsider,pdfContent: selectedText);
            return;
        }
        
        var shouldReadPDFContent = true;
        if currentDeskMode() == .deskModeClipboard {
            annotationsToConsider = self.lassoInfo.selectedAnnotations;
            self.lassoSelectionView?.finalizeMove();
            shouldReadPDFContent = annotationsToConsider.isEmpty;
        }
        annotationsToConsider = annotationsToConsider.isEmpty ? page.annotations() : annotationsToConsider
        
        var pdfContent = "";
        if !page.templateInfo.isTemplate
            , shouldReadPDFContent
            , let pdfString = page.pdfPageRef?.string?.openAITrim()
            ,!pdfString.isEmpty {
            pdfContent = pdfString;
        }
        self.generateOpenAIContentFor(annotations: annotationsToConsider,pdfContent: pdfContent);
    }
    
    @objc private func generateOpenAIContentFor(annotations : [FTAnnotation],pdfContent: String = "") {
        var annotationsToConsider = [FTAnnotation]();
        
        var contentToSearch: String = "";
        if !pdfContent.isEmpty {
            contentToSearch = pdfContent.appending(" ");
        }
        
        annotations.forEach { eachAnnotation in
            if(eachAnnotation.supportsHandwrittenRecognition && FTIAPManager.shared.premiumUser.isPremiumUser) {
                annotationsToConsider.append(eachAnnotation)
            }
            else if let textAnnotation = eachAnnotation as? FTTextAnnotation,let string = textAnnotation.attributedString?.string.openAITrim(), !string.isEmpty {
                contentToSearch.append(string);
            }
        }
        
        if annotationsToConsider.isEmpty {
            self.showNoteshelfAIController(contentToSearch);
        }
        else {
            let canvasSize = self.pdfPage?.pdfPageRect.size ?? CGSize.zero;
            let loadingIndicator = FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self.delegate ?? self, withText: NSLocalizedString("Indexing", comment: "Indexing"))
            DispatchQueue.global().async { [weak self] in
                if let weakSelf  = self {
                    let lang = FTConvertToTextViewModel.convertPreferredLanguage;
                    let recognitionProcessor = FTRecognitionTaskProcessor(with: lang)
                    let task: FTRecognitionTask = FTRecognitionTask(language: lang
                                                                    , annotations: annotationsToConsider
                                                                    , canvasSize: canvasSize);
                    
                    task.onCompletion = { (info, error) in
                        runInMainThread {
                            loadingIndicator.hide(nil);
                            guard let recogInfo = info,                    
                                  FTConvertToTextViewModel.convertPreferredLanguage == recogInfo.languageCode else {
                                weakSelf.showNoteshelfAIController(contentToSearch);
                                return
                            }
                            let text = recogInfo.recognisedString.openAITrim();
                            if !text.isEmpty {
                                contentToSearch.append(text);
                            }
                            weakSelf.showNoteshelfAIController(contentToSearch);
                        }
                    }
                    recognitionProcessor.startTask(task, onCompletion: nil)
                }
            }
        }
    }
    
    private func showNoteshelfAIController(_ content:String) {
        FTNoteshelfAIViewController.showNoteshelfAI(from: self
                                                    , content: content
                                                    , delegate: self);
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
                var yquotient = offset / page.lineHeight;
                if offset % page.lineHeight > 0 {
                    yquotient += 1;
                }
                
                origin.y = (yquotient * page.lineHeight).toCGFloat() + page.pageTopMargin
            }
        }
        origin.x += FTTextToStrokeProperties.paragraphMargin;
        return origin;
    }
    
    func noteshelfAIController(_ ccntroller: FTNoteshelfAIViewController
                               , didTapOnAction action: FTNotesehlfAIAction
                               , content: String) {
        ccntroller.dismiss(animated: true) {
            if action == .copyToClipboard {
                UIPasteboard.general.string = content;
            }
            else if action == .addToPage {
                if let annotation = self.pdfPage?.addTextAnnotation(content, visibleRect: CGRectScale(self.visibleRect(), 1/self.pageContentScale)) {
                    self.refreshView(refreshArea: annotation.boundingRect);
                }
            }
            else if action == .addToNewPage {
                if let page = self.pdfPage {
                    self.delegate?.insertNewPage(page, addText: content);
                }
            }
            else if action == .addHandwriting {
                let origin = self.originToInsertHandwrite();
                if let page = self.pdfPage,page.isAtTheEndOfPage(origin) {
                    self.delegate?.insertNewPage(page, addText: content, isHandwrite: true);
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
                    self.delegate?.insertNewPage(page, addText: content, isHandwrite: true);
                }
            }
        }
    }
}

extension FTPageViewController {
    @objc func convertTextToStroke(_ string: String,origin inOrigin: CGPoint) {
        guard let nsPage = self.pdfPage else {
            return;
        }
        self.delegate?.addTextAsStrokes(to: nsPage, content: string,origin: inOrigin)
    }
}

extension FTPDFRenderViewController {
    func insertNewPage(_ after: FTPageProtocol
                       ,addText text:String
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
                    self.addTextAsStrokes(to: newPage, content: text,origin:origin);
                }
                else {
                    newPage.addTextAnnotation(text);
                }
                loadingIndicator?.hide(nil);
                showPage(newPage.pageIndex())
            }
        }
    }
        
    func addTextAsStrokes(to page:FTPageProtocol
                          , content: String
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
    func addTextAnnotation(_ text: String,visibleRect: CGRect = .null) -> FTAnnotation? {
        let info = FTTextAnnotationInfo();
        info.scale = 1;
        info.visibleRect = CGRect(origin: .zero, size: self.pdfPageRect.size).insetBy(dx: 20, dy: 20);
        if !visibleRect.isNull {
            info.visibleRect = visibleRect;
        }
        info.atPoint = info.visibleRect.origin;
        
        let startPoint = startMargin;
        info.atPoint.x = max(info.atPoint.x , startPoint.x)
        info.atPoint.y = max(info.atPoint.y , startPoint.y)
        
        info.localmetadataCache = self.parentDocument?.localMetadataCache;
        info.fromConvertToText = true;
        info.enterEditMode = false;
        info.string = text;
        
        if let txtAnnotation = info.annotation() {
            (self as? FTPageUndoManagement)?.addAnnotations([txtAnnotation], indices: nil);
            return txtAnnotation;
        }
        return nil;
    }

}
