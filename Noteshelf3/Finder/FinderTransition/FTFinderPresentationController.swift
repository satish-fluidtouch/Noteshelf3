//
//  FTFinderPresentationController.swift
//  Noteshelf3
//
//  Created by Sameer on 28/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

private let maxVelocity: CGFloat = 1200
private let initialAlpha: CGFloat = 0.1
private let fullScreenAlpha: CGFloat = 0.5
private let draggableWidth: CGFloat = 50

//TODO: Right now leftToRight direction panels will not support fullScreen mode, rightToLeft mode always supports fullScreen mode.
class FTFinderPresentationController: UIPresentationController {
    var direction: FTFinderDirection = .rightToLeft
    var mode: FTFinderMode = .sideBySide
    var modalPresentationStyle: FTFinderPresentationStyle = .interaction
    var supportsFullScreen: Bool = true
    fileprivate var preferredSize: CGSize = CGSize.zero
    
    fileprivate var currentSize = CGSize.zero;
    fileprivate var startX: CGFloat = -1;
    fileprivate var formsheetXOffset: CGFloat {
        return 0;
    };

    fileprivate var presentedState: FTFinderScreenState = .dragging
    fileprivate var isSliding: Bool = false;
    fileprivate var controlView: UIView?
    fileprivate let offSet: CGFloat = 280
    override func presentationTransitionWillBegin() {
        guard let container = containerView,
            let coordinator = presentingViewController.transitionCoordinator else { return }
        container.backgroundColor = UIColor.clear
        self.preferredSize = self.presentedViewController.preferredContentSize
        
        var backgroundColor = UIColor.clear;
        if(self.modalPresentationStyle == .defaultAnimation) {
            backgroundColor = UIColor.black.withAlphaComponent(initialAlpha);
            if self.shouldStartWithFullScreen() {
                coordinator.animate(alongsideTransition: { (_) in
                    container.backgroundColor = backgroundColor;
                })
                return
            }
        }
        self.presentedState = .initial
        coordinator.animate(alongsideTransition: { (_) in
            container.backgroundColor = backgroundColor;
        }) {[weak self] (_) in
            self?.presentedState = .dragging
            self?.endScreenState(to: .fullScreen)
        }
    }
    func handleTraitCollectionChanges(){
        //TODO: Observe trait collection changes here and handle
        DispatchQueue.main.async {
            self.changePresentationState(state: self.presentedState)
        }
    }
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let container = containerView else { return .zero }
        var frameToSet = container.bounds;
        startX = self.initialXForState(presentedState)
        var contentWidth = (presentedState == .initial) ? 280 : container.bounds.width
        if presentedState == .initial, self.shouldStartWithFullScreen() {
            contentWidth = 0
        }
        frameToSet = CGRect(x: startX, y: 0, width: contentWidth, height: container.bounds.height);
        return frameToSet;
    }
    
    private var prevTraitcollection : UITraitCollection?

    override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed);
        let localtraitCollection = self.presentingViewController.traitCollection;
        self.prevTraitcollection = localtraitCollection;
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        coordinator.animate(alongsideTransition: { (_) in
            self.detectTraitCollectionChange();
        }) { (_) in
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self](_) in
            self?.detectTraitCollectionChange();
        }, completion: { [weak self](_) in
          
        });
    }

    private func detectTraitCollectionChange() {
        let localtraitCollection = self.presentingViewController.traitCollection;
        if self.prevTraitcollection?.isRegular != localtraitCollection.isRegular {
            if let presentable = self.presentableViewController() {
                presentable.detectTraitCollectionDidChange(to: localtraitCollection)
            }
            self.prevTraitcollection = localtraitCollection;
        }
    }
    
    private func presentableViewController() -> FTFinderPresentable? {
        if let navigationController = self.presentedViewController as? UINavigationController, !navigationController.viewControllers.isEmpty {
            if let presentable = navigationController.viewControllers[0] as? FTFinderPresentable {
                return presentable
            }
        }
        return nil
    }
    
    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentingViewController.transitionCoordinator else { return }
        coordinator.animate(alongsideTransition: { [weak self] context -> Void in
            guard let `self` = self else { return }
            self.containerView?.backgroundColor = UIColor.clear
            }, completion: { _ in
        })
    }

    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews();
        self.setDragIndicatorPosition()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if nil != previousTraitCollection {
            self.presentedView?.frame = self.frameOfPresentedViewInContainerView;
            self.updateRoundedCorner();
        }
    }
    
    func endScreenStateToInitial(to state: FTFinderScreenState) {
        endScreenState(to: .initial)
    }
    
    fileprivate var isInCompactMode: Bool {
        if self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.compact || self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.compact {
            return true;
        }
        return false;
    }
}

// MARK: - Private
extension FTFinderPresentationController {

    fileprivate func changePresentationState(state: FTFinderScreenState, animate: Bool = true) {
        guard let presented = presentedView else { return };
        if(state == .fullScreen) {
            if !self.supportsFullScreen {

            } else {
                self.presentedState = state;
            }
        } else {
            self.presentedState = state
        }
        if !animate {
            presented.frame = self.frameOfPresentedViewInContainerView
            presented.layoutIfNeeded()
        } else {
            UIView.animate(withDuration: 0.3,
                           delay: 0,
                           usingSpringWithDamping: 1.0,
                           initialSpringVelocity: 0.6,
                           options: [.curveEaseInOut, .allowUserInteraction, .overrideInheritedOptions],
                           animations: { [weak self] in
                guard let `self` = self else { return }
                presented.frame = self.frameOfPresentedViewInContainerView
                presented.layoutIfNeeded()
                if let presentable =  self.presentableViewController() {
                    presentable.didChangeState(to: .dragging)
                }
                self.containerView?.backgroundColor = UIColor.black.withAlphaComponent(self.dimmingAlpha())
            }, completion: { isFinished in
                if let presentable = self.presentableViewController() {
                    presentable.didChangeState(to: state)
                }
            })
        }
       
    }

    fileprivate func setupControlButtonView() {
        guard let presented = self.presentedView else { return }

        controlView = UIView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 4, height: 36)))
        controlView?.backgroundColor = UIColor.appColor(.black10)
        controlView?.layer.cornerRadius = 2.5
        controlView?.layer.masksToBounds = true
        presented.addSubview(controlView!)
        
        self.setDragIndicatorPosition()
    }
    fileprivate func setDragIndicatorPosition(){
        if !supportsFullScreen {
            controlView?.isHidden = true
            return
        }
        guard let presented = self.presentedView else { return }
        let controlX: CGFloat = 8 + 2// 2 = indicator width/2
        controlView?.center = CGPoint(x: controlX, y: presented.center.y)
        if(self.direction == .leftToRight){
            controlView?.center = CGPoint(x: presented.frame.width - controlX, y: presented.center.y)
        }
    }
    
    fileprivate func updateRoundedCorner() {
//        guard let presented = presentedView else { return }
//        presented.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
//        presented.layer.cornerRadius = 16;
//        presented.layer.masksToBounds = true
    }

    fileprivate func dimmingAlpha() -> CGFloat {
        guard let presented = presentedView, let container = containerView else { return initialAlpha }
        let visibleWidth = (self.direction == .leftToRight) ? presented.frame.maxX : presented.frame.minX;
        if(visibleWidth == 0){
            return initialAlpha
        }
        let widthToCover = (self.direction == .leftToRight) ? self.preferredSize.width : container.frame.width - self.preferredSize.width;
        let initialAlphaToConsider = (self.presentedState == .dragging) ? 0 : initialAlpha;
        let fullScreenAlphaToConsider = self.supportsFullScreen ? fullScreenAlpha : initialAlpha;
        var alpha = 1 - visibleWidth / widthToCover;
       
        if(self.direction == .leftToRight) {
            //alpha = (visibleWidth * fullScreenAlphaToConsider)/widthToCover;
        }
        
        if(alpha < initialAlphaToConsider) {
            alpha = initialAlphaToConsider;
        }
        
        if(alpha > fullScreenAlphaToConsider) {
            alpha = fullScreenAlphaToConsider;
        }
        if(self.presentedState != .dragging && !self.supportsFullScreen) {
            alpha = initialAlphaToConsider;
        }
        return 0;
    }
}

// MARK: - Gesture Recognizer
extension FTFinderPresentationController: UIGestureRecognizerDelegate {

    fileprivate func setupPanGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan(pan:)));
        panGesture.delegate = self;
        presentedViewController.view.addGestureRecognizer(panGesture);
    }

    fileprivate func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(tap:)));
        tapGesture.delegate = self;
        containerView?.addGestureRecognizer(tapGesture);
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if shouldIgnoreUserInteraction{
            return false
        }
        guard let presented = presentedView else { return false }
        if gestureRecognizer is UIPanGestureRecognizer {
            let location = touch.location(in: presentedView)
            if(self.direction == .leftToRight){
                if location.x < presented.frame.width - draggableWidth {
                    return false
                }
            }
            else{
                if location.x > draggableWidth {
                    return false
                }
            }
            return true
        } else if gestureRecognizer is UITapGestureRecognizer {
            let location = touch.location(in: presentedView)
            let isOutsidePresentedView = !presented.bounds.contains(location)
            return isOutsidePresentedView
        }
        return false
    }
    
    @objc func sendGesture(_ gesture: UIPanGestureRecognizer){
        self.didPan(pan: gesture)
    }
    
    @objc fileprivate func didPan(pan: UIPanGestureRecognizer) {
        guard let view = pan.view, let superView = view.superview,
            let presented = presentedView, let container = containerView else {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.1) {[weak self] in // To handle when fast swipe and release immediately from screen edge
                    if let weakSelf = self, weakSelf.isSliding == false{
                        weakSelf.changePresentationState(state: .initial)
                    }
                }
            return
        }

        let translation = pan.translation(in: superView)

        switch pan.state {
        case .began:
            self.isSliding = true;
            presented.frame.size.height = container.frame.height
            presentedView?.endEditing(true)
        case .changed:
            if self.isSliding == false{
              self.isSliding = true;
            }
            if let navigationController = self.presentedViewController as? UINavigationController, !navigationController.viewControllers.isEmpty {
                var prentable: FTFinderPresentable? = navigationController.viewControllers[0] as? FTFinderPresentable
                prentable?.isResizing = true
            }
            let originX = translation.x + startX
            if(self.direction == .leftToRight){
                presented.frame.origin.x = 0
//                presented.frame.size.width = self.preferredSize.width
                presented.frame.size.width = max(self.preferredSize.width, self.preferredSize.width + translation.x + startX)
            }
            else{
                presented.frame.origin.x = max(originX, 0);
                presented.frame.size.width = max(self.preferredSize.width, container.bounds.width - presented.frame.origin.x)
            }
            containerView?.backgroundColor = UIColor.black.withAlphaComponent(self.dimmingAlpha());

        case .ended, .cancelled:
            isSliding = false;
            if let navigationController = self.presentedViewController as? UINavigationController, !navigationController.viewControllers.isEmpty {
                var prentable: FTFinderPresentable? = navigationController.viewControllers[0] as? FTFinderPresentable
                prentable?.isResizing = false
            }

            startX = translation.x + startX
            let velocity = pan.velocity(in: superView)
            containerView?.backgroundColor = UIColor.black.withAlphaComponent(self.dimmingAlpha());
            
            let isFlicked = abs(velocity.x) > maxVelocity;
            if(isFlicked) {
                //either left or right;
                if(self.direction == .rightToLeft){
                    if(velocity.x < 0) {
                        if presentedState == .dragging {
                            endScreenState(to: .initial)
                        }
                        else if presentedState == .initial {
                            endScreenState(to: .fullScreen)
                        }
                    } else {
                        //right
                        let isFlickedDismiss = abs(velocity.x) > 2 * maxVelocity;
                        if (presentedState == .initial) || (isFlickedDismiss && abs(translation.x) < 150 ) {
                            presentedViewController.dismiss(animated: true, completion: nil)
                        } else {
                            endScreenState(to: .initial)
                        }
                    }
                }
                else if(self.direction == .leftToRight){
                    if(velocity.x > 0) {
                        if presentedState == .dragging {
                            endScreenState(to: .initial)
                        }
                        else if presentedState == .initial {
                            endScreenState(to: .fullScreen)
                        }
                    } else {
                        //right
                        let isFlickedDismiss = abs(velocity.x) > 2 * maxVelocity;
                        if (presentedState == .initial) || (isFlickedDismiss && abs(translation.x) < 150 ){
                            presentedViewController.dismiss(animated: true, completion: nil)
                        } else {
                            endScreenState(to: .initial)
                        }
                    }
                }
            } else {
                let minimumRequiredWidth: CGFloat = 100.0;
                var presentedViewWidth = container.frame.width - presented.frame.minX
                if(self.direction == .leftToRight){
                    presentedViewWidth = presented.frame.width + presented.frame.origin.x
                }
                let initialStateWidth: CGFloat = self.preferredSize.width;
                if(presentedViewWidth < minimumRequiredWidth) {
                    if self.presentedState == .dragging{
                        endScreenState(to: .initial)
                    }
                    else {
                        presentedViewController.dismiss(animated: true, completion: nil)
                    }
                }
                else if(initialStateWidth >= presentedViewWidth) {
                    endScreenState(to: .initial)
                }
                else if(initialStateWidth < presentedViewWidth) {
                    if presentedViewWidth > container.frame.width / 2.0{
                        endScreenState(to: .fullScreen)
                    }
                    else{
                        endScreenState(to: .initial)
                    }
                }
            }
        default:
            break
        }
    }
    
    fileprivate func endScreenState(to state: FTFinderScreenState, animate: Bool = true){
        self.changePresentationState(state: state, animate: animate)
    }
    
    @objc
    fileprivate func didTap(tap: UITapGestureRecognizer) {
        presentedViewController.dismiss(animated: true, completion: nil)
    }

    fileprivate func initialXForState(_ state: FTFinderScreenState) -> CGFloat {
        guard containerView != nil else { return 0 }
        var initialX: CGFloat = 0;
        if state == .initial {
            if mode == .primaryOverlay || mode == .twoBesideSecondary {
                initialX = offSet
            } else if self.shouldStartWithFullScreen() {
                initialX = 0
            }
        }
        return initialX
    }
    
    private func shouldStartWithFullScreen() -> Bool {
        var shouldStartWithFullScreen = false
        if let navigationController = self.presentedViewController as? UINavigationController, !navigationController.viewControllers.isEmpty {
            let presentable: FTFinderPresentable? = navigationController.viewControllers[0] as? FTFinderPresentable
            shouldStartWithFullScreen = presentable?.shouldStartWithFullScreen() ?? false
        }
        return shouldStartWithFullScreen
    }

    private var shouldIgnoreUserInteraction: Bool {
        if let childrenControllers = (presentedViewController as? UINavigationController)?.visibleViewController?.children {
            if childrenControllers.count > 0 && childrenControllers.last is FTLoadingIndicatorViewController { //To handle unexpected dismissing when export is in progress
                return true
            }
        }
        return false
    }
}

