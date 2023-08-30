//
//  FTRefreshViewController.swift
//  FTNotebookCreationAnimation
//
//  Created by Mahesh on 30/04/20.
//  Copyright © 2020 Mahesh. All rights reserved.
//

import UIKit

enum FTNewPageCreationOption: Int {
    case normalPage
    case photoPage
    case importPhotoPage
    case templatePage
    case scanDocumentPage
    case cameraPage
    case pageOptions
}

enum FTRefreshPosition: Int {
    case top
    case left
    case bottom
    case right
};

protocol FTRefreshSelectedItemDelegate: AnyObject {
    func didSelectItem(_ menuItem: FTAddMenuItemProtocol, insertPagePosition position: FTRefreshPosition?)
    func didInsertPageFromRefreshView(type: FTPageType)
    func toolBarHeight() -> CGFloat
    func toolbarMode() -> FTScreenMode
}

extension Notification.Name {
    static let newPageOptionsHiddenNotification = Notification.Name(rawValue: "FTNewPageOptionsHiddenNotification")
}

let closePageVelocity = 1000.0
let multiplyFactor = 0.30
class FTRefreshViewController: UIViewController {
    var isInReadOnlyMode : Bool = false
    weak var delegate: FTRefreshSelectedItemDelegate?
    weak var scrollView: UIScrollView?
    var scrollDirection: FTRefreshPosition?
    var previousTranslation: CGPoint = .zero
    private var addPageView: FTRefreshPageView?
    private var refreshPageViewHeight: CGFloat = 352
    private var refreshPageViewWidth: CGFloat = 392
    private var currentSize = CGSize.zero
    private var scrollContentSizeListner : NSKeyValueObservation?;
    private var currentOffsetValue: CGFloat {
        if let _scrollView = self.scrollView {
            switch scrollDirection {
            case .left,.right:
                return _scrollView.contentOffset.x
            case .top, .bottom:
                return _scrollView.contentOffset.y
            case .none:
                return 0.0
            }
        }
        return 0.0
    }
    
    //MARK:- System methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollContentSizeListner = self.scrollView?.observe(\.contentSize, changeHandler: { [weak self] (_, _) in
            guard let self = self else { return }
                self.updateFrame();
        });
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateUI()
    }
    
    deinit {
        self.scrollContentSizeListner?.invalidate();
        self.scrollContentSizeListner = nil;
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if addPageView != nil {
            self.addPageView?.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            self.addPageView?.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
            self.addPageView?.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            self.addPageView?.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        }
        let currentFrameSize = self.view.frame.size
        if(currentFrameSize != self.currentSize) {
            self.currentSize = currentFrameSize
            updateUI()
            if self.scrollDirection == .top && self.delegate?.toolbarMode() != .shortCompact {
                addPageView?.activateBottomConstraint(true)
            } else {
                addPageView?.activateBottomConstraint(false)
            }
        }
    }

    //MARK:- Static methods
    static func initialise(with scrollView: UIScrollView, scrollDirection: FTRefreshPosition, delegate: FTRefreshSelectedItemDelegate) -> FTRefreshViewController? {
        let storyBoard = UIStoryboard(name: "FTRefresh", bundle: nil)
        let refreshViewController = storyBoard.instantiateViewController(withIdentifier: "FTRefreshViewController") as! FTRefreshViewController
        refreshViewController.scrollView = scrollView
        refreshViewController.scrollDirection = scrollDirection
        refreshViewController.delegate = delegate
        if let refreshView = refreshViewController.view {
            scrollView.insertSubview(refreshView, at: 0);
        }
        return refreshViewController
    }
    
    func updateUI() {
        refreshPageViewHeight = self.isRegularClass() ? 352 : 276
        refreshPageViewWidth = self.isRegularClass() ? 392 : 344
        if self.scrollDirection == .top {
            refreshPageViewHeight = self.isRegularClass() ? 292 : 276
        }
        if self.scrollDirection == .left {
            addPageView?.swapPositions()
        }
        updateFrame()
    }
    
    @objc class func addObserversForHideNewPageOptions(){
        NotificationCenter.default.post(name: .newPageOptionsHiddenNotification, object: nil)
    }
    
    private func addRefreshPageView() {
        if addPageView == nil {
            self.addPageView = FTRefreshPageView(frame: self.view.frame)
            self.addPageView?.delegate = self
            self.addPageView?.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(addPageView!)
        }
    }
    
    @objc func showNewPageOptions() {
        if !self.isInReadOnlyMode { // enabling/making visible new page creation options for non readonly mode
            addPageView?.isHidden = false
        }
    }
    
    @objc func hideNewPageOptions() {
        addPageView?.isHidden = true
    }
}

extension FTRefreshViewController {
    //MARK:- Handle Gesture
    @objc func handleGesture(_ gestureRecognizer : UIPanGestureRecognizer) {
        guard let _scrollView = scrollView as? FTDocumentScrollView else {
            return;
        }
        let trans = gestureRecognizer.translation(in: _scrollView);
        let velocity = gestureRecognizer.velocity(in: _scrollView);
        switch gestureRecognizer.state {
        case .began: break
        case .changed: break
        case .ended,.cancelled:
            let toolBarHeight = self.delegate?.toolBarHeight() ?? .zero
            if self.scrollDirection == .left {
                let avoidSnapping = trans.x < previousTranslation.x
                previousTranslation = trans
                if (currentOffsetValue < 0.0) {
                    if avoidSnapping {
                        scrollView?.setContentOffset(.zero, animated: true)
                        return
                    }
                    let currentOffset = abs(currentOffsetValue)
                    let threshold = (refreshPageViewWidth * multiplyFactor)
                    if currentOffset > threshold {
                        scrollView?.setContentOffset(CGPoint(x: -refreshPageViewWidth, y: 0), animated: true)
                    } else {
                        scrollView?.setContentOffset(.zero, animated: true)
                    }
                }
            } else if self.scrollDirection == .right {
                let avoidSnapping = trans.x > previousTranslation.x
                previousTranslation = trans
                if currentOffsetValue > 0.0 {
                    let contentSize = _scrollView.contentSize
                    if avoidSnapping {
                        scrollView?.setContentOffset(CGPoint(x: contentSize.width - _scrollView.frame.width, y: 0), animated: true)
                        return
                    }
                    let threshold =  contentSize.width - scrollView!.frame.width + (refreshPageViewWidth * multiplyFactor)
                    if (currentOffsetValue) > threshold {
                        scrollView?.setContentOffset(CGPoint(x: contentSize.width - scrollView!.frame.width + refreshPageViewWidth , y: 0), animated: true)
                    } else {
                        scrollView?.setContentOffset(CGPoint(x: contentSize.width - _scrollView.frame.width, y: 0), animated: true)
                    }
                }
            } else if self.scrollDirection == .top {
                let topOffSet = currentOffsetValue - FTVerticalLayout.firstPageOffsetY
                if (topOffSet < 0.0) {
                    if velocity.y < 0 {
                        return
                    }
                    if abs(topOffSet) > (self.refreshPageViewHeight * 0.4) {
                        UIView.animate(withDuration: 0.5, delay: 0, options: .allowUserInteraction) {[weak self] in
                            guard let self = self else {return}
                            var yOffset = self.refreshPageViewHeight
                            if self.delegate?.toolbarMode() != .shortCompact {
                                yOffset += toolBarHeight
                            }
                            self.scrollView?.setContentOffset(CGPoint(x: _scrollView.contentOffset.x, y: -(yOffset)), animated: true)
                        }
                    }
                }
            } else {
                if self.scrollDirection == .bottom {
                    if currentOffsetValue > 0.0 {
                        let contentSize = _scrollView.contentSize
                        let contentHeight = max(contentSize.height,_scrollView.frame.height);
                        let maxY = contentHeight - _scrollView.frame.height;
                        if(currentOffsetValue > ((contentSize.height - scrollView!.frame.height) + self.refreshPageViewHeight * 0.4)) {
                            if velocity.y > 0 {
                                return
                            }
                            UIView.animate(withDuration: 0.5, delay: 0, options: .allowUserInteraction) { [weak self] in
                                guard let self = self else {return}
                                self.scrollView?.setContentOffset(CGPoint(x: _scrollView.contentOffset.x, y: maxY + self.refreshPageViewHeight), animated: true)
                            }
                        }
                    }
                }
            }
        default:
            break
        }
    }
        
    fileprivate func updateFrame() {
        guard let _scrollView = scrollView else {
            return;
        }
        let floatZero = CGFloat(0)
        let controlPosition = self.scrollDirection;
        var frame: CGRect = .zero
        switch controlPosition {
        case .top:
            frame = CGRect(x: _scrollView.contentOffset.x,
                           y: -refreshPageViewHeight,
                           width: _scrollView.frame.width,
                           height: refreshPageViewHeight)
        case .left:
            frame = CGRect(x: -refreshPageViewWidth,
                           y: floatZero,
                           width: refreshPageViewWidth,
                           height: _scrollView.frame.height)
        case .bottom:
            frame = CGRect(x: _scrollView.contentOffset.x,
                           y: max(_scrollView.contentSize.height, _scrollView.frame.size.height),
                           width: _scrollView.frame.width,
                           height: refreshPageViewHeight)
        case .right:
            let x = max(_scrollView.contentSize.width,(_scrollView.frame.width+_scrollView.contentOffset.x))
            frame = CGRect(x: x,
                           y: floatZero,
                           width: refreshPageViewWidth,
                           height: _scrollView.frame.height);
        default:
            break
        }
        self.view.frame = frame;
        self.addRefreshPageView()
        let width = frame.width
        let height = frame.height
        if scrollDirection == .left || scrollDirection == .right {
            _scrollView.contentInset = UIEdgeInsets(top: 0, left: width, bottom: 0, right: width)
        } else if scrollDirection == .top {
            _scrollView.contentInset = UIEdgeInsets(top: height + FTVerticalLayout.firstPageOffsetY, left: 0, bottom: 0, right: 0)
        } else if scrollDirection == .bottom {
            _scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: height, right: 0)

        }
    }
}

extension FTRefreshViewController: FTRefreshPageDelegate {
    func didTappedItem(item: FTNewPageCreationOption, with sender: UIButton) {
        if item == .pageOptions {
            self.didTapAddPageOption(sender)
        } else {
            self.createPageWithSelectedOption(item, fromAction: true)
        }
    }
    
    private func didTapAddPageOption(_ sender: UIButton) {
        let storyboard = UIStoryboard.init(name: "FTDocumentEntity", bundle: nil)
        guard let pageViewController = storyboard.instantiateViewController(withIdentifier: "FTAddMenuPageViewController") as? FTAddMenuPageViewController else {
            fatalError("Document Entities Viewcontroller not found")
        }
        pageViewController.delegate = self
        pageViewController.dataManager = AddMenuDataManager()
        pageViewController.ftPresentationDelegate.source = sender
        self.ftPresentPopover(vcToPresent: pageViewController, contentSize: CGSize(width: 320, height: 400), hideNavBar: true)
    }
    
    private func createPageWithSelectedOption(_ options: FTNewPageCreationOption, fromAction:Bool) {
        var eventName : String = ""
       
        var item: FTAddMenuItemProtocol
        switch options {
        case .normalPage:
            item = PageMenuItem()
            eventName = "normal_page"
        case .importPhotoPage:
            item = ImportDocumentMenuItem()
            eventName = "import_document_page"
        case .photoPage:
            item = PhotoBackgroundMenuItem()
            eventName = "photo_page"
        case .scanDocumentPage:
            item = ImportScanDocumentMenuItem()
            eventName = "scan_document_page"
        case .templatePage:
            item = PageFromTemplateMenuItem()
            eventName = "template_page"
        case .cameraPage:
            item = CameraMenuItem()
            eventName = "camera_page"
        case .pageOptions:
            item = PageMenuItem()
        }
        self.delegate?.didSelectItem(item, insertPagePosition: self.scrollDirection)
    }
}

extension FTRefreshViewController: FTAddMenuPageViewControllerDelegate {
    func didTapPageItem(_ type: FTPageType) {
        self.delegate?.didInsertPageFromRefreshView(type: type)
    }
}
