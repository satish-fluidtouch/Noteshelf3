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
    @IBOutlet weak var addFavoriteImageView: UIImageView!

    @IBOutlet private weak var penBottomConstraint: NSLayoutConstraint!

    private var currentViewSize = CGSize.zero
    private let borderWidth: CGFloat = 0.5
    private var favorite: FTPenSetProtocol?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.btnBg.layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if(currentViewSize != self.frame.size) {
            currentViewSize = self.frame.size
            self.layoutIfNeeded()
            self.btnBg.layer.cornerRadius = self.frame.size.width*0.5
            let penWidth = self.viewPenImage.bounds.width
            let maskLayer = CAShapeLayer()
            maskLayer.path = UIBezierPath(roundedRect: CGRect.init(x: 0, y: 0, width: penWidth, height: self.bounds.height + 20.0), byRoundingCorners: UIRectCorner.topLeft.union(.topRight), cornerRadii: CGSize(width: self.viewPenImage.frame.width / 2, height: self.viewPenImage.frame.height / 2)).cgPath // 20.0 is for pen to be extended outside
            self.viewPenImage.layer.mask = maskLayer
        }
    }

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

        self.btnBg.backgroundColor = UIColor(hexString: favorite.color, alpha: 0.3)
    }

    func configureEmptySlot() {
        self.imgShadow.image = nil
        self.imgMask.image = nil
        self.imgOverlay.image = nil
        self.imgEffect.image = nil
        self.isFavoriteSelected = false
    }

     var isFavoriteSelected: Bool = false {
        didSet {
            if self.isFavoriteSelected {
                self.btnBg.layer.borderWidth = borderWidth
                self.penBottomConstraint.constant = -12.0
                self.btnBg.backgroundColor = UIColor(hexString: self.favorite?.color ?? blackColorHex, alpha: 0.3)
            }
            else {
                self.btnBg.layer.borderWidth = 0.0
                self.penBottomConstraint.constant = 3.0
                self.btnBg.backgroundColor = UIColor.appColor(.favoriteEmptySlotColor)
            }
        }
    }
}

extension FTPenType {
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
            return "Favorites/ballpoint_color"
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
