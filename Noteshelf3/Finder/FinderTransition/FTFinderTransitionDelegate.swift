//
//  FTFinderTransitionDelegate.swift
//  Noteshelf3
//
//  Created by Sameer on 28/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTFinderTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    let presentationStyle: FTFinderPresentationStyle
    let direction: FTFinderDirection
    let supportsFullScreen: Bool
    let splitMode: FTFinderMode
    init(with style: FTFinderPresentationStyle, direction: FTFinderDirection, supportsFullScreen: Bool = true, splitMode: FTFinderMode = .sideBySide) {
        self.presentationStyle = style
        self.direction = direction
        self.supportsFullScreen = supportsFullScreen
        self.splitMode = splitMode
        super.init()
    }

    // MARK: - UIViewControllerTransitioningDelegate
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FTFinderDismissAnimator.init(mode: self.direction, presentingStyle: self.presentationStyle)
    }
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FTFinderPresentAnimator.init(mode: self.direction, presentingStyle: self.presentationStyle)
    }

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let presentedObject = FTFinderPresentationController(presentedViewController: presented, presenting: presenting)
        presentedObject.modalPresentationStyle = self.presentationStyle
        presentedObject.supportsFullScreen = self.supportsFullScreen
        presentedObject.direction = self.direction
        presentedObject.mode = self.splitMode
        return presentedObject
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }

}
