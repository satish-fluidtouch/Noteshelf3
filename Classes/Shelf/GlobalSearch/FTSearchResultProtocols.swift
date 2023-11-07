//
//  FTSearchResultProtocols.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 05/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

enum FTSearchContentType {
    case category
    case book
    case page
}

//================================ SECTION ITEM
protocol FTSearchSectionProtocol: NSObjectProtocol {
    var uuid: String {get set}
    var searchKey: String {get set}
    var contentType: FTSearchContentType {get}
    var title: String {get}
    var items: [FTSearchResultProtocol] {get}
    var sectionHeaderItem: FTDiskItemProtocol? {get set}
    var onStatusChange: ((_ section: FTSearchSectionProtocol?, _ isActive: Bool) -> Void)? {get set}
}

protocol FTSearchSectionContentProtocol: FTSearchSectionProtocol {
    func associatedPage(forItem item : FTSearchResultPageProtocol) -> FTThumbnailable?
    func addSearchItem(_ item: FTSearchResultPageProtocol);
    func beginContentAccess()
    func endContentAccess()
}

//================================ GRID ITEM
protocol FTSearchResultProtocol: NSObjectProtocol {
    var parentSection: FTSearchSectionProtocol? {get set}
    var title: String {get}
}

protocol FTSearchResultCategoryProtocol: FTSearchResultProtocol {
    var shelfItemCollection: FTShelfItemCollection? {get set}
}

protocol FTSearchResultBookProtocol: FTSearchResultProtocol {
    var shelfItem: FTShelfItemProtocol? {get set}
}

protocol FTSearchResultPageProtocol: FTSearchResultBookProtocol {
    var searchingInfo: FTPageSearchingInfo? {get set}
}
