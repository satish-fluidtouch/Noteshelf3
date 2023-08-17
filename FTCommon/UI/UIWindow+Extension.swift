//
//  UIWindow+Extension.swift
//  FTCommon
//
//  Created by Narayana on 02/03/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

 extension UIWindow {
     @objc public var ftStatusBarOrientation : UIInterfaceOrientation {
             return self.windowScene?.interfaceOrientation ?? .unknown
     }

    @objc public var visibleViewController: UIViewController? {
        let rootViewController = self.rootViewController
        return getVisibleViewController(from: rootViewController)
    }

    private func getVisibleViewController(from vc: UIViewController?) -> UIViewController? {
        if let navVC = vc as? UINavigationController {
            return getVisibleViewController(from: navVC.visibleViewController)
        } else if let tabVC = vc as? UITabBarController {
            return getVisibleViewController(from: tabVC.selectedViewController)
        } else if let presented = vc?.presentedViewController, presented.isBeingDismissed == false {
            return getVisibleViewController(from: presented)
        } else {
            return vc
        }
    }
}
