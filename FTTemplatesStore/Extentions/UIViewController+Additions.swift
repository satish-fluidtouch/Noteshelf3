//
//  UIViewController+Additions.swift
//  TempletesStore
//
//  Created by Siva on 25/05/23.
//

import UIKit

extension UIViewController {
     func noOfColumnsForCollectionViewGrid() -> Int {
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
