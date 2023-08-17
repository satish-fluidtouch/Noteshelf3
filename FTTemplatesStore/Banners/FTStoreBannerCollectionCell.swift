//
//  FTStoreBannerCollectionCell.swift
//  FTTemplatesStore
//
//  Created by Siva on 05/05/23.
//

import UIKit
import SDWebImage

class FTStoreBannerCollectionCell: UICollectionViewCell {
    @IBOutlet weak var thumbnail: UIImageView?
    @IBOutlet private weak var shadowImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func prepareCellWith(templateInfo: TemplateInfo) {
        self.shadowImageView.isHidden = true
        self.thumbnail?.image = nil
        self.thumbnail?.layer.cornerRadius = 2
        self.thumbnail?.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1)
        let image = UIImage(named: "Banner_shadow", in: storeBundle, with: .none)

        let scalled = image?.resizableImage(withCapInsets: UIEdgeInsets(top: 20, left: 30, bottom: 40, right: 30), resizingMode: .stretch)
        shadowImageView.image = scalled

        thumbnail?.sd_imageIndicator = SDWebImageActivityIndicator.gray
        if let thumbnailUrl = (templateInfo as! DiscoveryItem).bannerAndCategoryThumbnailUrl {
            self.thumbnail?.sd_setImage(with: thumbnailUrl, completed: { [weak self] _, error, _, _ in
                if error == nil {
                    self?.shadowImageView.isHidden = false
                }
            })
        }
    }

}
