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
    private let config = FTCoverStyleConfig()
    private var borderPath: CGPath?

     var isCoverSelected: Bool = false {
        didSet {
            if isCoverSelected {
                self.addBorderLayer()
                self.selectionImgView?.isHidden = false
            } else {
                self.removeBorderLayerIfExists()
                self.selectionImgView?.isHidden = true
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

    private func getBorderLayerIfExists() -> CAShapeLayer? {
        var layer: CAShapeLayer?
        if let borderLayer = self.imgView.layer.sublayers?.first(where: { layer in
            layer.name == config.borderLayerId
        }) as? CAShapeLayer {
            layer = borderLayer
        }
        return layer
    }

    private func removeBorderLayerIfExists() {
        if let layer = self.getBorderLayerIfExists() {
            layer.removeFromSuperlayer()
        }
    }

    private func addBorderLayer() {
        self.removeBorderLayerIfExists()
        if let path = self.borderPath {
            let borderLayer = CAShapeLayer()
            borderLayer.frame = self.imgView.bounds
            borderLayer.path  = path
            borderLayer.name = config.borderLayerId
            borderLayer.lineWidth = config.borderWidthSelected
            borderLayer.strokeColor = config.borderColor
            borderLayer.fillColor   = UIColor.clear.cgColor
            self.imgView.layer.addSublayer(borderLayer)
        }
    }

    func configureCell(with model: FTCoverThemeModel?, title: String = "", isSelected: Bool = false) {
        self.sectionTitleLabel?.text = title
        self.model = model

        if let theme = model {
            let img = theme.thumbnail();
            self.imgView?.image = img;
        }
        self.updateShadowImage()
        self.layoutIfNeeded()
        if let model = self.model, model.themeable.hasCover { // no cover
            let thumbnailRadius = FTCovers.ThumbnailCoverRadius.self
            self.borderPath = self.imgView.roundCorners(topLeft: thumbnailRadius.topLeft, topRight: thumbnailRadius.topRight, bottomLeft: thumbnailRadius.bottomLeft, bottomRight: thumbnailRadius.bottomRight)
        } else {
            let radius: CGFloat = 10.0
            self.borderPath = self.imgView.roundCorners(topLeft: radius, topRight: radius, bottomLeft: radius, bottomRight: radius)
        }
        DispatchQueue.main.async {
            self.isCoverSelected = isSelected
        }
    }

    fileprivate func updateShadowImage() {
        if let model = self.model, !model.themeable.hasCover {
            self.shadowImageView?.image = UIImage(named: "nocover_shadow", in: currentBundle, with: nil)
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
