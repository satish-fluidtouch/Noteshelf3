//
//  NSLayoutConstraint+Extension.swift
//  FTCommon
//
//  Created by Narayana on 21/05/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension NSLayoutConstraint {
   public func getUpdatedConstraint(byApplying multiplier: CGFloat) -> NSLayoutConstraint {
        NSLayoutConstraint.deactivate([self])

        // Create a new constraint with the updated multiplier
        let newConstraint = NSLayoutConstraint(
            item: self.firstItem!,
            attribute: self.firstAttribute,
            relatedBy: self.relation,
            toItem: self.secondItem,
            attribute: self.secondAttribute,
            multiplier: multiplier,
            constant: self.constant
        )
        newConstraint.priority = self.priority
        newConstraint.identifier = self.identifier

        NSLayoutConstraint.activate([newConstraint])
        return newConstraint
    }
}
