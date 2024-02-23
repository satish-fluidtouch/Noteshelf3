//
//  FTLinkPageThumbnailCell.swift
//  Noteshelf3
//
//  Created by Narayana on 12/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTLinkPageThumbnailCell: FTFinderThumbnailViewCell {
    private var borderPath: CGPath?

    private lazy var borderLayer: CAShapeLayer = {
        let borderLayer = CAShapeLayer()
        borderLayer.frame = self.imageViewPage?.bounds ?? .zero
        borderLayer.fillColor = nil
        return borderLayer
    }()

    var isPageSelected: Bool = false {
        didSet {
            if isPageSelected {
                self.borderLayer.strokeColor = UIColor.appColor(.accent).cgColor
                self.borderLayer.lineWidth = 4.0
                let path = self.imageViewPage?.roundCorners(topLeft: 10, topRight: 10, bottomLeft: 10, bottomRight: 10)
                self.borderLayer.path = path
                self.borderLayer.cornerRadius = self.imageViewPage?.layer.cornerRadius ?? 0.0
                self.selectionBadge?.isHidden = false
            } else {
                self.selectionBadge?.isHidden = true
                self.borderLayer.lineWidth = 0.0
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionBadge?.isHidden = true
        let path = self.imageViewPage?.roundCorners(topLeft: 10, topRight: 10, bottomLeft: 10, bottomRight: 10)
        self.borderLayer.path = path
        self.imageViewPage?.layer.addSublayer(borderLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let path = self.imageViewPage?.roundCorners(topLeft: 10, topRight: 10, bottomLeft: 10, bottomRight: 10)
        self.borderLayer.path = path
        self.borderLayer.cornerRadius = self.imageViewPage?.layer.cornerRadius ?? 0.0
    }
}
