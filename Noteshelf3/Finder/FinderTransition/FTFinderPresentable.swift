//
//  FTFinderPresentable.swift
//  Noteshelf3
//
//  Created by Sameer on 28/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

protocol FTFinderPresentable {
    var isResizing: Bool { get set }
    var finderTransitioningDelegate: FTFinderTransitionDelegate { get }
    
    func didChangeState(to screenState: FTFinderScreenState)
    func detectTraitCollectionDidChange(to traitCollection: UITraitCollection)
    func shouldStartWithFullScreen() -> Bool
}

enum FTFinderPresentationStyle {
    case defaultAnimation
    case interaction
    case presentWithoutAnimation
}

enum FTFinderMode {
    case suplimentaryOverlay
    case sideBySide
    case primaryOverlay
    case twoBesideSecondary
}

enum FTFinderDirection {
    case leftToRight
    case rightToLeft
}

enum FTFinderScreenState {
    case dragging
    case initial
    case fullScreen
    case dismiss
}

private let defaultPresentationSize = CGSize(width: 580, height: 700)
private let defaultInteractionSize = CGSize(width: 300, height: 400)

extension UIViewController {

    func presentFinderHorizontally(_ viewController: UIViewController, contentSize: CGSize? = nil, animated: Bool, completion:(() -> Void)?) {
        guard let customTransitioningDelegate = (viewController as? FTFinderPresentable)?.finderTransitioningDelegate else {
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
