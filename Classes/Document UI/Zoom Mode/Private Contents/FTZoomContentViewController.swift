//
//  FTZoomContentViewController.swift
//  Noteshelf
//
//  Created by Amar on 13/04/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTZoomContentViewControllerDelegate: AnyObject {
    func zoomContentViewController(_ viewController: FTZoomContentViewController,
                                   didChangeAutoScrollWidth width:Int);
}
protocol FTZoomContentViewControllerDataSource: AnyObject {
    var noteshelfDocument: FTDocumentProtocol? {get};
    var mainRenderViewController: FTPDFRenderViewController? {get};
}

class FTZoomContentViewController: UIViewController {
    @IBOutlet private weak var autoAdvanceIndicator: UIButton?;
    @IBOutlet private weak var autoAdvanceIndicatorTrailingConstraint: NSLayoutConstraint?;
    @IBOutlet private weak var autoAdvanceView: FTZoomBorderView?;
    @IBOutlet private weak var contentView: UIView?;
    @IBOutlet private weak var autoAdvancePanGesture: UIPanGestureRecognizer?;

    private weak var pageViewController: FTPageViewController?;
    
    weak var delegate: FTZoomContentViewControllerDelegate?
    weak var dataSource: FTZoomContentViewControllerDataSource?
    
    var lineHeight: CGFloat = 34 {
        didSet {
            self.validateUI();
        }
    }
    
    private let maxAutoScrollWidth = 300;
    private let minAutoScrollWidth = 30;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.autoAdvanceView?.autoscrollWidth = self.dataSource?.noteshelfDocument?.localMetadataCache?.zoomAutoscrollWidth ?? minAutoScrollWidth;
        validateUI();
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews();
        self.autoAdvanceView?.setNeedsDisplay();
        if let zoomBordersView = self.autoAdvanceView,
            let autoScrollIndicator = self.autoAdvanceIndicator {
            let autoscrollWidth = CGFloat(zoomBordersView.autoscrollWidth) - autoScrollIndicator.frame.width * 0.5;
            self.autoAdvanceIndicatorTrailingConstraint?.constant = autoscrollWidth;
        }
    }
    
    func validateUI() {
        let scale = self.pageViewController?.pageContentScale ?? 1;
        self.autoAdvanceView?.lineHeight = lineHeight * scale;

        let autoAdvanceEnabled = self.dataSource?.noteshelfDocument?.localMetadataCache?.zoomPanelAutoAdvanceEnabled ?? false;
        self.autoAdvanceView?.shouldShowAutoAdvance = autoAdvanceEnabled;
        self.autoAdvanceIndicator?.isHidden = !autoAdvanceEnabled;
    }
    
    func didChangeDeskMode(_ mode : RKDeskMode) {
        self.pageViewController?.setMode(mode);
        //Since we are supporting shape editing in zoom mode, removing active annotations on desk mode change
        if let pageViewController = pageViewController, pageViewController.activeAnnotationController != nil {
            pageViewController.endEditingActiveAnnotation(nil, refreshView: true)
        }
    }
    
    func setPageToDisplay(_ page: FTPageProtocol) {
        if(nil == self.pageViewController) {
            self.setupPageController(page);
        }
        else {
            self.pageViewController?.setPage(page,layoutForcibly: true);
        }
        self.lineHeight = CGFloat(page.lineHeight);
    }
    
    var contentOffset: CGPoint {
        set {
            if let pageController = self.pageViewController {
                pageController.scrollView?.contentOffset = newValue;
                self.autoAdvanceView?.setNeedsDisplay();
            }
        }
        get {
            return self.pageViewController?.scrollView?.contentOffset ?? CGPoint.zero;
        }
    }
    
    var visibleFrame: CGRect {
        return self.pageViewController?.scrollView?.visibleRect() ?? CGRect.null;
    }

    var pageContentScale: CGFloat {
        return self.pageViewController?.pageContentScale ?? 1;
    }

    var zoomFactor: CGFloat = 1;
    
    func zoomFrom(center pointIn1x: CGPoint,animate:Bool,forcibly: Bool)
    {
        guard let pageController = self.pageViewController,
            let scrollView = pageController.scrollView else {
            return;
        }
        let percentageOfZoom = self.zoomFactor / (scrollView.maxZoomScale - scrollView.minZoomScale);
        let maxZoom = scrollView.maximumZoomScale;
        let minZoom = scrollView.minimumZoomScale;

        let value = percentageOfZoom*(maxZoom-minZoom);
        if(!forcibly && fabsf(Float(value - 1)) < 0.001) {
            return;
        }
        scrollView.isZoomingInProgress = true;
        if(pointIn1x != CGPoint.zero) {
            let scaledPoint = CGPoint.scale(pointIn1x, self.zoomFactor/value);
            scrollView.zoomTo(scaledPoint, scale: value, animate: animate);
        }
        else {
            scrollView.setZoomScale(value, animated: animate)
            if(!animate) {
                scrollView.delegate?.scrollViewDidEndZooming?(scrollView, with: scrollView.contentHolderView, atScale: value);
            }
        }
    }
    
    func activeAnnotationController() -> FTAnnotationEditController? {
        self.pageViewController?.activeAnnotationController
    }
    
    func updateGestureConditions() {
        self.pageViewController?.scrollView?.updateGestureConditions();
    }
    
    func registerViewForTouchEvents() {
        self.pageViewController?.writingView?.registerViewForTouchEvents();
    }
    
    func unregisterView(forTouchEvents setToDefault: Bool) {
        self.pageViewController?.writingView?.unregisterView(forTouchEvents: setToDefault);
    }
    
    func refreshView() {
        self.pageViewController?.scrollView?.setNeedsLayout();
    }
}

//MARK: - Private -
private extension FTZoomContentViewController
{
    func removeCurrentPageViewController() {
        self.pageViewController?.willMove(toParent: nil);
        self.pageViewController?.removeFromParent();
        self.pageViewController?.isCurrent = false;
        self.pageViewController?.view.removeFromSuperview();
    }
    
    func setupPageController(_ page:FTPageProtocol) {
        let pageVC = FTPageViewController(page: page,
                                          mode: FTRenderModeZoom,
                                          delegate:self.dataSource?.mainRenderViewController);
        pageVC.isCurrent = true;
        pageVC.showPageImmediately = true;
        self.addChild(pageVC);
        self.pageViewController = pageVC
        if let contentView = self.contentView {
            pageVC.view.frame = contentView.bounds;
            contentView.addSubview(pageVC.view);
            pageVC.view.addEqualConstraintsToView(toView: contentView)
            pageVC.view.layer.cornerRadius = 10
            pageVC.view.setBorderColor(withBorderWidth: 1, withColor: UIColor.label.withAlphaComponent(0.04))
            contentView.addShadow(cornerRadius: 10.0, color: UIColor.label.withAlphaComponent(0.1), offset: CGSize(width: 0.0, height: 1.0), opacity: 1.0, shadowRadius: 4.0)
        }
        pageVC.didMove(toParent: self);
        if let localDocCache = page.parentDocument?.localMetadataCache {
            self.zoomFactor = localDocCache.zoomFactor;
        }
    }
}

//MARK: - Actions -
private extension FTZoomContentViewController {
    @IBAction func autoAdvanceGestureRecognized(_ gesture: UIPanGestureRecognizer) {
        guard let zoomBordersView = self.autoAdvanceView else {
            return;
        }
        switch gesture.state {
        case .changed:
            let translate = gesture.translation(in: self.view);
            gesture.setTranslation(CGPoint.zero, in: self.view);
            let autoScrollWidth = zoomBordersView.autoscrollWidth - Int(translate.x);
            zoomBordersView.autoscrollWidth = clamp(autoScrollWidth, minAutoScrollWidth, maxAutoScrollWidth)
            self.view.setNeedsLayout();
        case .ended,.cancelled:
            self.delegate?.zoomContentViewController(self, didChangeAutoScrollWidth: zoomBordersView.autoscrollWidth);
        default:
            break;
        }
    }
}

//MARK: - UIGestureRecognizerDelegate -
extension FTZoomContentViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        var shouldBegin = false;
        if gestureRecognizer == self.autoAdvancePanGesture {
            let location = gestureRecognizer.location(in: self.view);
            if let autoAdvanceButton = self.autoAdvanceIndicator,
                autoAdvanceButton.frame.contains(location) {
                shouldBegin = true;
            }
        }
        return shouldBegin;
    }
}
