//
//  FTMediaCollectionCell.swift
//  Noteshelf3
//
//  Created by Sameer on 23/08/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

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
        let type = object.mediaType
        if type == .photo, let imageAnn = object.annotation as? FTImageAnnotation, let image = imageAnn.image {
            thumbnailImage?.image = image
        } else if let stickerAnnotation = object.annotation as? FTStickerAnnotation, let image = stickerAnnotation.image {
            thumbnailImage?.image = image
        } else if let webclipAnnotation = object.annotation as? FTWebClipAnnotation, let image = webclipAnnotation.image {
            thumbnailImage?.image = image
        } else if type == .audio {
//            self.durationLbl?.text = object.duration
//            self.thumbnail?.image = object.getImage()
//            self.thumbnail?.backgroundColor = collection?.journalColor
        }
    }

}
