//
//  UIViewController+Extension.swift
//  FTCommon
//
//  Created by Narayana on 07/03/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import SwiftUI

extension UIViewController {
    public func ftPresentPopover(vcToPresent: UIViewController,
                                     contentSize: CGSize,
                                     animated: Bool = true,
                                     hideNavBar: Bool = false,
                                     completion: (() -> Void)? = nil) {
        let customPresentationDelegate: FTPopoverPresentation

        if let customPresentableController = vcToPresent as? FTPopoverPresentable {
            customPresentationDelegate = customPresentableController.ftPresentationDelegate
        } else if let customPresentableNavController = (vcToPresent as? UINavigationController)?.viewControllers.first as? FTPopoverPresentable {
            customPresentationDelegate = customPresentableNavController.ftPresentationDelegate
        } else {
            fatalError("viewController should conform to FTPopoverPresentable protocol")
        }

        let navController: UINavigationController
        if let navVC = vcToPresent as? UINavigationController {
            navController = navVC
        } else {
            navController = UINavigationController(rootViewController: vcToPresent)
        }
        navController.isNavigationBarHidden = hideNavBar
        navController.modalPresentationStyle = .custom
        navController.preferredContentSize = contentSize
        navController.transitioningDelegate = customPresentationDelegate
        self.present(navController, animated: animated, completion: completion)
    }

    public func ftPresentFormsheet(vcToPresent: UIViewController,
                                   contentSize: CGSize = CGSize(width: 540.0, height: 620.0),
                                   animated: Bool = true,
                                   hideNavBar: Bool = true,
                                   completion: (() -> Void)? = nil) {
        let navController: UINavigationController
        if let navVC = vcToPresent as? UINavigationController {
            navController = navVC
        } else {
            navController = UINavigationController(rootViewController: vcToPresent)
        }
        navController.navigationBar.isHidden = hideNavBar
        navController.modalPresentationStyle = .formSheet
        navController.preferredContentSize = contentSize
#if targetEnvironment(macCatalyst)
        navController.overrideUserInterfaceStyle = UIApplication.shared.uiColorScheme()
#endif
        self.present(navController, animated: animated, completion: completion)
    }

    public func add(_ child: UIViewController) {
        addChild(child)
        view.addSubview(child.view)
        child.didMove(toParent: self)
    }

    public func remove() {
        guard parent != nil else {
            return
        }
        willMove(toParent: nil)
        removeFromParent()
        view.removeFromSuperview()
    }

    @objc open func isRegularClass() -> Bool {
#if targetEnvironment(macCatalyst)
        return true
#else
        var isRegular = traitCollection.isRegular
        if let splitViewController = self.splitViewController {
            isRegular = splitViewController.traitCollection.isRegular
        }
        return isRegular
#endif
    }

   public func noOfColumnsForCollectionViewGrid() -> Int {
        let size = self.view.frame.size
       var noOfColumns: Int = 3
       let isInLandscape = UIScreen.main.bounds.width > UIScreen.main.bounds.height
       if self.splitViewController?.displayMode == .secondaryOnly {
           if isInLandscape {
               noOfColumns = (self.traitCollection.horizontalSizeClass == .regular && size.width >= 820) ? 4 : 3
           } else {
               noOfColumns = self.traitCollection.horizontalSizeClass == .regular ? 3 : 2
           }
       } else {
           if isInLandscape {
               noOfColumns = size.width > 550 ? 3 : 2
           } else {
               noOfColumns = 2
           }
       }
       return noOfColumns
   }

}

extension UITraitCollection {
  public var isRegular: Bool {
        if self.horizontalSizeClass == UIUserInterfaceSizeClass.regular
            && self.verticalSizeClass == UIUserInterfaceSizeClass.regular {
            return true
        }
        return false
    }
}

extension UIHostingController {
    public func isInLandscape()-> Bool {
        if let window = self.view.window {
            if window.ftStatusBarOrientation.isLandscape {
                return true
            } else {
                return false
            }
        }
        return false
    }
}
