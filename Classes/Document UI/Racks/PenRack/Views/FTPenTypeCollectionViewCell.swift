//
//  FTPenTypeCollectionViewCell.swift
//  FTPenRack
//
//  Created by Siva on 08/04/17.
//  Copyright © 2017 Fluid Touch Pvt Ltd. All rights reserved.
//

import UIKit
import FTCommon

enum FTPenTypeDisplayMode: String {
    case penRack
    case favoriteEditRack
}

class FTPenTypeCollectionViewCell: FTPenStyleCollectionViewCell {
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

    var displayMode = FTPenTypeDisplayMode.penRack

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

    func configure(penType: FTPenType, currentPenSet: FTPenSetProtocol, color: String) {
        self.penColor = color
        self.penType = penType

        self.imageViewShadow.image = UIImage(named: penType.shadowImageName, in: Bundle(for: FTPenTypeCollectionViewCell.self), compatibleWith: nil)

        self.imageViewIconMask.image = UIImage(named: penType.maskImageName, in: Bundle(for: FTPenTypeCollectionViewCell.self), compatibleWith: nil)

        self.imageViewIconOverlay.image = UIImage(named: penType.overlayImageName, in: Bundle(for: FTPenTypeCollectionViewCell.self), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)

        self.imageViewEffect.image = UIImage(named: penType.effectImageName, in: Bundle(for: FTPenTypeCollectionViewCell.self), compatibleWith: nil)
        self.imageViewNoiseTop.image = UIImage(named: penType.noiseTopImageName, in: Bundle(for: FTPenTypeCollectionViewCell.self), compatibleWith: nil)
        self.imageViewNoiseBottom.image = UIImage(named: penType.noiseBottomImageName, in: Bundle(for: FTPenTypeCollectionViewCell.self), compatibleWith: nil)

        self.imageViewNoiseTop.alpha = UIColor(hexString: color).isLightColor() ? 0.1 : 0.16
        self.isPenTypeSelected = currentPenSet.type == penType
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

    var isPenTypeSelected: Bool = false {
        didSet {
            self.imageViewIconOverlay.tintColor = self.increseBrightnessBy(0.10, for: self.penColor ?? blackColorHex)
            self.imageViewShadow?.isHidden = !(self.isPenTypeSelected)
            if self.isPenTypeSelected {
                self.buttonBackground.backgroundColor = UIColor(hexString: self.penColor ?? blackColorHex, alpha: 0.3)
                self.penBottomConstraint.constant = self.selectedBottomConstraint()
            }
            else {
                self.buttonBackground.backgroundColor = UIColor.appColor(.black5)
                self.penBottomConstraint.constant = -12
                if self.displayMode == .favoriteEditRack {
                    self.imageViewIconOverlay.tintColor = UIColor.appColor(.black10)
                }
            }
        }
    }
}

class FTPenStyleCollectionViewCell: UICollectionViewCell {
    func increseBrightnessBy(_ factor: CGFloat, for hexString: String) -> UIColor {
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

private extension FTPenType {
    //Shadow
    var shadowImageName: String {
        switch self {
        case .pilotPen: // Felt tip
            return "PenRack/felt_shadow"
        case .caligraphy: // Fountain
            return "PenRack/fountain_shadow"
        case .pen: // Ballpoint
            return "PenRack/ballpoint_shadow"
        case .pencil: // Pencil
            return "PenRack/pencil_shadow"
        case .highlighter:
            return "PenRack/highlighter_round_shadow"
        case .flatHighlighter:
            return "PenRack/highlighter_flat_shadow"
        default:
            return "PenRack/felt_tip_shadow";
        }
    }

    //Color
    var overlayImageName: String {
        switch self {
        case .pilotPen:
            return "PenRack/felt_color"
        case .caligraphy:
            return "PenRack/fountain_color"
        case .pen:
            return "PenRack/ballpoint_color"
        case .pencil:
            return "PenRack/pencil_color"
        case .highlighter:
            return "PenRack/highlighter_round_color"
        case .flatHighlighter:
            return "PenRack/highlighter_flat_color"
        default:
            return "PenRack/ballpoint_color"
        }
    }

    //Mask
    var maskImageName: String {
        switch self {
        case .pilotPen:
            return "PenRack/felt_mask"
        case .caligraphy:
            return "PenRack/fountain_mask"
        case .pen:
            return "PenRack/ballpoint_mask"
        case .pencil:
            return "PenRack/pencil_mask"
        case .highlighter:
            return "PenRack/highlighter_round_mask"
        case .flatHighlighter:
            return "PenRack/highlighter_flat_mask"
        default:
            return "PenRack/pilot_mask"
        }
    }

    var effectImageName: String {
        switch self {
        case .pilotPen:
            return "PenRack/felt_effect"
        case .caligraphy:
            return "PenRack/fountain_effect"
        case .pen:
            return "PenRack/ballpoint_effect"
        case .pencil:
            return "PenRack/pencil_effect"
        case .highlighter:
            return "PenRack/highlighter_round_effect"
        case .flatHighlighter:
            return "PenRack/highlighter_flat_effect"
        default:
            return "PenRack/ballpoint_effect"
        }
    }

    var noiseTopImageName: String {
        switch self {
        case .pilotPen:
            return "PenRack/felt_noiseTop"
        case .caligraphy:
            return "PenRack/fountain_noiseTop"
        case .pen:
            return "PenRack/ballpoint_noiseTop"
        case .pencil:
            return "PenRack/pencil_noiseTop"
        case .highlighter:
            return "PenRack/highlighter_round_noiseTop"
        case .flatHighlighter:
            return "PenRack/highlighter_flat_noiseTop"
        default:
            return "PenRack/pilot_noiseTop"
        }
    }

    var noiseBottomImageName: String {
        switch self {
        case .pilotPen:
            return "PenRack/felt_noiseBottom"
        case .caligraphy:
            return "PenRack/fountain_noiseBottom"
        case .pen:
            return "PenRack/ballpoint_noiseBottom"
        case .pencil:
            return "PenRack/pencil_noiseBottom"
        case .highlighter:
            return "PenRack/highlighter_round_noiseBottom"
        case .flatHighlighter:
            return "PenRack/highlighter_flat_noiseBottom"
        default:
            return "PenRack/pilot_noiseBottom"
        }
    }
}
