//
//  FTPaperCollectionViewCell.swift
//  FTNewNotebook
//
//  Created by Ramakrishna on 02/03/23.
//

import UIKit
import PDFKit
import FTStyles

class FTPaperCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var shadowImage: UIImageView?
    @IBOutlet weak private var selectedImageView: UIImageView?
    @IBOutlet weak private var imgView: UIImageView?
    @IBOutlet weak private var themeTitle: UILabel?
    private var thumbnailColorHex: String?
    var isCellSelected: Bool = false {
        didSet {
            setBorderAndSelectionToThumbnail()
        }
    }
    func configureCellWith(title: String?, thumbnailColorHex:String){
        self.thumbnailColorHex = thumbnailColorHex
        let color = UIColor(hexWithAlphaString: thumbnailColorHex)
        self.applySelectedColorVariant(color)
        self.imgView?.image = UIImage(named: "samplePaperTemplateThumbnail", in: currentBundle, with: nil)?.withRenderingMode(.alwaysTemplate)
        self.themeTitle?.text = title ?? "Plain"
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
        guard let paperTheme = (themWithVariants.theme as? FTPaperThumbnailGenerator) else {
            return
        }
        let thumbnailSize = FTNewNotebook.Constants.ChoosePaperPanel.thumbnailRegularSize
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
            if var image = UIImage(named: imgName, in: currentBundle, with: nil)?.withRenderingMode(.alwaysOriginal) {
                self.imgView?.backgroundColor = color
                self.imgView?.image = image
            }
        }
    }
    private func getRequiredPortionOfImageAsThumnail(_ thumbnailImage: UIImage,
                                                     requiredRect:CGRect) -> UIImage {
        let pdfPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0] as NSString
            let pdfFilePath = pdfPath.appendingPathComponent("thumnailPDF.pdf")
            let pdfBounds = CGRect(x: 0, y: 0, width: thumbnailImage.size.width, height: thumbnailImage.size.height)
        UIGraphicsBeginPDFContextToFile(pdfFilePath, pdfBounds, nil)
        UIGraphicsBeginPDFPage()
        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: 0, y: thumbnailImage.size.height);
        context?.scaleBy(x: 1, y: -1);
        context!.draw(thumbnailImage.cgImage!, in: pdfBounds)
        UIGraphicsEndPDFContext()
        guard let pdf = PDFDocument(url: URL(fileURLWithPath: pdfFilePath)),
              let page = pdf.page(at: 0) else {
            fatalError("pdf page note found")
        }
        let renderer = UIGraphicsImageRenderer(size: requiredRect.size)
        let thumbImage = renderer.image { context in
            page.draw(with: PDFDisplayBox.cropBox, to: context.cgContext)
        }
        return thumbImage
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            setBorderAndSelectionToThumbnail()
        }
    }
}
