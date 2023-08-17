//
//  FTCoverStyleCollectionViewCell.swift
//  FTNewNotebook
//
//  Created by Narayana on 24/02/23.
//

import UIKit
import FTStyles

class FTCoverStyleCollectionViewCell: UICollectionViewCell {
    @IBOutlet private weak var imgView: UIImageView!
    private let config = FTCoverStyleVariantConfig()

    override var isSelected: Bool {
        didSet {
            if let borderLayer = self.imgView.layer.sublayers?.first(where: { layer in
                layer.name == config.borderLayerId
            }) {
                if isSelected {
                    borderLayer.frame = self.imgView.frame.insetBy(dx: -config.borderWidthSelected, dy: -config.borderWidthSelected)
                    borderLayer.borderWidth = config.borderWidthSelected
                    borderLayer.cornerRadius = config.cornerRadiusSelected
                } else {
                    borderLayer.frame = .zero
                    borderLayer.frame = self.imgView.frame.insetBy(dx: -config.borderWidthUnSelected, dy: -config.borderWidthUnSelected)
                    borderLayer.borderWidth = config.borderWidthUnSelected
                    borderLayer.cornerRadius = config.cornerRadiusUnSelected
                }
            }
        }
    }

    private func addBorderLayer() {
        let borderLayer = CALayer()
        borderLayer.name = config.borderLayerId
        borderLayer.borderWidth = config.borderWidthUnSelected
        borderLayer.borderColor = UIColor.appColor(.black20).cgColor
        borderLayer.cornerRadius = config.cornerRadiusUnSelected
        borderLayer.frame = self.imgView.frame.insetBy(dx: config.borderWidthUnSelected, dy: config.borderWidthUnSelected)
        self.imgView?.layer.addSublayer(borderLayer)
    }

    func configure(with imageName: String, isSelected: Bool) {
        self.imgView.image = UIImage(named: imageName, in: currentBundle, with: nil)
        self.addBorderLayer()
        self.isSelected = isSelected
    }
}
