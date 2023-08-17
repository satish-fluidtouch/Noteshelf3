//
//  FTPenTypeCollectionViewCell.swift
//  FTPenRack
//
//  Created by Siva on 08/04/17.
//  Copyright © 2017 Fluid Touch Pvt Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTPenTypeCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var buttonBackground: UIButton!
    @IBOutlet weak var viewPenImage: UIView!

    @IBOutlet private weak var imageViewIconMask: UIImageView! // Mask
    @IBOutlet private weak var imageViewIconOverlay: UIImageView! // Color
    @IBOutlet private weak var imageViewShadow: UIImageView! // Shadow
    @IBOutlet private weak var imageViewEffect: UIImageView! // Effect
    @IBOutlet private weak var imageViewNoiseBottom: UIImageView! // bottom noise
    @IBOutlet private weak var imageViewNoiseTop: UIImageView! // top noise

    @IBOutlet private weak var penBottomConstraint: NSLayoutConstraint!
    
    private var currentViewSize = CGSize.zero
    private var penColor: String?
    private var penType: FTPenType?

    override func awakeFromNib() {
        self.imageViewNoiseTop?.layer.compositingFilter = "multiplyBlendMode"
        self.imageViewNoiseBottom?.layer.compositingFilter = "multiplyBlendMode"
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if(currentViewSize != self.frame.size) {
            currentViewSize = self.frame.size
            self.layoutIfNeeded()
            self.buttonBackground.layer.cornerRadius = self.frame.size.width*0.5
            self.buttonBackground.layer.borderWidth = 0.5
            self.buttonBackground.layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor

            let penWidth = self.isRegularTrait() ? self.bounds.width : self.viewPenImage.bounds.width

            let maskLayer = CAShapeLayer()
            maskLayer.path = UIBezierPath(roundedRect: CGRect.init(x: 0, y: 0, width: penWidth, height: self.bounds.height), byRoundingCorners: UIRectCorner.topLeft.union(.topRight), cornerRadii: CGSize(width: self.viewPenImage.frame.width / 2, height: self.viewPenImage.frame.height / 2)).cgPath
            self.viewPenImage.layer.mask = maskLayer
        }
    }

    func configure(penType: FTPenType, penSet: FTPenSetProtocol, color: String) {
        self.penColor = color
        self.penType = penType

        self.imageViewShadow.image = UIImage(named: penType.shadowImageName, in: Bundle(for: FTPenTypeCollectionViewCell.self), compatibleWith: nil)

        self.imageViewIconMask.image = UIImage(named: penType.maskImageName, in: Bundle(for: FTPenTypeCollectionViewCell.self), compatibleWith: nil)

        self.imageViewIconOverlay.image = UIImage(named: penType.overlayImageName, in: Bundle(for: FTPenTypeCollectionViewCell.self), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        self.imageViewIconOverlay.tintColor = self.increseBrightnessBy(0.10, for: color)

        self.imageViewEffect.image = UIImage(named: penType.effectImageName, in: Bundle(for: FTPenTypeCollectionViewCell.self), compatibleWith: nil)
        self.imageViewNoiseTop.image = UIImage(named: penType.noiseTopImageName, in: Bundle(for: FTPenTypeCollectionViewCell.self), compatibleWith: nil)
        self.imageViewNoiseBottom.image = UIImage(named: penType.noiseBottomImageName, in: Bundle(for: FTPenTypeCollectionViewCell.self), compatibleWith: nil)

        self.imageViewNoiseTop.alpha = UIColor(hexString: color).isLightColor() ? 0.1 : 0.16

        DispatchQueue.main.async {
            self.isSelected = penSet.type == penType
            self.imageViewShadow?.isHidden = !(self.isSelected)
        }
    }

    private func selectedBottomConstraint() -> CGFloat {
        var value: CGFloat = -45.0
        if self.penType == .flatHighlighter {
            value = -40.0
        } else if self.penType == .highlighter {
            value = -36.0
        }
        return value
    }

    override var isSelected: Bool {
        didSet {
            if self.isSelected {
                self.buttonBackground.backgroundColor = UIColor(hexString: self.penColor ?? blackColorHex, alpha: 0.3)
                self.penBottomConstraint.constant = self.selectedBottomConstraint()
            }
            else {
                self.buttonBackground.backgroundColor = UIColor.appColor(.black5)
                self.penBottomConstraint.constant = -12
            }
        }
    }

   private func increseBrightnessBy(_ factor: CGFloat, for hexString: String) -> UIColor {
        let color = UIColor(hexString: hexString)

        var hue: CGFloat = 0.0
        var saturation: CGFloat = 0.0
        var brightness: CGFloat = 0.0
        var alpha: CGFloat = 0.0

        if color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            brightness += factor
            return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
        }
        return color
    }
}
