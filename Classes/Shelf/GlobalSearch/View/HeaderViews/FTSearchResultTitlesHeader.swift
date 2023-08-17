//
//  FTSearchResultTitlesHeader.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 12/06/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTSearchResultTitlesHeader: FTSearchResultHeader {

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configureHeader(_ section: FTSearchSectionProtocol, searchKey: String) {
        self.coverPreviewContainer?.isHidden = true
        self.lblTitle?.font = UIFont.clearFaceFont(for: .medium, with: 20.0)
        self.lblTitle?.setTitle(title: section.title, highlight: searchKey)
        switch section.contentType {
        case .category, .book:
            self.lblCategory?.text = ""
            var pagesString = String.init(format: NSLocalizedString("NItems", comment: "%d Items"), section.items.count)
            if section.items.count == 1 {
                pagesString = NSLocalizedString("OneItem", comment: "1 Item")
            }
            self.lblMatchCount?.text = pagesString
        case .page:
            if let shelfItem = section.sectionHeaderItem as? FTShelfItemProtocol {
                self.coverPreviewContainer?.isHidden = false
                var token : String?
                token = FTURLReadThumbnailManager.sharedInstance.thumnailForItem(shelfItem, onCompletion: {[weak self] (image, imageToken) in
                    guard let self = self else {
                        return
                    }
                    if(image != nil && token == imageToken) {
                        runInMainThread {
                            if let img = image {
                                if img.size.width > img.size.height {
                                    self.imgWidthConstraint?.constant = 44.0
                                    self.imgHeightConstraint?.constant = 33.0
                                } else {
                                    self.imgWidthConstraint?.constant = 33.0
                                    self.imgHeightConstraint?.constant = 44.0
                                }
                                self.layoutIfNeeded()
                                self.bookImgPreview?.image = image
                                self.toShowEqualCorners = img.isDefaultCover || img.hasNoCover || img.size.width > img.size.height
                            }
                        }
                    }
                })

                var categoryName = "\(shelfItem.shelfCollection?.title ?? "")"
                if let groupItem = shelfItem.parent{
                    categoryName = "\(categoryName) /"
                    categoryName = "\(categoryName) \(groupItem.title) ·"
                }
                else{
                    categoryName = "\(categoryName) ·"
                }
                self.lblCategory?.text = categoryName
            }
            var pagesString = "\(section.items.count) \(NSLocalizedString("Pages", comment: "Pages"))"
            if section.items.count == 1 {
                pagesString = "\(section.items.count) \(NSLocalizedString("Page", comment: "Page"))"
            }
            self.lblMatchCount?.text = pagesString.lowercased()
        }
    }
}
