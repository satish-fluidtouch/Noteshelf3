//
//  FTCustomPresentable.swift
//  Noteshelf
//
//  Created by Akshay on 14/02/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTCustomPresentable {
    var customTransitioningDelegate: FTCustomTransitionDelegate { get }
}

private let defaultPresentationSize = CGSize(width: 580, height: 700)
private let defaultInteractionSize = CGSize(width: 580, height: 400)

extension UIViewController {
    @available(*, deprecated, message: "Now we have ios standard popover for Regular and UISheetPresentation(iOS 15.0) for Compact) with FTPopoverPresentation.. Use --> ftPresentPopover from FTCommon, If you want to present formsheet, present is from your screen")
    func ftPresentModally(_ viewController: UIViewController, contentSize: CGSize? = nil, hideNavBar: Bool = true, animated: Bool, completion:(() -> Void)?) {
        
        let customTransitioningDelegate : FTCustomTransitionDelegate

        if let customPresentableController = viewController as? FTCustomPresentable {
            customTransitioningDelegate = customPresentableController.customTransitioningDelegate
        } else if let customPresentableNavController = (viewController as? UINavigationController)?.viewControllers.first as? FTCustomPresentable {
            customTransitioningDelegate = customPresentableNavController.customTransitioningDelegate
        } else {
            fatalError("viewController should conform to FTCustomPresentable protocol")
        }

        let customContentSize: CGSize
        if let size = contentSize {
            customContentSize = size
        } else {
            switch customTransitioningDelegate.presentationStyle {
            case .interaction:
                customContentSize = defaultInteractionSize
            case .presentation:
                customContentSize = defaultPresentationSize
            case .overLay:
                customContentSize = defaultPresentationSize
            case .presentationFullScreen:
                customContentSize = CGSize.zero;
            }
        }

        if viewController is UISplitViewController {
            self.present(viewController, animated: animated, completion: completion);
        } else {
            let navController: UINavigationController
            if let navVC = viewController as? UINavigationController {
                navController = navVC
            } else {
                navController = UINavigationController(rootViewController: viewController)
            }
            navController.isNavigationBarHidden = hideNavBar
            navController.modalPresentationStyle = .custom;
            navController.preferredContentSize = customContentSize
            navController.transitioningDelegate = customTransitioningDelegate;
            self.present(navController, animated: animated, completion: {
                if let presentationVc = navController.presentationController as? FTPopoverPresentationController {
                    presentationVc.onDismissBlock = customTransitioningDelegate.onDismissBlock
                    customTransitioningDelegate.onDismissBlock = nil;
                }
            })
        }
    }

    func canbePopped() -> Bool {
        guard let firstVC = self.navigationController?.viewControllers.first else {
            return false
        }
        return firstVC != self
    }

    @IBAction internal func backButtonTapped(_ sender: UIButton?) {
        let poppedController = self.navigationController?.popViewController(animated: true)
        if nil == poppedController {
            self.dismiss(animated: true, completion: nil)
        }
    }

    var isRootViewController: Bool {
        if self.navigationController?.viewControllers.first == self
            || self.presentingViewController?.presentedViewController == self {
            return true;
        }
        return false;
    }

}

class FTCustomPresentationSegue: UIStoryboardSegue {
    override func perform() {
        var trasitionDelegate: FTCustomTransitionDelegate?

        if let customTransitioningDelegate = (destination as? FTCustomPresentable)?.customTransitioningDelegate {
            trasitionDelegate = customTransitioningDelegate;
        } else if let controller = (destination as? UINavigationController)?.viewControllers.first,
            let customTransitioningDelegate = (controller as? FTCustomPresentable)?.customTransitioningDelegate {
            trasitionDelegate = customTransitioningDelegate;
        }

        if trasitionDelegate != nil {
            destination.modalPresentationStyle = .custom;
            destination.transitioningDelegate = trasitionDelegate
        } else {
            destination.modalPresentationStyle = .formSheet;
        }

        source.present(destination, animated: true, completion: nil);
    }
}

protocol FTTraitCollectionOverridable : AnyObject {
    func rootViewController() -> UIViewController?
    func ftOverrideTraitCollection(forWindow window: UIWindow?) -> UITraitCollection?
}

extension FTTraitCollectionOverridable
{
    func rootViewController() -> UIViewController? {
        return nil;
    }
}
