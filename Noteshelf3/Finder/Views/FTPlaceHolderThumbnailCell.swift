//
//  FTPlaceHolderThumbnailCell.swift
//  Noteshelf3
//
//  Created by Sameer on 25/10/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
class FTPlaceHolderThumbnailCell: UICollectionViewCell {
    @IBOutlet var viewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var placeHolderView: UIView!
    @IBOutlet var viewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var moreOptionsButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        placeHolderView.layer.cornerRadius = 10
    }
    
    var isDisabled : Bool = false {
        didSet {
            self.isUserInteractionEnabled = !isDisabled
            self.contentView.subviews.forEach { eachSubview in
                if eachSubview != placeHolderView {
                    eachSubview.alpha = isDisabled ? 0.5 : 1
                }
            }
        }
    }

    override var canBecomeFocused: Bool {
        return false
    }
    
    var imageSize : CGSize = .zero {
        didSet {
            viewHeightConstraint.constant = imageSize.height
            viewWidthConstraint.constant = imageSize.width
        }
    }
}
