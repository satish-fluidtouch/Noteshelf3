//
//  FTChildPresentationController.swift
//  FTCommon
//
//  Created by Narayana on 17/06/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

public protocol FTChildPresentable {
    var ftPresentationDelegate: FTChildPresentation { get }
}

public class FTChildPresentation: NSObject, UIViewControllerTransitioningDelegate {
    public weak var source: AnyObject?
    public var sourceRect: CGRect?

    private weak var presented: UIViewController?
    private weak var sourceVc: UIViewController?

    override public init() {
        super.init()
    }

    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        self.presented = presented
        self.sourceVc = source
        if let sourceView = self.source as? UIView {
            let presentation = FTChildPresentationController(presentedViewController: presented, presenting: presenting)
            presentation.sourceView = sourceView
            presentation.sourceRect = sourceRect ?? sourceView.bounds
            return presentation
        }
        return nil
    }

    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        return nil
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        return nil
    }
}

public class FTChildPresentationController: UIPresentationController {
    var sourceView: UIView?
    var sourceRect: CGRect = .zero
    
    private var touchView: FTTouchView?
    private(set) var isViewPresented = false

    public override var shouldPresentInFullscreen: Bool {
        return false
    }
    public override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        self.touchView?.frame = self.containerView?.frame ?? .zero
    }

    public override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        if nil == self.touchView {
            let _touchView = FTTouchView(frame: .zero)
            self.containerView?.addSubview(_touchView)
            _touchView.backgroundColor  = .clear
            self.touchView = _touchView
            _touchView.delegate = self
        }
        self.containerView?.backgroundColor = .clear
    }

    public override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        self.isViewPresented = true
    }
    
    public override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        self.isViewPresented = false
    }

    public override var frameOfPresentedViewInContainerView: CGRect {
        return sourceRect
    }
}

private class FTTouchView: UIView {
    weak var delegate: FTChildPresentationController?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if event?.type == .hover || nil == event {
            return self
        }
        guard let del = self.delegate else {
            return self
        }
        if del.sourceRect.contains(point) {
            return self
        }
        if  del.presentedView?.frame.contains(point) ?? false {
            return self
        }
        if  del.isViewPresented {
            let presentingVIew = del.presentingViewController
            del.presentedViewController.dismiss(animated: false)
            let convertedPoint = self.convert(point, to: presentingVIew.view)
            return presentingVIew.view.hitTest(convertedPoint, with: event)
        }
        return self
    }
}
