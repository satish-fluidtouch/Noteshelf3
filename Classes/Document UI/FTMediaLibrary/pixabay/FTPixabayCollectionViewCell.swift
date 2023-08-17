//
//  FTPixabayCollectionViewCell.swift
//  Noteshelf
//
//  Created by srinivas on 17/10/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import SDWebImage
class FTPixabayCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var selectImage: UIImageView!

    private var currentItem: FTMediaLibraryModel?
    
    func configure(with item: FTMediaLibraryModel) {
        if(currentItem?.id == item.id) {
            return
        }
        self.imageView.contentMode = .center
        self.imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.imageView.clipsToBounds = true
        
        currentItem = item
        self.imageView?.image = nil
        self.selectImage.isHidden = !self.isSelected
       
        if let clipartURL = item.urls {
            imageView.sd_setImage(with: URL(string: clipartURL.png_thumb),
                                  placeholderImage: nil,
                                  options: SDWebImageOptions.refreshCached,
                                  completed: nil);
        }
        
    }
    
    override var isSelected: Bool {
        didSet {
            self.selectImage.isHidden = !self.isSelected
        }
    }
}
