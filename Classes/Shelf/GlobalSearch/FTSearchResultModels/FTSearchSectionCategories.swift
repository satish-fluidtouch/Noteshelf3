//
//  FTSearchSectionCategories.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 23/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTSearchSectionCategories: NSObject, FTSearchSectionProtocol {
    var uuid = UUID().uuidString
    var searchKey: String = ""
    var contentType: FTSearchContentType {
        return .category
    }
    var title: String {
        return NSLocalizedString("Categories", comment: "Categories")
    }
    var items: [FTSearchResultProtocol] = []
    var sectionHeaderItem: FTDiskItemProtocol?
    var onStatusChange: ((FTSearchSectionProtocol?, Bool) -> Void)?
}
