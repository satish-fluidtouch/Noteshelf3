//
//  FTSavedClipsCollectionViewCell.swift
//  Noteshelf3
//
//  Created by Siva on 21/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTSavedClipsCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var closeButton: UIButton!
    var deleteSavedClip:((_ clip: FTSavedClipModel) -> Void)?
    private var clip: FTSavedClipModel?

    func configureCellWith(clip: FTSavedClipModel, isEditing: Bool)  {
        self.clip = clip
        self.contentView.backgroundColor = .white
        self.contentView.layer.cornerRadius = 8
        self.contentView.layer.borderColor = UIColor.appColor(.grayDim).cgColor
        self.contentView.layer.borderWidth = 1.0
        self.thumbnail.contentMode = .center
        if let image = clip.image {
            if thumbnail.bounds.width < image.size.width || thumbnail.bounds.height < image.size.height {
                let width = min(image.size.width, image.size.height)
                let cropped = image.croppedImage(at: CGRect(origin: .zero, size: CGSize(width: width, height: width)))
                self.thumbnail.image = cropped
            } else {
                self.thumbnail.image = image
            }
        }

        if isEditing {
            closeButton.isHidden = false
            startWiggle()
        } else {
            closeButton.isHidden = true
            stopWiggle()
        }
    }

    @IBAction func closeAction(_ sender: Any) {
        if let clip {
            deleteSavedClip?(clip)
        }
    }
}
