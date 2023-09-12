//
//  FTDefaultCustomCoverSectionCell.swift
//  FTNewNotebook
//
//  Created by Narayana on 01/03/23.
//

import UIKit
import FTCommon

class FTDefaultCustomCoverSectionCell: FTTraitCollectionViewCell {
    @IBOutlet weak var imgView: UIImageView?
    @IBOutlet weak var sectionTitleLabel: UILabel?

    @IBOutlet private weak var imgHeightConstraint: NSLayoutConstraint?

    func configureCell(with model: FTDefaultCustomSection) {
        self.imgView?.image = model.type.image
        self.imgView?.addShadow(color: UIColor.black.withAlphaComponent(0.2), offset: CGSize(width: 0.0, height: 8.0), opacity: 1.0, shadowRadius: 64.0)
        if model.type == .unsplash {
            let attributedString = NSMutableAttributedString()
            // Image
            let imageAttachment = NSTextAttachment()
            imageAttachment.image = UIImage(named: "unsplash_titleIcon", in: currentBundle, with: nil)?.withTintColor(.label)
            let imageSize = CGSize(width: 15, height: 15)
            imageAttachment.bounds = CGRect(origin: CGPoint(x: 0.0, y: -3.0), size: imageSize)
            let imageAttributedString = NSAttributedString(attachment: imageAttachment)
            attributedString.append(imageAttributedString)

            // Space
            let spacingString = NSAttributedString(string: " ", attributes: [.kern: 2])
            attributedString.append(spacingString)

            // Text
            let textAttributedString = NSAttributedString(string: model.type.displayName)
            attributedString.append(textAttributedString)
            self.sectionTitleLabel?.attributedText = attributedString
        } else {
            self.sectionTitleLabel?.text = model.type.displayName
        }
    }

    func configureCell(with image: UIImage, title: String = "") {
        self.imgView?.image = image
        self.sectionTitleLabel?.text = title
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if isRegular {
            self.imgHeightConstraint?.constant = FTCovers.Panel.CoverSize.regular.height
        } else {
            self.imgHeightConstraint?.constant = FTCovers.Panel.CoverSize.compact.height
        }
    }
    override open var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.transform = self.isSelected ? CGAffineTransform(scaleX: 0.98, y: 1.0) : .identity
            }
        }
    }
}
