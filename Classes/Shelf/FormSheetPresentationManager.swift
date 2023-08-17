//
//  FTFormSheetPresentationManager.swift
//  Noteshelf
//
//  Created by Siva on 16/01/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

let ShadowOffsetFormSheet: CGFloat = -10;

enum FTFormSheetBackgroundType {
    case `default`
    case blur
    case settings
}

class FTFormSheetPresentationManager: NSObject, UIViewControllerTransitioningDelegate {
    let backgroundType: FTFormSheetBackgroundType;
    init(with backgroundType: FTFormSheetBackgroundType! = .default) {
        self.backgroundType = backgroundType;
    }
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let formPresenter = FTFormSheetPresentationController(presentedViewController: presented, presenting: presenting);
        formPresenter.backgroundType = self.backgroundType;
        return formPresenter;
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FTFormSheetAnimator(with: self.backgroundType);
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FTFormSheetDismissAnimator(with: self.backgroundType);
    }
}

class FTFormSheetPresentationController: UIPresentationController {
    var backgroundType: FTFormSheetBackgroundType = FTFormSheetBackgroundType.default;
    override var frameOfPresentedViewInContainerView : CGRect {
        if self.presentedViewController.modalPresentationStyle == .custom {
            return self.frameForCenteredView();
        }
        else {
            return self.presentingViewController.view.bounds;
        }
    }
    
    override func containerViewDidLayoutSubviews() {
        if self.containerView!.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.regular && self.containerView!.traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.regular
        {
            self.presentedViewController.view.frame = self.frameForCenteredView();
            if let imageViewShadow = self.containerView!.viewWithTag(555) {
                imageViewShadow.frame = self.presentedViewController.view.frame.insetBy(dx: ShadowOffsetFormSheet, dy: ShadowOffsetFormSheet);
            }
            else {
                let imageShadow = UIImage(named: "Export/formsheet_shadow")?.resizableImage(withCapInsets: UIEdgeInsets(top: 25, left: 25, bottom: 25, right: 25), resizingMode: .stretch);
                let imageViewShadow = UIImageView(image: imageShadow);
                imageViewShadow.tag = 555;
                imageViewShadow.frame = self.presentedViewController.view.frame.insetBy(dx: ShadowOffsetFormSheet, dy: ShadowOffsetFormSheet);
                self.containerView!.insertSubview(imageViewShadow, belowSubview: self.presentedViewController.view);
            }
            
            switch self.backgroundType {
            case .default:
               self.containerView?.backgroundColor = UIColor(white: 0, alpha: 0.5);
            default:
                break;
            }
        }
        else {
            self.presentedViewController.view.frame = self.presentingViewController.view.bounds;
        }
    }
    
    override func adaptivePresentationStyle(for traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        if traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.regular && traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.regular
        {
            self.presentedViewController.view.layer.cornerRadius = 10;
            if self.backgroundType == .settings {
                self.presentedViewController.view.layer.cornerRadius = 16;
            }
            return .custom;
        }
        self.presentedViewController.view.layer.cornerRadius = 0;
        return .overFullScreen;
    }
    
    //MARK:- Helper
    fileprivate func frameForCenteredView() -> CGRect {
        var sourceViewControllerFrame = self.presentingViewController.view.frame;
        if let containerView = self.containerView {
            sourceViewControllerFrame = containerView.frame;
        }
        let destinationViewControllerFrame = self.presentedViewController.preferredContentSize;
        return CGRect(origin: CGPoint.init(x: (sourceViewControllerFrame.width - destinationViewControllerFrame.width) / 2, y: (sourceViewControllerFrame.height - destinationViewControllerFrame.height) / 2), size: self.presentedViewController.preferredContentSize);
    }
}

class FTFormSheetAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let backgroundType: FTFormSheetBackgroundType;
    init(with backgroundType: FTFormSheetBackgroundType! = .default) {
        self.backgroundType = backgroundType;
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3;
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let destinationViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!;
        let containerView = transitionContext.containerView;
        let finalFrame = transitionContext.finalFrame(for: destinationViewController);
        
        containerView.addSubview(destinationViewController.view);
        
        switch self.backgroundType {
        case .default:
            containerView.backgroundColor = UIColor(white: 0, alpha: 0.5);
        case .blur:
            containerView.backgroundColor = UIColor.clear;
            let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.light));
            visualEffectView.alpha = 0;
            visualEffectView.tag = 666;
            visualEffectView.frame = containerView.bounds;
            visualEffectView.backgroundColor = UIColor.clear;
            visualEffectView.contentView.backgroundColor = UIColor(red: 45 / 255, green: 45 / 255, blue: 45 / 255, alpha: 0.7);
            containerView.insertSubview(visualEffectView, at: 0);
            
            visualEffectView.translatesAutoresizingMaskIntoConstraints = false
            
            let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[subview]-0-|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: ["subview" : visualEffectView]);
            containerView.addConstraints(horizontalConstraints);
            
            let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[subview]-0-|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: ["subview" : visualEffectView])
            containerView.addConstraints(verticalConstraints);
        case .settings:
            containerView.backgroundColor = UIColor.black.withAlphaComponent(0.1);
        }
        
        let imageShadow = UIImage(named: "Export/formsheet_shadow")?.resizableImage(withCapInsets: UIEdgeInsets(top: 25, left: 25, bottom: 25, right: 25), resizingMode: .stretch);
        let imageViewShadow = UIImageView(image: imageShadow);
        imageViewShadow.tag = 555;
        containerView.insertSubview(imageViewShadow, belowSubview: destinationViewController.view);

        destinationViewController.view.frame = finalFrame.offsetBy(dx: 0, dy: containerView.frame.height);

        destinationViewController.view.layer.cornerRadius = 4;
        if self.backgroundType == .settings {
            destinationViewController.view.layer.cornerRadius = 16;
        }
        destinationViewController.view.layer.masksToBounds  = true;
        
        imageViewShadow.frame = destinationViewController.view.frame.insetBy(dx: ShadowOffsetFormSheet, dy: ShadowOffsetFormSheet);

        UIView.animate(withDuration: self.transitionDuration(using: transitionContext), animations: {
            if let visualEffectView = containerView.viewWithTag(666) {
                visualEffectView.alpha = 1;
            }
            destinationViewController.view.frame = finalFrame;
            imageViewShadow.frame = destinationViewController.view.frame.insetBy(dx: ShadowOffsetFormSheet, dy: ShadowOffsetFormSheet);
        }, completion: { (finished) in
            transitionContext.completeTransition(finished);
        }) ;
    }
}

class FTFormSheetDismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let backgroundType: FTFormSheetBackgroundType;
    init(with backgroundType: FTFormSheetBackgroundType! = .default) {
        self.backgroundType = backgroundType;
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
//        if self.backgroundType == .settings {
//            return 0
//        }
        return 0.3;
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let sourceViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!;
        let containerView = transitionContext.containerView;
        let initialFrame = transitionContext.finalFrame(for: sourceViewController);

        sourceViewController.view.frame = initialFrame;
        
        UIView.animate(withDuration: self.transitionDuration(using: transitionContext), animations: {
            if let visualEffectView = containerView.viewWithTag(666) {
                visualEffectView.alpha = 0;
            }
            sourceViewController.view.frame = initialFrame.offsetBy(dx: 0, dy: containerView.frame.height - initialFrame.minY);
            if let imageViewShadow = containerView.viewWithTag(555) {
                imageViewShadow.frame = sourceViewController.view.frame.insetBy(dx: ShadowOffsetFormSheet, dy: ShadowOffsetFormSheet);
            }
        }, completion: { (finished) in
            transitionContext.completeTransition(finished);
        }) ;
    }
}
