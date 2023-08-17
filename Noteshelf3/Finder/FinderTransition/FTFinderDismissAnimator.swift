//
//  FTFinderDismissAnimator.swift
//  Noteshelf3
//
//  Created by Sameer on 28/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
class FTFinderDismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private var mode: FTFinderDirection;
    private var presentingStyle: FTFinderPresentationStyle = FTFinderPresentationStyle.interaction;
    
    init(mode: FTFinderDirection, presentingStyle: FTFinderPresentationStyle) {
        self.mode = mode;
        self.presentingStyle = presentingStyle
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        let minValue : Double = 0.05;
        let maxValue : Double = 0.2;

        if let context = transitionContext {
            let destinationViewController = context.viewController(forKey: UITransitionContextViewControllerKey.from)!;
            let initialFrame = context.initialFrame(for: destinationViewController);
            if !initialFrame.isEmpty {
                var finalFrame: CGRect = initialFrame;
                switch self.mode {
                case .rightToLeft:
                    finalFrame.origin.x = context.containerView.frame.width;
                case .leftToRight:
                    finalFrame.origin.x = -initialFrame.width;
                }
                let distanceToTravel = Double(abs(finalFrame.origin.x - initialFrame.origin.x));

                let containerWidth = Double(context.containerView.frame.width);
                var duration = (distanceToTravel*maxValue)/containerWidth;
                if(duration < minValue) {
                    duration = minValue;
                }
                if(duration > maxValue) {
                    duration = maxValue;
                }
                return duration;
            }
        }
        return maxValue;
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let sourceViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!;
        let initialFrame = transitionContext.finalFrame(for: sourceViewController);
        var finalFrame: CGRect = initialFrame;
        
        switch self.mode {
        case .rightToLeft:
            finalFrame.origin.x = transitionContext.containerView.frame.width;
        case .leftToRight:
            finalFrame.origin.x = -initialFrame.width;
        }
 
        sourceViewController.view.frame = initialFrame;
        UIView.animate(withDuration: self.transitionDuration(using: transitionContext),
                       delay: 0,
                       options: UIView.AnimationOptions.curveLinear,
                       animations: {
                        sourceViewController.view.frame = finalFrame;
            }, completion: { (finished) in
                transitionContext.completeTransition(finished);
        })
    }
}
