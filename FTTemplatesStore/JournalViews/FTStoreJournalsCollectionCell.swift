//
//  FTStoreJournalsCollectionCell.swift
//  TempletesStore
//
//  Created by Siva on 13/02/23.
//

import UIKit
import SDWebImage
import FTCommon
import Combine

class FTStoreJournalsCollectionCell: UICollectionViewCell {

    @IBOutlet private weak var thumbnail: UIImageView!
    @IBOutlet private weak var shadowImageView: UIImageView!
    @IBOutlet private weak var titlrLabel: UILabel!
    @IBOutlet private weak var premiumView: UIView?

    private var cancellableAction: AnyCancellable?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func prepareCellWith(templateInfo: TemplateInfo) {
        self.shadowImageView.isHidden = true
        self.thumbnail.roundCorners(topLeft: 6, topRight: 16, bottomLeft: 6, bottomRight: 16)
        self.shadowImageView.roundCorners(topLeft: 6, topRight: 16, bottomLeft: 6, bottomRight: 16)

        self.thumbnail.image = nil
        self.thumbnail.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1)
        self.premiumView?.isHidden = FTStorePremiumPublisher.shared.premiumUser?.isPremiumUser ?? true;
        if nil == self.cancellableAction
            , let premiumUser = FTStorePremiumPublisher.shared.premiumUser
            , !premiumUser.isPremiumUser {
            self.cancellableAction = FTStorePremiumPublisher.shared.premiumUser?.$isPremiumUser.sink { [weak self] value in
                self?.premiumView?.isHidden = value;
            }
        }
        
        self.titlrLabel.text = templateInfo.title
        let image = UIImage(named: "Dairy_shadow", in: storeBundle, with: .none)
        let scalled = image?.resizableImage(withCapInsets: UIEdgeInsets(top: 8, left: 20, bottom: 32, right: 20), resizingMode: .stretch)
        shadowImageView.image = scalled

        thumbnail.sd_imageIndicator = SDWebImageActivityIndicator.gray
        if let thumbnailUrl = templateInfo.thumbnailUrl {
            self.thumbnail?.sd_setImage(with: thumbnailUrl
                                        , placeholderImage: nil
                                        , options: .refreshCached
                                        , completed: {[weak self] _, error, _, _ in
                if error == nil {
                    self?.shadowImageView.isHidden = false
                }
            })
        }
    }

    deinit {
        cancellableAction?.cancel();
    }
}
