//
//  FTCustomCoverStyleCollectionViewCell.swift
//  Noteshelf
//
//  Created by Siva on 25/10/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTCustomCoverStyleCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageViewStyle: UIImageView!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var imageViewColors: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib();
        self.labelTitle.text = "Lorem Ipsum\nDolor Sit Amet";
    }
}
