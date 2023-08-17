//
//  FTSlideInPresentAnimator.swift
//  Noteshelf
//
//  Created by Siva on 05/01/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTSlideInBackgroundColorView: UIView {
    override func awakeFromNib() {
        super.awakeFromNib()
        self.isUserInteractionEnabled = false;
    }
}

protocol FTSlideInPresentationProtocol {
    var containerView: UIView! {get};
    var containerTopConstraint: NSLayoutConstraint! {get};
    var containerViewWidthConstraint: NSLayoutConstraint! {get};
    var containerSuperviewTopConstraint: NSLayoutConstraint! {get};
    var containerSuperviewHeightConstraint: NSLayoutConstraint! {get};
    var showHandleBar: Bool {get};
}

extension FTSlideInPresentationProtocol {
    var showHandleBar: Bool {
        return true
    }
}

class FTSlideInPresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    var mode: SlideInType;
    
    init(mode: SlideInType) {
        self.mode = mode;
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3;
    }
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let destinationViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!;
        
        transitionContext.containerView.addSubview(destinationViewController.view);
        
        let finalFrame = transitionContext.finalFrame(for: destinationViewController);
        let initialFrame: CGRect;
        
        let backgroundColorY: CGFloat;
        if let customTransitioningViewController = destinationViewController as? FTSlideInPresentationProtocol  {
            destinationViewController.view.layoutIfNeeded();
            initialFrame = finalFrame;
            customTransitioningViewController.containerTopConstraint.constant = -customTransitioningViewController.containerSuperviewHeightConstraint.constant;
            customTransitioningViewController.containerView.superview!.layoutIfNeeded();
            customTransitioningViewController.containerTopConstraint.constant = 0;
            backgroundColorY = customTransitioningViewController.containerSuperviewTopConstraint.constant;
        }
        else {
            backgroundColorY = 0;
            switch self.mode {
            case .rightToLeft:
                initialFrame = finalFrame.offsetBy(dx: finalFrame.width, dy: 0);
            case .leftToRight:
                initialFrame = finalFrame.offsetBy(dx: -finalFrame.width, dy: 0);
            case .topToBottom:
                initialFrame = finalFrame.offsetBy(dx: 0, dy: -finalFrame.height);
            case .bottomToTop:
                initialFrame = finalFrame.offsetBy(dx: 0, dy: finalFrame.height);
            case .center:
                initialFrame = CGRect(x: finalFrame.size.width/2, y: finalFrame.size.height/2, width: 0, height: 0)
            }
            
        }
        
        //Background
        let backgroundColorView = FTSlideInBackgroundColorView(frame: transitionContext.containerView.bounds);
        backgroundColorView.backgroundColor = UIColor.black.withAlphaComponent(0.0);
        transitionContext.containerView.insertSubview(backgroundColorView, at: 0);
        backgroundColorView.translatesAutoresizingMaskIntoConstraints = false
        transitionContext.containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[subview]-0-|", options: NSLayoutConstraint.FormatOptions.alignAllTop, metrics: nil, views: ["subview" : backgroundColorView]));
        transitionContext.containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(topMargin)-[subview]-0-|", options: NSLayoutConstraint.FormatOptions.alignAllTop, metrics: ["topMargin" : backgroundColorY], views: ["subview" : backgroundColorView]));

        
        destinationViewController.view.frame = initialFrame;
        UIView.animate(withDuration: self.transitionDuration(using: transitionContext),
                       delay: 0,
                       options: UIView.AnimationOptions.curveEaseOut,
                       animations: {
            backgroundColorView.backgroundColor = UIColor.black.withAlphaComponent(0.2);
            destinationViewController.view.frame = finalFrame;
            
            if let customTransitioningViewController = destinationViewController as? FTSlideInPresentationProtocol  {
                customTransitioningViewController.containerView.superview?.layoutIfNeeded();
            }
            
        }) { (finished) in
            transitionContext.completeTransition(finished);
        };
    }
}
