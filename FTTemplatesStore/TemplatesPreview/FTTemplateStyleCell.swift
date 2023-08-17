//
//  FTTemplateStyleCell.swift
//  TempletesStore
//
//  Created by Siva on 08/03/23.
//

import Foundation
import UIKit
import SDWebImage

class FTTemplateStyleCell: UICollectionViewCell {

    @IBOutlet weak var thumbnail: UIImageView!

    override class func awakeFromNib() {
        super.awakeFromNib()
    }

    override var isSelected: Bool {
        didSet {
            contentView.layer.borderColor = isSelected ? UIColor.appColor(.accent).cgColor : UIColor.clear.cgColor
            contentView.layer.borderWidth = 2
            contentView.layer.cornerRadius = 4
        }
    }

    func prepareCellWith(style: FTTemplateStyle, template: TemplateInfo) {
        let fileUrl = style.styleThumbnailFor(template: template)
        self.thumbnail.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1)

        self.thumbnail.sd_setImage(with: fileUrl)
        self.thumbnail.contentMode = .scaleAspectFit
        self.thumbnail.layer.cornerRadius = 4
        self.thumbnail.clipsToBounds = true
    }

}
