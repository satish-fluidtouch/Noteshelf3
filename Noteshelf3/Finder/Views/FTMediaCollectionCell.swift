//
//  FTMediaCollectionCell.swift
//  Noteshelf3
//
//  Created by Sameer on 23/08/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

fileprivate let imageCache = NSCache<AnyObject, AnyObject>()

class FTMediaCollectionViewCell: UICollectionViewCell {
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var thumbnailImage: UIImageView?
    @IBOutlet var gradientImage: UIImageView?
    weak var delegate: FTMediaDelegate?
    
    func configureCell(_ object: FTMediaItem, index: Int, delegate: FTMediaViewController) {
        self.delegate = delegate
        self.thumbnailImage?.image = nil
        self.thumbnailImage?.backgroundColor = .clear
        self.thumbnailImage?.contentMode = .scaleAspectFill
        titleLabel?.text = "\(index)"
        if let annotation = object.annotation {
            let identifier = annotation.uuid
            if let imageFromCache = imageCache.object(forKey: identifier as AnyObject) as? UIImage {
                thumbnailImage?.image = imageFromCache
            } else {
                if let imageTypeAnn = object.annotation as? FTImageAnnotation, let image = imageTypeAnn.image?.preparingThumbnail(of: CGSize(width: 400, height: 400)) {
                    imageCache.setObject(image, forKey: identifier as AnyObject)
                    thumbnailImage?.image = image
                }
            }
        }
    }

}
