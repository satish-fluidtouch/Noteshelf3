//
//  FTSearchResultContentHeader.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 20/06/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTSearchResultContentHeader: FTSearchResultHeader {
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    func configureHeader(_ section: FTSearchSectionProtocol, searchKey: String) {
        self.lblTitle?.setTitle(title: section.title, highlight: searchKey)
        if let shelfItem = section.sectionHeaderItem as? FTShelfItemProtocol {
            var categoryName = "\(shelfItem.shelfCollection?.title ?? "")"
            if let groupItem = shelfItem.parent{
                categoryName = "\(categoryName) / \(groupItem.title)"
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
