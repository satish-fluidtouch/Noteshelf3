//
//  FTBasePenRackViewController.swift
//  Noteshelf
//
//  Created by srinivas on 08/08/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

@objcMembers public class FTBasePenRackViewController : UIViewController, FTPopoverPresentable {
    public var ftPresentationDelegate = FTPopoverPresentation()

    class var identifier: String {
       return "FTLassoRackViewController"
    }

    class var storyBoardName: String {
        return "FTPenRack"
    }

    class var contentSize: CGSize {
        return CGSize(width: 320, height: 250)
    }

    static var selectedRack = FTRackData(type: .pen, userActivity: nil)
    
    class func setRackType(penTypeRack: FTRackData) {
        selectedRack = penTypeRack
    }

    @discardableResult
    class func showPopOver(presentingController: UIViewController, sourceView: Any, sourceRect: CGRect = .zero, arrowDirections: UIPopoverArrowDirection = .any) -> UIViewController {
        let storyboard = UIStoryboard(name: self.storyBoardName, bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: self.identifier)
        (viewController as? FTPopoverPresentable)?.ftPresentationDelegate.source = sourceView as AnyObject
        if sourceRect != .zero {
            (viewController as? FTPopoverPresentable)?.ftPresentationDelegate.sourceRect = sourceRect
        }
        (viewController as? FTPopoverPresentable)?.ftPresentationDelegate.permittedArrowDirections = arrowDirections
        presentingController.ftPresentPopover(vcToPresent: viewController, contentSize: contentSize, hideNavBar: true)
        return viewController
    }
}

extension CALayer {
  func applySketchShadow(
    color: UIColor = .black,
    alpha: Float = 0.5,
    x: CGFloat = 0,
    y: CGFloat = 2,
    blur: CGFloat = 4,
    spread: CGFloat = 0)
  {
    masksToBounds = false
    shadowColor = color.cgColor
    shadowOpacity = alpha
    shadowOffset = CGSize(width: x, height: y)
    shadowRadius = blur / 2.0
    if spread == 0 {
      shadowPath = nil
    } else {
      let dx = -spread
      let rect = bounds.insetBy(dx: dx, dy: dx)
      shadowPath = UIBezierPath(rect: rect).cgPath
    }
  }
}
