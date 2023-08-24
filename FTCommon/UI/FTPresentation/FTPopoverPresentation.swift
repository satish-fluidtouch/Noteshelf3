//
//  FTPresentation.swift
//  FTPresentation
//
//  Created by Narayana on 05/05/23.
//

import UIKit

let popOverThresholdWidth: CGFloat = 450.0

 public protocol FTPopoverPresentable {
     var ftPresentationDelegate: FTPopoverPresentation { get }
}

public class FTPopoverPresentation: NSObject, UIViewControllerTransitioningDelegate {
    public weak var source: AnyObject?

    public var permittedArrowDirections: UIPopoverArrowDirection?
    public var sourceRect: CGRect?

    public var isDismissDisable = false
    public var compactGrabFurther = true
    private weak var presented: UIViewController?
    private weak var sourceVc: UIViewController?

    override public init() {
        super.init()
    }

    // MARK: - UIViewControllerTransitioningDelegate
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        self.presented = presented
        self.sourceVc = source

#if targetEnvironment(macCatalyst)
        let presentation = popoverPresenter()
        if let toolItem = self.source as? NSToolbarItem {
            presentation.sourceItem = toolItem
        } else if let sourceView = self.source as? UIView {
            presentation.sourceView = sourceView
            presentation.sourceRect = sourceRect ?? sourceView.bounds
        }
        return presentation
#else
        var toPresentPopover = source.isRegularClass()
        if !toPresentPopover && source.view.frame.width > popOverThresholdWidth {
            toPresentPopover = true
        }
        
        if let sourceView = self.source as? UIView, toPresentPopover {
            let presentation = popoverPresenter()
            presentation.sourceView = sourceView
            presentation.sourceRect = sourceRect ?? sourceView.bounds
            return presentation
        } else {
            let ftPresent = FTSheetPresentationController(presentedVc: presented, presentingVc: presenting, toGrabFurther: compactGrabFurther)
            presented.view.backgroundColor = UIColor.appColor(.popoverBgColor)
            return ftPresent
        }
#endif
        func popoverPresenter() -> FTPopoverPresentationController {
            let presentation = FTPopoverPresentationController(presentedViewController: presented, presenting: presenting)
            presentation.permittedArrowDirections = permittedArrowDirections ?? .any
            presentation.delegate = self
            return presentation
        }
    }

    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }

    func resetPresentation() {
        if source != nil {
            //In order to dismiss any other controllers on top of this Custom Presentations.
            func dismissAndPresent(){
                presented?.dismiss(animated: false, completion: {
                    if let toBePresented = self.presented {
                        self.sourceVc?.present(toBePresented, animated: false, completion: nil)
                    }
                })
            }
            if presented?.presentedViewController != nil {
                presented?.dismiss(animated: false, completion: {
                    dismissAndPresent()
                })
            }
            else{
                dismissAndPresent()
            }
        }
    }
}

extension FTPopoverPresentation: UIPopoverPresentationControllerDelegate {
    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }

    public func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        // to prevent animation, we need to dismiss it manuallly with animated: false
        //          presentationController.presentingViewController.dismiss(animated: false, completion: nil)
        if isDismissDisable {
            return false
        }
        return true
    }
}
