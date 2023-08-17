//
//  FTInteractiveModalPresentationController.swift
//  TestAnim
//
//  Created by Amar on 06/02/19.
//  Copyright © 2019 Amar. All rights reserved.
//

import UIKit

enum FTModalPresentationStyle {
    case presentationFullScreen
    case presentation
    case interaction
    case overLay
    
    var alpha : CGFloat {
        let alpha: CGFloat;
        switch self {
        case .presentationFullScreen,.presentation, .overLay:
            alpha = fullScreenAlpha;
        case .interaction:
            alpha = initialAlpha;
        }
        return alpha;
    }
}

class FTSafeAreaView: UIView {
    override var safeAreaInsets: UIEdgeInsets {
        var inset = self.window?.safeAreaInsets ?? UIEdgeInsets.zero;
        //To resolve a header top sapcing issue in Settings, when we drag above status bar, we made top Zero.
        inset.top = 0;
        return inset;
    }
}

private enum FTScreenState {
    case initial
    case fullScreen
}

private let maxVelocity: CGFloat = 1200
private let initialAlpha: CGFloat = 0.1
private let fullScreenAlpha: CGFloat = 0.5

class FTInteractiveModalPresentationController: UIPresentationController {

    var modalPresentationStyle: FTModalPresentationStyle = .presentation
    var supportsFullScreen: Bool = true
    var overCurrentContext: Bool = false

    fileprivate var isAnimating = false;
    fileprivate var startY: CGFloat = 0;
    fileprivate var formsheetYOffset: CGFloat {
        guard self.presentedView != nil else {
            return 20;
        }
        let top = self.presentingViewController.view.window?.safeAreaInsets.top ?? 0.0
        if top > 0 {
            return top
        }
        if(self.traitCollection.verticalSizeClass == .compact) {
            return 40;
        }
        return 20;
    };

    fileprivate var presentedState: FTScreenState = .initial
    fileprivate var isSliding: Bool = false;
    fileprivate var controlView: UIView?
    fileprivate var panGesture: UIPanGestureRecognizer?

    override func presentationTransitionWillBegin() {
        guard let container = containerView,
            let coordinator = presentingViewController.transitionCoordinator else { return }
        
        var backgroundColor = UIColor.black.withAlphaComponent( self.modalPresentationStyle.alpha)
        self.updateRoundedCorner();
        self.setupKeyboardObservers()
        if self.modalPresentationStyle == .overLay {
            setupTapGesture()
        }
        if isInCompactMode && self.modalPresentationStyle == .interaction {
            setupControlButtonView()
            setupTapGesture()
            if(self.supportsOnlyFullScreen()) {
                self.presentedState = .fullScreen;
                backgroundColor = UIColor.black.withAlphaComponent(fullScreenAlpha)
            }
        }

        setupPanGesture()

        container.backgroundColor = UIColor.clear;
        self.isAnimating = true;
        coordinator.animate(alongsideTransition: { [weak container] (_) in
            container?.backgroundColor = backgroundColor;
        }) { [weak self] (_) in
            self?.isAnimating = false;
        }
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container);
        guard let presentedView = self.presentedView else {
            return;
        }

        if let navController = container as? UINavigationController,let topController = navController.topViewController {
            let contentSize = topController.preferredContentSize;
            if(contentSize.height > presentedView.frame.height) {
                let delay: TimeInterval = 0.3;
                UIView.animate(withDuration: 0.2,
                               delay: delay,
                               options: .curveLinear,
                               animations: {[weak self] in
                                self?.containerView?.setNeedsLayout();
                                self?.containerView?.layoutIfNeeded();
                }) { (_) in
                    
                }
            }
        }
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let container = containerView else { return .zero }
        var frameToSet = container.bounds;
        startY = self.initialYForState(presentedState);
        if isInCompactMode || self.modalPresentationStyle == .presentationFullScreen {
            let contentHeight = container.bounds.height - startY;
            frameToSet = CGRect(x: 0, y: startY, width: container.bounds.width, height: contentHeight);
        } else {
            let presentedViewControllerSize = self.presentedViewController.preferredContentSize
            var frameXFactor: CGFloat = 0.5
            var reqY = startY
            if self.overCurrentContext {
                frameXFactor = 1.0
                reqY = 0.0
            }
            frameToSet = CGRect(origin: CGPoint(x: (container.bounds.width - presentedViewControllerSize.width) * frameXFactor, y: reqY), size: presentedViewControllerSize)
        }
        return frameToSet;
    }

    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentingViewController.transitionCoordinator else { return }
        self.isAnimating = true;
        coordinator.animate(alongsideTransition: { [weak self] _ -> Void in
            guard let `self` = self else { return }
            self.containerView?.backgroundColor = UIColor.clear;
            }, completion: { [weak self] (_) in
                self?.isAnimating = false;
        })
    }

    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews();
        if(!isSliding && !isAnimating) {
            let newFrame = self.frameOfPresentedViewInContainerView
            self.presentedView?.frame = newFrame;
        }
        guard let presented = self.presentedView else { return }
        var controlY: CGFloat = 12
        if self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.compact {
            controlY -= 5
        }
        controlView?.center = CGPoint(x: presented.center.x, y: controlY)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if nil != previousTraitCollection {
            self.presentedView?.frame = self.frameOfPresentedViewInContainerView;
            self.updateRoundedCorner();
        }
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        removeExtraControlsOnPresentedView()
        coordinator.animate(alongsideTransition: { (_) in
            let localtraitCollection = self.presentingViewController.traitCollection
            if let navigationController = self.presentedViewController as? UINavigationController, !navigationController.viewControllers.isEmpty, let presentable = navigationController.viewControllers[0] as? FTFinderPresentable {
                presentable.detectTraitCollectionDidChange(to: localtraitCollection)
            } else {
                (self.presentedViewController.transitioningDelegate as? FTCustomTransitionDelegate)?.resetPresentation()

            }
        }) { (_) in
        }
    }

    override var overrideTraitCollection: UITraitCollection? {
        set {
            super.overrideTraitCollection = newValue
        } get {
            return nil
        }
    }

}

// MARK: - Private
extension FTInteractiveModalPresentationController {

    fileprivate func changePresentationState(state: FTScreenState) {
        guard let presented = presentedView else { return };
        if(state == .fullScreen) {
            if !self.supportsFullScreen, !self.supportsOnlyFullScreen() {

            } else {
                self.presentedState = state;
            }
        } else {
            self.presentedState = state
        }

        UIView.animate(withDuration: 0.4,
                       delay: 0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 0.6,
                       options: [.curveEaseInOut, .allowUserInteraction, .overrideInheritedOptions],
                       animations: { [weak self] in
                        guard let `self` = self else { return }

                        presented.frame = self.frameOfPresentedViewInContainerView
                        if self.presentedState == .fullScreen {
                            self.containerView?.backgroundColor = UIColor.black.withAlphaComponent(fullScreenAlpha)
                        } else {
                            self.containerView?.backgroundColor = UIColor.black.withAlphaComponent(initialAlpha)
                        }
                        presented.layoutIfNeeded();
                        self.containerView?.layoutIfNeeded();
            },
                       completion: { _ in
                        // self.state = state
        })
    }

    fileprivate var isInCompactMode: Bool {
        if self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.compact || self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.compact {
            return true;
        }
        return false;
    }

    fileprivate func updateRoundedCorner() {
        guard let presented = presentedView else { return }

        if self.isInCompactMode {
            presented.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else {
            presented.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        }
        var cornerRadius: CGFloat = 16.0
        var toMaskToBounds = true

        if overCurrentContext {
            cornerRadius = 0.0
            toMaskToBounds = false
        }
        presented.layer.cornerRadius = cornerRadius
        presented.layer.masksToBounds = toMaskToBounds
    }
    
    fileprivate func removeRoundedCorner() {
        presentedView?.layer.cornerRadius = 0;
        presentedView?.layer.masksToBounds = false
    }

    fileprivate func dimmingAlpha() -> CGFloat {
        guard let presented = presentedView, let container = containerView else { return initialAlpha }
        let visibleHeight = presented.frame.minY;
        var heightToCover = container.frame.height - self.presentedViewController.preferredContentSize.height;
        if(self.supportsOnlyFullScreen()) {
            heightToCover = container.frame.height - formsheetYOffset;
        }
        var alpha = 1 - visibleHeight / heightToCover;

        if(alpha < initialAlpha) {
            alpha = initialAlpha;
        }
        if(alpha > fullScreenAlpha) {
            alpha = fullScreenAlpha;
        }
        return alpha;
    }
}

// MARK: - Add-Ons
extension FTInteractiveModalPresentationController: UIGestureRecognizerDelegate {

    fileprivate func removeExtraControlsOnPresentedView() {
        removeControlButtonView()
        removeRoundedCorner()
    }

    fileprivate func setupControlButtonView() {
        guard let presented = self.presentedView else { return }

        controlView = UIView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 36, height: 4)))
        controlView?.backgroundColor = UIColor.appColor(.black10)
        controlView?.layer.cornerRadius = 2.5
        controlView?.layer.masksToBounds = true
        controlView?.center = CGPoint(x: presented.center.x, y: 12)
        
        /// TODO : commented for - remove grabber in Rack popover in Compact Mode
//        presented.addSubview(controlView!)
    }

    fileprivate func removeControlButtonView() {
        controlView?.removeFromSuperview()
    }

    fileprivate func setupPanGesture() {
        if let pan = self.panGesture {
            presentedView?.removeGestureRecognizer(pan)
            self.panGesture = nil;
        }
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan(pan:)));
        panGesture.delegate = self;
        presentedView?.addGestureRecognizer(panGesture);
        self.panGesture = panGesture
    }

    fileprivate func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(tap:)));
        tapGesture.delegate = self;
        containerView?.addGestureRecognizer(tapGesture);
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {

        guard let presented = presentedView else { return false }
        
        if(self.modalPresentationStyle != .interaction && !isInCompactMode && self.modalPresentationStyle != .overLay) {
            return false;
        }
       
        if gestureRecognizer is UIPanGestureRecognizer {
            let location = touch.location(in: presentedView)
            if location.y > 100 {//TODO: Change Header Height according to the size classes
                return false
            }
            return true
        } else if gestureRecognizer is UITapGestureRecognizer {
            let location = touch.location(in: presentedView)
            let isOutsidePresentedView = !presented.bounds.contains(location)
            return isOutsidePresentedView
        }
        return false
    }

    @objc
    fileprivate func didPan(pan: UIPanGestureRecognizer) {

        guard let view = pan.view, let superView = view.superview,
            let presented = presentedView, let container = containerView else { return }

        let translation = pan.translation(in: superView)
            switch pan.state {
            case .began:
                isSliding = true;
                presentedView?.endEditing(true)
            case .changed:
                var originY = startY
                if translation.y < 0 && !supportsFullScreen {
                    originY += translation.y/3
                } else {
                    originY += translation.y
                }
                let oldOrigin = presented.frame.origin.y;
                presented.frame.origin.y = max(originY, 0);
                if self.modalPresentationStyle != .overLay {
                    presented.frame.size.height += (oldOrigin - presented.frame.origin.y);
                }
                containerView?.backgroundColor = UIColor.black.withAlphaComponent(self.dimmingAlpha());
            case .ended, .cancelled:
                isSliding = false;
                let velocity = pan.velocity(in: superView)

                let isFlicked = abs(velocity.y) > maxVelocity;
                if(isFlicked) {
                    //either up or down;
                    if(velocity.y < 0) {
                        if presentedState == .initial {
                            changePresentationState(state: .fullScreen)
                        }
                    } else {
                        //down
                        let isFlickedDismiss = abs(velocity.y) > 2 * maxVelocity;
                        if (presentedState == .initial) || (isFlickedDismiss && abs(translation.y) < 150 ) || self.supportsOnlyFullScreen() {
                            self.dismiss()
                        } else {
                            changePresentationState(state: .initial)
                        }
                    }
                } else {
                    let dismissThreshold = 0.75 * container.frame.height;
                    var stateChangeThreshold = (presentedState == .initial) ? 0.75 * startY : 0.15 * container.frame.height;
                    if(supportsOnlyFullScreen()) {
                        stateChangeThreshold = dismissThreshold;
                    }

                    if(presented.frame.minY > dismissThreshold) {
                        self.dismiss()
                    } else if(presented.frame.minY > stateChangeThreshold) {
                        changePresentationState(state: .initial)
                    } else if(presented.frame.minY < stateChangeThreshold) {
                        changePresentationState(state: .fullScreen)
                    } else {
                        changePresentationState(state: presentedState);
                    }
                }
            default:
                break
            }
        
    }

    @objc
    fileprivate func didTap(tap: UITapGestureRecognizer) {
        self.dismiss()
    }
    
    private func dismiss() {
        presentedViewController.dismiss(animated: true) { [weak self] in
            guard let self = self else {
                return
            }
            if let navigationController = self.presentedViewController as? UINavigationController, !navigationController.viewControllers.isEmpty, let presentable = navigationController.viewControllers[0] as? FTFinderPresentable {
                presentable.didChangeState(to: .dismiss)
            }
        }
    }

    fileprivate func initialYForState(_ state: FTScreenState) -> CGFloat {
        guard let container = containerView else { return 0 }
        var iniitalY: CGFloat = 0;

        if isInCompactMode {
            switch self.modalPresentationStyle {
            case .interaction:
                if state == .initial {
                    iniitalY = max(container.bounds.height - self.presentedViewController.preferredContentSize.height, formsheetYOffset);
                } else {
                    iniitalY = formsheetYOffset
                }
            case .presentation,.presentationFullScreen, .overLay:
                iniitalY = formsheetYOffset
            }
        } else {
            let presentedViewControllerSize = self.presentedViewController.preferredContentSize
            iniitalY = (container.bounds.height - presentedViewControllerSize.height) * 0.5;
            if(self.modalPresentationStyle == .presentationFullScreen) {
                iniitalY = formsheetYOffset
            }
        }
        return iniitalY
    }

    fileprivate func supportsOnlyFullScreen() -> Bool {
        let startY = self.initialYForState(.initial);
        if(startY == formsheetYOffset) {
            return true;
        }
        return false;
    }
}

// MARK: - Keyboard handling
extension FTInteractiveModalPresentationController {

    fileprivate func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(willShowKeyboard(_:)), name: UIResponder.keyboardWillShowNotification, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(willHideKeyboard(_:)), name: UIResponder.keyboardWillHideNotification, object: nil);
    }

    // MARK: - KeyboardRelated
    @objc
    fileprivate func willShowKeyboard(_ notification: Notification) {
        if self.presentedState == .initial {
            self.changePresentationState(state: .fullScreen)
        }
    }

    @objc
    fileprivate func willHideKeyboard(_ notification: Notification) {

    }
}
