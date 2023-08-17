//
//  FTHorizontalPresentAnimator.swift
//  Noteshelf
//
//  Created by Siva on 05/01/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

enum FTHorizontalDirection {
    case leftToRight
    case rightToLeft
}
class FTHorizontalPresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private var mode: FTHorizontalDirection;
    private var presentingStyle: FTHorizontalPresentationStyle = FTHorizontalPresentationStyle.interaction;
    
    init(mode: FTHorizontalDirection, presentingStyle: FTHorizontalPresentationStyle) {
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
