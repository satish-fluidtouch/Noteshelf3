//
//  FTThemeCoverflowView.swift
//  Noteshelf
//
//  Created by Siva on 29/04/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTThemeCoverflowView: UIView {
    @IBOutlet weak var shadowImageView: FTShelfItemShadowImageView!
    @IBOutlet weak var imageView: UIImageView!;
    
    override func awakeFromNib() {
        self.shadowImageView.isHidden = true;
        self.imageView.layer.shadowColor = UIColor.black.cgColor;
        self.imageView.layer.shadowOpacity = 0.12;
        self.imageView.layer.shadowOffset = CGSize.init(width: 0, height: 2);
        self.imageView.layer.shadowRadius = 6;
//        let darkImage = UIImage.init(named: "theme_shadow");
//        self.shadowImageView?.image = darkImage?.resizableImage(withCapInsets: UIEdgeInsetsMake(6, 8, 10, 8), resizingMode: UIImageResizingMode.stretch);
    }
}
