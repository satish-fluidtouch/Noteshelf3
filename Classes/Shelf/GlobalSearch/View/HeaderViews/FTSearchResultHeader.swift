//
//  FTSearchResultHeader.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 05/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTSearchResultHeader: UICollectionReusableView {
    @IBOutlet private weak var shadowImage: UIImageView?

    @IBOutlet weak var lblTitle: UILabel?
    @IBOutlet weak var lblCategory: UILabel?
    @IBOutlet weak var lblMatchCount: UILabel?
    @IBOutlet weak var bookImgPreview: UIImageView?
    @IBOutlet weak var coverPreviewContainer: UIView?
    @IBOutlet weak var imgWidthConstraint: NSLayoutConstraint?
    @IBOutlet weak var imgHeightConstraint: NSLayoutConstraint?

     var toShowEqualCorners: Bool = false {
        didSet {
            let capInsets = UIEdgeInsets(top: 5, left: 15, bottom: 25, right: 15)
            if toShowEqualCorners {
                self.bookImgPreview?.layer.cornerRadius = 3.0
                self.shadowImage?.image = UIImage(named: "noCoverNBShadow")
                let scalled = self.shadowImage?.image?.resizableImage(withCapInsets: capInsets, resizingMode: .stretch)
                self.shadowImage?.image = scalled
            } else {
                self.bookImgPreview?.roundCorners(topLeft: 2.0, topRight: 4.0, bottomLeft: 2.0, bottomRight: 4.0)
                self.shadowImage?.image = UIImage(named: "searchResultBook_shadow")
                let scalled = self.shadowImage?.image?.resizableImage(withCapInsets: capInsets, resizingMode: .stretch)
                self.shadowImage?.image = scalled
            }
        }
    }
}
