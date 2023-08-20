//
//  FTBookmarkCollectionViewCell.swift
//  Noteshelf3
//
//  Created by Sameer Hussain on 05/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

class FTBookmarkCollectionViewCell: UICollectionViewCell {
    @IBOutlet var selectedImageView: UIImageView?
    @IBOutlet var bookmarkTitle: FTCustomLabel?
    @IBOutlet var pageNumber: FTCustomLabel?
    @IBOutlet var thumbnail: UIImageView?
    
    @IBOutlet weak var bookmarkButton: FTBaseButton!
    
    var isEditMode : Bool = false {
        didSet {
            selectedImageView?.isHidden = !isEditMode
        }
    }
  
    override func awakeFromNib() {
        super.awakeFromNib()
        thumbnail?.layer.borderColor = UIColor.appColor(.black10).cgColor
        thumbnail?.layer.borderWidth = 1
        thumbnail?.layer.cornerRadius = 4
    }

    func setIsSelected(_ selected : Bool) {
        let imageName = selected ? "checkmark.circle.fill" : "circle"
        let tintColor = selected ? UIColor.appColor(.accent) : UIColor.appColor(.black20)
        selectedImageView?.image = UIImage(systemName: imageName)
        selectedImageView?.tintColor =  tintColor
    }
    
    func confiureCell(with page: FTThumbnailable) {
        bookmarkTitle?.text = page.bookmarkTitle == "" ? NSLocalizedString("Untitled", comment: "Untitled") : page.bookmarkTitle
        pageNumber?.text = "p.\(page.pageIndex() + 1)"
        bookmarkButton.isSelected = page.isBookmarked
        let bookmarkColor = (!page.bookmarkColor.isEmpty) ? UIColor(hexString: page.bookmarkColor) : UIColor.appColor(.black20)
        bookmarkButton.tintColor = page.isBookmarked ? bookmarkColor : UIColor.appColor(.black20)
        page.thumbnail()?.thumbnailImage(onUpdate: {[weak self] image, error in
            self?.thumbnail?.image = image
            if nil == image {
                self?.thumbnail?.image = UIImage(named: "finder-empty-pdf-page");
            }
        })
    }
}
