//
//  FTCOverCollectionViewCell.swift
//  FTNewNotebook
//
//  Created by Narayana on 27/02/23.
//

import UIKit
import FTCommon

class FTCoverCollectionViewCell: FTTraitCollectionViewCell {
    @IBOutlet fileprivate weak var imgView: UIImageView!
    @IBOutlet fileprivate weak var selectionImgView: UIImageView?
    @IBOutlet fileprivate weak var sectionTitleLabel: UILabel?
    @IBOutlet fileprivate weak var shadowImageView: UIImageView?
    @IBOutlet private weak var imgHeightConstraint: NSLayoutConstraint?

    private var model: FTCoverThemeModel?
    private var borderPath: CGPath?

    private lazy var borderLayer: CAShapeLayer = {
        let borderLayer = CAShapeLayer()
        borderLayer.frame = self.imgView.bounds
        borderLayer.fillColor = nil
        return borderLayer
    }()

     var isCoverSelected: Bool = false {
        didSet {
            self.borderLayer.lineDashPattern = []
            self.borderLayer.path = borderPath
            self.borderLayer.strokeColor = UIColor.appColor(.accent).cgColor
            if isCoverSelected {
                self.borderLayer.lineWidth = 6.0
                self.selectionImgView?.isHidden = false
            } else {
                self.selectionImgView?.isHidden = true
                if let model = self.model, model.themeable.hasCover {
                    self.borderLayer.lineWidth = 0.0
                } else {
                    self.borderLayer.lineWidth = 2.0
                    self.borderLayer.strokeColor = UIColor.appColor(.black10).cgColor
                    self.borderLayer.lineDashPattern = [4,4]
                }
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if isRegular {
            self.imgHeightConstraint?.constant = FTCovers.Panel.CoverSize.regular.height
        } else {
            self.imgHeightConstraint?.constant = FTCovers.Panel.CoverSize.compact.height
        }
    }

    func configureCell(with model: FTCoverThemeModel?, title: String = "", isSelected: Bool = false) {
        self.sectionTitleLabel?.text = title
        self.model = model
        self.imgView.layer.addSublayer(borderLayer)

        if let theme = model {
            let img = theme.thumbnail()
            self.imgView?.image = img
        }
        self.updateShadowImage()
        self.layoutIfNeeded()
        if let model = self.model, model.themeable.hasCover {
            let thumbnailRadius = FTCovers.ThumbnailCoverRadius.self
            self.borderPath = self.imgView.roundCorners(topLeft: thumbnailRadius.topLeft, topRight: thumbnailRadius.topRight, bottomLeft: thumbnailRadius.bottomLeft, bottomRight: thumbnailRadius.bottomRight)
        }
        else {
            let radius: CGFloat = 6.0
            self.borderPath = self.imgView.roundCorners(topLeft: radius, topRight: radius, bottomLeft: radius, bottomRight: radius)
        }
        self.isCoverSelected = isSelected
    }

    fileprivate func updateShadowImage() {
        if let model = self.model, !model.themeable.hasCover {
            self.shadowImageView?.image = nil
        }
        let scalled = self.shadowImageView?.image?.resizableImage(withCapInsets: UIEdgeInsets(top: 6, left: 14, bottom: 23, right: 14), resizingMode: .stretch)
        self.shadowImageView?.image = scalled
    }
}

class FTCustomSectionCell: FTCoverCollectionViewCell {
    func configureSection(_ section: FTCoverSectionModel) {
        self.sectionTitleLabel?.text = section.name
        self.selectionImgView?.isHidden = true
        if section.sectionType == .custom { // safe check
            self.imgView?.image = UIImage(named: section.variantImageName, in: currentBundle, with: nil)
            self.updateShadowImage()
        }
    }
}
