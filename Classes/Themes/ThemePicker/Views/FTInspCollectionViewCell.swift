//
//  FTInspCollectionViewCell.swift
//  Noteshelf
//
//  Created by Naidu on 17/04/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTInspCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewNotebook: UIImageView!
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var shadowImageView : UIImageView?
    @IBOutlet weak var titleLabelTopConstraint: NSLayoutConstraint?
    
    var uuid : String = UUID().uuidString;
    
    var allowSelection : Bool = true {
        didSet {
            self.titleLabel?.alpha = self.allowSelection ? 1 : 0.3;
            self.imageView.alpha = self.allowSelection ? 1 : 0.3;
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        //self.titleLabelTopConstraint?.constant = self.titleLabel?.superview.frame.height * 0.242424
    }
    override func awakeFromNib() {
        let darkImage = UIImage.init(named: "theme_shadow");
        self.shadowImageView?.image = darkImage?.resizableImage(withCapInsets: UIEdgeInsets(top: 6, left: 8, bottom: 10, right: 8), resizingMode: UIImage.ResizingMode.stretch);
    }
}
