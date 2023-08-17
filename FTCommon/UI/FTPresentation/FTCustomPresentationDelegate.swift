//
//  FTCustomPresentationDelegate.swift
//  FTCommon
//
//  Created by Akshay on 12/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

// TODO: (Narayana) - It has been prepared for mac presentation in the view of new notebook kind screens
    // after final design - we may need to update and use or remove this
public class FTCustomPresentationDelegate: NSObject, UIViewControllerTransitioningDelegate {
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        presented.view.layer.cornerRadius = 20.0
        presented.view.layer.borderColor = UIColor.appColor(.black10).cgColor
        presented.view.layer.borderWidth = 1.0
        presented.view.backgroundColor = .clear
        presented.view.addVisualEffectBlur(cornerRadius: 20.0)
        let presentationController = FTCustomPresentationController(presentedViewController: presented, presenting: presenting)
        return presentationController
    }
}

public class FTCustomPresentationController: UIPresentationController {
    private var overlayView: UIVisualEffectView?

    override public func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        let blurEffect = UIBlurEffect(style: .systemMaterial)
        overlayView = UIVisualEffectView(effect: blurEffect)
        overlayView?.frame = containerView?.bounds ?? .zero
        overlayView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView?.insertSubview(overlayView!, at: 0)
        overlayView?.isUserInteractionEnabled = false
    }

    override public var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else {
            return CGRect.zero
        }
        let insetFrame = containerView.bounds.insetBy(dx: 100, dy: 100)
        return insetFrame
    }

    override public func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        presentedView?.frame = frameOfPresentedViewInContainerView
        overlayView?.frame = containerView?.bounds ?? .zero
    }
}
