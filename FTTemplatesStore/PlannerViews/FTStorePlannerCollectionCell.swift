//
//  FTTemplatesCollectionViewCell.swift
//  TempletesStore
//
//  Created by Siva on 13/02/23.
//

import UIKit
import SDWebImage

class FTStorePlannerCollectionCell: UICollectionViewCell {

    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var favorateImageView: UIImageView?
    @IBOutlet private weak var shadowImageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    // TODO: protocol approach
    func prepareCellWith(templateInfo: TemplateInfo) {
        self.thumbnail.image = nil
        shadowImageView.isHidden = true
        self.titleLabel.text = templateInfo.title
        thumbnail?.layer.cornerRadius = 2
        self.thumbnail.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1)
        let image = UIImage(named: "Template_shadow", in: storeBundle, with: .none)
        let scalled = image?.resizableImage(withCapInsets: UIEdgeInsets(top: 3, left: 4, bottom: 5, right: 4), resizingMode: .stretch)
        shadowImageView.image = scalled

        thumbnail?.sd_imageIndicator = SDWebImageActivityIndicator.gray
        thumbnail.contentMode = .scaleAspectFit
        let transformer = SDImageResizingTransformer(size: CGSize(width: 3 * CGFloat(self.frame.size.width), height: 3 * (self.frame.size.height - FTStoreConstants.StoreTemplate.extraHeightPadding)), scaleMode: .aspectFill)

        if let thumbnailUrl = templateInfo.thumbnailUrl {
            self.thumbnail?.sd_setImage(with: thumbnailUrl
                                        , placeholderImage: nil
                                        , options: .refreshCached
                                        , context: [.imageTransformer: transformer]
                                        , progress: nil
                                        , completed: {[weak self] _, error, _, _ in
                if error == nil {
                    self?.shadowImageView.isHidden = false
                }
            })
        }
//        let isFav = FTFavoriteTemplateHandler.shared.isFavoriteTemplate(template: templateInfo as! Template)
//        favorateImageView?.isHidden = isFav ? false : true
    }
}
