//
//  FTBookmarkColorFooter.swift
//  Noteshelf3
//
//  Created by Sameer Hussain on 07/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

class FTBookmarkColorFooter: UICollectionReusableView {
    @IBOutlet var removeBookmarkButton: UIButton?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        removeBookmarkButton?.layer.cornerRadius = 10
        removeBookmarkButton?.titleLabel?.text = "bookmark.removebookMark".localized
        FTInteractionButton.shared.apply(to: removeBookmarkButton!,withScaleValue: 0.94)
    }
}
