//
//  FTCustomTransitionDelegate.swift
//  TestAnim
//
//  Created by Amar on 06/02/19.
//  Copyright © 2019 Amar. All rights reserved.
//

import UIKit

let defaultCustomWidth: CGFloat = 300.0

class FTHorizontalTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {

    let presentationStyle: FTHorizontalPresentationStyle
    let direction: FTHorizontalDirection
    let supportsFullScreen: Bool
    init(with style: FTHorizontalPresentationStyle, direction: FTHorizontalDirection, supportsFullScreen: Bool = true) {
        self.presentationStyle = style
        self.direction = direction
        self.supportsFullScreen = supportsFullScreen
        super.init()
    }

    // MARK: - UIViewControllerTransitioningDelegate
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FTHorizontalDismissAnimator.init(mode: self.direction, presentingStyle: self.presentationStyle)
    }
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FTHorizontalPresentAnimator.init(mode: self.direction, presentingStyle: self.presentationStyle)
    }

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let presentedObject = FTHorizontalModalPresentationController(presentedViewController: presented, presenting: presenting)
        presentedObject.modalPresentationStyle = self.presentationStyle
        presentedObject.supportsFullScreen = self.supportsFullScreen
        presentedObject.direction = self.direction
        return presentedObject
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }

}
