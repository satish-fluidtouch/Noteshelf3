//
//  FTFavoritePenCollectionViewCell.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 03/10/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTFavoritePenCollectionViewCell: FTPenStyleCollectionViewCell {
    @IBOutlet weak var btnBg: UIButton!
    @IBOutlet weak var viewPenImage: UIView!

    @IBOutlet private weak var imgMask: UIImageView! // Mask
    @IBOutlet private weak var imgOverlay: UIImageView! // Color
    @IBOutlet private weak var imgShadow: UIImageView! // Shadow
    @IBOutlet private weak var imgEffect: UIImageView! // Effect

    @IBOutlet private weak var penBottomConstraint: NSLayoutConstraint!

    private var currentViewSize = CGSize.zero
    private var favorite: FTPenSetProtocol?

    func configure(favorite: FTPenSetProtocol, currentPenset: FTPenSetProtocol) {
        self.favorite = favorite

        self.imgShadow.image = UIImage(named: favorite.type.favShadowImageName, in: Bundle(for: FTFavoritePenCollectionViewCell.self), compatibleWith: nil)

        self.imgMask.image = UIImage(named: favorite.type.favMaskImageName, in: Bundle(for: FTFavoritePenCollectionViewCell.self), compatibleWith: nil)

        self.imgOverlay.image = UIImage(named: favorite.type.favOverlayImageName, in: Bundle(for: FTFavoritePenCollectionViewCell.self), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        self.imgOverlay.tintColor = self.increseBrightnessBy(0.10, for: favorite.color)

        self.imgEffect.image = UIImage(named: favorite.type.favEffectImageName, in: Bundle(for: FTFavoritePenCollectionViewCell.self), compatibleWith: nil)

        DispatchQueue.main.async {
            self.isFavoriteSelected = currentPenset.isEqual(favorite)
            self.imgShadow?.isHidden = !(self.isSelected)
        }
    }

    func configureEmptySlot() {
        self.imgShadow.image = nil
        self.imgMask.image = nil
        self.imgOverlay.image = nil
        self.imgEffect.image = nil
        self.isFavoriteSelected = false
    }

    private func selectedBottomConstraint() -> CGFloat {
        var value: CGFloat = -45.0
        if self.favorite?.type == .flatHighlighter {
            value = -40.0
        } else if self.favorite?.type == .highlighter {
            value = -36.0
        }
        return value
    }

     var isFavoriteSelected: Bool = false {
        didSet {
            if self.isFavoriteSelected {
                self.btnBg.backgroundColor = UIColor(hexString: self.favorite?.color ?? blackColorHex, alpha: 0.3)
                self.penBottomConstraint.constant = self.selectedBottomConstraint()
            }
            else {
                self.btnBg.backgroundColor = UIColor.appColor(.black5)
                self.penBottomConstraint.constant = -12
            }
        }
    }
}

private extension FTPenType {
    //Shadow
    var favShadowImageName: String {
        switch self {
        case .pilotPen: // Felt tip
            return "Favorites/felt_shadow"
        case .caligraphy: // Fountain
            return "Favorites/fountain_shadow"
        case .pen: // Ballpoint
            return "Favorites/ballpoint_shadow"
        case .pencil: // Pencil
            return "Favorites/pencil_shadow"
        case .highlighter:
            return "Favorites/highlighter_round_shadow"
        case .flatHighlighter:
            return "Favorites/highlighter_flat_shadow"
        default:
            return "Favorites/felt_tip_shadow";
        }
    }

    //Color
    var favOverlayImageName: String {
        switch self {
        case .pilotPen:
            return "Favorites/felt_color"
        case .caligraphy:
            return "Favorites/fountain_color"
        case .pen:
            return "PenRFavoritesack/ballpoint_color"
        case .pencil:
            return "Favorites/pencil_color"
        case .highlighter:
            return "Favorites/highlighter_round_color"
        case .flatHighlighter:
            return "Favorites/highlighter_flat_color"
        default:
            return "Favorites/ballpoint_color"
        }
    }

    //Mask
    var favMaskImageName: String {
        switch self {
        case .pilotPen:
            return "Favorites/felt_mask"
        case .caligraphy:
            return "Favorites/fountain_mask"
        case .pen:
            return "Favorites/ballpoint_mask"
        case .pencil:
            return "Favorites/pencil_mask"
        case .highlighter:
            return "Favorites/highlighter_round_mask"
        case .flatHighlighter:
            return "Favorites/highlighter_flat_mask"
        default:
            return "Favorites/pilot_mask"
        }
    }

    var favEffectImageName: String {
        switch self {
        case .pilotPen:
            return "Favorites/felt_effect"
        case .caligraphy:
            return "Favorites/fountain_effect"
        case .pen:
            return "Favorites/ballpoint_effect"
        case .pencil:
            return "Favorites/pencil_effect"
        case .highlighter:
            return "Favorites/highlighter_round_effect"
        case .flatHighlighter:
            return "Favorites/highlighter_flat_effect"
        default:
            return "Favorites/ballpoint_effect"
        }
    }
}
