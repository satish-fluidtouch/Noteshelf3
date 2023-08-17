//
//  FTPenColorCollectionViewCell.swift
//  FTPenRack
//
//  Created by Siva on 08/04/17.
//  Copyright © 2017 Fluid Touch Pvt Ltd. All rights reserved.
//

import UIKit

public class FTPenColorCollectionViewCell: UICollectionViewCell {
    @IBOutlet public weak var viewColor: UIView!
    @IBOutlet public weak var editButton: UIButton!
    @IBOutlet public weak var imageViewBorder: UIImageView!
    @IBOutlet public weak var imageViewEmpty: UIImageView!

    
    public override func awakeFromNib() {
        super.awakeFromNib()
        self.editButton.isHidden = true
        self.editButton.layer.cornerRadius = self.editButton.frame.size.height/2.0
        self.viewColor.layer.borderColor = UIColor.appColor(.black10).cgColor
    }
    
    public var currentSelected: Bool = false {
        didSet {
            if currentSelected {
                self.viewColor.layer.borderWidth = 0.0
                self.imageViewBorder.isHidden = false
            } else {
                self.imageViewBorder.isHidden = true
            }
        }
    }

}
