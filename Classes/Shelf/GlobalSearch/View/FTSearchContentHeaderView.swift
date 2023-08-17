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
    func configureHeader(_ section: FTSearchSectionProtocol) {
        super.updateThemeAppearance()
        
        self.lblTitle?.text = section.title
        if let shelfItem = section.sectionHeaderItem as? FTShelfItemProtocol {
            var categoryName = "\(shelfItem.shelfCollection.title!)"
            if let groupItem = shelfItem.parent{
                categoryName = "\(categoryName) . \(groupItem.title!)"
            }
            self.lblCategory?.text = categoryName
        }
        var pagesString = "\(section.items.count) pages"
        if section.items.count == 1 {
            pagesString = "\(section.items.count) page"
        }
        self.lblMatchCount?.text = pagesString
    }
}
