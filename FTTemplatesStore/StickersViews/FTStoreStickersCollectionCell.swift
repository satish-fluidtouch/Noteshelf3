//
//  FTStoreStickersCollectionCell.swift
//  TempletesStore
//
//  Created by Siva on 20/04/23.
//

import UIKit
import SDWebImage

class FTStoreStickersCollectionCell: UICollectionViewCell {
    @IBOutlet private weak var thumbnail: UIImageView?
    @IBOutlet private weak var titleLabel: UILabel?
    @IBOutlet private weak var shadowImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func prepareCellWith(templateInfo: TemplateInfo) {
        self.shadowImageView.isHidden = true
        self.titleLabel?.text = templateInfo.title
        self.thumbnail?.image = nil
        self.thumbnail?.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1)
        self.thumbnail?.layer.cornerRadius = 2

        let image = UIImage(named: "Banner_shadow", in: storeBundle, with: .none)
        let scalled = image?.resizableImage(withCapInsets: UIEdgeInsets(top: 20, left: 30, bottom: 40, right: 30), resizingMode: .stretch)
        shadowImageView.image = scalled

        thumbnail?.sd_imageIndicator = SDWebImageActivityIndicator.gray
        if templateInfo.type == FTDiscoveryItemType.userJournals.rawValue {
            if let thumbnailUrl = templateInfo.thumbnailUrl {
                self.thumbnail?.sd_setImage(with: thumbnailUrl, completed: {[weak self] _, error, _, _ in
                    if error == nil {
                        self?.shadowImageView.isHidden = false
                    }
                })
            }
        } else if let thumbnailUrl = (templateInfo as! DiscoveryItem).stickersThumbnailUrl {
            self.thumbnail?.sd_setImage(with: thumbnailUrl, completed: {[weak self] _, error, _, _ in
                if error == nil {
                    self?.shadowImageView.isHidden = false
                }
            })
        }

    }

}
