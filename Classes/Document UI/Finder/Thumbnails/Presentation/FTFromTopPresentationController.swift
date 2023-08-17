//
//  FTFromTopPresentationController.swift
//  Noteshelf
//
//  Created by Matra on 26/03/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

enum FTAnimationState {
    case up
    case down
}

class FTFromTopPresentationController: UIPresentationController {

    fileprivate var initialHeight: CGFloat = 0.0
    fileprivate let maxVelocity: CGFloat = 1200
    fileprivate var startingY:CGFloat = 0.0
    fileprivate var controlView: UIView?
    
    override func presentationTransitionWillBegin() {
        
        if let presentedController = presentedViewController as? FTSlideInPresentationProtocol {
            initialHeight = presentedController.containerSuperviewHeightConstraint.constant
            startingY = presentedController.containerTopConstraint.constant
            if let superview = presentedController.containerView.superview?.superview {
                superview.layoutIfNeeded()
            }
        }
        setupPanGesture()
        
        if let presentedController = presentedViewController as? FTSlideInPresentationProtocol, presentedController.showHandleBar {
            setupControlButtonView()
        }
    }

    override var overrideTraitCollection: UITraitCollection? {
        get {
            var overrideTraits = super.overrideTraitCollection
            if let overridableController = self.presentedViewController as? FTTraitCollectionOverridable {
                overrideTraits = overridableController.ftOverrideTraitCollection(forWindow: self.presentingViewController.view?.window) ?? super.overrideTraitCollection;
            }
            return overrideTraits
        } set {
            super.overrideTraitCollection = newValue
        }
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed);
        self.updateControlViewFrame();
    }
    
    fileprivate func setupControlButtonView() {
        guard let presentedController = presentedViewController as? FTSlideInPresentationProtocol,
            let contentView = presentedController.containerView else { return }
        
        controlView = UIView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 36, height: 4)))
        controlView?.backgroundColor = UIColor.appColor(.black10)
        controlView?.layer.cornerRadius = 2.5
        controlView?.layer.masksToBounds = true
        contentView.addSubview(controlView!)
        updateControlViewFrame()
    }
    
    fileprivate func resetPresentedState(_ lastState: FTAnimationState) {
        guard let presentedController = self.presentedViewController as? FTSlideInPresentationProtocol, let superView = presentedController.containerView.superview  else { return }
        
        superView.superview?.layoutIfNeeded()
        UIView.animate(withDuration: 0.4,
                       delay: 0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 0.6,
                       options: [.curveEaseInOut, .allowUserInteraction],
                       animations: {
                        if lastState == .up  {
                            presentedController.containerTopConstraint.constant = self.startingY
                        } else {
                            presentedController.containerSuperviewHeightConstraint.constant = self.initialHeight
                        }
                        
                        superView.superview?.layoutIfNeeded()
                        self.updateControlViewFrame()
        }) { (finished) in
            superView.backgroundColor = .clear
        }
    }
    
    fileprivate func setupPanGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan(pan:)));
        if let presentedController = presentedViewController as? FTSlideInPresentationProtocol {
            if let contentHolderView = presentedController.containerView.superview {
                contentHolderView.addGestureRecognizer(panGesture)
            }
        }
    }
    
    @objc
    fileprivate func didPan(pan: UIPanGestureRecognizer) {
        guard let view = pan.view, let superView = view.superview,
            let presentedController = presentedViewController as? FTSlideInPresentationProtocol  else { return }
        
        let translation = pan.translation(in: superView)
        switch pan.state {
        case .changed:
            if translation.y < 0 {
                presentedController.containerTopConstraint.constant = startingY + translation.y
            } else {
                let newHeight = translation.y/3 + initialHeight
                presentedController.containerSuperviewHeightConstraint.constant = newHeight
            }
            updateControlViewFrame()

        case .ended, .cancelled:
            let state: FTAnimationState  = translation.y > 0 ? .down : .up
            let velocity = pan.velocity(in: superView)
            if abs(velocity.y) > maxVelocity  {
                if velocity.y < 0 && abs(translation.y) > 130 {
                    presentedViewController.dismiss(animated: true, completion: nil)
                } else {
                    resetPresentedState(state)
                }
            } else if translation.y < -180 {
                presentedViewController.dismiss(animated: true, completion: nil)
            }
            else {
                resetPresentedState(state)
            }
        default:
            break
        }
    }
    
    func reloadPresentedView() {
        if let presentedController = presentedViewController as? FTSlideInPresentationProtocol {
            initialHeight = presentedController.containerSuperviewHeightConstraint.constant
            startingY = presentedController.containerTopConstraint.constant
            presentedViewController.view.layoutIfNeeded()
            updateControlViewFrame()
        }
    }
    
    fileprivate func updateControlViewFrame() {
        guard let contentView = self.controlView?.superview, let controlview = self.controlView else { return }
        controlview.center = CGPoint(x: contentView.bounds.midX, y: contentView.bounds.maxY-6)
    }
    
}
