//
//  FTShelfBookmarkPageCell.swift
//  Noteshelf3
//
//  Created by Siva on 20/01/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTShelfBookmarkPageCell: UICollectionViewCell {
    @IBOutlet weak var thumbnail: UIImageView?
    @IBOutlet weak var bookTitleLbl: UILabel?
    @IBOutlet weak var pageTitleLbl: UILabel?
    @IBOutlet weak private var bookmarkIcon: UIButton?
    @IBOutlet weak var shadowImageView: UIImageView!

    func updateBookmarkItemCellContent(bookmarkItem: FTBookmarksItem) {
        self.bookTitleLbl?.text = bookmarkItem.shelfItem?.displayTitle
        if let pageNo = bookmarkItem.pageIndex {
            self.pageTitleLbl?.text = String(format: "sidebar.bookmarks.page".localized, String(describing: pageNo + 1))
        } else {
            self.pageTitleLbl?.text = String(format: "sidebar.bookmarks.page".localized, "1")
        }
        self.thumbnail?.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1)
        self.thumbnail?.image = nil
        bookmarkIcon?.tintColor = UIColor(hexString: bookmarkItem.color)
        if bookmarkItem.type == .page, let page = bookmarkItem.page {
            let image = UIImage(named: "pages_shadow")
            let scalled = image?.resizableImage(withCapInsets: UIEdgeInsets(top: 8, left: 20, bottom: 32, right: 20), resizingMode: .stretch)
            shadowImageView.image = scalled
            self.shadowImageView.layer.cornerRadius = 10
            self.thumbnail?.layer.cornerRadius = 10
            page.thumbnail()?.thumbnailImage(onUpdate: { image, uuid in
                if nil == image {
                    self.thumbnail?.image = UIImage(named: "finder-empty-pdf-page");
                } else {
                    self.shadowImageView.isHidden = false
                    self.thumbnail?.image = image
                }
            })
        }

    }
}
