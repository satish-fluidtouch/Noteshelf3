//
//  FTCustomTransitionDelegate.swift
//  TestAnim
//
//  Created by Amar on 06/02/19.
//  Copyright © 2019 Amar. All rights reserved.
//

import UIKit
import FTCommon

let defaultCustomHeight: CGFloat = 300.0

class FTCustomTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {

    let presentationStyle: FTModalPresentationStyle
    let supportsFullScreen: Bool
    let overCurrentContext: Bool

    weak var sourceView : UIView?
    var permittedArrowDirections: UIPopoverArrowDirection?
    var isDismissDisable = false
    private var shouldStartWithFullScreen = false
    private weak var presented : UIViewController?
    private weak var source : UIViewController?
    public var onDismissBlock : (() -> Void)?;


    init(with style: FTModalPresentationStyle, supportsFullScreen: Bool = true, shouldStartWithFullScreen: Bool = false, overCurrentContext: Bool = false) {
        self.presentationStyle = style
        self.supportsFullScreen = supportsFullScreen
        self.shouldStartWithFullScreen = shouldStartWithFullScreen
        self.overCurrentContext = overCurrentContext
        super.init()
    }

    // MARK: - UIViewControllerTransitioningDelegate
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FTFormSheetDismissAnimation();
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FTFormSheetPresentAnimation(shouldStartWithFullScreen: shouldStartWithFullScreen);
    }

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        self.presented = presented
        self.source = source

        if sourceView == nil, self.presentationStyle == .interaction {
           // fatalError("Source View is nil for interactive presentation")
        }

        var isRegular = source.isRegularClass()
        if source.splitViewController != nil {
            isRegular = source.splitViewController?.isRegularClass() ?? false
        }
        if let sourceView = sourceView, isRegular {
            let presentation = FTPopoverPresentationController(presentedViewController: presented, presenting: presenting)
            presentation.sourceView = sourceView
            presentation.sourceRect = sourceView.bounds
            presentation.overrideTraitCollection = source.traitCollection
            presentation.permittedArrowDirections = permittedArrowDirections ?? .any
            presentation.delegate = self;
            return presentation
        } else {
            let presentation = FTInteractiveModalPresentationController(presentedViewController: presented, presenting: presenting)
            presentation.modalPresentationStyle = self.presentationStyle
            presentation.supportsFullScreen = self.supportsFullScreen
            presentation.overCurrentContext = self.overCurrentContext
            presentation.overrideTraitCollection = source.traitCollection
            return presentation
        }
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }

    func resetPresentation() {
        if sourceView != nil {
            //In order to dismiss any other controllers on top of this Custom Presentations.
            func dismissAndPresent(){
                presented?.dismiss(animated: false, completion: {
                    if let toBePresented = self.presented {
                        self.source?.present(toBePresented, animated: false, completion: nil)
                    }
                })
            }
            if presented?.presentedViewController != nil {
                presented?.dismiss(animated: false, completion: {
                    dismissAndPresent()
                })
            }
            else{
                dismissAndPresent()
            }
        }
    }
}

extension FTCustomTransitionDelegate : UIPopoverPresentationControllerDelegate
{
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
          // to prevent animation, we need to dismiss it manuallly with animated: false
//          presentationController.presentingViewController.dismiss(animated: false, completion: nil)
        if isDismissDisable {
            return false
        }
          return true
      }

}

fileprivate class FTFormSheetPresentAnimation : NSObject,UIViewControllerAnimatedTransitioning
{
    var shouldStartWithFullScreen = false
    init(shouldStartWithFullScreen: Bool) {
        self.shouldStartWithFullScreen = shouldStartWithFullScreen;
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        let minValue : Double = 0.3;
        let maxValue : Double = 0.5;
        
        if let context = transitionContext {
            let destinationViewController = context.viewController(forKey: UITransitionContextViewControllerKey.to)!;
            let finalFrame = context.finalFrame(for: destinationViewController);
            if !finalFrame.isEmpty {
                let initialFrame: CGRect = finalFrame.offsetBy(dx: 0, dy: finalFrame.height);
                let containerHeight = Double(context.containerView.frame.height);
                let distanceToTravel = Double((initialFrame.origin.y - finalFrame.origin.y));
                
                var duration = (distanceToTravel*maxValue)/containerHeight;
                if(duration < minValue) {
                    duration = minValue;
                }
                if(duration > maxValue) {
                    duration = maxValue;
                }
                return duration;
            }
        }
        return minValue;
    }
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let destinationViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!;
        
        transitionContext.containerView.addSubview(destinationViewController.view);
        
        let finalFrame = transitionContext.finalFrame(for: destinationViewController);
        var initialFrame: CGRect = finalFrame;
        initialFrame.origin.y = transitionContext.containerView.frame.height;
        
        destinationViewController.view.frame = initialFrame;
        if shouldStartWithFullScreen {
            destinationViewController.view.frame = finalFrame;
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled);
            return
        }
        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0,
                       usingSpringWithDamping: 1,
                       initialSpringVelocity: 1,
                       options: [.curveEaseOut,.allowUserInteraction],
                       animations: {
                        destinationViewController.view.frame = finalFrame;
        }) { (finished) in
        };
        transitionContext.completeTransition(!transitionContext.transitionWasCancelled);
    }
}

fileprivate class FTFormSheetDismissAnimation : NSObject,UIViewControllerAnimatedTransitioning
{
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        let minValue : Double = 0.05;
        let maxValue : Double = 0.2;
        
        if let context = transitionContext {
            let destinationViewController = context.viewController(forKey: UITransitionContextViewControllerKey.from)!;
            let initialFrame = context.initialFrame(for: destinationViewController);
            if !initialFrame.isEmpty {
                var finalFrame: CGRect = initialFrame;
                finalFrame.origin.y = context.containerView.frame.height;

                let containerHeight = Double(context.containerView.frame.height);
                let distanceToTravel = Double((finalFrame.origin.y - initialFrame.origin.y));
                
                var duration = (distanceToTravel*maxValue)/containerHeight;
                if(duration < minValue) {
                    duration = minValue;
                }
                if(duration > maxValue) {
                    duration = maxValue;
                }
                return duration;
            }
        }
        return minValue;
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let destinationViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!;
        
        transitionContext.containerView.addSubview(destinationViewController.view);
        
        var finalFrame = transitionContext.finalFrame(for: destinationViewController);
        finalFrame.origin.y = transitionContext.containerView.frame.height;

        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0,
                       options: [.curveLinear,.allowUserInteraction],
                       animations: {
                        destinationViewController.view.frame = finalFrame;
        }) { (finished) in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled);
        };
    }
}
