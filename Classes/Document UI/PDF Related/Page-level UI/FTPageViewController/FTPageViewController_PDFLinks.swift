//
//  FTPageViewController_PDFLinks.swift
//  Noteshelf
//
//  Created by Amar on 15/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTLinkActionInfo: NSObject {
    var rect = CGRect.null;
    var annotation: FTAnnotationAction?
    var pdfAnnotation: PDFAnnotation?;
}

private let FTActionFlickerViewTag : Int = 1002;

extension FTPageViewController {
    private static var linkTappedTimer : Timer?;
    func configureForPDFLinks()
    {
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "DidEndTouches"),
                                               object: nil,
                                               queue: nil)
        { [weak self] notification in
            guard notification.isSameSceneWindow(for: self?.view.window) else { return }
            self?.removeActionAnnotationSelectionRect();
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "DidMoveTouches"),
                                               object: nil,
                                               queue: nil)
        { [weak self] (notification) in
            guard notification.isSameSceneWindow(for: self?.view.window) else { return }
            guard let strongSelf = self else {return};
            guard let contentView = self?.contentHolderView else {return};
            if(nil == contentView.viewWithTag(FTActionFlickerViewTag)) {
                return;
            }

            let touches = notification.userInfo?["Touches"] as? Set<UITouch>;
            if(touches?.isEmpty ?? true) {
                self?.removeActionAnnotationSelectionRect();
            }
            else {
                if strongSelf.canProceedForActionCheck(mode: strongSelf.currentDeskMode()),let touch = touches?.first {
                    let point = touch.location(in: contentView);
                    if(nil == strongSelf.isLinkActionAvailable(atLocation: point)) {
                        self?.removeActionAnnotationSelectionRect();
                    }
                }
            }
        };
    }
    
    
    @discardableResult func highlightPDFLink(atPoint point : CGPoint) -> Bool {
        var success = false;
        if self.canProceedForActionCheck(mode: self.currentDeskMode()),
            let info = self.isLinkActionAvailable(atLocation: point) {
            success = true;
            self.showSelectionRect(info.rect);
        }
        return success;
    }
    
    func performPDFLinkAction(atPoint point : CGPoint)
    {
        self.performActionIfAvailable(atLocation: point);
    }
}

//MARK:- General Private methods -
private extension FTPageViewController {
    func canProceedForActionCheck(mode : RKDeskMode) -> Bool
    {
        guard nil != self.pdfPage else {
            return false;
        }
        if FTUserDefaults.isHyperlinkDisabled() &&
            (mode == RKDeskMode.deskModeEraser ||
                mode == RKDeskMode.deskModePen ||
                mode == RKDeskMode.deskModeMarker ||
             mode == RKDeskMode.deskModeShape || mode == RKDeskMode.deskModeClipboard)
        {
            return false
        }
        
        if self.renderMode != FTRenderModeDefault || self.isInZoomMode() {
            return false;
        }
        return true;
    }
    
    func isLinkActionAvailable(atLocation point : CGPoint) -> FTLinkActionInfo?
    {
        if let info = self.annotationLinkAction(atPoint: point) {
            return info;
        }
        return self.PDFAnnotationActionInfo(at: point);
    }
            
    func showSelectionRect(_ rect : CGRect)
    {
        guard let contentView = self.contentHolderView else { return }
        if(!rect.isNull) {
            var view = contentView.viewWithTag(FTActionFlickerViewTag);
            if(nil == view) {
                let highlighterView = UIView.init(frame: rect);
                highlighterView.isUserInteractionEnabled = false;
                highlighterView.backgroundColor = UIColor.init(hexString:"4AA1FF").withAlphaComponent(0.3);//UIColor(red: 26/255.0, green: 139/255.0, blue: 239/255.0, alpha: 0.4)
                highlighterView.layer.compositingFilter = "multiplyBlendMode";
                contentView.addSubview(highlighterView);
                highlighterView.tag = FTActionFlickerViewTag;
                view = highlighterView;
            }
            view?.frame = rect;
            
            FTPageViewController.linkTappedTimer?.invalidate();
            FTPageViewController.linkTappedTimer = nil;
            FTPageViewController.linkTappedTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: {[weak self] (_) in
                self?.singleTapGestureRecognizer?.isEnabled = false;
                self?.removeActionAnnotationSelectionRect();
            });
        }
    }
    
    func performActionIfAvailable(atLocation point : CGPoint)
    {
        if let info = self.isLinkActionAvailable(atLocation: point) {
            self.removeActionAnnotationSelectionRect();
            if let annotation = info.annotation {
                self.performAction(annotation)
            }
            else if let pdfAnnotation = info.pdfAnnotation {
                self.performPDFAnnotationAction(pdfAnnotation);
            }
            else {
                fatalError("should not execute");
            }
        }
    }
    
    func removeActionAnnotationSelectionRect() {
        FTPageViewController.linkTappedTimer?.invalidate();
        FTPageViewController.linkTappedTimer = nil;
        
        self.contentHolderView?.viewWithTag(FTActionFlickerViewTag)?.removeFromSuperview();
    }
}

//MARK:- PDF Action Related -
private extension FTPageViewController
{
    func PDFAnnotationActionInfo(at point : CGPoint) -> FTLinkActionInfo?
    {
        var actionInfo: FTLinkActionInfo?
        guard let contentView = self.contentHolderView else { return actionInfo; }
        if let page = self.pdfPage, let pdfPage = page.pdfPageRef {
            let pointOnPage = pdfPage.convertPoint(point, fromView: contentView, rotationAngle: Int(page.rotationAngle));
            let annotation = pdfPage.annotation(at: pointOnPage);
            if(nil != annotation?.action) {
                let viewRect = pdfPage.convertRect(annotation!.bounds, toViewBounds: contentView.bounds, rotationAngle:Int(page.rotationAngle));
                actionInfo = FTLinkActionInfo();
                actionInfo?.rect = viewRect;
                actionInfo?.pdfAnnotation = annotation;
            }
        }
        return actionInfo;
    }
    
    func performPDFAnnotationAction(_ annotation : PDFAnnotation) {
        if let action = annotation.action {
            if(action.type.lowercased() == "goto") {
                self.performGotoAction(action as! PDFActionGoTo)
            }
            else if(action.type.lowercased() == "uri") {
                let todayLinkURLString = FTSharedGroupID.getAppGroupID() + "://todayLink"
                if let url = action as? PDFActionURL, url.url?.absoluteString ==  todayLinkURLString {
                    self.performTodayLinkAction()
                }
                else {
                    self.performURLAction(action as! PDFActionURL);
                }
            }
            track("pdf_link_tap", params: ["type":action.type.lowercased()])
        }
    }
    
    func performGotoAction(_ actionGoto : PDFActionGoTo)
    {
        if let destinationpage = actionGoto.destination.page, let pdfPage = self.pdfPage {
            if let pageIndex = destinationpage.document?.index(for: destinationpage) {
                if let pages = pdfPage.parentDocument?.pages() {
                    for eachItem in pages {
                        if(eachItem.associatedPDFFileName == pdfPage.associatedPDFFileName
                            && eachItem.associatedPDFKitPageIndex == pageIndex) {
                            self.delegate?.showPage(at: eachItem.pageIndex(), forceReLayout: false);
                            break;
                        }
                    }
                }
            }
        }
    }
    
    func performURLAction(_ actionURL : PDFActionURL)
    {
        if let urlToLoad = actionURL.url {
            urlToLoad.openURL(on: self);
        }
    }
}

//MARK:- Annotation Related
private extension FTPageViewController {
    func annotationLinkAction(atPoint point: CGPoint) -> FTLinkActionInfo? {
        var annotationInfo : FTLinkActionInfo?;
        
        let annotations = self.pdfPage?.annotations().reversed() ?? [FTAnnotation]();
        let scaledDownPoint = CGPointScale(point, 1/self.pageContentScale);
        for eachAnnotation in annotations {
            if !eachAnnotation.isReadonly,
                let _annotation = eachAnnotation as? FTAnnotationLinkHandler {
                if let actionInfo = _annotation.hasLink(atPoint: scaledDownPoint) {
                    annotationInfo = FTLinkActionInfo();
                    annotationInfo?.annotation = actionInfo;
                    annotationInfo?.rect = CGRect.scale(actionInfo.rect, self.pageContentScale);
                    break;
                }
            }
        }
        return annotationInfo;
    }
    
    func performAction(_ actionInfo: FTAnnotationAction) {
        if let actionURL = actionInfo.URL {
            actionURL.openURL(on: self);
        }
    }
}

extension URL {
    func openURL(on viewController: UIViewController) {
        if(UIApplication.shared.canOpenURL(self)) {
            let title = NSLocalizedString("ExternalLink", comment: "Extenal Link");
            let message = String.init(format: NSLocalizedString("ExternalLinkOpenInfo", comment: "An external applicaiton..."), (self.path));
            UIAlertController.showConfirmationDialog(with: title,
                                                     message: message,
                                                     from: viewController,
                                                     okHandler: {
                                                        UIApplication.shared.open(self, options: [:], completionHandler: nil);
            });
        }
    }
}
private extension FTPageViewController {
    func performTodayLinkAction(){
        if let pdfPage = self.pdfPage , let pages = pdfPage.parentDocument?.pages() {
            guard let currentDate = Date().utcDate() else { return };
            let destinationPage = pages.first { eachpage in
                if let nsPage = eachpage as? FTNoteshelfPage, nsPage.diaryPageInfo?.type == .day, let date = nsPage.diaryPageInfo?.date {
                    let pageDate = Date(timeIntervalSinceReferenceDate: date).utcDate() ?? Date(timeIntervalSinceReferenceDate: date);
                    if pageDate.compareDate(currentDate) == ComparisonResult.orderedSame {
                        return true;
                    }
                }
                return false;
            }
            if let destinationPageIndex = destinationPage?.pageIndex() {
                self.delegate?.showPage(at: destinationPageIndex, forceReLayout: false, animate: true)
            }
        }
    }
}
