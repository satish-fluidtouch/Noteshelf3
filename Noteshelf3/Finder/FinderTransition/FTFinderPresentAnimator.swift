//
//  FTFinderPresentAnimator.swift
//  Noteshelf3
//
//  Created by Sameer on 28/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTFinderPresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private var mode: FTFinderDirection;
    private var presentingStyle: FTFinderPresentationStyle = .interaction;
    
    init(mode: FTFinderDirection, presentingStyle: FTFinderPresentationStyle) {
        self.mode = mode;
        self.presentingStyle = presentingStyle
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return presentingStyle == .interaction ? 0.01 : 0.3
    }
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let destinationViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!;
        
        transitionContext.containerView.addSubview(destinationViewController.view);
        
        let finalFrame = transitionContext.finalFrame(for: destinationViewController);
        let initialFrame: CGRect;
        switch self.mode {
        case .rightToLeft:
            initialFrame = finalFrame.offsetBy(dx: finalFrame.width, dy: 0);
        case .leftToRight:
            initialFrame = finalFrame.offsetBy(dx: -finalFrame.width, dy: 0);
        }
        if self.presentingStyle == .presentWithoutAnimation {
            destinationViewController.view.frame = finalFrame;
            transitionContext.completeTransition(true);
        } else {
            destinationViewController.view.frame = initialFrame;
            UIView.animate(withDuration: self.transitionDuration(using: transitionContext),
                           delay: 0,
                           options: UIView.AnimationOptions.curveEaseOut,
                           animations: {
                            destinationViewController.view.frame = finalFrame;
            }) { (finished) in
                transitionContext.completeTransition(finished);
            };
        }
    }
}
