//
//  FTFormSheetTransitionDelegate.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 04/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTFormSheetTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FTFormSheetPresentDismissAnimator(isPresenting: false);
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard presented.modalPresentationStyle == .formSheet else {
            fatalError("modalPresentationStyle for presented should be formSheet");
        }
        return FTFormSheetPresentDismissAnimator(isPresenting: true);
    }
}

class FTFormSheetPresentDismissAnimator: NSObject,UIViewControllerAnimatedTransitioning {
    private let isPresentingAnim: Bool;
    
    required init(isPresenting: Bool) {
        isPresentingAnim = isPresenting;
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let presentedControllerKey: UITransitionContextViewControllerKey = isPresentingAnim ? .to : .from;
        
        guard let presentedController = transitionContext.viewController(forKey: presentedControllerKey) else {
            fatalError("view to present missing")
        }
        
        let containerView = transitionContext.containerView;
        var finalFrame = transitionContext.finalFrame(for: presentedController);
        var initialFrame = finalFrame;

        if isPresentingAnim {
            let contentSize = presentedController.preferredContentSize;
            if !containerView.traitCollection.isRegular
                ,contentSize != .zero {
                let frameHeight = contentSize.height + containerView.safeAreaInsets.bottom;
                finalFrame.origin.y = containerView.frame.height - frameHeight;
                finalFrame.size.height = frameHeight;
            }
            initialFrame = finalFrame;
            initialFrame.origin.y = containerView.frame.height;
            presentedController.view.frame = initialFrame;
            if containerView.traitCollection.isRegular {
                presentedController.view.roundCorners(corners: .allCorners , radius: 10);
            }
            else {
                presentedController.view.roundCorners(corners: [.topLeft,.topRight] , radius: 10);
            }
            containerView.addSubview(presentedController.view);
        }
        else {
            presentedController.view.frame = initialFrame;
            finalFrame.origin.y = containerView.frame.height;
        }
        
        UIView.animate(withDuration: self.transitionDuration(using: transitionContext), animations: {
            presentedController.view.frame = finalFrame;
        }, completion: { (finished) in
            if !self.isPresentingAnim {
                presentedController.view.removeFromSuperview();
            }
            transitionContext.completeTransition(finished);
        }) ;
    }
}
