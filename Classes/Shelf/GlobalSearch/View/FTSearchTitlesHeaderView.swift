//
//  FTSearchResultHeaderView.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 12/06/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTSearchResultTitlesHeader: FTSearchResultHeader {
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configureHeader(_ section: FTSearchSectionProtocol) {
        
        super.updateThemeAppearance()
        
        self.lblTitle?.text = section.title
        if section is FTSearchSectionTitles {
            self.lblCategory?.text = ""
            var pagesString = "\(section.items.count) titles"
            if section.items.count == 1 {
                pagesString = "\(section.items.count) title"
            }
            self.lblMatchCount?.text = pagesString
        }
        else{
            if let shelfItem = section.sectionHeaderItem as? FTShelfItemProtocol {
                var categoryName = "\(shelfItem.shelfCollection.title!) ·"
                if let groupItem = shelfItem.parent{
                    categoryName = "\(categoryName) \(groupItem.title!) ·"
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
}
