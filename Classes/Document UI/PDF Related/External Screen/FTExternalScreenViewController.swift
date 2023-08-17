//
//  FTExternalScreenViewController.swift
//  Noteshelf
//
//  Created by Amar on 8/5/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import MetalKit

extension Notification.Name {
    static let didBeginStroke = Notification.Name(rawValue:"didBeginStrokeNotification");
    static let didMoveStroke = Notification.Name(rawValue:"didMoveStrokeNotification");
    static let didEndStroke = Notification.Name(rawValue:"didEndStrokeNotification");
    
    static let didClearLaserAnnotations = Notification.Name(rawValue:"didClearLaserAnnotationsNotification");
    static let didResetLaserAnnotations = Notification.Name(rawValue:"didResetLaserAnnotationsNotification");

}

class FTExternalScreenViewController : UIViewController
{
    fileprivate var pdfScrollView : FTPDFScrollView?;
    private var presentationView: FTLaserPresentationViewController?;
    private weak var laserDelegate: FTLaserAnnotationHandler?;
    
    var brandLogoShownInExternalScreen = false;

    private let brandLogoView = Bundle.main.loadNibNamed("FTBrandLogoView", owner: nil, options: nil)![0] as! UIView;
    
    required convenience init(externalWindow: UIWindow) {
        self.init();
        
        if let scrollView = FTPDFScrollView.init(frame: externalWindow.bounds, mode: FTRenderModeExternalScreen) {
            externalWindow.addSubview(scrollView);
            self.pdfScrollView = scrollView;
            let width = NSLayoutConstraint.init(item: scrollView, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: externalWindow, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: 0);
            
            let height = NSLayoutConstraint.init(item: scrollView, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: externalWindow, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant: 0);
            
            let centerX = NSLayoutConstraint.init(item: scrollView, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: externalWindow, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0)
            
            let centerY = NSLayoutConstraint.init(item: scrollView, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: externalWindow, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0)
            NSLayoutConstraint.activate([width,height,centerX,centerY]);
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(FTExternalScreenViewController.refreshView(_:)), name: NSNotification.Name.FTRefreshExternalView, object: nil);
        
        NotificationCenter.default.addObserver(self, selector: #selector(FTExternalScreenViewController.didChangePageTemplate(_:)), name: NSNotification.Name.FTPageDidChangePageTemplate, object: nil);
    }
    
    func setPageToDisplay(_ page : FTPageProtocol,
                          presentationDelegate : FTLaserAnnotationHandler) {
        self.laserDelegate = presentationDelegate;
        self.setPageToDisplay(page, forcible: false);
        self.loadPresentationView();
    }
            
    func exitExternalScreen()
    {
        self.brandLogoShownInExternalScreen = false;
        self.pdfScrollView?.removeFromSuperview();
        NotificationCenter.default.post(name: FTWhiteboardDisplayManager.didChangePageDisplay, object: nil);
    }
    
    deinit {
        #if DEBUG
        debugPrint("deinit");
        #endif
    }
}

//MARK:- Notification Observers -
private extension FTExternalScreenViewController
{
    @objc func refreshView(_ notification : Notification) {
        guard let userInfo = notification.userInfo,
              let window = userInfo[FTRefreshWindowKey] as? UIWindow,
              FTWhiteboardDisplayManager.shared.isKeyWindow(window) else {
            return;
        }
        
        if let scrollView = self.pdfScrollView,
           let localWritingView = scrollView.writingView() {
            let properties = FTRenderingProperties();
            properties.synchronously = true;
            if let refreshRect = userInfo[FTRefreshRectKey] as? NSValue {
                let refreshRect = refreshRect.cgRectValue;
                let scaleRect = CGRectScale(refreshRect, localWritingView.scale);
                localWritingView.reloadTiles(in: scaleRect,
                                             properties: properties);
            }
            else {
                localWritingView.reloadTiles(in: scrollView.visibleRect(),
                                              properties: properties);
            }
        }
    }

    @objc func didChangePageTemplate(_ notification : Notification) {
        if let curPage = self.pdfScrollView?.writingView()?.pageToDisplay,
            let pageObject = notification.object as? FTPageProtocol,
            curPage.uuid == pageObject.uuid {
            self.setPageToDisplay(curPage, forcible: true);
        }
    }
}

private extension FTExternalScreenViewController
{
    func setPageToDisplay(_ page : FTPageProtocol,forcible : Bool) {
        var shouldRefresh = false;
        var _forcible = forcible;
        if let localWritingView = self.pdfScrollView?.writingView() {
            if(nil == localWritingView.pageToDisplay || ((localWritingView.pageToDisplay.uuid != page.uuid) || forcible)) {
                localWritingView.reset(true);
                shouldRefresh = true;
                _forcible = true;
            }
        }
        self.pdfScrollView?.setPDFPage(page, layoutForcibly: _forcible);
        self.pdfScrollView?.writingView()?.mode = FTRenderModeExternalScreen;
        self.showBrandLogoIfNeeded();
        NotificationCenter.default.post(name: FTWhiteboardDisplayManager.didChangePageDisplay,
                                        object: page.uuid);
        if shouldRefresh {
            refreshLaserView();
        }
    }
}

//MARK:- Branding Logo -
private extension FTExternalScreenViewController
{
    func showBrandLogoIfNeeded() {
        if !self.brandLogoShownInExternalScreen,
            nil == self.brandLogoView.superview,
            let parentForBrandLogoView = self.pdfScrollView?.contentHolderView {
            self.brandLogoShownInExternalScreen = true;
            self.brandLogoView.translatesAutoresizingMaskIntoConstraints = false
            parentForBrandLogoView.addSubview(self.brandLogoView);
            
            parentForBrandLogoView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[subview(==175)]", options: NSLayoutConstraint.FormatOptions.alignAllLeft, metrics: nil, views: ["subview" : self.brandLogoView]));
            parentForBrandLogoView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[subview(==38)]-18-|", options: NSLayoutConstraint.FormatOptions.alignAllBottom, metrics: nil, views: ["subview" : self.brandLogoView]));
            self.showBrandLogoWithAnimation();
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: { [weak self] in
                self?.hideBrandLogoWithAnimation();
            });
        }
    }

    func showBrandLogoWithAnimation() {
        self.brandLogoView.alpha = 0;
        UIView.animate(withDuration: 1, animations: { [weak self] in
            self?.brandLogoView.alpha = 1;
        });
    }
    
    func hideBrandLogoWithAnimation() {
        UIView.animate(withDuration: 1.5, animations: {[weak self] in
            self?.brandLogoView.alpha = 0;
        }, completion: { [weak self] (_) in
            self?.brandLogoView.removeFromSuperview();
        });
    }

}

//MARK:- Presentation Related -
private extension FTExternalScreenViewController
{
    private func loadPresentationView() {
        if nil == self.presentationView,
           let contentHolderView = self.pdfScrollView?.contentHolderView {
            let _mtkView = FTLaserPresentationViewController();
            _mtkView.isWhiteboardMode = true;
            _mtkView.enableAutoDisplay = true;
            _mtkView.delegate = self;
            _mtkView.view.frame = contentHolderView.bounds;
            _mtkView.view.autoresizingMask = [.flexibleHeight,.flexibleWidth];
            contentHolderView.addSubview(_mtkView.view);
            self.presentationView = _mtkView;
            self.addStrokeObserver();
            self.refreshLaserView();
        }
    }

    func refreshLaserView() {
        let properties = FTRenderingProperties();
        properties.forcibly = true;
        self.presentationView?.reloadTiles(in: self.pdfScrollView?.visibleRect() ?? CGRect.zero,
                                           properties: properties);
    }
    
    func addStrokeObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(FTExternalScreenViewController.processStroke(_:)), name: .didBeginStroke, object: nil);
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(FTExternalScreenViewController.processStroke(_:)), name: .didMoveStroke, object: nil);
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(FTExternalScreenViewController.processStroke(_:)), name: .didEndStroke, object: nil);
    }
        
    @objc func processStroke(_ notification : Notification) {
        guard let userInfo = notification.userInfo,
              let window = userInfo[FTRefreshWindowKey] as? UIWindow,
              FTWhiteboardDisplayManager.shared.isKeyWindow(window),
              let touch = userInfo["touch"] as? CGPoint else {
            return;
        }
        
        let newPoint = CGPoint.scale(touch, self.scale);
        var vertexType: FTVertexType = .FirstVertex;
        if notification.name == .didMoveStroke {
            vertexType = .InterimVertex;
        }
        else if notification.name == .didEndStroke {
            vertexType = .LastVertex;
        }
        let penset = userInfo["penSet"] as? FTPenSetProtocol;
        self.presentationView?.processs(newPoint, vertexType: vertexType,penSet: penset);
    }
}

extension FTExternalScreenViewController: FTLaserPresentationDelegate {
    func addLaserAnnotation(_ annotation: FTAnnotation) {
        
    }
    
    var page: FTPageProtocol? {
        return self.pdfScrollView?.writingView()?.pageToDisplay;
    }
    
    var scale: CGFloat {
        return self.pdfScrollView?.writingView()?.scale ?? 1;
    }
    
    var contentSize: CGSize {
        return self.presentationView?.view.frame.size ?? CGSize.zero;
    }
    
    var visibleRect: CGRect {
        return self.presentationView?.view.frame ?? CGRect.zero;
    }
    
    func lasserAnnotations() -> [FTAnnotation] {
        guard let page = self.pdfScrollView?.writingView()?.pageToDisplay else {
            return [FTAnnotation]();
        }
        return self.laserDelegate?.laserAnnotations(for: page) ?? [FTAnnotation]();
    }
}
