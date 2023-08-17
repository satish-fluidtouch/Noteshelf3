//
//  FTFinderSegmentControl.swift
//  Noteshelf3
//
//  Created by Sameer on 22/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

enum FTSegmentType {
    case image
    case text
}

class FTFinderSegmentControl: UISegmentedControl {
    var type = FTSegmentType.image
    var segmentsCount = 3
    
    func populateSegments() {
        let items = itemsForSegment()
        self.removeAllSegments()
        for (index, item) in items.enumerated() {
            if type == .image {
                let image = UIImage.image(for: item, font: UIFont.appFont(for: .semibold, with: 14))
                self.insertSegment(with: image, at: index, animated: false)
            } else if type == .text {
                self.insertSegment(withTitle: item, at: index, animated: false)
            }
            self.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.label.withAlphaComponent(0.7)], for: UIControl.State.normal)
            self.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.label], for: UIControl.State.selected)
        }
    }
    
    private func itemsForSegment() -> [String] {
        var items = [""]
        if type == .image  {
            items = ["square.grid.2x2", "bookmark"]
            if segmentsCount == 3 {
                items.append("list.triangle")
            }
        } else if type == .text {
            items = ["Thumbnails".localized, "finder.bookmarks".localized]
            if segmentsCount == 3 {
                items.append("finder.outline".localized)
            }
        }
        return items
    }
}
