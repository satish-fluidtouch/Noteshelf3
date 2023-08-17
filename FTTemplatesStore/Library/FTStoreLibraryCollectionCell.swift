//
//  FTStoreLibraryCollectionCell.swift
//  TempletesStore
//
//  Created by Siva on 16/03/23.
//

import UIKit
import SDWebImage
import FTCommon

class FTStoreLibraryCollectionCell: UICollectionViewCell {

    @IBOutlet weak var thumbnail: UIImageView?
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet private weak var shadowImageView: UIImageView!
    var sourceType: Source = .none

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override var isSelected: Bool {
        didSet {
            if sourceType == .shelf {
                self.thumbnail?.layer.borderColor = isSelected ? UIColor.appColor(.accent).cgColor : UIColor.clear.cgColor
                self.thumbnail?.layer.borderWidth = 2
            }
        }
    }

    // TODO: protocol approach
    func prepareCellWith(style: FTTemplateStyle, sourceType: Source) {
        self.sourceType = sourceType
        self.thumbnail?.image = nil
        self.titleLabel?.text = style.title
        thumbnail?.layer.cornerRadius = 2

        self.thumbnail?.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1)
        let image = UIImage(named: "Template_shadow", in: storeBundle, with: .none)
        let scalled = image?.resizableImage(withCapInsets: UIEdgeInsets(top: 3, left: 4, bottom: 5, right: 4), resizingMode: .stretch)
        shadowImageView.image = scalled

        thumbnail?.sd_imageIndicator = SDWebImageActivityIndicator.gray
        let fileUrl = style.thumbnailPath()
        self.thumbnail?.sd_setImage(with: fileUrl)
    }
}
