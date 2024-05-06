//
//  UIApplication+Extension.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 28/04/22.
//

import UIKit
import SwiftUI

extension UIApplication {
    public func getKeyWindowScene() -> UIWindowScene? {
        let window =  UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        if let scene = window {
            return  scene.windowScene
        }
        return nil
    }
    
    public func topViewController() -> UIViewController? {
        var topViewController: UIViewController?
        for scene in connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                for window in windowScene.windows where window.isKeyWindow {
                    topViewController = window.rootViewController
                }
            }
        }
        while true {
            if let presented = topViewController?.presentedViewController {
                topViewController = presented
            } else if let navController = topViewController as? UINavigationController {
                topViewController = navController.topViewController
            } else if let tabBarController = topViewController as? UITabBarController {
                topViewController = tabBarController.selectedViewController
            } else {
                break
            }
        }
        return topViewController
    }

    public var keyWindow: UIWindow? {
        return UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .first(where: { $0 is UIWindowScene })
            .flatMap({ $0 as? UIWindowScene })?.windows
            .first(where: \.isKeyWindow)
    }

    public var sceneDelegate: UISceneDelegate? {
        return UIApplication.shared.connectedScenes
            .first(where: { $0 is UIWindowScene })
            .flatMap({ $0.delegate})
    }

    public func uiColorScheme() -> UIUserInterfaceStyle {
        return self.keyWindow?.traitCollection.userInterfaceStyle ?? .light
    }

}


extension UIUserInterfaceStyle {
    public var toColorScheme: ColorScheme {
        switch self {
        case .dark:
            return .dark
         default:
            return .light
        }
    }
}
