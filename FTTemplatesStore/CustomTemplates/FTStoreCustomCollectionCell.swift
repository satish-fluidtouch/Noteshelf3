//
//  FTStoreCustomCollectionCell.swift
//  TempletesStore
//
//  Created by Siva on 26/04/23.
//

import UIKit
import FTCommon
import PDFKit

class FTStoreCustomCollectionCell: UICollectionViewCell {
    @IBOutlet weak var thumbnail: UIImageView?
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet private weak var shadowImageView: UIImageView!
    var sourceType: Source = .none

    override var isSelected: Bool {
        didSet {
            if sourceType == .shelf {
                self.thumbnail?.layer.borderColor = isSelected ? UIColor.appColor(.accent).cgColor : UIColor.clear.cgColor
                self.thumbnail?.layer.borderWidth = 2
            }
        }
    }

    // TODO: protocol approach
    func prepareCellWith(style: FTTemplateStyle, sourceType: Source) {
        self.sourceType = sourceType
        self.thumbnail?.image = nil
        self.titleLabel?.text = style.title
        thumbnail?.layer.cornerRadius = 2
        self.thumbnail?.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1)

        let image = UIImage(named: "Template_shadow", in: storeBundle, with: .none)
        let scalled = image?.resizableImage(withCapInsets: UIEdgeInsets(top: 3, left: 4, bottom: 5, right: 4), resizingMode: .stretch)
        shadowImageView.image = scalled

        self.thumbnail?.image = UIImage(named: "finder-empty-pdf-page");

        let url = FTStoreCustomTemplatesHandler.shared.imageUrlForTemplate(template: style)
        func loadthumbnail() {
            if let loadedImage = url.loadThumbnail() {
                self.thumbnail?.image = loadedImage
            }
        }

        if let fileUrl = FTStoreCustomTemplatesHandler.shared.filUrlForTemplate(template: style), fileUrl.pathExtension == "pdf" {
            guard let document = PDFDocument(url: fileUrl) else { return }
            if document.isLocked {
                self.thumbnail?.image = UIImage(named: "template_locked", in: storeBundle, with: nil)
            } else {
                loadthumbnail()
            }
        } else {
            loadthumbnail()
        }

    }

    

}
