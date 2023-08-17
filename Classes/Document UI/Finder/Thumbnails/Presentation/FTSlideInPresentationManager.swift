//
//  FTSlideInPresentationManager.swift
//  Noteshelf
//
//  Created by Siva on 05/01/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

enum SlideInType {
    case leftToRight
    case rightToLeft
    case topToBottom
    case bottomToTop
    case center
}

class FTSlideInPresentationManager: NSObject, UIViewControllerTransitioningDelegate {
    var mode: SlideInType;
    
    override init() {
        self.mode = SlideInType.rightToLeft;
    }

    init(mode: SlideInType) {
        self.mode = mode;
    }
    
    //MARK:- Animation
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FTSlideInPresentAnimator(mode: self.mode);
    }
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FTSlideInDismissAnimator(mode: self.mode);
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        if self.mode == .topToBottom {
            let presentedObject = FTFromTopPresentationController(presentedViewController: presented, presenting: presenting)
            return presentedObject
        }
        
        return UIPresentationController(presentedViewController: presented, presenting: presenting)
    }
}
