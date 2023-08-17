//
//  FTPhotoCollectionViewCell.swift
//  Noteshelf
//
//  Created by Siva on 25/04/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTPhotoCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var selectionImageView: UIImageView!
    
    var representedAssetIdentifier: String!
    
    override var isSelected: Bool {
        didSet {
            self.selectionImageView.isHidden = !self.isSelected;
        }
    }
}
