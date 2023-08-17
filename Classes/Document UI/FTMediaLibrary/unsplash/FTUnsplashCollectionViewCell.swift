//
//  FTUnsplashCollectionViewCell.swift
//  Noteshelf
//
//  Created by srinivas on 13/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import SDWebImage
import FTNewNotebook

class FTUnsplashCollectionViewCell: UICollectionViewCell {
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var selectImage: UIImageView!
    
    private var currentItem: FTUnSplashItem?
    
    func configure(with item: FTUnSplashItem) {
        if(currentItem?.id == item.id) {
            return
        }
        self.imageView.contentMode = .center
        self.imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.imageView.clipsToBounds = true
        
        currentItem = item
        self.imageView?.image = nil
        self.selectImage.isHidden = !self.isSelected
        if let urlStr = item.urls?.thumb {
            imageView.sd_setImage(with: URL(string: urlStr),
                                  placeholderImage: nil,
                                  options: SDWebImageOptions.refreshCached,
                                  completed: nil)
        }
    }
    
    override var isSelected: Bool {
        didSet {
            self.selectImage.isHidden = !self.isSelected
        }
    }
}
