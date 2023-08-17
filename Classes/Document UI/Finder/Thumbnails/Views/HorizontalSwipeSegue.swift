//
//  HorizontalSwipeSegue.swift
//  Noteshelf
//
//  Created by Naidu on 30/01/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class HorizontalSwipeSegue: UIStoryboardSegue {

    // Need to retain self until dismissal because UIKit won't.
    fileprivate var selfRetainer: HorizontalSwipeSegue? = nil

    override func perform() {
        selfRetainer = self
        destination.modalPresentationStyle = .overCurrentContext
        destination.transitioningDelegate = self
        source.present(destination, animated: true, completion: nil)
    }
}

extension HorizontalSwipeSegue: UIViewControllerTransitioningDelegate {
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return Presenter()
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        selfRetainer = nil
        return Dismisser()
    }

    private class Presenter: NSObject, UIViewControllerAnimatedTransitioning {

        func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
            return 0.5
        }

        func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            let container = transitionContext.containerView
            let toView = transitionContext.view(forKey: .to)!
            let toViewController = transitionContext.viewController(forKey: .to)!
            // Configure the layout
            do {
                toView.translatesAutoresizingMaskIntoConstraints = false
                container.addSubview(toView)
                if toViewController.preferredContentSize.width > 0 {
                    toView.widthConst(toViewController.preferredContentSize.width)
                    toView.heightConst(transitionContext.containerView.frame.height)
                }
            }
            do {
                container.layoutIfNeeded()
                let originalOriginX: CGFloat = transitionContext.containerView.frame.width - toViewController.preferredContentSize.width
                toView.frame.origin.x += container.frame.width - toView.frame.minX
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [], animations: {
                    toView.frame.origin.x = originalOriginX
                }) { (completed) in
                    #if DEBUG
                    print(toView)
                    #endif
                    transitionContext.completeTransition(completed)
                }
            }
        }
    }

    private class Dismisser: NSObject, UIViewControllerAnimatedTransitioning {

        func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
            return 0.2
        }

        func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            let container = transitionContext.containerView
            let fromView = transitionContext.view(forKey: .from)!
            UIView.animate(withDuration: 0.2, animations: {
                fromView.frame.origin.x += container.frame.width - fromView.frame.minX
            }) { (completed) in
                transitionContext.completeTransition(completed)
            }
        }
    }
}



