//
//  FTCustomPresentable.swift
//  Noteshelf
//
//  Created by Akshay on 14/02/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTHorizontalPresentable {
    var isResizing: Bool { get set }
    var horizontalTransitioningDelegate: FTHorizontalTransitionDelegate { get }
    
    func didChangeState(to screenState: FTHotizontalScreenState)
    func shouldStartWithFullScreen() -> Bool
}

private let defaultPresentationSize = CGSize(width: 580, height: 700)
private let defaultInteractionSize = CGSize(width: 300, height: 400)

extension UIViewController {

    func ftPresentHorizontally(_ viewController: UIViewController, contentSize: CGSize? = nil, animated: Bool, completion:(() -> Void)?) {
        guard let customTransitioningDelegate = (viewController as? FTHorizontalPresentable)?.horizontalTransitioningDelegate else {
            fatalError("viewController should conform to FTCustomPresentable protocol")
        }

        let customContentSize: CGSize
        if let size = contentSize {
            customContentSize = size
        } else {
            if customTransitioningDelegate.presentationStyle == .interaction {
                customContentSize = defaultInteractionSize
            } else {
                customContentSize = defaultPresentationSize
            }
        }

        if viewController is UISplitViewController {
            viewController.modalPresentationStyle = .custom;
            viewController.preferredContentSize = customContentSize
            viewController.transitioningDelegate = customTransitioningDelegate;
            self.present(viewController, animated: animated, completion: completion);
        } else {
            let navController: UINavigationController
            if let navVC = viewController as? UINavigationController {
                navController = navVC
            } else {
                navController = UINavigationController(rootViewController: viewController)
            }
            navController.isNavigationBarHidden = true
            navController.modalPresentationStyle = .custom;
            navController.preferredContentSize = customContentSize
            navController.transitioningDelegate = customTransitioningDelegate;
            self.present(navController, animated: animated, completion: completion);
        }
    }
}

class FTHorizontalPresentationSegue: UIStoryboardSegue {
    override func perform() {
        var trasitionDelegate: FTHorizontalTransitionDelegate?

        if let customTransitioningDelegate = (destination as? FTHorizontalPresentable)?.horizontalTransitioningDelegate {
            trasitionDelegate = customTransitioningDelegate;
        } else if let controller = (destination as? UINavigationController)?.viewControllers.first,
            let customTransitioningDelegate = (controller as? FTHorizontalPresentable)?.horizontalTransitioningDelegate {
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
