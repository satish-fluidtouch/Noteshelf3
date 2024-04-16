//
//  FTPaperCollectionViewCell.swift
//  FTNewNotebook
//
//  Created by Ramakrishna on 02/03/23.
//

import UIKit
import PDFKit
import FTStyles
import FTCommon

class FTPaperCollectionViewCell: FTTraitCollectionViewCell {
    @IBOutlet weak var shadowImage: UIImageView?
    @IBOutlet weak private var selectedImageView: UIImageView?
    @IBOutlet weak private var imgView: UIImageView?
    @IBOutlet weak private var themeTitle: UILabel?
    @IBOutlet private weak var imgWidthConstraint: NSLayoutConstraint?
    
    private var paperPickerMode: FTPaperPickerMode = .paperPicker

    private var thumbnailColorHex: String?
    var isCellSelected: Bool = false {
        didSet {
            setBorderAndSelectionToThumbnail()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.updateImgWidthConstraint()
    }

    func updateImgWidthConstraint() {
        if self.paperPickerMode == .paperPicker {
            self.imgWidthConstraint?.constant = self.isRegular ? 120 : 100
        } else {
            self.imgWidthConstraint?.constant = 120
        }
    }

    func configureCellWith(title: String?, thumbnailColorHex:String, mode: FTPaperPickerMode){
        self.paperPickerMode = mode
        self.thumbnailColorHex = thumbnailColorHex
        let color = UIColor(hexWithAlphaString: thumbnailColorHex)
        self.applySelectedColorVariant(color)
        self.imgView?.image = UIImage(named: "samplePaperTemplateThumbnail", in: currentBundle, with: nil)?.withRenderingMode(.alwaysTemplate)
        self.themeTitle?.text = title ?? "Plain"
        self.updateImgWidthConstraint()
    }
    private func applyBorderToThemeImage(){
        self.imgView?.layer.borderWidth = 1.0
        self.imgView?.layer.borderColor = UIColor.appColor(.paperThemeBorderTint).cgColor
    }
    func applySelectedColorVariant(_ color: UIColor){
        self.imgView?.tintColor = color
    }
    private func applySelectedBorderToThemeImage(){
        self.imgView?.layer.borderWidth = 3.0
        self.imgView?.layer.borderColor = FTNewNotebook.Constants.SelectedAccent.tint.cgColor
    }
    private func setBorderAndSelectionToThumbnail(){
        self.selectedImageView?.image = UIImage(named: "selection_checkMark")
        if isCellSelected  {
            if let selectedImg  = self.selectedImageView {
                self.bringSubviewToFront(selectedImg)
                self.selectedImageView?.isHidden = false
            }
            applySelectedBorderToThemeImage()
            applyShadowToSelectedThumbnail()
        }    else {
            self.selectedImageView?.isHidden = true
            applyBorderToThemeImage()
            removeShadowForTHumbnail()
        }
    }
    private func applyShadowToSelectedThumbnail() {
        self.shadowImage?.layer.masksToBounds = false
        self.shadowImage?.layer.shadowRadius = 30.0
        self.shadowImage?.layer.shadowOffset = CGSize(width: 0, height: 10)
        self.shadowImage?.layer.shadowColor = UIColor.appColor(.black16).cgColor
        self.shadowImage?.layer.shadowOpacity = 1
        shadowImage?.layer.shadowPath = UIBezierPath(rect: imgView?.bounds ?? .zero).cgPath
    }
    private func removeShadowForTHumbnail() {
        self.shadowImage?.layer.masksToBounds = true
        self.shadowImage?.layer.shadowOpacity = 0
        self.shadowImage?.layer.shadowColor = UIColor.clear.cgColor
    }
    func thumbnailForVariantsAndTheme(_ variantsAndTheme: FTSelectedPaperVariantsAndTheme)  {
        var themWithVariants: FTSelectedPaperVariantsAndTheme = variantsAndTheme
        themWithVariants.orientation = .portrait
        var imgName = variantsAndTheme.thumbImagePrefix
        if !imgName.isEmpty {
            let color = UIColor(hexWithAlphaString: variantsAndTheme.templateColorModel.hex)
            if variantsAndTheme.templateColorModel.color == .legal {
                imgName = imgName + "_legal"
            } else {
                if color.isLightColor() {
                    imgName = imgName + "_light"
                } else {
                    imgName = imgName + "_dark"
                }
            }
            if let image = UIImage(named: imgName, in: currentBundle, with: nil)?.withRenderingMode(.alwaysOriginal) {
                self.imgView?.backgroundColor = color
                self.imgView?.image = image
            }
        }
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            setBorderAndSelectionToThumbnail()
        }
    }
}
