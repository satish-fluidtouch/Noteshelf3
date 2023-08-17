//
//  FTModalScaleUpPresentationController.swift
//  FTNewNotebook
//
//  Created by Amar Udupa on 31/05/23.
//

import Foundation
import UIKit

private class FTModalScaleUpPresentationController : UIPresentationController {
    private var dimmingView: UIView?;
    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController);
        
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect);
        
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
        let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
        blurEffectView.contentView.addSubview(vibrancyView)

        blurEffectView.backgroundColor = UIColor.clear
        blurEffectView.isUserInteractionEnabled = false
        blurEffectView.layer.masksToBounds = true
        dimmingView = blurEffectView;
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        return self.containerView?.bounds ?? super.frameOfPresentedViewInContainerView;
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator);
        let trasnform = self.presentingViewController.view.transform;
        self.presentingViewController.view.transform = .identity;
        coordinator.animate { _ in
            if let containerView = self.containerView {
                self.dimmingView?.frame = containerView.bounds;
            }
            self.presentingViewController.view.transform = trasnform;
        } completion: { _ in
            
        }
    }

    private var resetOnActiveTransform: CGAffineTransform?;
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews();
        if(self.presentingViewController.view.window?.windowScene?.activationState != .foregroundActive) {
            resetOnActiveTransform = self.presentingViewController.view.transform;
            self.presentingViewController.view.transform = .identity;
        }
        else if let transform = resetOnActiveTransform {
            self.presentingViewController.view.transform = transform;
            resetOnActiveTransform = nil;
        }
    }

    override func presentationTransitionWillBegin() {
        guard let containerView = self.containerView else {
            return;
        }
        
        let presentedViewController = self.presentedViewController;

        // Set the dimming view to the size of the container's
        // bounds, and make it transparent initially.
        self.dimmingView?.frame = containerView.bounds;
        self.dimmingView?.alpha = 0;
        
        // Insert the dimming view below everything else.
        if let dimView = self.dimmingView {
            containerView.insertSubview(dimView, at: 0)
        }
        
        // Set up the animations for fading in the dimming view.
        if let transitionCoordinator = presentedViewController .transitionCoordinator {
            transitionCoordinator.animate { context in
                if(!context.isAnimated) {
                    let fromController = context.viewController(forKey: .from);
                    let toController = context.viewController(forKey: .to);
                    
                    fromController?.view.transform = FTScaleTransitionMode.big.transform;
                    toController?.view.transform = FTScaleTransitionMode.normal.transform;
                }
                self.dimmingView?.alpha = 1.0;
            }
        }
        else {
            self.dimmingView?.alpha = 1;
        }
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool) {
        if (!completed) {
            self.dimmingView?.removeFromSuperview();
        }
    }
    
    override func dismissalTransitionWillBegin() {
        self.presentingViewController.isAppearingThroughModelScale()
        // Fade the dimming view back out.
        if let transitionCoordinator = self.presentedViewController.transitionCoordinator {
            transitionCoordinator.animate { context in
                if(!context.isAnimated) {
                    let fromController = context.viewController(forKey: .from);
                    let toController = context.viewController(forKey: .to);
                    
                    fromController?.view.transform = FTScaleTransitionMode.normal.transform;
                    toController?.view.transform = FTScaleTransitionMode.normal.transform;
                }
                self.dimmingView?.alpha = 0;
            }
        }
        else {
            self.dimmingView?.alpha = 0;
        }
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if (!completed) {
            self.dimmingView?.removeFromSuperview();
        }
    }
}

public class FTModalScaleTransitionDelegate: NSObject,UIViewControllerTransitioningDelegate {
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let controller = FTModalScaleUpPresentationController.init(presentedViewController: presented, presenting: presenting);
        return controller;
    }
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FTScaleAnimationTransition(isPresenting: true);
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FTScaleAnimationTransition(isPresenting: false);
    }
}

private class FTScaleAnimationTransition : NSObject,UIViewControllerAnimatedTransitioning {
    var isPresenting = false;
    init(isPresenting present: Bool) {
        super.init();
        isPresenting = present;
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4;
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // 1
        let key: UITransitionContextViewControllerKey = isPresenting ? .to : .from;
        
        guard let controller = transitionContext.viewController(forKey: key) else { return }
        
        let fromKey: UITransitionContextViewControllerKey = isPresenting ? .from : .to;
        guard let fromController = transitionContext.viewController(forKey: fromKey) else { return }

        // 2
        if(isPresenting) {
            transitionContext.containerView.addSubview(controller.view)
        }
        
        // 3
        let presentedFrame = transitionContext.finalFrame(for: controller)
        controller.view.frame = presentedFrame

        // 4
        let controllViewTransform : [FTScaleTransitionMode] = isPresenting ? [.small,.normal] : [.normal,.small];
        let fromViewTrasnform : [FTScaleTransitionMode] = isPresenting ? [.normal,.big] : [.big,.normal];

        // 5
        let animationDuration = transitionDuration(using: transitionContext)
        
        controller.view.transform = controllViewTransform[0].transform;
        fromController.view.transform = fromViewTrasnform[0].transform;
        
        let initalAlpha: CGFloat = isPresenting ? 0 : 1;
        let finalAlpha: CGFloat = isPresenting ? 1 : 0;

        controller.view.alpha = initalAlpha;

        UIView.animate(withDuration: animationDuration,
                       delay: 0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 10,
                       animations: {
            controller.view.alpha = finalAlpha;
            controller.view.transform = controllViewTransform[1].transform;
            fromController.view.transform = fromViewTrasnform[1].transform;
        }) { finished in
            if !self.isPresenting {
                controller.view.removeFromSuperview()
            }
            transitionContext.completeTransition(finished)
        };
    }
}

private enum FTScaleTransitionMode {
    case small, normal, big;
    
    var transform: CGAffineTransform {
        switch self {
        case .small:
            return CGAffineTransformMakeScale(0.7, 0.7);
        case .normal:
            return CGAffineTransform.identity;
        case .big:
            return CGAffineTransformMakeScale(1.3, 1.3);
        }
    }
    
}


 extension UIViewController {
   @objc open func isAppearingThroughModelScale() {

    }
}
