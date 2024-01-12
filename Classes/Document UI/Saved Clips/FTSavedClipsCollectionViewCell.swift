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
    var deleteSavedClip:(() -> Void)?

    func configureCellWith(clip: FTSavedClipModel, isEditing: Bool)  {
        self.contentView.backgroundColor = .white
        self.contentView.layer.cornerRadius = 8
        self.contentView.layer.borderColor = UIColor.appColor(.grayDim).cgColor
        self.contentView.layer.borderWidth = 1.0
        if let image = clip.image {
            self.thumbnail.image = image
        }

        if isEditing {
            closeButton.isHidden = false
            startWiggle()
        } else {
            closeButton.isHidden = true
            stopWiggle()
        }
    }

    @objc func startWiggle(_ notification:Notification) {
        closeButton.isHidden = false
        self.startWiggle()
    }

    @objc func stopWiggle(_ notification:Notification) {
        closeButton.isHidden = true
          self.stopWiggle()
      }

    @IBAction func closeAction(_ sender: Any) {
        deleteSavedClip?()
    }
}
