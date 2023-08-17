//
//  FTSlideInDismissAnimator.swift
//  Noteshelf
//
//  Created by Siva on 06/01/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTSlideInDismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    var mode: SlideInType;
    
    init(mode: SlideInType) {
        self.mode = mode;
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3;
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let sourceViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!;
        
        let initialFrame = transitionContext.finalFrame(for: sourceViewController);
        let finalFrame: CGRect;
        
        if let customTransitioningViewController = sourceViewController as? FTSlideInPresentationProtocol  {
            finalFrame = initialFrame;
            customTransitioningViewController.containerTopConstraint.constant = -customTransitioningViewController.containerSuperviewHeightConstraint.constant;
        }
        else {
            switch self.mode {
            case .rightToLeft:
                finalFrame = initialFrame.offsetBy(dx: initialFrame.width, dy: 0);
            case .leftToRight:
                finalFrame = initialFrame.offsetBy(dx: -initialFrame.width, dy: 0);
            case .topToBottom:
                finalFrame = initialFrame.offsetBy(dx: 0, dy: -initialFrame.height);
            case .bottomToTop:
                finalFrame = initialFrame.offsetBy(dx: 0, dy: initialFrame.height);
            case .center:
                finalFrame = CGRect(x: initialFrame.size.width/2, y: initialFrame.size.height/2, width: 0, height: 0)
            }
        }
 
        sourceViewController.view.frame = initialFrame;
        UIView.animate(withDuration: self.transitionDuration(using: transitionContext),
                       delay: 0,
                       options: UIView.AnimationOptions.curveEaseIn,
                       animations: {
            let slideInBackgroundColorViews = transitionContext.containerView.subviews.filter({$0 is FTSlideInBackgroundColorView});
            slideInBackgroundColorViews.forEach({ (slideInBackgroundColorView) in
                slideInBackgroundColorView.backgroundColor = UIColor.black.withAlphaComponent(0);
            });

            sourceViewController.view.frame = finalFrame;
            
            if let customTransitioningViewController = sourceViewController as? FTSlideInPresentationProtocol  {
                customTransitioningViewController.containerView.superview!.layoutIfNeeded();
            }
            
            }, completion: { (finished) in
                transitionContext.completeTransition(finished);
        }) 
    }
}
