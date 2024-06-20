//
//  FTPopoverPresentationViewController.swift
//  FTPresentation
//
//  Created by Narayana on 05/05/23.
//

import UIKit

public class FTPopoverPresentationController: UIPopoverPresentationController {
    private var prevTraitcollection : UITraitCollection?
    public var onDismissBlock : (() -> Void)?;

    public override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        let localtraitCollection = self.presentingViewController.traitCollection
        self.prevTraitcollection = localtraitCollection;
    }

    public override func dismissalTransitionWillBegin() {
        self.onDismissBlock?()
        super.dismissalTransitionWillBegin()
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        let isTemplatePresented = false
        coordinator.animate(alongsideTransition: { [weak self](_) in
            if(!isTemplatePresented) {
                self?.detectTraitCollectionChange()
            }
        }, completion: { [weak self](_) in
            if(isTemplatePresented) {
                self?.detectTraitCollectionChange()
            }
        })
    }

    private func detectTraitCollectionChange() {
        let localtraitCollection = self.presentingViewController.traitCollection
        if self.prevTraitcollection?.isRegular != localtraitCollection.isRegular {
            self.prevTraitcollection = localtraitCollection
            (self.presentedViewController.transitioningDelegate as? FTPopoverPresentation)?.resetPresentation()
        } else if !(self.prevTraitcollection?.isRegular ?? true) && self.presentingViewController.view.frame.width <= popOverThresholdWidth {
            (self.presentedViewController.transitioningDelegate as? FTPopoverPresentation)?.resetPresentation()
        }
    }

    public override func adaptivePresentationStyle(for traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        self.overrideTraitCollection = traitCollection
        return .none
    }
}

class FTSheetPresentationController: UISheetPresentationController {
    private var prevTraitcollection : UITraitCollection?

    override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        let localtraitCollection = self.presentingViewController.traitCollection
        self.prevTraitcollection = localtraitCollection;
    }

    init(presentedVc: UIViewController, presentingVc: UIViewController?, cornerRadius: CGFloat = 16.0, toGrabFurther: Bool = true, source: UIViewController) {
        super.init(presentedViewController: presentedVc, presenting: presentingVc)
        let startHeight = UISheetPresentationController.Detent.custom { context in
            presentedVc.preferredContentSize.height
        }
        if let window = source.view.window, presentedVc.preferredContentSize.height > window.frame.height * 0.5 {
            self.detents = [startHeight,.large()]
        }
        else {
            self.detents = [startHeight, .medium(), .large()]
        }
        if !toGrabFurther {
            self.detents = [startHeight]
        }
        self.preferredCornerRadius = cornerRadius
        self.prefersGrabberVisible = true
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: {_ in
        }, completion: { [weak self](_) in
            self?.detectTraitCollectionChange()
        })
    }

    private func detectTraitCollectionChange() {
        let localtraitCollection = self.presentingViewController.traitCollection
        if self.prevTraitcollection?.isRegular != localtraitCollection.isRegular {
            self.prevTraitcollection = localtraitCollection
            (self.presentedViewController.transitioningDelegate as? FTPopoverPresentation)?.resetPresentation()
        } else if !(self.prevTraitcollection?.isRegular ?? false) && self.presentingViewController.view.frame.width > popOverThresholdWidth {
            (self.presentedViewController.transitioningDelegate as? FTPopoverPresentation)?.resetPresentation()
        }
    }
}
