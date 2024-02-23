//
//  FTPDFDocumentPDFContentGenerator.swift
//  Noteshelf
//
//  Created by Siva on 23/12/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTPDFDocumentPDFContentGenerator: FTPDFDocumentContentGenerator {
    fileprivate var pdfContext: CGContext!;
    fileprivate var exportItem = FTExportItem();

    override func generateContent(forItem item: FTItemToExport,
                                  onCompletion completion: @escaping InternalCompletionHandler) {
        self.currentItem = item;
        self.internalCompletionHandler = completion;
        self.preprocessGeneration { (error) in
            if(nil != error) {
                self.finalizeProcess();
                completion(nil,error,false);
                return;
            }
            
            var scale: CGFloat  = 1.0;
            var start = 0;
            let destPath = self.localFilePathWithExtension();
            let item = FTExportItem();
            item.fileName = self.preferedFileName;
            let url = URL(fileURLWithPath: destPath);

            if !self.exportPaused {
                
                item.exportFileName = url.lastPathComponent;
                item.representedObject = destPath;
                item.tags = NSMutableSet();
                self.exportItem = item;
                self.pdfContext = CGContext(url as CFURL, mediaBox: nil, nil);
            }
            else
            {
                start = Int(self.progress.completedUnitCount);
            }
            let pdfView = FTPDFExportView(frame: CGRect.zero, pdfScale:1, pdfPage:nil, scale:1);
            
            let totalPages = self.pagesToExport.count;
            let val = max(Int(round(Double(totalPages)*0.1)),1);
            self.progress.totalUnitCount = Int64(totalPages+val);
            
            for index in start..<totalPages
            {
                if self.progress.isCancelled
                {
                    self.finalizeProcess();
                    completion(self.exportItem,NSError.exportCancelError(),true);
                    return;
                }
                self.isProcessInProgress = true;
                
                if self.progress.isPaused {
                    self.exportPaused = true;
                    self.isProcessInProgress = false;
                    return;
                }
                autoreleasepool {
                    let page = self.pagesToExport[index] ;
                    
                    var pdfScale: CGFloat = 1.0;
                    var pageRect = self.pageRectForPDFPage(page, scale: &pdfScale);
                    
                    let referenceViewSize = page.pageReferenceViewSize();
                    scale = pageRect.size.width / referenceViewSize.width;
                    
                    pageRect.origin = CGPoint.zero;
                    pdfView?.bounds = pageRect;
                    pdfView?.pdfPage = page;
                    pdfView?.pdfScale = pdfScale;
                    pdfView?.scale = scale;

                    self.pdfContext.beginPage(mediaBox: &pageRect);
                    let renderBackground: Bool
                    if !page.templateInfo.isTemplate || page.templateInfo.isImageTemplate {
                                renderBackground = true
                    } else {
                        renderBackground = !self.target.properties.hidePageTemplate
                    }
                    pdfView?.draw(in: self.pdfContext, renderBackground: renderBackground)
                    
                    if self.target.properties.includesPageFooter {
                        var textColor = UIColor.black
                        if let _page = page as? FTPageBackgroundColorProtocol,
                            page.templateInfo.isTemplate,
                           let bgcolor = _page.pageBackgroundColor
                        {
                            textColor = bgcolor.blackOrWhiteContrastingColor() ?? UIColor.black
                        }
                        FTPDFExportView.renderFooterInfo(context: self.pdfContext,
                                                         isFlipped: true,
                                                         scale: scale,
                                                         pageSize: pageRect.size,
                                                         title: self.preferedFileName,
                                                         currentPage: index + 1,
                                                         totalPages: totalPages,
                                                         textColor: textColor)
                    }
                    self.pdfContext.endPage();
                    
                    let exportItem = self.exportItem;
                    var tags = [String]();
                    if let pageTags = (page as? FTPageTagsProtocol)?.tags() {
                        tags = pageTags;
                    }
                    for tag in tags {
                        exportItem.tags?.add(tag);
                    }
                    page.unloadContents();
                    self.isProcessInProgress = false;
                }
                self.progress.completedUnitCount += 1;
            }
            self.pdfContext.closePDF();
            self.exportPaused = false;

            self.pagesToExport.forEach { (eachPage) in
                (eachPage as? FTNoteshelfPage)?.unloadPDFContentsIfNeeded();
            }

            self.addAnnotations(url)

            self.progress.completedUnitCount += Int64(val);

            completion(self.exportItem,nil,false);
            
            runInMainThread({
                self.finalizeProcess();
            });
        };
    }

    private func indexOfPage(_ page: PDFPage, in pages: [FTPageProtocol]) -> Int {
        let matchingPage = pages.firstIndex(where: { pageIn -> Bool in
            return page == pageIn.pdfPageRef
        })
        return matchingPage ?? -1
    }
    
    private func addAnnotations(_ url: URL) {
        guard let document = PDFDocument(url: url) else {
            return;
        }
        let pageCount = document.pageCount;
        for index in 0..<pageCount {
            autoreleasepool {
                if let pageExported = document.page(at: index) {
                    if !self.target.properties.hidePageTemplate {
                        let pdfPage = self.pagesToExport[index]
                        pdfPage.pdfPageRef?.annotations.forEach({ annotation in
                            if annotation.action is PDFActionURL {
                                pageExported.addAnnotation(annotation)
                            } else if let gotoAction = annotation.action as? PDFActionGoTo {
                                if let existingPage = gotoAction.destination.page {
                                    let indexNew = self.indexOfPage(existingPage, in: self.pagesToExport)
                                    if let newPage = document.page(at: indexNew) {
                                        let destinationNew = PDFDestination(page: newPage, at: gotoAction.destination.point)
                                        gotoAction.destination = destinationNew
                                        annotation.action = gotoAction
                                    }
                                }
                                pageExported.addAnnotation(annotation)
                            }
                        })
                    }
                    // Text Linking
                    let annotations = pageExported.annotations
                    annotations.forEach { eachAnnotation in
                        if let action = eachAnnotation.action as? PDFActionURL, let url = action.url {
                            let queryItems = url.getQueryItems()
                            if let documentId = queryItems.docId, let pageId = queryItems.pageId
                                ,let book = self.notebook, documentId == currentDocumentLinkingId
                                ,let pageIndex = book.pages().firstIndex(where: { $0.uuid == pageId })
                                ,let destPdfPage = document.page(at: pageIndex) {
                                let destinationNew = PDFDestination(page: destPdfPage, at: CGPoint(x: 0, y: destPdfPage.bounds(for: .cropBox).height));
                                let goToAction = PDFActionGoTo(destination: destinationNew)
                                eachAnnotation.action = goToAction
                            }
                        }
                    }
                }
            }
        }
        
        if let documentToExport = self.pagesToExport.first?.pdfPageRef?.document {
            document.outlineRoot = documentToExport.outlineRoot
        }
        document.write(to: url)
    }
}
