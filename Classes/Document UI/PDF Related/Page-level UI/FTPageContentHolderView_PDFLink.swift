//
//  FTPageContentHolderView_PDFLink.swift
//  Noteshelf
//
//  Created by Amar on 01/02/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import SafariServices
import Flurry_iOS_SDK


extension FTPageContentHolderView {
    @objc static let actionFlickerViewTag : Int = 1002;
    private static var linkTappedTimer : Timer?;

    @objc internal func canProceedForActionCheck(mode : RKDeskMode) -> Bool
    {
        if FTUserDefaults.isHyperlinkDisabled() &&
            (mode == RKDeskMode.deskModeEraser ||
                mode == RKDeskMode.deskModePen ||
                mode == RKDeskMode.deskModeMarker)
        {
            return false
        }
        if let pdfpage = self.pageToDisplay {
            let localMetadata = pdfpage.parentDocument?.localMetadataCache;
            if((self.mode != FTRenderModeDefault) || (nil == localMetadata) || (localMetadata!.zoomModeEnabled)) {
                return false;
            }
            return true;
        }
        return false;
    }
    
    @objc internal func isActionAnnotationAvailable(atLocation point : CGPoint) -> Bool
    {
        if let pdfPage = self.pageToDisplay.pdfPageRef {
            let pointOnPage = pdfPage.convertPoint(point, fromView: self);
            let annotation = pdfPage.annotation(at: pointOnPage);
            if(nil != annotation?.action) {
                return true;
            }
        }
        return false;
    }
    
    @objc internal func showSelectionRectForAnnotation(atPoint point : CGPoint)
    {
        if let pdfPage = self.pageToDisplay.pdfPageRef {
            let pointOnPage = pdfPage.convertPoint(point, fromView: self);
            let annotation = pdfPage.annotation(at: pointOnPage);
            if(nil != annotation?.action) {
                let viewRect = pdfPage.convertRect(annotation!.bounds, toViewBounds: self.bounds);
                var view = self.viewWithTag(FTPageContentHolderView.actionFlickerViewTag);
                if(nil == view) {
                    view = UIView.init(frame: viewRect);
                    view?.isUserInteractionEnabled = false;
                    view?.backgroundColor = UIColor.init(hexString:"4AA1FF")?.withAlphaComponent(0.3);//UIColor(red: 26/255.0, green: 139/255.0, blue: 239/255.0, alpha: 0.4)
                    view?.layer.compositingFilter = "multiplyBlendMode";
                    self.addSubview(view!);
                    view?.tag = FTPageContentHolderView.actionFlickerViewTag;
                }
                view?.frame = viewRect;
                
                FTPageContentHolderView.linkTappedTimer?.invalidate();
                FTPageContentHolderView.linkTappedTimer = nil;
                FTPageContentHolderView.linkTappedTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: {[weak self] (timer) in
                    self?.removeActionAnnotationSelectionRect();
                });
            }
        }
    }
    
    @objc internal func performActionAnnotationIfAvailable(atLocation point : CGPoint)
    {
        if let pdfPage = self.pageToDisplay.pdfPageRef {
            let pointOnPage = pdfPage.convertPoint(point, fromView: self);
            let annotation = pdfPage.annotation(at: pointOnPage);
            if let action = annotation?.action {
                self.removeActionAnnotationSelectionRect();
                if(action.type.lowercased() == "goto") {
                    self.performGotoAction(action as! PDFActionGoTo)
                }
                else if(action.type.lowercased() == "uri") {
                    self.performURLAction(action as! PDFActionURL);
                }
                track("pdf_link_tap", params: ["type":action.type.lowercased()])
            }
        }
    }
    
    @objc internal func removeActionAnnotationSelectionRect() {
        FTPageContentHolderView.linkTappedTimer?.invalidate();
        FTPageContentHolderView.linkTappedTimer = nil;
        self.viewWithTag(FTPageContentHolderView.actionFlickerViewTag)?.removeFromSuperview();
    }
    
    private func performGotoAction(_ actionGoto : PDFActionGoTo)
    {
        if let destinationpage = actionGoto.destination.page, let pdfPage = self.pageToDisplay {
            if let pageIndex = destinationpage.document?.index(for: destinationpage) {
                if let pages = pdfPage.parentDocument?.pages() {
                    for eachItem in pages {
                        if(eachItem.associatedPDFFileName == pdfPage.associatedPDFFileName
                            && eachItem.associatedPDFKitPageIndex == pageIndex) {
                            NotificationCenter.default.post(name: NSNotification.Name.FTShowPage, object: self, userInfo: [FTShowPageIndexKey:eachItem.pageIndex()])
                            break;
                        }
                    }
                }
            }
        }
    }

    private func performURLAction(_ actionURL : PDFActionURL)
    {
        if let urlToLoad = actionURL.url {
            if(UIApplication.shared.canOpenURL(urlToLoad)) {
                let title = NSLocalizedString("ExtenalLink", comment: "Extenal Link");
                let message = String.init(format: NSLocalizedString("ExternalLinkOpenInfo", comment: "An external applicaiton..."), (urlToLoad.absoluteString));
                if let visibleController = Application.visibleViewController {
                    UIAlertController.showConfirmationDialog(with: title,
                                                             message: message,
                                                             from: visibleController,
                                                             okHandler: {
                                                                UIApplication.shared.open(urlToLoad, options: [:], completionHandler: nil);
                    });
                }
            }
        }
    }
}
